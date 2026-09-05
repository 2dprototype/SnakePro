-- ============================================================
-- SNAKE PRO - MENU SYSTEM
-- ============================================================
local Config = require("config")
local Utils = require("utils")

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)
    self.state = "main_menu" -- "main_menu", "pause_menu", "controls"
    self.selectedIndex = 1
    self.hoveredIndex = nil

    -- Load fonts
    self.font = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 13) or love.graphics.newFont(13)
    self.largeFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 22) or love.graphics.newFont(22)
    self.titleFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 28) or love.graphics.newFont(28)
    self.smallFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 10) or love.graphics.newFont(10)

    self.buttonRects = {}
    return self
end

function Menu:getItems()
    if self.state == "main_menu" then
        return {
            {id = "start", label = "START GAME"},
            {id = "controls", label = "CONTROLS & GUIDE"},
            {id = "exit", label = "EXIT GAME"}
        }
    elseif self.state == "pause_menu" then
        return {
            {id = "resume", label = "RESUME GAME"},
            {id = "restart", label = "START NEW"},
            {id = "main_menu", label = "MAIN MENU"},
            {id = "exit", label = "EXIT GAME"}
        }
    elseif self.state == "controls" then
        return {
            {id = "back", label = "< BACK"}
        }
    end
    return {}
end

function Menu:setState(newState)
    self.state = newState
    self.selectedIndex = 1
    self.hoveredIndex = nil
end

function Menu:keypressed(key, game)
    if self.state == "controls" then
        if key == "escape" or key == "return" or key == "space" or key == "backspace" then
            Utils.playSFX("tick", 1.0, 0.4)
            self:setState(self.previousState or "main_menu")
            return true
        end
        return true
    end

    local items = self:getItems()
    if #items == 0 then return false end

    if key == "up" or key == "w" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then self.selectedIndex = #items end
        Utils.playSFX("tick", 1.2, 0.3)
        return true
    elseif key == "down" or key == "s" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #items then self.selectedIndex = 1 end
        Utils.playSFX("tick", 1.2, 0.3)
        return true
    elseif key == "return" or key == "space" then
        local selected = items[self.selectedIndex]
        if selected then
            self:triggerAction(selected.id, game)
        end
        return true
    elseif key == "escape" then
        if self.state == "pause_menu" then
            -- ESC in pause menu resumes the game
            self:triggerAction("resume", game)
            return true
        end
    end
    return false
end

