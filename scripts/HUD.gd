extends CanvasLayer

# =============================================
# HUD — Chi Bar + Timer + HUD Buttons
# Shared by Sanctuary and Living Room via autoload.
# CanvasLayer.layer = 5 (above scene content, below InventoryOverlay at 10)
# process_mode = ALWAYS so the Pause button still functions while paused.
# =============================================

# Chi bar color thresholds (progress tint)
const CHI_COLOR_HIGH: Color = Color(0.2, 0.9, 0.3)    # green  > 60%
const CHI_COLOR_MID:  Color = Color(1.0, 0.85, 0.1)   # yellow 30-60%
const CHI_COLOR_LOW:  Color = Color(0.95, 0.15, 0.15) # red    < 30%

# How fast the blink alpha oscillates when time < 30s
const BLINK_SPEED: float = 4.0

# Crystal texture paths — loaded once in _ready
const CRYSTAL_BLUE_PATH:   String = "res://assets/ui/Stage/Cristalblue.png"
const CRYSTAL_ORANGE_PATH: String = "res://assets/ui/Stage/Cristalorange.png"
const CRYSTAL_RED_PATH:    String = "res://assets/ui/Stage/Cristalred.png"

@onready var chi_bar:           TextureProgressBar = %ChiBar
@onready var crystal_icon:      TextureRect        = %CrystalIcon
@onready var title_label:       Label              = %TitleLabel
@onready var timer_label:       Label              = %TimerLabel
@onready var pause_btn:         Button             = %PauseBtn
@onready var restart_btn:       Button             = %RestartBtn
@onready var quit_btn:          Button             = %QuitBtn
@onready var rules_btn:         Button             = %RulesBtn
@onready var rules_panel:       Panel              = $RulesPanel
@onready var bgm_toggle_btn:    Button             = %BGMToggleBtn
@onready var sfx_toggle_btn:    Button             = %SFXToggleBtn
@onready var delivery_label:    Label              = %DeliveryLabel
@onready var star_preview_label: Label             = %StarPreviewLabel
@onready var paused_label:      Label              = %PausedLabel

var _tex_crystal_blue:   Texture2D = null
var _tex_crystal_orange: Texture2D = null
var _tex_crystal_red:    Texture2D = null

var _blink_tween: Tween = null
var _blinking: bool = false

# Crisis chi flash state (driven by GameManager.baby_woke / baby_silenced)
var _chi_flash_tween: Tween = null
var _chi_flash_active: bool = false

# Pause state label texts
const PAUSE_TEXT:  String = "||"
const RESUME_TEXT: String = ">"


