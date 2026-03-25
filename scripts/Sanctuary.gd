extends Control

# =============================================
# SANCTUARY SCENE
# Drawers (drag-drop), Prep Station, Craft FX, Transition
# =============================================

@onready var drawer_grid: GridContainer = $DrawerGrid
@onready var prep_station: Panel = $PrepStation
@onready var go_to_living_room_btn: Button = $GoToLivingRoomBtn
@onready var nav_right_btn: Button = $NavRightBtn
@onready var transition_overlay: ColorRect = $TransitionOverlay
@onready var craft_fx: GPUParticles2D = $PrepStation/CraftFX
@onready var status_label: Label = $StatusLabel
@onready var drag_icon: TextureRect = $DragIcon
@onready var slot_a_panel: Panel = $PrepStation/SlotA
@onready var slot_b_panel: Panel = $PrepStation/SlotB
@onready var recipe_panel: VBoxContainer = $RecipePanel
@onready var baby_recipe_title: Label = $RecipePanel/BabyRecipeTitle
@onready var baby_recipe1: Label = $RecipePanel/BabyRecipe1
@onready var baby_recipe2: Label = $RecipePanel/BabyRecipe2

const DRAWER_REFILL_TIME: float = 5.0
const DRAG_ICON_SIZE: float = 64.0

var drawer_items: Array[String] = ["water_bottle", "paper", "candle", "red_potion", "book", "scroll"]
var drawer_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var drawer_buttons: Array[TextureButton] = []
var _status_clear_tween: Tween = null
var _baby_pulse_tween: Tween = null

# Drag state
var dragging: bool = false
var drag_item: String = ""
var drag_source_index: int = -1

func _ready() -> void:
	var inv_overlay = preload("res://scenes/InventoryOverlay.tscn").instantiate()
	add_child(inv_overlay)

	_setup_drawers()
	_setup_prep_station()
	nav_right_btn.pressed.connect(_go_to_living_room)
	# Task 1 — Button background texture
	_apply_button_texture(nav_right_btn, "res://assets/backgrounds/direction.png")
	GameManager.baby_woke.connect(_on_baby_woke)
	GameManager.baby_silenced.connect(_on_baby_silenced)
	GameManager.game_over.connect(_on_game_over)
	transition_overlay.modulate.a = 0.0
	status_label.text = ""
	drag_icon.visible = false
	# Fade in from black
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, 0.3)
	# Set open-hand cursor resized to 32x32 (web-compatible)
	var _cb = load("res://assets/cursors/Cursor_Hand.png")
	if _cb:
		var _ci: Image = _cb.get_image()
		_ci.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(_ci), Input.CURSOR_ARROW, Vector2(4, 0))

func _setup_drawers() -> void:
	for i: int in range(6):
		var btn: TextureButton = drawer_grid.get_child(i) as TextureButton
		if btn == null:
			continue
		drawer_buttons.append(btn)
		btn.gui_input.connect(_on_drawer_gui_input.bind(i))
		_update_drawer_visual(i, true)

func _setup_prep_station() -> void:
	var craft_btn: Button = prep_station.get_node("CraftButton")
	craft_btn.pressed.connect(_on_craft_pressed)
	_update_prep_display()

func _process(delta: float) -> void:
	# Tick drawer refill cooldowns
	for i: int in range(6):
		if drawer_cooldowns[i] > 0.0:
			drawer_cooldowns[i] -= delta
			if drawer_cooldowns[i] <= 0.0:
				drawer_cooldowns[i] = 0.0
				_update_drawer_visual(i, true)
	# Keep drag icon centered on cursor
	if dragging:
		drag_icon.global_position = get_global_mouse_position() - Vector2(DRAG_ICON_SIZE, DRAG_ICON_SIZE) * 0.5

func _on_drawer_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed:
			if drawer_cooldowns[index] > 0.0:
				_show_status("Refilling... wait a moment.", Color(1, 0.8, 0.4, 1))
				return
			AudioManager.play_click()
			_begin_drag(index)

func _start_drag_from_inventory(item_name: String) -> void:
	if dragging:
		return
	dragging = true
	drag_item = item_name
	drag_source_index = -1  # -1 = from inventory, not from a drawer

	# Load item texture onto the shared floating drag icon
	var tex_path: String = GameManager.get_item_texture_path(item_name)
	drag_icon.texture = null
	if tex_path != "" and ResourceLoader.exists(tex_path):
		drag_icon.texture = load(tex_path)
	drag_icon.size = Vector2(DRAG_ICON_SIZE, DRAG_ICON_SIZE)
	drag_icon.visible = true
	drag_icon.global_position = get_global_mouse_position() - Vector2(DRAG_ICON_SIZE, DRAG_ICON_SIZE) * 0.5

	_show_status("Drag to Slot A or B to craft!", Color.YELLOW)

	# Closed-hand cursor while dragging (web-compatible)
	var _gb = load("res://assets/cursors/Cursor_Hand_closed.png")
	if _gb:
		var _gi: Image = _gb.get_image()
		_gi.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(_gi), Input.CURSOR_ARROW, Vector2(4, 0))


