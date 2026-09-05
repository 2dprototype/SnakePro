-- ============================================================
-- SNAKE PRO - GAMEPLAY ENGINE
-- ============================================================
local Config = require("config")
local Utils = require("utils")
local Storage = require("storage")
local Codex = require("codex")
local FemaleSnake = require("female_snake")

local DEBUG_SERIAL_MAP = {
    [1]  = {name = "Normal Apple", type = "food", key = "food"},
    [2]  = {name = "Lime Green Apple", type = "greenfruit", key = "greenfruit"},
    [3]  = {name = "Golden Apple", type = "goldenfruit", key = "goldenfruit"},
    [4]  = {name = "Tail Cutter", type = "powerup", key = "shorten", powerup = "shorten"},
    [5]  = {name = "U-Turn Paradox", type = "powerup", key = "reverse", powerup = "reverse"},
    [6]  = {name = "Ghost Phase", type = "powerup", key = "nocollision", powerup = "nocollision"},
    [7]  = {name = "Frost Hourglass", type = "powerup", key = "slowdown", powerup = "slowdown"},
    [8]  = {name = "Heart Core", type = "powerup", key = "extralife", powerup = "extralife"},
    [9]  = {name = "Devil's Fruit", type = "powerup", key = "devilfruit", powerup = "devilfruit"},
    [10] = {name = "Rainbow Prism", type = "powerup", key = "rainbow", powerup = "rainbow"},
    [11] = {name = "Cosmic Magnet", type = "powerup", key = "magnet", powerup = "magnet"},
    [12] = {name = "Prism Dye", type = "powerup", key = "colorchange", powerup = "colorchange"},
    [13] = {name = "Whitehole", type = "powerup", key = "whitehole", powerup = "whitehole"},
    [14] = {name = "Blackhole", type = "powerup", key = "blackhole", powerup = "blackhole"},
    [15] = {name = "Wormhole", type = "powerup", key = "wormhole", powerup = "wormhole"},
    [16] = {name = "Pheromone Core", type = "powerup", key = "mate", powerup = "mate"},
    [17] = {name = "Lust Berry", type = "powerup", key = "lustfood", powerup = "lustfood"},
    [18] = {name = "Forbidden Sigil", type = "powerup", key = "forbidden", powerup = "forbidden"},
    [19] = {name = "4th Wall Breach", type = "powerup", key = "fourthwall", powerup = "fourthwall"},
    [20] = {name = "5th Wall Breakout", type = "powerup", key = "fifthwall", powerup = "fifthwall"},
    [21] = {name = "Cosmic Shard", type = "forbidden_food", key = "forbidden_food_1", subtype = 1},
    [22] = {name = "Chrono Shard", type = "forbidden_food", key = "forbidden_food_2", subtype = 2},
    [23] = {name = "Thunder Surge", type = "powerup", key = "speedfood", powerup = "speedfood"},
    [24] = {name = "Chronostasis (Stop)", type = "powerup", key = "stopfood", powerup = "stopfood"},
    [25] = {name = "Wooden Crate", type = "box", key = "box"}
}

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
    self.highScore = Storage.getHighScore()
    self.gameOver = false
    self.paused = false
    self.timer = 0
    self.sessionTime = 0
    self.baseSpeed = Config.baseSpeed
    self.speed = self.baseSpeed
    self.tempSpeedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.stopTimer = 0
    self.stopDuration = Config.stopDuration
    self.storedNormalWorld = nil
    self.lives = Config.initialLives
    self.maxLives = Config.maxLives

    -- Tutorial & Discovery State
    self.showTutorial = Storage.isFirstTime()
    self.discoveryPopup = nil
    self.matchLogged = false

    -- Debug Input Buffer ("numnum" + Enter)
    self.debugBuffer = ""
    self.debugBufferTimer = 0

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

    self.glowActive = false
    self.glowTimer = 0
    self.glowDuration = Config.glowDuration

    self.whiteholeActive = false
    self.whiteholeTimer = 0

    self.blackholeActive = false
    self.blackholeTimer = 0

    self.noCollision = false
    self.noCollisionTimer = 0
    self.noCollisionDuration = Config.noCollisionDuration

    self.rainbowActive = false
    self.rainbowTimer = 0
    self.rainbowDuration = Config.rainbowDuration

    self.magnetActive = false
    self.magnetTimer = 0
    self.magnetDuration = Config.magnetDuration
    self.magnetStepTimer = 0

    self.lustActive = false
    self.lustTimer = 0
    self.lustDuration = Config.lustDuration
    self.lustMultiplier = Config.lustMultiplier

    self.devilPermanent = false
    self.devilColor = Config.colors.devilSkin
    self.devilFruitEaten = 0

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

    -- Interactive Obstacles (Wooden Boxes)
    self.boxes = {}
    self.boxParticles = {}
    self.boxSpawnTimer = 0

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
    self.titleFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 24) or love.graphics.newFont(24)
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
    self.stopTimer = 0
    self.storedNormalWorld = nil
    self.sessionTime = 0
    self.matchLogged = false

    self.showTutorial = Storage.isFirstTime()
    self.discoveryPopup = nil

    self.debugBuffer = ""
    self.debugBufferTimer = 0

    self.powerUp = nil
    self.powerUpTimer = 0
    self.powerUpSpawnTimer = 0
    self.invincible = false
    self.invincibleTimer = 0
    self.glowActive = false
    self.glowTimer = 0
    self.whiteholeActive = false
    self.whiteholeTimer = 0
    self.blackholeActive = false
    self.blackholeTimer = 0
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

    self.rainbowActive = false
    self.rainbowTimer = 0
    self.magnetActive = false
    self.magnetTimer = 0
    self.magnetStepTimer = 0
    self.fourthWallActive = false
    self.fourthWallTimer = 0
    self.outsideTimer = 0

    self.fifthWallActive = false
    self.fifthWallTimer = 0
    self:destroyExternalWindows()

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

    self.boxes = {}
    self.boxParticles = {}
    self.boxSpawnTimer = 0
    for i = 1, (Config.initialBoxes or 1) do
        self:spawnBox()
    end

    self:spawnFood()
    self.highScore = Storage.getHighScore()
