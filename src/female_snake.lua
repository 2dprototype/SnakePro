-- ============================================================
-- SNAKE PRO - FEMALE AI SNAKE
-- ============================================================
local Config = require("config")
local Utils = require("utils")

local FemaleSnake = {}
FemaleSnake.__index = FemaleSnake

function FemaleSnake.new()
    local self = setmetatable({}, FemaleSnake)
    self:reset()
    return self
end

function FemaleSnake:reset()
    self.active = false
    self.body = nil
    self.direction = {x = 1, y = 0}
    self.nextDir = {x = 1, y = 0}
    self.timer = 0
    self.duration = Config.femaleDuration
    self.lives = Config.femaleLives
    self.maxLives = Config.femaleMaxLives

    self.invincible = false
    self.invincibleTimer = 0
    self.noCollision = false
    self.noCollisionTimer = 0
    self.lustActive = false
    self.lustTimer = 0
    self.speedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.inForbidden = false
    self.forbiddenTimer = 0
    self.glow = false
    self.glowTimer = 0

    self.color = {Config.colors.femaleColor[1], Config.colors.femaleColor[2], Config.colors.femaleColor[3]}
    self.moveTimer = 0
    self.devilPermanent = false
    self.devilColor = Config.colors.devilSkin
end

function FemaleSnake:spawn(freeCells, playerHead, inForbidden, forbiddenCols, forbiddenRows, game)
    if self.active or not freeCells or #freeCells < 5 then return false end

    -- Place female snake as far from player head as possible
    local sorted = {}
    for _, cell in ipairs(freeCells) do
        table.insert(sorted, {cell = cell, dist = Utils.distance(cell, playerHead or {x = 10, y = 10})})
    end
    table.sort(sorted, function(a, b) return a.dist > b.dist end)
    local start = sorted[1].cell

    self.body = {
        {x = start.x, y = start.y},
        {x = start.x - 1, y = start.y},
        {x = start.x - 2, y = start.y}
    }
    self.direction = {x = 1, y = 0}
    self.nextDir = {x = 1, y = 0}
    self.active = true
    self.timer = self.duration
    self.lives = Config.femaleLives
    self.invincible = false
    self.invincibleTimer = 0
    self.noCollision = false
    self.noCollisionTimer = 0
    self.lustActive = false
    self.lustTimer = 0
    self.speedMultiplier = 1.0
    self.tempSpeedTimer = 0
    self.inForbidden = inForbidden or false
    self.forbiddenTimer = 0
    self.glow = false
    self.glowTimer = 0
    self.color = {Config.colors.femaleColor[1], Config.colors.femaleColor[2], Config.colors.femaleColor[3]}
    self.moveTimer = 0
    self.devilPermanent = false

    Utils.playSFX("levelup", 1.2, 0.5)
    Utils.notify("Snake", "A pink female snake appeared!", nil, 3.0)
    if game and game.checkDiscovery then
        game:checkDiscovery("event_female_spawn")
    end
    return true
end

-- BFS pathfinding towards target items
function FemaleSnake:findPath(start, targets, obstacles, cols, rows)
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

