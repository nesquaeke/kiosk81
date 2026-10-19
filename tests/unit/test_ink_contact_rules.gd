extends TestCase
## Physical ink transfer is independent of the document's truth and decision.

var rules: RationDeskRules
var state: CampaignState


func before_each() -> void:
	rules = RationDeskRules.new(ContentDB.all_of("ration_case"))
	state = CampaignState.from_dict(rules.opening(true))


func _apply(command: Dictionary) -> bool:
	if not command["ok"]:
		return false
	var effects: Array[Dictionary] = []
	effects.assign(command["effects"])
	var result: EffectPipeline.Result = EffectPipeline.apply(state, effects)
	assert_true(result.ok, result.error)
	if result.ok:
		state = result.state
	return result.ok


func _place() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))


func _wet_contact(position: Vector2 = Vector2(540, 190), angle: float = 0.0) -> void:
	assert_true(_apply(rules.stamp(state, "reject", position, true,
		{"contact_time": RationDeskRules.desk(state).get("ink_clock", 0),
		"ink_load": 0.8, "tilt": -0.12, "dry_duration": 10.0, "angle": angle})))


func _mark(index: int = 0) -> Dictionary:
	return RationDeskRules.desk(state)["marks"][index]


func _assert_rejected(command: Dictionary, before: Dictionary) -> void:
	assert_false(command["ok"])
	assert_eq(command["effects"], [])
	assert_eq(state.to_dict(), before, "rejected contact cannot partially mutate the campaign")


func test_legacy_contact_stays_fully_inked_and_dry_without_a_timestamp() -> void:
	assert_eq(RationDeskRules.desk(state)["ink_clock"], 0)
	_place()
	assert_true(_apply(rules.stamp(state, "reject", Vector2(540, 190), true)))
	assert_eq(_mark()["ink_load"], 1)
	assert_eq(_mark()["tilt"], 0)
	assert_eq(_mark()["contact_time"], -1)
	assert_eq(_mark()["dry_duration"], 10)
	_assert_rejected(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(560, 190)), state.to_dict())


func test_new_contact_is_finite_bounded_and_cannot_start_in_the_future() -> void:
	assert_true(_apply(rules.advance_ink_time(state, 2.25)))
	_place()
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true,
		{"ink_load": 3.0, "tilt": -8.0, "contact_time": 999.0, "dry_duration": 1.0})))
	assert_eq(_mark()["ink_load"], 1)
	assert_eq(_mark()["tilt"], -0.3)
	assert_eq(_mark()["contact_time"], 2.25)
	assert_eq(_mark()["dry_duration"], 8)
	assert_true(_apply(rules.stamp(state, "reject", Vector2(540, 190), true,
		{"ink_load": NAN, "tilt": INF, "contact_time": -0.5, "dry_duration": NAN})))
	assert_eq(_mark(1)["ink_load"], 1)
	assert_eq(_mark(1)["tilt"], 0)
	assert_eq(_mark(1)["contact_time"], -1)
	assert_eq(_mark(1)["dry_duration"], 10)
	assert_true(_apply(rules.stamp(state, "seize", Vector2(540, 190), true,
		{"ink_load": "wet", "tilt": true, "contact_time": INF, "dry_duration": 100.0})))
	assert_eq(_mark(2)["ink_load"], 1)
	assert_eq(_mark(2)["tilt"], 0)
	assert_eq(_mark(2)["contact_time"], -1)
	assert_eq(_mark(2)["dry_duration"], 12)
	var before: Dictionary = state.to_dict()
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(before)))
	assert_eq(state.to_dict(), before)


func test_empty_rubber_does_not_make_a_decision_but_faint_ink_is_still_a_decision() -> void:
	_place()
	var before: Dictionary = state.to_dict()
	_assert_rejected(rules.stamp(state, "approve", Vector2(540, 190), true, {"ink_load": 0}), before)
	_assert_rejected(rules.stamp(state, "approve", Vector2(540, 190), true, {"ink_load": -1}), before)
	assert_eq(RationDeskRules.desk(state)["stamp"], "")
	assert_eq(RationDeskRules.desk(state)["marks"], [])
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true, {"ink_load": 0.01})))
	assert_eq(RationDeskRules.desk(state)["stamp"], "approve")
	assert_eq(_mark()["ink_load"], 0.01)