func _ready() -> void:
	# HUD must process even when the tree is paused so the pause button works
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Pre-load crystal textures
	_tex_crystal_blue   = load(CRYSTAL_BLUE_PATH)   as Texture2D
	_tex_crystal_orange = load(CRYSTAL_ORANGE_PATH) as Texture2D
	_tex_crystal_red    = load(CRYSTAL_RED_PATH)    as Texture2D

	# Connect HUD button signals
	pause_btn.pressed.connect(_on_pause_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	rules_btn.pressed.connect(_on_rules_pressed)
	bgm_toggle_btn.pressed.connect(_on_bgm_toggle)
	sfx_toggle_btn.pressed.connect(_on_sfx_toggle)

	# Task 1 — Button background textures for all HUD buttons
	for _hud_btn: Button in [pause_btn, restart_btn, rules_btn, bgm_toggle_btn, sfx_toggle_btn, quit_btn]:
		_apply_button_texture(_hud_btn, "res://assets/backgrounds/Botton.png")

	# Connect to GameManager signals
	GameManager.chi_changed.connect(_on_chi_changed)
	GameManager.timer_updated.connect(_on_timer_updated)
	GameManager.baby_woke.connect(_on_baby_woke)
	GameManager.baby_silenced.connect(_on_baby_silenced)
	GameManager.delivery_scored.connect(_on_delivery_scored)

	# Setup chi bar textures so it renders even without an atlas
	_setup_chi_bar()

	# Sync immediately to current state
	_on_chi_changed(GameManager.chi_value, GameManager.chi_max)
	_on_timer_updated(GameManager.time_remaining)
	_update_score_display(GameManager.delivery_count, GameManager.calculate_stars())
	# Deferred update in case GameManager hasn't finished start_game yet
	call_deferred("_force_initial_update")

	# If game starts mid-crisis (e.g. scene reload), restore crisis visuals
	if GameManager.is_baby_awake:
		_on_baby_woke()


# ---------------------------------------------------------------------------
# Space Key Pause (Task 5)
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_on_pause_pressed()


# ---------------------------------------------------------------------------
# HUD Buttons
# ---------------------------------------------------------------------------

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


func _on_pause_pressed() -> void:
	var is_paused: bool = !get_tree().paused
	get_tree().paused = is_paused
	pause_btn.text = RESUME_TEXT if is_paused else PAUSE_TEXT
	if paused_label:
		paused_label.get_parent().visible = is_paused


func _on_restart_pressed() -> void:
	# Unpause before restart in case we were paused
	get_tree().paused = false
	pause_btn.text = PAUSE_TEXT
	if paused_label:
		paused_label.get_parent().visible = false
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/Sanctuary.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_rules_pressed() -> void:
	rules_panel.visible = true
	rules_panel.move_to_front()


# Nuclear close: ANY click anywhere (inside or outside panel) closes it.
# ESC and SPACE also close it. No close button needed.
func _input(event: InputEvent) -> void:
	if rules_panel != null and rules_panel.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			rules_panel.visible = false
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE:
				rules_panel.visible = false
				get_viewport().set_input_as_handled()
				return


func _on_bgm_toggle() -> void:
	AudioManager.toggle_bgm()
	GameManager.apply_click_bounce(bgm_toggle_btn)
	bgm_toggle_btn.text = "BGM" if AudioManager.bgm_enabled else "X"


func _on_sfx_toggle() -> void:
	AudioManager.toggle_sfx()
	GameManager.apply_click_bounce(sfx_toggle_btn)
	sfx_toggle_btn.text = "SFX" if AudioManager.sfx_enabled else "OFF"


# ---------------------------------------------------------------------------
# Chi Bar + Crystal Icon
# ---------------------------------------------------------------------------

func _on_chi_changed(value: float, max_val: float) -> void:
	var pct: float = value / max_val if max_val > 0.0 else 0.0
	chi_bar.value = pct * 100.0

	# Dynamic fill color via tint_progress
	var chi_color: Color = _get_chi_color(pct)
	chi_bar.tint_progress = chi_color

	# Crystal icon switches color based on chi level; position is fixed.
	_update_crystal_icon(pct)


func _get_chi_color(_pct: float) -> Color:
	return Color(0.9, 0.15, 0.15, 1.0)


func _update_crystal_icon(_pct: float) -> void:
	if _tex_crystal_red:
		crystal_icon.texture = _tex_crystal_red


func _setup_chi_bar() -> void:
	var under_img: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	under_img.fill(Color(0.15, 0.08, 0.08, 0.9))
	chi_bar.texture_under = ImageTexture.create_from_image(under_img)

	var progress_img: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	progress_img.fill(Color(0.9, 0.15, 0.1, 1.0))
	chi_bar.texture_progress = ImageTexture.create_from_image(progress_img)

	chi_bar.min_value = 0.0
	chi_bar.max_value = 100.0
	chi_bar.value = GameManager.chi_value


func _force_initial_update() -> void:
	_on_chi_changed(GameManager.chi_value, GameManager.chi_max)
	_on_timer_updated(GameManager.time_remaining)


# Flash chi bar during crisis (baby awake)
func _on_baby_woke() -> void:
	_chi_flash_active = true
	_run_chi_flash()


func _run_chi_flash() -> void:
	if not _chi_flash_active:
		return
	if _chi_flash_tween:
		_chi_flash_tween.kill()
	_chi_flash_tween = create_tween()
	_chi_flash_tween.tween_property(chi_bar, "tint_progress", Color.RED, 0.25)
	_chi_flash_tween.tween_property(chi_bar, "tint_progress", Color(0.5, 0.0, 0.0), 0.25)
	_chi_flash_tween.tween_callback(func() -> void:
		if _chi_flash_active:
			_run_chi_flash()
	)


func _on_baby_silenced() -> void:
	_chi_flash_active = false
	if _chi_flash_tween:
		_chi_flash_tween.kill()
		_chi_flash_tween = null
	# Restore color based on current chi
	var pct: float = GameManager.chi_value / GameManager.chi_max if GameManager.chi_max > 0.0 else 0.0
	chi_bar.tint_progress = _get_chi_color(pct)
	_update_crystal_icon(pct)


# ---------------------------------------------------------------------------
# Timer Label
# ---------------------------------------------------------------------------

func _on_timer_updated(seconds: float) -> void:
	var total_secs: int = int(max(seconds, 0.0))
	var m: int = total_secs / 60
	var s: int = total_secs % 60
	timer_label.text = "%02d:%02d" % [m, s]

	if seconds < 30.0:
		timer_label.add_theme_color_override("font_color", Color.RED)
		_start_blink()
	elif seconds < 60.0:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
		_stop_blink()
	else:
		timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5))
		_stop_blink()


func _start_blink() -> void:
	if _blinking:
		return
	_blinking = true
	_run_blink()


func _run_blink() -> void:
	if not _blinking:
		return
	if _blink_tween:
		_blink_tween.kill()
	_blink_tween = create_tween()
	_blink_tween.tween_property(timer_label, "modulate:a", 0.25, 0.3)
	_blink_tween.tween_property(timer_label, "modulate:a", 1.0, 0.3)
	_blink_tween.tween_callback(func() -> void:
		if _blinking:
			_run_blink()
	)


func _stop_blink() -> void:
	if not _blinking:
		return
	_blinking = false
	if _blink_tween:
		_blink_tween.kill()
		_blink_tween = null
	timer_label.modulate.a = 1.0


# ---------------------------------------------------------------------------
# Delivery Score Display
# ---------------------------------------------------------------------------

func _on_delivery_scored(count: int, stars_earned: int) -> void:
	_update_score_display(count, stars_earned)
	# Bounce animation on the delivery label
	delivery_label.pivot_offset = delivery_label.size * 0.5
	var t: Tween = create_tween()
	t.tween_property(delivery_label, "scale", Vector2(1.35, 1.35), 0.1)
	t.tween_property(delivery_label, "scale", Vector2(1.0, 1.0), 0.15)


func _update_score_display(count: int, stars_earned: int) -> void:
	delivery_label.text = "Delivered: %d" % count
	match stars_earned:
		0:
			star_preview_label.text = "- -"
			star_preview_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		1:
			star_preview_label.text = "S"
			star_preview_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		2:
			star_preview_label.text = "SS"
			star_preview_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		3:
			star_preview_label.text = "SSS"
			star_preview_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.0))
