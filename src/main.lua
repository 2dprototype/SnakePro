local ffi = require("ffi")

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
    sdl = ffi.load("SDL2")
else
    sdl = ffi.C
end

package.loaded["src/core/audio_manager"] = {
    playSFX = function(name, pitch, volume) end
}

_G.Notifications = {
    add = function(title, msg, icon, duration) end
}

local moonshine = require("lib/moonshine")
local SnakeGame = require("snake")

effect = moonshine(moonshine.effects.scanlines).chain(moonshine.effects.crt)
effect.scanlines.opacity = 0.6

function love.load()
    -- Fixed window size, non‑resizable
    love.window.setMode(420, 440, {resizable = false, vsync = true})
    love.window.setTitle("Snake Pro")
    game = SnakeGame.new()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    -- effect(function()
        -- game:draw(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    -- end)
    game:draw(0, 0, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.keypressed(key)
    game:keypressed(key)
end

function love.mousepressed(x, y, button)
    game:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
    game:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    if game.mousemoved then game:mousemoved(x, y, dx, dy) end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if game.touchmoved then game:touchmoved(id, x, y) end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    game:touchpressed(id, x, y)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    game:touchreleased(id, x, y)
end

function love.quit()
    -- optional cleanup
end