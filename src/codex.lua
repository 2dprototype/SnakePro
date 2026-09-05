-- ============================================================
-- SNAKE PRO - ITEM DATABASE & CODEX (WITH EVENT MILESTONES)
-- ============================================================
local Config = require("config")
local Utils = require("utils")

local Codex = {}

Codex.items = {
    -- Foods & Rare Fruits
    {
        key = "food",
        name = "Normal Apple",
        category = "Basic Food",
        points = "+10 pts",
        desc = "Standard crisp apple. Increases snake length by 1 and advances base speed over time."
    },
    {
        key = "greenfruit",
        name = "Lime Green Apple",
        category = "Rare Fruit",
        points = "+200 pts, Glow & Speed",
        desc = "Rare glowing harvest. Awards +200 points, accelerates movement speed, and envelops the snake in an energetic green glow for 5s."
    },
    {
        key = "goldenfruit",
        name = "Golden Apple",
        category = "Legendary Food",
        points = "+250 pts & Life",
        desc = "Legendary jackpot harvest! Grants +250 points, +1 Extra Life, and a 3-second golden invincibility shield."
    },
    {
        key = "coin",
        name = "Gold Coin",
        category = "Currency",
        points = "+1 Coin (Shop Currency)",
        desc = "Shimmering gold currency harvested on the board. Spend your collected coins in the Upgrades Shop for permanent fruit and power-up boosts!"
    },

    -- Tactical Utility
    {
        key = "shorten",
        name = "Tail Cutter",
        category = "Tactical Utility",
        points = "Trims 3 Segments",
        desc = "Instantly shears off up to 3 segments from the tail, providing breathing room in tight corners."
    },
    {
        key = "reverse",
        name = "U-Turn Paradox",
        category = "Tactical Utility",
        points = "180° Direction Flip",
        desc = "Swaps head and tail immediately, reversing your movement direction by 180 degrees."
    },
    {
        key = "nocollision",
        name = "Ghost Phase",
        category = "Tactical Utility",
        points = "Intangible (4s)",
        desc = "Allows the snake to phase straight through its own body segments unharmed for 4 seconds."
    },
    {
        key = "slowdown",
        name = "Frost Hourglass",
        category = "Tactical Utility",
        points = "50% Slow-Mo (5s)",
        desc = "Chills time itself, reducing movement speed by 50% for 5 seconds for surgical turning."
    },
    {
        key = "extralife",
        name = "Heart Core",
        category = "Tactical Utility",
        points = "+1 Extra Life",
        desc = "Infuses the snake with a vital heart container (+1 Life, up to maximum 5 lives)."
    },
    {
        key = "box",
        name = "Wooden Crate",
        category = "Interactive Obstacle",
        points = "+100 pts (Smash)",
        desc = "Solid wooden crate that collides with snakes and items. Cannot be eaten. Push it outside the arena boundaries to smash it for +100 bonus points!"
    },

    -- Power Surge
    {
        key = "devilfruit",
        name = "Devil's Fruit",
        category = "Power Surge",
        points = "+100 pts & Surge",
        desc = "Imbues the snake with a permanent demonic crimson skin, +100 bonus points, and a speed surge."
    },
    {
        key = "rainbow",
        name = "Rainbow Prism",
        category = "Cosmetic Power",
        points = "Rainbow Visual (10s)",
        desc = "Illuminates the snake in a dazzling ROYGBIV rainbow color-cycling spectrum for 10 seconds."
    },
    {
        key = "speedfood",
        name = "Thunder Surge",
        category = "Power Surge",
        points = "+50 pts & Speed (5s)",
        desc = "Electrifies the snake with thunderous energy, granting a 1.8x lightning speed surge for 5 seconds."
    },
    {
        key = "stopfood",
        name = "Chronostasis (Stop)",
        category = "Tactical Utility",
        points = "Freeze (5s)",
        desc = "Completely halts all movement of the snake that consumes it for 5 seconds."
    },
    {
        key = "magnet",
        name = "Cosmic Magnet",
        category = "Power Surge",
        points = "Food Vacuum (6s)",
        desc = "Generates a magnetic vacuum that smoothly draws all foods and shards across the board toward your head."
    },
    {
        key = "colorchange",
        name = "Prism Dye",
        category = "Power-up",
        points = "Live Color Capture",
        desc = "Constantly cycles through vivid prism spectrum colors. When eaten by you or the AI companion, absorbs the exact color captured at that split second!"
    },

    -- Cosmic Powers
    {
        key = "whitehole",
        name = "Whitehole",
        category = "Cosmic Power",
        points = "Repulsion (5s)",
        desc = "Generates gravitational repulsion, pushing items away from your snake's head."
    },
    {
        key = "blackhole",
        name = "Blackhole",
        category = "Cosmic Power",
        points = "Attraction (5s)",
        desc = "Generates an intense gravitational vortex drawing distant items directly towards your head."
    },
    {
        key = "wormhole",
        name = "Wormhole",
        category = "Cosmic Power",
        points = "Spatial Teleport",
        desc = "Instantly teleports the entire snake to a random safe location on the grid, preserving body geometry."
    },
    {
        key = "gravityfruit",
        name = "Gravity Fruit",
        category = "Cosmic Power",
        points = "Downward Pull (5s)",
        desc = "Generates intense planetary downward gravity, steadily pulling all fruits, items, and crates toward the bottom of the grid."
    },
    {
        key = "antigravity",
        name = "Antigravity Fruit",
        category = "Cosmic Power",
        points = "Upward Pull (5s)",
        desc = "Reverses gravitational polarity, pulling all fruits, items, and crates towards the ceiling of the grid."
    },
    {
        key = "physicsfruit",
        name = "Physics Fruit",
        category = "Cosmic Power",
        points = "Zero-G Physics (8s)",
        desc = "Un-snaps all objects from grid cells into zero-gravity physical bodies that float, bounce, collide with boxes, and respond to cosmic forces."
    },

    -- Social & Companion
    {
        key = "mate",
        name = "Pheromone Core",
        category = "Social / AI",
        points = "Summons AI Snake",
        desc = "Summons a pink AI female companion or extends her lifespan by +30s. Touch heads to mate for massive points!"
    },
    {
        key = "lustfood",
        name = "Lust Berry",
        category = "Social / AI",
        points = "3x pts & AI Magnet",
        desc = "Triples all point gains for 5 seconds and magnetically lures the female snake directly to your head for mating."
    },

    -- Reality Breakers
    {
        key = "forbidden",
        name = "Forbidden Sigil",
        category = "Reality Breaker",
        points = "Forbidden Realm (8s)",
        desc = "Tears open space-time to transport the snake into the cosmic Forbidden Realm packed with high-value shards."
    },
    {
        key = "fourthwall",
        name = "4th Wall Breach",
        category = "Reality Breaker",
        points = "Boundary Void",
        desc = "Shatters arena walls for 15s. Slither outside into the surrounding void (return within 5s to survive!)."
    },
    {
        key = "fifthwall",
        name = "5th Wall Breakout",
        category = "Reality Breaker",
        points = "Desktop Windows",
        desc = "Outside segments escape into real desktop windows! Foods and crates materialize across your Windows desktop too."
    },

    -- Forbidden Realm Shards
    {
        key = "forbidden_food_1",
        name = "Cosmic Shard",
        category = "Forbidden Realm",
        points = "+30 pts",
        desc = "Radiant emerald energy shard harvested exclusively within the cosmic Forbidden Realm (+30 points)."
    },
    {
        key = "forbidden_food_2",
        name = "Chrono Shard",
        category = "Forbidden Realm",
        points = "+2.5s Realm Time",
        desc = "Cyan time crystal that extends your remaining duration in the Forbidden Realm by +2.5 seconds."
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
        desc = "Plunges the grid into dark purple cosmos populated exclusively by high-value forbidden shards."
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
        desc = "Outside segments materialize as real floating borderless windows across your Windows desktop, alongside delicious apples and smashable crates."
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
        -- Red Apple with leaf/stem
        local col = Config.colors.food
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 3, size - 4, size - 5, 5,5)
        love.graphics.setColor(1.0, 0.4, 0.4, 0.6)
        love.graphics.rectangle("fill", x + 3, y + 4, 3, 3, 1, 1)
        love.graphics.setColor(0.3, 0.9, 0.2)
        love.graphics.rectangle("fill", x + size / 2, y + 1, 3, 3, 1, 1)

    elseif key == "greenfruit" then
        -- Lime Green Apple (Glow & Speed)
        local col = Config.colors.greenfruit
        local pulse = 0.35 + 0.15 * math.sin(time * 5)
        love.graphics.setColor(col[1], col[2], col[3], pulse)
        love.graphics.rectangle("fill", x - 3, y - 3, size + 6, size + 6, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 2, size - 2, size - 4, 5, 5)
        love.graphics.setColor(col[1] * 0.6, col[2] * 0.8, col[3] * 0.6)
        love.graphics.rectangle("fill", x + 3, y + 4, 4, 4, 2, 2)
        love.graphics.setColor(col[1] * 0.6, col[2] * 0.8, col[3] * 0.6)
        love.graphics.rectangle("fill", x + size / 2, y, 4, 3, 1, 1)

    elseif key == "goldenfruit" then
        -- Golden Apple Jackpot
        local col = Config.colors.goldenfruit
        local pulse = 0.35 + 0.15 * math.sin(time * 5)
        love.graphics.setColor(col[1], col[2], col[3], pulse)
        love.graphics.rectangle("fill", x - 3, y - 3, size + 6, size + 6, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 2, size - 2, size - 4, 5, 5)
        love.graphics.setColor(1.0, 1.0, 0.8)
        love.graphics.rectangle("fill", x + 3, y + 4, 4, 4, 2, 2)
        love.graphics.setColor(1.0, 0.95, 0.4)
        love.graphics.rectangle("fill", x + size / 2, y, 4, 3, 1, 1)

    elseif key == "coin" then
        -- Shimmering Golden Coin with inner rim & glint
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        local pulse = 0.35 + 0.15 * math.sin(time * 6)
        
        -- Golden aura glow
        love.graphics.setColor(1.0, 0.85, 0.2, pulse)
        love.graphics.circle("fill", cx, cy, rad + 2)

        -- Coin outer rim
        love.graphics.setColor(0.85, 0.65, 0.0)
        love.graphics.circle("fill", cx, cy, rad - 0.5)

        -- Coin face (bright gold)
        love.graphics.setColor(1.0, 0.84, 0.1)
        love.graphics.circle("fill", cx, cy, rad - 2)

        -- Inner embossed circle
        love.graphics.setColor(0.9, 0.72, 0.05)
        love.graphics.circle("line", cx, cy, rad - 3.5)

        -- Central Star / Glyph
        love.graphics.setColor(1.0, 0.95, 0.6)
        local starR = math.max(2, rad * 0.4)
        love.graphics.polygon("fill",
            cx, cy - starR,
            cx + starR * 0.35, cy - starR * 0.35,
            cx + starR, cy,
            cx + starR * 0.35, cy + starR * 0.35,
            cx, cy + starR,
            cx - starR * 0.35, cy + starR * 0.35,
            cx - starR, cy,
            cx - starR * 0.35, cy - starR * 0.35
        )

        -- Specular highlight glint
        love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
        love.graphics.circle("fill", cx - rad * 0.35, cy - rad * 0.35, math.max(1, rad * 0.2))

    elseif key == "shorten" then
        -- Purple Scissors / Cutter
        local col = Config.colors.shorten
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.line(x + 4, y + 4, x + size - 4, y + size - 4)
        love.graphics.line(x + size - 4, y + 4, x + 4, y + size - 4)

    elseif key == "reverse" then
        -- Cyan 180 Flip Arrows
        local col = Config.colors.reverse
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.line(x + 4, y + size/2 - 2, x + size - 4, y + size/2 - 2)
        love.graphics.line(x + 4, y + size/2 + 2, x + size - 4, y + size/2 + 2)

    elseif key == "nocollision" then
        -- Mint Ghost Phase
        local col = Config.colors.nocollision
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 2)
        love.graphics.setColor(col[1], col[2], col[3], 0.85)
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 4, 4)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.circle("fill", x + size * 0.35, y + size * 0.4, 2)
        love.graphics.circle("fill", x + size * 0.65, y + size * 0.4, 2)

    elseif key == "slowdown" then
        -- Ice Blue Frost Hourglass
        local col = Config.colors.slowdown
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(0.8, 0.95, 1.0, 0.9)
        love.graphics.polygon("fill", x + 4, y + 4, x + size - 4, y + 4, x + size/2, y + size/2)
        love.graphics.polygon("fill", x + 4, y + size - 4, x + size - 4, y + size - 4, x + size/2, y + size/2)

    elseif key == "extralife" then
        -- Pink Heart Core
        local col = Config.colors.extralife
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 2)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", x + size * 0.35, y + size * 0.4, size * 0.28)
        love.graphics.circle("fill", x + size * 0.65, y + size * 0.4, size * 0.28)
        love.graphics.polygon("fill", x + 2, y + size * 0.45, x + size - 2, y + size * 0.45, x + size / 2, y + size - 2)

    elseif key == "devilfruit" then
        -- Crimson Demonic Fruit
        local col = Config.colors.devilfruit
        local pulse = 0.35 + 0.15 * math.sin(time * 5)
        love.graphics.setColor(col[1], col[2], col[3], pulse)
        love.graphics.rectangle("fill", x - 3, y - 3, size + 6, size + 6, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 2, size - 2, size - 4, 5, 5)
        love.graphics.setColor(col[1] * 0.6, col[2] * 0.8, col[3] * 0.6)
        love.graphics.rectangle("fill", x + 3, y + 4, 4, 4, 2, 2)
        love.graphics.setColor(col[1] * 0.6, col[2] * 0.8, col[3] * 0.6)
        love.graphics.rectangle("fill", x + size / 2, y, 4, 3, 1, 1)
        
    elseif key == "rainbow" then
        -- ROYGBIV Rainbow Star Frenzy
        local rainbowColors = {
            {1.0, 0.0, 0.0}, {1.0, 0.5, 0.0}, {1.0, 1.0, 0.0},
            {0.0, 1.0, 0.0}, {0.0, 0.8, 1.0}, {0.3, 0.0, 0.9}, {0.7, 0.0, 0.9}
        }
        local cIdx = math.floor(time * 8.0) % 7 + 1
        local col = rainbowColors[cIdx]
        love.graphics.setColor(col[1], col[2], col[3], 0.45)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 3)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 4, 4)

    elseif key == "speedfood" then
        -- Yellow Thunder Surge (Lightning Bolt)
        local cx = x + size / 2
        local cy = y + size / 2
        local pulse = 0.35 + 0.15 * math.sin(time * 8)
        love.graphics.setColor(1.0, 0.9, 0.1, pulse)
        love.graphics.circle("fill", cx, cy, size / 2 + 3)
        love.graphics.setColor(0.15, 0.12, 0.02, 0.85)
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 4, 4)
        love.graphics.setColor(1.0, 0.85, 0.1)
        love.graphics.rectangle("line", x + 1, y + 1, size - 2, size - 2, 4, 4)

        -- Lightning Bolt shape
        love.graphics.setColor(1.0, 0.95, 0.15)
        love.graphics.polygon("fill",
            cx + 1, y + 2,
            cx - 5, cy + 1,
            cx - 1, cy + 1,
            cx - 3, y + size - 2,
            cx + 5, cy - 1,
            cx + 1, cy - 1
        )
        -- Core white highlight
        love.graphics.setColor(1.0, 1.0, 0.8, 0.9)
        love.graphics.polygon("fill",
            cx + 1, y + 4,
            cx - 3, cy,
            cx, cy,
            cx - 1, cy + 3,
            cx + 3, cy - 1,
            cx + 1, cy - 1
        )

    elseif key == "stopfood" then
        -- Red / Crimson Stop Sign (Chronostasis Freeze)
        local cx = x + size / 2
        local cy = y + size / 2
        local pulse = 0.35 + 0.15 * math.sin(time * 5)
        love.graphics.setColor(0.95, 0.25, 0.25, pulse)
        love.graphics.circle("fill", cx, cy, size / 2 + 3)
        love.graphics.setColor(0.85, 0.15, 0.2)
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 4, 4)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.95)
        -- Dual pause/halt bars
        local barW = math.max(2, math.floor(size * 0.18))
        local barH = math.max(6, math.floor(size * 0.55))
        love.graphics.rectangle("fill", cx - barW - 2, cy - barH / 2, barW, barH, 1, 1)
        love.graphics.rectangle("fill", cx + 2, cy - barH / 2, barW, barH, 1, 1)

    elseif key == "magnet" then
        -- Cosmic Magnet (Horseshoe Vacuum)
        local cx = x + size / 2
        local cy = y + size / 2
        local pulse = 0.3 + 0.15 * math.sin(time * 6)
        love.graphics.setColor(0.3, 0.4, 0.9, pulse)
        love.graphics.circle("fill", cx, cy, size / 2 + 3)
        love.graphics.setColor(0.2, 0.25, 0.4)
        love.graphics.circle("fill", cx, cy, size / 2 - 1)
        -- love.graphics.setColor(0.4, 0.7, 1.0)
        -- love.graphics.circle("line", cx, cy, size / 2 - 2)
        love.graphics.setColor(0.9, 0.3, 0.3)
        love.graphics.rectangle("fill", cx - 4, cy - 4, 3, 8)
        love.graphics.setColor(0.3, 0.5, 1.0)
        love.graphics.rectangle("fill", cx + 1, cy - 4, 3, 8)

    elseif key == "colorchange" then
        -- Prism Dye: live shifting chromatic prism crystal
        local pCol = Utils.getPrismColor(0)
        local pSec = Utils.getPrismColor(0.25)
        local pTert = Utils.getPrismColor(0.5)
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2

        -- Chromatic aura pulse
        local pulse = 0.35 + 0.15 * math.sin(time * 6)
        love.graphics.setColor(pCol[1], pCol[2], pCol[3], pulse)
        love.graphics.circle("fill", cx, cy, rad + 2)

        -- Diamond prism shape
        love.graphics.setColor(pCol[1], pCol[2], pCol[3], 0.95)
        love.graphics.polygon("fill", cx, cy - rad + 1, cx + rad - 1, cy, cx, cy + rad - 1, cx - rad + 1, cy)

        -- Inner spectrum facets
        love.graphics.setColor(pSec[1], pSec[2], pSec[3], 0.9)
        love.graphics.polygon("fill", cx, cy - rad + 3, cx + rad - 3, cy, cx, cy, cx, cy)
        love.graphics.setColor(pTert[1], pTert[2], pTert[3], 0.9)
        love.graphics.polygon("fill", cx, cy, cx - rad + 3, cy, cx, cy + rad - 3)

        -- Crystal reflection glint
        love.graphics.setColor(1.0, 1.0, 1.0, 0.85)
        love.graphics.circle("fill", cx - 1, cy - 2, 2)
        love.graphics.circle("fill", cx + 2, cy + 2, 1)

    elseif key == "whitehole" then
        -- Whitehole (Repulsion)
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        love.graphics.setColor(0.8, 0.8, 0.8, 0.35 + math.sin(time * 2) * 0.1)
        love.graphics.circle("fill", cx, cy, rad + 3)
        love.graphics.setColor(1.0, 1.0, 1.0)
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(0.8, 0.8, 0.8, 0.5)
        love.graphics.circle("fill", cx, cy, rad - 4)

    elseif key == "blackhole" then
        -- Blackhole (Attraction)
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        love.graphics.setColor(1, 1, 1, 0.35 + math.sin(time * 2) * 0.1)
        love.graphics.circle("fill", cx, cy, rad + 3)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        love.graphics.circle("line", cx, cy, rad - 2)

    elseif key == "wormhole" then
        -- Wormhole (Spatial Teleport)
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        love.graphics.setColor(0.4, 0.2, 0.6, 0.4 + math.sin(time * 2) * 0.1)
        love.graphics.circle("fill", cx, cy, rad + 3)
        local col = Config.colors.wormhole
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 0.5)
        love.graphics.circle("fill", cx, cy, rad - 4)

    elseif key == "mate" then
        -- Pink Pheromone Core
        local col = Config.colors.mate
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 3)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", x + size * 0.35, y + size * 0.4, size * 0.25)
        love.graphics.circle("fill", x + size * 0.65, y + size * 0.4, size * 0.25)
        love.graphics.polygon("fill", x + 2, y + size * 0.45, x + size - 2, y + size * 0.45, x + size / 2, y + size - 2)

    elseif key == "lustfood" then
        -- Magenta Lust Berry
        local col = Config.colors.lustfood
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 3)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 - 2)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", x + size * 0.4, y + size * 0.35, 2)

    elseif key == "gravityfruit" then
        -- Gravity Fruit (Heavy Downward Pull)
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        local col = Config.colors.gravityfruit or {0.6, 0.25, 0.85}
        love.graphics.setColor(col[1], col[2], col[3], 0.35 + math.sin(time * 3) * 0.1)
        love.graphics.circle("fill", cx, cy, rad + 3)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
        love.graphics.line(cx - 3, cy - 1, cx, cy + 3)
        love.graphics.line(cx + 3, cy - 1, cx, cy + 3)
        love.graphics.line(cx, cy - 4, cx, cy + 3)

    elseif key == "antigravity" then
        -- Antigravity Fruit (Upward Pull)
        local cx = x + size / 2
        local cy = y + size / 2
        local rad = size / 2
        local col = Config.colors.antigravity or {0.2, 0.9, 0.85}
        love.graphics.setColor(col[1], col[2], col[3], 0.35 + math.sin(time * 3) * 0.1)
        love.graphics.circle("fill", cx, cy, rad + 3)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.circle("fill", cx, cy, rad - 1)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
        love.graphics.line(cx - 3, cy + 1, cx, cy - 3)
        love.graphics.line(cx + 3, cy + 1, cx, cy - 3)
        love.graphics.line(cx, cy + 4, cx, cy - 3)

    elseif key == "physicsfruit" then
        -- Physics Fruit (Zero-G Floating Atom / Cube)
        local cx = x + size / 2
        local cy = y + size / 2
        local col = Config.colors.physicsfruit or {0.95, 0.8, 0.1}
        love.graphics.setColor(col[1], col[2], col[3], 0.35 + math.sin(time * 4) * 0.15)
        love.graphics.circle("fill", cx, cy, size / 2 + 2)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(time * 1.5)
        love.graphics.rectangle("line", -size * 0.3, -size * 0.3, size * 0.6, size * 0.6, 2, 2)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.9)
        love.graphics.circle("fill", 0, 0, 2)
        love.graphics.pop()

    elseif key == "forbidden" then
        -- Cosmic Purple Sigil
        local col = Config.colors.forbidden
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.circle("fill", x + size / 2, y + size / 2, size / 2 + 3)
        love.graphics.setColor(0.8, 0.2, 0.9)
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 4, 4)
        love.graphics.setColor(0.2, 0.05, 0.3)
        love.graphics.rectangle("fill", x + 4, y + 4, size - 8, size - 8, 2, 2)

    elseif key == "fourthwall" then
        -- 4th Wall Breach
        local col = Config.colors.fourthwall
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("line", x + 2, y + 2, size - 4, size - 4)
        love.graphics.line(x + size/2, y, x + size/2, y + size)

    elseif key == "fifthwall" then
        -- 5th Wall Desktop Breakout
        local col = Config.colors.fifthwall
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("line", x + 1, y + 1, size - 2, size - 2, 2, 2)
        love.graphics.rectangle("fill", x + 3, y + 3, size - 6, 4)

    elseif key == "forbidden_food_1" then
        -- Cosmic Shard (Emerald)
        local col = Config.colors.forbidden_food_1
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.7)
        love.graphics.rectangle("fill", x + 4, y + 4, 3, 3, 1, 1)

    elseif key == "forbidden_food_2" then
        -- Chrono Shard (Cyan)
        local col = Config.colors.forbidden_food_2
        love.graphics.setColor(col[1], col[2], col[3], 0.4)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 2, y + 2, size - 4, size - 4, 3, 3)
        love.graphics.setColor(1.0, 1.0, 1.0, 0.8)
        love.graphics.line(x + size/2, y + 3, x + size/2, y + size - 3)
        love.graphics.line(x + 3, y + size/2, x + size - 3, y + size/2)

    elseif key == "box" then
        -- Wooden Crate [X]
        local col = Config.colors.box or {0.72, 0.48, 0.24}
        local borderCol = Config.colors.boxBorder or {0.45, 0.28, 0.12}
        love.graphics.setColor(borderCol[1], borderCol[2], borderCol[3], 0.4)
        love.graphics.rectangle("fill", x - 1, y - 1, size + 2, size + 2, 3, 3)
        love.graphics.setColor(col[1], col[2], col[3])
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 2, 2)
        love.graphics.setColor(borderCol[1], borderCol[2], borderCol[3])
        love.graphics.rectangle("line", x + 1.5, y + 1.5, size - 3, size - 3)
        -- Cross bracing
        love.graphics.line(x + 3, y + 3, x + size - 3, y + size - 3)
        love.graphics.line(x + size - 3, y + 3, x + 3, y + size - 3)
        -- Corner rivets/nails
        love.graphics.setColor(0.25, 0.15, 0.08)
        love.graphics.rectangle("fill", x + 2.5, y + 2.5, 1.5, 1.5)
        love.graphics.rectangle("fill", x + size - 4, y + 2.5, 1.5, 1.5)
        love.graphics.rectangle("fill", x + 2.5, y + size - 4, 1.5, 1.5)
        love.graphics.rectangle("fill", x + size - 4, y + size - 4, 1.5, 1.5)

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
        -- Fallback
        local col = Config.colors[key] or {1, 1, 1}
        love.graphics.setColor(col[1], col[2], col[3], 0.35)
        love.graphics.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 6, 6)
        love.graphics.setColor(col[1], col[2], col[3], 1)
        love.graphics.rectangle("fill", x + 1, y + 1, size - 2, size - 2, 4, 4)
    end
end

return Codex