func _begin_drag(index: int) -> void:
	dragging = true
	drag_item = drawer_items[index]
	drag_source_index = index
	# Load item texture onto floating drag icon
	var tex_path: String = GameManager.get_item_texture_path(drag_item)
	if tex_path != "":
		drag_icon.texture = load(tex_path)
	drag_icon.size = Vector2(DRAG_ICON_SIZE, DRAG_ICON_SIZE)
	drag_icon.visible = true
	drag_icon.global_position = get_global_mouse_position() - Vector2(DRAG_ICON_SIZE, DRAG_ICON_SIZE) * 0.5
	# Show drawer in open/depleted state
	_update_drawer_visual(index, false)
	# Closed-hand cursor while dragging (web-compatible)
	var _gb2 = load("res://assets/cursors/Cursor_Hand_closed.png")
	if _gb2:
		var _gi2: Image = _gb2.get_image()
		_gi2.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(_gi2), Input.CURSOR_ARROW, Vector2(4, 0))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and not mbe.pressed:
			_end_drag(get_global_mouse_position())

func _end_drag(mouse_pos: Vector2) -> void:
	var dropped: bool = false
	if slot_a_panel.get_global_rect().has_point(mouse_pos):
		if GameManager.prep_slots[0].is_empty():
			GameManager.prep_slots[0] = drag_item
			dropped = true
			_show_status("Placed " + GameManager.get_item_display_name(drag_item) + " in Slot A", Color.WHITE)
		else:
			_show_status("Slot A is full!", Color.ORANGE)
	elif slot_b_panel.get_global_rect().has_point(mouse_pos):
		if GameManager.prep_slots[1].is_empty():
			GameManager.prep_slots[1] = drag_item
			dropped = true
			_show_status("Placed " + GameManager.get_item_display_name(drag_item) + " in Slot B", Color.WHITE)
		else:
			_show_status("Slot B is full!", Color.ORANGE)

	if dropped:
		if drag_source_index >= 0:
			# Start refill cooldown on the source drawer
			drawer_cooldowns[drag_source_index] = DRAWER_REFILL_TIME
		else:
			# Item came from inventory — consume it
			GameManager.remove_item(drag_item)
		_update_prep_display()
		# Auto-craft when both slots are filled
		if not GameManager.prep_slots[0].is_empty() and not GameManager.prep_slots[1].is_empty():
			_try_craft()
	else:
		if drag_source_index >= 0:
			# Missed drop — restore drawer to available state
			_update_drawer_visual(drag_source_index, true)
		_show_status("Drag onto Slot A or B to place an ingredient.", Color.YELLOW)

	# Always end drag regardless of outcome
	dragging = false
	drag_icon.visible = false
	drag_item = ""
	drag_source_index = -1
	# Restore open-hand cursor (web-compatible)
	var _hb = load("res://assets/cursors/Cursor_Hand.png")
	if _hb:
		var _hi: Image = _hb.get_image()
		_hi.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(_hi), Input.CURSOR_ARROW, Vector2(4, 0))

func _on_craft_pressed() -> void:
	AudioManager.play_click()
	_try_craft()

func _try_craft() -> void:
	if GameManager.prep_slots[0].is_empty() or GameManager.prep_slots[1].is_empty():
		_show_status("Need 2 ingredients to craft!", Color.ORANGE)
		return
	var result: String = GameManager.try_craft()
	if result != "":
		_play_craft_fx()
		AudioManager.play_deliver()
		if GameManager.add_item(result):
			_show_status("Crafted: " + GameManager.get_item_display_name(result), Color.GREEN)
		else:
			_show_status("Inventory full! Max 4 items.", Color.ORANGE)
	else:
		_show_status("Those don't combine!", Color.ORANGE)
	_update_prep_display()

func _play_craft_fx() -> void:
	if craft_fx:
		craft_fx.restart()
		craft_fx.emitting = true