function Menu:mousemoved(x, y)
    self.hoveredIndex = nil
    for i, rect in ipairs(self.buttonRects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            self.hoveredIndex = i
            self.selectedIndex = i
            break
        end
    end
end

function Menu:mousepressed(x, y, button, game)
    if button == 1 then
        for i, rect in ipairs(self.buttonRects) do
            if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
                local items = self:getItems()
                if items[i] then
                    self:triggerAction(items[i].id, game)
                    return true
                end
            end
        end
    end
    return false
end

function Menu:touchpressed(id, x, y, game)
    for i, rect in ipairs(self.buttonRects) do
        if x >= rect.x and x <= rect.x + rect.w and y >= rect.y and y <= rect.y + rect.h then
            local items = self:getItems()
            if items[i] then
                self:triggerAction(items[i].id, game)
                return true
            end
        end
    end
    return false
end

function Menu:triggerAction(actionId, game)
    Utils.playSFX("levelup", 1.2, 0.5)

    if actionId == "start" then
        game:reset()
        _G.GameState = "playing"
    elseif actionId == "resume" then
        _G.GameState = "playing"
    elseif actionId == "restart" then
        game:reset()
        _G.GameState = "playing"
    elseif actionId == "controls" then
        self.previousState = self.state
        self:setState("controls")
    elseif actionId == "back" then
        self:setState(self.previousState or "main_menu")
    elseif actionId == "main_menu" then
        self:setState("main_menu")
        _G.GameState = "main_menu"
    elseif actionId == "exit" then
        love.event.quit()
    end
end

function Menu:draw(width, height, game)
    self.buttonRects = {}
    local time = love.timer.getTime()

    if self.state == "pause_menu" then
        -- Semi-transparent backdrop over active game
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, width, height)

        -- Pause title
        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(0.35, 0.75, 1.0)
        love.graphics.printf("GAME PAUSED", 0, height * 0.18, width, "center")

        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Press [ESC] to Resume", 0, height * 0.27, width, "center")

    elseif self.state == "main_menu" then
        -- Dark animated background
        love.graphics.setColor(0.02, 0.02, 0.04)
        love.graphics.rectangle("fill", 0, 0, width, height)

        -- Subtle retro grid lines
        love.graphics.setColor(0.08, 0.08, 0.14, 0.5)
        for gy = 0, height, 20 do
            love.graphics.line(0, gy, width, gy)
        end
        for gx = 0, width, 20 do
            love.graphics.line(gx, 0, gx, height)
        end

        -- Title with glowing effect
        love.graphics.setFont(self.titleFont)
        local glow = 0.8 + 0.2 * math.sin(time * 3)
        love.graphics.setColor(0.35 * glow, 0.85 * glow, 0.2 * glow)
        love.graphics.printf("S N A K E   P R O", 0, height * 0.14, width, "center")

        -- Subtitle / High score
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.85, 0.75, 0.3)
        local highScore = game and game.highScore or Utils.loadHighScore()
        love.graphics.printf("HIGH SCORE: " .. tostring(highScore), 0, height * 0.24, width, "center")

    elseif self.state == "controls" then
        -- Controls Screen
        love.graphics.setColor(0.02, 0.02, 0.04)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setFont(self.largeFont)
        love.graphics.setColor(0.35, 0.75, 1.0)
        love.graphics.printf("CONTROLS & GUIDE", 0, 16, width, "center")

        love.graphics.setFont(self.font)
        love.graphics.setColor(0.9, 0.9, 0.9)

        local lines = {
            {"Movement:", "W A S D / Arrow Keys / Swipe"},
            {"Pause Menu:", "[ESC] - Pause / Resume / Exit"},
            {"Quick Restart:", "[R] Key"},
            {"Debug Spawn:", "Type [Code 01-28] + Enter at mouse"},
            {"Immortal Ending:", "Bite your own tail!"},
            {"5th Wall Break:", "Escape the game window into desktop"}
        }

        local startY = 65
        for _, pair in ipairs(lines) do
            love.graphics.setColor(0.5, 0.8, 1.0)
            love.graphics.print(pair[1], 24, startY)
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(pair[2], 150, startY)
            startY = startY + 28
        end
    end

    -- Render Menu Option Buttons
    local items = self:getItems()
    local btnW = 220
    local btnH = 34
    local startY = (self.state == "controls") and (height - 60) or (height * 0.36)
    local spacing = 44

    for i, item in ipairs(items) do
        local btnX = (width - btnW) / 2
        local btnY = startY + (i - 1) * spacing
        local isSelected = (i == self.selectedIndex)

        table.insert(self.buttonRects, {x = btnX, y = btnY, w = btnW, h = btnH})

        if isSelected then
            -- Selected button highlight
            local pulse = 0.85 + 0.15 * math.sin(time * 6)
            love.graphics.setColor(0.15, 0.35, 0.25, 0.9)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

            -- Border glow
            love.graphics.setColor(0.35 * pulse, 0.95 * pulse, 0.3 * pulse, 1.0)
            love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)

            -- Selector arrows
            love.graphics.setFont(self.font)
            love.graphics.print(">", btnX + 10, btnY + 8)
            love.graphics.print("<", btnX + btnW - 20, btnY + 8)

            -- Text
            love.graphics.setColor(1, 1, 1)
        else
            -- Normal button
            love.graphics.setColor(0.08, 0.08, 0.12, 0.8)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

            love.graphics.setColor(0.25, 0.25, 0.35, 0.8)
            love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)

            love.graphics.setColor(0.7, 0.7, 0.7)
        end

        love.graphics.setFont(self.font)
        love.graphics.printf(item.label, btnX, btnY + 8, btnW, "center")
    end

    -- Footer info
    if self.state == "main_menu" then
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.printf("Use [W/S] or [Arrows] + [ENTER] or Mouse to Select", 0, height - 24, width, "center")
    end
end

return Menu
