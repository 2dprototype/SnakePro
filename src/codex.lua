-- ============================================================
-- SNAKE PRO - ITEM DATABASE & CODEX (WITH EVENT MILESTONES)
-- ============================================================
local Config = require("config")

local Codex = {}

Codex.items = {
    -- Foods & Rare Fruits
    {
        key = "food",
        name = "Normal Food",
        category = "Basic Food",
        points = "+10 pts",
        desc = "Standard food item. Increases snake length by 1 and increases base speed over time."
    },
    {
        key = "greenfruit",
        name = "Lime Green Fruit",
        category = "Rare Fruit",
        points = "+200 pts",
        desc = "Rare glowing fruit. Awards 200 points and envelops the snake in an energetic green glow for 5s."
    },
    {
        key = "goldenfruit_1",
        name = "Golden Fruit (Life)",
        category = "Golden Fruit",
        points = "Extra Life",
        desc = "Legendary golden harvest. Grants +1 Extra Life (up to max 5 lives)."
    },
    {
        key = "goldenfruit_2",
        name = "Golden Fruit (Wealth)",
        category = "Golden Fruit",
        points = "+500 pts",
        desc = "Legendary golden harvest. Instantly awards a massive +500 point bonus."
    },
    {
        key = "goldenfruit_3",
        name = "Golden Fruit (Aegis)",
        category = "Golden Fruit",
        points = "Invincibility",
        desc = "Legendary golden harvest. Grants 5 seconds of total invulnerability."
    },

    -- 18 Power-ups
    {
        key = "shorten",
        name = "Shorten Orb",
        category = "Power-up",
        points = "Trims Body",
        desc = "Instantly trims up to 3 segments from the tail, making tight corners easier to navigate."
    },
    {
        key = "reverse",
        name = "Reverse Orb",
        category = "Power-up",
        points = "Flip Direction",
        desc = "Immediately swaps head and tail, flipping your travel direction 180 degrees."
    },
    {
        key = "speedup",
        name = "Speed Surge",
        category = "Power-up",
        points = "Speed Boost",
        desc = "Temporarily accelerates snake movement speed for 4 seconds."
    },
    {
        key = "slowdown",
        name = "Chrono Slow",
        category = "Power-up",
        points = "Slow Time",
        desc = "Reduces movement speed for 4 seconds, allowing pinpoint navigation."
    },
    {
        key = "extralife",
        name = "Heart Core",
        category = "Power-up",
        points = "+1 Life",
        desc = "Awards +1 Extra Life to withstand additional accidental collisions."
    },
    {
        key = "scoreboost",
        name = "Score Crystal",
        category = "Power-up",
        points = "+50 pts",
        desc = "Instant point boost that adds +50 points to your total score."
    },
    {
        key = "colorchange",
        name = "Prism Dye",
        category = "Power-up",
        points = "Cosmetic",
        desc = "Randomizes your snake's skin color palette into a vibrant new shade."
    },
    {
        key = "devilfruit",
        name = "Devil's Fruit",
        category = "Power-up",
        points = "+100 pts & Skin",
        desc = "Imbues the snake with a permanent demonic red skin, bonus points, and a speed surge."
    },
    {
        key = "lustfood",
        name = "Lust Berry",
        category = "Power-up",
        points = "3x Multiplier",
        desc = "Triples all point values for 5s and draws the pink AI female snake directly to you."
    },
    {
        key = "nocollision",
        name = "Ghost Phase",
        category = "Power-up",
        points = "Phase Shift",
        desc = "Phase through your own body segments for 3 seconds without suffering collision damage."
    },
    {
        key = "forbidden",
        name = "Forbidden Sigil",
        category = "Power-up",
        points = "Cosmic Realm",
        desc = "Teleports you into the dark Forbidden Realm packed with high-value cosmic foods for 8s."
    },
    {
        key = "mate",
        name = "Pheromone Core",
        category = "Power-up",
        points = "Summon AI",
        desc = "Summons a pink AI female snake or extends her lifespan by +30s. Touch heads to mate for huge points!"
    },
    {
        key = "rainbow",
        name = "Rainbow Prism",
        category = "Power-up",
        points = "Rainbow Aura",
        desc = "Transforms the snake into an animated 7-color ROYGBIV spectrum for 10 seconds."
    },
    {
        key = "wormhole",
        name = "Wormhole",
        category = "Power-up",
        points = "Teleport",
        desc = "Instantly teleports the entire snake to a safe random location on the board."
    },
    {
        key = "whitehole",
        name = "Whitehole",
        category = "Power-up",
        points = "Repulsion Field",
        desc = "Generates gravitational repulsion, pushing items away from your snake's head."
    },
    {
        key = "blackhole",
        name = "Blackhole",
        category = "Power-up",
        points = "Attraction Field",
        desc = "Generates gravitational pull, drawing distant items directly towards your head."
    },
    {
        key = "fourthwall",
        name = "4th Wall Breach",
        category = "Power-up",
        points = "Boundary Break",
        desc = "Disables grid walls for 15s. Slither outside the boundary (return within 5s to survive!)."
    },
    {
        key = "fifthwall",
        name = "5th Wall Breakout",
        category = "Power-up",
        points = "Desktop Escape",
        desc = "Segments escaping the window materialize as real borderless windows on your PC desktop!"
    },

    -- Forbidden Foods
    {
        key = "forbidden_food_1",
        name = "Forbidden Emerald",
        category = "Forbidden Realm",
        points = "+15 pts",
        desc = "Common cosmic food harvested exclusively within the Forbidden Realm."
    },
    {
        key = "forbidden_food_2",
        name = "Forbidden Amber",
        category = "Forbidden Realm",
        points = "+30 pts",
        desc = "Uncommon cosmic food glowing with yellow radiant energy (+30 points)."
    },
    {
        key = "forbidden_food_3",
        name = "Forbidden Amethyst",
        category = "Forbidden Realm",
        points = "+50 pts",
        desc = "Rare high-yield cosmic food pulsing with purple energy (+50 points)."
    },
    {
        key = "forbidden_food_4",
        name = "Forbidden Chrono",
        category = "Forbidden Realm",
        points = "+2s Realm Time",
        desc = "Cyan cosmic artifact that extends your remaining time in the Forbidden Realm by +2 seconds."
    },

    -- Event Milestones
    {
        key = "event_death",
        name = "Collision & Revival",
        category = "Milestone Event",
        points = "-1 Life / Respawn",
        desc = "Crashing into your body loses 1 life, granting 2s invincibility and trimming the snake. Lives at 0 ends run."
    },
    {
        key = "event_mating",
        name = "First Mating Encounter",
        category = "Milestone Event",
        points = "Massive Bonus & Shake",
        desc = "Touching heads with the female snake triggers mating! Grants massive points, screen shake, and freezes time."
    },
    {
        key = "event_female_spawn",
        name = "Female Snake Arrival",
        category = "Milestone Event",
        points = "AI Companion",
        desc = "A pink AI female snake enters the arena. She actively hunts for fruits and pursues you in Lust mode."
    },
    {
        key = "event_forbidden_realm",
        name = "Forbidden Realm Entry",
        category = "Milestone Event",
        points = "Cosmic Realm (8s)",
        desc = "Plunges the grid into dark purple cosmos populated exclusively by 15 high-value forbidden foods."
    },
    {
        key = "event_immortal_ending",
        name = "Immortal Ascension",
        category = "Secret Milestone",
        points = "Secret Ending",
        desc = "Biting your own tail initiates the ancient Ouroboros ascension! The world freezes into gold and void sparks."
    },
    {
        key = "event_fourth_wall",
        name = "4th Wall Grid Breach",
        category = "Secret Milestone",
        points = "Void Slithering",
        desc = "Grid barriers shatter! Slither outside into the surrounding void (return within 5 seconds to survive)."
    },
    {
        key = "event_fifth_wall",
        name = "5th Wall Desktop Escape",
        category = "Secret Milestone",
        points = "Desktop Windows",
        desc = "Outside segments materialize as real floating borderless windows across your Windows desktop."
    }
}