func test_ink_amount_does_not_block_a_wrong_decision_on_a_forged_card() -> void:
	state.flags[RationDeskRules.KEY]["index"] = 3
	assert_true(RationDeskRules.is_forged(rules.current(state)))
	_place()
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true, {"ink_load": 0.01})))
	assert_eq(RationDeskRules.desk(state)["stamp"], "approve", "the physical mechanism must not reveal guilt")


func test_developing_a_contact_never_reloads_it_or_restarts_its_drying_clock() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.advance_ink_time(state, 3.0)))
	var initial: Dictionary = _mark().duplicate(true)
	assert_true(_apply(rules.update_impression(state, 1,
		{"ink_load": 1, "contact_time": 3, "dry_duration": 12, "tilt": 0.3,
		"dwell": 0.9, "pressure": 0.88, "smudge": 0.004, "smudge_direction": [0, -1]})))
	for field: String in ["ink_load", "contact_time", "dry_duration", "tilt", "kind", "x", "y", "serial"]:
		assert_eq(_mark()[field], initial[field], "the first contact owns %s" % field)
	assert_eq(_mark()["dwell"], 0.9)
	assert_eq(_mark()["pressure"], 0.88)
	assert_eq(_mark()["smudge"], 0.004)
	assert_eq(_mark()["smudge_direction"], [0, -1])
	assert_eq(RationDeskRules.desk(state)["ink_clock"], 3)


func test_clock_runs_between_customers_preserves_audits_and_caps_each_tick() -> void:
	assert_true(_apply(rules.advance_ink_time(state, 0.25)), "intake still has a shift clock")
	_place()
	_wet_contact()
	var contact: Dictionary = _mark().duplicate(true)
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	assert_true(_apply(rules.advance_ink_time(state, 1000000.0)))
	assert_eq(RationDeskRules.desk(state)["ink_clock"], 60.25)
	assert_eq(RationDeskRules.desk(state)["results"][0]["marks"][0], contact)
	assert_true(_apply(rules.next(state)))
	assert_eq(RationDeskRules.desk(state)["ink_clock"], 60.25)
	assert_eq(RationDeskRules.desk(state)["marks"], [])
	assert_eq(RationDeskRules.desk(state)["results"][0]["marks"][0], contact)
	assert_true(_apply(rules.advance_ink_time(state, 0)))
	assert_eq(RationDeskRules.desk(state)["ink_clock"], 60.25)


func test_clock_rejects_nonfinite_negative_and_nonnumeric_ticks_without_effects() -> void:
	var before: Dictionary = state.to_dict()
	for invalid: Variant in [NAN, INF, -INF, -0.01, "2", true, null]:
		_assert_rejected(rules.advance_ink_time(state, invalid), before)
	(state.flags[RationDeskRules.KEY] as Dictionary).erase("ink_clock")
	assert_true(_apply(rules.advance_ink_time(state, 0.25)))
	assert_eq(RationDeskRules.desk(state)["ink_clock"], 0.25, "older saves acquire a finite shift clock")


func test_wet_rub_adds_only_local_damage_and_replaying_same_contact_is_idempotent() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.advance_ink_time(state, 2.5)))
	var before: Dictionary = state.to_dict()
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(580, 190))))
	var rub: Dictionary = _mark()["rubs"][0]
	assert_eq(rub["from"], [-20, 0])
	assert_eq(rub["to"], [40, 0])
	assert_eq(rub["wetness"], 0.75)
	var expected: Dictionary = before.duplicate(true)
	expected["flags"][RationDeskRules.KEY]["marks"][0]["rubs"] = [rub]
	assert_eq(state.to_dict(), expected, "rubbing cannot create a verdict, money, stock or another contact")
	var after: Dictionary = state.to_dict()
	_assert_rejected(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(580, 190)), after)
	assert_true(_apply(rules.update_impression(state, 1, {"rubs": [], "dwell": 1.0})))
	assert_eq(_mark()["rubs"], [rub], "continued rubber pressure cannot erase later damage")


