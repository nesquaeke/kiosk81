class_name ScissorStroke
extends RefCounted
## Cutting advances only during the closing part of a visible scissors stroke.
const PERIOD: float = 0.42
const CLOSE_START: float = 0.12
const CLOSE_END: float = 0.34
const CLOSING_SPEED: float = 0.16
var elapsed: float = 0.0

func advance(delta: float, engaged: bool) -> float:
	var previous: float = elapsed
	elapsed += maxf(0.0, delta)
	return (_closing_time(elapsed) - _closing_time(previous)) * CLOSING_SPEED if engaged else 0.0

func jaw_angle() -> float:
	var phase: float = fmod(elapsed, PERIOD)
	if phase < CLOSE_START:
		return lerpf(0.04, 0.54, smoothstep(0.0, CLOSE_START, phase))
	if phase < CLOSE_END:
		return lerpf(0.54, 0.0, smoothstep(CLOSE_START, CLOSE_END, phase))
	return 0.0

func cycle() -> int:
	return int(floor(elapsed / PERIOD))

func _closing_time(time: float) -> float:
	return floor(time / PERIOD) * (CLOSE_END - CLOSE_START) + clampf(fmod(time, PERIOD) - CLOSE_START, 0.0, CLOSE_END - CLOSE_START)
