extends CanvasLayer

# =============================================
# INVENTORY OVERLAY - Global Autoload
# Displays up to 4 inventory slots in the bottom-right corner.
# Slots are arranged in a 2x2 grid.
# The selected slot is highlighted with a gold border.
# Clicking a filled slot "picks it up" — cursor becomes closed hand.
# Clicking the same slot again, or an empty slot, deselects.
# =============================================

# Slot node references — populated in _ready after the scene loads
var _slot_panels: Array[Panel] = []
var _slot_icons: Array[TextureRect] = []
var _slot_labels: Array[Label] = []

# Style resources cached to avoid recreating every frame
var _style_empty: StyleBoxFlat = null
var _style_filled: StyleBoxFlat = null
var _style_selected: StyleBoxFlat = null

# Cursor texture cache
var _cursor_open: ImageTexture = null
var _cursor_closed: ImageTexture = null

# Drag ghost (semi-transparent copy follows mouse)
var _drag_ghost: TextureRect = null


func _ready() -> void:
	_build_styles()
	_collect_slot_nodes()
	_load_cursors()
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.item_dropped.connect(_on_item_dropped)
	_refresh_slots()


func _build_styles() -> void:
	_style_empty = StyleBoxFlat.new()
	_style_empty.bg_color = Color(0.12, 0.10, 0.18, 0.85)
	_style_empty.corner_radius_top_left = 6
	_style_empty.corner_radius_top_right = 6
	_style_empty.corner_radius_bottom_right = 6
	_style_empty.corner_radius_bottom_left = 6
	_style_empty.border_width_left = 1
	_style_empty.border_width_top = 1
	_style_empty.border_width_right = 1
	_style_empty.border_width_bottom = 1
	_style_empty.border_color = Color(0.35, 0.30, 0.45, 0.8)

	_style_filled = StyleBoxFlat.new()
	_style_filled.bg_color = Color(0.10, 0.08, 0.16, 0.92)
	_style_filled.corner_radius_top_left = 6
	_style_filled.corner_radius_top_right = 6
	_style_filled.corner_radius_bottom_right = 6
	_style_filled.corner_radius_bottom_left = 6
	_style_filled.border_width_left = 1
	_style_filled.border_width_top = 1
	_style_filled.border_width_right = 1
	_style_filled.border_width_bottom = 1
	_style_filled.border_color = Color(0.55, 0.42, 0.12, 0.9)

	_style_selected = StyleBoxFlat.new()
	_style_selected.bg_color = Color(0.18, 0.14, 0.08, 0.95)
	_style_selected.corner_radius_top_left = 6
	_style_selected.corner_radius_top_right = 6
	_style_selected.corner_radius_bottom_right = 6
	_style_selected.corner_radius_bottom_left = 6
	_style_selected.border_width_left = 3
	_style_selected.border_width_top = 3
	_style_selected.border_width_right = 3
	_style_selected.border_width_bottom = 3
	_style_selected.border_color = Color(1.0, 0.82, 0.0, 1.0)


func _load_cursors() -> void:
	var open_tex: Texture2D = load("res://assets/cursors/Cursor_Hand.png") as Texture2D
	if open_tex:
		var img: Image = open_tex.get_image()
		img.resize(24, 24, Image.INTERPOLATE_NEAREST)
		_cursor_open = ImageTexture.create_from_image(img)

	var closed_tex: Texture2D = load("res://assets/cursors/Cursor_Hand_closed.png") as Texture2D
	if closed_tex:
		var img: Image = closed_tex.get_image()
		img.resize(24, 24, Image.INTERPOLATE_NEAREST)
		_cursor_closed = ImageTexture.create_from_image(img)


func _collect_slot_nodes() -> void:
	for i: int in range(GameManager.MAX_INVENTORY):
		var panel: Panel = get_node("InventoryPanel/MarginContainer/VBoxOuter/SlotGrid/Slot%d" % i) as Panel
		var icon: TextureRect = panel.get_node("VBox/SlotIcon") as TextureRect
		var lbl: Label = panel.get_node("VBox/SlotLabel") as Label
		_slot_panels.append(panel)
		_slot_icons.append(icon)
		_slot_labels.append(lbl)
		# Connect click — capture index by value with bind()
		panel.gui_input.connect(_on_slot_gui_input.bind(i))


func _on_inventory_changed(_new_inventory: Array) -> void:
	_refresh_slots()
	_sync_cursor()