end

function SnakeGame:addScore(points)
    self.score = self.score + points
    if self.score > self.highScore then
        self.highScore = self.score
        Storage.setHighScore(self.highScore)
    end
end

function SnakeGame:updateBaseSpeed()
    self.baseSpeed = math.max(Config.minSpeed, Config.baseSpeed - math.floor(self.score / 50) * 0.01)
    self.speed = self.baseSpeed
end

-- ============================================================
-- DISCOVERY POPUP TRIGGER
-- ============================================================
function SnakeGame:checkDiscovery(itemKey)
    if not itemKey then return end
    if not Storage.isDiscovered(itemKey) then
        Storage.markDiscovered(itemKey)
        self.discoveryPopup = {key = itemKey, timer = 0}
        self.paused = true
        Utils.playSFX("levelup", 1.8, 0.8)
    end
end

-- ============================================================
-- GRID & BOARD COORDINATE HELPERS
-- ============================================================
function SnakeGame:getBoardGeometry()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    local boardW = cols * self.gridSize
    local boardH = rows * self.gridSize
    local barH = 52

    local scale = 1
    if boardW > self.width - 20 or boardH > self.height - barH - 20 then
        scale = math.min((self.width - 20) / boardW, (self.height - barH - boardH) / boardH)
        boardW = boardW * scale
        boardH = boardH * scale
    end

    local boardX = math.floor((self.width - boardW) / 2)
    local boardY = barH + math.floor((self.height - barH - boardH) / 2)

    return boardX, boardY, boardW, boardH, scale, cols, rows
end

function SnakeGame:getMouseCell()
    local mx, my = love.mouse.getPosition()
    local boardX, boardY, boardW, boardH, scale, cols, rows = self:getBoardGeometry()

    local cellX = math.floor((mx - boardX) / (self.gridSize * scale)) + 1
    local cellY = math.floor((my - boardY) / (self.gridSize * scale)) + 1

    cellX = math.max(1, math.min(cols, cellX))
    cellY = math.max(1, math.min(rows, cellY))

    return cellX, cellY
end

-- ============================================================
-- ITEM SPAWNING
-- ============================================================
function SnakeGame:getFreeCells()
    local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
    local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows
    return Utils.findFreeCells(self.snake, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, cols, rows, self.female.body, self.boxes)
end

function SnakeGame:spawnBox()
    if #self.boxes >= (Config.maxBoxes or 3) then return false end
    local free = self:getFreeCells()
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        table.insert(self.boxes, {x = pos.x, y = pos.y})
        return true
    end
    return false
end

