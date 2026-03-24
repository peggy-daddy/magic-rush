extends Node

# =============================================
# GAME MANAGER - Global Singleton
# Feng Shui Rush
# =============================================

enum GameState { MENU, PLAYING, PAUSED, CRISIS, GAME_OVER }
enum Room { SANCTUARY, LIVING_ROOM }
enum EndType { PERFECT, FAIL, NORMAL }

# --- Game State ---
var game_state: GameState = GameState.MENU
var current_room: Room = Room.SANCTUARY

# --- Chi ---
var chi_value: float = 0.0
var chi_max: float = 100.0
var chi_drain_rate: float = 2.0  # per second when baby awake

const CHI_PER_NPC_ORDER: float = 10.0
const CHI_PER_BABY_ORDER: float = 40.0
const MAX_ORDERS_PER_NPC: int = 8

# --- Timer ---
var time_remaining: float = 180.0  # 3 minutes
var timer_running: bool = false

# --- Baby ---
var is_baby_awake: bool = false
var baby_wake_timer: float = 0.0
const BABY_WAKE_INTERVAL: float = 60.0

# --- Inventory ---
var inventory: Array = []
const MAX_INVENTORY: int = 4
var selected_slot: int = -1

# --- Delivery ---
var delivery_count: int = 0

# --- Crafting ---
var prep_slots: Array = ["", ""]  # two ingredient slots on prep station

# --- NPC Order Tracking ---
var npc_order_count: Dictionary = {"grandpa": 0, "dad": 0, "mom": 0, "child": 0}

# --- Signals ---
signal chi_changed(new_value: float, max_value: float)
signal delivery_scored(count: int, stars_earned: int)
signal timer_updated(seconds_left: float)
signal baby_woke()
signal baby_silenced()
signal game_over(end_type: int)
signal inventory_changed(new_inventory: Array)
signal item_picked_up(item_name: String)
signal item_dropped()
signal room_changed(room: Room)

# --- Item Definitions ---
const INGREDIENTS = {
	"water_bottle": {
		"name": "Water Bottle",
		"texture": "res://assets/sprites/potions/Water Bottle.png",
		"color": Color(0.3, 0.6, 1.0)
	},
	"paper": {
		"name": "Paper",
		"texture": "res://assets/sprites/items/Paper.png",
		"color": Color(0.95, 0.95, 0.8)
	},
	"candle": {
		"name": "Candle",
		"texture": "res://assets/sprites/misc/Candle.png",
		"color": Color(1.0, 0.9, 0.3)
	},
	"red_potion": {
		"name": "Potion",
		"texture": "res://assets/sprites/potions/Red Potion 2.png",
		"color": Color(1.0, 0.2, 0.2)
	},
	"book": {
		"name": "Book",
		"texture": "res://assets/sprites/misc/Book.png",
		"color": Color(0.6, 0.3, 0.1)
	},
	"scroll": {
		"name": "Scroll",
		"texture": "res://assets/sprites/misc/Scroll.png",
		"color": Color(0.8, 0.7, 0.5)
	}
}

const CRAFTED_ITEMS = {
	"eye": {
		"name": "Eye",
		"texture": "res://assets/sprites/items/Eye.png",
		"color": Color(1.0, 0.8, 0.0),
		"recipe": ["paper", "candle"]
	},
	"egg": {
		"name": "Egg",
		"texture": "res://assets/sprites/items/Egg.png",
		"color": Color(0.3, 0.5, 1.0),
		"recipe": ["water_bottle", "red_potion"]
	},
	"pearl": {
		"name": "Pearl",
		"texture": "res://assets/sprites/items/Pearl.png",
		"color": Color(0.5, 0.0, 0.8),
		"recipe": ["book", "scroll"]
	},
	"key": {
		"name": "Key",
		"texture": "res://assets/sprites/items/Key.png",
		"color": Color(0.1, 0.1, 0.3),
		"recipe": ["candle", "book"]
	},
	"apple": {
		"name": "Apple",
		"texture": "res://assets/sprites/items/Apple.png",
		"color": Color(0.9, 0.8, 1.0),
		"recipe": ["water_bottle", "scroll"]
	},
	"obsidian": {
		"name": "Obsidian",
		"texture": "res://assets/sprites/items/Obsidian.png",
		"color": Color(0.5, 0.9, 1.0),
		"recipe": ["water_bottle", "paper"]
	},
	"crystal": {
		"name": "Crystal",
		"texture": "res://assets/sprites/items/Pearl.png",
		"color": Color(0.8, 0.2, 1.0),
		"recipe": ["candle", "red_potion"]
	},
	"heart": {
		"name": "Heart",
		"texture": "res://assets/sprites/items/Heart.png",
		"color": Color(1.0, 0.0, 0.5),
		"recipe": ["obsidian", "crystal"]
	}
}

