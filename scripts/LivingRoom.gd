extends Control

# =============================================
# LIVING ROOM SCENE  —  Tasks 2, 3, 4, 5, 6
# 4 NPCs: Grandpa, Dad, Mom, Child
# _process-based walking (no tweens for walk)
# Full NPCBehavior: exclamation bounce, stop/resume, 2s reset
# InventoryOverlay loaded manually (not autoload)
# =============================================

# --- Status ---
@onready var status_label: Label         = $StatusLabel

# --- Navigation ---
@onready var go_to_sanctuary_btn: Button = $GoToSanctuaryBtn
@onready var nav_left_btn: Button        = $NavLeftBtn

# --- Grandpa nodes ---
@onready var grandpa_body: Control              = $GrandpaWalkArea/GrandpaBody
@onready var grandpa_exclaim_btn: Button        = $GrandpaWalkArea/GrandpaBody/ExclamationBtn
@onready var grandpa_bubble_panel: Panel        = $GrandpaWalkArea/GrandpaBody/ThoughtBubblePanel
@onready var grandpa_bubble: Label              = $GrandpaWalkArea/GrandpaBody/ThoughtBubblePanel/ThoughtBubble
@onready var grandpa_btn: Button                = $GrandpaWalkArea/GrandpaBody/GrandpaBtn
@onready var grandpa_emotion: TextureRect       = $GrandpaWalkArea/GrandpaBody/EmotionIcon
@onready var grandpa_bubble_timer: Timer        = $GrandpaWalkArea/GrandpaBubbleTimer
@onready var grandpa_sprite: TextureRect        = $GrandpaWalkArea/GrandpaBody/GrandpaSprite

# --- Dad nodes ---
@onready var dad_body: Control                  = $DadWalkArea/DadBody
@onready var dad_exclaim_btn: Button            = $DadWalkArea/DadBody/ExclamationBtn
@onready var dad_bubble_panel: Panel            = $DadWalkArea/DadBody/ThoughtBubblePanel
@onready var dad_bubble: Label                  = $DadWalkArea/DadBody/ThoughtBubblePanel/ThoughtBubble
@onready var dad_btn: Button                    = $DadWalkArea/DadBody/DadBtn
@onready var dad_emotion: TextureRect           = $DadWalkArea/DadBody/EmotionIcon
@onready var dad_bubble_timer: Timer            = $DadWalkArea/DadBubbleTimer
@onready var dad_sprite: TextureRect            = $DadWalkArea/DadBody/DadSprite

# --- Mom nodes ---
@onready var mom_body: Control                  = $MomWalkArea/MomBody
@onready var mom_exclaim_btn: Button            = $MomWalkArea/MomBody/ExclamationBtn
@onready var mom_bubble_panel: Panel            = $MomWalkArea/MomBody/ThoughtBubblePanel
@onready var mom_bubble: Label                  = $MomWalkArea/MomBody/ThoughtBubblePanel/ThoughtBubble
@onready var mom_btn: Button                    = $MomWalkArea/MomBody/MomBtn
@onready var mom_emotion: TextureRect           = $MomWalkArea/MomBody/EmotionIcon
@onready var mom_bubble_timer: Timer            = $MomWalkArea/MomBubbleTimer
@onready var mom_sprite: TextureRect            = $MomWalkArea/MomBody/MomSprite

# --- Child nodes ---
@onready var child_body: Control                = $ChildWalkArea/ChildBody
@onready var child_exclaim_btn: Button          = $ChildWalkArea/ChildBody/ExclamationBtn
@onready var child_bubble_panel: Panel          = $ChildWalkArea/ChildBody/ThoughtBubblePanel
@onready var child_bubble: Label                = $ChildWalkArea/ChildBody/ThoughtBubblePanel/ThoughtBubble
@onready var child_btn: Button                  = $ChildWalkArea/ChildBody/ChildBtn
@onready var child_emotion: TextureRect         = $ChildWalkArea/ChildBody/EmotionIcon
@onready var child_bubble_timer: Timer          = $ChildWalkArea/ChildBubbleTimer
@onready var child_sprite: TextureRect          = $ChildWalkArea/ChildBody/ChildSprite

