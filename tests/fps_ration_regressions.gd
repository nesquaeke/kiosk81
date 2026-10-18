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
	await _overhead_navigation()
	await _held_inspection_recovery()
	await _stamp_interruptions()
	await _stamp_speed_and_dwell()
	await _restart_during_stamp()
	await _cut_interruptions_and_resume()
	await _restart_during_tool_drop()
	_release_inputs()
	await _fresh_customer()
	print("[fps regressions] %s" % ("PASS: occlusion, world handoff, physical table flip, overhead cursor/pan/zoom and exits, focus/pause, stamp cancellation/restart, measured 2 cm cutting and persistent damage, perimeter severance, package surfaces, drop/restart" if _failures.is_empty() else "FAIL: " + "; ".join(_failures)))
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
	_check(_desk._desk_inspecting and _desk.player.camera.position.length() > 0.1, "E did not move the existing camera above the desk")
	_check((-_desk.player.camera.global_basis.z).dot(Vector3.DOWN) > 0.995, "inspection camera did not look vertically down at the tabletop")
	_check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "overhead inspection did not release a visible cursor")
	_desk._key(KEY_Q)
	await _camera_settled()
	await _desk.get_tree().physics_frame
	_check(not _desk._desk_inspecting and _desk.player.can_move and not _desk.player.look_locked, "Q left desk inspection movement/look locked")
	# The headless DisplayServer exposes only visible mode even after a
	# successful capture request. Keep the OS capture assertion on graphical
	# runs; movement, look and camera restoration remain checked everywhere.
	if DisplayServer.get_name() != "headless":
		_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "Q did not restore normal FPS mouse capture")
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


func _overhead_navigation() -> void:
	await _front()
	if not await _enter_overhead(): return
	var paper: Transform3D = _desk.card.global_transform
	var before: Transform3D = _desk.player.camera.global_transform
	_desk._mouse(MOUSE_BUTTON_RIGHT, true)
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.position = _desk.get_viewport().get_mouse_position() + Vector2(48, -28)
	drag.relative = Vector2(48, -28)
	drag.screen_relative = drag.relative
	Input.parse_input_event(drag)
	Input.flush_buffered_events()
	await _desk.get_tree().physics_frame
	_desk._mouse(MOUSE_BUTTON_RIGHT, false)
	var panned: Transform3D = _desk.player.camera.global_transform
	_check(panned.origin.distance_to(before.origin) > 0.005, "RMB drag did not pan the overhead camera")
	_check(panned.basis.is_equal_approx(before.basis), "overhead panning tilted the vertical camera")
	_desk._mouse(MOUSE_BUTTON_WHEEL_UP, true)
	_desk._mouse(MOUSE_BUTTON_WHEEL_UP, false)
	await _desk.get_tree().physics_frame
	_check(_desk.player.camera.global_position.y < panned.origin.y - 0.005, "overhead wheel-up did not bring the camera closer to the paper")
	_check(_desk.card.global_transform.is_equal_approx(paper), "overhead panning or zooming moved the world card")
	_desk._key(KEY_Q)
	await _camera_settled()


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
	if not await _start_stamp(): return
	# No frame elapses between arming the hover and Q: contact cannot have
	# occurred, even when the graphical runner's frame rate is low.
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _idle_hands()
	await _desk.get_tree().create_timer(0.40).timeout
	_check((_work().get("marks", []) as Array).is_empty(), "Q before stamp contact still left a delayed ink mark")
	_check(not _desk._busy and not _desk._stamp_animating and _desk.held_tool.get_parent() == _desk.player.camera, "pre-contact stamp cancellation stranded the tool or movement lock")
	_check(_sound_count("stamp_down") == down and _sound_count("stamp_lift") == lift, "a cancelled pre-contact stamp emitted contact/lift sounds")
	if not await _start_stamp(): return
	_stamp_descent(180.0)
	await _until(func() -> bool: return _desk._stamp_contacted, "stamp never reached contact while held")
	_check((_work().get("marks", []) as Array).size() == 1, "stamp contact failed to create one mark")
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _idle_hands()
	await _desk.get_tree().create_timer(0.40).timeout
	_check((_work().get("marks", []) as Array).size() == 1, "cancelling after contact removed or duplicated the completed stamp")
	_check(_sound_count("stamp_down") == down + 1 and _sound_count("stamp_lift") == lift + 1, "post-contact cancellation did not produce exactly one contact and one lift")