func test_rotated_stamp_keeps_actual_finger_direction_in_its_local_coordinates() -> void:
	_place()
	_wet_contact(Vector2(540, 190), PI / 2.0)
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(540, 170), Vector2(540, 230))))
	var rub: Dictionary = _mark()["rubs"][0]
	assert_true(Vector2(float(rub["from"][0]), float(rub["from"][1])).distance_to(Vector2(-20, 0)) < 0.00001)
	assert_true(Vector2(float(rub["to"][0]), float(rub["to"][1])).distance_to(Vector2(40, 0)) < 0.00001)
	assert_eq(_mark()["angle"], CampaignState.normalize_numbers(JSON.parse_string(JSON.stringify(PI / 2.0))))
	var before: Dictionary = state.to_dict()
	_assert_rejected(rules.smear_wet_ink(state, Vector2(480, 130), Vector2(480, 250)), before)


func test_rub_clips_sheet_exit_and_omits_travel_before_first_print_contact() -> void:
	_place()
	_wet_contact(Vector2(600, 190))
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(500, 190), Vector2(800, 190))))
	var rub: Dictionary = _mark()["rubs"][0]
	assert_eq(rub["from"], [-71, 0], "the 6 px finger radius touches before its centre enters the 130 px rubber face")
	assert_eq(rub["to"], [40, 0], "the fingertip stops at the real sheet edge, not at the off-sheet mouse target")


func test_dry_contacts_cannot_be_smeared_or_refreshed_by_pressure() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.advance_ink_time(state, 10)))
	assert_true(_apply(rules.update_impression(state, 1, {"contact_time": 10, "dry_duration": 12, "dwell": 1.5})))
	assert_eq(_mark()["contact_time"], 0)
	_assert_rejected(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(580, 190)), state.to_dict())
	assert_false(_mark().has("rubs"))


func test_invalid_or_off_print_finger_gestures_are_atomic() -> void:
	_place()
	_wet_contact()
	var before: Dictionary = state.to_dict()
	for path: Array in [
		[Vector2(520, 190), Vector2(520, 190)],
		[Vector2(520, 190), Vector2(520.01, 190)],
		[Vector2(520, 190), Vector2(10000, 190)],
		[Vector2(-5, 190), Vector2(580, 190)],
		[Vector2(NAN, 190), Vector2(580, 190)],
		[Vector2(520, 190), Vector2(INF, 190)],
		[Vector2(20, 20), Vector2(180, 20)],
	]:
		_assert_rejected(rules.smear_wet_ink(state, path[0], path[1]), before)


func test_rub_can_contact_several_wet_marks_without_moving_or_redeciding_them() -> void:
	_place()
	_wet_contact()
	_wet_contact(Vector2(540, 190), PI / 2.0)
	var before: Dictionary = state.to_dict()
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(540, 175), Vector2(550, 200))))
	for index: int in 2:
		var initial: Dictionary = before["flags"][RationDeskRules.KEY]["marks"][index]
		var developed: Dictionary = _mark(index).duplicate(true)
		assert_eq(developed["rubs"].size(), 1)
		developed.erase("rubs")
		assert_eq(developed, initial)
	assert_eq(RationDeskRules.desk(state)["stamp"], "reject")
	assert_eq(RationDeskRules.desk(state)["marks"].size(), 2)
	var damaged: Dictionary = state.to_dict()
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(damaged)))
	assert_eq(state.to_dict(), damaged, "wet damage survives a save without moving or rerolling")


func test_rub_history_is_bounded_and_never_discards_previous_strokes() -> void:
	_place()
	_wet_contact()
	for index: int in RationDeskRules.MAX_INK_RUBS:
		assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(550 + index * 0.1, 190))))
	assert_eq(_mark()["rubs"].size(), RationDeskRules.MAX_INK_RUBS)
	var before: Dictionary = state.to_dict()
	_assert_rejected(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(590, 190)), before)
	assert_eq(_mark()["rubs"].size(), RationDeskRules.MAX_INK_RUBS)