# --- Baby ---
@onready var baby_area: VBoxContainer           = $BabyArea
@onready var baby_btn: Button                   = $BabyArea/BabyBtn
@onready var baby_sprite: TextureRect           = $BabyArea/BabyBtn/BabySprite
@onready var baby_face_label: Label             = $BabyArea/BabyBtn/BabyFaceLabel
@onready var baby_btn_label: Label              = $BabyArea/BabyBtn/BabyBtnLabel
@onready var baby_alert_label: Label            = $BabyArea/BabyAlertLabel
@onready var baby_status_label: Label           = $BabyArea/BabyStatusLabel

# --- Transition ---
@onready var transition_overlay: ColorRect      = $TransitionOverlay

# --- Internal State ---
var _status_clear_tween: Tween = null

# --- Task 3: Drag-and-Drop Delivery State ---
var _drag_active: bool = false
var _drag_item: String = ""
var _drag_icon: TextureRect = null

# ---------------------------------------------------------------
# _process-based NPC walk configs.
# Each entry holds the mutable walk state for one NPC.
# Keys:
#   body      : Control      — the NPC body node
#   sprite    : TextureRect  — the NPC sprite (used for flip_h instead of scale)
#   start_x   : float        — centre of the patrol range
#   range     : float        — half-width of patrol (walks ± range from start_x)
#   speed     : float        — current movement speed (set to 0 to pause)
#   base_speed: float        — default speed to restore after stopping
#   dir       : int          — 1 = moving right, -1 = moving left
#   is_solved : bool         — true while waiting for 2-s request regeneration
# ---------------------------------------------------------------
var npc_configs: Array = []


func _ready() -> void:
	# Load InventoryOverlay manually so it never appears on
	# TitleScreen or GameOver (which don't call this _ready).
	var inv_overlay: Node = preload("res://scenes/InventoryOverlay.tscn").instantiate()
	add_child(inv_overlay)

	_setup_npcs()
	_setup_baby()

	nav_left_btn.pressed.connect(_go_to_sanctuary)
	# Task 1 — Button background texture
	_apply_button_texture(nav_left_btn, "res://assets/backgrounds/direction.png")
	GameManager.baby_woke.connect(_on_baby_woke)
	GameManager.baby_silenced.connect(_on_baby_silenced)
	GameManager.game_over.connect(_on_game_over)

	# Web-compatible cursor: use load() + get_image()
	var _cb = load("res://assets/cursors/Cursor_Hand.png")
	if _cb:
		var _ci: Image = _cb.get_image()
		_ci.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(_ci), Input.CURSOR_ARROW, Vector2(4, 0))

	transition_overlay.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.4)

	_update_thought_bubbles()
	_show_status("Deliver items to the NPCs!")

	if GameManager.is_baby_awake:
		_on_baby_woke()

	# Build walk configs after onready vars are valid.
	# sprite key is used for flip_h to avoid mirroring child Labels.
	# start_x values are relative to each WalkArea, spreading NPCs across 1280px screen.
	# GrandpaWalkArea starts at x=0, DadWalkArea at x=220, MomWalkArea at x=440, ChildWalkArea at x=660.
	# Body offset within each area is 80-100px, so effective screen positions are well spread.
	npc_configs = [
		{"body": grandpa_body, "sprite": grandpa_sprite, "start_x": 180.0, "range": 100.0, "base_speed": 40.0, "speed": 40.0, "dir": 1,  "is_solved": false},
		{"body": dad_body,     "sprite": dad_sprite,     "start_x": 180.0, "range": 100.0, "base_speed": 45.0, "speed": 45.0, "dir": -1, "is_solved": false},
		{"body": mom_body,     "sprite": mom_sprite,     "start_x": 180.0, "range": 100.0, "base_speed": 42.0, "speed": 42.0, "dir": 1,  "is_solved": false},
		{"body": child_body,   "sprite": child_sprite,   "start_x": 180.0, "range": 100.0, "base_speed": 50.0, "speed": 50.0, "dir": -1, "is_solved": false},
	]


