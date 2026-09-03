# Snake Pro

Another classic Snake game built with LÖVE2D, packed with power-ups, special fruits, AI opponents, and mind-bending effects.

## Features

### Core Gameplay
- Classic snake movement with arrow keys or WASD
- Score tracking with persistent high scores
- Lives system (start with 3, max 5)
- Dynamic speed scaling as score increases

### Fruits & Foods

| Fruit | Color | Effect |
|-------|-------|--------|
| Regular Food | Red | +10 points (x3 with Lust Food active) |
| Green Fruit | Lime Green | +200 points + temporary glow effect |
| Golden Fruit | Golden | Rare spawn! Random bonus: extra life, +500 points, or invincibility |

#### Forbidden Realm Foods (appear in dark purple dimension)

| Type | Color | Effect |
|------|-------|--------|
| Type 1 | Dark Green | +15 points |
| Type 2 | Yellow | +30 points |
| Type 3 | Purple | +50 points |
| Type 4 | Cyan | +2 seconds in Forbidden Realm |

### Power-Ups (18 types!)

| Power-Up | Color | Effect |
|----------|-------|--------|
| Shorten | Purple | Shrinks snake by 3 segments |
| Reverse | Cyan | Flips snake direction |
| Speed Up | Yellow | Increases movement speed |
| Slow Down | Blue | Slows movement speed |
| Extra Life | Pink | +1 life (up to max 5) |
| Score Boost | Orange | +50 points |
| Color Change | Teal | Randomizes snake color |
| Devil Fruit | Red | Permanent red + speed boost |
| Lust Food | Hot Pink | 3x points for 5 seconds |
| No Collision | Mint | Phase through walls/body |
| Forbidden | Dark Purple | Enter Forbidden Realm |
| Mate | Light Pink | Summons/extend female snake |
| Rainbow | Rainbow | Rainbow color cycling |
| Wormhole | Dark Purple | Teleports snake |
| White Hole | White | Repels items |
| Black Hole | Black | Attracts items |
| 4th Wall Break | Teal | Leave the grid (dangerous!) |
| 5th Wall Break | Bright Green | Snake segments escape the window |

### AI Female Snake
- Pink-colored AI snake that appears after using Mate power-up
- Has its own lives system
- Can eat fruits and power-ups
- Mating mechanic - When heads touch, you get bonus points! (100 + 50 per mate)
- Tracks mate count and displays on game over

### Forbidden Realm
- Enter via Forbidden power-up
- Dark purple dimension with special forbidden foods
- 4 types of forbidden foods with different point values
- Type 4 extends your time in the realm

### Visual Effects
- Screen shake during mating
- Glow effects from green fruit
- Rainbow mode for snake
- Invincibility blinking
- Golden spark particles during Immortal Ending

### Controls
| Action | Key |
|--------|-----|
| Move | Arrow Keys / WASD |
| Pause | P |
| Restart | R / Space (when game over) |
| Debug Spawn | T (spawns one of every item) |
| Touch/Mouse | Swipe to control direction |

## Installation

1. Download and install [LÖVE2D](https://love2d.org/)
2. Clone or download this repository
3. Run the game:
   ```
   love .
   ```

Or create a .love file by zipping the project folder and renaming to .love.

## Dependencies

- LÖVE2D - Game framework
- Moonshine - For retro scanline/CRT effects (optional, currently commented out)
- FFI - For SDL2 integration (5th Wall Break feature)

## Objective

Eat food to grow your snake and increase your score. Collect power-ups strategically, manage your lives, and survive as long as possible. Reach a high score to become Immortal (triggers a special ending when you eat your own tail)!

## Debug Mode

Press T to spawn one of every item type on the board (useful for testing all power-ups).

---

Made with love using LÖVE2D