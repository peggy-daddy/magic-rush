# Magic Rush — Design Reflection

## Overview

Magic Rush is a 2D pixel art time-management crafting game built in Godot 4. The player cycles between two rooms: a Sanctuary where they craft magical items by combining ingredients dragged from drawers, and a Living Room where they deliver crafted items to four walking NPCs to earn Magic. A Demon Baby wakes periodically, draining Magic until silenced with a special three-step craft. The game ends in one of three states: Perfect Victory (Magic reaches 100), Defeated (Magic hits zero), or Time's Up (three minutes pass with Magic remaining).

---

## Iteration Log and Key Changes

**Prototype Foundation (V2)**
The initial build established the core loop: drawer-based ingredient collection, two-slot prep station crafting, and NPC delivery. The game ran without crashing and passed headless validation, but UI was placeholder-only — no real backgrounds, no cursor, no sound.

**Visual and Mechanical Overhaul (V3)**
Sanctuary received pixel art drawer sprites and a drag-and-drop mechanic replacing the original click-to-pickup flow. The recipe list moved to the left panel. A shared HUD with Chi Bar and countdown timer was introduced across both scenes. The NPC system expanded to four characters with independent walk cycles.

**Identity Redesign (V4)**
The game was renamed from Feng Shui Rush to Magic Rush and rebranded away from Eastern aesthetics toward a fantasy theme. All item names became Western-neutral (talisman → Eye, elixir → Egg, etc.). The title screen was rebuilt with a fantasy layout, gold Kingstone typeface, and three fantasy-themed buttons.

**Playability Gap Remediation (V5)**
A full audit against the submission requirements revealed several gaps: the Chi bar started at zero (making the game nearly unwinnable), no keyboard shortcuts existed for quitting or replaying, no live delivery score was shown during play, and the Game Over screen lacked meaningful statistics. All were corrected: Chi now starts at 20, ESC quits, ENTER replays, and Game Over shows time survived, deliveries made, and final Magic percentage.

**Drag-and-Drop Delivery Overhaul (V6–V7)**
Early playtesting revealed that requiring players to click a "!" bubble before delivering felt like an unnecessary gate. The delivery flow was simplified: players drag items from the backpack directly onto any NPC or the Baby without any prior step. The backpack drag visual was also improved — the original icon appeared on top of the slot (looking like a copy), and was revised so the slot icon dims while a full-opacity ghost follows the cursor, giving the tactile feel of lifting an item.

**Audio System (V9)**
An AudioManager autoload was added with four sound layers: looping BGM, Baby Siren (overlaid on BGM when the Baby wakes, stops when silenced), Click (inventory selections and scene transitions), and Deliver (successful drops). HUD gained BGM and SFX mute toggles.

**Three Endings and Chi Rebalance (V8)**
Originally the game had a binary win/lose. This was replaced with three distinct endings: Perfect Victory (chi = 100, instant trigger), Defeated (chi = 0, instant trigger), and Time's Up (chi between 1–99 when timer expires). Each has its own full-screen color scheme and message. Chi rebalance: delivery awards +10, silencing Baby awards +40, Baby drain was reduced to 2/sec, and Baby now wakes on a fixed 60-second cycle rather than random.

**Bug Resolution and UI Polish (V10–V16)**
Several persistent bugs were resolved through root-cause diagnosis rather than repeated patching. The How-to-Play close button required replacing button-press detection with a click-outside-to-close pattern, since the long text content was overflowing the VBox and making the button unreachable. The Chi bar's progress color was simplified to always-red (previously cycled green/yellow/red with chi level, which confused players after Baby silencing). NPC sprites were replaced with character-pack assets for visual variety. The Baby was repositioned to the center of the Living Room background image, directly on the visible bed.

---

## What Worked Well

**The drag-and-drop crafting loop** proved intuitive and satisfying once the visual ghost was added. Players could see what they were carrying and where to drop it without tutorial prompts.

**Three distinct endings** gave the game a clearer success/failure structure and made replays feel purposeful — players chasing the Perfect Victory naturally engaged with the Baby-silencing mechanic rather than ignoring it.

**The Chi rebalance** transformed the game from nearly unwinnable to approachable. Starting at 20 and awarding +40 for silencing the Baby makes the crisis mechanic feel rewarding rather than punishing.

**Layered audio** (BGM + situational siren) created a clear emotional signal when the Baby woke, prompting the right player response without text instruction.

