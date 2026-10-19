class_name StampWetnessView
extends Control
## Transparent, canonical full-sheet mask for the SAME rubber/drag geometry.
## No new printable ink and no wall-clock: the owning desk supplies game time.

const PAPER_SIZE: Vector2 = Vector2(640, 400)
const UPDATE_INTERVAL: float = 0.05
var marks: Array = []
var _impressions: Array[RationStampImpression] = []
var _game_time: float = 0.0
var _last_render_time: float = -INF
var _wet_count: int = 0


func _init() -> void:
	size = PAPER_SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("ration_wet_ink")


func set_marks(source: Array) -> void:
	marks = source.duplicate(true)
	for impression: RationStampImpression in _impressions:
		impression.free()
	_impressions.clear()
	for mark: Variant in marks:
		if not mark is Dictionary:
			continue
		var created: float = float(mark.get("contact_time", -1.0))
		if not is_finite(created) or created < 0.0:
			continue
		var impression: RationStampImpression = RationStampImpression.new()
		impression.wet_mask = true
		impression.set_impression(mark)
		add_child(impression)
		_impressions.append(impression)
	_refresh(true)


func set_game_time(now: float) -> bool:
	if not is_finite(now) or now < 0.0:
		return false
	var previous: float = _game_time
	_game_time = now
	return _refresh(now < previous)


func wet_count() -> int:
	return _wet_count


func has_wet_ink() -> bool:
	return _wet_count > 0


func _refresh(force: bool = false) -> bool:
	var count: int = 0
	for impression: RationStampImpression in _impressions:
		if StampInkState.wetness(impression.impression, _game_time) > 0.0 and float(impression.features.get("density", 0.0)) > 0.0:
			count += 1
	var became_dry: bool = count == 0 and _wet_count > 0
	_wet_count = count
	if not force and not became_dry and _game_time - _last_render_time < UPDATE_INTERVAL:
		return false
	var changed: bool = force
	for impression: RationStampImpression in _impressions:
		changed = impression.set_game_time(_game_time) or changed
	if not changed:
		return false
	_last_render_time = _game_time
	if get_parent() is SubViewport:
		(get_parent() as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
	return true
