extends Control

# =============================================
# TITLE SCREEN — Magic Rush
# =============================================

@onready var start_button: Button       = $VBoxContainer/StartButton
@onready var how_to_play_button: Button = $VBoxContainer/HowToPlayButton
@onready var quit_button: Button        = $VBoxContainer/QuitButton
@onready var how_to_play_panel: Panel   = $HowToPlayPanel
@onready var close_htp_btn: Button      = $HowToPlayPanel/VBox/CloseHTPBtn
@onready var credits_panel: Panel       = $CreditsPanel
@onready var close_credits_btn: Button  = $CreditsPanel/VBox/CloseButton
@onready var bg_image: TextureRect      = $BackgroundImage

# Hover scale constants
const HOVER_SCALE: Vector2  = Vector2(1.05, 1.05)
const NORMAL_SCALE: Vector2 = Vector2(1.0,  1.0)

# Tween handle for each button (keyed by node)
var _hover_tweens: Dictionary = {}


func _ready() -> void:
	# Connect button pressed signals
	start_button.pressed.connect(_on_start_pressed)
	how_to_play_button.pressed.connect(_on_how_to_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_htp_btn.pressed.connect(_on_close_htp)
	close_credits_btn.pressed.connect(_on_close_credits)

	# Wire hover signals for the three main buttons
	for btn: Button in [start_button, how_to_play_button, quit_button]:
		btn.mouse_entered.connect(_on_btn_hover.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhover.bind(btn))

	# Hide panels initially; ensure they block input when visible
	how_to_play_panel.visible = false
	how_to_play_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_panel.visible     = false
	credits_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Load background at runtime so missing import doesn't break headless parsing
	var bg_tex: Texture2D = load("res://assets/backgrounds/mockup8.png") as Texture2D
	if bg_tex and is_instance_valid(bg_image):
		bg_image.texture = bg_tex

	# Custom hand cursor resized to 32x32 (web-compatible: use load + get_image)
	var _cursor_base = load("res://assets/cursors/Cursor_Hand.png")
	if _cursor_base:
		var _cursor_img: Image = _cursor_base.get_image()
		_cursor_img.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		var _cursor_tex: ImageTexture = ImageTexture.create_from_image(_cursor_img)
		Input.set_custom_mouse_cursor(_cursor_tex, Input.CURSOR_ARROW, Vector2(4, 0))

	# Task 1 — Button background textures
	_apply_button_texture(start_button,       "res://assets/backgrounds/Start Panel.png")
	_apply_button_texture(how_to_play_button, "res://assets/backgrounds/Other Panel.png")
	_apply_button_texture(quit_button,        "res://assets/backgrounds/Other Panel.png")


# ---------------------------------------------------------------------------
# Button hover effects
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


func _on_btn_hover(btn: Button) -> void:
	_tween_button_scale(btn, HOVER_SCALE)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.7, 1.0))


func _on_btn_unhover(btn: Button) -> void:
	_tween_button_scale(btn, NORMAL_SCALE)
	btn.remove_theme_color_override("font_color")


func _tween_button_scale(btn: Button, target: Vector2) -> void:
	var key: int = btn.get_instance_id()
	if _hover_tweens.has(key) and _hover_tweens[key] is Tween:
		(_hover_tweens[key] as Tween).kill()
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tweens[key] = tw


# ---------------------------------------------------------------------------
# Button press handlers
# ---------------------------------------------------------------------------

func _on_start_pressed() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(start_button)
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/LivingRoom.tscn")


func _on_how_to_play_pressed() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(how_to_play_button)
	how_to_play_panel.visible = true
	how_to_play_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	how_to_play_panel.move_to_front()


func _on_close_htp() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(close_htp_btn)
	how_to_play_panel.visible = false


func _on_quit_pressed() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(quit_button)
	await get_tree().create_timer(0.25).timeout
	get_tree().quit()


func _on_open_credits() -> void:
	AudioManager.play_click()
	credits_panel.visible = true
	credits_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_panel.move_to_front()


func _on_close_credits() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(close_credits_btn)
	credits_panel.visible = false


# ---------------------------------------------------------------------------
# ANY click anywhere closes the active overlay panel.
# ESC also closes. The in-panel close buttons still work as a fallback.
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if how_to_play_panel.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			how_to_play_panel.visible = false
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				how_to_play_panel.visible = false
				get_viewport().set_input_as_handled()
				return
	if credits_panel != null and credits_panel.visible:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			credits_panel.visible = false
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				credits_panel.visible = false
				get_viewport().set_input_as_handled()
				return
