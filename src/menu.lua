-- ============================================================
-- SNAKE PRO - MENU SYSTEM (WITH STATUS & ARCHIVE CODEX)
-- ============================================================
local Config = require("config")
local Utils = require("utils")
local Storage = require("storage")
local Codex = require("codex")

local Menu = {}
Menu.__index = Menu

function Menu.new()
    local self = setmetatable({}, Menu)
    self.state = "main_menu" -- "main_menu", "pause_menu", "controls", "status"
    self.previousState = "main_menu"
    self.selectedIndex = 1
    self.hoveredIndex = nil

    -- Status Screen State
    self.statusTab = 1 -- 1: Discovered Items (Codex), 2: History & Stats
    self.codexPage = 1
    self.codexPerPage = 4
    self.historyPage = 1
    self.historyPerPage = 4

    -- Load fonts
    self.font = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 13) or love.graphics.newFont(13)
    self.largeFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 20) or love.graphics.newFont(20)
    self.titleFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 26) or love.graphics.newFont(26)
    self.smallFont = love.graphics.newFont("font/x14y24pxHeadUpDaisy.ttf", 10) or love.graphics.newFont(10)

    self.buttonRects = {}
    self.tabRects = {}
    self.pageBtnRects = {}
    return self
end

function Menu:getItems()
    if self.state == "main_menu" then
        return {
            {id = "start", label = "START GAME"},
            {id = "status", label = "STATUS & ARCHIVE"},
            {id = "controls", label = "CONTROLS & GUIDE"},
            {id = "exit", label = "EXIT GAME"}
        }
    elseif self.state == "pause_menu" then
        return {
            {id = "resume", label = "RESUME GAME"},
            {id = "restart", label = "START NEW"},
            {id = "status", label = "STATUS & ARCHIVE"},
            {id = "main_menu", label = "MAIN MENU"},
            {id = "exit", label = "EXIT GAME"}
        }
    elseif self.state == "controls" then
        return {
            {id = "back", label = "< BACK"}
        }
    elseif self.state == "status" then
        return {
            {id = "back", label = "< BACK"}
        }
    end
    return {}
end

