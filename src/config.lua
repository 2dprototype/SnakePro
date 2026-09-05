-- ============================================================
-- SNAKE PRO - CONFIGURATION & CONSTANTS
-- ============================================================
local Config = {}

-- Window & Grid Settings
Config.windowWidth = 420
Config.windowHeight = 440
Config.gridSize = 16
Config.cols = 20
Config.rows = 20
Config.forbiddenCols = 20
Config.forbiddenRows = 20

-- Gameplay Timings & Parameters
Config.baseSpeed = 0.12
Config.minSpeed = 0.06
Config.initialLives = 3
Config.maxLives = 5
Config.invincibleDuration = 2.0
Config.noCollisionDuration = 4.0
Config.glowDuration = 5.0
Config.rainbowDuration = 10.0
Config.frostDuration = 5.0
Config.magnetDuration = 6.0
Config.lustDuration = 5.0
Config.lustMultiplier = 3
Config.holeEffectDuration = 5.0
Config.fourthWallDuration = 15.0
Config.fourthWallMaxOutside = 5.0
Config.fifthWallDuration = 15.0
Config.forbiddenDuration = 8.0
Config.speedFoodDuration = 5.0
Config.speedFoodMultiplier = 1.8
Config.stopDuration = 5.0
Config.boxSpawnInterval = 18.0
Config.maxBoxes = 3
Config.initialBoxes = 1
Config.boxScore = 100
Config.maxOutsideFoods = 3
Config.maxOutsideBoxes = 2
Config.outsideMargin = 8
Config.outsideSpawnInterval = 4.0

-- Spawning Intervals & Durations
Config.powerUpSpawnInterval = 7.0
Config.powerUpDuration = 6.0
Config.greenFruitSpawnInterval = 8.0
Config.greenFruitDuration = 5.0
Config.goldenFruitSpawnInterval = 25.0
Config.goldenFruitDuration = 4.0
Config.forbiddenFoodDuration = 5.0

-- Female Snake Parameters
Config.femaleDuration = 300 -- 5 minutes
Config.femaleLives = 3
Config.femaleMaxLives = 5
Config.matingCooldownMax = 10.0

-- Power-up Type Registry (Curated Roster + Requested Classical Powers)
Config.powerUpTypes = {
    "shorten",
    "reverse",
    "nocollision",
    "slowdown",
    "extralife",
    "devilfruit",
    "rainbow",
    "magnet",
    "colorchange",
    "whitehole",
    "blackhole",
    "wormhole",
    "mate",
    "lustfood",
    "forbidden",
    "fourthwall",
    "fifthwall",
    "speedfood",
    "stopfood"
}

-- Color Palettes
Config.colors = {
    -- Foods
    food        = {0.95, 0.25, 0.25},
    greenfruit  = {0.5, 1.0, 0.3},
    goldenfruit = {1.0, 0.85, 0.2},

    -- Forbidden Shards
    forbidden_food_1 = {0.2, 0.9, 0.4},  -- Cosmic Shard (Emerald)
    forbidden_food_2 = {0.2, 0.85, 1.0}, -- Chrono Shard (Cyan)

    -- Power-ups
    shorten     = {0.8, 0.4, 0.9},
    reverse     = {0.2, 0.9, 0.9},
    nocollision = {0.0, 1.0, 0.6},
    slowdown    = {0.3, 0.7, 1.0},
    extralife   = {0.95, 0.2, 0.5},
    devilfruit  = {0.95, 0.1, 0.1},
    rainbow     = {0.9, 0.2, 0.9},
    magnet      = {0.15, 0.15, 0.25},
    colorchange = {0.2, 0.9, 0.6},
    whitehole   = {1.0, 1.0, 1.0},
    blackhole   = {0.0, 0.0, 0.0},
    wormhole    = {0.19, 0.10, 0.20},
    mate        = {1.0, 0.4, 0.7},
    lustfood    = {1.0, 0.08, 0.58},
    forbidden   = {0.6, 0.1, 0.8},
    fourthwall  = {0.0, 0.8, 0.8},
    fifthwall   = {0.0, 1.0, 0.4},
    speedfood   = {1.0, 0.9, 0.1},
    stopfood    = {0.95, 0.25, 0.25},
    box         = {0.68, 0.42, 0.22},
    boxBorder   = {0.38, 0.22, 0.08},

    -- Snake Defaults
    snakeHead   = {0.6, 0.95, 0.3},
    snakeBody   = {0.35, 0.85, 0.2},
    devilSkin   = {0.95, 0.1, 0.1},
    femaleColor = {1.0, 0.4, 0.7},
    immortalGold= {0.85, 0.7, 0.2}
}

return Config