function SnakeGame:spawnBoxParticles(gridX, gridY)
    local count = 16
    for i = 1, count do
        local angle = math.random() * 2 * math.pi
        local speed = math.random(40, 120)
        local life = math.random() * 0.4 + 0.2
        local size = math.random(2, 5)
        local col = (math.random() < 0.5) and (Config.colors.box or {0.72, 0.48, 0.24}) or (Config.colors.boxBorder or {0.45, 0.28, 0.12})
        table.insert(self.boxParticles, {
            x = gridX,
            y = gridY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = life,
            maxLife = life,
            size = size,
            color = col
        })
    end
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
        if Config.powerUpTypes[typeIdx] == "devilfruit" and math.random() > 0.3 then
            typeIdx = math.random(1, #Config.powerUpTypes - 1)
        end
        if Config.powerUpTypes[typeIdx] == "mate" and math.random() > 0.3 then
            typeIdx = math.random(1, #Config.powerUpTypes - 1)
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
            timer = self.goldenFruitDuration
        }
        self.goldenFruitTimer = self.goldenFruitDuration
    end
end

function SnakeGame:spawnForbiddenFood()
    local free = self:getFreeCells()
    if #free > 0 then
        local pos = free[math.random(1, #free)]
        -- 70% Cosmic Shard (+30 pts), 30% Chrono Shard (+2.5s)
        local ftype = (math.random() < 0.7) and 1 or 2
        table.insert(self.forbiddenFoods, {x = pos.x, y = pos.y, type = ftype})
    end
end

-- ============================================================
-- DEBUG SPAWN SYSTEM: "numnum" + Enter
-- ============================================================
function SnakeGame:spawnDebugItemByCode(code)
    local entry = DEBUG_SERIAL_MAP[code]
    if not entry then
        Utils.notify("Debug", "Unknown code: " .. tostring(code), nil, 2.0)
        return false
    end

    local cellX, cellY = self:getMouseCell()

    if entry.type == "food" then
        self.food = {x = cellX, y = cellY}
    elseif entry.type == "greenfruit" then
        self.greenFruit = {
            x = cellX,
            y = cellY,
            timer = self.greenFruitDuration
        }
        self.greenFruitTimer = self.greenFruitDuration
    elseif entry.type == "goldenfruit" then
        self.goldenFruit = {
            x = cellX,
            y = cellY,
            timer = self.goldenFruitDuration
        }
        self.goldenFruitTimer = self.goldenFruitDuration
    elseif entry.type == "powerup" then
        self.powerUp = {
            x = cellX,
            y = cellY,
            type = entry.powerup,
            timer = Config.powerUpDuration,
            blink = 0
        }
        self.powerUpTimer = Config.powerUpDuration
    elseif entry.type == "forbidden_food" then
        table.insert(self.forbiddenFoods, {
            x = cellX,
            y = cellY,
            type = entry.subtype or 1
        })
    elseif entry.type == "box" then
        table.insert(self.boxes, {
            x = cellX,
            y = cellY
        })
    end

    Utils.playSFX("levelup", 1.8, 0.7)
    Utils.notify("Debug Spawn", string.format("[%s] %s at (%d, %d)", tostring(code), entry.name, cellX, cellY), nil, 2.0)
    return true
end

-- ============================================================
-- SPECIAL MECHANICS & EFFECTS
-- ============================================================
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

function SnakeGame:enterForbiddenRealm()
    self:checkDiscovery("event_forbidden_realm")
    if not self.inForbiddenRealm then
        -- Snapshot all normal world foods and active power-ups
        self.storedNormalWorld = {
            food = self.food and {x = self.food.x, y = self.food.y} or nil,
            powerUp = self.powerUp and {
                x = self.powerUp.x,
                y = self.powerUp.y,
                type = self.powerUp.type,
                timer = self.powerUpTimer or self.powerUp.timer or Config.powerUpDuration,
                blink = self.powerUp.blink or 0
            } or nil,
            powerUpTimer = self.powerUpTimer,
            powerUpSpawnTimer = self.powerUpSpawnTimer,
            greenFruit = self.greenFruit and {
                x = self.greenFruit.x,
                y = self.greenFruit.y,
                timer = self.greenFruitTimer or self.greenFruit.timer or Config.greenFruitDuration
            } or nil,
            greenFruitTimer = self.greenFruitTimer,
            greenFruitSpawnTimer = self.greenFruitSpawnTimer,
            goldenFruit = self.goldenFruit and {
                x = self.goldenFruit.x,
                y = self.goldenFruit.y,
                timer = self.goldenFruitTimer or self.goldenFruit.timer or Config.goldenFruitDuration
            } or nil,
            goldenFruitTimer = self.goldenFruitTimer,
            goldenFruitSpawnTimer = self.goldenFruitSpawnTimer,
            boxes = Utils.shallowCopyTable(self.boxes) or {},
            boxSpawnTimer = self.boxSpawnTimer
        }

        -- Clear normal world active items from the grid
        self.food = nil
        self.powerUp = nil
        self.powerUpTimer = 0
        self.greenFruit = nil
        self.greenFruitTimer = 0
        self.goldenFruit = nil
        self.goldenFruitTimer = 0
        self.boxes = {}
    end

    self.inForbiddenRealm = true
    self.forbiddenTimer = self.forbiddenDuration
    self.forbiddenFoods = {}
    self.forbiddenPowerUps = {}

    -- Synchronize female snake realm entry
    if self.female and self.female.active then
        self.female.inForbidden = true
        self.female.forbiddenTimer = self.forbiddenDuration
    end

    for i = 1, 14 do
        self:spawnForbiddenFood()
    end

    Utils.playSFX("levelup", 1.0, 0.8)
    Utils.notify("Forbidden Realm", "Shifted into Cosmic Realm! Normal foods preserved.", nil, 2.5)
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

    -- Synchronize female snake realm exit
    if self.female and self.female.active then
        self.female.inForbidden = false
        self.female.forbiddenTimer = 0
        if self.female.body and self.female.body[1] then
            local fHead = self.female.body[1]
            fHead.x = math.max(1, math.min(Config.cols, fHead.x))
            fHead.y = math.max(1, math.min(Config.rows, fHead.y))
        end
    end

    if self.snake and self.snake[1] then
        local pHead = self.snake[1]
        pHead.x = math.max(1, math.min(Config.cols, pHead.x))
        pHead.y = math.max(1, math.min(Config.rows, pHead.y))
    end

    -- Restore stored normal world items & timers
    if self.storedNormalWorld then
        self.food = self.storedNormalWorld.food
        self.powerUp = self.storedNormalWorld.powerUp
        self.powerUpTimer = self.storedNormalWorld.powerUpTimer or (self.powerUp and self.powerUp.timer or 0)
        self.powerUpSpawnTimer = self.storedNormalWorld.powerUpSpawnTimer or 0
        self.greenFruit = self.storedNormalWorld.greenFruit
        self.greenFruitTimer = self.storedNormalWorld.greenFruitTimer or (self.greenFruit and self.greenFruit.timer or 0)
        self.greenFruitSpawnTimer = self.storedNormalWorld.greenFruitSpawnTimer or 0
        self.goldenFruit = self.storedNormalWorld.goldenFruit
        self.goldenFruitTimer = self.storedNormalWorld.goldenFruitTimer or (self.goldenFruit and self.goldenFruit.timer or 0)
        self.goldenFruitSpawnTimer = self.storedNormalWorld.goldenFruitSpawnTimer or 0
        self.boxes = self.storedNormalWorld.boxes or {}
        self.boxSpawnTimer = self.storedNormalWorld.boxSpawnTimer or 0
        self.storedNormalWorld = nil
    end

    if not self.food then
        self:spawnFood()
    end

    Utils.playSFX("levelup", 0.9, 0.6)
    Utils.notify("Normal World", "Returned from Forbidden Realm! Stored foods restored.", nil, 2.5)
end

function SnakeGame:triggerMating()
    self:checkDiscovery("event_mating")
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
    self:checkDiscovery(ptype)

    if ptype == "shorten" then
        for i = 1, 3 do if #self.snake > 3 then table.remove(self.snake) end end
        Utils.playSFX("tick", 1.2, 0.3)
        Utils.notify("Snake", "TAIL CUTTER! -3 segments", nil, 1.8)

    elseif ptype == "reverse" then
        local reversed = {}
        for i = #self.snake, 1, -1 do table.insert(reversed, self.snake[i]) end
        self.snake = reversed
        self.dir = {x = -self.dir.x, y = -self.dir.y}
        self.nextDir = {x = self.dir.x, y = self.dir.y}
        Utils.playSFX("tick", 0.8, 0.3)
        Utils.notify("Snake", "U-TURN PARADOX! 180° Direction Swapped", nil, 1.8)

    elseif ptype == "nocollision" then
        self.noCollision = true
        self.noCollisionTimer = Config.noCollisionDuration
        Utils.playSFX("tick", 1.8, 0.3)
        Utils.notify("Snake", "GHOST PHASE! Pass through body (4s)", nil, 2.0)

    elseif ptype == "slowdown" then
        self.tempSpeedMultiplier = 0.5
        self.tempSpeedTimer = Config.frostDuration
        Utils.playSFX("tick", 0.6, 0.3)
        Utils.notify("Snake", "FROST HOURGLASS! 50% Slow-Mo (5s)", nil, 2.0)

    elseif ptype == "extralife" then
        if self.lives < self.maxLives then
            self.lives = self.lives + 1
            Utils.notify("Snake", "HEART CORE! +1 Extra Life", nil, 2.0)
        else
            self:addScore(100)
            Utils.notify("Snake", "HEART CORE (Max Lives)! +100 pts", nil, 2.0)
        end
        Utils.playSFX("levelup", 1.2, 0.5)

    elseif ptype == "colorchange" then
        local liveCol = Utils.getPrismColor(0)
        self.devilPermanent = false
        self.targetHeadColor = {liveCol[1], liveCol[2], liveCol[3]}
        self.targetBodyColor = {liveCol[1] * 0.75, liveCol[2] * 0.75, liveCol[3] * 0.75}
        self.colorChangeTimer = 1.0
        Utils.playSFX("tick", 1.5, 0.3)
        Utils.notify("Snake", "PRISM DYE! Absorbed live prism hue!", nil, 1.8)

    elseif ptype == "devilfruit" then
        self:addScore(100)
        self.devilFruitEaten = self.devilFruitEaten + 1
        self.devilPermanent = true
        self.targetHeadColor = self.devilColor
        self.targetBodyColor = self.devilColor
        self.colorChangeTimer = 1.0
        self.tempSpeedMultiplier = 1.4
        self.tempSpeedTimer = 3.0
        Utils.playSFX("levelup", 1.5, 0.8)
        Utils.notify("Snake", "DEVIL'S FRUIT! +100 pts & Crimson Surge", nil, 2.5)

    elseif ptype == "rainbow" then
        self:addScore(50)
        self.rainbowActive = true
        self.rainbowTimer = Config.rainbowDuration
        Utils.playSFX("levelup", 1.3, 0.6)
        Utils.notify("Snake", "RAINBOW PRISM! Vibrant Spectrum (10s)!", nil, 2.5)

    elseif ptype == "speedfood" then
        self:addScore(50)
        self.tempSpeedMultiplier = Config.speedFoodMultiplier
        self.tempSpeedTimer = Config.speedFoodDuration
        Utils.playSFX("levelup", 1.6, 0.7)
        Utils.notify("Snake", "SPEED SURGE! Lightning Boost (5s)!", nil, 2.0)

    elseif ptype == "stopfood" then
        self.stopTimer = Config.stopDuration
        Utils.playSFX("tick", 0.5, 0.8)
        Utils.notify("Snake", "CHRONOSTASIS! Snake Frozen (5s)!", nil, 2.0)

    elseif ptype == "magnet" then
        self.magnetActive = true
        self.magnetTimer = Config.magnetDuration
        self.magnetStepTimer = 0
        Utils.playSFX("levelup", 1.4, 0.6)
        Utils.notify("Snake", "COSMIC MAGNET! Vacuuming all foods (6s)!", nil, 2.5)

    elseif ptype == "whitehole" then
        self.whiteholeActive = true
        self.whiteholeTimer = Config.holeEffectDuration
        Utils.playSFX("levelup", 1.0, 0.5)
        Utils.notify("Snake", "WHITEHOLE! Gravitational Repulsion (5s)!", nil, 2.0)

    elseif ptype == "blackhole" then
        self.blackholeActive = true
        self.blackholeTimer = Config.holeEffectDuration
        Utils.playSFX("levelup", 1.0, 0.5)
        Utils.notify("Snake", "BLACKHOLE! Gravitational Vortex (5s)!", nil, 2.0)

    elseif ptype == "wormhole" then
        self:teleportSnake()
        Utils.playSFX("levelup", 1.0, 0.7)
        Utils.notify("Snake", "WORMHOLE! Spatial Teleportation!", nil, 2.0)

    elseif ptype == "mate" then
        if not self.female.active then
            local free = self:getFreeCells()
            self.female:spawn(free, self.snake[1], self.inForbiddenRealm, self.forbiddenCols, self.forbiddenRows, self)
        else
            self.female.timer = math.min(self.female.timer + 30, 600)
            self:addScore(50)
            Utils.notify("Snake", "PHEROMONE CORE! Female stay +30s", nil, 2.0)
        end
        Utils.playSFX("levelup", 1.2, 0.5)

    elseif ptype == "lustfood" then
        self.lustActive = true
        self.lustTimer = self.lustDuration
        Utils.playSFX("task_complete", 1.2, 0.5)
        Utils.notify("Snake", "LUST BERRY! 3x Points & AI Magnetized!", nil, 2.0)

    elseif ptype == "forbidden" then
        self:enterForbiddenRealm()
        Utils.playSFX("levelup", 1.0, 0.8)

    elseif ptype == "fourthwall" then
        self:checkDiscovery("event_fourth_wall")
        self.fourthWallActive = true
        self.fourthWallTimer = self.fourthWallDuration
        self.outsideTimer = 0
        Utils.playSFX("levelup", 1.0, 0.7)
        Utils.notify("Snake", "4TH WALL BREACH! You can slither into void!", nil, 2.5)

    elseif ptype == "fifthwall" then
        self:checkDiscovery("event_fifth_wall")
        self.fifthWallActive = true
        self.fifthWallTimer = self.fifthWallDuration
        self.outsideTimer = 0
        Utils.playSFX("levelup", 1.0, 0.7)
        Utils.notify("Snake", "5TH WALL BREAKOUT! Escaping into desktop windows!", nil, 2.5)
    end
end

function SnakeGame:applyGoldenFruit(fruit)
    self:checkDiscovery("goldenfruit")
    local mult = (self.lustActive and self.lustMultiplier or 1)
    local pts = 250 * mult
    self:addScore(pts)

    if self.lives < self.maxLives then
        self.lives = self.lives + 1
    end
    self.invincible = true
    self.invincibleTimer = 3.0

    Utils.playSFX("levelup", 2.0, 0.9)
    Utils.notify("Snake", "GOLDEN JACKPOT! +" .. pts .. " pts, +1 Life & Shield!", nil, 2.5)
end

function SnakeGame:revive()
    self:checkDiscovery("event_death")
    self.lives = self.lives - 1
    if self.lives <= 0 then
        self.gameOver = true
        self.gameOverMessage = "Game Over"
        if not self.matchLogged then
            self.matchLogged = true
            Storage.addHistoryRecord({
                score = self.score,
                devilFruits = self.devilFruitEaten,
                matings = self.mateCount,
                duration = math.floor(self.sessionTime),
                foodsEaten = math.floor(self.score / 10),
                outcome = "Game Over"
            })
        end
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
    self:checkDiscovery("event_immortal_ending")
    self.food = nil
    self.powerUp = nil
    self.greenFruit = nil
    self.goldenFruit = nil
    self.forbiddenFoods = {}
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

            if not self.matchLogged then
                self.matchLogged = true
                Storage.addHistoryRecord({
                    score = self.score,
                    devilFruits = self.devilFruitEaten,
                    matings = self.mateCount,
                    duration = math.floor(self.sessionTime),
                    foodsEaten = math.floor(self.score / 10),
                    outcome = "Ascended"
                })
            end

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
    -- Don't advance gameplay if tutorial or discovery popup is active
    if self.showTutorial or self.discoveryPopup then
        return
    end

    if self.paused then return end

    self.sessionTime = self.sessionTime + dt

    -- Update debug buffer timeout
    if self.debugBufferTimer > 0 then
        self.debugBufferTimer = self.debugBufferTimer - dt
        if self.debugBufferTimer <= 0 then
            self.debugBuffer = ""
        end
    end

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

    -- Whitehole physics (repels items away from snake head)
    if self.whiteholeActive then
        self.whiteholeTimer = self.whiteholeTimer - dt
        if self.whiteholeTimer <= 0 then self.whiteholeActive = false end

        local head = self.snake[1]
        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local function repelItem(item)
            if item and head then
                local dx = item.x - head.x
                local dy = item.y - head.y
                local dist = math.abs(dx) + math.abs(dy)
                if dist > 1 then
                    local nx = item.x
                    local ny = item.y
                    if math.abs(dx) >= math.abs(dy) then
                        nx = item.x + (dx > 0 and 1 or -1)
                    else
                        ny = item.y + (dy > 0 and 1 or -1)
                    end
                    nx = math.max(1, math.min(cols, nx))
                    ny = math.max(1, math.min(rows, ny))
                    if Utils.isEmptyCell(nx, ny, self.snake, self.female.body, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, item) then
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

    -- Blackhole physics (attracts items towards snake head)
    if self.blackholeActive then
        self.blackholeTimer = self.blackholeTimer - dt
        if self.blackholeTimer <= 0 then self.blackholeActive = false end

        local head = self.snake[1]
        local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
        local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

        local function attractItem(item)
            if item and head then
                local dx = head.x - item.x
                local dy = head.y - item.y
                local dist = math.abs(dx) + math.abs(dy)
                if dist > 1 then
                    local nx = item.x
                    local ny = item.y
                    if math.abs(dx) >= math.abs(dy) then
                        nx = item.x + (dx > 0 and 1 or -1)
                    else
                        ny = item.y + (dy > 0 and 1 or -1)
                    end
                    nx = math.max(1, math.min(cols, nx))
                    ny = math.max(1, math.min(rows, ny))
                    if Utils.isEmptyCell(nx, ny, self.snake, self.female.body, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, item) then
                        item.x = nx
                        item.y = ny
                    end
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

    -- Cosmic Magnet physics (pull foods and shards smoothly towards snake head)
    if self.magnetActive then
        self.magnetTimer = self.magnetTimer - dt
        if self.magnetTimer <= 0 then self.magnetActive = false end

        self.magnetStepTimer = (self.magnetStepTimer or 0) + dt
        if self.magnetStepTimer >= 0.12 then
            self.magnetStepTimer = 0
            local head = self.snake[1]
            local cols = self.inForbiddenRealm and self.forbiddenCols or self.cols
            local rows = self.inForbiddenRealm and self.forbiddenRows or self.rows

            local function pullItem(item)
                if item and head then
                    local dx = head.x - item.x
                    local dy = head.y - item.y
                    if math.abs(dx) > 0 or math.abs(dy) > 0 then
                        local stepX = 0
                        local stepY = 0
                        if math.abs(dx) >= math.abs(dy) then
                            stepX = (dx > 0) and 1 or -1
                        else
                            stepY = (dy > 0) and 1 or -1
                        end
                        local nx = math.max(1, math.min(cols, item.x + stepX))
                        local ny = math.max(1, math.min(rows, item.y + stepY))
                        if Utils.isEmptyCell(nx, ny, self.snake, self.female.body, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, item) then
                            item.x = nx
                            item.y = ny
                        end
                    end
                end
            end

            pullItem(self.food)
            pullItem(self.greenFruit)
            pullItem(self.goldenFruit)
            if self.inForbiddenRealm then
                for _, f in ipairs(self.forbiddenFoods) do pullItem(f) end
            end
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
    if self.stopTimer > 0 then
        self.stopTimer = self.stopTimer - dt
        if self.stopTimer < 0 then self.stopTimer = 0 end
    end

    -- Update Box Smash Particles
    if self.boxParticles and #self.boxParticles > 0 then
        for i = #self.boxParticles, 1, -1 do
            local p = self.boxParticles[i]
            p.x = p.x + (p.vx * dt) / self.gridSize
            p.y = p.y + (p.vy * dt) / self.gridSize
            p.life = p.life - dt
            if p.life <= 0 then
                table.remove(self.boxParticles, i)
            end
        end
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
        while #self.forbiddenFoods < 14 do self:spawnForbiddenFood() end
    else
        -- Periodic Box Spawning
        if not self.boxes or #self.boxes < (Config.maxBoxes or 3) then
            self.boxSpawnTimer = (self.boxSpawnTimer or 0) + dt
            if self.boxSpawnTimer >= (Config.boxSpawnInterval or 18.0) then
                self.boxSpawnTimer = 0
                self:spawnBox()
            end
        end

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
    if self.stopTimer > 0 then
        self.timer = 0
    else
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
                    if not self.matchLogged then
                        self.matchLogged = true
                        Storage.addHistoryRecord({
                            score = self.score,
                            devilFruits = self.devilFruitEaten,
                            matings = self.mateCount,
                            duration = math.floor(self.sessionTime),
                            foodsEaten = math.floor(self.score / 10),
                            outcome = "Lost in Void"
                        })
                    end
                    Utils.playSFX("glitch", 1.2, 0.4)
                    return
                end
            end

            local scoreMult = (self.lustActive and self.lustMultiplier or 1)

            -- Box collision & pushing physics
            local hitBoxIndex = nil
            if self.boxes then
                for bi, b in ipairs(self.boxes) do
                    if b.x == newHead.x and b.y == newHead.y then
                        hitBoxIndex = bi
                        break
                    end
                end
            end

            if hitBoxIndex then
                self:checkDiscovery("box")
                local box = self.boxes[hitBoxIndex]
                local pushTargetX = box.x + self.dir.x
                local pushTargetY = box.y + self.dir.y
                local isOutside = (pushTargetX < 1 or pushTargetX > cols or pushTargetY < 1 or pushTargetY > rows)

                if isOutside then
                    -- Pushed outside the arena boundary! Smash box!
                    table.remove(self.boxes, hitBoxIndex)
                    local pts = (Config.boxScore or 100) * scoreMult
                    self:addScore(pts)
                    self:spawnBoxParticles(box.x, box.y)
                    Utils.playSFX("glitch", 1.4, 0.5)
                    Utils.notify("Smash!", "Box smashed outside the arena! +" .. pts .. " pts", nil, 2.0)
                else
                    -- Pushed inside arena: check if target cell is empty
                    local free = Utils.isEmptyCell(pushTargetX, pushTargetY, self.snake, self.female.body, self.food, self.powerUp, self.greenFruit, self.goldenFruit, self.forbiddenFoods, nil, self.boxes)
                    if free then
                        box.x = pushTargetX
                        box.y = pushTargetY
                        Utils.playSFX("tick", 0.7, 0.4)
                    else
                        -- Push target blocked! Snake movement is blocked
                        return
                    end
                end
            end

            table.insert(self.snake, 1, newHead)

            local ate = false

            if not self.inForbiddenRealm then
                if self.food and newHead.x == self.food.x and newHead.y == self.food.y then
                    self:checkDiscovery("food")
                    local pts = 10 * scoreMult
                    self:addScore(pts)
                    self:updateBaseSpeed()
                    Utils.playSFX("tick", 1.5, 0.5)
                    self:spawnFood()
                    ate = true
                end
                if self.greenFruit and newHead.x == self.greenFruit.x and newHead.y == self.greenFruit.y then
                    self:checkDiscovery("greenfruit")
                    local pts = 200 * scoreMult
                    self:addScore(pts)
                    self.glowActive = true
                    self.glowTimer = self.glowDuration
                    self.tempSpeedMultiplier = self.tempSpeedMultiplier + 0.6
                    self.tempSpeedTimer = 5.0
                    Utils.playSFX("levelup", 1.8, 0.8)
                    Utils.notify("Snake", "Lime Green Apple! +200 & Glow Speed!", nil, 2.0)
                    self.greenFruit = nil
                    self.greenFruitTimer = 0
                    ate = true
                end
                if self.powerUp and newHead.x == self.powerUp.x and newHead.y == self.powerUp.y then
                    self:applyPowerUp(self.powerUp)
                    self.powerUp = nil
                    ate = true
                end
                if self.goldenFruit and newHead.x == self.goldenFruit.x and newHead.y == self.goldenFruit.y then
                    self:applyGoldenFruit(self.goldenFruit)
                    self.goldenFruit = nil
                    self.goldenFruitTimer = 0
                    ate = true
                end
            else
                for i = #self.forbiddenFoods, 1, -1 do
                    local f = self.forbiddenFoods[i]
                    if newHead.x == f.x and newHead.y == f.y then
                        self:checkDiscovery("forbidden_food_" .. f.type)
                        if f.type == 2 then
                            self.forbiddenTimer = math.min(self.forbiddenTimer + 2.5, 15.0)
                            Utils.playSFX("levelup", 1.2, 0.6)
                            Utils.notify("Snake", "+2.5s Chrono Shard Harvested!", nil, 1.5)
                        else
                            local pts = 30 * scoreMult
                            self:addScore(pts)
                            Utils.playSFX("tick", 1.6, 0.5)
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
end

-- ============================================================
-- DRAWING & OVERLAYS
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

    if self.noCollision then statuses[#statuses+1] = {text = "NC", color = {0.2, 0.9, 0.9}} end
    if self.tempSpeedMultiplier < 1.0 then statuses[#statuses+1] = {text = "FROST", color = {0.3, 0.7, 1.0}} end
    if self.tempSpeedMultiplier > 1.0 and self.tempSpeedTimer > 0 then statuses[#statuses+1] = {text = "SPEED", color = {1.0, 0.9, 0.1}} end
    if self.stopTimer > 0 then statuses[#statuses+1] = {text = string.format("STOP (%.0fs)", math.ceil(self.stopTimer)), color = {0.95, 0.3, 0.3}} end
    if self.glowActive then statuses[#statuses+1] = {text = "GLOW", color = {0.5, 1.0, 0.3}} end
    if self.rainbowActive then statuses[#statuses+1] = {text = "RAINBOW", color = {0.9, 0.2, 0.9}} end
    if self.magnetActive then statuses[#statuses+1] = {text = "MAGNET", color = {0.4, 0.6, 1.0}} end
    if self.whiteholeActive then statuses[#statuses+1] = {text = "WH", color = {1.0, 1.0, 1.0}} end
    if self.blackholeActive then statuses[#statuses+1] = {text = "BH", color = {0.4, 0.4, 0.4}} end
    if self.lustActive then statuses[#statuses+1] = {text = "LUST (3X)", color = {1.0, 0.2, 0.6}} end
    if self.invincible then statuses[#statuses+1] = {text = "SHIELD", color = {1.0, 0.85, 0.2}} end
    if self.inForbiddenRealm then statuses[#statuses+1] = {text = "REALM", color = {0.8, 0.3, 0.9}} end
    if self.fourthWallActive then statuses[#statuses+1] = {text = "4W", color = {0.0, 0.8, 0.8}} end
    if self.fifthWallActive then statuses[#statuses+1] = {text = "5W", color = {0.0, 1.0, 0.4}} end
    if self.devilPermanent then statuses[#statuses+1] = {text = "DEVIL", color = {0.95, 0.1, 0.1}} end

    for _, st in ipairs(statuses) do
        love.graphics.setColor(st.color)
        love.graphics.print(st.text, statusX, statusY)
        statusX = statusX + love.graphics.getFont():getWidth(st.text) + 6
    end

    -- Board Geometry & Scaling
    local boardX, boardY, boardW, boardH, scale, cols, rows = self:getBoardGeometry()

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
        Codex.drawIcon("food", fx, fy, size)
    end

    -- Lime Green Apple (Rare Fruit)
    if self.greenFruit and not self.inForbiddenRealm then
        local gx = boardX + (self.greenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.greenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        Codex.drawIcon("greenfruit", gx, gy, size)
    end

    -- Forbidden Foods
    if self.inForbiddenRealm or #self.forbiddenFoods > 0 then
        for _, f in ipairs(self.forbiddenFoods) do
            local fx = boardX + (f.x - 1) * self.gridSize * scale
            local fy = boardY + (f.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale
            Codex.drawIcon("forbidden_food_" .. f.type, fx, fy, size)
        end
    end

    -- Power-up
    if self.powerUp and not self.inForbiddenRealm then
        local px = boardX + (self.powerUp.x - 1) * self.gridSize * scale
        local py = boardY + (self.powerUp.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        Codex.drawIcon(self.powerUp.type, px, py, size)
    end

    -- Golden Fruit
    if self.goldenFruit and not self.inForbiddenRealm then
        local gx = boardX + (self.goldenFruit.x - 1) * self.gridSize * scale
        local gy = boardY + (self.goldenFruit.y - 1) * self.gridSize * scale
        local size = self.gridSize * scale
        Codex.drawIcon("goldenfruit", gx, gy, size)
    end

    -- Wooden Boxes (Interactive Obstacles)
    if self.boxes and #self.boxes > 0 then
        for _, b in ipairs(self.boxes) do
            local bx = boardX + (b.x - 1) * self.gridSize * scale
            local by = boardY + (b.y - 1) * self.gridSize * scale
            local size = self.gridSize * scale
            Codex.drawIcon("box", bx, by, size)
        end
    end

    -- Box Smash Splinter Particles
    if self.boxParticles and #self.boxParticles > 0 then
        for _, p in ipairs(self.boxParticles) do
            local alpha = math.max(0, p.life / p.maxLife)
            local px = boardX + (p.x - 1) * self.gridSize * scale + (self.gridSize * scale / 2)
            local py = boardY + (p.y - 1) * self.gridSize * scale + (self.gridSize * scale / 2)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.rectangle("fill", px - (p.size * scale) / 2, py - (p.size * scale) / 2, p.size * scale, p.size * scale)
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
                if self.glowActive then
                    love.graphics.setColor(0.5, 1.0, 0.3, 0.4)
                    love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
                end

                local drawColor = {self.snakeColors.head[1], self.snakeColors.head[2], self.snakeColors.head[3]}
                if self.immortalEnding then
                    local t = self.immortalProgress
                    local gold = {0.9, 0.75, 0.2}
                    for c = 1, 3 do drawColor[c] = drawColor[c] + (gold[c] - drawColor[c]) * t end
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

    -- Debug Typed Code Overlay with dynamic item name preview (Bottom Right)
    if self.debugBuffer and #self.debugBuffer > 0 then
        local code = tonumber(self.debugBuffer)
        local itemName = (code and DEBUG_SERIAL_MAP[code]) and DEBUG_SERIAL_MAP[code].name or "Unknown"
        local isKnown = (code and DEBUG_SERIAL_MAP[code]) ~= nil
        local text = "SPAWN: [" .. self.debugBuffer .. "] " .. itemName .. " [ENTER]"

        love.graphics.setFont(self.smallFont)
        local tw = love.graphics.getFont():getWidth(text)
        local tx = width - tw - 12
        local ty = height - 22

        love.graphics.setColor(0.04, 0.04, 0.08, 0.85)
        love.graphics.rectangle("fill", tx - 4, ty - 2, tw + 8, 18, 3, 3)

        if isKnown then
            love.graphics.setColor(0.35, 0.95, 0.4, 0.9)
            love.graphics.rectangle("line", tx - 4, ty - 2, tw + 8, 18, 3, 3)
            love.graphics.setColor(1.0, 0.9, 0.3)
        else
            love.graphics.setColor(0.95, 0.35, 0.35, 0.9)
            love.graphics.rectangle("line", tx - 4, ty - 2, tw + 8, 18, 3, 3)
            love.graphics.setColor(0.95, 0.5, 0.5)
        end
        love.graphics.print(text, tx, ty)
    end

    -- ========================================================
    -- MODAL OVERLAYS: FIRST-TIME GUIDE & DISCOVERY POPUP
    -- ========================================================
    if self.showTutorial then
        -- Tutorial Guide Card
        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", 0, 0, width, height)

        local cardW = width - 40
        local cardH = height - 60
        local cardX = 20
        local cardY = 30

        love.graphics.setColor(0.06, 0.08, 0.14, 0.95)
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 8, 8)
        love.graphics.setColor(0.35, 0.75, 1.0, 0.85)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 8, 8)

        love.graphics.setFont(self.largeFont)
        love.graphics.setColor(0.4, 1.0, 0.5)
        love.graphics.printf("WELCOME TO SNAKE PRO!", cardX, cardY + 14, cardW, "center")

        love.graphics.setFont(self.font)
        love.graphics.setColor(0.9, 0.9, 0.9)

        local tips = {
            {"[CONTROLS]", "W A S D / Arrow Keys or Swipe"},
            {"[HARVEST]", "Eat foods to grow & gain high scores"},
            {"[POWER-UPS]", "Discover 22 unique foods & powers"},
            {"[AVOID]", "Don't crash into your own body segments"},
            {"[SECRET]", "Bite your tail to unlock Immortal Ending"},
            {"[MENU]", "Press [ESC] anytime to pause or restart"}
        }

        local startY = cardY + 48
        for _, tip in ipairs(tips) do
            love.graphics.setColor(0.4, 0.8, 1.0)
            love.graphics.print(tip[1], cardX + 16, startY)
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print(tip[2], cardX + 115, startY)
            startY = startY + 24
        end

        local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 5)
        love.graphics.setColor(1.0 * pulse, 0.85 * pulse, 0.2 * pulse)
        love.graphics.printf("Press [ENTER] or [SPACE] to Play", cardX, cardY + cardH - 34, cardW, "center")

    elseif self.discoveryPopup then
        -- First-time Food/Power-up Discovery Popup
        local item = Codex.byKey[self.discoveryPopup.key]
        if item then
            love.graphics.setColor(0, 0, 0, 0.85)
            love.graphics.rectangle("fill", 0, 0, width, height)

            local cardW = width - 48
            local cardH = 220
            local cardX = 24
            local cardY = (height - cardH) / 2

            love.graphics.setColor(0.08, 0.08, 0.14, 0.95)
            love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 8, 8)
            love.graphics.setColor(1.0, 0.85, 0.2, 0.9)
            love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 8, 8)

            -- Header
            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(1.0, 0.85, 0.2)
            love.graphics.printf("★ NEW DISCOVERY UNLOCKED ★", cardX, cardY + 12, cardW, "center")

            -- Icon
            local iconSize = 28
            local iconX = cardX + 20
            local iconY = cardY + 42
            Codex.drawIcon(self.discoveryPopup.key, iconX, iconY, iconSize)

            -- Item Title & Category
            love.graphics.setFont(self.largeFont)
            love.graphics.setColor(0.35, 0.95, 0.5)
            love.graphics.print(item.name, iconX + iconSize + 12, iconY - 2)

            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(0.5, 0.8, 1.0)
            love.graphics.print(item.category .. " | " .. item.points, iconX + iconSize + 12, iconY + 20)

            -- Description
            love.graphics.setFont(self.font)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.printf(item.desc, cardX + 20, cardY + 88, cardW - 40, "left")

            -- Dismiss Prompt
            local pulse = 0.8 + 0.2 * math.sin(love.timer.getTime() * 5)
            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(0.7 * pulse, 0.9 * pulse, 1.0 * pulse)
            love.graphics.printf("Press [ENTER] / [SPACE] / [ESC] to Continue", cardX, cardY + cardH - 26, cardW, "center")
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
    -- Dismiss Tutorial
    if self.showTutorial then
        if key == "return" or key == "space" or key == "escape" then
            Storage.completeFirstTime()
            self.showTutorial = false
            self.paused = false
            Utils.playSFX("levelup", 1.2, 0.5)
            return true
        end
        return true
    end

    -- Dismiss Discovery Popup
    if self.discoveryPopup then
        if key == "return" or key == "space" or key == "escape" then
            self.discoveryPopup = nil
            self.paused = false
            Utils.playSFX("tick", 1.2, 0.4)
            return true
        end
        return true
    end

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

    -- Number typing for debug scheme: "numnum" + Enter
    local digit = nil
    if key >= "0" and key <= "9" then
        digit = key
    elseif key:match("^kp(%d)$") then
        digit = key:match("^kp(%d)$")
    end

    if digit then
        if #self.debugBuffer < 4 then
            self.debugBuffer = self.debugBuffer .. digit
            self.debugBufferTimer = 4.0
            Utils.playSFX("tick", 1.5, 0.2)
        end
        return true
    end

    if key == "backspace" and #self.debugBuffer > 0 then
        self.debugBuffer = self.debugBuffer:sub(1, -2)
        return true
    end

    if (key == "return" or key == "kpenter") and #self.debugBuffer > 0 then
        local code = tonumber(self.debugBuffer)
        self.debugBuffer = ""
        self.debugBufferTimer = 0
        if code then
            self:spawnDebugItemByCode(code)
            return true
        end
    end

    -- Normal Controls
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
    if self.showTutorial then
        Storage.completeFirstTime()
        self.showTutorial = false
        self.paused = false
        return
    end

    if self.discoveryPopup then
        self.discoveryPopup = nil
        self.paused = false
        return
    end

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
        if self.showTutorial then
            Storage.completeFirstTime()
            self.showTutorial = false
            self.paused = false
            return true
        end

        if self.discoveryPopup then
            self.discoveryPopup = nil
            self.paused = false
            return true
        end

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
    if self.showTutorial then
        Storage.completeFirstTime()
        self.showTutorial = false
        self.paused = false
        return true
    end

    if self.discoveryPopup then
        self.discoveryPopup = nil
        self.paused = false
        return true
    end

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

return SnakeGame
