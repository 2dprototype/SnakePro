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
    self.state = "main_menu" -- "main_menu", "pause_menu", "controls", "status", "shop"
    self.previousState = "main_menu"
    self.selectedIndex = 1
    self.hoveredIndex = nil

    -- Status Screen State
    self.statusTab = 1 -- 1: Discovered Items (Codex), 2: History & Stats
    self.codexPage = 1
    self.codexPerPage = 4
    self.historyPage = 1
    self.historyPerPage = 4

    -- Shop Screen State
    self.shopPage = 1
    self.shopPerPage = 3
    self.selectedShopIndex = 1
    self.shopBtnRects = {}
    self.shopFeedbackMsg = nil
    self.shopFeedbackTimer = 0
    self.shopFeedbackColor = {0.35, 0.95, 0.4}

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
            {id = "shop", label = "UPGRADES SHOP"},
            {id = "status", label = "STATUS & ARCHIVE"},
            {id = "controls", label = "CONTROLS & GUIDE"},
            {id = "exit", label = "EXIT GAME"}
        }
    elseif self.state == "pause_menu" then
        return {
            {id = "resume", label = "RESUME GAME"},
            {id = "shop", label = "UPGRADES SHOP"},
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
    elseif self.state == "shop" then
        return {
            {id = "back", label = "< BACK"}
        }
    end
    return {}
end

function Menu:setState(newState)
    if self.state ~= "controls" and self.state ~= "status" and self.state ~= "shop" then
        self.previousState = self.state
    end
    self.state = newState
    self.selectedIndex = 1
    self.hoveredIndex = nil
end

function Menu:buyUpgradeByIndex(index, game)
    local upgrades = Config.upgrades or {}
    local item = upgrades[index]
    if not item then return end

    local success, msg = Storage.buyUpgrade(item.id)
    if success then
        Utils.playSFX("levelup", 1.5, 0.7)
        self.shopFeedbackMsg = "Upgraded: " .. item.name .. " to LVL " .. Storage.getUpgradeLevel(item.id) .. "!"
        self.shopFeedbackTimer = 2.5
        self.shopFeedbackColor = {0.35, 0.95, 0.4}
        if game and game.refreshUpgrades then
            game:refreshUpgrades()
        end
    else
        Utils.playSFX("glitch", 1.2, 0.4)
        self.shopFeedbackMsg = msg or "Cannot upgrade!"
        self.shopFeedbackTimer = 2.0
        self.shopFeedbackColor = {0.95, 0.35, 0.35}
    end
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

    if self.state == "shop" then
        local upgrades = Config.upgrades or {}
        local totalPages = math.max(1, math.ceil(#upgrades / self.shopPerPage))
        local startIdx = (self.shopPage - 1) * self.shopPerPage + 1
        local endIdx = math.min(#upgrades, startIdx + self.shopPerPage - 1)
        local countOnPage = math.max(1, endIdx - startIdx + 1)

        if key == "escape" or key == "backspace" then
            Utils.playSFX("tick", 1.0, 0.4)
            self:setState(self.previousState or "main_menu")
            return true
        elseif key == "up" or key == "w" then
            self.selectedShopIndex = self.selectedShopIndex - 1
            if self.selectedShopIndex < 1 then self.selectedShopIndex = countOnPage end
            Utils.playSFX("tick", 1.2, 0.3)
            return true
        elseif key == "down" or key == "s" then
            self.selectedShopIndex = self.selectedShopIndex + 1
            if self.selectedShopIndex > countOnPage then self.selectedShopIndex = 1 end
            Utils.playSFX("tick", 1.2, 0.3)
            return true
        elseif key == "left" or key == "a" or key == "q" then
            if self.shopPage > 1 then
                self.shopPage = self.shopPage - 1
                self.selectedShopIndex = 1
                Utils.playSFX("tick", 1.1, 0.3)
            end
            return true
        elseif key == "right" or key == "d" or key == "e" or key == "tab" then
            if self.shopPage < totalPages then
                self.shopPage = self.shopPage + 1
                self.selectedShopIndex = 1
                Utils.playSFX("tick", 1.1, 0.3)
            end
            return true
        elseif key == "return" or key == "space" or key == "u" then
            local actualIndex = startIdx + self.selectedShopIndex - 1
            self:buyUpgradeByIndex(actualIndex, game)
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
    if self.state == "shop" then
        for _, sbtn in ipairs(self.shopBtnRects or {}) do
            if x >= sbtn.x and x <= sbtn.x + sbtn.w and y >= sbtn.y and y <= sbtn.y + sbtn.h then
                if sbtn.slotIndex then
                    self.selectedShopIndex = sbtn.slotIndex
                end
                break
            end
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

    -- Check Shop buttons and cards
    if self.state == "shop" then
        for _, sbtn in ipairs(self.shopBtnRects or {}) do
            if x >= sbtn.x and x <= sbtn.x + sbtn.w and y >= sbtn.y and y <= sbtn.y + sbtn.h then
                self:buyUpgradeByIndex(sbtn.upgradeIndex, game)
                return true
            end
        end

        for _, pbtn in ipairs(self.pageBtnRects or {}) do
            if x >= pbtn.x and x <= pbtn.x + pbtn.w and y >= pbtn.y and y <= pbtn.y + pbtn.h then
                local upgrades = Config.upgrades or {}
                local totalPages = math.max(1, math.ceil(#upgrades / self.shopPerPage))
                if pbtn.action == "shop_prev" and self.shopPage > 1 then
                    self.shopPage = self.shopPage - 1
                    self.selectedShopIndex = 1
                    Utils.playSFX("tick", 1.1, 0.3)
                    return true
                elseif pbtn.action == "shop_next" and self.shopPage < totalPages then
                    self.shopPage = self.shopPage + 1
                    self.selectedShopIndex = 1
                    Utils.playSFX("tick", 1.1, 0.3)
                    return true
                end
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
    elseif self.state == "shop" then
        local upgrades = Config.upgrades or {}
        local totalPages = math.max(1, math.ceil(#upgrades / self.shopPerPage))
        if y < 0 and self.shopPage < totalPages then
            self.shopPage = self.shopPage + 1
            self.selectedShopIndex = 1
            Utils.playSFX("tick", 1.1, 0.3)
        elseif y > 0 and self.shopPage > 1 then
            self.shopPage = self.shopPage - 1
            self.selectedShopIndex = 1
            Utils.playSFX("tick", 1.1, 0.3)
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
    elseif actionId == "shop" then
        self:setState("shop")
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
    elseif self.state == "shop" then
        -- ========================================================
        -- UPGRADE SHOP SCREEN (COMPACT & CLEAN PIXEL-PERFECT UI)
        -- ========================================================
        local dt = love.timer.getDelta()
        if self.shopFeedbackTimer and self.shopFeedbackTimer > 0 then
            self.shopFeedbackTimer = self.shopFeedbackTimer - dt
            if self.shopFeedbackTimer <= 0 then self.shopFeedbackMsg = nil end
        end

        love.graphics.setColor(0.02, 0.02, 0.05)
        love.graphics.rectangle("fill", 0, 0, width, height)

        -- Title
        love.graphics.setFont(self.largeFont)
        love.graphics.setColor(0.35, 0.85, 1.0)
        love.graphics.printf("FRUIT & POWER UPGRADES", 0, 10, width, "center")

        -- Gold Coin Wallet Header
        local coins = Storage.getCoins()
        local walletY = 34
        love.graphics.setColor(0.06, 0.08, 0.15, 0.95)
        love.graphics.rectangle("fill", 20, walletY, width - 40, 24, 4, 4)
        love.graphics.setColor(1.0, 0.84, 0.0, 0.8)
        love.graphics.rectangle("line", 20, walletY, width - 40, 24, 4, 4)

        Codex.drawIcon("coin", 26, walletY + 2, 20)
        love.graphics.setFont(self.font)
        love.graphics.setColor(1.0, 0.84, 0.0)
        love.graphics.print("COINS: " .. tostring(coins), 52, walletY + 4)

        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.65, 0.75, 0.9)
        love.graphics.printf("Permanent upgrades for fruits & powers", width - 240, walletY + 6, 215, "right")

        -- Feedback message banner (if active)
        if self.shopFeedbackMsg then
            local fbColor = self.shopFeedbackColor or {0.35, 0.95, 0.4}
            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(fbColor[1], fbColor[2], fbColor[3], 0.95)
            love.graphics.printf(self.shopFeedbackMsg, 0, walletY + 28, width, "center")
        end

        -- Upgrade Cards (3 Compact Cards per page)
        local upgrades = Config.upgrades or {}
        local totalPages = math.max(1, math.ceil(#upgrades / self.shopPerPage))
        if self.shopPage > totalPages then self.shopPage = totalPages end

        local startIdx = (self.shopPage - 1) * self.shopPerPage + 1
        local endIdx = math.min(#upgrades, startIdx + self.shopPerPage - 1)

        local cardW = width - 40
        local cardH = 104
        local cardStartY = 76
        local cardSpacing = 112

        self.shopBtnRects = {}

        for i = startIdx, endIdx do
            local cardSlot = i - startIdx + 1
            local u = upgrades[i]
            local cardY = cardStartY + (cardSlot - 1) * cardSpacing
            local isSelected = (cardSlot == self.selectedShopIndex)

            local curLvl = Storage.getUpgradeLevel(u.id)
            local maxLvl = u.maxLevel or 5
            local isMaxed = (curLvl >= maxLvl)
            local canAfford, nextLvl, cost = Storage.canAffordUpgrade(u.id)

            -- Register Card Rect for click-to-buy
            table.insert(self.shopBtnRects, {x = 20, y = cardY, w = cardW, h = cardH, upgradeIndex = i, slotIndex = cardSlot})

            -- Card Background
            if isSelected then
                local glow = 0.85 + 0.15 * math.sin(time * 5)
                love.graphics.setColor(0.08, 0.13, 0.20, 0.95)
                love.graphics.rectangle("fill", 20, cardY, cardW, cardH, 5, 5)
                love.graphics.setColor(0.35 * glow, 0.95 * glow, 0.5 * glow, 0.95)
                love.graphics.rectangle("line", 20, cardY, cardW, cardH, 5, 5)
            else
                love.graphics.setColor(0.05, 0.06, 0.10, 0.9)
                love.graphics.rectangle("fill", 20, cardY, cardW, cardH, 5, 5)
                love.graphics.setColor(0.18, 0.22, 0.32, 0.7)
                love.graphics.rectangle("line", 20, cardY, cardW, cardH, 5, 5)
            end

            -- Row 1: Icon (24px)
            local iconSize = 24
            local iconX = 30
            local iconY = cardY + 8
            Codex.drawIcon(u.iconKey or "food", iconX, iconY, iconSize)

            -- Row 1: Title (font size 13) & Category (font size 10)
            love.graphics.setFont(self.font)
            love.graphics.setColor(0.35, 0.95, 0.5)
            love.graphics.print(u.name, 62, cardY + 6)

            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(0.5, 0.7, 0.9)
            love.graphics.print(u.category or "Upgrades", 62, cardY + 22)

            -- Row 1: Level Progress Pips (Top Right)
            local pipX = 265
            local pipY = cardY + 9
            local pipSize = 8
            local pipGap = 3

            for p = 1, maxLvl do
                local px = pipX + (p - 1) * (pipSize + pipGap)
                if p <= curLvl then
                    love.graphics.setColor(1.0, 0.84, 0.0, 0.95)
                    love.graphics.rectangle("fill", px, pipY, pipSize, pipSize, 1.5, 1.5)
                else
                    love.graphics.setColor(0.15, 0.18, 0.28, 0.8)
                    love.graphics.rectangle("fill", px, pipY, pipSize, pipSize, 1.5, 1.5)
                    love.graphics.setColor(0.3, 0.35, 0.5, 0.6)
                    love.graphics.rectangle("line", px, pipY, pipSize, pipSize, 1.5, 1.5)
                end
            end

            love.graphics.setFont(self.smallFont)
            if isMaxed then
                love.graphics.setColor(1.0, 0.84, 0.0)
                love.graphics.print("★ MAX", 325, cardY + 8)
            else
                love.graphics.setColor(0.8, 0.85, 0.9)
                love.graphics.print("LVL " .. curLvl .. "/" .. maxLvl, 325, cardY + 8)
            end

            -- Row 2: Description (font size 10, compact 2 lines max)
            love.graphics.setFont(self.smallFont)
            love.graphics.setColor(0.82, 0.84, 0.88)
            love.graphics.printf(u.desc or "", 30, cardY + 38, cardW - 20, "left")

            -- Row 3: Stat Values Comparison (Bottom Left)
            local curVal = (curLvl > 0 and u.values[curLvl]) or (u.values[1])
            local nextVal = (curLvl < maxLvl and u.values[curLvl + 1]) or curVal
            local unit = u.unit or ""

            if isMaxed then
                love.graphics.setColor(1.0, 0.84, 0.0)
                love.graphics.print("Current: " .. tostring(curVal) .. " " .. unit .. " (MAX LEVEL)", 30, cardY + 74)
            else
                love.graphics.setColor(0.45, 0.85, 1.0)
                local effectText = "Effect: " .. tostring(curVal) .. " " .. unit .. "  ➜  Next: " .. tostring(nextVal) .. " " .. unit
                love.graphics.print(effectText, 30, cardY + 74)
            end

            -- Row 3: Buy / Upgrade Button (Bottom Right)
            local btnX = cardW - 130
            local btnY = cardY + 68
            local btnW = 140
            local btnH = 26

            if isMaxed then
                love.graphics.setColor(0.12, 0.14, 0.20, 0.8)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setColor(1.0, 0.84, 0.0, 0.5)
                love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(1.0, 0.84, 0.0, 0.7)
                love.graphics.printf("★ MAXED ★", btnX, btnY + 6, btnW, "center")
            elseif canAfford then
                local btnPulse = 0.85 + 0.15 * math.sin(time * 6)
                love.graphics.setColor(0.12, 0.35, 0.18, 0.9)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setColor(0.35 * btnPulse, 0.95 * btnPulse, 0.3 * btnPulse, 1.0)
                love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setFont(self.font)
                love.graphics.setColor(1.0, 1.0, 1.0)
                love.graphics.printf("UPGRADE [" .. tostring(cost) .. "]", btnX, btnY + 4, btnW, "center")
            else
                love.graphics.setColor(0.16, 0.08, 0.10, 0.85)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setColor(0.6, 0.25, 0.25, 0.7)
                love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setFont(self.smallFont)
                love.graphics.setColor(0.9, 0.5, 0.5)
                love.graphics.printf("NEED " .. tostring(cost), btnX, btnY + 6, btnW, "center")
            end
        end

        -- Pagination Controls
        local pY = 422
        love.graphics.setFont(self.smallFont)

        love.graphics.setColor(self.shopPage > 1 and {0.12, 0.2, 0.35} or {0.05, 0.05, 0.08})
        love.graphics.rectangle("fill", 20, pY, 75, 24, 3, 3)
        love.graphics.setColor(self.shopPage > 1 and {0.4, 0.8, 1.0} or {0.2, 0.2, 0.3})
        love.graphics.rectangle("line", 20, pY, 75, 24, 3, 3)
        love.graphics.printf("< PREV", 20, pY + 5, 75, "center")
        table.insert(self.pageBtnRects, {x = 20, y = pY, w = 75, h = 24, action = "shop_prev"})

        love.graphics.setColor(0.85, 0.75, 0.3)
        love.graphics.printf("PAGE " .. self.shopPage .. " / " .. totalPages .. "  ([A/D] or [Q/E] to Flip)", 100, pY + 5, width - 200, "center")

        love.graphics.setColor(self.shopPage < totalPages and {0.12, 0.2, 0.35} or {0.05, 0.05, 0.08})
        love.graphics.rectangle("fill", width - 95, pY, 75, 24, 3, 3)
        love.graphics.setColor(self.shopPage < totalPages and {0.4, 0.8, 1.0} or {0.2, 0.2, 0.3})
        love.graphics.rectangle("line", width - 95, pY, 75, 24, 3, 3)
        love.graphics.printf("NEXT >", width - 95, pY + 5, 75, "center")
        table.insert(self.pageBtnRects, {x = width - 95, y = pY, w = 75, h = 24, action = "shop_next"})

        -- Keyboard / Mouse Navigation Hints
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(0.45, 0.55, 0.65)
        love.graphics.printf("[W/S] Select  •  [ENTER/SPACE] Upgrade  •  [A/D] Page  •  [ESC] Back", 0, 458, width, "center")

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
            {"Debug Spawn:", "Type [1-22] + Enter at mouse"},
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
        local discCount, totalCount = Storage.getDiscoveredCount(#Codex.items, Codex.byKey)
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
    local startY = (self.state == "controls" or self.state == "status" or self.state == "shop") and (height - 46) or (height * 0.26)
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
