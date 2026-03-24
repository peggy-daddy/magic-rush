extends Control

# =============================================
# GAME OVER SCREEN — 3 endings (PERFECT / FAIL / NORMAL)
# =============================================

@onready var bg_color: ColorRect = $BgColor
@onready var ending_icon: Label = $ContentVBox/EndingIcon
@onready var title_label: Label = $ContentVBox/TitleLabel
@onready var subtitle_label: Label = $ContentVBox/SubtitleLabel
@onready var time_survived_label: Label = $ContentVBox/StatsVBox/TimeSurvivedLabel
@onready var deliveries_label: Label = $ContentVBox/StatsVBox/DeliveriesLabel
@onready var final_magic_label: Label = $ContentVBox/StatsVBox/FinalMagicLabel
@onready var play_again_btn: Button = $ContentVBox/PlayAgainBtn
@onready var quit_btn: Button = $ContentVBox/QuitBtn

func _ready() -> void:
	play_again_btn.pressed.connect(_on_play_again)
	quit_btn.pressed.connect(_on_quit)

	GameManager.game_over.connect(_show_result)

	# Show current result immediately when scene loads
	var end_type: int = GameManager._get_end_type()
	_show_result(end_type)

	# Task 1 — Button background textures
	_apply_button_texture(play_again_btn, "res://assets/backgrounds/Start Panel.png")
	_apply_button_texture(quit_btn,       "res://assets/backgrounds/Other Panel.png")


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

func _show_result(end_type: int) -> void:
	# --- Stats ---
	var elapsed: float = 180.0 - GameManager.time_remaining
	elapsed = clampf(elapsed, 0.0, 180.0)
	var minutes: int = int(elapsed) / 60
	var seconds: int = int(elapsed) % 60
	time_survived_label.text = "Time Survived: %d:%02d" % [minutes, seconds]

	deliveries_label.text = "Deliveries: %d" % GameManager.delivery_count

	var chi_pct: int = int((GameManager.chi_value / GameManager.chi_max) * 100.0)
	final_magic_label.text = "Final Magic: %d%%" % chi_pct

	# --- Result title, icon, subtitle, and background by end type ---
	match end_type:
		GameManager.EndType.PERFECT:
			bg_color.color = Color(0.04, 0.22, 0.08, 1.0)
			ending_icon.text = "< * >"
			title_label.text = "PERFECT VICTORY!"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.843, 0.0, 1.0))
			subtitle_label.text = "The magic is overflowing! Perfect mastery!"

		GameManager.EndType.FAIL:
			bg_color.color = Color(0.22, 0.04, 0.04, 1.0)
			ending_icon.text = "[ X ]"
			title_label.text = "DEFEATED"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.18, 0.18, 1.0))
			subtitle_label.text = "The Demon Baby won... the house is lost!"

		_:  # NORMAL — time ran out
			bg_color.color = Color(0.05, 0.10, 0.22, 1.0)
			ending_icon.text = "{ ~ }"
			title_label.text = "TIME'S UP"
			title_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0, 1.0))
			subtitle_label.text = "Time ran out — but the spirits are appeased!"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # ENTER
		_on_play_again()
	elif event.is_action_pressed("ui_cancel"):  # ESC
		_on_quit()

func _on_play_again() -> void:
	GameManager.apply_click_bounce(play_again_btn)
	get_tree().change_scene_to_file("res://scenes/TitleScreen.tscn")

func _on_quit() -> void:
	GameManager.apply_click_bounce(quit_btn)
	get_tree().quit()
