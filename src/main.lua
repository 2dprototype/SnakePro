-- ============================================================
-- SNAKE PRO - MAIN ENTRYPOINT
-- ============================================================
local ffi = require("ffi")

-- SDL2 FFI Declarations for 5th Wall Desktop Breakout
ffi.cdef[[
    typedef void SDL_Window;
    typedef void SDL_Surface;
    typedef struct { int x, y, w, h; } SDL_Rect;

    enum {
        SDL_WINDOW_BORDERLESS    = 0x00000010,
        SDL_WINDOW_ALWAYS_ON_TOP = 0x00008000
    };

    SDL_Window* SDL_CreateWindow(const char* title, int x, int y, int w, int h, uint32_t flags);
    int SDL_SetWindowOpacity(SDL_Window* window, float opacity);
    void SDL_SetWindowPosition(SDL_Window* window, int x, int y);
    SDL_Surface* SDL_GetWindowSurface(SDL_Window* window);
    int SDL_UpdateWindowSurface(SDL_Window* window);
    int SDL_FillRect(SDL_Surface* dst, const SDL_Rect* rect, uint32_t color);
    void SDL_DestroyWindow(SDL_Window* window);
]]

if love.system.getOS() == "Windows" then
    _G.sdl = ffi.load("SDL2")
else
    _G.sdl = ffi.C
end

-- Global Stubs & Fallbacks
_G.AudioManager = {
    playSFX = function(name, pitch, volume) end
}
package.loaded["src/core/audio_manager"] = _G.AudioManager

_G.Notifications = {
    add = function(title, msg, icon, duration) end
}

-- Module Imports
local Config = require("config")
local SnakeGame = require("game")
local Menu = require("menu")

-- Application State
_G.GameState = "main_menu" -- "main_menu", "playing", "paused", "controls"

function love.load()
    love.window.setMode(Config.windowWidth, Config.windowHeight, {resizable = false, vsync = true})
    love.window.setTitle("Snake Pro")

    _G.GameInstance = SnakeGame.new()
    _G.MenuInstance = Menu.new()
end

function love.update(dt)
    if _G.GameState == "playing" then
        _G.GameInstance:update(dt)
    end
end

function love.draw()
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if _G.GameState == "playing" then
        _G.GameInstance:draw(0, 0, w, h)
    elseif _G.GameState == "paused" then
        _G.GameInstance:draw(0, 0, w, h)
        _G.MenuInstance:draw(w, h, _G.GameInstance)
    elseif _G.GameState == "main_menu" or _G.GameState == "controls" then
        _G.MenuInstance:draw(w, h, _G.GameInstance)
    end
end

function love.keypressed(key)
    if key == "escape" then
        if _G.GameState == "playing" then
            if _G.GameInstance.gameOver then
                _G.GameState = "main_menu"
                _G.MenuInstance:setState("main_menu")
            else
                _G.GameState = "paused"
                _G.MenuInstance:setState("pause_menu")
            end
            return
        elseif _G.GameState == "paused" then
            _G.GameState = "playing"
            return
        elseif _G.GameState == "controls" then
            _G.MenuInstance:setState(_G.MenuInstance.previousState or "main_menu")
            return
        elseif _G.GameState == "main_menu" then
            love.event.quit()
            return
        end
    end

    if _G.GameState == "playing" then
        _G.GameInstance:keypressed(key)
    else
        _G.MenuInstance:keypressed(key, _G.GameInstance)
    end
end

function love.mousemoved(x, y, dx, dy)
    if _G.GameState ~= "playing" then
        _G.MenuInstance:mousemoved(x, y)
    end
end

function love.mousepressed(x, y, button)
    if _G.GameState == "playing" then
        _G.GameInstance:mousepressed(x, y, button)
    else
        _G.MenuInstance:mousepressed(x, y, button, _G.GameInstance)
    end
end

function love.mousereleased(x, y, button)
    if _G.GameState == "playing" then
        _G.GameInstance:mousereleased(x, y, button)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if _G.GameState == "playing" then
        _G.GameInstance:touchpressed(id, x, y)
    else
        _G.MenuInstance:touchpressed(id, x, y, _G.GameInstance)
    end
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    if _G.GameState == "playing" then
        _G.GameInstance:touchreleased(id, x, y)
    end
end

function love.quit()
    if _G.GameInstance then
        _G.GameInstance:destroyExternalWindows()
    end
end