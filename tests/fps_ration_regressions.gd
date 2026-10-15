extends RefCounted
## Native-input interruption regressions. Fixture positions isolate interactions;
## these checks do not claim to walk every route or assess real-device audio.

var _desk: Variant
var _failures: PackedStringArray = []


func run(desk: Node) -> PackedStringArray:
	_desk = desk
	_failures.clear()
	await _fresh_customer()
	await _front()
	await _occluded_handoff()
	await _walking_handoff()
	await _table_flip_faces_and_clearance()
	await _lean_exits()
	await _held_inspection_recovery()
	await _stamp_interruptions()
	await _restart_during_stamp()
	await _cut_interruptions_and_resume()
	await _restart_during_tool_drop()
	_release_inputs()
	await _fresh_customer()
	print("[fps regressions] %s" % ("PASS: occlusion, world handoff, physical table flip, lean exits, focus/pause, stamp cancellation/restart, cut resume, package surfaces, drop/restart" if _failures.is_empty() else "FAIL: " + "; ".join(_failures)))
	return _failures


func _fresh_customer() -> void:
	_release_inputs()
	_desk._restart()
	await _desk._wait_customer()
	await _until(func() -> bool: return _desk._window_ready, "customer did not become ready")
	await _desk.get_tree().physics_frame


func _front() -> void:
	# Fixture relocation follows separate native WASD/collision coverage.
	_desk.player.position = Vector3(0, 0.025, -1.25)
	_desk.player.velocity = Vector3.ZERO
	await _desk.get_tree().physics_frame


func _occluded_handoff() -> void:
	var blocker: StaticBody3D = StaticBody3D.new()
	blocker.name = "RegressionOccluder"
	blocker.collision_layer = 1
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.8, 0.10)
	collision.shape = shape
	blocker.add_child(collision)
	_desk.add_child(blocker)
	blocker.global_position = (_desk.player.camera.global_position + _desk.card.global_position) * 0.5
	await _desk.get_tree().physics_frame
	await _desk.get_tree().physics_frame
	_desk._aim(_desk.card.global_position)
	_check(_desk._ray().get("collider") == blocker, "occlusion fixture did not intercept interaction ray")
	_desk._key(KEY_E)
	_check(_work().get("location") == "intake" and not _desk._card_busy, "card was accepted through a solid blocker")
	blocker.queue_free()
	await _desk.get_tree().physics_frame
	await _desk.get_tree().physics_frame


func _walking_handoff() -> void:
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	_check(_desk._card_busy, "handoff did not begin")
	var start: Vector3 = _desk.player.position
	_desk._key_down(KEY_S, true)
	var deadline: int = Time.get_ticks_msec() + 8000
	while _desk._card_busy and Time.get_ticks_msec() < deadline:
		_check(_desk.card.get_parent() == _desk and not _desk.card_held, "handoff attached the card to the walking eye camera")
		await _desk.get_tree().process_frame
	_desk._key_down(KEY_S, false)
	await _idle_hands()
	await _desk.get_tree().physics_frame
	_check(_desk.player.position.distance_to(start) > 0.05, "walking was blocked throughout customer handoff")
	_check(_work().get("placement") == "table" and _desk.card.get_parent() == _desk, "walking away prevented the card settling on the world table")
	_check(_desk.card.global_position.distance_to(Vector3(-0.20, 0.987, -2.13)) < 0.01, "handoff card followed the player instead of settling on its table")


func _lean_exits() -> void:
	await _front()
	var paper: Transform3D = _desk.card.global_transform
	var eye: Transform3D = _desk.player.camera.transform
	_desk._aim(_desk.card.global_position)
	# _aim changes only the existing eye camera orientation; remember that pose.
	eye = _desk.player.camera.transform
	_desk._key(KEY_E)
	await _camera_settled()
	_check(_desk._desk_inspecting and _desk.player.camera.position.length() > 0.1, "E did not lean the existing eye camera over the desk")
	_desk._key(KEY_Q)
	await _camera_settled()
	await _desk.get_tree().physics_frame
	_check(not _desk._desk_inspecting and _desk.player.can_move and not _desk.player.look_locked, "Q left desk inspection movement/look locked")
	_check(_desk.player.camera.transform.is_equal_approx(eye), "Q did not restore the pre-inspection eye pose")
	_check(_desk.card.global_transform.is_equal_approx(paper), "Q moved the table card")
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _camera_settled()
	_check(_desk._desk_inspecting, "returning to the same table card did not resume inspection")
	var start: Vector3 = _desk.player.position
	_desk._key_down(KEY_S, true)
	await _until(func() -> bool: return not _desk._desk_inspecting and _desk.player.can_move, "WASD did not release the lean mode")
	for frame: int in 4:
		await _desk.get_tree().physics_frame
	_desk._key_down(KEY_S, false)
	await _camera_settled()
	_check(_desk.player.position.distance_to(start) > 0.001, "WASD exited inspection without actually allowing walking")
	_check(_desk.card.global_transform.is_equal_approx(paper), "walking out of inspection moved the card")