---

## What Needed Improvement

**The multi-step Baby Seal recipe** (three crafting steps) introduced late in development created cognitive load. Players needed to remember two intermediate products (Obsidian and Crystal) before the final Heart Seal — a recipe chain not clearly visible during crisis.

**NPC request randomness** occasionally produced back-to-back identical requests for the same NPC, which felt repetitive. A cooldown or no-repeat rule for consecutive requests would improve variety.

**Drag precision on moving NPCs** was sometimes frustrating — the NPCs' patrol zones were generous but their visual sprites moved independently from the collision rect in some edge cases.

---

## Conclusion

Magic Rush evolved from a GDScript skeleton to a playable, polished prototype across sixteen design iterations in a single development session. The most impactful changes were not cosmetic but structural: simplifying the delivery flow, introducing three endings, and rebalancing the economy so the game feels winnable. The core loop — craft in Sanctuary, deliver in Living Room, manage the Baby crisis — held up throughout every iteration and remained the design's strongest element.

---

*Submitted by: Peggy Daddy | Engine: Godot 4.6.1 | Date: March 2026*

---

## Appendix: Iteration Log (V2–V16)

### Iteration V2 — Foundation
- Built initial Godot 4 project structure from scratch
- Implemented GameManager autoload with signals (chi_changed, timer_updated, game_over, baby_woke)
- Created all 4 scenes: TitleScreen, Sanctuary, LivingRoom, GameOver
- Wrote core GDScript for crafting logic, NPC delivery validation, Baby wake timer
- Fixed sub_resource ordering errors in .tscn files that blocked scene loading
- Renamed private `_calculate_stars()` to public `calculate_stars()` to fix cross-script call
- Simplified Master Seal recipe from 3 ingredients to 2 (within 2-slot constraint)
- Ran Godot headless validation — zero errors confirmed

### Iteration V3 — Visual Overhaul + Gameplay Depth
- Replaced placeholder drawer buttons with pixel art cabinet sprites (cabinet1-drawer1/2.png)
- Added per-drawer item icons using RPG icon pack assets
- Implemented drag-and-drop from drawers to Slot A/Slot B (replaced click-to-hold)
- Added 5-second drawer refill timer with visual state switching (open/closed sprite)
- Moved Recipe display to left panel with font size 18+
- Built InventoryOverlay.tscn as shared CanvasLayer across both scenes (4-slot backpack)
- Added Living Room NPC left-right walking animation via Tween (independent x-ranges per NPC)
- Implemented exclamation mark click → thought bubble reveal mechanic
- Added emoji feedback on delivery: 😊 success, 😠 failure
- Implemented Demon Baby scale/color Tween animation on wake
- Built unified HUD.tscn (CanvasLayer, autoload) with Chi Bar + countdown timer
- Ran QA Feature List audit — all 10 core features confirmed implemented

### Iteration V4 — Identity Redesign + 11 Feature Upgrades
- Renamed game from "Feng Shui Rush" to "Magic Rush"; removed all Eastern aesthetic elements
- Replaced yin-yang icon with gold star SVG game icon
- Rebuilt TitleScreen: Kingstone gold title font, fantasy color palette, 3 buttons with hover effects
- Replaced mockup backgrounds: mockup5.png (Living Room), mockup2.png (Sanctuary)
- Added 4th NPC (Mom + Child) with independent walk zones (no overlap paths)
- Removed NPC grey panel backgrounds; NPCs scaled to 0.65 for screen balance
- Implemented cursor size fix: dynamic resize to 24×24px using Image.new().load() method
- Switched Inventory from single-slot to 4-slot 2×2 grid
- Added drag-from-inventory mechanic in Living Room (replaced click-to-deliver)
- Replaced Grimoire popup with Sanctuary left-panel recipe display
- Swapped Baby character to baby_calm.png / baby_angry.png (user-provided sprites)
- Added TextureProgressBar Chi Bar with crystal icon (Cristalblue/orange/red)
- Implemented BGM/SFX toggle buttons in HUD right corner

### Iteration V5 — Playability Requirements Gap Remediation
- Set Chi starting value to 50 (from 0) to ensure game is winnable on first attempt
- Added ESC key to quit from any game scene
- Added ENTER key to replay from GameOver screen
- Added live delivery counter in HUD ("✨ N delivered")
- Rebuilt GameOver screen to show: time survived, deliveries count, final Magic %
- Updated How to Play panel content to reflect drag-drop mechanics and 4-NPC system
- Fixed chi drain rate: reduced from 5/sec to 3/sec to allow player recovery time
- Increased NPC delivery reward from +10 to +15 chi