func _update_drawer_visual(index: int, available: bool) -> void:
	if index >= drawer_buttons.size():
		return
	var btn: TextureButton = drawer_buttons[index]
	# Label node name matches pattern "Drawer0Label", "Drawer1Label", etc.
	var lbl: Label = btn.get_node_or_null("Drawer%dLabel" % index) as Label
	var icon: TextureRect = btn.get_node_or_null("ItemIcon") as TextureRect
	var item_key: String = drawer_items[index]
	if available:
		btn.texture_normal = load("res://assets/sprites/drawers/cabinet1-drawer1.png")
		btn.modulate = Color.WHITE
		if lbl:
			lbl.text = GameManager.get_item_display_name(item_key)
		if icon:
			var tex_path: String = GameManager.get_item_texture_path(item_key)
			if tex_path != "":
				icon.texture = load(tex_path)
			icon.visible = true
	else:
		btn.texture_normal = load("res://assets/sprites/drawers/cabinet1-drawer2.png")
		btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
		if lbl:
			lbl.text = "(Refilling...)"
		if icon:
			icon.visible = false

func _update_prep_display() -> void:
	var slot_a_label: Label = prep_station.get_node("SlotA/Label") as Label
	var slot_b_label: Label = prep_station.get_node("SlotB/Label") as Label
	var slot_a_icon: TextureRect = prep_station.get_node_or_null("SlotA/SlotAIcon") as TextureRect
	var slot_b_icon: TextureRect = prep_station.get_node_or_null("SlotB/SlotBIcon") as TextureRect

	if GameManager.prep_slots[0].is_empty():
		slot_a_label.text = "Slot A\n(empty)"
		slot_a_label.modulate = Color(0.7, 0.7, 0.7, 1)
		if slot_a_icon:
			slot_a_icon.texture = null
	else:
		slot_a_label.text = "Slot A:\n" + GameManager.get_item_display_name(GameManager.prep_slots[0])
		slot_a_label.modulate = Color.WHITE
		if slot_a_icon:
			var p: String = GameManager.get_item_texture_path(GameManager.prep_slots[0])
			slot_a_icon.texture = load(p) if p != "" else null

	if GameManager.prep_slots[1].is_empty():
		slot_b_label.text = "Slot B\n(empty)"
		slot_b_label.modulate = Color(0.7, 0.7, 0.7, 1)
		if slot_b_icon:
			slot_b_icon.texture = null
	else:
		slot_b_label.text = "Slot B:\n" + GameManager.get_item_display_name(GameManager.prep_slots[1])
		slot_b_label.modulate = Color.WHITE
		if slot_b_icon:
			var p: String = GameManager.get_item_texture_path(GameManager.prep_slots[1])
			slot_b_icon.texture = load(p) if p != "" else null

func _show_status(msg: String, color: Color = Color.WHITE) -> void:
	status_label.text = msg
	status_label.modulate = color
	status_label.modulate.a = 1.0
	if _status_clear_tween:
		_status_clear_tween.kill()
	_status_clear_tween = create_tween()
	_status_clear_tween.tween_property(status_label, "modulate:a", 0.0, 0.5).set_delay(2.0)
	_status_clear_tween.tween_callback(func() -> void:
		status_label.text = ""
		status_label.modulate.a = 1.0
	)

func _on_baby_woke() -> void:
	_show_status("DEMON BABY WOKE UP! Go to Living Room!", Color.RED)
	baby_recipe_title.modulate = Color(1, 0.15, 0.15, 1)
	baby_recipe1.modulate = Color(1, 0.15, 0.15, 1)
	baby_recipe2.modulate = Color(1, 0.15, 0.15, 1)
	if _baby_pulse_tween:
		_baby_pulse_tween.kill()
	_baby_pulse_tween = create_tween().set_loops()
	_baby_pulse_tween.tween_property(baby_recipe_title, "modulate:a", 0.4, 0.5)
	_baby_pulse_tween.tween_property(baby_recipe_title, "modulate:a", 1.0, 0.5)

func _on_baby_silenced() -> void:
	if _baby_pulse_tween:
		_baby_pulse_tween.kill()
		_baby_pulse_tween = null
	baby_recipe_title.modulate = Color(1, 0.6, 0.1, 1)
	baby_recipe1.modulate = Color(0.9, 0.95, 0.9, 1)
	baby_recipe2.modulate = Color(0.9, 0.95, 0.9, 1)

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


func _go_to_living_room() -> void:
	AudioManager.play_click()
	GameManager.apply_click_bounce(nav_right_btn)
	var tween: Tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func() -> void:
		GameManager.change_room(GameManager.Room.LIVING_ROOM)
		get_tree().change_scene_to_file("res://scenes/LivingRoom.tscn")
	)

func _on_game_over(_end_type: int) -> void:
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
