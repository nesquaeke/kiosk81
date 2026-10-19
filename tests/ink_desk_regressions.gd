extends RefCounted
## Real input and the original physical tools. A reservoir, an ink impression
## and a decision remain separate facts through interruption and finger contact.

var _desk: Node3D
var _failures: PackedStringArray = []


func run(desk: Node3D) -> PackedStringArray:
	_desk = desk
	_failures.clear()
	await _abort_pad_before_contact()
	await _load_pad_then_leave()
	await _lift_pad_without_releasing()
	await _interrupt_contacted_pad()
	await _paper_airborne_motion_and_recontact()
	await _finger_stain_survives_held_drying()
	await _paper_contact_and_finger()
	_desk._restart()
	await _desk._wait_customer()
	_check(_desk._ink_now() == 0.0 and _work().get("marks", []).is_empty(), "restart retained an old wet print or physical ink clock")
	for kind: String in ["approve", "reject", "seize"]:
		_check(_load(kind) == StampInkState.INITIAL_LOAD, "restart retained a previous stamp reservoir: " + kind)
	_check(_desk.ink_pad.compression_depth == 0.0 and not _desk._ink_rubbing and not _desk._stamp_charging, "restart left felt pressure or a finger/stamp gesture")
	print("[ink desk regressions] %s" % ("PASS: precontact Q/pause/restart, contact-only independent pad absorption, held-button lift/recontact, contacted pad pause/restart, airborne paper movement without smear, separate paper recontacts/debits, live finger stain retained through natural drying, single paper debit/tilt snapshot, postcontact cancellation, paused drying, wet/dry physical finger contact, no stock/economy/verdict changes" if _failures.is_empty() else "FAIL: " + "; ".join(_failures)))
	return _failures


func _abort_pad_before_contact() -> void:
	for exit_key: int in [KEY_Q, KEY_ESCAPE, KEY_R]:
		await _fresh_table()
		if not await _take_stamp("approve"): return
		var before: Dictionary = Game.state.to_dict()
		var initial_load: float = _load("approve")
		var down_events: int = _sound_count("ink_pad_down")
		var lift_events: int = _sound_count("ink_pad_lift")
		_desk._aim(_desk.ink_pad.felt_world_point())
		_desk._mouse(MOUSE_BUTTON_LEFT, true)
		await _frames(2)
		_check(_desk._stamp_charging and _desk._stamp_surface == "pad" and not _desk._stamp_contacted, "pad press did not begin as a contact-free approach")
		if exit_key == KEY_R:
			_desk._restart()
			await _desk._wait_customer()
		else:
			_desk._key(exit_key)
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		await _desk._test_camera_settled()
		_check(not _desk._stamp_charging and not _desk._stamp_contacted and not _desk._stamp_animating, "aborting a pad approach left a contact/control latch")
		_check(absf(_load("approve") - initial_load) < 0.000001, "Q/pause/restart before felt contact changed the stamp reservoir")
		_check(_desk.ink_pad.compression_depth == 0.0 and _desk.ink_pad.pressure == 0.0, "aborted pad approach compressed the real felt")
		_check(_sound_count("ink_pad_down") == down_events and _sound_count("ink_pad_lift") == lift_events, "aborted pad approach emitted a false contact/lift sound")
		_check(_work().get("marks", []).is_empty() and _work().get("stamp", "") == "", "aborted pad approach wrote paper ink or a decision")
		if exit_key != KEY_R:
			_check(Game.state.to_dict() == before, "Q/pause before felt contact changed campaign state")
		if _desk.pause.visible: _desk._key(KEY_ESCAPE)


