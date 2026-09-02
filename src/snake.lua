local AudioManager = require("src/core/audio_manager")

local SnakeGame = {}
SnakeGame.__index = SnakeGame

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function randomColor()
    return {math.random(), math.random(), math.random()}
end

local function lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

local function distance(p1, p2)
    return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

-- Convert HSV to RGB (for rainbow)
local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    else r, g, b = v, p, q end
    return r, g, b
end

-- Find free cells considering all entities (snake, female snake, foods, power‑ups, forbidden, debug)
local function findFreeCells(snake, food, powerUp, greenFruit, goldenFruit, forbiddenFoods, cols, rows, femaleSnake, debugItems)
    local free = {}
    for r = 1, rows do
        for c = 1, cols do
            local occ = false
            for _, seg in ipairs(snake) do
                if seg.x == c and seg.y == r then occ = true; break end
            end
            if not occ and femaleSnake then
                for _, seg in ipairs(femaleSnake) do
                    if seg.x == c and seg.y == r then occ = true; break end
                end
            end
            if not occ and food and food.x == c and food.y == r then occ = true end
            if not occ and powerUp and powerUp.x == c and powerUp.y == r then occ = true end
            if not occ and greenFruit and greenFruit.x == c and greenFruit.y == r then occ = true end
            if not occ and goldenFruit and goldenFruit.x == c and goldenFruit.y == r then occ = true end
            if not occ and forbiddenFoods then
                for _, ff in ipairs(forbiddenFoods) do
                    if ff.x == c and ff.y == r then occ = true; break end
                end
            end
            if not occ and debugItems then
                for _, item in ipairs(debugItems) do
                    if item.x == c and item.y == r then occ = true; break end
                end
            end
            if not occ then table.insert(free, {x = c, y = r}) end
        end
    end
    return free
end

-- ============================================================
-- SNAKE GAME
-- ============================================================
function SnakeGame.new()
    local self = setmetatable({}, SnakeGame)
    self.gridSize = 16
    self.cols = 20
    self.rows = 20
    self.score = 0
    self.highScore = 0
    self.gameOver = false
    self.paused = false
    self.timer = 0
    self.baseSpeed = 0.12
    self.speed = self.baseSpeed
    self.tempSpeedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.lives = 3
    self.maxLives = 5
    self.width = 420
    self.height = 440
    self.glowTimer = 0
    self.glowActive = false
    self.glowDuration = 5.0
    
    -- Touch and Mouse Swipe State
    self.swipeStartX = 0
    self.swipeStartY = 0
    self.minSwipeDistance = 20
    self.touchMap = {}

    -- Color map for all items
    self.colorMap = {
        -- Foods
        food = {0.95, 0.2, 0.2},
        greenfruit = {0.5, 1.0, 0.3},
        goldenfruit = {1.0, 0.85, 0.2},
        
        -- Forbidden foods
        forbidden_food_1 = {0.13, 0.55, 0.13}, -- green
        forbidden_food_2 = {0.95, 0.85, 0.1},  -- Yellow
        forbidden_food_3 = {0.8, 0.2, 0.9},    -- Purple
        forbidden_food_4 = {0.2, 0.9, 0.9},    -- Cyan
        
        -- Power-ups
        shorten = {0.8, 0.4, 0.9},
        reverse = {0.2, 0.9, 0.9},
        speedup = {0.9, 0.9, 0.2},
        slowdown = {0.2, 0.4, 0.9},
        extralife = {0.9, 0.2, 0.6},
        scoreboost = {0.9, 0.6, 0.2},
        colorchange = {0.2, 0.9, 0.6},
        devilfruit = {0.9, 0.1, 0.1},
        lustfood = {1.0, 0.08, 0.58},
        nocollision = {0.0, 1.0, 0.5},
        forbidden = {0.5, 0.1, 0.5},
        mate = {1.0, 0.4, 0.7},
        rainbow = {0.9, 0.1, 0.8},
        wormhole = {0.19, 0.10, 0.20},
        whitehole = {1.0, 1.0, 1.0},
        blackhole = {0.0, 0.0, 0.0},
        fourthwall = {0.0, 0.8, 0.8}
    }

    -- Invincibility after respawn
    self.invincible = false
    self.invincibleTimer = 0
    self.invincibleDuration = 2.0
    self.blinkTimer = 0
    self.blinkVisible = true

    -- Forbidden Realm
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenDuration = 8.0
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}
    self.forbiddenCols = 20
    self.forbiddenRows = 20

    -- Color system
    self.snakeColors = {
        head = {0.6, 0.95, 0.3},
        body = {0.35, 0.85, 0.2}
    }
    self.targetHeadColor = {0.6, 0.95, 0.3}
    self.targetBodyColor = {0.35, 0.85, 0.2}
    self.colorChangeTimer = 0

    -- Devil fruit permanent red
    self.devilPermanent = false
    self.devilColor = {0.9, 0.1, 0.1}

    -- Rainbow mode
    self.rainbowActive = false
    self.rainbowTimer = 0
    self.rainbowDuration = 10.0

    -- Temporal no collision
    self.noCollision = false
    self.noCollisionTimer = 0
    self.noCollisionDuration = 3.0

    -- Lust food effect
    self.lustActive = false
    self.lustTimer = 0
    self.lustDuration = 5.0
    self.lustMultiplier = 3

    -- Whitehole / Blackhole effects
    self.whiteholeActive = false
    self.whiteholeTimer = 0
    self.blackholeActive = false
    self.blackholeTimer = 0
    self.effectDuration = 5.0

    -- 4th Wall Break
    self.fourthWallActive = false
    self.fourthWallTimer = 0
    self.fourthWallDuration = 15.0
    self.outsideTimer = 0
    self.outsideMax = 5.0

    -- Devil's fruit count
    self.devilFruitEaten = 0

    -- Golden fruit (very rare)
    self.goldenFruit = nil
    self.goldenFruitTimer = 0
    self.goldenFruitDuration = 3.0
    self.goldenFruitSpawnInterval = 30.0
    self.goldenFruitSpawnTimer = 0

    -- AI female snake
    self.femaleSnake = nil
    self.femaleActive = false
    self.femaleTimer = 0
    self.femaleDuration = 300 -- 5 minutes
    self.femaleLives = 3
    self.femaleMaxLives = 5
    self.femaleInvincible = false
    self.femaleInvincibleTimer = 0
    self.femaleNoCollision = false
    self.femaleNoCollisionTimer = 0
    self.femaleLustActive = false
    self.femaleLustTimer = 0
    self.femaleSpeedMultiplier = 1.0
    self.femaleTempSpeedTimer = 0
    self.femaleInForbidden = false
    self.femaleForbiddenTimer = 0
    self.femaleTarget = nil
    self.femaleDirection = {x = 1, y = 0}
    self.femaleNextDir = {x = 1, y = 0}
    self.femaleColor = {1.0, 0.4, 0.7}  -- pink
    self.femaleGlow = false
    self.femaleGlowTimer = 0
    self.femaleMoveTimer = 0
    self.femaleDevilPermanent = false
    self.femaleDevilColor = {0.9, 0.1, 0.1}

    -- Mating
    self.matingCooldown = 0
    self.matingCooldownMax = 10.0
    self.mateCount = 0
    self.matingFreeze = false
    self.matingFreezeTimer = 0
    self.shakeAmount = 0

    -- Power-up types (extended)
    self.powerUpTypes = {
        "shorten", 
        "reverse", 
        "speedup", 
        "slowdown", 
        "extralife", 
        "scoreboost",
        "colorchange", 
        "devilfruit", 
        "lustfood", 
        "nocollision", 
        "forbidden",
        "mate", 
        "rainbow", 
        "wormhole", 
        "whitehole", 
        "blackhole", 
        "fourthwall"
    }
    self.powerUp = nil
    self.powerUpTimer = 0
    self.powerUpSpawnInterval = 7.0
    self.powerUpSpawnTimer = 0

    -- Rare green fruit (spawns independently)
    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.greenFruitDuration = 5.0
    self.greenFruitSpawnInterval = 8.0
    self.greenFruitSpawnTimer = 0

    -- Debug items (multiple power-ups, foods, etc.)
    self.debugItems = {}

    -- Fonts (slightly smaller)
    self.font = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 13) or love.graphics.newFont(13)
    self.largeFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 20) or love.graphics.newFont(20)
    self.smallFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 10) or love.graphics.newFont(10)

    -- Load high score from file
    self:loadHighScore()

    -- IMMORTAL ENDING: new fields
    self.immortalEnding = false
    self.immortalTimer = 0
    self.immortalProgress = 0
    self.immortalSpeed = 0
    self.immortalParticles = {}
    self.immortalRemovedTiles = {}   -- positions of tiles that disappear
    self.immortalSnakePositions = {} -- copy of snake at start
    self.immortalSegmentIndex = 0    -- which segment to remove next
    self.immortalColor = {0.85, 0.7, 0.2} -- golden
    self.gameOverMessage = nil
    self.immortalFlash = 0
    self.immortalShake = 0

    self:reset()
    return self
end

function SnakeGame:loadHighScore()
    if love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo("snake_highscore.txt") then
            local content = love.filesystem.read("snake_highscore.txt")
            if content then
                self.highScore = tonumber(content) or 0
            end
        end
    end
end

function SnakeGame:saveHighScore()
    if love.filesystem and love.filesystem.write then
        love.filesystem.write("snake_highscore.txt", tostring(self.highScore))
    end
end

function SnakeGame:reset()
    self.snake = {
        { x = 10, y = 10 },
        { x = 9, y = 10 },
        { x = 8, y = 10 }
    }
    self.dir = { x = 1, y = 0 }
    self.nextDir = { x = 1, y = 0 }
    self.gameOver = false
    self.gameOverMessage = nil
    self.score = 0
    self.lives = 3
    self.speed = self.baseSpeed
    self.tempSpeedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.powerUp = nil
    self.powerUpTimer = 0
    self.powerUpSpawnTimer = 0
    self.invincible = false
    self.invincibleTimer = 0
    self.noCollision = false
    self.noCollisionTimer = 0
    self.lustActive = false
    self.lustTimer = 0
    self.devilFruitEaten = 0
    self.devilPermanent = false
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}
    self.glowActive = false
    self.glowTimer = 0
    self.rainbowActive = false
    self.rainbowTimer = 0
    self.whiteholeActive = false
    self.whiteholeTimer = 0
    self.blackholeActive = false
    self.blackholeTimer = 0
    self.fourthWallActive = false
    self.fourthWallTimer = 0
    self.outsideTimer = 0
    self.debugItems = {}
    self.goldenFruit = nil
    self.goldenFruitTimer = 0
    self.goldenFruitSpawnTimer = 0

    -- Reset female
    self.femaleActive = false
    self.femaleSnake = nil
    self.femaleTimer = 0
    self.femaleLives = 3
    self.femaleInvincible = false
    self.femaleNoCollision = false
    self.femaleLustActive = false
    self.femaleSpeedMultiplier = 1.0
    self.femaleInForbidden = false
    self.femaleGlow = false
    self.femaleGlowTimer = 0
    self.matingCooldown = 0
    self.mateCount = 0
    self.femaleMoveTimer = 0
    self.matingFreeze = false
    self.matingFreezeTimer = 0
    self.shakeAmount = 0
    self.femaleDevilPermanent = false
    self.femaleDevilColor = {0.9, 0.1, 0.1}

    -- Reset green fruit
    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.greenFruitSpawnTimer = 0

    -- IMMORTAL ENDING reset
    self.immortalEnding = false
    self.immortalTimer = 0
    self.immortalProgress = 0
    self.immortalSpeed = 0
    self.immortalParticles = {}
    self.immortalRemovedTiles = {}
    self.immortalSnakePositions = {}
    self.immortalSegmentIndex = 0
    self.immortalColor = {0.85, 0.7, 0.2}
    self.gameOverMessage = nil
    self.immortalFlash = 0
    self.immortalShake = 0

    self.targetHeadColor = {0.6, 0.95, 0.3}
    self.targetBodyColor = {0.35, 0.85, 0.2}
    self.snakeColors.head = {0.6, 0.95, 0.3}
    self.snakeColors.body = {0.35, 0.85, 0.2}
    self:spawnFood()
    self:loadHighScore()