### Iteration V6 — Debug + Scene Polish
- Changed game entry point: Start → Living Room first (then Sanctuary)
- Fixed Inventory visibility: removed from TitleScreen and GameOver, retained only in Sanctuary + LivingRoom
- Corrected NPC walk start_x values: all 4 NPCs had identical x=140 (complete overlap); set to 180/450/720/990
- Implemented AutoMove.cs-equivalent walk logic in GDScript (flip_h instead of scale.x to avoid text flipping)
- Implemented NPCBehavior.cs-equivalent: exclamation scale bounce on click, bubble hidden by default, stop-on-success/continue-on-fail
- Fixed Sanctuary background: removed stray window/chair nodes left by earlier layers; white overlay for clean mockup
- Replaced Recipe panel background with Foldingpaper.png (NinePatchRect)
- Fixed go-to-Sanctuary button scene path typo (was loading LivingRoom.tscn instead)

### Iteration V7 — UI Polish Pass
- Baby sprites: implemented Image.new().load() pattern to bypass missing .import files
- Fixed cursor resize: switched from load() to Image.new().load() with INTERPOLATE_LANCZOS
- Moved drawer grid to horizontal center of Sanctuary, clear of prep station
- Aligned backpack panel bottom edge to match Go-to-LivingRoom button bottom edge
- Extended Foldingpaper.png to fully cover recipe text area (NinePatchRect patch margins tuned)
- Deleted stale placeholder labels: "The Sanctuary", "Chi: 0%", "3:00" from both scene tops
- Added NPC walk mark.png exclamation icon (replaced text "!" character)

### Iteration V8 — Chi System Redesign + Three Endings
- Redesigned Chi economy: start=20, NPC order +10, Baby silence +40, drain=2/sec, Baby wakes every 60s fixed
- Added EndType enum (PERFECT / FAIL / NORMAL) with three distinct full-screen endings
- PERFECT (chi=100): gold color scheme, instant trigger on reaching 100
- FAIL (chi=0): deep red color scheme, instant trigger on hitting zero
- NORMAL (timer expires): deep blue color scheme, result depends on final chi
- Rebuilt GameOver.tscn to match: separate color backgrounds, stats row, Kingstone title font
- Added Arcane Rune as Baby Seal intermediate product (3-step chain: Obsidian + Crystal → Heart)
- Added two new deliverable recipes: Magic Dust (Candle+Book) and Spirit Water (Water+Scroll)
- Added NPC per-order counter (max 3 orders per NPC)
- Replaced Mom/Dad sprites with Forest Pack and Castle Pack character sheets
- Added scene-switch arrow buttons (◀ left-center, ▶ right-center) replacing text buttons
- Aligned PrepStation, RecipePanel, and Backpack bottom edges

### Iteration V9 — Full Audio System
- Built AudioManager.gd as autoload; manages 4 audio streams
- BGM.mp3: set AudioStreamMP3.loop=true for continuous playback; fallback finished signal replay
- Baby Siren.wav: triggered on baby_woke signal, stopped on baby_silenced signal
- Click.wav: wired to inventory slot selection, scene transitions, exclamation clicks
- Deliver.wav: wired to successful NPC drop and Baby seal delivery
- Added 🎵 BGM toggle and 🔊 SFX toggle buttons to HUD right section
- Verified all audio layers stack correctly (BGM + Siren play simultaneously without conflict)

### Iteration V10 — NPC Sprites + HTP Close Fix
- Replaced NPC placeholder sprites with 1.png / 2.png / 3.png / 4.png (character pack assets)
- Applied Image.new().load() pattern for NPC textures (bypasses .import requirement)
- Fixed HTP (How to Play) close button: root cause identified as BackgroundImage mouse_filter=STOP eating all click events; set mouse_filter=IGNORE
- Added z_index=10 to HowToPlayPanel; added move_to_front() call on open