# ---------------------------------------------------------------
# _process-based walk — flip uses sprite flip_h, not body scale.
# ---------------------------------------------------------------
func _process(delta: float) -> void:
	for cfg in npc_configs:
		var body: Control = cfg["body"]
		if not is_instance_valid(body):
			continue
		var spd: float = cfg["speed"]
		if spd == 0.0:
			continue

		var new_x: float = body.position.x + spd * cfg["dir"] * delta
		var start_x: float = cfg["start_x"]
		var rng: float     = cfg["range"]

		if new_x >= start_x + rng:
			cfg["dir"] = -1
			new_x = start_x + rng
			cfg["sprite"].flip_h = true   # facing left
		elif new_x <= start_x - rng:
			cfg["dir"] = 1
			new_x = start_x - rng
			cfg["sprite"].flip_h = false  # facing right

		body.position.x = new_x


# ---------------------------------------------------------------
# NPC Setup
# ---------------------------------------------------------------
func _setup_npcs() -> void:
	grandpa_btn.pressed.connect(_on_grandpa_clicked)
	dad_btn.pressed.connect(_on_dad_clicked)
	mom_btn.pressed.connect(_on_mom_clicked)
	child_btn.pressed.connect(_on_child_clicked)

	grandpa_exclaim_btn.pressed.connect(_on_grandpa_exclaim_clicked)
	dad_exclaim_btn.pressed.connect(_on_dad_exclaim_clicked)
	mom_exclaim_btn.pressed.connect(_on_mom_exclaim_clicked)
	child_exclaim_btn.pressed.connect(_on_child_exclaim_clicked)

	grandpa_bubble_timer.timeout.connect(_hide_grandpa_bubble)
	dad_bubble_timer.timeout.connect(_hide_dad_bubble)
	mom_bubble_timer.timeout.connect(_hide_mom_bubble)
	child_bubble_timer.timeout.connect(_hide_child_bubble)

	# Scale NPC bodies to 1.5x (Task 6)
	grandpa_body.scale = Vector2(1.5, 1.5)
	dad_body.scale     = Vector2(1.5, 1.5)
	mom_body.scale     = Vector2(1.5, 1.5)
	child_body.scale   = Vector2(1.5, 1.5)

	# Load NPC sprites (Task 1) — use Image.new().load() to bypass .import requirement.
	var t1 := _load_npc_texture("res://assets/sprites/characters/1.png")
	if t1: grandpa_sprite.texture = t1
	var t2 := _load_npc_texture("res://assets/sprites/characters/2.png")
	if t2: dad_sprite.texture = t2
	var t3 := _load_npc_texture("res://assets/sprites/characters/3.png")
	if t3: mom_sprite.texture = t3
	var t4 := _load_npc_texture("res://assets/sprites/characters/4.png")
	if t4: child_sprite.texture = t4

	# Ensure correct stretch/expand modes on each NPC sprite.
	grandpa_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	grandpa_sprite.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	dad_sprite.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dad_sprite.expand_mode      = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	mom_sprite.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mom_sprite.expand_mode      = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	child_sprite.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	child_sprite.expand_mode    = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

	# Initial state — exclamation visible, bubble hidden, emotion hidden.
	grandpa_bubble_panel.visible = false
	dad_bubble_panel.visible = false
	mom_bubble_panel.visible = false
	child_bubble_panel.visible = false

	grandpa_exclaim_btn.visible = true
	dad_exclaim_btn.visible = true
	mom_exclaim_btn.visible = true
	child_exclaim_btn.visible = true

	grandpa_emotion.visible = false
	grandpa_emotion.texture = load("res://assets/sprites/emotion_icons/emotion_icons.png")
	grandpa_emotion.use_parent_material = false
	dad_emotion.visible = false
	dad_emotion.texture = load("res://assets/sprites/emotion_icons/emotion_icons.png")
	dad_emotion.use_parent_material = false
	mom_emotion.visible = false
	mom_emotion.texture = load("res://assets/sprites/emotion_icons/emotion_icons.png")
	mom_emotion.use_parent_material = false
	child_emotion.visible = false
	child_emotion.texture = load("res://assets/sprites/emotion_icons/emotion_icons.png")
	child_emotion.use_parent_material = false

	# Task 4 — Replace "!" text with mark.png texture on all exclamation buttons.
	for exclaim_btn: Button in [grandpa_exclaim_btn, dad_exclaim_btn, mom_exclaim_btn, child_exclaim_btn]:
		exclaim_btn.text = ""
		var mark_tex := TextureRect.new()
		mark_tex.texture = load("res://assets/sprites/emotion_icons/mark.png")
		mark_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mark_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		exclaim_btn.add_child(mark_tex)


