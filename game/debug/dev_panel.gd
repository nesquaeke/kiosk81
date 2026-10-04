extends CanvasLayer
## Developer panel (autoload, roadmap 1.12). F3 shows the live campaign state,
## the recent decisions and the content status. Debug builds only: in a
## release export it removes itself on start.

const MAX_DECISIONS: int = 8

var _panel: PanelContainer
var _text: Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.position = Vector2(16, 16)
	_panel.visible = false
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.06, 0.86)
	style.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 16)
	_text.add_theme_color_override("font_color", Color("#d4dad8"))
	_panel.add_child(_text)
	Game.state_changed.connect(func(_s: CampaignState) -> void: _refresh())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_panel"):
		_panel.visible = not _panel.visible
		_refresh()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _panel != null and _panel.visible


func _refresh() -> void:
	if _panel == null or not _panel.visible:
		return
	_text.text = describe(Game.state)


## Plain-text summary of a state; also used by tests.
static func describe(s: CampaignState) -> String:
	var lines: PackedStringArray = []
	lines.append("DAY %d · %s · %02d:%02d · %s" % [s.day, s.calendar_date, s.minute_of_day / 60, s.minute_of_day % 60, s.phase])
	var money: PackedStringArray = []
	for account: String in CampaignState.ACCOUNTS:
		money.append("%s %s" % [account, Money.format(s.money.get(account, 0))])
	lines.append("MONEY  " + "  |  ".join(money))
	for location: String in CampaignState.STOCK_LOCATIONS:
		var items: Dictionary = s.stock[location]
		var parts: PackedStringArray = []
		for item_id: Variant in items:
			parts.append("%s ×%d" % [str(item_id).trim_prefix("itm_"), int(items[item_id])])
		lines.append("%-8s %s" % [location.to_upper(), ", ".join(parts) if not parts.is_empty() else "-"])
	for character_id: String in s.characters:
		var c: Dictionary = s.characters[character_id]
		var rel: Dictionary = c.get("relations", {})
		var rel_parts: PackedStringArray = []
		for dim: String in CampaignState.RELATIONS:
			if int(rel.get(dim, 0)) != 0:
				rel_parts.append("%s %+d" % [dim, int(rel[dim])])
		lines.append("%s [%s] %s · %d memories" % [character_id, c.get("status", "active"), ", ".join(rel_parts), (c.get("memories", []) as Array).size()])
	if not s.flags.is_empty():
		var flag_parts: PackedStringArray = []
		for key: String in s.flags:
			flag_parts.append("%s=%s" % [key, str(s.flags[key])])
		lines.append("FLAGS  " + ", ".join(flag_parts))
	var first: int = maxi(0, s.decision_log.size() - MAX_DECISIONS)
	for i: int in range(first, s.decision_log.size()):
		var d: Dictionary = s.decision_log[i]
		lines.append("  day %d %02d:%02d  %s" % [int(d.get("day", 0)), int(d.get("minute", 0)) / 60, int(d.get("minute", 0)) % 60, str(d.get("id", d))])
	lines.append("REGISTER %d entries · F3 to close" % s.register.size())
	return "\n".join(lines)
