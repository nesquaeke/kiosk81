extends TestCase

const Ink: GDScript = preload("res://scenes/kiosk/stamp_ink_state.gd")


func test_hovering_and_approaching_the_pad_never_refill_or_bank_time() -> void:
	var stamp: RefCounted = Ink.new(0.25)
	assert_eq(stamp.advance_pad(30.0), 0.25)
	stamp.set_pad_contact(true)
	stamp.advance_pad(0.1)
	var brief_contact: float = stamp.load
	assert_true(brief_contact > 0.25 and brief_contact < 0.5)
	stamp.set_pad_contact(false)
	assert_eq(stamp.advance_pad(60.0), brief_contact, "leaving the pad immediately stops absorption")
	stamp.set_pad_contact(true)
	assert_eq(stamp.advance_pad(0.0), brief_contact, "hover time cannot become ink on next contact")


func test_longer_actual_pad_dwell_loads_more_without_overflow() -> void:
	var brief: RefCounted = Ink.new(0.1)
	var held: RefCounted = Ink.new(0.1)
	brief.set_pad_contact(true)
	held.set_pad_contact(true)
	brief.advance_pad(0.08)
	held.advance_pad(0.7)
	assert_true(held.load > brief.load)
	assert_true(held.load > 0.8 and held.load < 1.0)
	held.advance_pad(1000.0)
	assert_eq(held.load, 1.0)


func test_pad_absorption_depends_on_elapsed_contact_time_not_render_frames() -> void:
	var fast: RefCounted = Ink.new(0.15)
	var slow: RefCounted = Ink.new(0.15)
	fast.set_pad_contact(true)
	slow.set_pad_contact(true)
	for frame: int in 120:
		fast.advance_pad(1.0 / 120.0)
	for frame: int in 20:
		slow.advance_pad(1.0 / 20.0)
	assert_true(absf(fast.load - slow.load) < 0.0000001)


func test_paper_contact_returns_one_fixed_snapshot_and_debits_only_once() -> void:
	var stamp: RefCounted = Ink.new(0.75)
	var initial: float = stamp.begin_paper_contact()
	var after: float = stamp.load
	assert_eq(initial, 0.75)
	assert_true(after < initial)
	for frame: int in 600:
		assert_eq(stamp.begin_paper_contact(), initial, "ten seconds of held pressure remain one physical mark")
	assert_eq(stamp.load, after)
	stamp.end_contact()
	assert_eq(stamp.begin_paper_contact(), after, "a new physical contact snapshots the remaining reservoir")
	assert_true(stamp.load < after)


func test_one_default_reservoir_supports_the_full_sixteen_customer_shift() -> void:
	var stamp: RefCounted = Ink.new()
	for customer: int in 16:
		var transferred: float = stamp.begin_paper_contact()
		assert_true(transferred > 0.55, "normal duty must not require visiting the pad for every customer")
		stamp.end_contact()
	assert_true(stamp.load > 0.55)


func test_empty_rubber_cannot_create_extra_ink_and_repad_restores_it() -> void:
	var stamp: RefCounted = Ink.new(0.005)
	assert_eq(stamp.begin_paper_contact(), 0.005)
	assert_eq(stamp.load, 0.0)
	stamp.end_contact()
	assert_eq(stamp.begin_paper_contact(), 0.0)
	assert_eq(stamp.load, 0.0)
	stamp.set_pad_contact(true)
	stamp.advance_pad(0.5)
	var refilled: float = stamp.load
	assert_true(refilled > 0.6)
	assert_eq(stamp.begin_paper_contact(), refilled, "pad-to-paper transfer starts a fresh snapshot")


func test_reservoirs_are_independent_and_an_aborted_approach_does_not_consume() -> void:
	var approve: RefCounted = Ink.new()
	var reject: RefCounted = Ink.new()
	approve.end_contact()
	assert_eq(approve.load, 0.75)
	approve.begin_paper_contact()
	assert_true(approve.load < reject.load)
	approve.end_contact()
	approve.set_pad_contact(true)
	approve.advance_pad(1.0)
	assert_eq(reject.load, 0.75, "different stamp bodies do not share ink")