func _setup_baby() -> void:
	baby_btn.pressed.connect(_on_baby_clicked)
	# Task 4 — baby button and sprite sizing
	baby_btn.custom_minimum_size = Vector2(120, 120)
	baby_sprite.custom_minimum_size = Vector2(120, 120)
	baby_area.visible = true
	# Task 2: ensure baby button renders above GoToSanctuaryBtn and captures input first.
	baby_btn.z_index = 5
	# Task 4 — hide extra labels and BabyColorBlock
	if is_instance_valid(baby_alert_label):
		baby_alert_label.text = ""
		baby_alert_label.visible = false
	if is_instance_valid(baby_status_label):
		baby_status_label.text = ""
		baby_status_label.visible = false
	var color_block: ColorRect = baby_btn.get_node_or_null("BabyColorBlock") as ColorRect
	if color_block != null:
		color_block.visible = false
	if GameManager.is_baby_awake:
		_apply_baby_awake_visuals()
	else:
		_apply_baby_sleep_visuals()


# ---------------------------------------------------------------
# Helper: get the walk-config dict for a given NPC name.
# ---------------------------------------------------------------
func _get_npc_cfg(npc_name: String) -> Dictionary:
	match npc_name:
		"grandpa": return npc_configs[0]
		"dad":     return npc_configs[1]
		"mom":     return npc_configs[2]
		"child":   return npc_configs[3]
	return {}


# ---------------------------------------------------------------
# Exclamation click handlers
# — scale bounce, stop walking, show request bubble.
# ---------------------------------------------------------------
func _on_grandpa_exclaim_clicked() -> void:
	_handle_exclaim_click("grandpa", grandpa_exclaim_btn, grandpa_bubble_panel, grandpa_bubble_timer)

func _on_dad_exclaim_clicked() -> void:
	_handle_exclaim_click("dad", dad_exclaim_btn, dad_bubble_panel, dad_bubble_timer)

func _on_mom_exclaim_clicked() -> void:
	_handle_exclaim_click("mom", mom_exclaim_btn, mom_bubble_panel, mom_bubble_timer)

func _on_child_exclaim_clicked() -> void:
	_handle_exclaim_click("child", child_exclaim_btn, child_bubble_panel, child_bubble_timer)


func _handle_exclaim_click(npc_name: String, exclaim_btn: Button, bubble_panel: Panel, bubble_timer: Timer) -> void:
	AudioManager.play_click()
	# Bounce animation on the exclamation button.
	exclaim_btn.pivot_offset = exclaim_btn.size * 0.5
	var t: Tween = create_tween()
	t.tween_property(exclaim_btn, "scale", Vector2(0.8, 0.8), 0.1)
	t.tween_property(exclaim_btn, "scale", Vector2(1.0, 1.0), 0.1)

	# Stop the NPC walking while bubble is shown.
	var cfg: Dictionary = _get_npc_cfg(npc_name)
	if not cfg.is_empty():
		cfg["speed"] = 0.0

	# Show the request bubble.
	_update_thought_bubbles()
	bubble_panel.visible = true
	bubble_timer.start()


