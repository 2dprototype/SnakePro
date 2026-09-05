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
Config.noCollisionDuration = 3.0
Config.glowDuration = 5.0
Config.rainbowDuration = 10.0
Config.lustDuration = 5.0
Config.lustMultiplier = 3
Config.holeEffectDuration = 5.0
Config.fourthWallDuration = 15.0
Config.fourthWallMaxOutside = 5.0
Config.fifthWallDuration = 15.0
Config.forbiddenDuration = 8.0

-- Spawning Intervals & Durations
Config.powerUpSpawnInterval = 7.0
Config.powerUpDuration = 6.0
Config.greenFruitSpawnInterval = 8.0
Config.greenFruitDuration = 5.0
Config.goldenFruitSpawnInterval = 30.0
Config.goldenFruitDuration = 3.0

-- Female Snake Parameters
Config.femaleDuration = 300 -- 5 minutes
Config.femaleLives = 3
Config.femaleMaxLives = 5
Config.matingCooldownMax = 10.0

-- Power-up Type Registry
Config.powerUpTypes = {
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
    "fourthwall",
    "fifthwall"
}

-- Color Palettes
Config.colors = {
    -- Foods
    food = {0.95, 0.2, 0.2},
    greenfruit = {0.5, 1.0, 0.3},
    goldenfruit = {1.0, 0.85, 0.2},

    -- Forbidden Foods
    forbidden_food_1 = {0.13, 0.55, 0.13}, -- green
    forbidden_food_2 = {0.95, 0.85, 0.1},  -- yellow
    forbidden_food_3 = {0.8, 0.2, 0.9},    -- purple
    forbidden_food_4 = {0.2, 0.9, 0.9},    -- cyan (adds time)

    -- Power-ups
    shorten     = {0.8, 0.4, 0.9},
    reverse     = {0.2, 0.9, 0.9},
    speedup     = {0.9, 0.9, 0.2},
    slowdown    = {0.2, 0.4, 0.9},
    extralife   = {0.9, 0.2, 0.6},
    scoreboost  = {0.9, 0.6, 0.2},
    colorchange = {0.2, 0.9, 0.6},
    devilfruit  = {0.9, 0.1, 0.1},
    lustfood    = {1.0, 0.08, 0.58},
    nocollision = {0.0, 1.0, 0.5},
    forbidden   = {0.5, 0.1, 0.5},
    mate        = {1.0, 0.4, 0.7},
    rainbow     = {0.9, 0.1, 0.8},
    wormhole    = {0.19, 0.10, 0.20},
    whitehole   = {1.0, 1.0, 1.0},
    blackhole   = {0.0, 0.0, 0.0},
    fourthwall  = {0.0, 0.8, 0.8},
    fifthwall   = {0.0, 1.0, 0.0},

    -- Snake Defaults
    snakeHead   = {0.6, 0.95, 0.3},
    snakeBody   = {0.35, 0.85, 0.2},
    devilSkin   = {0.9, 0.1, 0.1},
    femaleColor = {1.0, 0.4, 0.7},
    immortalGold= {0.85, 0.7, 0.2}
}

return Config