func _load_pad_then_leave() -> void:
	await _fresh_table()
	if not await _take_stamp("approve"): return
	var before: Dictionary = Game.state.to_dict()
	var initial: float = _load("approve")
	var reject: float = _load("reject")
	var seize: float = _load("seize")
	var down_events: int = _sound_count("ink_pad_down")
	var lift_events: int = _sound_count("ink_pad_lift")
	_desk._aim(_desk.ink_pad.felt_world_point())
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._test_motion(Vector2(0, 180))
	if not await _desk._test_until(func() -> bool: return _desk._stamp_contacted, 2200):
		_check(false, "lowered stamp never touched the physical ink felt")
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		return
	_check(_desk._stamp_surface == "pad" and _desk._stamp_serial < 0, "ink-pad contact was treated as a paper impression")
	await _desk.get_tree().create_timer(0.35).timeout
	var loaded: float = _load("approve")
	_check(loaded > initial + 0.01 and loaded <= 1.0, "held felt contact did not absorb bounded ink")
	_check(_desk.ink_pad.compression_depth > 0.0, "actual contact did not compress the felt")
	_check(_load("reject") == reject and _load("seize") == seize, "inking one stamp refilled another physical stamp")
	_check(Game.state.to_dict() == before, "pad contact wrote campaign paper/decision/clock data")
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._test_camera_settled()
	await _frames(3)
	_check(absf(_load("approve") - loaded) < 0.000001, "Q after pad contact discarded absorbed ink or kept loading off the felt")
	_check(_desk.ink_pad.compression_depth == 0.0 and _desk.ink_pad.pressure == 0.0, "leaving real felt contact left the pad compressed")
	_check(_sound_count("ink_pad_down") == down_events + 1 and _sound_count("ink_pad_lift") == lift_events + 1, "one pad contact did not produce exactly one down/lift pair")
	_check(not _desk._desk_inspecting and not _desk.player.look_locked and _desk.player.camera.get_parent() == _desk.player.head, "Q after inking did not restore the first-person camera")
	_check(not _desk._stamp_charging and not _desk._busy, "Q after inking left a stamp/control lock")
	# The headless DisplayServer cannot expose OS mouse capture. The same
	# suite retains this assertion during its real graphical run.
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Q after inking did not restore FPS pointer capture")
	_check(Game.state.to_dict() == before, "leaving ink-pad contact mutated campaign state")


func _lift_pad_without_releasing() -> void:
	await _fresh_table()
	if not await _take_stamp("approve"): return
	var before: Dictionary = Game.state.to_dict()
	var down_events: int = _sound_count("ink_pad_down")
	var lift_events: int = _sound_count("ink_pad_lift")
	if not await _touch_pad(): return
	await _desk.get_tree().create_timer(0.15).timeout
	# The left button remains held throughout. Raising the actual rubber above
	# the felt must end absorption even though this gesture touched it earlier.
	_desk._test_motion(Vector2(0, -220))
	_check(await _desk._test_until(func() -> bool: return _desk._stamp_height > 0.01, 1500), "held-button upward motion did not physically lift the stamp")
	var lifted_load: float = _load("approve")
	_check(_desk._stamp_charging and _desk._stamp_contacted, "held-button lift discarded the gesture's first-contact history")
	_check(_desk.ink_pad.compression_depth == 0.0 and _desk.ink_pad.pressure == 0.0, "lifted stamp kept compressing felt before button release")
	await _desk.get_tree().create_timer(0.30).timeout
	_check(absf(_load("approve") - lifted_load) < 0.000001, "raised rubber kept absorbing ink while the mouse button was held")
	_check(_sound_count("ink_pad_down") == down_events + 1 and _sound_count("ink_pad_lift") == lift_events + 1, "lifting actual pad contact did not emit exactly one physical down/lift pair")
	_desk._test_motion(Vector2(0, 220))
	_check(await _desk._test_until(func() -> bool: return _desk.ink_pad.pressure > 0.0, 1500), "lowering the still-held stamp did not recontact the felt")
	await _desk.get_tree().create_timer(0.20).timeout
	_check(_load("approve") > lifted_load + 0.001, "actual felt recontact did not resume absorption")
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._wait_hands()
	var released_load: float = _load("approve")
	await _desk.get_tree().create_timer(0.25).timeout
	_check(absf(_load("approve") - released_load) < 0.000001 and _desk.ink_pad.compression_depth == 0.0, "normal release after felt recontact retained absorption or pressure")
	_check(not _desk._stamp_charging and not _desk._stamp_animating and not _desk._busy, "release after felt recontact left controls latched")
	_check(_sound_count("ink_pad_down") == down_events + 2 and _sound_count("ink_pad_lift") == lift_events + 2, "two real felt contacts did not produce two down/lift pairs exactly")
	_check(Game.state.to_dict() == before, "lift/recontact on the ink pad wrote paper or campaign data")


