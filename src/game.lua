-- ============================================================
-- SNAKE PRO - GAMEPLAY ENGINE
-- ============================================================
local Config = require("config")
local Utils = require("utils")
local FemaleSnake = require("female_snake")

local SnakeGame = {}
SnakeGame.__index = SnakeGame

function SnakeGame.new()
    local self = setmetatable({}, SnakeGame)
    self.gridSize = Config.gridSize
    self.cols = Config.cols
    self.rows = Config.rows
    self.forbiddenCols = Config.forbiddenCols
    self.forbiddenRows = Config.forbiddenRows

    self.width = Config.windowWidth
    self.height = Config.windowHeight
    self.score = 0
    self.highScore = Utils.loadHighScore()
    self.gameOver = false
    self.paused = false
    self.timer = 0
    self.baseSpeed = Config.baseSpeed
    self.speed = self.baseSpeed
    self.tempSpeedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.lives = Config.initialLives
    self.maxLives = Config.maxLives

    -- Swipe & Touch State
    self.swipeStartX = 0
    self.swipeStartY = 0
    self.minSwipeDistance = 20
    self.touchMap = {}

    -- Snake Color Palette & Transitions
    self.snakeColors = {
        head = {Config.colors.snakeHead[1], Config.colors.snakeHead[2], Config.colors.snakeHead[3]},
        body = {Config.colors.snakeBody[1], Config.colors.snakeBody[2], Config.colors.snakeBody[3]}
    }
    self.targetHeadColor = {Config.colors.snakeHead[1], Config.colors.snakeHead[2], Config.colors.snakeHead[3]}
    self.targetBodyColor = {Config.colors.snakeBody[1], Config.colors.snakeBody[2], Config.colors.snakeBody[3]}
    self.colorChangeTimer = 0

    -- Buffs & Statuses
    self.invincible = false
    self.invincibleTimer = 0
    self.invincibleDuration = Config.invincibleDuration
    self.blinkTimer = 0
    self.blinkVisible = true

    self.noCollision = false
    self.noCollisionTimer = 0
    self.noCollisionDuration = Config.noCollisionDuration

    self.glowActive = false
    self.glowTimer = 0
    self.glowDuration = Config.glowDuration

    self.rainbowActive = false
    self.rainbowTimer = 0
    self.rainbowDuration = Config.rainbowDuration

    self.lustActive = false
    self.lustTimer = 0
    self.lustDuration = Config.lustDuration
    self.lustMultiplier = Config.lustMultiplier

    self.devilPermanent = false
    self.devilColor = Config.colors.devilSkin
    self.devilFruitEaten = 0

    self.whiteholeActive = false
    self.whiteholeTimer = 0
    self.blackholeActive = false
    self.blackholeTimer = 0
    self.effectDuration = Config.holeEffectDuration

    self.fourthWallActive = false
    self.fourthWallTimer = 0
    self.fourthWallDuration = Config.fourthWallDuration
    self.outsideTimer = 0
    self.outsideMax = Config.fourthWallMaxOutside

    self.fifthWallActive = false
    self.fifthWallTimer = 0
    self.fifthWallDuration = Config.fifthWallDuration
    self.externalWindows = {}

    -- Forbidden Realm
    self.inForbiddenRealm = false
    self.forbiddenTimer = 0
    self.forbiddenDuration = Config.forbiddenDuration
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}

    -- Items & Spawners
    self.food = nil
    self.powerUp = nil
    self.powerUpTimer = 0
    self.powerUpSpawnInterval = Config.powerUpSpawnInterval
    self.powerUpSpawnTimer = 0

    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.greenFruitDuration = Config.greenFruitDuration
    self.greenFruitSpawnInterval = Config.greenFruitSpawnInterval
    self.greenFruitSpawnTimer = 0

    self.goldenFruit = nil
    self.goldenFruitTimer = 0
    self.goldenFruitDuration = Config.goldenFruitDuration
    self.goldenFruitSpawnInterval = Config.goldenFruitSpawnInterval
    self.goldenFruitSpawnTimer = 0

    self.debugItems = {}

    -- AI Female Snake
    self.female = FemaleSnake.new()
    self.matingCooldown = 0
    self.matingCooldownMax = Config.matingCooldownMax
    self.mateCount = 0
    self.matingFreeze = false
    self.matingFreezeTimer = 0
    self.shakeAmount = 0

    -- Immortal Ending Sequence
    self.immortalEnding = false
    self.immortalTimer = 0
    self.immortalProgress = 0
    self.immortalSpeed = 0
    self.immortalParticles = {}
    self.immortalRemovedTiles = {}
    self.immortalSnakePositions = {}
    self.immortalSegmentIndex = 0
    self.immortalColor = Config.colors.immortalGold
    self.gameOverMessage = nil
    self.immortalFlash = 0
    self.immortalShake = 0

    -- Fonts
    self.font = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 13) or love.graphics.newFont(13)
    self.largeFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 20) or love.graphics.newFont(20)
    self.smallFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 10) or love.graphics.newFont(10)

    self:reset()
    return self
end

function SnakeGame:reset()
    self.snake = {
        {x = 10, y = 10},
        {x = 9, y = 10},
        {x = 8, y = 10}
    }
    self.dir = {x = 1, y = 0}
    self.nextDir = {x = 1, y = 0}
    self.gameOver = false
    self.gameOverMessage = nil
    self.score = 0
    self.lives = Config.initialLives
    self.baseSpeed = Config.baseSpeed
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

    self.fifthWallActive = false
    self.fifthWallTimer = 0
    self:destroyExternalWindows()

    self.debugItems = {}
    self.greenFruit = nil
    self.greenFruitTimer = 0
    self.greenFruitSpawnTimer = 0
    self.goldenFruit = nil
    self.goldenFruitTimer = 0
    self.goldenFruitSpawnTimer = 0

    -- Reset Female
    self.female:reset()
    self.matingCooldown = 0
    self.mateCount = 0
    self.matingFreeze = false
    self.matingFreezeTimer = 0
    self.shakeAmount = 0

    -- Reset Immortal Ending
    self.immortalEnding = false
    self.immortalTimer = 0
    self.immortalProgress = 0
    self.immortalSpeed = 0
    self.immortalParticles = {}
    self.immortalRemovedTiles = {}
    self.immortalSnakePositions = {}
    self.immortalSegmentIndex = 0
    self.immortalFlash = 0
    self.immortalShake = 0

    self.targetHeadColor = {Config.colors.snakeHead[1], Config.colors.snakeHead[2], Config.colors.snakeHead[3]}
    self.targetBodyColor = {Config.colors.snakeBody[1], Config.colors.snakeBody[2], Config.colors.snakeBody[3]}
    self.snakeColors.head = {Config.colors.snakeHead[1], Config.colors.snakeHead[2], Config.colors.snakeHead[3]}
    self.snakeColors.body = {Config.colors.snakeBody[1], Config.colors.snakeBody[2], Config.colors.snakeBody[3]}

    self:spawnFood()
    self.highScore = Utils.loadHighScore()