-- Key-based lookup dictionary
Codex.byKey = {}
for i, item in ipairs(Codex.items) do
    Codex.byKey[item.key] = item
end

-- Draw authentic item / event icon in UI
function Codex.drawIcon(key, x, y, size)
    local item = Codex.byKey[key]
    if not item then return end
    local time = love.timer.getTime()

    if key == "food" then
        local col = Config.colors.food
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(col[1] * 0.8, col[2] * 0.5, col[3] * 0.5)
        love.graphics.rectangle("fill", x + 4, y + 4, size - 8, size - 8, 2, 2)

    elseif key == "greenfruit" then
        local col = Config.colors.greenfruit
        love.graphics.setColor(col[1], col[2], col[3], 0.3)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 3, 3)
        love.graphics.setColor(col[1] * 0.6, col[2] * 0.8, col[3] * 0.6)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 8, size - 8, 2, 2)

    elseif key:find("^goldenfruit") then
        local col = Config.colors.goldenfruit
        love.graphics.setColor(col[1], col[2], col[3], 0.35 + 0.15 * math.sin(time * 4))
        love.graphics.rectangle("fill", x - 3, y - 3, size + 6, size + 6, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(col[1] * 0.9, col[2] * 0.8, col[3] * 0.5)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 8, size - 8, 2, 2)

    elseif key == "rainbow" then
        local rainbowColors = {
            {1.0, 0.0, 0.0}, {1.0, 0.5, 0.0}, {1.0, 1.0, 0.0},
            {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}, {0.29, 0.0, 0.51}, {0.58, 0.0, 0.83}
        }
        local cIdx = math.floor(time * 6.66) % 7 + 1
        local col = rainbowColors[cIdx]
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 3, 3)
        love.graphics.setColor(col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 0.6)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 8, size - 8, 2, 2)

    elseif key == "blackhole" then
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        love.graphics.setColor(1, 1, 1, 0.35)
        love.graphics.circle("fill", cx, cy, rad + 3)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(0.35, 0.35, 0.35, 0.7)
        love.graphics.circle("line", cx, cy, rad - 2)

    elseif key == "whitehole" then
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        love.graphics.setColor(0.8, 0.8, 0.8, 0.35)
        love.graphics.circle("fill", cx, cy, rad + 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(0.7, 0.7, 0.7, 0.6)
        love.graphics.circle("fill", cx, cy, rad - 4)

    elseif key == "wormhole" then
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        love.graphics.setColor(0.4, 0.2, 0.6, 0.4)
        love.graphics.circle("fill", cx, cy, rad + 3)
        local col = Config.colors.wormhole
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(0.6, 0.3, 0.8, 0.6)
        love.graphics.circle("fill", cx, cy, rad - 4)

    elseif key:find("^forbidden_food_") then
        local fnum = tonumber(key:sub(-1)) or 1
        local col = Config.colors["forbidden_food_" .. fnum] or Config.colors.forbidden_food_1
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 6, 6)

    -- EVENT MILESTONES ICONS
    elseif key == "event_death" then
        -- Red cracked heart / cross
        love.graphics.setColor(0.95, 0.2, 0.3, 0.9)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 6, size - 6, 3, 3)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.line(x + 5, y + 5, x + size - 5, y + size - 5)
        love.graphics.line(x + size - 5, y + 5, x + 5, y + size - 5)

    elseif key == "event_mating" then
        -- Double pink heart
        love.graphics.setColor(1.0, 0.4, 0.7, 0.4)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 2)
        love.graphics.setColor(1.0, 0.4, 0.7)
        love.graphics.circle("fill", x + size * 0.35, y + size * 0.45, size * 0.25)
        love.graphics.circle("fill", x + size * 0.65, y + size * 0.45, size * 0.25)

    elseif key == "event_female_spawn" then
        -- Pink snake head with eyes
        love.graphics.setColor(1.0, 0.4, 0.7)
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", x + size * 0.35, y + size * 0.4, 2)
        love.graphics.circle("fill", x + size * 0.65, y + size * 0.4, 2)

    elseif key == "event_forbidden_realm" then
        -- Cosmic purple vortex
        love.graphics.setColor(0.6, 0.1, 0.8, 0.4)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 2)
        love.graphics.setColor(0.8, 0.3, 0.9)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 6, size - 6, 4, 4)

    elseif key == "event_immortal_ending" then
        -- Golden Ouroboros ring
        local cx = x + size / 2
        local cy = y + size / 2
        love.graphics.setColor(1.0, 0.85, 0.2, 0.4)
        love.graphics.circle("fill", cx, cy, size / 2 + 3)
        love.graphics.setColor(1.0, 0.85, 0.2)
        love.graphics.circle("line", cx, cy, size / 2 - 2)
        love.graphics.circle("fill", cx + size * 0.3, cy, 3)

    elseif key == "event_fourth_wall" then
        -- Grid breach icon
        love.graphics.setColor(0.0, 0.8, 0.8, 0.3)
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 3, 3)
        love.graphics.setColor(0.0, 0.9, 0.9)
        love.graphics.rectangle("line", x + 3, y + 3, size - 6, size - 6)
        love.graphics.line(x + size/2, y, x + size/2, y + size)

    elseif key == "event_fifth_wall" then
        -- Desktop window icon
        love.graphics.setColor(0.0, 1.0, 0.0, 0.3)
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 3, 3)
        love.graphics.setColor(0.3, 1.0, 0.4)
        love.graphics.rectangle("line", x + 1, y + 1, size - 2, size - 2, 2, 2)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 6, 4)

    else
        -- Regular power-up
        local col = Config.colors[key] or {1, 1, 1}
        love.graphics.setColor(col[1], col[2], col[3], 0.3)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3], 1)
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 4, 4)
    end
end

return Codex