### Iteration V11 — Critical Bug Sweep
- Fixed NPC image display: ran Godot --import to generate .import files for 1/2/3/4.png
- Fixed Baby click navigating to Sanctuary: added get_viewport().set_input_as_handled() to prevent event bubbling through baby_btn to scene-switch button beneath it
- Implemented drag-from-inventory delivery in Living Room: InventoryOverlay now calls scene._start_drag_from_inventory() on slot press
- Implemented _start_drag_from_inventory() in Sanctuary for inventory→slot drag (previously only drawers could be dragged)
- Fixed Chi bar invisible: TextureProgressBar requires texture_under + texture_progress; added dynamic 1×1 pixel ImageTexture creation in _setup_chi_bar()
- Fixed chi_changed signal timing: added call_deferred("_force_initial_update") to ensure HUD reads chi value after GameManager.start_game() completes
- Added debug print statements in deliver_to_npc() to confirm +10 chi award path
- Added _try_deliver_baby() drop zone check in _check_drop_on_npc()

### Iteration V12 — Font System + Ending Polish
- Identified BackgroundImage as persistent HTP close blocker; final fix: replaced Close button signal with _input() click-outside-to-close pattern
- Registered Kingstone font (TTF) as ext_resource in TitleScreen.tscn and GameOver.tscn
- Removed Oblata font references from all scenes; restored default system font for body text
- Aligned title button font sizes: Start Game / How to Play / Quit all set to 24px
- Rebuilt GameOver.tscn with three visually distinct ending layouts (color bg, icon, Kingstone title, stats)
- Fixed Rules panel close: same click-outside-to-close pattern applied to HUD RulesPanel

### Iteration V13 — Item Rename + Chi Bar Visual + Drag Ghost
- Renamed all crafted items: talisman→Eye, elixir→Egg, grimoire_seal→Pearl, magic_dust→Key, spirit_water→Apple, ink→Obsidian, arcane_rune→Crystal, master_seal→Heart
- Updated all item dictionary keys throughout GameManager, Sanctuary, LivingRoom, InventoryOverlay
- Updated recipe display text in Sanctuary to match new names
- Replaced item textures: Eye/Egg/Pearl/Key/Apple/Obsidian/Heart all load from assets/sprites/items/
- Chi bar: _get_chi_color() now always returns red (removed green/yellow progression)
- Crystal icon: _update_crystal_icon() always shows Cristalred.png (removed color switching)
- Implemented backpack drag ghost: slot dims on pick-up, full-opacity ghost follows cursor
- Added SPACE key global pause via HUD._unhandled_input()
- Added Baby "Get me Seal!" speech bubble on click while awake (later removed per request)

### Iteration V14 — Drag Simplification + Bug Fixes
- Removed Baby speech bubble (per feedback: unnecessary)
- Fixed Crystal icon: set to static left position (removed sliding animation)
- Replaced icon.svg: yin-yang removed, new gold star + pink gem on dark purple background
- Ran Godot --import to generate .import files for all new item PNGs (Eye/Egg/Pearl/Key/Apple/Obsidian/Heart)
- Renamed "Red Potion" ingredient to "Potion"
- Simplified NPC delivery: removed exclamation click requirement; drag directly onto NPC to deliver at any time
- Added Baby drop zone: drag Heart Seal directly onto Baby to silence (no click required)
- Confirmed all drag flows work end-to-end

### Iteration V15 — BGM Loop + Baby Position + Drag Visual
- Fixed BGM loop: AudioStreamMP3.loop=true set before stream assignment; added finished signal fallback
- Changed backpack drag from ghost-copy to ghost-move: slot icon dims to 30% opacity on drag start, full-opacity ghost at cursor
- Repositioned Baby to screen center (x:540–740, y:330–510) over visible bed graphic
- Simplified Baby UI: removed multi-line status labels, kept only sprite (calm/angry) with minimal indicator
- Replaced NPC exclamation "!" text with mark.png (emotion icon asset, pixel art style)
- Applied click-outside-to-close for both HTP panel and Rules panel
- Added Rules panel to HUD via RulesBtn; click outside or ESC closes
- Added CloseRulesBtn as direct child of RulesPanel (not inside VBox overflow zone)

### Iteration V16 — Button Skins + Final Polish
- Chi bar color locked to red (removed dynamic color cycling that confused players post-Baby-silence)
- Crystal icon locked to Cristalred.png (static, left-anchored)
- Baby repositioned to (595, 208) matching bed coordinates in background image
- Baby click area resized to match sprite dimensions (removed oversized ColorRect)
- Removed stale purple status text from Living Room bottom edge
- PrepStation black frame resized to Slot A bottom edge + 1px
- Recipe scroll (Foldingpaper.png) extended to cover Baby Seal section