func _hide_grandpa_bubble() -> void:
	grandpa_bubble_panel.visible = false
	# Resume walking only if not in solved state.
	var cfg: Dictionary = _get_npc_cfg("grandpa")
	if not cfg.is_empty() and not cfg["is_solved"]:
		cfg["speed"] = cfg["base_speed"]


func _hide_dad_bubble() -> void:
	dad_bubble_panel.visible = false
	var cfg: Dictionary = _get_npc_cfg("dad")
	if not cfg.is_empty() and not cfg["is_solved"]:
		cfg["speed"] = cfg["base_speed"]


func _hide_mom_bubble() -> void:
	mom_bubble_panel.visible = false
	var cfg: Dictionary = _get_npc_cfg("mom")
	if not cfg.is_empty() and not cfg["is_solved"]:
		cfg["speed"] = cfg["base_speed"]


func _hide_child_bubble() -> void:
	child_bubble_panel.visible = false
	var cfg: Dictionary = _get_npc_cfg("child")
	if not cfg.is_empty() and not cfg["is_solved"]:
		cfg["speed"] = cfg["base_speed"]


func _update_thought_bubbles() -> void:
	var grandpa_req: String = GameManager.npc_requests.get("grandpa", "")
	var dad_req: String     = GameManager.npc_requests.get("dad", "")
	var mom_req: String     = GameManager.npc_requests.get("mom", "")
	var child_req: String   = GameManager.npc_requests.get("child", "")

	grandpa_bubble.text = "Wants:\n" + GameManager.get_item_display_name(grandpa_req)
	dad_bubble.text     = "Wants:\n" + GameManager.get_item_display_name(dad_req)
	mom_bubble.text     = "Wants:\n" + GameManager.get_item_display_name(mom_req)
	child_bubble.text   = "Wants:\n" + GameManager.get_item_display_name(child_req)


# ---------------------------------------------------------------
# NPC body click handlers
# ---------------------------------------------------------------
func _on_grandpa_clicked() -> void:
	GameManager.apply_click_bounce(grandpa_btn)
	_try_deliver("grandpa", grandpa_btn, grandpa_exclaim_btn, grandpa_bubble_panel, grandpa_emotion)


func _on_dad_clicked() -> void:
	GameManager.apply_click_bounce(dad_btn)
	_try_deliver("dad", dad_btn, dad_exclaim_btn, dad_bubble_panel, dad_emotion)


func _on_mom_clicked() -> void:
	GameManager.apply_click_bounce(mom_btn)
	_try_deliver("mom", mom_btn, mom_exclaim_btn, mom_bubble_panel, mom_emotion)


func _on_child_clicked() -> void:
	GameManager.apply_click_bounce(child_btn)
	_try_deliver("child", child_btn, child_exclaim_btn, child_bubble_panel, child_emotion)


# ---------------------------------------------------------------
# Delivery with full NPCBehavior reactions.
# ---------------------------------------------------------------
func _try_deliver(
		npc_name: String,
		npc_button: Button,
		exclaim_btn: Button,
		bubble_panel: Panel,
		emotion_icon: TextureRect) -> void:

	var held: String = GameManager.get_selected_item()
	if held == "":
		_show_status("You're not holding anything!")
		return

	var cfg: Dictionary = _get_npc_cfg(npc_name)
	var success: bool = GameManager.deliver_to_npc(npc_name, held)

	if success:
		AudioManager.play_deliver()
		_show_status("Delivered! +10 Chi!", Color.GREEN)
		_flash_npc_success(npc_button)

		# Hide bubble and exclamation, stop walking, show happy emotion.
		bubble_panel.visible = false
		exclaim_btn.visible = false
		if not cfg.is_empty():
			cfg["speed"] = 0.0
			cfg["is_solved"] = true

		_show_emotion(emotion_icon, true)

		# After 2 seconds: check if NPC still has requests, show exclamation, resume walking.
		var reset_timer: SceneTreeTimer = get_tree().create_timer(2.0)
		reset_timer.timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			_update_thought_bubbles()
			# Only show exclamation if this NPC still has requests
			var req: String = GameManager.npc_requests.get(npc_name, "")
			if req != "":
				exclaim_btn.visible = true
			if not cfg.is_empty():
				cfg["is_solved"] = false
				cfg["speed"] = cfg["base_speed"]
		)
	else:
		var requested: String = GameManager.npc_requests[npc_name]
		_show_status("Wrong item! They want: " + GameManager.get_item_display_name(requested), Color.RED)
		_flash_npc_fail(npc_button)
		_shake_npc(npc_button)
		if not cfg.is_empty():
			_shake_npc(cfg["body"])

		# Hide exclamation temporarily, show sad emotion, keep walking.
		exclaim_btn.visible = false
		bubble_panel.visible = false
		_show_emotion(emotion_icon, false)

		# After 2 seconds: show exclamation again.
		var sad_timer: SceneTreeTimer = get_tree().create_timer(2.0)
		sad_timer.timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			exclaim_btn.visible = true
		)


