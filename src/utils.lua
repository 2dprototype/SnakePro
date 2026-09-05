-- ============================================================
-- SNAKE PRO - UTILITIES
-- ============================================================
local bit = require("bit")

local Utils = {}

-- Random RGB color tuple in range [0, 1]
function Utils.randomColor()
    return {math.random(), math.random(), math.random()}
end

-- Linear interpolation between two RGB color arrays
function Utils.lerpColor(c1, c2, t)
    return {
        c1[1] + (c2[1] - c1[1]) * t,
        c1[2] + (c2[2] - c1[2]) * t,
        c1[3] + (c2[3] - c1[3]) * t
    }
end

-- Manhattan distance between two grid points
function Utils.distance(p1, p2)
    return math.abs(p1.x - p2.x) + math.abs(p1.y - p2.y)
end

-- Shallow / 1-level copy of a table or array of tables
function Utils.shallowCopyTable(orig)
    if not orig then return {} end
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            local sub = {}
            for sk, sv in pairs(v) do sub[sk] = sv end
            copy[k] = sub
        else
            copy[k] = v
        end
    end
    return copy
end

-- Convert HSV (0-1) to RGB (0-1)
function Utils.hsvToRgb(h, s, v)
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

-- Get live animated Prism Dye color at current time
function Utils.getPrismColor(timeOffset)
    local t = ((love.timer and love.timer.getTime() or os.clock()) + (timeOffset or 0)) * 0.75
    local hue = t % 1.0
    local r, g, b = Utils.hsvToRgb(hue, 0.95, 1.0)
    return {r, g, b}
end

-- Convert [0,1] RGB or RGBA array to 32-bit ARGB uint for SDL2 surfaces
function Utils.toUintColor(colorArr, alpha)
    local a = math.floor((alpha or colorArr[4] or 1.0) * 255)
    local r = math.floor(colorArr[1] * 255)
    local g = math.floor(colorArr[2] * 255)
    local b = math.floor(colorArr[3] * 255)
    return bit.lshift(a, 24) + bit.lshift(r, 16) + bit.lshift(g, 8) + b
end

-- Find all unoccupied grid coordinates
function Utils.findFreeCells(snake, food, powerUp, greenFruit, goldenFruit, forbiddenFoods, cols, rows, femaleSnake, boxes, coin)
    local free = {}
    for r = 1, rows do
        for c = 1, cols do
            local occ = false
            if snake then
                for _, seg in ipairs(snake) do
                    if seg.x == c and seg.y == r then occ = true; break end
                end
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
            if not occ and coin and coin.x == c and coin.y == r then occ = true end
            if not occ and forbiddenFoods then
                for _, ff in ipairs(forbiddenFoods) do
                    if ff.x == c and ff.y == r then occ = true; break end
                end
            end
            if not occ and boxes then
                for _, b in ipairs(boxes) do
                    if b.x == c and b.y == r then occ = true; break end
                end
            end
            if not occ then
                table.insert(free, {x = c, y = r})
            end
        end
    end
    return free
end

-- Check if a specific cell (x, y) is empty
function Utils.isEmptyCell(x, y, snake, femaleSnake, food, powerUp, greenFruit, goldenFruit, forbiddenFoods, excludeItem, boxes, coin)
    if snake then
        for _, seg in ipairs(snake) do
            if seg.x == x and seg.y == y then return false end
        end
    end
    if femaleSnake then
        for _, seg in ipairs(femaleSnake) do
            if seg.x == x and seg.y == y then return false end
        end
    end
    if boxes then
        for _, b in ipairs(boxes) do
            if excludeItem ~= b and b.x == x and b.y == y then return false end
        end
    end
    if food and excludeItem ~= food and food.x == x and food.y == y then return false end
    if powerUp and excludeItem ~= powerUp and powerUp.x == x and powerUp.y == y then return false end
    if greenFruit and excludeItem ~= greenFruit and greenFruit.x == x and greenFruit.y == y then return false end
    if goldenFruit and excludeItem ~= goldenFruit and goldenFruit.x == x and goldenFruit.y == y then return false end
    if coin and excludeItem ~= coin and coin.x == x and coin.y == y then return false end
    if forbiddenFoods then
        for _, f in ipairs(forbiddenFoods) do
            if excludeItem ~= f and f.x == x and f.y == y then return false end
        end
    end
    return true
end

-- High Score Storage
function Utils.loadHighScore(filename)
    filename = filename or "snake_highscore.txt"
    if love.filesystem and love.filesystem.getInfo then
        if love.filesystem.getInfo(filename) then
            local content = love.filesystem.read(filename)
            if content then
                return tonumber(content) or 0
            end
        end
    end
    return 0
end

function Utils.saveHighScore(score, filename)
    filename = filename or "snake_highscore.txt"
    if love.filesystem and love.filesystem.write then
        love.filesystem.write(filename, tostring(score))
    end
end

-- Safe Audio Player
function Utils.playSFX(name, pitch, volume)
    if _G.AudioManager and _G.AudioManager.playSFX then
        _G.AudioManager.playSFX(name, pitch, volume)
    end
end

-- Safe Notification Displayer
function Utils.notify(title, msg, icon, duration)
    if _G.Notifications and _G.Notifications.add then
        _G.Notifications.add(title, msg, icon, duration)
    end
end

return Utils