func _table_flip_faces_and_clearance() -> void:
	await _front()
	_desk._aim(_desk.card.global_position)
	var resting: Vector3 = _desk.card.global_position
	_desk._key(KEY_F)
	var deadline: int = Time.get_ticks_msec() + 8000
	while _desk._card_busy and Time.get_ticks_msec() < deadline:
		for x: float in [-RationCard3D.WIDTH / 2.0, RationCard3D.WIDTH / 2.0]:
			for y: float in [-RationCard3D.HEIGHT / 2.0, RationCard3D.HEIGHT / 2.0]:
				var corner: Vector3 = _desk.card.global_transform * Vector3(x, y, 0)
				_check(corner.y >= 0.965, "table flip passed a paper corner through the tabletop")
		await _desk.get_tree().process_frame
	await _idle_hands()
	_check(not _desk.card.front_showing and _desk.card.global_basis.z.dot(Vector3.DOWN) > 0.99, "table flip changed its flag but did not physically expose the back")
	_check(_desk.card.global_position.is_equal_approx(resting), "table flip did not return to the same surface position")
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_F)
	await _idle_hands()
	_check(_desk.card.front_showing and _desk.card.global_basis.z.dot(Vector3.UP) > 0.99, "second table flip did not restore the physical front face")


func _held_inspection_recovery() -> void:
	await _front()
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_R)
	await _idle_hands()
	_check(_desk.card_held, "explicit card pickup for interruption checks failed")
	_desk._mouse(MOUSE_BUTTON_RIGHT, true)
	_check(_desk._inspecting and _desk.player.look_locked, "held-card RMB inspection did not acquire look control")
	_desk._key(KEY_ESCAPE)
	_check(_desk.pause.visible and not _desk._inspecting and not _desk.player.look_locked, "Escape did not clear held-card inspection without an RMB release")
	_desk._key(KEY_ESCAPE)
	_desk._mouse(MOUSE_BUTTON_RIGHT, false)
	_desk._mouse(MOUSE_BUTTON_RIGHT, true)
	# Exercise the OS notification handler; normal selftests suppress unsolicited
	# focus notifications from a graphical runner, so disable only that guard.
	var selftest: bool = _desk._selftest
	_desk._selftest = false
	_desk._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_desk._selftest = selftest
	_check(_desk.pause.visible and not _desk._inspecting and not _desk.player.look_locked, "focus loss did not clear an unreleased RMB inspection")
	if _desk.pause.visible: _desk._key(KEY_ESCAPE)
	_desk._mouse(MOUSE_BUTTON_RIGHT, false)
	await _desk.get_tree().physics_frame
	_check(_desk.player.can_move and _desk.card_held and _work().get("placement") == "hand", "pause/focus recovery lost the held card or left walking blocked")
	_desk._aim(_desk.workmat.global_position)
	_desk._key(KEY_G)
	await _idle_hands()


