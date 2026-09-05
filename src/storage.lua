-- ============================================================
-- SNAKE PRO - PERSISTENT JSON STORAGE
-- ============================================================
local json = require("lib/json")

local Storage = {}
local SAVE_FILENAME = "game_data.json"
local LEGACY_HIGHSCORE_FILE = "snake_highscore.txt"

-- Default Profile Data Structure
local defaultData = {
    isFirstTime = true,
    highScore = 0,
    coins = 0,
    upgrades = {},
    discoveredItems = {},
    history = {},
    stats = {
        gamesPlayed = 0,
        totalScore = 0,
        totalFoodsEaten = 0,
        totalCoinsCollected = 0,
        totalMatings = 0,
        totalDevilFruits = 0,
        immortalAscensions = 0,
        totalPlayTime = 0
    }
}

Storage.data = nil

-- Deep copy helper
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Initialize and load profile data
function Storage.load()
    if Storage.data then return Storage.data end
    Storage.data = deepCopy(defaultData)

    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(SAVE_FILENAME) then
        local content = love.filesystem.read(SAVE_FILENAME)
        if content and #content > 0 then
            local success, parsed = pcall(json.decode, content)
            if success and type(parsed) == "table" then
                if parsed.isFirstTime ~= nil then Storage.data.isFirstTime = parsed.isFirstTime end
                if parsed.highScore ~= nil then Storage.data.highScore = parsed.highScore end
                if parsed.coins ~= nil then Storage.data.coins = parsed.coins end
                if type(parsed.upgrades) == "table" then Storage.data.upgrades = parsed.upgrades end
                if type(parsed.discoveredItems) == "table" then Storage.data.discoveredItems = parsed.discoveredItems end
                if type(parsed.history) == "table" then Storage.data.history = parsed.history end
                if type(parsed.stats) == "table" then
                    for k, v in pairs(parsed.stats) do
                        Storage.data.stats[k] = v
                    end
                end
                return Storage.data
            end
        end
    end

    -- Migrate legacy high score if available
    if love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(LEGACY_HIGHSCORE_FILE) then
        local legacyContent = love.filesystem.read(LEGACY_HIGHSCORE_FILE)
        if legacyContent then
            local legacyScore = tonumber(legacyContent) or 0
            if legacyScore > Storage.data.highScore then
                Storage.data.highScore = legacyScore
            end
        end
    end

    Storage.save()
    return Storage.data
end

-- Save profile data to JSON
function Storage.save()
    if not Storage.data then Storage.data = deepCopy(defaultData) end
    if love.filesystem and love.filesystem.write then
        local success, encoded = pcall(json.encode, Storage.data)
        if success and encoded then
            love.filesystem.write(SAVE_FILENAME, encoded)
        end
    end
end

-- First time tutorial methods
function Storage.isFirstTime()
    if not Storage.data then Storage.load() end
    return Storage.data.isFirstTime == true
end

function Storage.completeFirstTime()
    if not Storage.data then Storage.load() end
    Storage.data.isFirstTime = false
    Storage.save()
end

-- High score accessors
function Storage.getHighScore()
    if not Storage.data then Storage.load() end
    return Storage.data.highScore or 0
end

function Storage.setHighScore(newScore)
    if not Storage.data then Storage.load() end
    if newScore > (Storage.data.highScore or 0) then
        Storage.data.highScore = newScore
        Storage.save()
    end
end

-- Discovery codex methods
function Storage.isDiscovered(itemKey)
    if not Storage.data then Storage.load() end
    return Storage.data.discoveredItems[itemKey] == true
end

function Storage.markDiscovered(itemKey)
    if not Storage.data then Storage.load() end
    if not Storage.data.discoveredItems[itemKey] then
        Storage.data.discoveredItems[itemKey] = true
        Storage.save()
        return true -- was newly discovered
    end
    return false
end

function Storage.getDiscoveredCount(totalItems, validKeys)
    if not Storage.data then Storage.load() end
    local count = 0
    for k, v in pairs(Storage.data.discoveredItems or {}) do
        if v == true then
            if not validKeys or validKeys[k] then
                count = count + 1
            end
        end
    end
    return count, totalItems or 24
end

