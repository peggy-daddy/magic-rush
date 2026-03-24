# Magic Rush 🌟
**A time-management crafting delivery game**
**By: Peggy_Daddy (Scarlett Y)  | Engine: Godot 4**

Itchi.io - play online: https://peggy-daddy.itch.io/magic-rush
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
- **Drag**: Left-click hold → drag item
- **Deliver**: Drag item from Backpack onto NPC or Baby
- **SPACE**: Pause / unpause
- **ESC**: Quit game
- **ENTER**：Restart game

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

```
# Open in editor
open -a Godot godot-project

# Or from terminal
/Applications/Godot.app/Contents/MacOS/Godot --path godot-project/
```

No export templates needed to run from editor.

---

## What's in here

```
godot-project/
├── scenes/          # TitleScreen, Sanctuary, LivingRoom, GameOver, HUD, Inventory
├── scripts/         # GDScript — GameManager, AudioManager, scene controllers
├── assets/
│   ├── backgrounds/ # Room mockups + button panel art
│   ├── bgm/         # Background music + SFX (BGM, Click, Deliver, Baby Siren)
│   ├── characters/  # Baby calm + angry sprites
│   ├── cursors/     # Custom hand cursor
│   ├── fonts/       # Kingstone display font
│   ├── sprites/     # Items, drawers, NPC characters, emotion icons
│   └── ui/          # Foldingpaper recipe bg, Crystal icons for chi bar
└── project.godot

submission_docs/
├── reflection.md       # Design process write-up
└──  playtest_report.md  # Four playtests with feedback
```

---

## Known Issues
- Drag precision: Items must be dragged onto the NPC body area; edge cases may miss
- Emotion icons may show placeholder if spritesheet frame offset is misaligned

---

## Credits
- **Game Design & Development**: Peggy Daddy
- **Art Assets**:
  - ERW Village Interiors Pack (CC0 / Free Use) — backgrounds
  - Tasty Characters Village Pack (Free Use) — NPC sprites
  - Pixel Art RPG Icon Pack by Free Game Assets (Free) — item icons
  - ZOSMA UI Kit (Free) — UI panels, crystal icons
  - Cursor Pack 256 (Free) — custom cursor sprites
  - Kingstone Demo Font (Free Demo License) — title font
- **Music & SFX**: 
  - Sound by https://mixkit.co/free-sound-effects/
  - Music by https://bensound.com/royalty-free-music/
- **Engine**: Godot 4 — godotengine.org (MIT License)

---

## Build Info
- Platform: macOS standalone / Web (Chrome)
- Resolution: 1280x720
- Godot version: 4.6.1 stable
