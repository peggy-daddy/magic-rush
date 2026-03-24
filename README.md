# Magic Rush 🌟

A chaotic time-management crafting game where you're the only thing standing between a household and complete magical collapse.

Built in Godot 4 for a game design course. 
Try here: https://peggy-daddy.itch.io/magic-
rush

---

## What is this

You run between two rooms under a 3-minute countdown. In the **Sanctuary**, you drag ingredients together to craft magical items. In the **Living Room**, four NPCs are pacing around demanding things from you. Deliver the right item to the right person, keep the Magic Meter climbing, and — the fun part — there's a **Demon Baby** sleeping in the corner who wakes up every minute and starts draining your magic unless you craft a specific 3-step seal to shut it down.

Three possible endings:
- ✨ **Perfect Victory** — hit 100 Magic before time's up (harder than it sounds)
- ⏰ **Time's Up** — survive the 3 minutes with some magic still left
- 💀 **Defeated** — magic hits zero. it got you.

---

## How to play

**Sanctuary (left room):**
- Drag ingredients from the drawers onto Slot A and Slot B
- Hit CRAFT to combine them
- Your backpack (bottom right) holds up to 4 crafted items

**Living Room (right room):**
- Drag items from your backpack directly onto NPCs to fulfill their requests
- The `!` above each NPC means they're waiting for something
- Drag the Heart Seal onto the Baby when it wakes up

**Controls:**
- Left click + drag to pick up / deliver items
- SPACE to pause
- ESC to quit
- ENTER to restart after game over

**Recipes:**

| Ingredients | Makes |
|-------------|-------|
| Paper + Candle | Eye |
| Water Bottle + Potion | Egg |
| Book + Scroll | Pearl |
| Candle + Book | Key |
| Water Bottle + Scroll | Apple |

**Baby Seal (3 steps):**
1. Water Bottle + Paper → Obsidian
2. Candle + Potion → Crystal
3. Obsidian + Crystal → Heart Seal → drag onto Baby

---

## Running it

Requires **Godot 4** (tested on 4.6.1).

```bash
# Open in Godot editor (Mac)
open -a Godot .

# Or from terminal
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

No export templates needed to run from editor.

---

## What's in here

```
magic-rush/
├── project.godot            Godot 4 project config
├── icon.svg                 Game icon
├── scenes/                  All scene files (.tscn)
│   ├── TitleScreen.tscn
│   ├── Sanctuary.tscn
│   ├── LivingRoom.tscn
│   ├── GameOver.tscn
│   ├── HUD.tscn
│   └── InventoryOverlay.tscn
├── scripts/                 GDScript logic
│   ├── GameManager.gd       Core game state, signals, chi/timer
│   ├── AudioManager.gd      BGM + SFX autoload
│   ├── Sanctuary.gd
│   ├── LivingRoom.gd
│   ├── HUD.gd
│   ├── TitleScreen.gd
│   ├── GameOver.gd
│   └── InventoryOverlay.gd
├── assets/
│   ├── backgrounds/         Room mockups + button panels
│   ├── bgm/                 BGM.mp3, Click/Deliver/Siren .wav
│   ├── characters/          Baby calm + angry sprites
│   ├── cursors/             Custom hand cursor
│   ├── fonts/               Kingstone display font
│   ├── sprites/             Items, drawers, NPC characters, emotion icons
│   └── ui/                  Recipe background, Chi crystal icons
└── submission_docs/
    ├── reflection.md        Design process write-up + iteration log
    └── playtest_report.md   Four playtests with feedback
```

---

## Known issues

- Drag precision: items need to land on the NPC body area — edge cases can miss
- Emotion icon alignment: may show placeholder if spritesheet offset is off

---

## Credits

- **Design + development**: Peggy Daddy
- ERW Village Interiors Pack — room backgrounds
- Tasty Characters Village Pack — NPC sprites
- Pixel Art RPG Icon Pack (Free Game Assets) — item icons
- ZOSMA UI Kit — panel art, crystal icons
- Cursor Pack 256 — hand cursor
- Kingstone Demo Font — title display (free demo license)
- Audio: [Mixkit](https://mixkit.co/free-sound-effects/) + [Bensound](https://bensound.com/royalty-free-music/)
- Engine: [Godot 4](https://godotengine.org) (MIT)

---

*Course project. Game design is surprisingly hard. Would recommend.*