-- Match history & career statistics
function Storage.addHistoryRecord(record)
    if not Storage.data then Storage.load() end
    
    local entry = {
        date = os.date("%Y-%m-%d %H:%M"),
        score = record.score or 0,
        devilFruits = record.devilFruits or 0,
        matings = record.matings or 0,
        duration = record.duration or 0,
        outcome = record.outcome or "Defeat"
    }

    table.insert(Storage.data.history, 1, entry) -- prepend latest run
    while #Storage.data.history > 50 do
        table.remove(Storage.data.history)
    end

    -- Update aggregate stats
    local s = Storage.data.stats
    s.gamesPlayed = (s.gamesPlayed or 0) + 1
    s.totalScore = (s.totalScore or 0) + entry.score
    s.totalFoodsEaten = (s.totalFoodsEaten or 0) + (record.foodsEaten or 0)
    s.totalMatings = (s.totalMatings or 0) + entry.matings
    s.totalDevilFruits = (s.totalDevilFruits or 0) + entry.devilFruits
    s.totalPlayTime = (s.totalPlayTime or 0) + entry.duration
    if entry.outcome == "Ascended" or entry.outcome == "Immortal" then
        s.immortalAscensions = (s.immortalAscensions or 0) + 1
    end
    if record.coins and record.coins > 0 then
        s.totalCoinsCollected = (s.totalCoinsCollected or 0) + record.coins
    end

    if entry.score > (Storage.data.highScore or 0) then
        Storage.data.highScore = entry.score
    end

    Storage.save()
end

function Storage.getHistory()
    if not Storage.data then Storage.load() end
    return Storage.data.history or {}
end

function Storage.getStats()
    if not Storage.data then Storage.load() end
    return Storage.data.stats or defaultData.stats
end

-- ============================================================
-- COINS & UPGRADES SYSTEM
-- ============================================================

function Storage.getCoins()
    if not Storage.data then Storage.load() end
    return Storage.data.coins or 0
end

function Storage.addCoins(amount)
    if not Storage.data then Storage.load() end
    amount = math.max(0, math.floor(amount or 0))
    Storage.data.coins = (Storage.data.coins or 0) + amount
    local s = Storage.data.stats
    s.totalCoinsCollected = (s.totalCoinsCollected or 0) + amount
    Storage.save()
    return Storage.data.coins
end

function Storage.spendCoins(amount)
    if not Storage.data then Storage.load() end
    amount = math.max(0, math.floor(amount or 0))
    if (Storage.data.coins or 0) >= amount then
        Storage.data.coins = Storage.data.coins - amount
        Storage.save()
        return true
    end
    return false
end

function Storage.getUpgradeLevel(upgradeId)
    if not Storage.data then Storage.load() end
    if not Storage.data.upgrades then Storage.data.upgrades = {} end
    return Storage.data.upgrades[upgradeId] or 1
end

function Storage.setUpgradeLevel(upgradeId, level)
    if not Storage.data then Storage.load() end
    if not Storage.data.upgrades then Storage.data.upgrades = {} end
    Storage.data.upgrades[upgradeId] = level
    Storage.save()
end

function Storage.getUpgradeConfig(upgradeId)
    local Config = require("config")
    for _, up in ipairs(Config.upgrades or {}) do
        if up.id == upgradeId then
            return up
        end
    end
    return nil
end

function Storage.getUpgradeValue(upgradeId, fallbackDefault)
    local up = Storage.getUpgradeConfig(upgradeId)
    if up and up.values then
        local lvl = Storage.getUpgradeLevel(upgradeId)
        lvl = math.max(1, math.min(#up.values, lvl))
        return up.values[lvl]
    end
    return fallbackDefault
end

function Storage.canAffordUpgrade(upgradeId)
    local up = Storage.getUpgradeConfig(upgradeId)
    if not up then return false, "Invalid upgrade", 0 end
    local currentLvl = Storage.getUpgradeLevel(upgradeId)
    if currentLvl >= (up.maxLevel or #up.costs) then
        return false, "Max level reached", 0
    end
    local nextCost = up.costs[currentLvl] or 0
    local coins = Storage.getCoins()
    if coins >= nextCost then
        return true, "Affordable", nextCost
    else
        return false, "Not enough coins", nextCost
    end
end

function Storage.buyUpgrade(upgradeId)
    local canAfford, reason, cost = Storage.canAffordUpgrade(upgradeId)
    if canAfford then
        if Storage.spendCoins(cost) then
            local curLvl = Storage.getUpgradeLevel(upgradeId)
            Storage.setUpgradeLevel(upgradeId, curLvl + 1)
            return true, curLvl + 1
        end
    end
    return false, reason
end

return Storage