# Emotion spritesheet: 128x96, 8 columns x 6 rows, each cell 16x16
# happy  = row 0, col 0  => Rect2(0,  0,  16, 16)
# sad    = row 2, col 0  => Rect2(0,  32, 16, 16)
func _show_emotion(icon: TextureRect, happy: bool) -> void:
	if happy:
		icon.region_rect = Rect2(0, 0, 16, 16)
	else:
		icon.region_rect = Rect2(0, 32, 16, 16)
	icon.modulate = Color.WHITE
	icon.visible = true
	var t: Tween = create_tween()
	icon.pivot_offset = icon.size * 0.5
	t.tween_property(icon, "scale", Vector2(1.3, 1.3), 0.1)
	t.tween_property(icon, "scale", Vector2(1.0, 1.0), 0.15)
	t.tween_property(icon, "modulate:a", 0.0, 0.4).set_delay(1.1)
	t.tween_callback(func() -> void:
		icon.visible = false
		icon.modulate = Color.WHITE
		icon.scale = Vector2(1.0, 1.0)
	)


func _on_baby_clicked() -> void:
	# Task 2: consume input so it does not fall through to GoToSanctuaryBtn.
	get_viewport().set_input_as_handled()
	AudioManager.play_click()
	GameManager.apply_click_bounce(baby_btn)
	if not GameManager.is_baby_awake:
		return

	var held: String = GameManager.get_selected_item()
	if held == "heart":
		var success: bool = GameManager.deliver_baby_seal(held)
		if success:
			AudioManager.play_deliver()
			_show_status("Baby silenced! +40 Chi! Crisis over!", Color.GREEN)
	elif held == "":
		_show_status("Go to Sanctuary! Craft Heart (Obsidian+Crystal)", Color.YELLOW)
	else:
		_show_status("Need the Heart Seal to silence baby!", Color.ORANGE)


# Task 5 — Baby PNG fix using Image.new().load()
func _apply_baby_sleep_visuals() -> void:
	baby_btn.disabled = false
	baby_btn.modulate = Color.WHITE
	var calm_img: Image = Image.new()
	var err: int = calm_img.load("res://assets/characters/baby_calm.png")
	if err == OK:
		baby_sprite.texture = ImageTexture.create_from_image(calm_img)
	if is_instance_valid(baby_btn_label):
		baby_btn_label.text = "Sleeping zzz"
		baby_btn_label.modulate = Color(0.7, 0.7, 0.9, 1.0)
	baby_alert_label.text = ""
	baby_status_label.text = ""
	baby_area.modulate = Color.WHITE
	baby_btn.scale = Vector2(1.0, 1.0)