function Menu:setState(newState)
    if self.state ~= "controls" and self.state ~= "status" then
        self.previousState = self.state
    end
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

    if self.state == "status" then
        if key == "escape" or key == "backspace" then
            Utils.playSFX("tick", 1.0, 0.4)
            self:setState(self.previousState or "main_menu")
            return true
        elseif key == "tab" or key == "q" or key == "e" then
            self.statusTab = (self.statusTab == 1) and 2 or 1
            Utils.playSFX("tick", 1.3, 0.3)
            return true
        elseif key == "left" or key == "a" then
            if self.statusTab == 1 then
                if self.codexPage > 1 then
                    self.codexPage = self.codexPage - 1
                    Utils.playSFX("tick", 1.1, 0.3)
                end
            else
                if self.historyPage > 1 then
                    self.historyPage = self.historyPage - 1
                    Utils.playSFX("tick", 1.1, 0.3)
                end
            end
            return true
        elseif key == "right" or key == "d" then
            if self.statusTab == 1 then
                local maxPages = math.ceil(#Codex.items / self.codexPerPage)
                if self.codexPage < maxPages then
                    self.codexPage = self.codexPage + 1
                    Utils.playSFX("tick", 1.1, 0.3)
                end
            else
                local history = Storage.getHistory()
                local maxPages = math.max(1, math.ceil(#history / self.historyPerPage))
                if self.historyPage < maxPages then
                    self.historyPage = self.historyPage + 1
                    Utils.playSFX("tick", 1.1, 0.3)
                end
            end
            return true
        elseif key == "return" or key == "space" then
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
    if button ~= 1 then return false end

    -- Check Tab clicks in Status screen
    if self.state == "status" then
        for _, tab in ipairs(self.tabRects or {}) do
            if x >= tab.x and x <= tab.x + tab.w and y >= tab.y and y <= tab.y + tab.h then
                self.statusTab = tab.tabId
                Utils.playSFX("tick", 1.3, 0.3)
                return true
            end
        end

        for _, pbtn in ipairs(self.pageBtnRects or {}) do
            if x >= pbtn.x and x <= pbtn.x + pbtn.w and y >= pbtn.y and y <= pbtn.y + pbtn.h then
                if pbtn.action == "prev" then
                    if self.statusTab == 1 and self.codexPage > 1 then
                        self.codexPage = self.codexPage - 1
                    elseif self.statusTab == 2 and self.historyPage > 1 then
                        self.historyPage = self.historyPage - 1
                    end
                elseif pbtn.action == "next" then
                    if self.statusTab == 1 then
                        local maxP = math.ceil(#Codex.items / self.codexPerPage)
                        if self.codexPage < maxP then self.codexPage = self.codexPage + 1 end
                    elseif self.statusTab == 2 then
                        local history = Storage.getHistory()
                        local maxP = math.max(1, math.ceil(#history / self.historyPerPage))
                        if self.historyPage < maxP then self.historyPage = self.historyPage + 1 end
                    end
                end
                Utils.playSFX("tick", 1.1, 0.3)
                return true
            end
        end
    end

    -- Check standard menu buttons
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

function Menu:touchpressed(id, x, y, game)
    return self:mousepressed(x, y, 1, game)
end

function Menu:wheelmoved(x, y)
    if self.state == "status" then
        if y < 0 then
            if self.statusTab == 1 then
                local maxP = math.ceil(#Codex.items / self.codexPerPage)
                if self.codexPage < maxP then
                    self.codexPage = self.codexPage + 1
                    Utils.playSFX("tick", 1.1, 0.3)
                end
            elseif self.statusTab == 2 then
                local history = Storage.getHistory()
                local maxP = math.max(1, math.ceil(#history / self.historyPerPage))
                if self.historyPage < maxP then
                    self.historyPage = self.historyPage + 1
                    Utils.playSFX("tick", 1.1, 0.3)
                end
            end
        elseif y > 0 then
            if self.statusTab == 1 and self.codexPage > 1 then
                self.codexPage = self.codexPage - 1
                Utils.playSFX("tick", 1.1, 0.3)
            elseif self.statusTab == 2 and self.historyPage > 1 then
                self.historyPage = self.historyPage - 1
                Utils.playSFX("tick", 1.1, 0.3)
            end
        end
    end
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
    elseif actionId == "status" then
        self:setState("status")
    elseif actionId == "controls" then
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

-- ============================================================
-- DRAWING MENUS
-- ============================================================
function Menu:draw(width, height, game)
    self.buttonRects = {}
    self.tabRects = {}
    self.pageBtnRects = {}
    local time = love.timer.getTime()

    if self.state == "pause_menu" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setFont(self.titleFont)
        love.graphics.setColor(0.35, 0.75, 1.0)
        love.graphics.printf("GAME PAUSED", 0, height * 0.12, width, "center")

        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("Press [ESC] to Resume", 0, height * 0.19, width, "center")

    elseif self.state == "main_menu" then
        love.graphics.setColor(0.02, 0.02, 0.04)
        love.graphics.rectangle("fill", 0, 0, width, height)

        love.graphics.setColor(0.08, 0.08, 0.14, 0.5)
        for gy = 0, height, 20 do love.graphics.line(0, gy, width, gy) end
        for gx = 0, width, 20 do love.graphics.line(gx, 0, gx, height) end

        love.graphics.setFont(self.titleFont)
        local glow = 0.8 + 0.2 * math.sin(time * 3)
        love.graphics.setColor(0.35 * glow, 0.85 * glow, 0.2 * glow)
        love.graphics.printf("S N A K E   P R O", 0, height * 0.10, width, "center")

        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.85, 0.75, 0.3)
        local highScore = Storage.getHighScore()
        love.graphics.printf("HIGH SCORE: " .. tostring(highScore), 0, height * 0.18, width, "center")

    elseif self.state == "controls" then
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
            {"Debug Spawn:", "Type [1-28] + Enter at mouse"},
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

    elseif self.state == "status" then
        -- ========================================================
        -- STATUS & ARCHIVE SCREEN
        -- ========================================================
        love.graphics.setColor(0.02, 0.02, 0.05)
        love.graphics.rectangle("fill", 0, 0, width, height)

        -- Title
        love.graphics.setFont(self.largeFont)
        love.graphics.setColor(0.35, 0.85, 1.0)
        love.graphics.printf("STATUS & ARCHIVE", 0, 10, width, "center")

        -- Tab Navigation Headers
        local tabW = (width - 40) / 2
        local tabH = 26
        local tabY = 36

        -- Tab 1: Discoveries
        local isTab1 = (self.statusTab == 1)
        love.graphics.setColor(isTab1 and {0.15, 0.25, 0.4, 0.95} or {0.06, 0.08, 0.14, 0.8})
        love.graphics.rectangle("fill", 20, tabY, tabW, tabH, 4, 4)
        love.graphics.setColor(isTab1 and {0.4, 0.8, 1.0} or {0.3, 0.4, 0.5})
        love.graphics.rectangle("line", 20, tabY, tabW, tabH, 4, 4)
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(isTab1 and {1, 1, 1} or {0.7, 0.7, 0.7})
        local discCount, totalCount = Storage.getDiscoveredCount(#Codex.items)
        love.graphics.printf("DISCOVERIES (" .. discCount .. "/" .. totalCount .. ")", 20, tabY + 6, tabW, "center")
        table.insert(self.tabRects, {x = 20, y = tabY, w = tabW, h = tabH, tabId = 1})

        -- Tab 2: History & Stats
        local isTab2 = (self.statusTab == 2)
        love.graphics.setColor(isTab2 and {0.15, 0.25, 0.4, 0.95} or {0.06, 0.08, 0.14, 0.8})
        love.graphics.rectangle("fill", 20 + tabW + 4, tabY, tabW, tabH, 4, 4)
        love.graphics.setColor(isTab2 and {0.4, 0.8, 1.0} or {0.3, 0.4, 0.5})
        love.graphics.rectangle("line", 20 + tabW + 4, tabY, tabW, tabH, 4, 4)
        love.graphics.setColor(isTab2 and {1, 1, 1} or {0.7, 0.7, 0.7})
        love.graphics.printf("HISTORY & STATS", 20 + tabW + 4, tabY + 6, tabW, "center")
        table.insert(self.tabRects, {x = 20 + tabW + 4, y = tabY, w = tabW, h = tabH, tabId = 2})

        -- TAB 1 CONTENT: DISCOVERED FOODS & POWERUPS
        if self.statusTab == 1 then
            local startIdx = (self.codexPage - 1) * self.codexPerPage + 1
            local endIdx = math.min(#Codex.items, startIdx + self.codexPerPage - 1)
            local itemY = 70
            local boxW = width - 40
            local boxH = 68

            for idx = startIdx, endIdx do
                local item = Codex.items[idx]
                local isDisc = Storage.isDiscovered(item.key)

                love.graphics.setColor(0.06, 0.07, 0.12, 0.9)
                love.graphics.rectangle("fill", 20, itemY, boxW, boxH, 4, 4)

                if isDisc then
                    love.graphics.setColor(0.2, 0.35, 0.5, 0.8)
                    love.graphics.rectangle("line", 20, itemY, boxW, boxH, 4, 4)

                    -- Icon
                    Codex.drawIcon(item.key, 30, itemY + 8, 20)

                    -- Title & Points
                    love.graphics.setFont(self.font)
                    love.graphics.setColor(0.4, 1.0, 0.5)
                    love.graphics.print(item.name, 60, itemY + 6)

                    love.graphics.setFont(self.smallFont)
                    love.graphics.setColor(0.4, 0.8, 1.0)
                    love.graphics.printf(item.points, boxW - 100, itemY + 8, 110, "right")

                    -- Description
                    love.graphics.setFont(self.smallFont)
                    love.graphics.setColor(0.85, 0.85, 0.85)
                    love.graphics.printf(item.desc, 60, itemY + 26, boxW - 75, "left")
                else
                    love.graphics.setColor(0.15, 0.15, 0.22, 0.8)
                    love.graphics.rectangle("line", 20, itemY, boxW, boxH, 4, 4)

                    -- Mystery Icon Box
                    love.graphics.setColor(0.12, 0.12, 0.18)
                    love.graphics.rectangle("fill", 30, itemY + 8, 20, 20, 3, 3)
                    love.graphics.setFont(self.font)
                    love.graphics.setColor(0.4, 0.4, 0.5)
                    love.graphics.printf("?", 30, itemY + 8, 20, "center")

                    -- Hidden Text
                    love.graphics.setFont(self.font)
                    love.graphics.setColor(0.5, 0.5, 0.6)
                    love.graphics.print("??? [Undiscovered]", 60, itemY + 6)

                    love.graphics.setFont(self.smallFont)
                    love.graphics.setColor(0.4, 0.4, 0.5)
                    love.graphics.print("Eat this item during gameplay to unlock lore and powers.", 60, itemY + 28)
                end

                itemY = itemY + boxH + 6
            end

            -- Pagination Controls
            local totalPages = math.ceil(#Codex.items / self.codexPerPage)
            local pY = height - 76
            love.graphics.setFont(self.smallFont)

            -- Prev Page
            love.graphics.setColor(self.codexPage > 1 and {0.12, 0.2, 0.35} or {0.05, 0.05, 0.08})
            love.graphics.rectangle("fill", 20, pY, 70, 22, 3, 3)
            love.graphics.setColor(self.codexPage > 1 and {0.4, 0.8, 1.0} or {0.2, 0.2, 0.3})
            love.graphics.rectangle("line", 20, pY, 70, 22, 3, 3)
            love.graphics.printf("< PREV", 20, pY + 4, 70, "center")
            table.insert(self.pageBtnRects, {x = 20, y = pY, w = 70, h = 22, action = "prev"})

            -- Page Indicator
            love.graphics.setColor(0.85, 0.75, 0.3)
            love.graphics.printf("PAGE " .. self.codexPage .. " / " .. totalPages, 100, pY + 4, width - 200, "center")

            -- Next Page
            love.graphics.setColor(self.codexPage < totalPages and {0.12, 0.2, 0.35} or {0.05, 0.05, 0.08})
            love.graphics.rectangle("fill", width - 90, pY, 70, 22, 3, 3)
            love.graphics.setColor(self.codexPage < totalPages and {0.4, 0.8, 1.0} or {0.2, 0.2, 0.3})
            love.graphics.rectangle("line", width - 90, pY, 70, 22, 3, 3)
            love.graphics.printf("NEXT >", width - 90, pY + 4, 70, "center")
            table.insert(self.pageBtnRects, {x = width - 90, y = pY, w = 70, h = 22, action = "next"})

        -- TAB 2 CONTENT: HISTORY & CAREER STATS
        elseif self.statusTab == 2 then
            local stats = Storage.getStats()
            local cardW = width - 40
            local cardY = 68

            -- Career Stats Card
            love.graphics.setColor(0.06, 0.08, 0.14, 0.9)
            love.graphics.rectangle("fill", 20, cardY, cardW, 80, 4, 4)
            love.graphics.setColor(0.3, 0.6, 0.8, 0.8)
            love.graphics.rectangle("line", 20, cardY, cardW, 80, 4, 4)

            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(0.4, 1.0, 0.5)
            love.graphics.print("CAREER SUMMARY:", 30, cardY + 6)

            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print("Total Runs: " .. (stats.gamesPlayed or 0), 30, cardY + 24)
            love.graphics.print("High Score: " .. (Storage.getHighScore() or 0), 160, cardY + 24)
            love.graphics.print("Ascensions: " .. (stats.immortalAscensions or 0), 280, cardY + 24)

            love.graphics.print("Foods Eaten: " .. (stats.totalFoodsEaten or 0), 30, cardY + 44)
            love.graphics.print("Total Matings: " .. (stats.totalMatings or 0), 160, cardY + 44)
            love.graphics.print("Devil Fruits: " .. (stats.totalDevilFruits or 0), 280, cardY + 44)

            -- Match History Log List
            local history = Storage.getHistory()
            local totalPages = math.max(1, math.ceil(#history / self.historyPerPage))
            local histY = cardY + 90
            local rowH = 34

            love.graphics.setFont(self.font)
            love.graphics.setColor(0.35, 0.75, 1.0)
            love.graphics.print("RECENT MATCHES:", 20, histY)
            histY = histY + 18

            if #history == 0 then
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(0.5, 0.5, 0.6)
                love.graphics.print("No completed runs recorded yet. Start playing!", 30, histY + 10)
            else
                local startIdx = (self.historyPage - 1) * self.historyPerPage + 1
                local endIdx = math.min(#history, startIdx + self.historyPerPage - 1)

                for i = startIdx, endIdx do
                    local h = history[i]
                    love.graphics.setColor(0.06, 0.07, 0.12, 0.85)
                    love.graphics.rectangle("fill", 20, histY, cardW, rowH, 3, 3)
                    love.graphics.setColor(0.2, 0.3, 0.45, 0.7)
                    love.graphics.rectangle("line", 20, histY, cardW, rowH, 3, 3)

                    love.graphics.setFont(self.smallFont)
                    love.graphics.setColor(0.7, 0.7, 0.8)
                    love.graphics.print(h.date or "N/A", 28, histY + 4)

                    love.graphics.setFont(self.font)
                    love.graphics.setColor(0.35, 0.95, 0.4)
                    love.graphics.print("Score: " .. (h.score or 0), 140, histY + 8)

                    love.graphics.setFont(self.smallFont)
                    love.graphics.setColor(h.outcome == "Ascended" and {1.0, 0.85, 0.2} or {0.8, 0.4, 0.4})
                    love.graphics.printf(h.outcome or "Over", cardW - 80, histY + 8, 90, "right")

                    histY = histY + rowH + 4
                end
            end

            -- Pagination Controls
            local pY = height - 76
            love.graphics.setFont(self.smallFont)

            love.graphics.setColor(self.historyPage > 1 and {0.12, 0.2, 0.35} or {0.05, 0.05, 0.08})
            love.graphics.rectangle("fill", 20, pY, 70, 22, 3, 3)
            love.graphics.setColor(self.historyPage > 1 and {0.4, 0.8, 1.0} or {0.2, 0.2, 0.3})
            love.graphics.rectangle("line", 20, pY, 70, 22, 3, 3)
            love.graphics.printf("< PREV", 20, pY + 4, 70, "center")
            table.insert(self.pageBtnRects, {x = 20, y = pY, w = 70, h = 22, action = "prev"})

            love.graphics.setColor(0.85, 0.75, 0.3)
            love.graphics.printf("PAGE " .. self.historyPage .. " / " .. totalPages, 100, pY + 4, width - 200, "center")

            love.graphics.setColor(self.historyPage < totalPages and {0.12, 0.2, 0.35} or {0.05, 0.05, 0.08})
            love.graphics.rectangle("fill", width - 90, pY, 70, 22, 3, 3)
            love.graphics.setColor(self.historyPage < totalPages and {0.4, 0.8, 1.0} or {0.2, 0.2, 0.3})
            love.graphics.rectangle("line", width - 90, pY, 70, 22, 3, 3)
            love.graphics.printf("NEXT >", width - 90, pY + 4, 70, "center")
            table.insert(self.pageBtnRects, {x = width - 90, y = pY, w = 70, h = 22, action = "next"})
        end
    end

    -- Render Menu Option Buttons
    local items = self:getItems()
    local btnW = 220
    local btnH = 32
    local startY = (self.state == "controls" or self.state == "status") and (height - 46) or (height * 0.26)
    local spacing = 40

    for i, item in ipairs(items) do
        local btnX = (width - btnW) / 2
        local btnY = startY + (i - 1) * spacing
        local isSelected = (i == self.selectedIndex)

        table.insert(self.buttonRects, {x = btnX, y = btnY, w = btnW, h = btnH})

        if isSelected then
            local pulse = 0.85 + 0.15 * math.sin(time * 6)
            love.graphics.setColor(0.15, 0.35, 0.25, 0.9)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

            love.graphics.setColor(0.35 * pulse, 0.95 * pulse, 0.3 * pulse, 1.0)
            love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)

            love.graphics.setFont(self.font)
            love.graphics.print(">", btnX + 10, btnY + 7)
            love.graphics.print("<", btnX + btnW - 20, btnY + 7)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.08, 0.08, 0.12, 0.8)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

            love.graphics.setColor(0.25, 0.25, 0.35, 0.8)
            love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)

            love.graphics.setColor(0.7, 0.7, 0.7)
        end

        love.graphics.setFont(self.font)
        love.graphics.printf(item.label, btnX, btnY + 7, btnW, "center")
    end

    if self.state == "main_menu" then
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.printf("Use [W/S] or [Arrows] + [ENTER] or Mouse to Select", 0, height - 20, width, "center")
    end
end

return Menu