function FemaleSnake:getDirection(playerSnake, food, powerUp, greenFruit, goldenFruit, forbiddenFoods)
    if not self.body or #self.body == 0 then return nil end
    local head = self.body[1]
    local cols = self.inForbidden and Config.forbiddenCols or Config.cols
    local rows = self.inForbidden and Config.forbiddenRows or Config.rows

    local obstacles = {}
    for i = 1, #self.body - 1 do
        table.insert(obstacles, self.body[i])
    end
    if not self.inForbidden and playerSnake then
        for i = 2, #playerSnake do
            table.insert(obstacles, playerSnake[i])
        end
    end

    local targets = {}
    if self.lustActive and not self.inForbidden and playerSnake and playerSnake[1] then
        table.insert(targets, 1, playerSnake[1])
        if goldenFruit then table.insert(targets, goldenFruit) end
        if greenFruit then table.insert(targets, greenFruit) end
        if powerUp and powerUp.type == "lustfood" then table.insert(targets, powerUp) end
        if food then table.insert(targets, food) end
    else
        if not self.inForbidden then
            if goldenFruit then table.insert(targets, 1, goldenFruit) end
            if greenFruit then table.insert(targets, greenFruit) end
            if powerUp and powerUp.type == "lustfood" then table.insert(targets, 1, powerUp) end
            if food then table.insert(targets, food) end
            if powerUp and powerUp.type ~= "lustfood" then table.insert(targets, powerUp) end
        else
            for _, f in ipairs(forbiddenFoods or {}) do
                table.insert(targets, f)
            end
            if food then table.insert(targets, food) end
            if greenFruit then table.insert(targets, greenFruit) end
            if powerUp then table.insert(targets, powerUp) end
            if goldenFruit then table.insert(targets, 1, goldenFruit) end
        end
    end

    if #targets == 0 then return nil end

    for _, t in ipairs(targets) do
        local step = self:findPath(head, {t}, obstacles, cols, rows)
        if step then
            return {x = step.x - head.x, y = step.y - head.y}
        end
    end
    return nil
end

