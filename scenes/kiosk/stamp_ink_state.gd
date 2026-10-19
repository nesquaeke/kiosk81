class_name StampInkState
extends RefCounted
## One rubber stamp's finite ink reservoir. No campaign state, render clock or
## authenticity data is read here. The caller owns actual physical contacts.

const INITIAL_LOAD: float = 0.75
const PAPER_USE: float = 0.012
const PAD_ABSORPTION_RATE: float = 2.2
const MIN_DRYING_SECONDS: float = 8.0
const MAX_DRYING_SECONDS: float = 12.0

var load: float = INITIAL_LOAD:
	set(value):
		load = _unit(value, INITIAL_LOAD)

var _pad_contact: bool = false
var _paper_contact: bool = false
var _contact_load: float = 0.0


func _init(initial_load: float = INITIAL_LOAD) -> void:
	reset(initial_load)


func reset(initial_load: float = INITIAL_LOAD) -> void:
	load = initial_load
	end_contact()


## Start only when the rubber face actually meets the ink pad, never when an
## approach animation starts. Leaving a pad cannot release a paper impression.
func set_pad_contact(touching: bool) -> void:
	if touching:
		_paper_contact = false
		_contact_load = 0.0
	_pad_contact = touching


## Exponential absorption is independent of contact frame rate and saturates
## without overflowing. Time spent approaching or hovering is not banked.
func advance_pad(delta: float) -> float:
	if _pad_contact and is_finite(delta) and delta > 0.0:
		load = 1.0 - (1.0 - load) * exp(-PAD_ABSORPTION_RATE * delta)
	return load


## Snapshot ink at the FIRST paper contact. Continued pressure may develop the
## mark but never consumes another reservoir debit or changes that snapshot.
func begin_paper_contact() -> float:
	if not _paper_contact:
		_pad_contact = false
		_paper_contact = true
		_contact_load = load
		load -= PAPER_USE
	return _contact_load


func end_contact() -> void:
	_pad_contact = false
	_paper_contact = false
	_contact_load = 0.0


static func drying_duration(ink_load: float = INITIAL_LOAD) -> float:
	return lerpf(MIN_DRYING_SECONDS, MAX_DRYING_SECONDS, _unit(ink_load, INITIAL_LOAD))


## A persisted contact timestamp in the caller's game-time domain. Missing
## legacy timestamps render dry. Pause/inspection must pass the same
## game time: shader TIME or wall-clock time would dry an otherwise paused game.
## The persisted drying duration is authoritative, independent of later reservoir
## changes. This function only reads its input; printing/save data is immutable.
static func wetness(mark: Dictionary, game_time: float) -> float:
	var created_at: float = _finite_number(mark.get("contact_time", -1.0), -1.0)
	if not is_finite(created_at) or not is_finite(game_time) or created_at < 0.0 or game_time < 0.0:
		return 0.0
	var ink_load: float = _finite_number(mark.get("ink_load", INITIAL_LOAD), INITIAL_LOAD)
	var duration: float = clampf(_finite_number(mark.get("dry_duration", drying_duration(ink_load)), drying_duration(ink_load)), MIN_DRYING_SECONDS, MAX_DRYING_SECONDS)
	var fraction: float = clampf((game_time - created_at) / duration, 0.0, 1.0)
	# Smoothly lose the liquid sheen, then stay exactly dry forever. A corrected
	# clock earlier than creation cannot produce a value greater than fully wet.
	return 1.0 - fraction * fraction * (3.0 - 2.0 * fraction)


static func _unit(value: float, fallback: float) -> float:
	return clampf(value, 0.0, 1.0) if is_finite(value) else fallback


static func _finite_number(value: Variant, fallback: float) -> float:
	if (value is float or value is int) and is_finite(float(value)):
		return float(value)
	return fallback