end

function SnakeGame:addScore(points)
    self.score = self.score + points
    if self.score > self.highScore then
        self.highScore = self.score
    end
end

function SnakeGame:updateBaseSpeed()
    self.baseSpeed = math.max(Config.minSpeed, Config.baseSpeed - math.floor(self.score / 50) * 0.01)
    self.speed = self.baseSpeed
end

-- ============================================================
-- ITEM SPAWNING
-- ============================================================
function SnakeGame:getFreeCells()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    return Utils.findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, self.female.body, self.debugItems)
end

function SnakeGame:spawnFood()
    local free = self:getFreeCells()
    if #free > 0 then
        self.food = free[math.random(1, #free)]
    else
        self.food = {x = 1, y = 1}
    end
end

function SnakeGame:spawnPowerUp()
    local free = self:getFreeCells()
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        local typeIdx = math.random(1, #Config.powerUpTypes)
        if Config.powerUpTypes[typeIdx] == "devilfruit" and math.random() > 0.25 then
            typeIdx = math.random(1, #Config.powerUpTypes - 2)
        end
        if Config.powerUpTypes[typeIdx] == "mate" and math.random() > 0.25 then
            typeIdx = math.random(1, #Config.powerUpTypes - 2)
        end
        self.powerUp = {
            x = pos.x,
            y = pos.y,
            type = Config.powerUpTypes[typeIdx],
            timer = Config.powerUpDuration,
            blink = 0
        }
        self.powerUpTimer = Config.powerUpDuration
    end
end

function SnakeGame:spawnGreenFruit()
    local free = self:getFreeCells()
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
    local free = self:getFreeCells()
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

function SnakeGame:spawnForbiddenFood()
    local free = self:getFreeCells()
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        local ftype = math.random(1, 4)
        table.insert(self.forbiddenFoods, {x = pos.x, y = pos.y, type = ftype})
    end
end

-- ============================================================
-- SPECIAL MECHANICS & EFFECTS
-- ============================================================
function SnakeGame:enterForbiddenRealm()
    self.inForbiddenRealm = true
    self.forbiddenTimer = self.forbiddenDuration
    self.forbiddenFoods = {}
    self.food = nil
    self.powerUp = nil
    self.greenFruit = nil
    self.goldenFruit = nil
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
    self:spawnFood()
end

function SnakeGame:teleportSnake()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local free = self:getFreeCells()
    if #free == 0 then return end

    local newHead = free[math.random(1, #free)]
    local oldHead = self.snake[1]
    local offsetX = newHead.x - oldHead.x
    local offsetY = newHead.y - oldHead.y

    for _, seg in ipairs(self.snake) do
        seg.x = seg.x + offsetX
        seg.y = seg.y + offsetY
        while seg.x < 1 do seg.x = seg.x + cols end
        while seg.x > cols do seg.x = seg.x - cols end
        while seg.y < 1 do seg.y = seg.y + rows end
        while seg.y > rows do seg.y = seg.y - rows end
    end
end

function SnakeGame:triggerMating()
    self.mateCount = self.mateCount + 1
    local bonus = 100 + self.mateCount * 50
    self:addScore(bonus)
    self.matingCooldown = self.matingCooldownMax
    Utils.playSFX("levelup", 1.5, 0.8)
    Utils.notify("Snake", "Mating success! +" .. bonus .. " points!", nil, 2.0)

    self.matingFreeze = true
    self.matingFreezeTimer = 0.5
    self.shakeAmount = 4
    self.tempSpeedMultiplier = 0.7
    self.tempSpeedTimer = 3.0
    self.female.speedMultiplier = 0.7
    self.female.tempSpeedTimer = 3.0
end

function SnakeGame:applyPowerUp(powerUp)
    local ptype = powerUp.type
    if ptype == "shorten" then
        for i = 1, 3 do if #self.snake > 3 then table.remove(self.snake) end end
        Utils.playSFX("tick", 1.2, 0.3)
    elseif ptype == "reverse" then
        local reversed = {}
        for i = #self.snake, 1, -1 do table.insert(reversed, self.snake[i]) end
        self.snake = reversed
        self.dir = {x = -self.dir.x, y = -self.dir.y}
        self.nextDir = {x = self.dir.x, y = self.dir.y}
        Utils.playSFX("tick", 0.8, 0.3)
    elseif ptype == "speedup" then
        self.tempSpeedMultiplier = self.tempSpeedMultiplier + 0.8
        self.tempSpeedTimer = 4.0
        Utils.playSFX("tick", 1.8, 0.3)
    elseif ptype == "slowdown" then
        self.tempSpeedMultiplier = 0.5
        self.tempSpeedTimer = 4.0
        Utils.playSFX("tick", 0.6, 0.3)
    elseif ptype == "extralife" then
        if self.lives < self.maxLives then self.lives = self.lives + 1 end
        Utils.playSFX("levelup", 1.2, 0.5)
    elseif ptype == "scoreboost" then
        self:addScore(50)
        Utils.playSFX("task_complete", 1.0, 0.5)
    elseif ptype == "colorchange" then
        self.devilPermanent = false
        self.targetHeadColor = Utils.randomColor()
        self.targetBodyColor = Utils.randomColor()
        self.colorChangeTimer = 1.0
        Utils.playSFX("tick", 1.5, 0.3)
    elseif ptype == "devilfruit" then
        self:addScore(100)
        self.devilFruitEaten = self.devilFruitEaten + 1
        self.devilPermanent = true
        self.targetHeadColor = self.devilColor
        self.targetBodyColor = self.devilColor
        self.colorChangeTimer = 1.0
        self.tempSpeedMultiplier = 1.5
        self.tempSpeedTimer = 3.0
        Utils.playSFX("levelup", 1.5, 0.8)
    elseif ptype == "lustfood" then
        self.lustActive = true
        self.lustTimer = self.lustDuration
        Utils.playSFX("task_complete", 1.2, 0.5)
    elseif ptype == "nocollision" then
        self.noCollision = true
        self.noCollisionTimer = self.noCollisionDuration
        Utils.playSFX("tick", 1.8, 0.3)
    elseif ptype == "forbidden" then
        self:enterForbiddenRealm()
        Utils.playSFX("levelup", 1.0, 0.8)
    elseif ptype == "mate" then
        if not self.female.active then
            local free = self:getFreeCells()
            self.female:spawn(free, self.snake[1], self.inForbiddenRealm, self.forbiddenCols, self.forbiddenRows)
        else
            self.female.timer = math.min(self.female.timer + 30, 600)
            self:addScore(50)
            Utils.notify("Snake", "Female time extended!", nil, 2.0)
        end
        Utils.playSFX("levelup", 1.2, 0.5)
    elseif ptype == "rainbow" then
        self.rainbowActive = true
        self.rainbowTimer = self.rainbowDuration
        Utils.playSFX("levelup", 1.3, 0.6)
    elseif ptype == "wormhole" then
        self:teleportSnake()
        Utils.playSFX("levelup", 1.0, 0.7)
    elseif ptype == "whitehole" then
        self.whiteholeActive = true
        self.whiteholeTimer = self.effectDuration
        Utils.playSFX("levelup", 1.0, 0.5)
    elseif ptype == "blackhole" then
        self.blackholeActive = true
        self.blackholeTimer = self.effectDuration
        Utils.playSFX("levelup", 1.0, 0.5)
    elseif ptype == "fourthwall" then
        self.fourthWallActive = true
        self.fourthWallTimer = self.fourthWallDuration
        self.outsideTimer = 0
        Utils.playSFX("levelup", 1.0, 0.7)
        Utils.notify("Snake", "4TH WALL BREAK! You can leave the grid!", nil, 2.0)
    elseif ptype == "fifthwall" then
        self.fifthWallActive = true
        self.fifthWallTimer = self.fifthWallDuration
        self.outsideTimer = 0
        Utils.playSFX("levelup", 1.0, 0.7)
        Utils.notify("Snake", "5TH WALL BREAK! The snake escapes the window!", nil, 2.0)
    end
end

function SnakeGame:applyGoldenFruit(fruit)
    fruit = fruit or self.goldenFruit
    if not fruit then return end
    local ftype = fruit.type
    if ftype == 1 then
        self.lives = math.min(self.lives + 1, self.maxLives)
        Utils.notify("Snake", "GOLDEN FRUIT! Extra life!", nil, 2.0)
    elseif ftype == 2 then
        self:addScore(500)
        Utils.notify("Snake", "GOLDEN FRUIT! +500 points!", nil, 2.0)
    else
        self.invincible = true
        self.invincibleTimer = 5.0
        Utils.notify("Snake", "GOLDEN FRUIT! Invincibility!", nil, 2.0)
    end
    Utils.playSFX("levelup", 2.0, 0.9)
end

function SnakeGame:revive()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self.gameOver = true
        self.gameOverMessage = "Game Over"
        Utils.saveHighScore(self.highScore)
        Utils.playSFX("glitch", 1.2, 0.4)
        return false
    end
    self.invincible = true
    self.invincibleTimer = self.invincibleDuration
    self.blinkTimer = 0
    self.blinkVisible = true
    while #self.snake > 3 do table.remove(self.snake) end
    if #self.snake > 1 then
        local head = self.snake[1]
        local nextSeg = self.snake[2]
        self.dir = {x = head.x - nextSeg.x, y = head.y - nextSeg.y}
        self.nextDir = {x = self.dir.x, y = self.dir.y}
    else
        self.dir = {x = 1, y = 0}
        self.nextDir = {x = 1, y = 0}
    end

    self.devilPermanent = false
    self.targetHeadColor = {Config.colors.snakeHead[1], Config.colors.snakeHead[2], Config.colors.snakeHead[3]}
    self.targetBodyColor = {Config.colors.snakeBody[1], Config.colors.snakeBody[2], Config.colors.snakeBody[3]}
    self.snakeColors.head = {Config.colors.snakeHead[1], Config.colors.snakeHead[2], Config.colors.snakeHead[3]}
    self.snakeColors.body = {Config.colors.snakeBody[1], Config.colors.snakeBody[2], Config.colors.snakeBody[3]}
    self.colorChangeTimer = 0
    self:spawnFood()
    self.powerUp = nil
    Utils.playSFX("levelup", 0.8, 0.5)
    return true
end

function SnakeGame:handleDeath()
    self:revive()
end

-- ============================================================
-- IMMORTAL ENDING
-- ============================================================
function SnakeGame:startImmortalEnding()
    self.food = nil
    self.powerUp = nil
    self.greenFruit = nil
    self.goldenFruit = nil
    self.forbiddenFoods = {}
    self.debugItems = {}
    self.powerUpTimer = 0
    self.greenFruitTimer = 0
    self.female:reset()

    self.immortalEnding = true
    self.immortalTimer = 0
    self.immortalProgress = 0
    self.immortalSpeed = self.speed
    self.immortalSegmentIndex = #self.snake

    self.immortalSnakePositions = {}
    for _, seg in ipairs(self.snake) do
        table.insert(self.immortalSnakePositions, {x = seg.x, y = seg.y})
    end
    self.immortalRemovedTiles = {}
    self.immortalParticles = {}
    self.immortalFlash = 0.5
    self.immortalShake = 10

    Utils.playSFX("levelup", 2.0, 0.9)
    Utils.notify("Snake", "Ascending to immortality...", nil, 1.5)
end

function SnakeGame:updateImmortalEnding(dt)
    self.immortalTimer = self.immortalTimer + dt
    self.immortalFlash = math.max(0, self.immortalFlash - dt)
    self.immortalShake = self.immortalShake * 0.98

    if not self.gameOver then
        if self.immortalTimer < 3.0 then
            self.immortalProgress = self.immortalTimer / 3.0
        else
            self.immortalProgress = 1.0
            for _, pos in ipairs(self.immortalSnakePositions) do
                table.insert(self.immortalRemovedTiles, {x = pos.x, y = pos.y})
            end

            while #self.snake > 0 do
                local tail = table.remove(self.snake)
                for i = 1, 15 do
                    local angle = math.random() * 2 * math.pi
                    local spd = math.random() * 100 + 50
                    local life = math.random() * 0.6 + 0.2
                    table.insert(self.immortalParticles, {
                        x = tail.x, y = tail.y,
                        vx = math.cos(angle) * spd,
                        vy = math.sin(angle) * spd - 20,
                        life = life, maxLife = life,
                        size = math.random() * 4 + 2,
                        color = {1.0, 0.85, 0.2, 0.9}
                    })
                end
            end

            self.immortalFlash = 1.5
            self.gameOver = true
            self.gameOverMessage = "SNAKE BECAME IMMORTAL"
            Utils.saveHighScore(self.highScore)
            Utils.playSFX("glitch", 0.8, 0.4)
        end
    end

    for i = #self.immortalParticles, 1, -1 do
        local p = self.immortalParticles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 30 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(self.immortalParticles, i) end
    end
end

-- ============================================================
-- 5TH WALL SDL2 DESKTOP BREAKOUT
-- ============================================================
function SnakeGame:destroyExternalWindows()
    if not _G.sdl then return end
    for _, winData in pairs(self.externalWindows) do
        _G.sdl.SDL_DestroyWindow(winData.window)
    end
    self.externalWindows = {}
end

function SnakeGame:updateExternalWindows(scale, boardX, boardY)
    if not _G.sdl then return end
    if not self.fifthWallActive then
        if next(self.externalWindows) then self:destroyExternalWindows() end
        return
    end

    local ffi = require("ffi")
    local bit = require("bit")
    local mainWinX, mainWinY = love.window.getPosition()
    local size = self.gridSize * scale
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local currentOutside = {}

    for i, seg in ipairs(self.snake) do
        local isOutside = (seg.x < 1 or seg.x > cols or seg.y < 1 or seg.y > rows)
        if isOutside then
            local segKey = tostring(seg.x) .. "_" .. tostring(seg.y)
            currentOutside[segKey] = true

            local absX = mainWinX + boardX + (seg.x - 1) * size
            local absY = mainWinY + boardY + (seg.y - 1) * size

            if not self.externalWindows[segKey] then
                local flags = bit.bor(0x00000010, 0x00008000)
                local win = _G.sdl.SDL_CreateWindow("SnakeSegment", absX, absY, size, size, flags)
                self.externalWindows[segKey] = {window = win, x = absX, y = absY}
            else
                local winData = self.externalWindows[segKey]
                if winData.x ~= absX or winData.y ~= absY then
                    _G.sdl.SDL_SetWindowPosition(winData.window, absX, absY)
                    winData.x = absX
                    winData.y = absY
                end
            end

            local winData = self.externalWindows[segKey]
            local surface = _G.sdl.SDL_GetWindowSurface(winData.window)
            local shouldSkip = (self.invincible or self.noCollision) and not self.blinkVisible

            if shouldSkip then
                _G.sdl.SDL_FillRect(surface, nil, 0x00000000)
            else
                local drawColor = {self.snakeColors.head[1], self.snakeColors.head[2], self.snakeColors.head[3]}
                if self.immortalEnding then
                    local t = self.immortalProgress
                    local gold = {0.9, 0.75, 0.2}
                    for c = 1, 3 do drawColor[c] = drawColor[c] + (gold[c] - drawColor[c]) * t end
                end

                if self.rainbowActive then
                    local hue = (i - 1) / #self.snake
                    local r, g, b = Utils.hsvToRgb(hue, 1.0, 1.0)
                    drawColor = {r, g, b}
                else
                    if i == 1 then
                        if self.devilPermanent then drawColor = self.devilColor end
                    else
                        if self.immortalEnding then
                            local t = self.immortalProgress
                            local bodyGold = {0.7, 0.55, 0.15}
                            local bodyColor = {self.snakeColors.body[1], self.snakeColors.body[2], self.snakeColors.body[3]}
                            for c = 1, 3 do bodyColor[c] = bodyColor[c] + (bodyGold[c] - bodyColor[c]) * t end
                            drawColor = bodyColor
                        else
                            drawColor = self.devilPermanent and self.devilColor or self.snakeColors.body
                        end
                    end
                end

                local bgCol = self.inForbiddenRealm and 0xFF080010 or 0xFF030303
                _G.sdl.SDL_FillRect(surface, nil, bgCol)

                if self.glowActive then
                    _G.sdl.SDL_FillRect(surface, nil, 0xFF80FF4C)
                end

                local mainRect = ffi.new("SDL_Rect", {x = 1, y = 1, w = size - 2, h = size - 2})
                _G.sdl.SDL_FillRect(surface, mainRect, Utils.toUintColor(drawColor))

                local hlColor = {math.min(1, drawColor[1] + 0.2), math.min(1, drawColor[2] + 0.2), math.min(1, drawColor[3] + 0.2)}
                local highlightRect = ffi.new("SDL_Rect", {x = 3, y = 3, w = math.max(1, size - 8), h = math.max(1, size - 8)})
                _G.sdl.SDL_FillRect(surface, highlightRect, Utils.toUintColor(hlColor))
            end

            _G.sdl.SDL_UpdateWindowSurface(winData.window)
        end
    end

    for key, winData in pairs(self.externalWindows) do
        if not currentOutside[key] then
            _G.sdl.SDL_DestroyWindow(winData.window)
            self.externalWindows[key] = nil
        end
    end
end

-- ============================================================
-- MAIN GAME UPDATE
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
    if self.fifthWallActive then
        self.fifthWallTimer = self.fifthWallTimer - dt
        if self.fifthWallTimer <= 0 then
            self.fifthWallActive = false
            self.outsideTimer = 0
        end
    end
    if self.fourthWallActive then
        self.fourthWallTimer = self.fourthWallTimer - dt
        if self.fourthWallTimer <= 0 then
            self.fourthWallActive = false
            self.outsideTimer = 0
        end
    end

    -- Whitehole physics (repel items)
    if self.whiteholeActive then
        self.whiteholeTimer = self.whiteholeTimer - dt
        if self.whiteholeTimer <= 0 then self.whiteholeActive = false end
        local head = self.snake[1]
        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local function repelItem(item)
            if item then
                local dx = item.x - head.x
                local dy = item.y - head.y
                local dist = math.abs(dx) + math.abs(dy)
                if dist > 1 then
                    local nx = item.x + (math.abs(dx) >= math.abs(dy) and (dx > 0 and 1 or -1) or 0)
                    local ny = item.y + (math.abs(dx) < math.abs(dy) and (dy > 0 and 1 or -1) or 0)
                    nx = math.max(1, math.min(cols, nx))
                    ny = math.max(1, math.min(rows, ny))
                    if Utils.isEmptyCell(nx, ny, self.snake, self.female.body, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, self.debugItems, item) then
                        item.x = nx
                        item.y = ny
                    end
                end
            end
        end

        repelItem(self.food)
        repelItem(self.powerUp)
        repelItem(self.greenFruit)
        repelItem(self.goldenFruit)
        if self.inForbiddenRealm then
            for _, f in ipairs(self.forbiddenFoods) do repelItem(f) end
        end
    end

    -- Blackhole physics (attract items)
    if self.blackholeActive then
        self.blackholeTimer = self.blackholeTimer - dt
        if self.blackholeTimer <= 0 then self.blackholeActive = false end
        local head = self.snake[1]
        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local function attractItem(item)
            if item then
                local dx = head.x - item.x
                local dy = head.y - item.y
                local nx = item.x + (math.abs(dx) >= math.abs(dy) and (dx > 0 and 1 or -1) or 0)
                local ny = item.y + (math.abs(dx) < math.abs(dy) and (dy > 0 and 1 or -1) or 0)
                nx = math.max(1, math.min(cols, nx))
                ny = math.max(1, math.min(rows, ny))
                if Utils.isEmptyCell(nx, ny, self.snake, self.female.body, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, self.debugItems, item) then
                    item.x = nx
                    item.y = ny
                end
            end
        end

        attractItem(self.food)
        attractItem(self.powerUp)
        attractItem(self.greenFruit)
        attractItem(self.goldenFruit)
        if self.inForbiddenRealm then
            for _, f in ipairs(self.forbiddenFoods) do attractItem(f) end
        end
    end

    -- Blinking
    local shouldBlink = self.invincible or self.noCollision or self.female.invincible or self.female.noCollision
    if shouldBlink then
        self.blinkTimer = self.blinkTimer + dt
        if self.blinkTimer > 0.1 then
            self.blinkTimer = 0
            self.blinkVisible = not self.blinkVisible
        end
    else
        self.blinkVisible = true
    end

    if self.invincible then
        self.invincibleTimer = self.invincibleTimer - dt
        if self.invincibleTimer <= 0 then self.invincible = false end
    end
    if self.noCollision then
        self.noCollisionTimer = self.noCollisionTimer - dt
        if self.noCollisionTimer <= 0 then self.noCollision = false end
    end
    if self.lustActive then
        self.lustTimer = self.lustTimer - dt
        if self.lustTimer <= 0 then self.lustActive = false end
    end
    if self.colorChangeTimer > 0 then
        self.colorChangeTimer = self.colorChangeTimer - dt
        local t = 1 - self.colorChangeTimer
        self.snakeColors.head = Utils.lerpColor(self.snakeColors.head, self.targetHeadColor, t * 0.05)
        self.snakeColors.body = Utils.lerpColor(self.snakeColors.body, self.targetBodyColor, t * 0.05)
    end
    if self.tempSpeedTimer > 0 then
        self.tempSpeedTimer = self.tempSpeedTimer - dt
        if self.tempSpeedTimer <= 0 then self.tempSpeedMultiplier = 1.0 end
    end

    -- Realm Timers & Spawners
    if self.inForbiddenRealm then
        self.forbiddenTimer = self.forbiddenTimer - dt
        if self.forbiddenTimer <= 0 then
            self:exitForbiddenRealm()
            if self.female.active and self.female.inForbidden then
                self.female.inForbidden = false
                self.female.forbiddenTimer = 0
            end
        end
        while #self.forbiddenFoods < 15 do self:spawnForbiddenFood() end
    else
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

    -- Update AI Female Snake
    self.female:update(dt, self)

    -- Player Movement
    self.timer = self.timer + dt
    local currentSpeed = self.speed * (1 / self.tempSpeedMultiplier)

    if self.timer >= currentSpeed then
        self.timer = 0
        self.dir = {x = self.nextDir.x, y = self.nextDir.y}

        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local head = self.snake[1]
        local newHead = {x = head.x + self.dir.x, y = head.y + self.dir.y}

        local outside = false
        if not (self.fourthWallActive or self.fifthWallActive) then
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

        -- Collision: Tail (Immortal Ending) vs Body (Revive/Death)
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

        if self.fourthWallActive and not self.fifthWallActive and outside then
            self.outsideTimer = self.outsideTimer + dt
            if self.outsideTimer >= self.outsideMax then
                self.gameOver = true
                self.gameOverMessage = "Lost in the void"
                Utils.saveHighScore(self.highScore)
                Utils.playSFX("glitch", 1.2, 0.4)
                return
            end
        end

        table.insert(self.snake, 1, newHead)

        local ate = false
        if not self.inForbiddenRealm then
            if self.food and newHead.x == self.food.x and newHead.y == self.food.y then
                local pts = 10 * (self.lustActive and self.lustMultiplier or 1)
                self:addScore(pts)
                self:updateBaseSpeed()
                Utils.playSFX("tick", 1.5, 0.5)
                self:spawnFood()
                ate = true
            end
            if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                self:applyPowerUp(self.powerUp)
                self.powerUp = nil
                ate = true
            end
            if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                self:addScore(200)
                self.glowActive = true
                self.glowTimer = self.glowDuration
                self.greenFruit = nil
                self.greenFruitTimer = 0
                Utils.playSFX("levelup", 1.8, 0.8)
                Utils.notify("Snake", "LIME GREEN FRUIT! +200 points and glow!", nil, 2.0)
                ate = true
            end
            if self.goldenFruit and newHead.x == self.goldenFruit.x and newHead.y == self.goldenFruit.y then
                self:applyGoldenFruit(self.goldenFruit)
                self.goldenFruit = nil
                self.goldenFruitTimer = 0
                ate = true
            end
            for i = #self.debugItems, 1, -1 do
                local item = self.debugItems[i]
                if newHead.x == item.x and newHead.y == item.y then
                    if item.type == "food" then
                        self:addScore(10)
                        Utils.playSFX("tick", 1.5, 0.5)
                    elseif item.type == "greenfruit" then
                        self:addScore(200)
                        self.glowActive = true
                        self.glowTimer = self.glowDuration
                        Utils.playSFX("levelup", 1.8, 0.8)
                    elseif item.type == "goldenfruit" then
                        self:applyGoldenFruit(item)
                    elseif item.type == "forbidden_food" then
                        local ftype = item.food_type or 1
                        if ftype == 4 then
                            self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                            Utils.playSFX("levelup", 1.0, 0.6)
                            Utils.notify("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                        else
                            local pts = (ftype == 1 and 15 or (ftype == 2 and 30 or 50)) * (self.lustActive and self.lustMultiplier or 1)
                            self:addScore(pts)
                            Utils.playSFX("tick", 1.5 + ftype * 0.2, 0.5)
                        end
                    else
                        self:applyPowerUp(item)
                    end
                    table.remove(self.debugItems, i)
                    ate = true
                end
            end
        else
            for i = #self.forbiddenFoods, 1, -1 do
                local f = self.forbiddenFoods[i]
                if newHead.x == f.x and newHead.y == f.y then
                    if f.type == 4 then
                        self.forbiddenTimer = math.min(self.forbiddenTimer + 2.0, 12.0)
                        Utils.playSFX("levelup", 1.0, 0.6)
                        Utils.notify("Snake", "+2s in Forbidden Realm!", nil, 1.5)
                    else
                        local pts = (f.type == 1 and 15 or (f.type == 2 and 30 or 50)) * (self.lustActive and self.lustMultiplier or 1)
                        self:addScore(pts)
                        Utils.playSFX("tick", 1.5 + f.type * 0.2, 0.5)
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

        if self.female.active and self.female.body and self.female.body[1] then
            local fHead = self.female.body[1]
            if newHead.x == fHead.x and newHead.y == fHead.y and self.matingCooldown <= 0 then
                self:triggerMating()
            end
        end
    end
end

-- ============================================================
-- DRAWING & HUD
-- ============================================================
function SnakeGame:draw(x, y, width, height)
    self.width = width
    self.height = height

    love.graphics.push()
    love.graphics.translate(x, y)

    if self.immortalShake and self.immortalShake > 0.29 then
        local ox = math.random(-self.immortalShake, self.immortalShake)
        local oy = math.random(-self.immortalShake, self.immortalShake)
        love.graphics.translate(ox, oy)
    end

    if self.shakeAmount > 0 then
        local ox = math.random(-self.shakeAmount, self.shakeAmount)
        local oy = math.random(-self.shakeAmount, self.shakeAmount)
        love.graphics.translate(ox, oy)
    end

    -- Background
    if self.inForbiddenRealm then
        love.graphics.setColor(0.06, 0.01, 0.09)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(0.2, 0.05, 0.3, 0.2)
        for i = 1, 5 do
            love.graphics.rectangle("fill", math.random(0, width), math.random(0, height), math.random(10, 40), math.random(2, 6))
        end
    else
        love.graphics.setColor(0.02, 0.02, 0.02)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end

    -- Header Bar
    local barH = 52
    love.graphics.setColor(self.inForbiddenRealm and {0.12, 0.04, 0.18} or {0.06, 0.06, 0.06})
    love.graphics.rectangle("fill", 0, 0, width, barH)

    -- Row 1: Scores & Lives
    love.graphics.setFont(self.font)
    love.graphics.setColor(0.35, 0.75, 1.0)
    love.graphics.print("SCORE: " .. tostring(self.score), 10, 6)

    love.graphics.setColor(0.85, 0.75, 0.3)
    love.graphics.print("HIGH: " .. tostring(self.highScore), 130, 6)

    local rightX = width - 10
    love.graphics.setColor(0.9, 0.3, 0.3)
    for i = 1, self.lives do
        love.graphics.circle("fill", rightX - (self.lives - i) * 14, 10, 4)
    end
    rightX = rightX - self.lives * 14 - 6

    if self.female.active then
        love.graphics.setColor(1.0, 0.4, 0.7)
        for i = 1, self.female.lives do
            love.graphics.circle("fill", rightX - (self.female.lives - i) * 14, 10, 4)
        end
        rightX = rightX - self.female.lives * 14 - 6

        local mins = math.floor(self.female.timer / 60)
        local secs = math.floor(self.female.timer % 60)
        love.graphics.setFont(self.smallFont)
        love.graphics.print(string.format("F:%02d:%02d", mins, secs), rightX - 55, 8)
    end

    -- Row 2: Status Badges
    love.graphics.setFont(self.smallFont)
    local statusX = 10
    local statusY = 28
    local statuses = {}

    if self.noCollision then statuses[#statuses+1] = {text = "NC", color = {0.2, 0.8, 0.9}} end
    if self.lustActive then statuses[#statuses+1] = {text = "LUST", color = {0.9, 0.2, 0.5}} end
    if self.invincible then statuses[#statuses+1] = {text = "INV", color = {1.0, 0.8, 0.2}} end
    if self.inForbiddenRealm then statuses[#statuses+1] = {text = "FR", color = {0.8, 0.3, 0.9}} end
    if self.glowActive then statuses[#statuses+1] = {text = "GLOW", color = {0.5, 1.0, 0.3}} end
    if self.rainbowActive then statuses[#statuses+1] = {text = "RB", color = {0.9, 0.1, 0.8}} end
    if self.whiteholeActive then statuses[#statuses+1] = {text = "WH", color = {1.0, 1.0, 1.0}} end
    if self.blackholeActive then statuses[#statuses+1] = {text = "BH", color = {0.2, 0.2, 0.2}} end
    if self.fourthWallActive then statuses[#statuses+1] = {text = "4W", color = {0.0, 0.8, 0.8}} end
    if self.fifthWallActive then statuses[#statuses+1] = {text = "5W", color = {0.0, 1.0, 0.0}} end
    if self.devilPermanent then statuses[#statuses+1] = {text = "DEVIL", color = {0.9, 0.1, 0.1}} end

    for _, st in ipairs(statuses) do
        love.graphics.setColor(st.color)
        love.graphics.print(st.text, statusX, statusY)
        statusX = statusX + love.graphics.getFont():getWidth(st.text) + 6
    end

    -- Board Geometry & Scale
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

    -- Board Background & Grid
    love.graphics.setColor(self.inForbiddenRealm and {0.03, 0.0, 0.06} or {0.01, 0.01, 0.01})
    love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)

    love.graphics.setColor(self.inForbiddenRealm and {0.35, 0.1, 0.45} or {0.15, 0.15, 0.15})
    love.graphics.rectangle("line", boardX, boardY, boardW, boardH)

    love.graphics.setColor(self.inForbiddenRealm and {0.15, 0.03, 0.2} or {0.1, 0.1, 0.1})
    for r = 1, rows - 1 do
        love.graphics.line(boardX, boardY + r * self.gridSize * scale, boardX + boardW, boardY + r * self.gridSize * scale)
    end
    for c = 1, cols - 1 do
        love.graphics.line(boardX + c * self.gridSize * scale, boardY, boardX + c * self.gridSize * scale, boardY + boardH)
    end

    -- Removed Void Tiles (Immortal Ending)
    if self.immortalEnding then
        for _, tile in ipairs(self.immortalRemovedTiles) do
            local tx = boardX + (tile.x - 1) * self.gridSize * scale
            local ty = boardY + (tile.y - 1) * self.gridSize * scale
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.rectangle("fill", tx, ty, self.gridSize * scale, self.gridSize * scale)
        end
    end

    -- Normal Food
    if self.food and not self.inForbiddenRealm then
        local fx = boardX + (self.food.x - 1) * self.gridSize * scale
        local fy = boardY + (self.food.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local col = Config.colors.food
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", fx + 2, fy + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(col[1] * 0.8, col[2] * 0.5, col[3] * 0.5)
        love.graphics.rectangle("fill", fx + 4, fy + 4, size - 8, size - 8, 2, 2)
    end

    -- Forbidden Foods
    if self.inForbiddenRealm then
        for _, f in ipairs(self.forbiddenFoods) do
            local fx = boardX + (f.x - 1) * self.gridSize * scale
            local fy = boardY + (f.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale
            local col = Config.colors["forbidden_food_" .. f.type] or Config.colors.forbidden_food_1
            love.graphics.setColor(col[1], col[2], col[3])
            love.graphics.rectangle("fill", fx + 1, fy + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(1, 1, 1, 0.15)
            love.graphics.rectangle("fill", fx - 2, fy - 2, size + 4, size + 4, 6, 6)
        end
    end

    -- Helper: Draw Rainbow Power-up
    local function drawRainbow(px, py, size, alpha)
        local rainbowColors = {
            {1.0, 0.0, 0.0}, {1.0, 0.5, 0.0}, {1.0, 1.0, 0.0},
            {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}, {0.29, 0.0, 0.51}, {0.58, 0.0, 0.83}
        }
        local cIdx = math.floor(love.timer.getTime() * 6.66) % 7 + 1
        local col = rainbowColors[cIdx]
        local glowAlpha = 0.2 + math.sin(love.timer.getTime() * 3) * 0.15

        love.graphics.setColor(col[1], col[2], col[3], glowAlpha)
        love.graphics.rectangle("fill", px - 2, py - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3], alpha or 1)
        love.graphics.rectangle("fill", px + 1, py + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 0.5 * (alpha or 1))
        love.graphics.rectangle("fill", px + 3, py + 3, size - 8, size - 8, 2, 2)
    end

    -- Helper: Draw Circle Power-up
    local function drawCircle(px, py, size, col, glowCol, isBlackhole)
        local cx = px + size / 2
        local cy = py + size / 2
        local rad = size / 2
        local glow = 0.3 + math.sin(love.timer.getTime() * 2) * 0.1

        love.graphics.setColor(isBlackhole and {1, 1, 1, glow} or {glowCol[1], glowCol[2], glowCol[3], glow})
        love.graphics.circle("fill", cx, cy, rad + 4)
        love.graphics.setColor(isBlackhole and {1, 1, 1, 0.15} or {glowCol[1], glowCol[2], glowCol[3], 0.15})
        love.graphics.circle("fill", cx, cy, rad + 8)

        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", cx, cy, rad - 1)
        if not isBlackhole then
            love.graphics.setColor(col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 0.5)
            love.graphics.circle("fill", cx, cy, rad - 4)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            love.graphics.circle("line", cx, cy, rad - 2)
        end
    end

    -- Power-up
    if self.powerUp and not self.inForbiddenRealm then
        local px = boardX + (self.powerUp.x - 1) * self.gridSize * scale
        local py = boardY + (self.powerUp.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local ptype = self.powerUp.type

        if ptype == "rainbow" then
            drawRainbow(px, py, size, 1)
        elseif ptype == "blackhole" then
            drawCircle(px, py, size, Config.colors.blackhole, {1, 1, 1}, true)
        elseif ptype == "whitehole" then
            drawCircle(px, py, size, Config.colors.whitehole, {0.8, 0.8, 0.8}, false)
        elseif ptype == "wormhole" then
            drawCircle(px, py, size, Config.colors.wormhole, {0.4, 0.2, 0.6}, false)
        else
            local col = Config.colors[ptype] or {1, 1, 1}
            local alpha = (self.powerUpTimer < 2 and math.floor(self.powerUp.blink * 4) % 2 == 0) and 0.4 or 1
            love.graphics.setColor(col[1], col[2], col[3], alpha)
            love.graphics.rectangle("fill", px + 1, py + 1, size - 2, size - 2, 4, 4)
            love.graphics.setColor(col[1], col[2], col[3], 0.3 * alpha)
            love.graphics.rectangle("fill", px - 2, py - 2, size + 4, size + 4, 6, 6)
        end
    end

    -- Green Fruit
    if self.greenFruit and not self.inForbiddenRealm then
        local gx = boardX + (self.greenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.greenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local col = Config.colors.greenfruit
        love.graphics.setColor(col[1], col[2], col[3], 0.25)
        love.graphics.rectangle("fill", gx - 4, gy - 4, size + 8, size + 8, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", gx + 1, gy + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(col[1] * 0.6, col[2] * 0.8, col[3] * 0.6)
        love.graphics.rectangle("fill", gx + 3, gy + 3, size - 8, size - 8, 2, 2)
    end

    -- Golden Fruit
    if self.goldenFruit and not self.inForbiddenRealm then
        local gx = boardX + (self.goldenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.goldenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local col = Config.colors.goldenfruit
        love.graphics.setColor(col[1], col[2], col[3], 0.3 + math.sin(love.timer.getTime() * 4) * 0.15)
        love.graphics.rectangle("fill", gx - 6, gy - 6, size + 12, size + 12, 8, 8)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", gx + 1, gy + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(col[1] * 0.9, col[2] * 0.8, col[3] * 0.5)
        love.graphics.rectangle("fill", gx + 3, gy + 3, size - 8, size - 8, 2, 2)
    end

    -- Debug Items
    for _, item in ipairs(self.debugItems) do
        local ix = boardX + (item.x - 1) * self.gridSize * scale
        local iy = boardY + (item.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        local col = (item.type == "forbidden_food") and (Config.colors["forbidden_food_" .. (item.food_type or 1)]) or (Config.colors[item.type] or {1, 1, 1})

        if item.type == "rainbow" then
            drawRainbow(ix, iy, size, 1)
        elseif item.type == "blackhole" then
            drawCircle(ix, iy, size, Config.colors.blackhole, {1, 1, 1}, true)
        elseif item.type == "whitehole" then
            drawCircle(ix, iy, size, Config.colors.whitehole, {0.8, 0.8, 0.8}, false)
        elseif item.type == "wormhole" then
            drawCircle(ix, iy, size, Config.colors.wormhole, {0.4, 0.2, 0.6}, false)
        else
            love.graphics.setColor(col[1], col[2], col[3], 0.3)
            love.graphics.rectangle("fill", ix - 2, iy - 2, size + 4, size + 4, 6, 6)
            love.graphics.setColor(col[1], col[2], col[3], 1)
            love.graphics.rectangle("fill", ix + 1, iy + 1, size - 2, size - 2, 4, 4)
        end
    end

    -- Player Snake
    if not self.immortalEnding or #self.snake > 0 then
        for i, seg in ipairs(self.snake) do
            local sx = boardX + (seg.x - 1) * self.gridSize * scale
            local sy = boardY + (seg.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale
            local shouldSkip = (self.invincible or self.noCollision) and not self.blinkVisible

            if not shouldSkip then
                local drawColor = {self.snakeColors.head[1], self.snakeColors.head[2], self.snakeColors.head[3]}
                if self.immortalEnding then
                    local t = self.immortalProgress
                    local gold = {0.9, 0.75, 0.2}
                    for c = 1, 3 do drawColor[c] = drawColor[c] + (gold[c] - drawColor[c]) * t end
                end

                if self.glowActive then
                    love.graphics.setColor(0.5, 1.0, 0.3, 0.4)
                    love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
                end

                if self.rainbowActive then
                    local hue = (i - 1) / #self.snake
                    local r, g, b = Utils.hsvToRgb(hue, 1.0, 1.0)
                    love.graphics.setColor(r, g, b)
                else
                    if i == 1 then
                        love.graphics.setColor(self.devilPermanent and self.devilColor or drawColor)
                    else
                        if self.immortalEnding then
                            local t = self.immortalProgress
                            local bodyGold = {0.7, 0.55, 0.15}
                            local bodyColor = {self.snakeColors.body[1], self.snakeColors.body[2], self.snakeColors.body[3]}
                            for c = 1, 3 do bodyColor[c] = bodyColor[c] + (bodyGold[c] - bodyColor[c]) * t end
                            love.graphics.setColor(bodyColor)
                        else
                            love.graphics.setColor(self.devilPermanent and self.devilColor or self.snakeColors.body)
                        end
                    end
                end

                love.graphics.rectangle("fill", sx + 1, sy + 1, size - 2, size - 2, 3, 3)
                love.graphics.setColor(0.8, 1.0, 0.5, 0.2)
                love.graphics.rectangle("fill", sx + 3, sy + 3, size - 8, size - 8, 2, 2)
            end
        end
    end

    -- AI Female Snake
    self.female:draw(boardX, boardY, self.gridSize, scale, self.blinkVisible)

    -- Immortal Ending Particles
    if self.immortalEnding then
        for _, p in ipairs(self.immortalParticles) do
            local alpha = p.life / p.maxLife
            local size = p.size * (1 + (1 - alpha) * 0.5)
            local px = boardX + (p.x - 1) * self.gridSize * scale + self.gridSize * scale / 2
            local py = boardY + (p.y - 1) * self.gridSize * scale + self.gridSize * scale / 2
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.9)
            love.graphics.circle("fill", px, py, size * scale)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.3)
            love.graphics.circle("fill", px, py, size * scale * 2.5)
        end
    end

    -- Game Over Screen
    if self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", boardX, boardY, boardW, boardH)

        love.graphics.setFont(self.largeFont)
        if self.gameOverMessage then
            love.graphics.setColor(1.0, 0.85, 0.2)
            love.graphics.printf(self.gameOverMessage, boardX, boardY + boardH / 2 - 45, boardW, "center")
        else
            love.graphics.setColor(0.95, 0.35, 0.35)
            love.graphics.printf("GAME OVER", boardX, boardY + boardH / 2 - 45, boardW, "center")
        end

        love.graphics.setFont(self.font)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Press [SPACE] / [R] to Restart", boardX, boardY + boardH / 2 + 2, boardW, "center")
        love.graphics.printf("Press [ESC] for Main Menu", boardX, boardY + boardH / 2 + 22, boardW, "center")
        love.graphics.printf("Final Score: " .. self.score, boardX, boardY + boardH / 2 + 45, boardW, "center")
    end

    self:updateExternalWindows(scale, boardX, boardY)
    love.graphics.pop()
end

-- ============================================================
-- INPUT HANDLING
-- ============================================================
function SnakeGame:keypressed(key)
    if self.immortalEnding and not self.gameOver then
        return true
    end

    if self.gameOver then
        if key == "space" or key == "r" or key == "return" then
            self:reset()
            return true
        elseif key == "escape" then
            _G.GameState = "main_menu"
            if _G.MenuInstance then _G.MenuInstance:setState("main_menu") end
            return true
        end
    end

    if key == "t" then
        self:spawnDebugItems()
        return true
    end

    if key == "up" or key == "w" then
        if self.dir.y == 0 then self.nextDir = {x = 0, y = -1}; return true end
    elseif key == "down" or key == "s" then
        if self.dir.y == 0 then self.nextDir = {x = 0, y = 1}; return true end
    elseif key == "left" or key == "a" then
        if self.dir.x == 0 then self.nextDir = {x = -1, y = 0}; return true end
    elseif key == "right" or key == "d" then
        if self.dir.x == 0 then self.nextDir = {x = 1, y = 0}; return true end
    elseif key == "r" then
        self:reset()
        return true
    end
    return false
end

function SnakeGame:handleSwipe(dx, dy)
    if self.gameOver then
        self:reset()
        return
    end

    local absX = math.abs(dx)
    local absY = math.abs(dy)
    if math.max(absX, absY) < self.minSwipeDistance then return end

    if absX > absY then
        if dx > 0 and self.dir.x == 0 then self.nextDir = {x = 1, y = 0}
        elseif dx < 0 and self.dir.x == 0 then self.nextDir = {x = -1, y = 0} end
    else
        if dy > 0 and self.dir.y == 0 then self.nextDir = {x = 0, y = 1}
        elseif dy < 0 and self.dir.y == 0 then self.nextDir = {x = 0, y = -1} end
    end
end

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

function SnakeGame:touchpressed(id, x, y)
    self.touchMap = self.touchMap or {}
    self.touchMap[id] = {x = x, y = y}
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

    local itemTypes = {"food", "greenfruit", "goldenfruit"}
    for _, ptype in ipairs(Config.powerUpTypes) do table.insert(itemTypes, ptype) end
    table.insert(itemTypes, "forbidden_food_1")
    table.insert(itemTypes, "forbidden_food_2")
    table.insert(itemTypes, "forbidden_food_3")
    table.insert(itemTypes, "forbidden_food_4")

    for i = #itemTypes, 2, -1 do
        local j = math.random(i)
        itemTypes[i], itemTypes[j] = itemTypes[j], itemTypes[i]
    end

    local freeCells = {}
    for y = 1, rows do
        for x = 1, cols do
            local occupied = false
            for _, seg in ipairs(self.snake) do
                if seg.x == x and seg.y == y then occupied = true; break end
            end
            if not occupied then table.insert(freeCells, {x = x, y = y}) end
        end
    end

    local itemsPlaced = 0
    for i, pos in ipairs(freeCells) do
        if i <= #itemTypes then
            local itype = itemTypes[i]
            if itype:find("forbidden_food_") then
                local fnum = tonumber(itype:sub(-1))
                table.insert(self.debugItems, {x = pos.x, y = pos.y, type = "forbidden_food", food_type = fnum})
            else
                table.insert(self.debugItems, {x = pos.x, y = pos.y, type = itype})
            end
            itemsPlaced = itemsPlaced + 1
        end
    end
    print("Placed " .. itemsPlaced .. " debug items.")
end

return SnakeGame