func _stamp_interruptions() -> void:
	if not await _pickup_tool("stamp_approve"): return
	var down: int = _sound_count("stamp_down")
	var lift: int = _sound_count("stamp_lift")
	if not await _release_stamp(): return
	# No frame elapses between releasing the button and Q: contact cannot have
	# occurred, even when the graphical runner's frame rate is low.
	_desk._key(KEY_Q)
	await _idle_hands()
	await _desk.get_tree().create_timer(0.40).timeout
	_check((_work().get("marks", []) as Array).is_empty(), "Q before stamp contact still left a delayed ink mark")
	_check(not _desk._busy and not _desk._stamp_animating and _desk.held_tool.get_parent() == _desk.player.camera, "pre-contact stamp cancellation stranded the tool or movement lock")
	_check(_sound_count("stamp_down") == down and _sound_count("stamp_lift") == lift, "a cancelled pre-contact stamp emitted contact/lift sounds")
	if not await _release_stamp(): return
	await _until(func() -> bool: return _desk._stamp_contacted or not _desk._stamp_animating, "stamp never reached contact")
	_check((_work().get("marks", []) as Array).size() == 1, "stamp contact failed to create one mark")
	_desk._key(KEY_Q)
	await _idle_hands()
	await _desk.get_tree().create_timer(0.40).timeout
	_check((_work().get("marks", []) as Array).size() == 1, "cancelling after contact removed or duplicated the completed stamp")
	_check(_sound_count("stamp_down") == down + 1 and _sound_count("stamp_lift") == lift + 1, "post-contact cancellation did not produce exactly one contact and one lift")


func _restart_during_stamp() -> void:
	if _desk.held_tool != _desk.props["stamp_approve"]:
		_failures.append("restart-during-stamp setup lost its stamp")
		return
	if not await _release_stamp(): return
	_desk._restart()
	await _desk._wait_customer()
	await _until(func() -> bool: return _desk._window_ready, "restart did not offer a fresh customer")
	await _desk.get_tree().create_timer(0.40).timeout
	_check((_work().get("marks", []) as Array).is_empty() and _work().get("location") == "intake", "old stamp callback marked the restarted customer's card")
	_check(not _desk._busy and not _desk._stamp_animating and not _desk._stamp_charging, "restart retained stamp animation/control state")


func _cut_interruptions_and_resume() -> void:
	await _front()
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _idle_hands()
	if not await _pickup_tool("stamp_approve"): return
	if not await _release_stamp(): return
	await _idle_hands()
	_check(_work().get("stamp") == "approve", "cut regression setup could not approve the card")
	await _drop_tool_on_table(Vector3(0.70, 0.966, -1.66))
	if not await _pickup_tool("scissors"): return
	var rect: Rect2 = RationCardView.coupon_rect(0)
	_desk._aim(_desk.card.pixel_to_world(rect.position + Vector2(3, 0)))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_check(_desk._cut_index == 0, "coupon cut did not begin at its printed edge")
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_check(_desk._cut_index < 0 and (_work().get("cuts", []) as Array).is_empty(), "Q consumed an unfinished coupon or retained the cutting state")
	_desk._aim(_desk.card.pixel_to_world(rect.position + Vector2(3, 0)))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._aim(_desk.card.pixel_to_world(rect.position + Vector2(60, 70)))
	await _desk.get_tree().physics_frame
	await _desk.get_tree().physics_frame
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_check(_desk._cut_index < 0 and (_work().get("cuts", []) as Array).is_empty(), "leaving the printed cut line consumed the coupon")
	_desk._aim(_desk.card.pixel_to_world(rect.position + Vector2(3, 0)))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	for step: int in range(1, 9):
		_desk._aim(_desk.card.pixel_to_world(rect.position + Vector2(rect.size.x * step / 8.0, 0)))
		await _desk.get_tree().physics_frame
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_check(_work().get("cuts", []) == ["meat"] and (_work().get("parcel", {}) as Dictionary).is_empty(), "completed paperwork required goods or failed to consume exactly one coupon")
	var paper: Transform3D = _desk.card.global_transform
	_desk._key_down(KEY_S, true)
	for frame: int in 8:
		await _desk.get_tree().physics_frame
	_desk._key_down(KEY_S, false)
	await _front()
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _camera_settled()
	_check(_desk._desk_inspecting and _work().get("cuts", []) == ["meat"] and _desk.card.global_transform.is_equal_approx(paper), "walking away and re-inspecting reset the completed coupon")
	_desk._key(KEY_Q)
	await _camera_settled()
	await _drop_tool_on_table(Vector3(0.25, 0.966, -1.66))
	await _package_surfaces()