end

-- ============================================================
-- FOOD & POWER-UP SPAWNING
-- ============================================================
function SnakeGame:spawnFood()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, nil, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, self.femaleSnake, self.debugItems)
    if #free > 0 then
        self.food = free[math.random(1, #free)]
    else
        self.food = { x = 1, y = 1 }
    end
end

function SnakeGame:spawnPowerUp()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, nil, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, self.femaleSnake, self.debugItems)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        local typeIdx = math.random(1, #self.powerUpTypes)
        -- Devil's fruit and mate are rarer; mate can now spawn even if female active
        if self.powerUpTypes[typeIdx] == "devilfruit" and math.random() > 0.25 then
            typeIdx = math.random(1, #self.powerUpTypes - 2)
        end
        if self.powerUpTypes[typeIdx] == "mate" and math.random() > 0.25 then
            typeIdx = math.random(1, #self.powerUpTypes - 2)
        end
        self.powerUp = {
            x = pos.x,
            y = pos.y,
            type = self.powerUpTypes[typeIdx],
            timer = 6.0,
            blink = 0
        }
        self.powerUpTimer = 6.0
    end
end

function SnakeGame:spawnGreenFruit()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, self.powerUp, nil, self.goldenFruit, self.forbiddenFoods, cols, rows, self.femaleSnake, self.debugItems)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        self.greenFruit = {
            x = pos.x,
            y = pos.y,
            timer = self.greenFruitDuration
        }
        self.greenFruitTimer = self.greenFruitDuration
    end
end

function SnakeGame:spawnGoldenFruit()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, nil, self.forbiddenFoods, cols, rows, self.femaleSnake, self.debugItems)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        self.goldenFruit = {
            x = pos.x,
            y = pos.y,
            timer = self.goldenFruitDuration,
            type = math.random(1, 3) -- 1: extra life, 2: score boost, 3: invincibility
        }
        self.goldenFruitTimer = self.goldenFruitDuration
    end
end

-- Spawn a forbidden food (type 1-4)
function SnakeGame:spawnForbiddenFood()
    local cols = self.forbiddenCols
    local rows = self.forbiddenRows
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, self.femaleSnake, self.debugItems)
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        local type = math.random(1, 4)  -- type 4 adds time
        table.insert(self.forbiddenFoods, {x = pos.x, y = pos.y, type = type})
    end
end

-- ============================================================
-- FEMALE AI SNAKE
-- ============================================================
function SnakeGame:spawnFemale()
    if self.femaleActive then return end
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, nil, self.debugItems) -- female not yet exists
    if #free < 5 then return end

    -- Place female snake away from player
    local head = self.snake[1]
    local sorted = {}
    for _, cell in ipairs(free) do
        table.insert(sorted, {cell = cell, dist = distance(cell, head)})
    end
    table.sort(sorted, function(a,b) return a.dist > b.dist end)
    local start = sorted[1].cell

    self.femaleSnake = {
        { x = start.x, y = start.y },
        { x = start.x - 1, y = start.y },
        { x = start.x - 2, y = start.y }
    }
    self.femaleDirection = { x = 1, y = 0 }
    self.femaleNextDir = { x = 1, y = 0 }
    self.femaleActive = true
    self.femaleTimer = self.femaleDuration
    self.femaleLives = 3
    self.femaleInvincible = false
    self.femaleInvincibleTimer = 0
    self.femaleNoCollision = false
    self.femaleNoCollisionTimer = 0
    self.femaleLustActive = false
    self.femaleLustTimer = 0
    self.femaleSpeedMultiplier = 1.0
    self.femaleTempSpeedTimer = 0
    self.femaleInForbidden = false
    self.femaleForbiddenTimer = 0
    self.femaleGlow = false
    self.femaleGlowTimer = 0
    self.femaleTarget = nil
    self.femaleColor = {1.0, 0.4, 0.7}
    self.femaleMoveTimer = 0
    self.femaleDevilPermanent = false
    self.femaleDevilColor = {0.9, 0.1, 0.1}
    AudioManager.playSFX("levelup", 1.2, 0.5)
    Notifications.add("Snake", "A pink female snake appeared!", nil, 3.0)
end

-- BFS pathfinding for female AI
function SnakeGame:findPath(start, targets, obstacles, cols, rows)
    local queue = {{x = start.x, y = start.y, path = {}}}
    local visited = {}
    visited[start.x .. "," .. start.y] = true

    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, dir in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
            local nx, ny = current.x + dir[1], current.y + dir[2]
            if nx >= 1 and nx <= cols and ny >= 1 and ny <= rows then
                local key = nx .. "," .. ny
                if not visited[key] then
                    local blocked = false
                    for _, obs in ipairs(obstacles) do
                        if obs.x == nx and obs.y == ny then
                            blocked = true
                            break
                        end
                    end
                    if not blocked then
                        local newPath = {unpack(current.path)}
                        table.insert(newPath, {x = nx, y = ny})
                        for _, t in ipairs(targets) do
                            if t.x == nx and t.y == ny then
                                if #newPath > 0 then
                                    return newPath[1]
                                else
                                    return {x = nx, y = ny}
                                end
                            end
                        end
                        visited[key] = true
                        table.insert(queue, {x = nx, y = ny, path = newPath})
                    end
                end
            end
        end
    end
    return nil
end

function SnakeGame:getFemaleDirection()
    local head = self.femaleSnake[1]
    local cols, rows
    local obstacles = {}

    if self.femaleInForbidden then
        cols = self.forbiddenCols
        rows = self.forbiddenRows
        for i = 1, #self.femaleSnake - 1 do
            table.insert(obstacles, self.femaleSnake[i])
        end
    else
        cols = self.cols
        rows = self.rows
        for i = 1, #self.femaleSnake - 1 do
            table.insert(obstacles, self.femaleSnake[i])
        end
        for i = 2, #self.snake do
            table.insert(obstacles, self.snake[i])
        end
    end

    local targets = {}

    -- If lust active, highest priority is the player's head
    if self.femaleLustActive and not self.femaleInForbidden then
        local playerHead = self.snake[1]
        table.insert(targets, 1, playerHead)  -- highest priority
        -- Also add other targets after
        if self.powerUp and self.powerUp.type == "lustfood" then
            table.insert(targets, self.powerUp)
        end
        if self.food then table.insert(targets, self.food) end
        if self.greenFruit then table.insert(targets, self.greenFruit) end
        if self.goldenFruit then table.insert(targets, self.goldenFruit) end
    else
        -- Normal priority: golden fruit first, then lust food, green fruit, power-ups, food
        if not self.femaleInForbidden then
            if self.goldenFruit then
                table.insert(targets, 1, self.goldenFruit)
            end
            if self.powerUp and self.powerUp.type == "lustfood" then
                table.insert(targets, 1, self.powerUp)  -- highest priority
            end
            if self.greenFruit then table.insert(targets, 1, self.greenFruit) end
            if self.food then table.insert(targets, self.food) end
            -- other power-ups (excluding lustfood)
            if self.powerUp and self.powerUp.type ~= "lustfood" then
                table.insert(targets, self.powerUp)
            end
        else
            -- Forbidden realm: forbidden foods
            for _, f in ipairs(self.forbiddenFoods) do
                table.insert(targets, f)
            end
            -- Also regular items if present
            if self.food then table.insert(targets, self.food) end
            if self.powerUp then table.insert(targets, self.powerUp) end
            if self.greenFruit then table.insert(targets, 1, self.greenFruit) end
            if self.goldenFruit then table.insert(targets, 1, self.goldenFruit) end
        end
    end

    if #targets == 0 then
        return nil
    end

    for _, t in ipairs(targets) do
        local step = self:findPath(head, {t}, obstacles, cols, rows)
        if step then
            return {x = step.x - head.x, y = step.y - head.y}
        end
    end
    return nil
end