# NPC requests pool (normal mode)
const NPC_REQUEST_POOL = ["eye", "egg", "pearl", "key", "apple"]

# Current NPC requests
var npc_requests: Dictionary = {
	"grandpa": "",
	"dad": "",
	"mom": "",
	"child": ""
}

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	if game_state != GameState.PLAYING and game_state != GameState.CRISIS:
		return

	# Timer countdown
	if timer_running:
		time_remaining -= delta
		emit_signal("timer_updated", time_remaining)

		if time_remaining <= 0:
			time_remaining = 0
			_end_game()
			return

	# Baby wake timer — fixed 60-second interval
	if not is_baby_awake:
		baby_wake_timer += delta
		if baby_wake_timer >= BABY_WAKE_INTERVAL:
			_wake_baby()

	# Chi drain when baby awake
	if is_baby_awake and game_state != GameState.GAME_OVER:
		chi_value -= chi_drain_rate * delta
		if chi_value < 0.01:
			chi_value = 0.0
		emit_signal("chi_changed", chi_value, chi_max)

		if chi_value <= 0.0:
			_end_game()
			return

func start_game() -> void:
	chi_value = 20.0
	time_remaining = 180.0
	is_baby_awake = false
	baby_wake_timer = 0.0
	inventory = []
	selected_slot = -1
	prep_slots = ["", ""]
	delivery_count = 0
	npc_order_count = {"grandpa": 0, "dad": 0, "mom": 0, "child": 0}
	game_state = GameState.PLAYING
	timer_running = true
	current_room = Room.LIVING_ROOM

	# Generate initial NPC requests
	_generate_npc_request("grandpa")
	_generate_npc_request("dad")
	_generate_npc_request("mom")
	_generate_npc_request("child")

	emit_signal("chi_changed", chi_value, chi_max)
	emit_signal("timer_updated", time_remaining)

func _wake_baby() -> void:
	is_baby_awake = true
	game_state = GameState.CRISIS
	emit_signal("baby_woke")

func silence_baby() -> void:
	is_baby_awake = false
	game_state = GameState.PLAYING
	baby_wake_timer = 0.0
	emit_signal("baby_silenced")

func add_chi(amount: float) -> void:
	chi_value = min(chi_value + amount, chi_max)
	emit_signal("chi_changed", chi_value, chi_max)
	if chi_value >= chi_max:
		_end_game()

func add_item(item_name: String) -> bool:
	if inventory.size() >= MAX_INVENTORY:
		return false
	inventory.append(item_name)
	# Auto-select the first item added
	if selected_slot == -1:
		selected_slot = 0
	emit_signal("inventory_changed", inventory)
	emit_signal("item_picked_up", item_name)
	return true

func remove_item(item_name: String) -> bool:
	var idx: int = inventory.find(item_name)
	if idx == -1:
		return false
	inventory.remove_at(idx)
	# Clamp selected_slot to valid range
	if inventory.is_empty():
		selected_slot = -1
	elif selected_slot >= inventory.size():
		selected_slot = inventory.size() - 1
	emit_signal("inventory_changed", inventory)
	emit_signal("item_dropped")
	return true