func _apply_baby_awake_visuals() -> void:
	baby_btn.disabled = false
	var angry_img: Image = Image.new()
	var err: int = angry_img.load("res://assets/characters/baby_angry.png")
	if err == OK:
		baby_sprite.texture = ImageTexture.create_from_image(angry_img)
	if is_instance_valid(baby_btn_label):
		baby_btn_label.text = "AWAKE!"
		baby_btn_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	baby_alert_label.text = ""
	baby_status_label.text = ""
	baby_btn.modulate = Color(1.0, 0.4, 0.4, 1.0)
	_flash_baby_red()


func _flash_baby_red() -> void:
	if not is_instance_valid(baby_btn):
		return
	var tween: Tween = create_tween()
	tween.tween_property(baby_btn, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.15)
	tween.tween_property(baby_btn, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.15)
	tween.tween_property(baby_btn, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.15)
	tween.tween_property(baby_btn, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.15)
	tween.tween_property(baby_btn, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.15)
	tween.tween_property(baby_btn, "modulate", Color(1.0, 0.4, 0.4, 1.0), 0.15)


func _baby_wake_tween() -> void:
	baby_btn.pivot_offset = baby_btn.size * 0.5
	baby_btn.scale = Vector2(1.0, 1.0)
	var t: Tween = create_tween()
	t.tween_property(baby_btn, "scale", Vector2(1.3, 1.3), 0.25).set_ease(Tween.EASE_OUT)
	t.tween_property(baby_btn, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_IN)
	t.tween_callback(func() -> void: _shake_npc(baby_btn))


func _on_baby_woke() -> void:
	_apply_baby_awake_visuals()
	_baby_wake_tween()
	_show_status("DEMON BABY WOKE UP! Craft the Heart Seal!", Color.RED)


func _on_baby_silenced() -> void:
	_apply_baby_sleep_visuals()
	_show_status("Baby silenced! Keep delivering!", Color.GREEN)


func _flash_npc_success(btn: Button) -> void:
	var original_mod: Color = btn.modulate
	var tween := create_tween()
	tween.tween_property(btn, "modulate", Color(0.4, 1.0, 0.4), 0.08)
	tween.tween_property(btn, "modulate", original_mod, 0.3)


func _flash_npc_fail(btn: Button) -> void:
	var original_mod: Color = btn.modulate
	var tween := create_tween()
	tween.tween_property(btn, "modulate", Color(1.0, 0.25, 0.25), 0.08)
	tween.tween_property(btn, "modulate", original_mod, 0.35)


func _shake_npc(btn: Control) -> void:
	var orig_pos: float = btn.position.x
	var tween := create_tween()
	tween.tween_property(btn, "position:x", orig_pos + 8.0, 0.04)
	tween.tween_property(btn, "position:x", orig_pos - 8.0, 0.04)
	tween.tween_property(btn, "position:x", orig_pos + 4.0, 0.04)
	tween.tween_property(btn, "position:x", orig_pos, 0.04)


func _show_status(msg: String, color: Color = Color.WHITE) -> void:
	status_label.text = msg
	status_label.modulate = color
	status_label.modulate.a = 1.0
	if _status_clear_tween:
		_status_clear_tween.kill()
	_status_clear_tween = create_tween()
	_status_clear_tween.tween_property(status_label, "modulate:a", 0.0, 0.5).set_delay(2.5)
	_status_clear_tween.tween_callback(func() -> void:
		status_label.text = ""
		status_label.modulate.a = 1.0
	)


# ---------------------------------------------------------------
# Task 1: _apply_button_texture — adds TextureRect background to a Button.
# ---------------------------------------------------------------
func _apply_button_texture(btn: Button, tex_path: String) -> void:
	var tex_rect := TextureRect.new()
	var img := Image.new()
	if img.load(tex_path) == OK:
		tex_rect.texture = ImageTexture.create_from_image(img)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
	tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.z_index = -1
	btn.add_child(tex_rect)
	btn.move_child(tex_rect, 0)