func _interrupt_contacted_pad() -> void:
	for restart: bool in [false, true]:
		await _fresh_table()
		if not await _take_stamp("approve"): return
		var before: Dictionary = Game.state.to_dict()
		if not await _touch_pad(): return
		await _desk.get_tree().create_timer(0.12).timeout
		var loaded: float = _load("approve")
		_check(loaded > StampInkState.INITIAL_LOAD and _desk.ink_pad.compression_depth > 0.0, "contacted interruption fixture did not actually load/compress the pad")
		if restart:
			_desk._restart()
			await _desk._wait_customer()
		else:
			_desk._key(KEY_ESCAPE)
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		await _desk.get_tree().create_timer(0.35).timeout
		_check(not _desk._stamp_charging and not _desk._stamp_contacted and not _desk._stamp_animating and not _desk._busy, "pause/restart during felt contact left an old gesture callback or lock")
		_check(_desk.ink_pad.compression_depth == 0.0 and _desk.ink_pad.pressure == 0.0, "pause/restart during felt contact left compressed felt")
		if restart:
			for kind: String in ["approve", "reject", "seize"]:
				_check(_load(kind) == StampInkState.INITIAL_LOAD, "old contacted-pad callback changed a reset reservoir: " + kind)
			_check(_desk.held_tool == null and _desk._ink_now() == 0.0 and _work().get("marks", []).is_empty(), "restart during pad contact retained old ink, a held stamp or paper data")
		else:
			_check(_desk.pause.visible and absf(_load("approve") - loaded) < 0.000001, "pausing actual felt contact discarded ink or continued loading")
			_check(Game.state.to_dict() == before, "pausing actual felt contact changed campaign state")
			_desk._key(KEY_ESCAPE)
			await _frames(3)
			_check(absf(_load("approve") - loaded) < 0.000001 and not _desk.player.look_locked, "resuming a cancelled felt contact revived absorption or locked first-person look")


func _touch_pad() -> bool:
	_desk._aim(_desk.ink_pad.felt_world_point())
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._test_motion(Vector2(0, 180))
	var contacted: bool = await _desk._test_until(func() -> bool: return _desk._stamp_contacted and _desk.ink_pad.pressure > 0.0, 2200)
	_check(contacted, "pad contact fixture did not bring real rubber onto the felt")
	if not contacted: _desk._mouse(MOUSE_BUTTON_LEFT, false)
	return contacted


