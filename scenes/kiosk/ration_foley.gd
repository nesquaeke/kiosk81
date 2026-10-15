class_name RationFoley
extends Node
## Original procedural placeholders. A contact sound is never used as a verdict cue.

const NAMES: PackedStringArray = ["paper_pick", "paper_flip", "paper_place", "snip", "stamp_down", "stamp_lift", "coupon_drop", "drawer", "package_meat_pick", "package_meat_place", "package_sugar_pick", "package_sugar_place", "package_soap_pick", "package_soap_place"]
var streams: Dictionary[String, AudioStream] = {}
var players: Array[AudioStreamPlayer] = []
var events: PackedStringArray = []
var gain_db: float = -5.0
var _next: int = 0
var _silent_output: bool = false


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	var driver: int = args.find("--audio-driver")
	_silent_output = DisplayServer.get_name() == "headless" or (driver >= 0 and driver + 1 < args.size() and args[driver + 1].to_lower() == "dummy")
	for name: String in NAMES:
		streams[name] = load("res://assets/audio/ration/%s.wav" % name) as AudioStream
	for i: int in 4:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)


func play_sound(name: String) -> void:
	if not streams.has(name) or players.is_empty():
		return
	var player: AudioStreamPlayer = players[_next % players.size()]
	_next += 1
	player.stop()
	player.stream = streams[name]
	player.volume_db = gain_db
	player.pitch_scale = randf_range(0.96, 1.04)
	if not _silent_output:
		player.play()
	events.append(name)
	if events.size() > 128:
		events.remove_at(0)


func play_package(contact: String, item: String) -> void:
	# Caller chooses the real grip/surface contact, not the initial button press.
	if contact not in ["pick", "place"] or item not in ["meat", "sugar", "soap"]:
		return
	play_sound("package_%s_%s" % [item, contact])


func set_level(value: float) -> void:
	gain_db = linear_to_db(value) if value > 0 else -80.0
	for player: AudioStreamPlayer in players:
		player.volume_db = gain_db


func stop_all() -> void:
	for player: AudioStreamPlayer in players:
		player.stop()
		player.stream = null


func _exit_tree() -> void:
	stop_all()
	streams.clear()