function FemaleSnake:applyPowerUp(powerUp, game)
    local ptype = powerUp.type
    if ptype == "shorten" then
        for i = 1, 3 do if #self.body > 3 then table.remove(self.body) end end
    elseif ptype == "reverse" then
        local reversed = {}
        for i = #self.body, 1, -1 do
            table.insert(reversed, self.body[i])
        end
        self.body = reversed
        self.direction = {x = -self.direction.x, y = -self.direction.y}
        self.nextDir = {x = self.direction.x, y = self.direction.y}
    elseif ptype == "slowdown" then
        self.speedMultiplier = 0.5
        self.tempSpeedTimer = Config.frostDuration
    elseif ptype == "extralife" then
        if self.lives < self.maxLives then self.lives = self.lives + 1 end
    elseif ptype == "colorchange" then
        self.devilPermanent = false
        self.color = Utils.getPrismColor(0)
        Utils.notify("Snake", "Female absorbed live prism hue!", nil, 1.8)
    elseif ptype == "devilfruit" then
        game:addScore(100)
        self.devilPermanent = true
        self.color = self.devilColor
        self.speedMultiplier = 1.4
        self.tempSpeedTimer = 3.0
    elseif ptype == "lustfood" then
        self.lustActive = true
        self.lustTimer = Config.lustDuration
    elseif ptype == "nocollision" then
        self.noCollision = true
        self.noCollisionTimer = Config.noCollisionDuration
    elseif ptype == "wormhole" then
        local cols = self.inForbidden and Config.forbiddenCols or Config.cols
        local rows = self.inForbidden and Config.forbiddenRows or Config.rows
        local free = Utils.findFreeCells(game.snake, game.food, game.powerUp, game.greenFruit, game.goldenFruit, game.forbiddenFoods, cols, rows, self.body)
        if #free > 0 then
            local newHead = free[math.random(1, #free)]
            local oldHead = self.body[1]
            local offX = newHead.x - oldHead.x
            local offY = newHead.y - oldHead.y
            for _, seg in ipairs(self.body) do
                seg.x = seg.x + offX
                seg.y = seg.y + offY
                while seg.x < 1 do seg.x = seg.x + cols end
                while seg.x > cols do seg.x = seg.x - cols end
                while seg.y < 1 do seg.y = seg.y + rows end
                while seg.y > rows do seg.y = seg.y - rows end
            end
        end
    elseif ptype == "forbidden" then
        if not self.inForbidden then
            self.inForbidden = true
            self.forbiddenTimer = Config.forbiddenDuration
            local cols = Config.forbiddenCols
            local rows = Config.forbiddenRows
            self.body = {
                {x = math.floor(cols/2), y = math.floor(rows/2)},
                {x = math.floor(cols/2)-1, y = math.floor(rows/2)},
                {x = math.floor(cols/2)-2, y = math.floor(rows/2)}
            }
            self.direction = {x = 1, y = 0}
            self.nextDir = {x = 1, y = 0}
        end
    elseif ptype == "mate" then
        self.timer = math.min(self.timer + 30, 600)
        game:addScore(50)
        Utils.notify("Snake", "Female time extended!", nil, 2.0)
    elseif ptype == "rainbow" then
        self.invincible = true
        self.invincibleTimer = Config.rainbowDuration
    end
    Utils.playSFX("tick", 1.0, 0.3)
end

function FemaleSnake:applyGoldenFruit(fruit, game)
    if self.lives < self.maxLives then
        self.lives = self.lives + 1
    end
    game:addScore(250)
    self.invincible = true
    self.invincibleTimer = 3.0
    Utils.notify("Snake", "Female ate Golden Apple! +250 & Life!", nil, 2.0)
    Utils.playSFX("levelup", 2.0, 0.9)
end

function FemaleSnake:update(dt, game)
    if not self.active or not self.body then return end

    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.active = false
        self.body = nil
        Utils.notify("Snake", "Female snake disappeared into the walls!", nil, 3.0)
        return
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
    if self.tempSpeedTimer > 0 then
        self.tempSpeedTimer = self.tempSpeedTimer - dt
        if self.tempSpeedTimer <= 0 then self.speedMultiplier = 1.0 end
    end
    if self.glow then
        self.glowTimer = self.glowTimer - dt
        if self.glowTimer <= 0 then self.glow = false end
    end
    if self.inForbidden then
        self.forbiddenTimer = self.forbiddenTimer - dt
        if self.forbiddenTimer <= 0 then
            self.inForbidden = false
            local head = self.body[1]
            head.x = math.min(head.x, Config.cols)
            head.y = math.min(head.y, Config.rows)
        end
    end

    local currentSpeed = Config.baseSpeed * (1 / self.speedMultiplier)
    self.moveTimer = self.moveTimer + dt
    if self.moveTimer >= currentSpeed then
        self.moveTimer = 0

        local cols = self.inForbidden and Config.forbiddenCols or Config.cols
        local rows = self.inForbidden and Config.forbiddenRows or Config.rows

        local dir = self:getDirection(game.snake, game.food, game.powerUp, game.greenFruit, game.goldenFruit, game.forbiddenFoods)
        if dir then
            self.nextDir = dir
        else
            local possible = {}
            local rev = {x = -self.direction.x, y = -self.direction.y}
            for _, d in ipairs({{0, -1}, {0, 1}, {-1, 0}, {1, 0}}) do
                if not (d[1] == rev.x and d[2] == rev.y) then
                    local nx = self.body[1].x + d[1]
                    local ny = self.body[1].y + d[2]
                    local blocked = (nx < 1 or nx > cols or ny < 1 or ny > rows)
                    if not blocked then
                        for i = 1, #self.body - 1 do
                            if self.body[i].x == nx and self.body[i].y == ny then
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
                self.nextDir = possible[math.random(1, #possible)]
            else
                self.nextDir = {x = -self.direction.x, y = -self.direction.y}
            end
        end

        self.direction = {x = self.nextDir.x, y = self.nextDir.y}
        local head = self.body[1]
        local newHead = {x = head.x + self.direction.x, y = head.y + self.direction.y}

        if newHead.x < 1 then newHead.x = cols end
        if newHead.x > cols then newHead.x = 1 end
        if newHead.y < 1 then newHead.y = rows end
        if newHead.y > rows then newHead.y = 1 end

        -- Self-collision
        if not self.noCollision and not self.invincible then
            for i = 1, #self.body - 1 do
                if self.body[i].x == newHead.x and self.body[i].y == newHead.y then
                    self.lives = self.lives - 1
                    if self.lives <= 0 then
                        self.active = false
                        self.body = nil
                        Utils.notify("Snake", "Female snake died!", nil, 3.0)
                        return
                    else
                        self.invincible = true
                        self.invincibleTimer = Config.invincibleDuration
                        while #self.body > 3 do table.remove(self.body) end
                        self.direction = {x = 1, y = 0}
                        self.nextDir = {x = 1, y = 0}
                        self.devilPermanent = false
                        self.color = {Config.colors.femaleColor[1], Config.colors.femaleColor[2], Config.colors.femaleColor[3]}
                    end
                    return
                end
            end
        end

        table.insert(self.body, 1, newHead)

        -- Eat items
        local ate = false
        if not self.inForbidden then
            if game.food and newHead.x == game.food.x and newHead.y == game.food.y then
                local pts = 10 * (self.lustActive and Config.lustMultiplier or 1)
                game:addScore(pts)
                game:updateBaseSpeed()
                Utils.playSFX("tick", 1.5, 0.5)
                game:spawnFood()
                ate = true
            end
            if game.greenFruit and newHead.x == game.greenFruit.x and newHead.y == game.greenFruit.y then
                local pts = 200 * (self.lustActive and Config.lustMultiplier or 1)
                game:addScore(pts)
                self.glow = true
                self.glowTimer = Config.glowDuration
                self.speedMultiplier = self.speedMultiplier + 0.6
                self.tempSpeedTimer = Config.glowDuration
                game.greenFruit = nil
                game.greenFruitTimer = 0
                Utils.playSFX("levelup", 1.8, 0.8)
                Utils.notify("Snake", "Female ate Lime Green Apple! Glow & Speed!", nil, 2.0)
                ate = true
            end
            if game.powerUp and newHead.x == game.powerUp.x and newHead.y == game.powerUp.y then
                self:applyPowerUp(game.powerUp, game)
                game.powerUp = nil
                ate = true
            end
            if game.goldenFruit and newHead.x == game.goldenFruit.x and newHead.y == game.goldenFruit.y then
                self:applyGoldenFruit(game.goldenFruit, game)
                game.goldenFruit = nil
                game.goldenFruitTimer = 0
                ate = true
            end
        else
            for i = #game.forbiddenFoods, 1, -1 do
                local f = game.forbiddenFoods[i]
                if newHead.x == f.x and newHead.y == f.y then
                    if f.type == 2 then
                        game.forbiddenTimer = math.min(game.forbiddenTimer + 2.5, 15.0)
                        Utils.playSFX("levelup", 1.2, 0.6)
                        Utils.notify("Snake", "+2.5s in Forbidden Realm!", nil, 1.5)
                    else
                        local pts = 30 * (self.lustActive and Config.lustMultiplier or 1)
                        game:addScore(pts)
                        Utils.playSFX("tick", 1.6, 0.5)
                    end
                    table.remove(game.forbiddenFoods, i)
                    ate = true
                    break
                end
            end
        end

        if not ate then
            table.remove(self.body)
        end

        -- Mating check with player
        if self.active and not game.gameOver and game.snake and game.snake[1] then
            local pHead = game.snake[1]
            if pHead.x == newHead.x and pHead.y == newHead.y and game.matingCooldown <= 0 then
                game:triggerMating()
            end
        end
    end
end

function FemaleSnake:draw(boardX, boardY, gridSize, scale, blinkVisible)
    if not self.active or not self.body then return end

    local shouldSkip = (self.invincible or self.noCollision) and not blinkVisible

    for i, seg in ipairs(self.body) do
        local sx = boardX + (seg.x - 1) * gridSize * scale
        local sy = boardY + (seg.y - 1) * gridSize * scale
        local size = gridSize * scale

        if not shouldSkip then
            if self.glow then
                love.graphics.setColor(1.0, 0.4, 0.7, 0.4)
                love.graphics.rectangle("fill", sx - 2, sy - 2, size + 4, size + 4, 6, 6)
            end

            if i == 1 then
                if self.devilPermanent then
                    love.graphics.setColor(self.devilColor)
                else
                    love.graphics.setColor(self.color)
                end
            else
                local bodyCol = self.devilPermanent and self.devilColor or self.color
                love.graphics.setColor(bodyCol[1] * 0.7, bodyCol[2] * 0.7, bodyCol[3] * 0.7)
            end

            love.graphics.rectangle("fill", sx + 1, sy + 1, size - 2, size - 2, 3, 3)
            love.graphics.setColor(1.0, 0.7, 0.9, 0.2)
            love.graphics.rectangle("fill", sx + 3, sy + 3, size - 8, size - 8, 2, 2)
        end
    end
end

return FemaleSnake