func _paper_airborne_motion_and_recontact() -> void:
	for recontact: bool in [false, true]:
		await _fresh_table()
		if not await _take_stamp("approve"): return
		var initial_load: float = _load("approve")
		var down_events: int = _sound_count("stamp_down")
		var lift_events: int = _sound_count("stamp_lift")
		var target: Vector2 = Vector2(540, 183)
		_desk._aim(_desk.card.pixel_to_world(target))
		_desk._mouse(MOUSE_BUTTON_LEFT, true)
		_desk._test_motion(Vector2(20, 0))
		_check(_work().get("marks", []).is_empty(), "airborne sideways paper approach created ink before contact")
		_desk._test_motion(Vector2(0, 180))
		if not await _desk._test_until(func() -> bool: return _desk._stamp_touching and _work().get("marks", []).size() == 1, 2200):
			_check(false, "sideways paper approach never reached a real first contact")
			_desk._mouse(MOUSE_BUTTON_LEFT, false)
			return
		var first: Dictionary = _work()["marks"][0]
		var expected_x: float = target.x + 20.0 * 0.00012 * (640.0 / RationCard3D.WIDTH)
		_check(absf(float(first["x"]) - expected_x) < 0.05 and absf(float(first["y"]) - target.y) < 0.05, "precontact sideways motion did not move the actual first impression")
		_check(float(first.get("smudge", -1.0)) == 0.0, "airborne approach displacement was recorded as paper smearing")
		_desk._test_motion(Vector2(0, -220))
		_check(await _desk._test_until(func() -> bool: return _desk._stamp_height > 0.01 and not _desk._stamp_touching, 1500), "raising paper rubber did not end its actual contact")
		var frozen: Dictionary = _work()["marks"][0].duplicate(true)
		var lifted_load: float = _load("approve")
		_check(absf(lifted_load - (initial_load - StampInkState.PAPER_USE)) < 0.000001, "first physical paper contact did not debit ink exactly once")
		_desk._mouse(MOUSE_BUTTON_RIGHT, true)
		_desk._test_motion(Vector2(20, 15))
		_desk._mouse(MOUSE_BUTTON_RIGHT, false)
		await _desk.get_tree().create_timer(0.15).timeout
		_check(_work()["marks"][0] == frozen and _work()["marks"].size() == 1, "moving the raised rubber sideways changed old ink or created a phantom impression")
		_check(_load("approve") == lifted_load, "airborne paper movement consumed reservoir ink")
		if recontact:
			_desk._test_motion(Vector2(0, 220))
			_check(await _desk._test_until(func() -> bool: return _desk._stamp_touching and _work()["marks"].size() == 2, 2200), "held-button paper recontact did not create a second physical impression")
			_check(_work()["marks"][0] == frozen, "new paper contact rewrote the first completed impression")
			_check(absf(_load("approve") - (initial_load - 2.0 * StampInkState.PAPER_USE)) < 0.000001, "two separate paper contacts did not consume two reservoir debits")
			if _work()["marks"].size() == 2:
				var second: Dictionary = _work()["marks"][1]
				_check(second["serial"] != frozen["serial"] and float(second["contact_time"]) >= float(frozen["contact_time"]), "second contact reused an old impression identity or timestamp")
				_check(absf(float(second["ink_load"]) - lifted_load) < 0.000001 and float(second["smudge"]) == 0.0, "second impact did not snapshot its own reservoir or included airborne smearing")
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		await _desk._wait_hands()
		var expected_contacts: int = 2 if recontact else 1
		_check(_work()["marks"].size() == expected_contacts and _work()["marks"][0] == frozen, "button release changed completed paper ink or created a phantom extra mark")
		_check(_sound_count("stamp_down") == down_events + expected_contacts and _sound_count("stamp_lift") == lift_events + expected_contacts, "paper sounds did not occur exactly once per actual contact and lift")


func _finger_stain_survives_held_drying() -> void:
	await _fresh_table()
	if not await _take_stamp("approve"): return
	var target: Vector2 = Vector2(540, 183)
	_desk._aim(_desk.card.pixel_to_world(target))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._test_motion(Vector2(0, 180))
	if not await _desk._test_until(func() -> bool: return _desk._stamp_touching and _work().get("marks", []).size() == 1, 2200):
		_check(false, "live finger fixture could not create fresh physical ink")
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		return
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._wait_hands()
	await _park_tool()
	var pose: Transform3D = _desk.card.global_transform
	_desk._aim(_desk.card.pixel_to_world(target))
	_desk._key_down(KEY_ALT, true)
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	await _frames(2)
	_desk._aim(_desk.card.pixel_to_world(target + Vector2(30, 7)))
	_desk._test_motion(Vector2(30, 7))
	_check(await _desk._test_until(func() -> bool: return not _work()["marks"][0].get("rubs", []).is_empty(), 1500), "wet finger movement did not persist its stain before button release")
	_check(_desk._ink_rubbing, "live-stain test released its finger before ink was recorded")
	var stain: Dictionary = _work()["marks"][0].duplicate(true)
	# Keep the real gesture held until this physical print naturally dries.
	# Releasing later must not erase the earlier wet contact or recalculate it
	# as a dry gesture which supposedly never touched transferable ink.
	_check(await _desk._test_until(func() -> bool: return StampInkState.wetness(stain, _desk._ink_now()) == 0.0, 15000), "held finger fixture never reached natural ink drying")
	_check(_desk._ink_rubbing and _work()["marks"][0] == stain, "holding a stationary finger until drying rewrote the existing stain")
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_desk._key_down(KEY_ALT, false)
	await _frames(2)
	_check(_work()["marks"][0] == stain and not _desk._ink_rubbing, "release after natural drying erased or duplicated the earlier wet stain")
	_check(_desk.card.global_transform.is_equal_approx(pose) and not _desk._paper_dragging, "live finger contact moved the physical document")


