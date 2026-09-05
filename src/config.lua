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
Config.magnetDuration = 26.0
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
Config.gravityFruitDuration = 25.0
Config.antigravityDuration = 25.0
Config.physicsFruitDuration = 25.0
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
Config.coinSpawnInterval = 14.0
Config.coinDuration = 8.0

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
    "stopfood",
    "gravityfruit",
    "antigravity",
    "physicsfruit"
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
    shorten      = {0.8, 0.4, 0.9},
    reverse      = {0.2, 0.9, 0.9},
    nocollision  = {0.0, 1.0, 0.6},
    slowdown     = {0.3, 0.7, 1.0},
    extralife    = {0.95, 0.2, 0.5},
    devilfruit   = {0.95, 0.1, 0.1},
    rainbow      = {0.9, 0.2, 0.9},
    magnet       = {0.15, 0.15, 0.25},
    colorchange  = {0.2, 0.9, 0.6},
    whitehole    = {1.0, 1.0, 1.0},
    blackhole    = {0.0, 0.0, 0.0},
    wormhole     = {0.19, 0.10, 0.20},
    mate         = {1.0, 0.4, 0.7},
    lustfood     = {1.0, 0.08, 0.58},
    forbidden    = {0.6, 0.1, 0.8},
    fourthwall   = {0.0, 0.8, 0.8},
    fifthwall    = {0.0, 1.0, 0.4},
    speedfood    = {1.0, 0.9, 0.1},
    stopfood     = {0.95, 0.25, 0.25},
    gravityfruit = {0.6, 0.25, 0.85},
    antigravity  = {0.2, 0.9, 0.85},
    physicsfruit = {0.95, 0.8, 0.1},
    box          = {0.68, 0.42, 0.22},
    boxBorder   = {0.38, 0.22, 0.08},
    coin         = {1.0, 0.84, 0.0},
    coinBorder   = {0.85, 0.65, 0.0},

    -- Snake Defaults
    snakeHead   = {0.6, 0.95, 0.3},
    snakeBody   = {0.35, 0.85, 0.2},
    devilSkin   = {0.95, 0.1, 0.1},
    femaleColor = {1.0, 0.4, 0.7},
    immortalGold= {0.85, 0.7, 0.2}
}

-- Permanent Upgrades Catalog (Purchasable with Coins)
Config.upgrades = {
    {
        id = "apple_value",
        name = "Apple Yield",
        iconKey = "food",
        category = "Fruits",
        desc = "Increases score points awarded by standard red apples.",
        unit = "pts",
        maxLevel = 5,
        costs = {5, 10, 20, 35, 50},
        values = {10, 15, 20, 25, 35}
    },
    {
        id = "green_duration",
        name = "Lime Glow Duration",
        iconKey = "greenfruit",
        category = "Fruits",
        desc = "Extends the duration of Lime Green Apple's energetic glow and speed boost.",
        unit = "s",
        maxLevel = 5,
        costs = {8, 15, 25, 40, 60},
        values = {5.0, 6.5, 8.0, 10.0, 12.0}
    },
    {
        id = "green_spawn",
        name = "Lime Apple Spawn Rate",
        iconKey = "greenfruit",
        category = "Fruits",
        desc = "Causes glowing Lime Green Apples to spawn much more frequently on the board.",
        unit = "s interval",
        maxLevel = 5,
        costs = {10, 20, 35, 50, 75},
        values = {8.0, 7.0, 6.0, 5.0, 4.0}
    },
    {
        id = "golden_duration",
        name = "Golden Shield Duration",
        iconKey = "goldenfruit",
        category = "Fruits",
        desc = "Extends the duration of Golden Apple's invincibility shield.",
        unit = "s",
        maxLevel = 5,
        costs = {12, 25, 45, 70, 100},
        values = {3.0, 4.0, 5.5, 7.0, 9.0}
    },
    {
        id = "golden_spawn",
        name = "Golden Apple Spawn Rate",
        iconKey = "goldenfruit",
        category = "Fruits",
        desc = "Shortens spawn delay between legendary Golden Apples appearing.",
        unit = "s interval",
        maxLevel = 5,
        costs = {15, 30, 50, 80, 120},
        values = {25.0, 21.0, 17.0, 14.0, 11.0}
    },
    {
        id = "speed_duration",
        name = "Thunder Surge Duration",
        iconKey = "speedfood",
        category = "Power-ups",
        desc = "Extends the duration of lightning speed boost from Thunder Surge power-up.",
        unit = "s",
        maxLevel = 5,
        costs = {8, 15, 25, 40, 60},
        values = {5.0, 6.5, 8.0, 9.5, 12.0}
    },
    {
        id = "ghost_duration",
        name = "Ghost Phase Duration",
        iconKey = "nocollision",
        category = "Power-ups",
        desc = "Extends how long the snake can phase straight through its own body safely.",
        unit = "s",
        maxLevel = 5,
        costs = {8, 15, 25, 40, 60},
        values = {4.0, 5.5, 7.0, 8.5, 10.0}
    },
    {
        id = "magnet_duration",
        name = "Cosmic Magnet Duration",
        iconKey = "magnet",
        category = "Power-ups",
        desc = "Extends the duration of the Cosmic Magnet food vacuum field.",
        unit = "s",
        maxLevel = 5,
        costs = {10, 20, 35, 55, 80},
        values = {6.0, 8.0, 10.0, 12.5, 15.0}
    },
    {
        id = "lust_duration",
        name = "Lust Berry Duration",
        iconKey = "lustfood",
        category = "Power-ups",
        desc = "Extends the active duration of Lust Mode and 3x multiplier.",
        unit = "s",
        maxLevel = 5,
        costs = {10, 20, 35, 55, 80},
        values = {5.0, 6.5, 8.0, 9.5, 11.0}
    },
    {
        id = "coin_spawn",
        name = "Coin Fortune",
        iconKey = "coin",
        category = "Currency",
        desc = "Increases Gold Coin appearance frequency across the arena.",
        unit = "s interval",
        maxLevel = 5,
        costs = {10, 20, 35, 50, 75},
        values = {14.0, 11.5, 9.0, 7.0, 5.0}
    }
}

return Config