function SnakeGame:updateFemaleAI(dt)
    if not self.femaleActive then return end

    self.femaleTimer = self.femaleTimer - dt
    if self.femaleTimer <= 0 then
        self.femaleActive = false
        self.femaleSnake = nil
        Notifications.add("Snake", "Female snake disappeared into the walls!", nil, 3.0)
        return
    end

    if self.femaleInvincible then
        self.femaleInvincibleTimer = self.femaleInvincibleTimer - dt
        if self.femaleInvincibleTimer <= 0 then
            self.femaleInvincible = false
        end
    end
    if self.femaleNoCollision then
        self.femaleNoCollisionTimer = self.femaleNoCollisionTimer - dt
        if self.femaleNoCollisionTimer <= 0 then
            self.femaleNoCollision = false
        end
    end
    if self.femaleLustActive then
        self.femaleLustTimer = self.femaleLustTimer - dt
        if self.femaleLustTimer <= 0 then
            self.femaleLustActive = false
        end
    end
    if self.femaleTempSpeedTimer > 0 then
        self.femaleTempSpeedTimer = self.femaleTempSpeedTimer - dt
        if self.femaleTempSpeedTimer <= 0 then
            self.femaleSpeedMultiplier = 1.0
        end
    end
    if self.femaleGlow then
        self.femaleGlowTimer = self.femaleGlowTimer - dt
        if self.femaleGlowTimer <= 0 then
            self.femaleGlow = false
        end
    end
    if self.femaleInForbidden then
        self.femaleForbiddenTimer = self.femaleForbiddenTimer - dt
        if self.femaleForbiddenTimer <= 0 then
            self.femaleInForbidden = false
            local cols = self.cols
            local rows = self.rows
            local head = self.femaleSnake[1]
            head.x = math.min(head.x, cols)
            head.y = math.min(head.y, rows)
        end
    end

    local currentSpeed = self.baseSpeed * (1 / self.femaleSpeedMultiplier)
    self.femaleMoveTimer = self.femaleMoveTimer + dt
    if self.femaleMoveTimer >= currentSpeed then
        self.femaleMoveTimer = 0

        local cols = self.femaleInForbidden and self.forbiddenCols or self.cols
        local rows = self.femaleInForbidden and self.forbiddenRows or self.rows

        local dir = self:getFemaleDirection()
        if dir then
            self.femaleNextDir = dir
        else
            local possible = {}
            local reverse = {x = -self.femaleDirection.x, y = -self.femaleDirection.y}
            for _, d in ipairs({{0,-1},{0,1},{-1,0},{1,0}}) do
                if not (d[1] == reverse.x and d[2] == reverse.y) then
                    local nx = self.femaleSnake[1].x + d[1]
                    local ny = self.femaleSnake[1].y + d[2]
                    local blocked = false
                    if nx < 1 or nx > cols or ny < 1 or ny > rows then blocked = true end
                    if not blocked then
                        for i = 1, #self.femaleSnake - 1 do
                            if self.femaleSnake[i].x == nx and self.femaleSnake[i].y == ny then
                                blocked = true; break
                            end
                        end
                    end
                    if not blocked then
                        table.insert(possible, {x = d[1], y = d[2]})
                    end
                end
            end
            if #possible > 0 then
                local d = possible[math.random(1, #possible)]
                self.femaleNextDir = d
            else
                self.femaleNextDir = {x = -self.femaleDirection.x, y = -self.femaleDirection.y}
            end
        end

        self.femaleDirection = {x = self.femaleNextDir.x, y = self.femaleNextDir.y}
        local head = self.femaleSnake[1]
        local newHead = {x = head.x + self.femaleDirection.x, y = head.y + self.femaleDirection.y}

        -- Wrap (or not if 4th wall active for female? For simplicity, female always wraps)
        if newHead.x < 1 then newHead.x = cols end
        if newHead.x > cols then newHead.x = 1 end
        if newHead.y < 1 then newHead.y = rows end
        if newHead.y > rows then newHead.y = 1 end

        if not self.femaleNoCollision and not self.femaleInvincible then
            for i = 1, #self.femaleSnake - 1 do
                if self.femaleSnake[i].x == newHead.x and self.femaleSnake[i].y == newHead.y then
                    self.femaleLives = self.femaleLives - 1
                    if self.femaleLives <= 0 then
                        self.femaleActive = false
                        self.femaleSnake = nil
                        Notifications.add("Snake", "Female snake died!", nil, 3.0)
                        return
                    else
                        self.femaleInvincible = true
                        self.femaleInvincibleTimer = 2.0
                        while #self.femaleSnake > 3 do table.remove(self.femaleSnake) end
                        self.femaleDirection = {x = 1, y = 0}
                        self.femaleNextDir = {x = 1, y = 0}
                        -- Reset female color on death (revival)
                        self.femaleDevilPermanent = false
                        self.femaleColor = {1.0, 0.4, 0.7} -- default pink
                    end
                    return
                end
            end
        end

        table.insert(self.femaleSnake, 1, newHead)

        -- Eat food (including forbidden realm)
        local ate = false
        if not self.femaleInForbidden then
            if self.food and newHead.x == self.food.x and newHead.y == self.food.y then
                local points = 10
                if self.femaleLustActive then points = points * 3 end
                self.score = self.score + points
                if self.score > self.highScore then self.highScore = self.score end
                self.baseSpeed = math.max(0.06, 0.12 - math.floor(self.score / 50) * 0.01)
                self.speed = self.baseSpeed
                AudioManager.playSFX("tick", 1.5, 0.5)
                self:spawnFood()
                ate = true
            end
            if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                self:applyPowerUpToFemale(self.powerUp)
                self.powerUp = nil
                ate = true
            end
            if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                self.score = self.score + 200
                if self.score > self.highScore then self.highScore = self.score end
                self.femaleGlow = true
                self.femaleGlowTimer = self.glowDuration
                self.greenFruit = nil
                self.greenFruitTimer = 0
                AudioManager.playSFX("levelup", 1.8, 0.8)
                Notifications.add("Snake", "Female ate LIME GREEN FRUIT! +200 and pink glow!", nil, 2.0)
                ate = true
            end
            if self.goldenFruit and newHead.x == self.goldenFruit.x and newHead.y == self.goldenFruit.y then
                self:applyGoldenFruitToFemale()
                self.goldenFruit = nil
                self.goldenFruitTimer = 0
                ate = true
            end
        end

        -- Forbidden foods (including type 4)
        for i = #self.forbiddenFoods, 1, -1 do
            local f = self.forbiddenFoods[i]
            if newHead.x == f.x and newHead.y == f.y then
                if f.type == 4 then
                    self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                    AudioManager.playSFX("levelup", 1.0, 0.6)
                    Notifications.add("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                else
                    local points = f.type == 1 and 15 or (f.type == 2 and 30 or 50)
                    if self.femaleLustActive then points = points * 3 end
                    self.score = self.score + points
                    if self.score > self.highScore then self.highScore = self.score end
                    AudioManager.playSFX("tick", 1.5 + f.type * 0.2, 0.5)
                end
                table.remove(self.forbiddenFoods, i)
                ate = true
                break
            end
        end

        if not ate then
            table.remove(self.femaleSnake)
        end

        -- Mating check (female with player)
        if self.femaleActive and not self.gameOver then
            local playerHead = self.snake[1]
            local femaleHead = self.femaleSnake[1]
            if playerHead.x == femaleHead.x and playerHead.y == femaleHead.y then
                if self.matingCooldown <= 0 then
                    self:mate()
                end
            end
        end
    end
end

function SnakeGame:applyPowerUpToFemale(powerUp)
    local type = powerUp.type
    if type == "shorten" then
        for i = 1, 3 do if #self.femaleSnake > 3 then table.remove(self.femaleSnake) end end
    elseif type == "reverse" then
        local reversed = {}
        for i = #self.femaleSnake, 1, -1 do
            table.insert(reversed, self.femaleSnake[i])
        end
        self.femaleSnake = reversed
        self.femaleDirection = { x = -self.femaleDirection.x, y = -self.femaleDirection.y }
        self.femaleNextDir = { x = self.femaleDirection.x, y = self.femaleDirection.y }
    elseif type == "speedup" then
        self.femaleSpeedMultiplier = self.femaleSpeedMultiplier + 0.8
        self.femaleTempSpeedTimer = 4.0
    elseif type == "slowdown" then
        self.femaleSpeedMultiplier = 0.5
        self.femaleTempSpeedTimer = 4.0
    elseif type == "extralife" then
        if self.femaleLives < self.femaleMaxLives then
            self.femaleLives = self.femaleLives + 1
        end
    elseif type == "scoreboost" then
        self.score = self.score + 50
        if self.score > self.highScore then self.highScore = self.score end
    elseif type == "colorchange" then
        -- Override devil skin: set permanent flag to false and apply random color
        self.femaleDevilPermanent = false
        self.femaleColor = randomColor()
    elseif type == "devilfruit" then
        self.score = self.score + 100
        self.devilFruitEaten = self.devilFruitEaten + 1
        self.femaleDevilPermanent = true
        self.femaleColor = self.femaleDevilColor
        self.femaleSpeedMultiplier = 1.5
        self.femaleTempSpeedTimer = 3.0
    elseif type == "lustfood" then
        self.femaleLustActive = true
        self.femaleLustTimer = 5.0
    elseif type == "nocollision" then
        self.femaleNoCollision = true
        self.femaleNoCollisionTimer = 3.0
    elseif type == "forbidden" then
        if not self.femaleInForbidden then
            self.femaleInForbidden = true
            self.femaleForbiddenTimer = 8.0
            local cols = self.forbiddenCols
            local rows = self.forbiddenRows
            self.femaleSnake = {
                {x = math.floor(cols/2), y = math.floor(rows/2)},
                {x = math.floor(cols/2)-1, y = math.floor(rows/2)},
                {x = math.floor(cols/2)-2, y = math.floor(rows/2)}
            }
            self.femaleDirection = {x = 1, y = 0}
            self.femaleNextDir = {x = 1, y = 0}
        end
    elseif type == "mate" then
        if self.femaleActive then
            self.femaleTimer = math.min(self.femaleTimer + 30, 600)
            self.score = self.score + 50
            if self.score > self.highScore then self.highScore = self.score end
            Notifications.add("Snake", "Female time extended!", nil, 2.0)
        else
            self:spawnFemale()
        end
    elseif type == "rainbow" then
        if self.femaleDevilPermanent then
            self.femaleColor = self.femaleDevilColor
        else
            self.femaleColor = randomColor()
        end
    end
    AudioManager.playSFX("tick", 1.0, 0.3)
end

function SnakeGame:applyGoldenFruitToFemale()
    if not self.goldenFruit then return end
    local type = self.goldenFruit.type
    if type == 1 then
        self.femaleLives = math.min(self.femaleLives + 1, self.femaleMaxLives)
        Notifications.add("Snake", "Female got extra life from Golden Fruit!", nil, 2.0)
    elseif type == 2 then
        self.score = self.score + 500
        if self.score > self.highScore then self.highScore = self.score end
        Notifications.add("Snake", "Female +500 points from Golden Fruit!", nil, 2.0)
    else
        self.femaleInvincible = true
        self.femaleInvincibleTimer = 5.0
        Notifications.add("Snake", "Female got invincibility from Golden Fruit!", nil, 2.0)
    end
    AudioManager.playSFX("levelup", 2.0, 0.9)
end

function SnakeGame:mate()
    self.mateCount = self.mateCount + 1
    local bonus = 100 + self.mateCount * 50
    self.score = self.score + bonus
    if self.score > self.highScore then self.highScore = self.score end
    self.matingCooldown = self.matingCooldownMax
    AudioManager.playSFX("levelup", 1.5, 0.8)
    Notifications.add("Snake", "Mating success! +" .. bonus .. " points!", nil, 2.0)

    self.matingFreeze = true
    self.matingFreezeTimer = 0.5
    self.shakeAmount = 4
    self.tempSpeedMultiplier = 0.7
    self.tempSpeedTimer = 3.0
    self.femaleSpeedMultiplier = 0.7
    self.femaleTempSpeedTimer = 3.0
end

function SnakeGame:startImmortalEnding()
    -- Clear all fruits, power-ups, AI, and items from the board
    self.food = nil
    self.powerUp = nil
    self.greenFruit = nil
    self.goldenFruit = nil
    self.forbiddenFoods = {}
    self.debugItems = {}
    self.powerUpTimer = 0
    self.greenFruitTimer = 0
    self.femaleActive = false
    self.femaleSnake = nil

    self.immortalEnding = true
    self.immortalTimer = 0
    self.immortalProgress = 0 -- Used to slowly transition the color to golden
    self.immortalSpeed = self.speed
    self.immortalSegmentIndex = #self.snake

    self.immortalSnakePositions = {}
    for _, seg in ipairs(self.snake) do
        table.insert(self.immortalSnakePositions, {x = seg.x, y = seg.y})
    end

    -- Keep this empty initially; tiles will disappear after the freeze
    self.immortalRemovedTiles = {}

    self.immortalParticles = {}
    self.immortalFlash = 0.5
    self.immortalShake = 10

    AudioManager.playSFX("levelup", 2.0, 0.9)
    Notifications.add("Snake", "Ascending to immortality...", nil, 1.5)
end

function SnakeGame:updateImmortalEnding(dt)
    self.immortalTimer = self.immortalTimer + dt
    self.immortalFlash = self.immortalFlash - dt
    if self.immortalFlash < 0 then self.immortalFlash = 0 end
    self.immortalShake = self.immortalShake * 0.98

    if not self.gameOver then
        -- Phase 1: Freeze and transition color to golden over 2 seconds
        if self.immortalTimer < 3.0 then
            self.immortalProgress = self.immortalTimer / 3.0
            
        -- Phase 2: Disappear snake, vanish tiles, and show Game Over
        else
            self.immortalProgress = 1.0
            
            -- Make the tiles beneath the snake disappear
            for _, pos in ipairs(self.immortalSnakePositions) do
                table.insert(self.immortalRemovedTiles, {x = pos.x, y = pos.y})
            end
            
            -- Snake disappears (with optional particle burst)
            while #self.snake > 0 do
                local tail = table.remove(self.snake)
                
                for i = 1, 15 do
                    local angle = math.random() * 2 * math.pi
                    local speed = math.random() * 100 + 50
                    local life = math.random() * 0.6 + 0.2
                    local sparkSize = math.random() * 4 + 2
                    table.insert(self.immortalParticles, {
                        x = tail.x, y = tail.y,
                        vx = math.cos(angle) * speed,
                        vy = math.sin(angle) * speed - 20,
                        life = life, maxLife = life,
                        size = sparkSize,
                        color = {1.0, 0.85, 0.2, 0.9}
                    })
                end
            end

            self.immortalFlash = 1.5
            self.gameOver = true
            self.gameOverMessage = "SNAKE BECAME IMMORTAL"
            
            if self.score > self.highScore then
                self.highScore = self.score
                self:saveHighScore()
            end
            AudioManager.playSFX("glitch", 0.8, 0.4)
        end
    end

    -- Animate lingering particles over the void
    for i = #self.immortalParticles, 1, -1 do
        local p = self.immortalParticles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 30 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.immortalParticles, i)
        end
    end
end

-- ============================================================
-- PLAYER METHODS
-- ============================================================
function SnakeGame:isEmptyCell(x, y, excludeItem)
    -- Check snake
    for _, seg in ipairs(self.snake) do
        if seg.x == x and seg.y == y then return false end
    end
    -- Check female snake
    if self.femaleSnake then
        for _, seg in ipairs(self.femaleSnake) do
            if seg.x == x and seg.y == y then return false end
        end
    end
    -- Check food
    if self.food and excludeItem ~= self.food then
        if self.food.x == x and self.food.y == y then return false end
    end
    -- Check powerUp
    if self.powerUp and excludeItem ~= self.powerUp then
        if self.powerUp.x == x and self.powerUp.y == y then return false end
    end
    -- Check greenFruit
    if self.greenFruit and excludeItem ~= self.greenFruit then
        if self.greenFruit.x == x and self.greenFruit.y == y then return false end
    end
    -- Check goldenFruit
    if self.goldenFruit and excludeItem ~= self.goldenFruit then
        if self.goldenFruit.x == x and self.goldenFruit.y == y then return false end
    end
    -- Check forbidden foods
    for _, f in ipairs(self.forbiddenFoods) do
        if excludeItem ~= f then
            if f.x == x and f.y == y then return false end
        end
    end
    -- Check debug items
    for _, item in ipairs(self.debugItems) do
        if excludeItem ~= item then
            if item.x == x and item.y == y then return false end
        end
    end
    return true
end

function SnakeGame:applyPowerUp(powerUp)
    local type = powerUp.type
    if type == "shorten" then
        for i = 1, 3 do if #self.snake > 3 then table.remove(self.snake) end end
        AudioManager.playSFX("tick", 1.2, 0.3)
    elseif type == "reverse" then
        local reversed = {}
        for i = #self.snake, 1, -1 do
            table.insert(reversed, self.snake[i])
        end
        self.snake = reversed
        self.dir = { x = -self.dir.x, y = -self.dir.y }
        self.nextDir = { x = self.dir.x, y = self.dir.y }
        AudioManager.playSFX("tick", 0.8, 0.3)
    elseif type == "speedup" then
        self.tempSpeedMultiplier = self.tempSpeedMultiplier + 0.8
        self.tempSpeedTimer = 4.0
        AudioManager.playSFX("tick", 1.8, 0.3)
    elseif type == "slowdown" then
        self.tempSpeedMultiplier = 0.5
        self.tempSpeedTimer = 4.0
        AudioManager.playSFX("tick", 0.6, 0.3)
    elseif type == "extralife" then
        if self.lives < self.maxLives then self.lives = self.lives + 1 end
        AudioManager.playSFX("levelup", 1.2, 0.5)
    elseif type == "scoreboost" then
        self.score = self.score + 50
        if self.score > self.highScore then self.highScore = self.score end
        AudioManager.playSFX("task_complete", 1.0, 0.5)
    elseif type == "colorchange" then
        -- Override devil skin: set permanent flag to false and apply random color
        self.devilPermanent = false
        self.targetHeadColor = randomColor()
        self.targetBodyColor = randomColor()
        self.colorChangeTimer = 1.0
        AudioManager.playSFX("tick", 1.5, 0.3)
    elseif type == "devilfruit" then
        self.score = self.score + 100
        self.devilFruitEaten = self.devilFruitEaten + 1
        self.devilPermanent = true
        self.targetHeadColor = self.devilColor
        self.targetBodyColor = self.devilColor
        self.colorChangeTimer = 1.0
        self.tempSpeedMultiplier = 1.5
        self.tempSpeedTimer = 3.0
        AudioManager.playSFX("levelup", 1.5, 0.8)
    elseif type == "lustfood" then
        self.lustActive = true
        self.lustTimer = self.lustDuration
        AudioManager.playSFX("task_complete", 1.2, 0.5)
    elseif type == "nocollision" then
        self.noCollision = true
        self.noCollisionTimer = self.noCollisionDuration
        AudioManager.playSFX("tick", 1.8, 0.3)
    elseif type == "forbidden" then
        self:enterForbiddenRealm()
        AudioManager.playSFX("levelup", 1.0, 0.8)
    elseif type == "mate" then
        if not self.femaleActive then
            self:spawnFemale()
        else
            self.femaleTimer = math.min(self.femaleTimer + 30, 600)
            self.score = self.score + 50
            if self.score > self.highScore then self.highScore = self.score end
            Notifications.add("Snake", "Female time extended!", nil, 2.0)
        end
        AudioManager.playSFX("levelup", 1.2, 0.5)
    elseif type == "rainbow" then
        self.rainbowActive = true
        self.rainbowTimer = self.rainbowDuration
        AudioManager.playSFX("levelup", 1.3, 0.6)
    elseif type == "wormhole" then
        self:teleportSnake()
        AudioManager.playSFX("levelup", 1.0, 0.7)
    elseif type == "whitehole" then
        self.whiteholeActive = true
        self.whiteholeTimer = self.effectDuration
        AudioManager.playSFX("levelup", 1.0, 0.5)
    elseif type == "blackhole" then
        self.blackholeActive = true
        self.blackholeTimer = self.effectDuration
        AudioManager.playSFX("levelup", 1.0, 0.5)
    elseif type == "fourthwall" then
        self.fourthWallActive = true
        self.fourthWallTimer = self.fourthWallDuration
        self.outsideTimer = 0
        AudioManager.playSFX("levelup", 1.0, 0.7)
        Notifications.add("Snake", "4TH WALL BREAK! You can leave the grid!", nil, 2.0)
    end
end

function SnakeGame:teleportSnake()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    
    local free = findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, self.femaleSnake, self.debugItems)
    if #free == 0 then return end
    
    local newHead = free[math.random(1, #free)]
    local oldHead = self.snake[1]
    
    -- Calculate the exact distance the head is moving
    local offsetX = newHead.x - oldHead.x
    local offsetY = newHead.y - oldHead.y
    
    -- Shift every segment by the exact same distance to retain the current shape
    for _, seg in ipairs(self.snake) do
        seg.x = seg.x + offsetX
        seg.y = seg.y + offsetY
        
        -- Wrap around the boundaries seamlessly
        while seg.x < 1 do seg.x = seg.x + cols end
        while seg.x > cols do seg.x = seg.x - cols end
        while seg.y < 1 do seg.y = seg.y + rows end
        while seg.y > rows do seg.y = seg.y - rows end
    end
end

function SnakeGame:enterForbiddenRealm()
    self.inForbiddenRealm = true
    self.forbiddenTimer = self.forbiddenDuration
    self.forbiddenFoods = {}
    self.food = nil -- Remove normal food
    self.powerUp = nil -- Remove power-ups
    self.greenFruit = nil -- Remove green fruit
    self.goldenFruit = nil -- Remove golden fruit
    local cols = self.forbiddenCols
    local rows = self.forbiddenRows
    for i = 1, 15 do
        self:spawnForbiddenFood()
    end
end

function SnakeGame:exitForbiddenRealm()
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}
    self.powerUp = nil
    self.powerUpTimer = 0
    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.goldenFruit = nil
    self.goldenFruitTimer = 0
    self:spawnFood() -- Spawn regular food when exiting
end

function SnakeGame:revive()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self.gameOver = true
        self.gameOverMessage = "Game Over"
        if self.score > self.highScore then
            self.highScore = self.score
            self:saveHighScore()
        end
        AudioManager.playSFX("glitch", 1.2, 0.4)
        return false
    end
    self.invincible = true
    self.invincibleTimer = self.invincibleDuration
    self.blinkTimer = 0
    self.blinkVisible = true
    while #self.snake > 3 do table.remove(self.snake) end
    if #self.snake > 1 then
        local head = self.snake[1]
        local next = self.snake[2]
        self.dir = { x = head.x - next.x, y = head.y - next.y }
        self.nextDir = { x = self.dir.x, y = self.dir.y }
    else
        self.dir = { x = 1, y = 0 }
        self.nextDir = { x = 1, y = 0 }
    end
    -- Reset color to default green on death (revival)
    self.devilPermanent = false
    self.targetHeadColor = {0.6, 0.95, 0.3}
    self.targetBodyColor = {0.35, 0.85, 0.2}
    self.snakeColors.head = {0.6, 0.95, 0.3}
    self.snakeColors.body = {0.35, 0.85, 0.2}
    self.colorChangeTimer = 0
    self:spawnFood()
    self.powerUp = nil
    AudioManager.playSFX("levelup", 0.8, 0.5)
    return true
end

-- New method to handle normal death (non-tail collision)
function SnakeGame:handleDeath()
    local revived = self:revive()
    if not revived then
        -- game over is already set inside revive
        -- ensure message is set (revive sets it)
    end
end

-- ============================================================
-- MAIN UPDATE
-- ============================================================
function SnakeGame:update(dt)
    if self.paused then return end

    if self.immortalEnding then
        self:updateImmortalEnding(dt)
        return
    elseif self.gameOver then 
        return 
    end

    -- Mating freeze
    if self.matingFreeze then
        self.matingFreezeTimer = self.matingFreezeTimer - dt
        if self.matingFreezeTimer <= 0 then
            self.matingFreeze = false
            self.shakeAmount = 0
        else
            self.shakeAmount = self.shakeAmount * 0.95
            return
        end
    end

    if self.matingCooldown > 0 then self.matingCooldown = self.matingCooldown - dt end
    if self.glowActive then
        self.glowTimer = self.glowTimer - dt
        if self.glowTimer <= 0 then self.glowActive = false end
    end
    if self.rainbowActive then
        self.rainbowTimer = self.rainbowTimer - dt
        if self.rainbowTimer <= 0 then self.rainbowActive = false end
    end
    if self.fourthWallActive then
        self.fourthWallTimer = self.fourthWallTimer - dt
        if self.fourthWallTimer <= 0 then
            self.fourthWallActive = false
            self.outsideTimer = 0
        end
    end

    -- Whitehole logic (attracts items to player head)
    if self.whiteholeActive then
        self.whiteholeTimer = self.whiteholeTimer - dt
        if self.whiteholeTimer <= 0 then self.whiteholeActive = false end
        if self.food and not self.inForbiddenRealm then
            local head = self.snake[1]
            local dx = self.food.x - head.x
            local dy = self.food.y - head.y
            local newX, newY = self.food.x, self.food.y
            if math.abs(dx) >= math.abs(dy) then
                newX = self.food.x + (dx > 0 and 1 or -1)
            else
                newY = self.food.y + (dy > 0 and 1 or -1)
            end
            newX = math.max(1, math.min(self.cols, newX))
            newY = math.max(1, math.min(self.rows, newY))
            if self:isEmptyCell(newX, newY, self.food) then
                self.food.x = newX
                self.food.y = newY
            end
        end
        if self.inForbiddenRealm then
            local head = self.snake[1]
            for _, f in ipairs(self.forbiddenFoods) do
                local dx = f.x - head.x
                local dy = f.y - head.y
                local newX, newY = f.x, f.y
                if math.abs(dx) >= math.abs(dy) then
                    newX = f.x + (dx > 0 and 1 or -1)
                else
                    newY = f.y + (dy > 0 and 1 or -1)
                end
                newX = math.max(1, math.min(self.forbiddenCols, newX))
                newY = math.max(1, math.min(self.forbiddenRows, newY))
                if self:isEmptyCell(newX, newY, f) then
                    f.x = newX
                    f.y = newY
                end
            end
        end
    end

    -- Blackhole logic (repels items away from player head)
    if self.blackholeActive then
        self.blackholeTimer = self.blackholeTimer - dt
        if self.blackholeTimer <= 0 then self.blackholeActive = false end
        local head = self.snake[1]
        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
        
        local function repel(item)
            if item then
                local dx = head.x - item.x
                local dy = head.y - item.y
                local newX, newY = item.x, item.y
                if math.abs(dx) >= math.abs(dy) then
                    newX = item.x + (dx > 0 and 1 or -1)
                else
                    newY = item.y + (dy > 0 and 1 or -1)
                end
                newX = math.max(1, math.min(cols, newX))
                newY = math.max(1, math.min(rows, newY))
                if self:isEmptyCell(newX, newY, item) then
                    item.x = newX
                    item.y = newY
                end
            end
        end

        repel(self.food)
        repel(self.powerUp)
        repel(self.greenFruit)
        repel(self.goldenFruit)

        if self.inForbiddenRealm then
            for _, f in ipairs(self.forbiddenFoods) do
                local dx = head.x - f.x
                local dy = head.y - f.y
                local newX, newY = f.x, f.y
                if math.abs(dx) >= math.abs(dy) then
                    newX = f.x + (dx > 0 and 1 or -1)
                else
                    newY = f.y + (dy > 0 and 1 or -1)
                end
                newX = math.max(1, math.min(self.forbiddenCols, newX))
                newY = math.max(1, math.min(self.forbiddenRows, newY))
                if self:isEmptyCell(newX, newY, f) then
                    f.x = newX
                    f.y = newY
                end
            end
        end
        if self.femaleActive and not self.femaleInForbidden then
            local fHead = self.femaleSnake[1]
            local dx = head.x - fHead.x
            local dy = head.y - fHead.y
            local newX, newY = fHead.x, fHead.y
            if math.abs(dx) >= math.abs(dy) then
                newX = fHead.x + (dx > 0 and 1 or -1)
            else
                newY = fHead.y + (dy > 0 and 1 or -1)
            end
            newX = math.max(1, math.min(self.cols, newX))
            newY = math.max(1, math.min(self.rows, newY))
            if self:isEmptyCell(newX, newY, fHead) then
                fHead.x = newX
                fHead.y = newY
            end
        end
    end

    -- Handle blinking for invincibility and no collision (both snakes)
    local shouldBlink = self.invincible or self.noCollision or self.femaleInvincible or self.femaleNoCollision

    if shouldBlink then
        self.blinkTimer = self.blinkTimer + dt
        if self.blinkTimer > 0.1 then
            self.blinkTimer = 0
            self.blinkVisible = not self.blinkVisible
        end
    else
        self.blinkVisible = true
    end

    -- Handle individual timers
    if self.invincible then
        self.invincibleTimer = self.invincibleTimer - dt
        if self.invincibleTimer <= 0 then
            self.invincible = false
            if not (self.noCollision or self.femaleInvincible or self.femaleNoCollision) then
                self.blinkVisible = true
            end
        end
    end

    if self.noCollision then
        self.noCollisionTimer = self.noCollisionTimer - dt
        if self.noCollisionTimer <= 0 then
            self.noCollision = false
            if not (self.invincible or self.femaleInvincible or self.femaleNoCollision) then
                self.blinkVisible = true
            end
        end
    end

    if self.femaleInvincible then
        self.femaleInvincibleTimer = self.femaleInvincibleTimer - dt
        if self.femaleInvincibleTimer <= 0 then
            self.femaleInvincible = false
            if not (self.invincible or self.noCollision or self.femaleNoCollision) then
                self.blinkVisible = true
            end
        end
    end

    if self.femaleNoCollision then
        self.femaleNoCollisionTimer = self.femaleNoCollisionTimer - dt
        if self.femaleNoCollisionTimer <= 0 then
            self.femaleNoCollision = false
            if not (self.invincible or self.noCollision or self.femaleInvincible) then
                self.blinkVisible = true
            end
        end
    end

    if self.lustActive then
        self.lustTimer = self.lustTimer - dt
        if self.lustTimer <= 0 then self.lustActive = false end
    end

    if self.colorChangeTimer > 0 then
        self.colorChangeTimer = self.colorChangeTimer - dt
        local t = 1 - self.colorChangeTimer
        self.snakeColors.head = lerpColor(self.snakeColors.head, self.targetHeadColor, t * 0.05)
        self.snakeColors.body = lerpColor(self.snakeColors.body, self.targetBodyColor, t * 0.05)
    end

    if self.tempSpeedTimer > 0 then
        self.tempSpeedTimer = self.tempSpeedTimer - dt
        if self.tempSpeedTimer <= 0 then self.tempSpeedMultiplier = 1.0 end
    end

    if self.inForbiddenRealm then
        self.forbiddenTimer = self.forbiddenTimer - dt
        if self.forbiddenTimer <= 0 then
            self:exitForbiddenRealm()
            if self.femaleActive and self.femaleInForbidden then
                self.femaleInForbidden = false
                self.femaleForbiddenTimer = 0
            end
        end
        -- Only spawn forbidden foods, no regular food or power-ups
        while #self.forbiddenFoods < 15 do self:spawnForbiddenFood() end
    else
        -- Normal spawning outside forbidden realm
        if not self.powerUp then
            self.powerUpSpawnTimer = self.powerUpSpawnTimer + dt
            if self.powerUpSpawnTimer >= self.powerUpSpawnInterval then
                self.powerUpSpawnTimer = 0
                self:spawnPowerUp()
            end
        else
            self.powerUpTimer = self.powerUpTimer - dt
            self.powerUp.blink = (self.powerUp.blink or 0) + dt
            if self.powerUpTimer <= 0 then self.powerUp = nil end
        end

        if not self.greenFruit then
            self.greenFruitSpawnTimer = self.greenFruitSpawnTimer + dt
            if self.greenFruitSpawnTimer >= self.greenFruitSpawnInterval then
                self.greenFruitSpawnTimer = 0
                self:spawnGreenFruit()
            end
        else
            self.greenFruitTimer = self.greenFruitTimer - dt
            if self.greenFruitTimer <= 0 then self.greenFruit = nil end
        end

        -- Golden fruit spawn (very rare)
        if not self.goldenFruit then
            self.goldenFruitSpawnTimer = self.goldenFruitSpawnTimer + dt
            if self.goldenFruitSpawnTimer >= self.goldenFruitSpawnInterval then
                self.goldenFruitSpawnTimer = 0
                self:spawnGoldenFruit()
            end
        else
            self.goldenFruitTimer = self.goldenFruitTimer - dt
            if self.goldenFruitTimer <= 0 then self.goldenFruit = nil end
        end
    end

    self:updateFemaleAI(dt)

    -- Player Movement
    self.timer = self.timer + dt
    local currentSpeed = self.speed * (1 / self.tempSpeedMultiplier)
    
    if self.timer >= currentSpeed then
        self.timer = 0
        self.dir = { x = self.nextDir.x, y = self.nextDir.y }

        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local head = self.snake[1]
        local newHead = { x = head.x + self.dir.x, y = head.y + self.dir.y }

        local outside = false
        if not self.fourthWallActive then
            if newHead.x < 1 then newHead.x = cols end
            if newHead.x > cols then newHead.x = 1 end
            if newHead.y < 1 then newHead.y = rows end
            if newHead.y > rows then newHead.y = 1 end
        else
            if newHead.x < 1 or newHead.x > cols or newHead.y < 1 or newHead.y > rows then
                outside = true
            else
                self.outsideTimer = 0
            end
        end

        -- Collision checks separated: Strict tail vs body
        if not self.noCollision and not self.invincible then
            local hitTail = false
            local hitBody = false

            if #self.snake > 0 then
                local tail = self.snake[#self.snake]
                if newHead.x == tail.x and newHead.y == tail.y then
                    hitTail = true
                end
            end
            
            if not hitTail then
                for i = 2, #self.snake - 1 do
                    if self.snake[i].x == newHead.x and self.snake[i].y == newHead.y then
                        hitBody = true
                        break
                    end
                end
            end

            if hitTail then
                self:startImmortalEnding()
                return
            elseif hitBody then
                self:handleDeath()
                return
            end
        end

        if self.fourthWallActive and outside then
            self.outsideTimer = self.outsideTimer + dt
            if self.outsideTimer >= self.outsideMax then
                self.gameOver = true
                self.gameOverMessage = "Lost in the void"
                if self.score > self.highScore then
                    self.highScore = self.score
                    self:saveHighScore()
                end
                AudioManager.playSFX("glitch", 1.2, 0.4)
                return
            end        end

        table.insert(self.snake, 1, newHead)

        local ate = false
        if not self.inForbiddenRealm then
            if self.food and newHead.x == self.food.x and newHead.y == self.food.y then
                local points = 10
                if self.lustActive then points = points * self.lustMultiplier end
                self.score = self.score + points
                if self.score > self.highScore then self.highScore = self.score end
                self.baseSpeed = math.max(0.06, 0.12 - math.floor(self.score / 50) * 0.01)
                self.speed = self.baseSpeed
                AudioManager.playSFX("tick", 1.5, 0.5)
                self:spawnFood()
                ate = true
            end
            if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                self:applyPowerUp(self.powerUp)
                self.powerUp = nil
                ate = true
            end
            if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                self.score = self.score + 200
                if self.score > self.highScore then self.highScore = self.score end
                self.glowActive = true
                self.glowTimer = self.glowDuration
                self.greenFruit = nil
                self.greenFruitTimer = 0
                AudioManager.playSFX("levelup", 1.8, 0.8)
                Notifications.add("Snake", "LIME GREEN FRUIT! +200 points and glow!", nil, 2.0)
                ate = true
            end
            if self.goldenFruit and newHead.x == self.goldenFruit.x and newHead.y == self.goldenFruit.y then
                self:applyGoldenFruit()  -- uses self.goldenFruit
                self.goldenFruit = nil
                self.goldenFruitTimer = 0
                ate = true
            end
            for i = #self.debugItems, 1, -1 do
                local item = self.debugItems[i]
                if newHead.x == item.x and newHead.y == item.y then
                    if item.type == "food" then
                        self.score = self.score + 10
                        AudioManager.playSFX("tick", 1.5, 0.5)
                    elseif item.type == "greenfruit" then
                        self.score = self.score + 200
                        self.glowActive = true
                        self.glowTimer = self.glowDuration
                        AudioManager.playSFX("levelup", 1.8, 0.8)
                    elseif item.type == "goldenfruit" then
                        self:applyGoldenFruit(item)  -- pass debug item
                    elseif item.type == "forbidden_food" then
                        -- Handle forbidden food types from debug
                        local ftype = item.food_type or 1
                        if ftype == 4 then
                            self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                            AudioManager.playSFX("levelup", 1.0, 0.6)
                            Notifications.add("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                        else
                            local points = ftype == 1 and 15 or (ftype == 2 and 30 or 50)
                            if self.lustActive then points = points * self.lustMultiplier end
                            self.score = self.score + points
                            if self.score > self.highScore then self.highScore = self.score end
                            AudioManager.playSFX("tick", 1.5 + ftype * 0.2, 0.5)
                        end
                    else
                        self:applyPowerUp(item)
                    end
                    table.remove(self.debugItems, i)
                    ate = true
                end
            end
        else
            -- In forbidden realm: only forbidden foods can be eaten
            for i = #self.forbiddenFoods, 1, -1 do
                local f = self.forbiddenFoods[i]
                if newHead.x == f.x and newHead.y == f.y then
                    if f.type == 4 then
                        self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                        AudioManager.playSFX("levelup", 1.0, 0.6)
                        Notifications.add("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                    else
                        local points = f.type == 1 and 15 or (f.type == 2 and 30 or 50)
                        if self.lustActive then points = points * self.lustMultiplier end
                        self.score = self.score + points
                        if self.score > self.highScore then self.highScore = self.score end
                        AudioManager.playSFX("tick", 1.5 + f.type * 0.2, 0.5)
                    end
                    table.remove(self.forbiddenFoods, i)
                    ate = true
                    break
                end
            end
        end

        if not ate then
            table.remove(self.snake)
        end

        if self.femaleActive then
            local fHead = self.femaleSnake[1]
            if newHead.x == fHead.x and newHead.y == fHead.y then
                if self.matingCooldown <= 0 then
                    self:mate()
                end
            end
        end
    end
end

-- FIXED: applyGoldenFruit now accepts an optional fruit parameter
function SnakeGame:applyGoldenFruit(fruit)
    fruit = fruit or self.goldenFruit
    if not fruit then return end
    local type = fruit.type
    if type == 1 then
        self.lives = math.min(self.lives + 1, self.maxLives)
        Notifications.add("Snake", "GOLDEN FRUIT! Extra life!", nil, 2.0)
    elseif type == 2 then
        self.score = self.score + 500
        if self.score > self.highScore then self.highScore = self.score end
        Notifications.add("Snake", "GOLDEN FRUIT! +500 points!", nil, 2.0)
    else
        self.invincible = true
        self.invincibleTimer = 5.0
        Notifications.add("Snake", "GOLDEN FRUIT! Invincibility!", nil, 2.0)
    end
    AudioManager.playSFX("levelup", 2.0, 0.9)
end

-- Helper function to get color from color map
function SnakeGame:getItemColor(type, subtype)
    if type == "forbidden_food" then
        local key = "forbidden_food_" .. tostring(subtype or 1)
        return self.colorMap[key] or self.colorMap.forbidden_food_1
    end
    return self.colorMap[type] or {1, 1, 1}
end

-- ============================================================
-- DRAW
-- ============================================================
function SnakeGame:draw(x, y, width, height)
    self.width = width
    self.height = height

    love.graphics.push()
    love.graphics.translate(x, y)

    -- Screen shake for immortal ending
    if self.immortalShake and self.immortalShake > 0.29 then
        local ox = math.random(-self.immortalShake, self.immortalShake)
        local oy = math.random(-self.immortalShake, self.immortalShake)
        love.graphics.translate(ox, oy)
    end

    -- Mating freeze shake
    if self.shakeAmount > 0 then
        local ox = math.random(-self.shakeAmount, self.shakeAmount)
        local oy = math.random(-self.shakeAmount, self.shakeAmount)
        love.graphics.translate(ox, oy)
    end

    -- Background (normal: near‑black; Forbidden Realm: dark purple with subtle accents)
    if self.inForbiddenRealm then
        love.graphics.setColor(0.06, 0.01, 0.09)   -- deep purple background
        love.graphics.rectangle("fill", 0, 0, width, height)
        -- faint "glow" spots for atmosphere
        love.graphics.setColor(0.2, 0.05, 0.3, 0.2)
        for i = 1, 5 do
            local rx = math.random(0, width)
            local ry = math.random(0, height)
            love.graphics.rectangle("fill", rx, ry, math.random(10, 40), math.random(2, 6))
        end
    else
        -- Normal world: almost black
        love.graphics.setColor(0.02, 0.02, 0.02)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end

    -- Header bar (two rows: total 52px)
    local barH = 52
    if self.inForbiddenRealm then
        love.graphics.setColor(0.12, 0.04, 0.18)   -- dark purple header
    else
        love.graphics.setColor(0.06, 0.06, 0.06)   -- dark gray header
    end
    love.graphics.rectangle("fill", 0, 0, width, barH)

    -- Row 1: Score, High Score, Lives (unchanged)
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.35, 0.75, 1.0)
    love.graphics.print("SCORE: " .. tostring(self.score), 10, 6)

    love.graphics.setColor(0.85, 0.75, 0.3)
    love.graphics.print("HIGH: " .. tostring(self.highScore), 10 + 120, 6)

    local rightX = width - 10
    love.graphics.setColor(0.9, 0.3, 0.3)
    for i = 1, self.lives do
        love.graphics.circle("fill", rightX - (self.lives - i) * 14, 10, 4)
    end
    rightX = rightX - self.lives * 14 - 6

    if self.femaleActive then
        love.graphics.setColor(1.0, 0.4, 0.7)
        for i = 1, self.femaleLives do
            love.graphics.circle("fill", rightX - (self.femaleLives - i) * 14, 10, 4)
        end
        rightX = rightX - self.femaleLives * 14 - 6

        local minutes = math.floor(self.femaleTimer / 60)
        local seconds = math.floor(self.femaleTimer % 60)
        local timeStr = string.format("F:%02d:%02d", minutes, seconds)
        love.graphics.setColor(1.0, 0.4, 0.7)
        love.graphics.setFont(self.smallFont)
        love.graphics.print(timeStr, rightX - 55, 8)
        rightX = rightX - 55 - 4
    end

    love.graphics.setFont(self.smallFont)
    local statusX = 10
    local statusY = 28
    local statuses = {}

    if self.noCollision then
        statuses[#statuses+1] = {text = "NC", color = {0.2, 0.8, 0.9}}
    end
    if self.lustActive then
        statuses[#statuses+1] = {text = "LUST", color = {0.9, 0.2, 0.5}}
    end
    if self.invincible then
        statuses[#statuses+1] = {text = "INV", color = {1.0, 0.8, 0.2}}
    end
    if self.inForbiddenRealm then
        statuses[#statuses+1] = {text = "FR", color = {0.8, 0.3, 0.9}}  -- purple FR indicator
    end
    if self.glowActive then
        statuses[#statuses+1] = {text = "GLOW", color = {0.5, 1.0, 0.3}}
    end
    if self.rainbowActive then
        statuses[#statuses+1] = {text = "RB", color = {0.9, 0.1, 0.8}}
    end
    if self.whiteholeActive then
        statuses[#statuses+1] = {text = "WH", color = {1.0, 1.0, 1.0}}
    end
    if self.blackholeActive then
        statuses[#statuses+1] = {text = "BH", color = {0.2, 0.2, 0.2}}
    end
    if self.fourthWallActive then
        statuses[#statuses+1] = {text = "4W", color = {0.0, 0.8, 0.8}}
    end
    if self.devilPermanent then
        statuses[#statuses+1] = {text = "DEVIL", color = {0.9, 0.1, 0.1}}
    end

    for _, st in ipairs(statuses) do
        love.graphics.setColor(st.color)
        love.graphics.print(st.text, statusX, statusY)
        statusX = statusX + love.graphics.getFont():getWidth(st.text) + 6
    end

    if self.paused then
        love.graphics.setColor(0.9, 0.9, 0.2, 0.8)
        love.graphics.setFont(self.largeFont)
        love.graphics.printf("PAUSED", width/2 - 60, 10, 120, "center")
    end

    -- Playing Grid Area
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local boardW = cols * self.gridSize
    local boardH = rows * self.gridSize

    local scale = 1
    if boardW > width - 20 or boardH > height - barH - 20 then
        scale = math.min((width - 20) / boardW, (height - barH - 20) / boardH)
        boardW = boardW * scale
        boardH = boardH * scale
    end

    local boardX = math.floor((width - boardW) / 2)
    local boardY = barH + math.floor((height - barH - boardH) / 2)

    -- Board background (different for each realm)
    if self.inForbiddenRealm then
        love.graphics.setColor(0.03, 0.0, 0.06)   -- very dark purple board
    else
        love.graphics.setColor(0.01, 0.01, 0.01)  -- near‑black board
    end
    love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)

    -- Board border
    if self.inForbiddenRealm then
        love.graphics.setColor(0.35, 0.1, 0.45)   -- bright purple border
    else
        love.graphics.setColor(0.15, 0.15, 0.15)  -- subtle gray border
    end
    love.graphics.rectangle("line", boardX, boardY, boardW, boardH)

    -- Grid lines
    if self.inForbiddenRealm then
        love.graphics.setColor(0.15, 0.03, 0.2)   -- dark purple grid lines
    else
        love.graphics.setColor(0.1, 0.1, 0.1)     -- dark gray lines
    end
    for r = 1, rows-1 do
        love.graphics.line(boardX, boardY + r * self.gridSize * scale, boardX + boardW, boardY + r * self.gridSize * scale)
    end
    for c = 1, cols-1 do
        love.graphics.line(boardX + c * self.gridSize * scale, boardY, boardX + c * self.gridSize * scale, boardY + boardH)
    end

    -- IMMORTAL ENDING: draw removed tiles as dark voids (unchanged)
    if self.immortalEnding then
        for _, tile in ipairs(self.immortalRemovedTiles) do
            local tx = boardX + (tile.x - 1) * self.gridSize * scale
            local ty = boardY + (tile.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", tx, ty, size, size)
        end
    end

    -- Food (only show if not in forbidden realm)
    if self.food and not self.inForbiddenRealm then
        local fx = boardX + (self.food.x - 1) * self.gridSize * scale
        local fy = boardY + (self.food.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local color = self.colorMap.food
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", fx + 2, fy + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(color[1] * 0.8, color[2] * 0.5, color[3] * 0.5)
        love.graphics.rectangle("fill", fx + 4, fy + 4, size - 8, size - 8, 2, 2)
    end

    -- Forbidden foods (using color map)
    if self.inForbiddenRealm then
        for _, f in ipairs(self.forbiddenFoods) do
            local fx = boardX + (f.x - 1) * self.gridSize * scale
            local fy = boardY + (f.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale
            local color = self:getItemColor("forbidden_food", f.type)
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", fx + 1, fy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("fill", fx - 2, fy - 2, size + 4, size + 4, 6, 6)
        end
    end

    -- Helper function to draw rainbow power-up
    local function drawRainbowPowerUp(px, py, size, alpha, isDebug)
        -- 7 rainbow colors (ROYGBIV)
        local rainbowColors = {
            {1.0, 0.0, 0.0},     -- Red
            {1.0, 0.5, 0.0},     -- Orange
            {1.0, 1.0, 0.0},     -- Yellow
            {0.0, 1.0, 0.0},     -- Green
            {0.0, 0.0, 1.0},     -- Blue
            {0.29, 0.0, 0.51},   -- Indigo
            {0.58, 0.0, 0.83}    -- Violet
        }
        
        -- Cycle through colors every 0.3 seconds
        local colorIndex = math.floor(love.timer.getTime() * 3.33 * 2) % 7 + 1
        local color = rainbowColors[colorIndex]
        
        -- Pulsing glow effect
        local glowAlpha = 0.2 + math.sin(love.timer.getTime() * 3) * 0.15
        
        -- Outer glow
        love.graphics.setColor(color[1], color[2], color[3], glowAlpha * (isDebug and 1.5 or 1))
        love.graphics.rectangle("fill", px - 2, py - 2, size + 4, size + 4, 4, 4)
        
        -- Main rainbow power-up
        love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
        love.graphics.rectangle("fill", px + 1, py + 1, size - 2, size - 2, 4, 4)
        
        -- Inner highlight
        love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 0.5 * (alpha or 1))
        love.graphics.rectangle("fill", px + 3, py + 3, size - 8, size - 8, 2, 2)
        
        -- Blink effect when about to expire (only for regular spawn)
        if not isDebug and self.powerUpTimer < 2 and math.floor(self.powerUp.blink * 4) % 2 == 0 then
            love.graphics.setColor(1, 1, 1, 0.3)
            love.graphics.rectangle("fill", px, py, size, size)
        end
    end

    -- Helper function to draw circle-shaped power-ups
    local function drawCirclePowerUp(px, py, size, color, glowColor, isBlackhole)
        local centerX = px + size / 2
        local centerY = py + size / 2
        local radius = size / 2
        
        -- Outer glow
        if isBlackhole then
            -- Blackhole gets WHITE glow
            love.graphics.setColor(1, 1, 1, 0.3 + math.sin(love.timer.getTime() * 2) * 0.1)
        else
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.3 + math.sin(love.timer.getTime() * 2) * 0.1)
        end
        love.graphics.circle("fill", centerX, centerY, radius + 4)
        
        -- Inner glow
        if isBlackhole then
            love.graphics.setColor(1, 1, 1, 0.15)
        else
            love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], 0.15)
        end
        love.graphics.circle("fill", centerX, centerY, radius + 8)
        
        -- Main circle
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.circle("fill", centerX, centerY, radius - 1)
        
        -- Inner highlight (for whitehole and wormhole)
        if not isBlackhole then
            love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, 0.5)
            love.graphics.circle("fill", centerX, centerY, radius - 4)
        end
        
        -- Blackhole gets a subtle ring effect
        if isBlackhole then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            love.graphics.circle("line", centerX, centerY, radius - 2)
            love.graphics.setColor(0.2, 0.2, 0.2, 0.3)
            love.graphics.circle("line", centerX, centerY, radius + 2)
        end
    end

    -- Power‑up (only show if not in forbidden realm)
    if self.powerUp and not self.inForbiddenRealm then
        local px = boardX + (self.powerUp.x - 1) * self.gridSize * scale
        local py = boardY + (self.powerUp.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        
        if self.powerUp.type == "rainbow" then
            drawRainbowPowerUp(px, py, size, 1, false)
        elseif self.powerUp.type == "blackhole" then
            local color = self.colorMap.blackhole or {0.0, 0.0, 0.0}
            drawCirclePowerUp(px, py, size, color, {1, 1, 1}, true)
        elseif self.powerUp.type == "whitehole" then
            local color = self.colorMap.whitehole or {1.0, 1.0, 1.0}
            drawCirclePowerUp(px, py, size, color, {0.8, 0.8, 0.8}, false)
        elseif self.powerUp.type == "wormhole" then
            local color = self.colorMap.wormhole or {0.19, 0.10, 0.20}
            drawCirclePowerUp(px, py, size, color, {0.4, 0.2, 0.6}, false)
        else
            -- Regular power-up rendering
            local color = self.colorMap[self.powerUp.type] or {1, 1, 1}
            local alpha = 1
            if self.powerUpTimer < 2 and math.floor(self.powerUp.blink * 4) % 2 == 0 then
                alpha = 0.4
            end
            love.graphics.setColor(color[1], color[2], color[3], alpha)
            love.graphics.rectangle("fill", px + 1, py + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(color[1], color[2], color[3], 0.3 * alpha)
            love.graphics.rectangle("fill", px - 2, py - 2, size + 4, size + 4, 6, 6)
        end
    end

    -- Debug items (using color map)
    for _, item in ipairs(self.debugItems) do
        local ix = boardX + (item.x - 1) * self.gridSize * scale
        local iy = boardY + (item.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local color
        
        if item.type == "forbidden_food" then
            color = self:getItemColor("forbidden_food", item.food_type)
        else
            color = self.colorMap[item.type] or {1, 1, 1}
        end
        
        if item.type == "food" then
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", ix + 2, iy + 2, size - 4, size - 4, 3, 3)
            love.graphics.setColor(color[1] * 0.8, color[2] * 0.5, color[3] * 0.5)
            love.graphics.rectangle("fill", ix + 4, iy + 4, size - 8, size - 8, 2, 2)
        elseif item.type == "greenfruit" then
            love.graphics.setColor(color[1], color[2], color[3], 0.25)
            love.graphics.rectangle("fill", ix - 4, iy - 4, size + 8, size + 8, 6, 6)
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(color[1] * 0.6, color[2] * 0.8, color[3] * 0.6)
            love.graphics.rectangle("fill", ix + 3, iy + 3, size - 8, size - 8, 2, 2)
        elseif item.type == "goldenfruit" then
            love.graphics.setColor(color[1], color[2], color[3], 0.3)
            love.graphics.rectangle("fill", ix - 6, iy - 6, size + 12, size + 12, 8, 8)
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(color[1] * 0.9, color[2] * 0.8, color[3] * 0.5)
            love.graphics.rectangle("fill", ix + 3, iy + 3, size - 8, size - 8, 2, 2)
        elseif item.type == "forbidden_food" then
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("fill", ix - 2, iy - 2, size + 4, size + 4, 6, 6)
        elseif item.type == "rainbow" then
            drawRainbowPowerUp(ix, iy, size, 1, true)
        elseif item.type == "blackhole" then
            drawCirclePowerUp(ix, iy, size, color, {1, 1, 1}, true)
        elseif item.type == "whitehole" then
            drawCirclePowerUp(ix, iy, size, color, {0.8, 0.8, 0.8}, false)
        elseif item.type == "wormhole" then
            drawCirclePowerUp(ix, iy, size, color, {0.4, 0.2, 0.6}, false)
        else
    
            love.graphics.setColor(color[1], color[2], color[3], 0.3)
            love.graphics.rectangle("fill", ix - 2, iy - 2, size + 4, size + 4, 6, 6)
            love.graphics.setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
        end
    end

    -- Green fruit (only show if not in forbidden realm)
    if self.greenFruit and not self.inForbiddenRealm then
        local gx = boardX + (self.greenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.greenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local color = self.colorMap.greenfruit
        love.graphics.setColor(color[1], color[2], color[3], 0.25)
        love.graphics.rectangle("fill", gx - 4, gy - 4, size + 8, size + 8, 6, 6)
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", gx + 1, gy + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(color[1] * 0.6, color[2] * 0.8, color[3] * 0.6)
        love.graphics.rectangle("fill", gx + 3, gy + 3, size - 8, size - 8, 2, 2)
    end

    -- Golden fruit (very rare, glowing)
    if self.goldenFruit and not self.inForbiddenRealm then
        local gx = boardX + (self.goldenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.goldenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local color = self.colorMap.goldenfruit
        -- Glow effect
        love.graphics.setColor(color[1], color[2], color[3], 0.3 + math.sin(love.timer.getTime() * 4) * 0.15)
        love.graphics.rectangle("fill", gx - 6, gy - 6, size + 12, size + 12, 8, 8)
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.rectangle("fill", gx + 1, gy + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(color[1] * 0.9, color[2] * 0.8, color[3] * 0.5)
        love.graphics.rectangle("fill", gx + 3, gy + 3, size - 8, size - 8, 2, 2)
        -- Sparkle effect
        love.graphics.setColor(1.0, 1.0, 0.8, 0.6)
        love.graphics.rectangle("fill", gx + size * 0.3, gy + size * 0.2, 2, 2)
        love.graphics.rectangle("fill", gx + size * 0.7, gy + size * 0.7, 2, 2)
    end

    -- Draw player snake
    if not self.immortalEnding or #self.snake > 0 then
        for i, seg in ipairs(self.snake) do
            local sx = boardX + (seg.x - 1) * self.gridSize * scale
            local sy = boardY + (seg.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale

            -- Check if we should skip drawing due to blinking (invincibility OR no collision)
            local shouldSkip = false
            if self.invincible and not self.blinkVisible then
                shouldSkip = true
            end
            if self.noCollision and not self.blinkVisible then
                shouldSkip = true
            end
            
            if not shouldSkip then
                local color = {self.snakeColors.head[1], self.snakeColors.head[2], self.snakeColors.head[3]}
                if self.immortalEnding then
                    local t = self.immortalProgress
                    local gold = {0.9, 0.75, 0.2}
                    for c = 1, 3 do
                        color[c] = color[c] + (gold[c] - color[c]) * t
                    end
                end

                if self.glowActive then
                    love.graphics.setColor(0.5, 1.0, 0.3, 0.4)
                    love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
                end
                if self.rainbowActive then
                    local hue = (i - 1) / #self.snake
                    local r, g, b = hsvToRgb(hue, 1.0, 1.0)
                    love.graphics.setColor(r, g, b)
                else
                    if i == 1 then
                        if self.devilPermanent then
                            love.graphics.setColor(self.devilColor)
                        else
                            love.graphics.setColor(color)
                        end
                    else
                        if self.immortalEnding then
                            local t = self.immortalProgress
                            local bodyGold = {0.7, 0.55, 0.15}
                            local bodyColor = {self.snakeColors.body[1], self.snakeColors.body[2], self.snakeColors.body[3]}
                            for c = 1, 3 do
                                bodyColor[c] = bodyColor[c] + (bodyGold[c] - bodyColor[c]) * t
                            end
                            love.graphics.setColor(bodyColor)
                        else
                            if self.devilPermanent then
                                love.graphics.setColor(self.devilColor)
                            else
                                love.graphics.setColor(self.snakeColors.body)
                            end
                        end
                    end
                end
                love.graphics.rectangle("fill", sx + 1, sy + 1, size - 2, size - 2, 3, 3)
                love.graphics.setColor(0.8, 1.0, 0.5, 0.2)
                love.graphics.rectangle("fill", sx + 3, sy + 3, size - 8, size - 8, 2, 2)
            end
        end
    end

    -- Female snake
    if self.femaleActive and self.femaleSnake then
        for i, seg in ipairs(self.femaleSnake) do
            local sx = boardX + (seg.x - 1) * self.gridSize * scale
            local sy = boardY + (seg.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale

            -- Check if we should skip drawing due to blinking (invincibility OR no collision)
            local shouldSkip = false
            if self.femaleInvincible and not self.blinkVisible then
                shouldSkip = true
            end
            if self.femaleNoCollision and not self.blinkVisible then
                shouldSkip = true
            end
            
            if not shouldSkip then
                if self.femaleGlow then
                    love.graphics.setColor(1.0, 0.4, 0.7, 0.4)
                    love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
                end
                if i == 1 then
                    if self.femaleDevilPermanent then
                        love.graphics.setColor(self.femaleDevilColor)
                    else
                        love.graphics.setColor(self.femaleColor)
                    end
                else
                    if self.femaleDevilPermanent then
                        love.graphics.setColor(self.femaleDevilColor[1] * 0.7, self.femaleDevilColor[2] * 0.7, self.femaleDevilColor[3] * 0.7)
                    else
                        love.graphics.setColor(self.femaleColor[1] * 0.7, self.femaleColor[2] * 0.7, self.femaleColor[3] * 0.7)
                    end
                end
                love.graphics.rectangle("fill", sx + 1, sy + 1, size - 2, size - 2, 3, 3)
                love.graphics.setColor(1.0, 0.7, 0.9, 0.2)
                love.graphics.rectangle("fill", sx + 3, sy + 3, size - 8, size - 8, 2, 2)
            end
        end
    end

    -- IMMORTAL ENDING: golden sparks (unchanged)
    if self.immortalEnding then
        for _, p in ipairs(self.immortalParticles) do
            local alpha = p.life / p.maxLife
            local size = p.size * (1 + (1 - alpha) * 0.5)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.9)
            local px = boardX + (p.x - 1) * self.gridSize * scale + self.gridSize * scale / 2
            local py = boardY + (p.y - 1) * self.gridSize * scale + self.gridSize * scale / 2
            love.graphics.circle("fill", px, py, size * scale)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.3)
            love.graphics.circle("fill", px, py, size * scale * 2.5)
        end
    end

    -- Game Over (unchanged)
    if self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)

        love.graphics.setFont(self.largeFont)
        if self.gameOverMessage then
            love.graphics.setColor(1.0, 0.85, 0.2)
            love.graphics.printf(self.gameOverMessage, boardX, boardY + boardH / 2 - 40, boardW, "center")
        else
            love.graphics.setColor(0.95, 0.35, 0.35)
            love.graphics.printf("GAME OVER", boardX, boardY + boardH / 2 - 40, boardW, "center")
        end

        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press [SPACE] or [R] to Restart", boardX, boardY + boardH / 2 + 6, boardW, "center")
        love.graphics.printf("Final Score: " .. self.score, boardX, boardY + boardH / 2 + 30, boardW, "center")
        love.graphics.printf("Devil's Fruits: " .. self.devilFruitEaten, boardX, boardY + boardH / 2 + 54, boardW, "center")
        if self.femaleActive then
            love.graphics.printf("Mate Count: " .. self.mateCount, boardX, boardY + boardH / 2 + 78, boardW, "center")
        end
    end

    love.graphics.pop()
end


-- ============================================================
-- INPUT HANDLING
-- ============================================================
function SnakeGame:keypressed(key)
    -- Allow restarting even if immortal ending triggered Game Over
    if self.immortalEnding and not self.gameOver then
        return true  -- block movement keys during immortal sequence
    end
	
    if self.gameOver then
        if key == "space" or key == "r" or key == "return" then
            self:reset()
            return true
        end
    end

    if key == "t" then
        self:spawnDebugItems()
        return true
    end

    if key == "up" or key == "w" then
        if self.dir.y == 0 then
            self.nextDir = { x = 0, y = -1 }
            return true
        end
    elseif key == "down" or key == "s" then
        if self.dir.y == 0 then
            self.nextDir = { x = 0, y = 1 }
            return true
        end
    elseif key == "left" or key == "a" then
        if self.dir.x == 0 then
            self.nextDir = { x = -1, y = 0 }
            return true
        end
    elseif key == "right" or key == "d" then
        if self.dir.x == 0 then
            self.nextDir = { x = 1, y = 0 }
            return true
        end
    elseif key == "p" then
        self.paused = not self.paused
        return true
    elseif key == "r" then
        self:reset()
        return true
    end
    return false
end

function SnakeGame:handleSwipe(dx, dy)
    -- Restart game on tap/swipe if game over
    if self.gameOver then
        self:reset()
        return
    end

    local absX = math.abs(dx)
    local absY = math.abs(dy)

    -- Ignore small accidental taps/drags
    if math.max(absX, absY) < self.minSwipeDistance then
        return
    end

    -- Determine primary swipe direction
    if absX > absY then
        if dx > 0 and self.dir.x == 0 then
            self.nextDir = { x = 1, y = 0 }
        elseif dx < 0 and self.dir.x == 0 then
            self.nextDir = { x = -1, y = 0 }
        end
    else
        if dy > 0 and self.dir.y == 0 then
            self.nextDir = { x = 0, y = 1 }
        elseif dy < 0 and self.dir.y == 0 then
            self.nextDir = { x = 0, y = -1 }
        end
    end
end

-- Mouse slide support
function SnakeGame:mousepressed(x, y, button)
    if button == 1 then
        self.swipeStartX = x
        self.swipeStartY = y
        return true
    end
    return false
end

function SnakeGame:mousereleased(x, y, button)
    if button == 1 then
        local dx = x - self.swipeStartX
        local dy = y - self.swipeStartY
        self:handleSwipe(dx, dy)
        return true
    end
    return false
end

-- Mobile touch support
function SnakeGame:touchpressed(id, x, y)
    self.touchMap = self.touchMap or {}
    self.touchMap[id] = { x = x, y = y }
    return true
end

function SnakeGame:touchreleased(id, x, y)
    if self.touchMap and self.touchMap[id] then
        local startPos = self.touchMap[id]
        local dx = x - startPos.x
        local dy = y - startPos.y
        self:handleSwipe(dx, dy)
        self.touchMap[id] = nil
        return true
    end
    return false
end

function SnakeGame:spawnDebugItems()
    self.debugItems = {}
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    
    -- Create a list of all item types (one of each)
    local itemTypes = {
        "food",
        "greenfruit",
        "goldenfruit"
    }
    
    -- Add all power-up types
    for _, ptype in ipairs(self.powerUpTypes) do
        table.insert(itemTypes, ptype)
    end
    
    -- Add forbidden realm foods (types 1-4)
    table.insert(itemTypes, "forbidden_food_1")
    table.insert(itemTypes, "forbidden_food_2")
    table.insert(itemTypes, "forbidden_food_3")
    table.insert(itemTypes, "forbidden_food_4")
    
    -- Shuffle the items
    for i = #itemTypes, 2, -1 do
        local j = math.random(i)
        itemTypes[i], itemTypes[j] = itemTypes[j], itemTypes[i]
    end
    
    -- Collect all free cells
    local freeCells = {}
    for y = 1, rows do
        for x = 1, cols do
            local occupied = false
            for _, seg in ipairs(self.snake) do
                if seg.x == x and seg.y == y then
                    occupied = true
                    break
                end
            end
            if not occupied then
                table.insert(freeCells, {x = x, y = y})
            end
        end
    end
    
    -- Place items on free cells
    local itemsPlaced = 0
    for i, pos in ipairs(freeCells) do
        if i <= #itemTypes then
            local itemType = itemTypes[i]
            -- Check if it's a forbidden food type
            if itemType == "forbidden_food_1" then
                table.insert(self.debugItems, {
                    x = pos.x,
                    y = pos.y,
                    type = "forbidden_food",
                    food_type = 1
                })
            elseif itemType == "forbidden_food_2" then
                table.insert(self.debugItems, {
                    x = pos.x,
                    y = pos.y,
                    type = "forbidden_food",
                    food_type = 2
                })
            elseif itemType == "forbidden_food_3" then
                table.insert(self.debugItems, {
                    x = pos.x,
                    y = pos.y,
                    type = "forbidden_food",
                    food_type = 3
                })
            elseif itemType == "forbidden_food_4" then
                table.insert(self.debugItems, {
                    x = pos.x,
                    y = pos.y,
                    type = "forbidden_food",
                    food_type = 4
                })
            else
                table.insert(self.debugItems, {
                    x = pos.x,
                    y = pos.y,
                    type = itemType
                })
            end
            itemsPlaced = itemsPlaced + 1
        end
    end
    
    print("Placed " .. itemsPlaced .. " debug items (one of each type, including forbidden foods)")
end

return SnakeGame