func get_selected_item() -> String:
	if selected_slot >= 0 and selected_slot < inventory.size():
		return inventory[selected_slot]
	return ""

# Backward-compat wrappers
func pick_up_item(item_name: String) -> void:
	add_item(item_name)

func drop_item() -> void:
	var item: String = get_selected_item()
	if item != "":
		remove_item(item)

func try_craft() -> String:
	var slot_a: String = prep_slots[0]
	var slot_b: String = prep_slots[1]

	if slot_a.is_empty() or slot_b.is_empty():
		return ""

	# Check all crafted items for matching recipe
	for item_key in CRAFTED_ITEMS:
		var recipe: Array = CRAFTED_ITEMS[item_key]["recipe"]
		if recipe.size() == 2:
			if (recipe[0] == slot_a and recipe[1] == slot_b) or \
			   (recipe[0] == slot_b and recipe[1] == slot_a):
				prep_slots = ["", ""]
				return item_key

	# No match - clear slots and return fail
	prep_slots = ["", ""]
	return ""

func deliver_to_npc(npc_name: String, item_name: String) -> bool:
	if npc_requests[npc_name] == item_name:
		npc_order_count[npc_name] += 1
		print("[GameManager] deliver_to_npc: %s delivered %s — adding %.1f chi (was %.1f)" % [npc_name, item_name, CHI_PER_NPC_ORDER, chi_value])
		add_chi(CHI_PER_NPC_ORDER)
		remove_item(item_name)
		delivery_count += 1
		emit_signal("delivery_scored", delivery_count, calculate_stars())
		if npc_order_count[npc_name] >= MAX_ORDERS_PER_NPC:
			npc_requests[npc_name] = ""
		else:
			_generate_npc_request(npc_name)
		return true
	return false

func deliver_baby_seal(item_name: String) -> bool:
	if item_name == "heart":
		silence_baby()
		add_chi(CHI_PER_BABY_ORDER)
		remove_item(item_name)
		return true
	return false

func _generate_npc_request(npc_name: String) -> void:
	var idx: int = randi() % NPC_REQUEST_POOL.size()
	npc_requests[npc_name] = NPC_REQUEST_POOL[idx]

func change_room(room: Room) -> void:
	current_room = room
	emit_signal("room_changed", room)

func _get_end_type() -> EndType:
	if chi_value >= chi_max:
		return EndType.PERFECT
	elif chi_value <= 0:
		return EndType.FAIL
	else:
		return EndType.NORMAL

func _end_game() -> void:
	if game_state == GameState.GAME_OVER:
		return
	game_state = GameState.GAME_OVER
	timer_running = false
	emit_signal("game_over", _get_end_type())

func calculate_stars() -> int:
	var pct: float = chi_value / chi_max
	if pct < 0.33:
		return 0
	elif pct < 0.66:
		return 1
	elif pct < 0.85:
		return 2
	else:
		return 3

func get_item_display_name(item_key: String) -> String:
	if item_key in INGREDIENTS:
		return INGREDIENTS[item_key]["name"]
	if item_key in CRAFTED_ITEMS:
		return CRAFTED_ITEMS[item_key]["name"]
	return item_key

func get_item_texture_path(item_key: String) -> String:
	if item_key in INGREDIENTS:
		return INGREDIENTS[item_key]["texture"]
	if item_key in CRAFTED_ITEMS:
		return CRAFTED_ITEMS[item_key]["texture"]
	return ""

func get_item_color(item_key: String) -> Color:
	if item_key in INGREDIENTS:
		return INGREDIENTS[item_key]["color"]
	if item_key in CRAFTED_ITEMS:
		return CRAFTED_ITEMS[item_key]["color"]
	return Color.WHITE

func format_time(seconds: float) -> String:
	var m: int = int(seconds) / 60
	var s: int = int(seconds) % 60
	return "%d:%02d" % [m, s]

func apply_click_bounce(node: Control) -> void:
	node.pivot_offset = node.size * 0.5
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", Vector2(0.85, 0.85), 0.1)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.15)
