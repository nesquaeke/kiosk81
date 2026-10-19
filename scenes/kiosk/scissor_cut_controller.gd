class_name ScissorCutController
extends RefCounted
## Paper-space scissors motion. Opening/turning never spends cutting travel.
## One canonical 640 px card is 0.36 m wide; no coupon-edge inference is used.

const PIXELS_PER_METRE: float = 640.0 / 0.36
const TURN_THRESHOLD: float = deg_to_rad(35.0)
const TURN_DISTANCE: float = 2.0
const TURN_SPEED: float = deg_to_rad(240.0)
const REOPEN_TIME: float = 0.12
const OPEN_JAW: float = 0.54
const FINE_SPEED: float = 0.35
const EPSILON: float = 0.000001

var tip: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var stroke: ScissorStroke = ScissorStroke.new()
var aligning: bool = false
var active: bool = false

var _opening_elapsed: float = 0.0
var _opening_jaw: float = 0.04
var _turn_target: Vector2 = Vector2.RIGHT


func start(pixel: Vector2, heading: Vector2 = Vector2.RIGHT) -> void:
	reset()
	tip = pixel if pixel.is_finite() else Vector2.ZERO
	if heading.is_finite() and heading.length_squared() > EPSILON:
		direction = heading.normalized()
	active = true


func release() -> void:
	# Preserve the final tip for the caller's persistent incision; discard timing.
	active = false
	aligning = false
	stroke.elapsed = 0.0
	_opening_elapsed = 0.0


func reset() -> void:
	tip = Vector2.ZERO
	direction = Vector2.RIGHT
	stroke = ScissorStroke.new()
	aligning = false
	active = false
	_opening_elapsed = 0.0
	_opening_jaw = 0.04
	_turn_target = Vector2.RIGHT


func advance(delta: float, target: Vector2, fine: bool = false) -> float:
	if not active or delta <= 0.0 or not is_finite(delta) or not target.is_finite():
		return 0.0
	var time: float = delta * (FINE_SPEED if fine else 1.0)
	var difference: Vector2 = target - tip
	var distance: float = difference.length()
	if distance <= EPSILON:
		# Stationary blades may animate, but cannot accumulate travel for later.
		if not aligning: stroke.advance(time, false)
		return 0.0
	var desired: Vector2 = difference / distance
	if aligning:
		_turn_target = desired
	elif distance > TURN_DISTANCE and absf(direction.angle_to(desired)) > TURN_THRESHOLD:
		_opening_elapsed = 0.0
		_opening_jaw = stroke.jaw_angle()
		_turn_target = desired
		aligning = true
	if aligning:
		time = _advance_alignment(time)
		if aligning or time <= EPSILON:
			return 0.0
	# Gentle corrections follow the actual incision. A large corner was dealt with
	# above while the tip stayed fixed, before either blade could close on paper.
	direction = desired
	var budget: float = stroke.advance(time, true) * PIXELS_PER_METRE
	var travelled: float = minf(distance, maxf(0.0, budget))
	if travelled > 0.0:
		tip = target if travelled >= distance else tip + direction * travelled
	return travelled


func jaw_angle() -> float:
	if aligning:
		return lerpf(_opening_jaw, OPEN_JAW, smoothstep(0.0, REOPEN_TIME, _opening_elapsed))
	return stroke.jaw_angle()


func cycle() -> int:
	return stroke.cycle()


func _advance_alignment(time: float) -> float:
	# Consume exact event times instead of one frame per state. A 20 FPS render
	# therefore reaches the same physical point as 60 FPS for the same targets.
	var opening: float = minf(time, maxf(0.0, REOPEN_TIME - _opening_elapsed))
	_opening_elapsed += opening
	time -= opening
	if _opening_elapsed < REOPEN_TIME - EPSILON:
		return 0.0
	var angle: float = direction.angle_to(_turn_target)
	var turning: float = absf(angle) / TURN_SPEED
	if turning > time + EPSILON:
		direction = direction.rotated(signf(angle) * TURN_SPEED * time).normalized()
		return 0.0
	direction = _turn_target
	time = maxf(0.0, time - turning)
	aligning = false
	# The jaw is visibly open. Resume at the start of a fresh closing stroke,
	# never reuse a half-closed cycle or emit another cut in its old sound cycle.
	var current_cycle: int = stroke.cycle()
	if fmod(stroke.elapsed, ScissorStroke.PERIOD) >= ScissorStroke.CLOSE_START - EPSILON:
		current_cycle += 1
	stroke.elapsed = current_cycle * ScissorStroke.PERIOD + ScissorStroke.CLOSE_START
	return time