func _paper_contact_and_finger() -> void:
	await _fresh_table()
	if not await _take_stamp("approve"): return
	var initial: float = _load("approve")
	var target: Vector2 = Vector2(540, 183)
	var before: Dictionary = Game.state.to_dict()
	# Paper also has an approach phase. Releasing the desk before the rubber
	# touches must not consume a reservoir debit or invent a dry impression.
	_desk._aim(_desk.card.pixel_to_world(target))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	await _frames(2)
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._test_camera_settled()
	_check(Game.state.to_dict() == before and _load("approve") == initial, "Q before paper contact spent ink or left an impression")
	await _enter_table()
	_desk._key_down(KEY_ALT, true)
	for step: int in 3: _desk._mouse(MOUSE_BUTTON_WHEEL_UP, true)
	_desk._key_down(KEY_ALT, false)
	var tilt: float = _desk._stamp_tilt
	_check(absf(tilt) > 0.01 and absf(tilt) <= 0.30, "Alt + wheel did not adjust a bounded physical stamp tilt")
	var down_events: int = _sound_count("stamp_down")
	var lift_events: int = _sound_count("stamp_lift")
	_desk._aim(_desk.card.pixel_to_world(target))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._test_motion(Vector2(0, 180))
	if not await _desk._test_until(func() -> bool: return _desk._stamp_contacted, 2200):
		_check(false, "tilted physical paper contact never occurred")
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		return
	if _work().get("marks", []).size() != 1:
		_check(false, "first rubber/paper contact did not create exactly one impression")
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		return
	var mark: Dictionary = _work()["marks"][0].duplicate(true)
	var after_debit: float = _load("approve")
	_check(_desk._stamp_surface == "paper" and _desk._stamp_serial > 0, "paper contact did not receive its own impression serial")
	_check(absf(float(mark.get("ink_load", -1.0)) - initial) < 0.000001, "paper did not snapshot the reservoir at first contact")
	_check(absf(after_debit - (initial - StampInkState.PAPER_USE)) < 0.000001, "one paper contact did not debit the reservoir once")
	_check(absf(float(mark.get("tilt", 1.0)) - tilt) < 0.000001, "paper did not preserve the actual tilted contact")
	_check(float(mark.get("contact_time", -1.0)) >= 0.0 and float(mark.get("dry_duration", 0.0)) >= 8.0, "paper impression omitted persisted drying metadata")
	await _desk.get_tree().create_timer(0.25).timeout
	_check(_work().get("marks", []).size() == 1 and absf(_load("approve") - after_debit) < 0.000001, "held pressure created another impression or another reservoir debit")
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._test_camera_settled()
	var released: Dictionary = _work()["marks"][0]
	for key: String in ["serial", "x", "y", "kind", "ink_load", "tilt", "contact_time", "dry_duration"]:
		_check(released.get(key) == mark.get(key), "postcontact Q rewrote immutable paper field: " + key)
	_check(_work().get("marks", []).size() == 1 and _work().get("stamp") == "approve", "Q after contact lost its permanent ink/decision")
	_check(_sound_count("stamp_down") == down_events + 1 and _sound_count("stamp_lift") == lift_events + 1, "one paper contact did not produce exactly one down/lift pair")
	var contact_expected: Dictionary = _without_clock(before)
	contact_expected["flags"][RationDeskRules.KEY]["marks"] = [released.duplicate(true)]
	contact_expected["flags"][RationDeskRules.KEY]["stamp"] = "approve"
	_check(_without_clock(Game.state.to_dict()) == contact_expected, "physical stamping changed stock, money, evidence, paper cuts or other campaign fields")
	_desk._key(KEY_ESCAPE)
	var paused: Dictionary = Game.state.to_dict()
	var paused_time: float = _desk._ink_now()
	await _desk.get_tree().create_timer(0.30).timeout
	_check(_desk.pause.visible and absf(_desk._ink_now() - paused_time) < 0.000001, "pause advanced physical ink drying")
	_check(Game.state.to_dict() == paused, "paused drying mutated persisted campaign state")
	_desk._key(KEY_ESCAPE)
	await _enter_table()
	await _park_tool()
	var paper_pose: Transform3D = _desk.card.global_transform
	var before_rub: Dictionary = _without_clock(Game.state.to_dict())
	await _rub(target, target + Vector2(30, 7))
	var rubbed: Dictionary = _work()["marks"][0].duplicate(true)
	_check(not rubbed.get("rubs", []).is_empty(), "actual Alt + finger drag across fresh ink left no persisted smear")
	_check(_desk.card.global_transform.is_equal_approx(paper_pose) and not _desk._paper_dragging and not _desk._ink_rubbing, "finger drag moved the document or left a contact latch")
	var expected: Dictionary = before_rub.duplicate(true)
	(expected["flags"][RationDeskRules.KEY]["marks"] as Array)[0] = rubbed.duplicate(true)
	_check(_without_clock(Game.state.to_dict()) == expected, "finger smearing altered a decision, paper damage, stock, money or evidence")
	for key: String in ["serial", "x", "y", "kind", "ink_load", "tilt", "contact_time", "dry_duration"]:
		_check(rubbed.get(key) == mark.get(key), "finger smear rewrote original contact field: " + key)
	# Advance the same persisted physical clock through its public rule. The
	# dry-contact gesture remains real input; there is no renderer-only override
	# or direct CampaignState mutation to manufacture a dry print.
	_check(_desk._execute(_desk.rules.advance_ink_time(Game.state, 15.0)), "dry-contact fixture could not advance the authoritative ink clock")
	await _frames(2)
	_check(StampInkState.wetness(rubbed, _desk._ink_now()) == 0.0, "dry-contact fixture still has wet ink")
	var dry: Dictionary = _without_clock(Game.state.to_dict())
	await _rub(target, target + Vector2(30, 7))
	_check(_without_clock(Game.state.to_dict()) == dry, "touching dry ink changed print, decision or campaign resources")
	_check(_desk.card.global_transform.is_equal_approx(paper_pose) and not _desk._paper_dragging and not _desk._ink_rubbing, "dry finger drag moved paper or left controls stuck")


