extends Node

# =============================================
# AUDIO MANAGER — Global Autoload
# Handles BGM, SFX, and baby siren triggers.
# Connects to GameManager.baby_woke / baby_silenced automatically.
# =============================================

var bgm_player: AudioStreamPlayer
var siren_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var deliver_player: AudioStreamPlayer

var bgm_enabled: bool = true
var sfx_enabled: bool = true


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	var stream: AudioStreamMP3 = load("res://assets/bgm/BGM.mp3") as AudioStreamMP3
	if stream:
		stream.loop = true
	bgm_player.stream = stream
	bgm_player.autoplay = true
	bgm_player.volume_db = -6.0
	add_child(bgm_player)
	bgm_player.finished.connect(func() -> void: bgm_player.play())
	bgm_player.play()

	siren_player = AudioStreamPlayer.new()
	siren_player.stream = load("res://assets/bgm/Baby Siren.wav")
	siren_player.volume_db = 0.0
	add_child(siren_player)

	click_player = AudioStreamPlayer.new()
	click_player.stream = load("res://assets/bgm/Click.wav")
	click_player.volume_db = 0.0
	add_child(click_player)

	deliver_player = AudioStreamPlayer.new()
	deliver_player.stream = load("res://assets/bgm/Deliver.wav")
	deliver_player.volume_db = 0.0
	add_child(deliver_player)

	GameManager.baby_woke.connect(_on_baby_woke)
	GameManager.baby_silenced.connect(_on_baby_silenced)


func play_click() -> void:
	if sfx_enabled and click_player:
		click_player.stop()
		click_player.play()


func play_deliver() -> void:
	if sfx_enabled and deliver_player:
		deliver_player.stop()
		deliver_player.play()


func play_siren() -> void:
	if sfx_enabled and siren_player and not siren_player.playing:
		siren_player.play()


func stop_siren() -> void:
	if siren_player:
		siren_player.stop()


func _on_baby_woke() -> void:
	play_siren()


func _on_baby_silenced() -> void:
	stop_siren()


func toggle_bgm() -> void:
	bgm_enabled = !bgm_enabled
	if bgm_enabled:
		bgm_player.volume_db = -6.0
		if not bgm_player.playing:
			bgm_player.play()
	else:
		bgm_player.volume_db = -80.0


func toggle_sfx() -> void:
	sfx_enabled = !sfx_enabled
	if not sfx_enabled:
		siren_player.stop()