func _restart_during_stamp() -> void:
	if _desk.held_tool != _desk.props["stamp_approve"]:
		_failures.append("restart-during-stamp setup lost its stamp")
		return
	if not await _start_stamp(): return
	_stamp_descent(180.0)
	_desk._restart()
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._wait_customer()
	await _until(func() -> bool: return _desk._window_ready, "restart did not offer a fresh customer")
	await _desk.get_tree().create_timer(0.40).timeout
	_check((_work().get("marks", []) as Array).is_empty() and _work().get("location") == "intake", "old stamp callback marked the restarted customer's card")
	_check(not _desk._busy and not _desk._stamp_animating and not _desk._stamp_charging, "restart retained stamp animation/control state")


func _stamp_speed_and_dwell() -> void:
	if not await _start_stamp(): return
	var before: int = (_work().get("marks", []) as Array).size()
	# The same physical downward travel, spread over multiple frames, must
	# make a slower impact than one quick stroke. Holding at contact develops
	# this impression; sideways movement smudges it without adding contacts.
	for step: int in 22:
		_stamp_descent(8.0)
		await _desk.get_tree().create_timer(0.04).timeout
		if _desk._stamp_contacted: break
	if not await _until(func() -> bool: return _desk._stamp_contacted, "slow stamp never reached the paper"):
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
		return
	_stamp_motion(Vector2(12, 0))
	await _desk.get_tree().create_timer(0.25).timeout
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _idle_hands()
	var marks: Array = _work().get("marks", [])
	_check(marks.size() == before + 1, "one held stamp contact generated repeated ink marks")
	if marks.size() != before + 1: return
	var slow: Dictionary = (marks[-1] as Dictionary).duplicate(true)
	if not await _release_stamp(): return
	await _idle_hands()
	marks = _work().get("marks", [])
	_check(marks.size() == before + 2, "quick stamp contact was lost or duplicated")
	if marks.size() != before + 2: return
	var quick: Dictionary = marks[-1]
	_check(float(quick.get("speed", 0)) > float(slow.get("speed", 0)) + 0.04, "native fast and slow stamp strokes stored the same impact speed")
	_check(float(slow.get("dwell", 0)) > float(quick.get("dwell", 0)) + 0.1, "holding a stamp on the paper did not persist contact dwell")
	_check(float(slow.get("smudge", 0)) > 0, "sideways movement while touching the paper left no smudge metadata")