func _rub(start: Vector2, end: Vector2) -> void:
	_desk._aim(_desk.card.pixel_to_world(start))
	_desk._key_down(KEY_ALT, true)
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_check(_desk._ink_rubbing and not _desk._paper_dragging, "Alt + empty-hand paper contact did not select finger rubbing")
	await _frames(2)
	_desk._aim(_desk.card.pixel_to_world(end))
	_desk._test_motion(Vector2(30, 7))
	await _frames(2)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_desk._key_down(KEY_ALT, false)
	await _frames(2)


func _fresh_table() -> void:
	_desk._restart()
	await _desk._wait_customer()
	_desk.player.position = Vector3(0, 0.025, -1.25)
	_desk.player.velocity = Vector3.ZERO
	await _desk.get_tree().physics_frame
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	_desk._aim(_desk.workmat.global_position)
	_desk._key(KEY_G)
	await _desk._wait_hands()
	await _desk._test_camera_settled()
	_check(_desk._desk_inspecting and _work().get("placement") == "table", "ink fixture could not place the original card on the physical desk")


func _take_stamp(kind: String) -> bool:
	_desk._aim(_desk.props["stamp_" + kind].global_position + Vector3.UP * 0.08)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	var held: bool = _desk.held_tool == _desk.props["stamp_" + kind]
	_check(held, "ink regression could not pick up the original " + kind + " stamp")
	return held


func _enter_table() -> void:
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _desk._test_camera_settled()
	_check(_desk._desk_inspecting, "ink regression could not re-enter physical overhead work")


func _park_tool() -> void:
	if _desk.held_tool == null: return
	_desk._aim(_desk.homes[_desk.held_tool].origin + Vector3.UP * 0.003)
	_desk._key(KEY_G)
	await _desk._wait_hands()
	_check(_desk.held_tool == null, "ink regression could not leave the physical stamp on real support")


func _frames(count: int) -> void:
	for frame: int in count:
		await _desk.get_tree().physics_frame


func _load(kind: String) -> float:
	return float(_desk._stamp_inks[kind].load)


func _work() -> Dictionary:
	return RationDeskRules.desk(Game.state)


func _sound_count(event_name: String) -> int:
	return _desk.foley.events.count(event_name)


func _without_clock(state: Dictionary) -> Dictionary:
	var copy: Dictionary = state.duplicate(true)
	(copy["flags"][RationDeskRules.KEY] as Dictionary).erase("ink_clock")
	return copy


func _check(condition: bool, reason: String) -> void:
	if not condition: _failures.append(reason)