func _on_item_dropped() -> void:
	_refresh_slots()
	_sync_cursor()


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed:
			# Consume the event so it does not fall through to scene nodes
			get_viewport().set_input_as_handled()
			AudioManager.play_click()

			var has_item: bool = slot_index < GameManager.inventory.size()
			if not has_item:
				# Clicking an empty slot deselects
				GameManager.selected_slot = -1
				_refresh_slots()
				_sync_cursor()
				return

			if GameManager.selected_slot == slot_index:
				# Clicking the already-selected slot deselects (puts item back)
				GameManager.selected_slot = -1
				_refresh_slots()
				_sync_cursor()
				return

			# Select this slot — item is now "held"
			GameManager.selected_slot = slot_index
			_refresh_slots()
			_sync_cursor()

			# Create drag ghost (Task 6)
			_create_drag_ghost(slot_index, mbe.global_position)

			# Notify the current scene to begin drag-and-drop delivery/placement
			var item_name: String = GameManager.inventory[slot_index]
			var scene: Node = get_tree().current_scene
			if scene != null and scene.has_method("_start_drag_from_inventory"):
				scene._start_drag_from_inventory(item_name)


func _sync_cursor() -> void:
	var item_held: bool = GameManager.selected_slot >= 0 and \
		GameManager.selected_slot < GameManager.inventory.size()

	if item_held and _cursor_closed != null:
		Input.set_custom_mouse_cursor(_cursor_closed, Input.CURSOR_ARROW, Vector2(0, 0))
	elif _cursor_open != null:
		Input.set_custom_mouse_cursor(_cursor_open, Input.CURSOR_ARROW, Vector2(0, 0))


func _refresh_slots() -> void:
	for i: int in range(GameManager.MAX_INVENTORY):
		var has_item: bool = i < GameManager.inventory.size()
		var is_selected: bool = (i == GameManager.selected_slot) and has_item

		if is_selected:
			_slot_panels[i].add_theme_stylebox_override("panel", _style_selected)
		elif has_item:
			_slot_panels[i].add_theme_stylebox_override("panel", _style_filled)
		else:
			_slot_panels[i].add_theme_stylebox_override("panel", _style_empty)

		if has_item:
			var item_key: String = GameManager.inventory[i]
			var tex_path: String = GameManager.get_item_texture_path(item_key)
			_slot_icons[i].texture = load(tex_path) if tex_path != "" else null
			_slot_icons[i].modulate = Color(1.0, 1.0, 0.7, 1.0) if is_selected else Color.WHITE
			_slot_labels[i].text = GameManager.get_item_display_name(item_key)
			_slot_labels[i].modulate = Color(1.0, 1.0, 0.6, 1.0) if is_selected else Color.WHITE
		else:
			_slot_icons[i].texture = null
			_slot_icons[i].modulate = Color(0.4, 0.4, 0.4, 0.6)
			_slot_labels[i].text = "(empty)"
			_slot_labels[i].modulate = Color(0.5, 0.5, 0.5, 0.8)


# ---------------------------------------------------------------------------
# Drag Ghost (Task 6) — semi-transparent copy follows mouse
# ---------------------------------------------------------------------------

func _create_drag_ghost(slot_index: int, start_pos: Vector2) -> void:
	_clear_drag_ghost()
	if slot_index >= _slot_icons.size():
		return
	var icon: TextureRect = _slot_icons[slot_index]
	if icon == null or icon.texture == null:
		return
	_drag_ghost = TextureRect.new()
	_drag_ghost.texture = icon.texture
	_drag_ghost.custom_minimum_size = Vector2(48, 48)
	_drag_ghost.size = Vector2(48, 48)
	_drag_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_ghost.modulate = Color(1, 1, 1, 1.0)
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.z_index = 200
	add_child(_drag_ghost)
	_drag_ghost.global_position = start_pos - Vector2(24, 24)
	# Dim the original slot icon to indicate the item is "moving"
	icon.modulate = Color(0.3, 0.3, 0.3, 0.5)


func _clear_drag_ghost() -> void:
	# Restore brightness on the original slot icon before freeing the ghost
	if GameManager.selected_slot >= 0 and GameManager.selected_slot < _slot_icons.size():
		_slot_icons[GameManager.selected_slot].modulate = Color.WHITE
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free()
	_drag_ghost = null


func _process(_delta: float) -> void:
	if _drag_ghost != null and is_instance_valid(_drag_ghost):
		_drag_ghost.global_position = get_viewport().get_mouse_position() - Vector2(24, 24)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_clear_drag_ghost()