func _cut_interruptions_and_resume() -> void:
	await _front()
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _idle_hands()
	if not await _enter_overhead(): return
	if not await _pickup_tool("stamp_approve"): return
	if not await _release_stamp(): return
	await _idle_hands()
	_check(_work().get("stamp") == "approve", "cut regression setup could not approve the card")
	await _drop_tool_on_table(Vector3(0.70, 0.966, -1.66))
	if not await _pickup_tool("scissors"): return
	var rect: Rect2 = RationCardView.coupon_rect(0)
	var start: Vector2 = rect.position
	# Print space has a physical scale of 0.36 m / 640 px. The blade must
	# travel 2 cm, rather than completing an entire coupon from a percentage.
	var two_cm: Vector2 = start + Vector2(0.02 * 640.0 / 0.36, 0)
	if not _start_cut(start): return
	_desk._aim(_desk.card.pixel_to_world(two_cm))
	await _desk.get_tree().physics_frame
	var first_frame_m: float = ((_desk._cut_tip as Vector2) - start).length() * 0.36 / 640.0
	_check(first_frame_m < 0.015, "a cursor jump teleported the physical blades through the entire 2 cm path")
	if not await _trace_to(two_cm): return
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk.get_tree().physics_frame
	var incisions: Array = _work().get("incisions", [])
	_check(incisions.size() == 1, "a released physical stroke did not persist exactly one incision")
	if incisions.is_empty(): return
	var first_stroke: Dictionary = (incisions[0] as Dictionary).duplicate(true)
	_check(absf(float(first_stroke.get("length_m", 0)) - 0.02) <= 0.0008, "2 cm blade travel did not leave a measured 2 cm cut")
	_check((_work().get("cuts", []) as Array).is_empty(), "2 cm of damage detached an entire coupon")
	_check(_desk._cut_index < 0, "releasing a partial incision retained cutting control")
	var paper: Transform3D = _desk.card.global_transform
	_desk._key(KEY_Q)
	await _camera_settled()
	_check(_work().get("incisions", []) == incisions, "leaving the desk healed a partial incision")
	_check(not _desk._desk_inspecting and _desk.player.can_move, "partial incision prevented leaving the desk")
	if not await _enter_overhead(): return
	_check(_desk.held_tool == _desk.props["scissors"], "re-entering the desk lost the held scissors")
	# Q saves the actual path already travelled. There is no all-or-nothing
	# cancellation that restores paper which the blades have already cut.
	var resumed: Vector2 = two_cm + Vector2(18, 0)
	if not _start_cut(two_cm): return
	if not await _trace_to(resumed): return
	_desk._key(KEY_Q)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _camera_settled()
	var after_q: Array = _work().get("incisions", [])
	_check(after_q.size() == 2 and after_q[0] == first_stroke, "Q lost, replaced or duplicated the previous physical incision")
	_check((_work().get("cuts", []) as Array).is_empty(), "Q consumed the still-attached coupon")
	if not await _enter_overhead(): return
	# Escape before release must retain physical damage as well, and the
	# returning cursor must remain usable after unpausing.
	var paused_at: Vector2 = resumed + Vector2(18, 0)
	if not _start_cut(resumed): return
	if not await _trace_to(paused_at): return
	_desk._key(KEY_ESCAPE)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_check(_desk.pause.visible and _desk._cut_index < 0, "Escape did not stop the live cutting gesture")
	_check((_work().get("incisions", []) as Array).size() == 3, "Escape healed physical blade travel")
	_desk._key(KEY_ESCAPE)
	await _camera_settled()
	if not await _enter_overhead(): return
	# Complete only the rest of the top edge. Three uncut sides must still
	# hold the coupon, regardless of apparent percentage progress.
	if not _start_cut(paused_at): return
	if not await _trace_to(rect.position + Vector2(rect.size.x, 0)): return
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk.get_tree().physics_frame
	_check((_work().get("cuts", []) as Array).is_empty(), "a complete top edge detached three uncut coupon sides")
	_check(_first_incision() == first_stroke, "resuming the cut rewrote the original 2 cm incision")
	# A stray interior stroke is real damage too. It cannot become invisible
	# merely because the player missed the dotted perimeter guide.
	var interior: Vector2 = rect.position + Vector2(35, 35)
	var before_interior: int = (_work().get("incisions", []) as Array).size()
	if not _start_cut(interior): return
	if not await _trace_to(interior + Vector2(18, 0)): return
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk.get_tree().physics_frame
	_check((_work().get("incisions", []) as Array).size() == before_interior + 1, "cutting inside the coupon did not retain the actual paper damage")
	_check((_work().get("cuts", []) as Array).is_empty(), "stray interior damage detached an attached coupon")
	# Follow the three remaining edges with the actual scissors tip. Awaiting
	# tip arrival respects the physical speed cap rather than jumping the
	# pointer once per frame and forcing an entitlement change.
	var top_right: Vector2 = rect.position + Vector2(rect.size.x, 0)
	if not _start_cut(top_right): return
	for corner: Vector2 in [rect.end, rect.position + Vector2(0, rect.size.y), rect.position]:
		if not await _trace_to(corner): return
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk.get_tree().physics_frame
	_check(_work().get("cuts", []) == ["meat"] and (_work().get("parcel", {}) as Dictionary).is_empty(), "four severed edges failed to consume exactly one coupon before goods preparation")
	_check(_desk._tokens.size() == 1, "physical coupon severance did not create exactly one separate paper piece")
	_desk._key_down(KEY_S, true)
	for frame: int in 8:
		await _desk.get_tree().physics_frame
	_desk._key_down(KEY_S, false)
	await _camera_settled()
	await _front()
	if not await _enter_overhead(): return
	_check(_work().get("cuts", []) == ["meat"] and _desk.card.global_transform.is_equal_approx(paper), "walking away and re-inspecting reset the detached coupon or moved its card")
	_check(_first_incision() == first_stroke, "completed paperwork lost the original physical incision")
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