func test_cancel_and_reset_clear_contact_latches_without_creating_a_mark() -> void:
	var stamp: RefCounted = Ink.new(0.2)
	stamp.begin_paper_contact()
	stamp.reset()
	assert_eq(stamp.load, 0.75)
	assert_eq(stamp.advance_pad(10.0), 0.75)
	assert_eq(stamp.begin_paper_contact(), 0.75, "restart cannot reuse a stale contact snapshot")
	stamp.reset(0.3)
	assert_eq(stamp.begin_paper_contact(), 0.3)


func test_invalid_time_and_load_cannot_poison_subsequent_contacts() -> void:
	var stamp: RefCounted = Ink.new(NAN)
	assert_eq(stamp.load, 0.75)
	stamp.set_pad_contact(true)
	for elapsed: float in [-1.0, INF, NAN]:
		assert_eq(stamp.advance_pad(elapsed), 0.75)
	stamp.load = 12.0
	assert_eq(stamp.load, 1.0)
	stamp.load = -1.0
	assert_eq(stamp.load, 0.0)
	stamp.load = NAN
	assert_eq(stamp.load, 0.75)


func test_wet_ink_loses_sheen_monotonically_then_stays_dry() -> void:
	var previous: float = 1.0
	var mark: Dictionary = {"contact_time": 4.0, "ink_load": 0.75, "dry_duration": 11.0}
	assert_eq(Ink.wetness(mark, 4.0), 1.0)
	for step: int in 240:
		var wet: float = Ink.wetness(mark, 4.0 + float(step) * 0.1)
		assert_true(wet <= previous and wet >= 0.0)
		previous = wet
	assert_eq(Ink.wetness(mark, 16.0), 0.0)
	assert_eq(Ink.wetness(mark, 100000.0), 0.0)


func test_heavier_ink_load_keeps_its_liquid_sheen_longer() -> void:
	assert_true(Ink.drying_duration(0.1) >= 8.0)
	assert_true(Ink.drying_duration(1.0) <= 12.0)
	assert_true(Ink.wetness({"contact_time": 0.0, "ink_load": 0.9}, 8.5) > Ink.wetness({"contact_time": 0.0, "ink_load": 0.1}, 8.5))
	assert_eq(Ink.wetness({"contact_time": 0.0, "ink_load": 0.1}, 8.5), 0.0)


func test_legacy_or_invalid_timestamps_stay_dry_and_paused_time_is_stable() -> void:
	assert_eq(Ink.wetness({}, 12.0), 0.0, "old saved marks without a contact time must not rewet")
	assert_eq(Ink.wetness({"contact_time": NAN}, 12.0), 0.0)
	assert_eq(Ink.wetness({"contact_time": 0.0}, INF), 0.0)
	assert_eq(Ink.wetness({"contact_time": 0.0}, -1.0), 0.0)
	var mark: Dictionary = {"contact_time": 10.0}
	var paused: float = Ink.wetness(mark, 13.0)
	for render: int in 120:
		assert_eq(Ink.wetness(mark, 13.0), paused, "renderer frames alone never advance game drying")
	assert_eq(Ink.wetness(mark, 9.0), 1.0, "a corrected earlier clock never exceeds fully wet")


func test_persisted_drying_duration_is_authoritative_and_reading_never_mutates_mark() -> void:
	var mark: Dictionary = {"contact_time": 3.0, "dry_duration": 8.0, "ink_load": 1.0, "serial": 4}
	var snapshot: Dictionary = mark.duplicate(true)
	assert_eq(Ink.wetness(mark, 11.0), 0.0, "persisted duration wins over later or inconsistent reservoir load")
	assert_eq(mark, snapshot)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(mark))
	assert_eq(Ink.wetness(mark, 7.0), Ink.wetness(restored, 7.0))
	for malformed: Dictionary in [{"contact_time": "now"}, {"contact_time": false}, {"contact_time": null}]:
		assert_eq(Ink.wetness(malformed, 1.0), 0.0)
	assert_eq(Ink.wetness({"contact_time": 0.0, "dry_duration": 0.0}, 8.0), 0.0)
	assert_true(is_finite(Ink.wetness({"contact_time": 0.0, "dry_duration": NAN, "ink_load": NAN}, 1.0)))