# ---------------------------------------------------------------
# Task 1: Image.new().load() helper — bypasses .import requirement.
# ---------------------------------------------------------------
func _load_npc_texture(path: String) -> ImageTexture:
	var img := Image.new()
	var err := img.load(path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	push_warning("NPC texture not found: " + path)
	return null


# ---------------------------------------------------------------
# Task 3: Drag-and-Drop Delivery from Inventory
# ---------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if not _drag_active:
		return
	if event is InputEventMouseMotion:
		if _drag_icon != null and is_instance_valid(_drag_icon):
			_drag_icon.global_position = get_global_mouse_position() - _drag_icon.size * 0.5
	elif event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and not mbe.pressed:
			_check_drop_on_npc(get_global_mouse_position())
			_end_drag()


func _start_drag_from_inventory(item_name: String) -> void:
	if _drag_active:
		return
	_drag_active = true
	_drag_item = item_name

	# Create a floating icon parented to this scene.
	var icon := TextureRect.new()
	icon.size = Vector2(64.0, 64.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 100
	var tex_path: String = GameManager.get_item_texture_path(item_name)
	if tex_path != "":
		icon.texture = load(tex_path)
	add_child(icon)
	_drag_icon = icon
	_drag_icon.global_position = get_global_mouse_position() - icon.size * 0.5
	_show_status("Drag to an NPC to deliver!", Color.YELLOW)


func _check_drop_on_npc(pos: Vector2) -> void:
	# Use the NPC body rect (includes sprite + child nodes) grown by 20px.
	# This means dragging onto any visible part of an NPC triggers delivery —
	# no exclamation click required first.
	var npc_map: Array = [
		{"name": "grandpa", "body": grandpa_body, "btn": grandpa_btn, "exclaim": grandpa_exclaim_btn, "bubble": grandpa_bubble_panel, "emotion": grandpa_emotion},
		{"name": "dad",     "body": dad_body,     "btn": dad_btn,     "exclaim": dad_exclaim_btn,     "bubble": dad_bubble_panel,     "emotion": dad_emotion},
		{"name": "mom",     "body": mom_body,     "btn": mom_btn,     "exclaim": mom_exclaim_btn,     "bubble": mom_bubble_panel,     "emotion": mom_emotion},
		{"name": "child",   "body": child_body,   "btn": child_btn,   "exclaim": child_exclaim_btn,   "bubble": child_bubble_panel,   "emotion": child_emotion},
	]
	for entry: Dictionary in npc_map:
		var body: Control = entry["body"] as Control
		if not is_instance_valid(body):
			continue
		var rect: Rect2 = body.get_global_rect().grow(20.0)
		if rect.has_point(pos):
			_try_deliver(
				entry["name"] as String,
				entry["btn"] as Button,
				entry["exclaim"] as Button,
				entry["bubble"] as Panel,
				entry["emotion"] as TextureRect
			)
			return

	# Baby drop zone — only active when baby is awake.
	if GameManager.is_baby_awake:
		if is_instance_valid(baby_btn):
			var baby_rect: Rect2 = baby_btn.get_global_rect().grow(30.0)
			if baby_rect.has_point(pos):
				_try_deliver_baby()
				return

	_show_status("Missed! Drag onto an NPC to deliver.", Color.ORANGE)


func _try_deliver_baby() -> void:
	var held: String = GameManager.get_selected_item()
	if held == "":
		return
	if held == "heart":
		var success: bool = GameManager.deliver_baby_seal(held)
		if success:
			AudioManager.play_deliver()
			_show_status("Baby silenced! +40 Chi! Crisis over!", Color.GREEN)
	else:
		_show_status("Baby needs the Heart Seal!", Color.ORANGE)


func _end_drag() -> void:
	_drag_active = false
	_drag_item = ""
	if _drag_icon != null and is_instance_valid(_drag_icon):
		_drag_icon.queue_free()
	_drag_icon = null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()


func _on_game_over(_end_type: int) -> void:
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")


func _go_to_sanctuary() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(nav_left_btn)
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 1.0, 0.4)
	tween.tween_callback(func() -> void:
		GameManager.change_room(GameManager.Room.SANCTUARY)
		get_tree().change_scene_to_file("res://scenes/Sanctuary.tscn")
	)
