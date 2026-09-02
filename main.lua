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