func _enter_overhead() -> bool:
	if not _desk._desk_inspecting:
		# Under a slow software renderer, a wall-clock timer can expire before
		# the returning camera has finished its tween. Await the actual pose
		# before aiming and pressing E, just as the entering pose is awaited.
		await _camera_settled()
		_desk._aim(_desk.card.global_position)
		_desk._key(KEY_E)
		await _camera_settled()
	var ok: bool = _desk._desk_inspecting
	_check(ok, "could not enter overhead inspection for a physical tool action")
	return ok


func _start_cut(pixel: Vector2) -> bool:
	_desk._aim(_desk.card.pixel_to_world(pixel))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	var ok: bool = _desk._cut_index == 0
	_check(ok, "actual-path cutting did not start at the scissors tip")
	return ok


func _trace_to(pixel: Vector2) -> bool:
	_desk._aim(_desk.card.pixel_to_world(pixel))
	var ok: bool = await _until(func() -> bool: return _desk._cut_index < 0 or (_desk._cut_tip as Vector2).distance_to(pixel) <= 0.12,
		"physical scissors tip did not reach its requested print coordinate", 10000)
	_check(_desk._cut_index == 0, "cutting stopped before the actual scissors tip reached its target")
	return ok and _desk._cut_index == 0


func _start_stamp() -> bool:
	if not await _enter_overhead(): return false
	_desk._aim(_desk.card.pixel_to_world(Vector2(540, 190)))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	var ok: bool = _desk._stamp_charging
	_check(ok, "stamp press did not arm its physical hover gesture")
	if not ok: _desk._mouse(MOUSE_BUTTON_LEFT, false)
	return ok


func _stamp_descent(pixels: float) -> void:
	_stamp_motion(Vector2(0, pixels))


func _stamp_motion(relative: Vector2) -> void:
	var stroke: InputEventMouseMotion = InputEventMouseMotion.new()
	stroke.position = _desk.get_viewport().get_mouse_position()
	stroke.relative = relative
	stroke.screen_relative = relative
	Input.parse_input_event(stroke)
	Input.flush_buffered_events()


func _release_stamp() -> bool:
	if not await _start_stamp(): return false
	_stamp_descent(180.0)
	var ok: bool = await _until(func() -> bool: return _desk._stamp_contacted, "native downward stamp motion never reached the paper")
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_check(not ok or _desk._stamp_animating, "stamp release did not begin its physical lift")
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


func _first_incision() -> Dictionary:
	var incisions: Array = _work().get("incisions", [])
	return incisions[0] if not incisions.is_empty() else {}


func _check(ok: bool, failure: String) -> void:
	if not ok and not failure in _failures:
		_failures.append(failure)


func _release_inputs() -> void:
	for key: int in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_desk._key_down(key, false)
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_desk._mouse(MOUSE_BUTTON_RIGHT, false)