func test_held_or_completed_card_cannot_receive_postlift_finger_damage() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.move_card(state, "hand")))
	_assert_rejected(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(580, 190)), state.to_dict())
	assert_true(_apply(rules.finish_review(state, "return")))
	_assert_rejected(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(580, 190)), state.to_dict())


func test_live_collinear_samples_extend_one_path_without_refreshing_its_initial_wetness() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(530, 190), 7)))
	var first: Dictionary = _mark()["rubs"][0].duplicate(true)
	assert_true(_apply(rules.advance_ink_time(state, 2)))
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(530, 190), Vector2(550, 190), 7)))
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(550, 190), Vector2(610, 190), 7)))
	# The same finger carries its picked-up ink beyond the original rubber face.
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(610, 190), Vector2(635, 190), 7)))
	assert_eq(_mark()["rubs"].size(), 1)
	assert_eq(_mark()["rubs"][0]["from"], first["from"])
	assert_eq(_mark()["rubs"][0]["to"], [95, 0])
	assert_eq(_mark()["rubs"][0]["wetness"], first["wetness"])
	assert_eq(_mark()["rubs"][0]["gesture_id"], 7)


func test_live_turns_reversals_and_discontinuities_preserve_separate_actual_paths() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(540, 190), 7)))
	var first: Dictionary = _mark()["rubs"][0].duplicate(true)
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(540, 190), Vector2(540, 210), 7)))
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(540, 210), Vector2(540, 190), 7)))
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(545, 190), Vector2(545, 180), 7)))
	assert_eq(_mark()["rubs"].size(), 4)
	assert_eq(_mark()["rubs"][0], first)
	assert_eq(_mark()["rubs"][1]["from"], [0, 0])
	assert_eq(_mark()["rubs"][1]["to"], [0, 20])
	assert_eq(_mark()["rubs"][2]["to"], [0, 0])
	assert_eq(_mark()["rubs"][3]["from"], [5, 0])


func test_live_drying_rejects_later_motion_without_erasing_earlier_committed_ink() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(540, 190), 7)))
	var first: Dictionary = _mark().duplicate(true)
	assert_true(_apply(rules.advance_ink_time(state, 10)))
	_assert_rejected(rules.smear_wet_ink(state, Vector2(540, 190), Vector2(560, 190), 7), state.to_dict())
	assert_eq(_mark(), first, "holding a finger until dry cannot undo its earlier wet drag")


func test_live_new_gesture_never_overwrites_another_gesture_or_reopens_old_history() -> void:
	_place()
	_wet_contact()
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(530, 190), 7)))
	var first: Dictionary = _mark()["rubs"][0].duplicate(true)
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(530, 190), Vector2(540, 190), 8)))
	var second: Dictionary = _mark()["rubs"][1].duplicate(true)
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(540, 190), Vector2(550, 190), 7)))
	assert_eq(_mark()["rubs"].size(), 3)
	assert_eq(_mark()["rubs"][0], first)
	assert_eq(_mark()["rubs"][1], second)
	var before: Dictionary = state.to_dict()
	_assert_rejected(rules.smear_wet_ink(state, Vector2(550, 190), Vector2(560, 190), -1), before)
	_assert_rejected(rules.smear_wet_ink(state, Vector2(550, 190), Vector2(560, 190), 2147483648), before)


func test_live_path_can_extend_at_history_limit_but_cannot_append_a_new_path() -> void:
	_place()
	_wet_contact()
	for index: int in RationDeskRules.MAX_INK_RUBS:
		assert_true(_apply(rules.smear_wet_ink(state, Vector2(520, 190), Vector2(550, 190), index + 1)))
	var first: Dictionary = _mark()["rubs"][0].duplicate(true)
	assert_true(_apply(rules.smear_wet_ink(state, Vector2(550, 190), Vector2(560, 190), RationDeskRules.MAX_INK_RUBS)))
	assert_eq(_mark()["rubs"].size(), RationDeskRules.MAX_INK_RUBS)
	assert_eq(_mark()["rubs"][0], first)
	assert_eq(_mark()["rubs"][-1]["to"], [20, 0])
	_assert_rejected(rules.smear_wet_ink(state, Vector2(560, 190), Vector2(560, 200), RationDeskRules.MAX_INK_RUBS), state.to_dict())