func _package_surfaces() -> void:
	_desk.player.position = Vector3(1.60, 0.025, 0.15)
	_desk.player.velocity = Vector3.ZERO
	await _desk.get_tree().physics_frame
	_desk._aim(_desk.shelves["meat"].global_position + Vector3(0, 0.14, 0))
	_desk._key(KEY_E)
	await _idle_hands()
	if _desk.held_tool != _desk.parcel:
		_failures.append("post-paperwork shelf package pickup failed")
		return
	var stock: int = int(_work()["official"]["meat"])
	_desk._aim(Vector3(1.6, 0.015, 0.85))
	_desk._key(KEY_G)
	await _idle_hands()
	_check(_desk.held_tool == null and _desk.parcel.get_parent() == _desk and _desk.parcel.collision_layer == 2, "floor drop stranded the package or its collider")
	_desk._aim(_desk.parcel.global_position + Vector3(0, 0.03, 0))
	_desk._key(KEY_E)
	await _idle_hands()
	_check(_desk.held_tool == _desk.parcel, "floor package could not be picked back up")
	await _front()
	await _drop_tool_on_table(Vector3(-0.85, 0.966, -1.66))
	_desk._aim(_desk.parcel.global_position + Vector3(0, 0.03, 0))
	_desk._key(KEY_E)
	await _idle_hands()
	_check(_desk.held_tool == _desk.parcel and int(_work()["official"]["meat"]) == stock and not _work()["parcel"].get("delivered", false), "table package retrieval duplicated/consumed stock or lost the pending package")


func _restart_during_tool_drop() -> void:
	await _fresh_customer()
	await _front()
	if not await _pickup_tool("scissors"): return
	_desk._aim(Vector3(0.25, 0.966, -1.66))
	_desk._key(KEY_G)
	_check(_desk.held_tool == null and _desk._busy, "drop/restart setup did not enter an animated tool placement")
	# The collider is deliberately disabled until surface contact. Restart must
	# restore it even though held_tool has already been cleared by the drop.
	_desk._restart()
	await _desk._wait_customer()
	await _until(func() -> bool: return _desk._window_ready, "drop/restart did not restore the customer")
	_check(_desk.props["scissors"].collision_layer == 2, "restart during tool drop left its home collider disabled")
	_check(_desk.right_hand.get_parent() == _desk.player.camera and not _desk.right_hand.visible, "restart during tool drop left the right hand parented to the released object")
	await _front()
	await _pickup_tool("scissors")


func _pickup_tool(key: String) -> bool:
	_desk._aim(_desk.props[key].global_position + Vector3(0, 0.04 if key == "scissors" else 0.08, 0))
	_desk._key(KEY_E)
	await _idle_hands()
	var ok: bool = _desk.held_tool == _desk.props[key]
	_check(ok, "could not pick up " + key + " for interruption regression")
	return ok


func _drop_tool_on_table(at: Vector3) -> void:
	_desk._aim(at)
	_desk._key(KEY_G)
	await _idle_hands()
	_check(_desk.held_tool == null, "tool did not settle on the table")


func _release_stamp() -> bool:
	_desk._aim(_desk.card.pixel_to_world(Vector2(540, 190)))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	if not _desk._stamp_charging:
		_failures.append("stamp press did not start charging")
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		return false
	await _until(func() -> bool: return _desk._stamp_time >= 0.10 or not _desk._stamp_charging, "stamp charge did not advance")
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	var ok: bool = _desk._stamp_animating
	_check(ok, "stamp release did not begin a physical contact animation")
	return ok


func _idle_hands() -> void:
	await _desk._wait_hands()
	_check(not _desk._busy and not _desk._card_busy, "hand animation exceeded its bounded wait")
	await _desk.get_tree().physics_frame


func _camera_settled() -> void:
	await _until(func() -> bool: return _desk._lean_tween == null or not _desk._lean_tween.is_valid(), "lean camera tween did not finish")
	await _desk.get_tree().physics_frame


func _until(predicate: Callable, failure: String, timeout_ms: int = 8000) -> bool:
	var deadline: int = Time.get_ticks_msec() + timeout_ms
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await _desk.get_tree().process_frame
	var ok: bool = bool(predicate.call())
	_check(ok, failure)
	return ok


func _sound_count(sound: String) -> int:
	return (_desk.foley.events as PackedStringArray).count(sound)


func _work() -> Dictionary:
	var game: Node = _desk.get_tree().root.get_node("Game")
	return RationDeskRules.desk(game.get("state") as CampaignState)


func _check(ok: bool, failure: String) -> void:
	if not ok and not failure in _failures:
		_failures.append(failure)


func _release_inputs() -> void:
	for key: int in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_desk._key_down(key, false)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_desk._mouse(MOUSE_BUTTON_RIGHT, false)
