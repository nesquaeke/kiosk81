extends RefCounted
## Native inputs and the same physical document through pickup, RE-style
## inspection, safe cancellation, placement and table-space stamp guidance.

func run(desk: Node3D) -> PackedStringArray:
	var failures: PackedStringArray = []
	desk._restart()
	await desk._wait_customer()
	desk.player.position = Vector3(0, 0.025, -1.25)
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	# An early F must queue, rather than silently swallowing the player's input.
	desk._key(KEY_F)
	await desk._wait_hands()
	await desk._test_until(func() -> bool: return desk._object_inspector.active)
	await desk.get_tree().create_timer(0.25).timeout
	if not desk.card_held or desk.card.get_parent() != desk.player.camera or RationDeskRules.desk(Game.state).get("placement") != "hand":
		failures.append("E did not take the original card into the hand")
	if not desk._object_inspector.active or not desk.player.look_locked or desk.player.can_move:
		failures.append("early F did not acquire a persistent handheld inspection")
	var eye: Transform3D = desk.player.camera.transform
	var ink: Dictionary = RationDeskRules.desk(Game.state).duplicate(true)
	var first: Quaternion = desk.card.quaternion
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._test_motion(Vector2(110, -65))
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	var turned: Quaternion = desk.card.quaternion
	if turned.is_equal_approx(first): failures.append("LMB drag did not rotate the physical sheet")
	desk._test_motion(Vector2(100, 100))
	for frame: int in 4: await desk.get_tree().physics_frame
	if not desk.card.quaternion.is_equal_approx(turned): failures.append("sheet drifted after releasing the rotate button")
	if not desk.player.camera.transform.is_equal_approx(eye): failures.append("object rotation moved the first-person camera")
	for step: int in 40: desk._mouse(MOUSE_BUTTON_WHEEL_UP, true)
	for x: float in [-RationCard3D.WIDTH * .5, RationCard3D.WIDTH * .5]:
		for y: float in [-RationCard3D.HEIGHT * .5, RationCard3D.HEIGHT * .5]:
			for z: float in [-desk.card.half_thickness, desk.card.half_thickness]:
				var camera_corner: Vector3 = desk.card.transform * Vector3(x, y, z)
				if camera_corner.z > -desk.player.camera.near - .015 + .00001:
					failures.append("zoom pushed a rotated document corner through the near-plane clearance")
	var close_distance: float = desk.card.position.length()
	for step: int in 40: desk._mouse(MOUSE_BUTTON_WHEEL_DOWN, true)
	if desk.card.position.length() < close_distance + 0.15: failures.append("bounded zoom did not change inspection distance")
	desk._mouse(MOUSE_BUTTON_RIGHT, true)
	desk._mouse(MOUSE_BUTTON_RIGHT, false)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid(), 3000)
	if desk.card.basis.z.dot(Vector3.FORWARD) < .99: failures.append("right click did not expose a readable reverse face")
	desk._key(KEY_R)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid(), 3000)
	if desk.card.basis.z.dot(Vector3.BACK) < .99: failures.append("R did not restore readable front orientation")
	desk._key(KEY_ESCAPE)
	if desk._object_inspector.active or desk.pause.visible or desk.player.look_locked or not desk.left_hand.visible:
		failures.append("Escape failed to return directly to the held card")
	if desk.card.position.distance_to(desk._card_hold_position()) > .001:
		failures.append("inspection exit lost the exact held pose")
	if RationDeskRules.desk(Game.state) != ink: failures.append("looking at the card modified document work")
	# Focus loss and restart must cancel a turn without leaving hidden hands,
	# a stale tween or a stuck cursor. Simulate OS notification through its handler.
	desk._key(KEY_F)
	var was_selftest: bool = desk._selftest
	desk._selftest = false
	desk._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	desk._selftest = was_selftest
	if desk._object_inspector.active or not desk.pause.visible: failures.append("focus loss failed to close inspection and pause")
	desk._key(KEY_ESCAPE)
	desk._key(KEY_F)
	desk._key(KEY_Q)
	if desk._object_inspector.active or desk.player.look_locked: failures.append("Q left handheld inspection locked")
	desk._aim(desk.workmat.global_position)
	await desk._test_until(func() -> bool: return desk._placement_preview.visible, 1000)
	if not desk._placement_preview.visible: failures.append("looking at the desk did not show a placement footprint")
	var placement: Vector3 = desk._placement_preview.global_position - Vector3.UP * .001
	desk._key(KEY_G)
	await desk._wait_hands()
	await desk._test_camera_settled()
	if desk.card.global_position.distance_to(placement) > .001 or not desk._desk_inspecting:
		failures.append("G placement disagreed with preview or failed to enter overhead")
	desk._aim(desk.props["stamp_approve"].global_position + Vector3.UP * .08)
	desk._key(KEY_E)
	await desk._wait_hands()
	desk._aim(desk.card.pixel_to_world(Vector2(540, 180)))
	for frame: int in 3: await desk.get_tree().physics_frame
	ink = RationDeskRules.desk(Game.state).duplicate(true)
	if not desk._stamp_guide.visible or desk._stamp_guide.drawing.pixel.distance_to(Vector2(540, 180)) > 1.5:
		failures.append("stamp guide did not align with the actual paper point")
	desk._table_yaw = .37
	desk.card.quaternion = Quaternion(Vector3.UP, .37) * RationCard3D.table_orientation(true)
	desk._stamp_yaw = .61
	if absf(desk._stamp_ink_angle() - (.37 - .61)) > .001:
		failures.append("stamp preview/ink angle ignored table rotation")
	# Tool travel in air and the part transferred during paper contact are
	# separate. Only contact travel may become a rotated, permanent smear.
	desk._stamp_offset = Vector2(.009, .002)
	desk._stamp_ink_offset = Vector2(.005, 0)
	var impression: Dictionary = desk._stamp_impression()
	var direction: Array = impression["smudge_direction"]
	var paper_smear: Vector2 = Vector2(float(direction[0]), float(direction[1])).rotated(float(impression["angle"])) * float(impression["smudge"])
	var world_smear: Vector3 = desk.card.global_basis * Vector3(paper_smear.x, -paper_smear.y, 0)
	if world_smear.distance_to(Vector3(.005, 0, 0)) > .00001:
		failures.append("rotated ink smudge did not follow the physical stamp slip")
	desk._stamp_offset = Vector2.ZERO
	desk._stamp_ink_offset = Vector2.ZERO
	if RationDeskRules.desk(Game.state) != ink: failures.append("transient stamp preview became permanent ink")
	desk._key(KEY_Q)
	desk._key(KEY_F)
	await desk.get_tree().create_timer(.24).timeout
	if absf(desk.player.camera.fov - desk._eye_fov) > .001 or desk.player.camera.get_parent() != desk.player.head:
		failures.append("F during overhead exit left camera FOV or parent half-restored")
	if not desk._object_inspector.active or desk._object_inspector.object != desk.props["stamp_approve"]:
		failures.append("F did not inspect the held physical tool")
	desk._key(KEY_F)
	# Existing ink and a measured partial cut survive repeated inspection and
	# cancelling a reverse animation. They are never reconstructed from a PNG.
	if not desk._execute(desk.rules.incise(Game.state, [[30.0, 285.0], [65.5556, 285.0]])):
		failures.append("partial-damage preservation fixture failed")
	if not desk._execute(desk.rules.stamp(Game.state, "approve", Vector2(540, 180), true)):
		failures.append("ink preservation fixture failed")
	desk._aim(desk.card.global_position)
	desk._key(KEY_R)
	await desk._wait_hands()
	ink = RationDeskRules.desk(Game.state).duplicate(true)
	desk._key(KEY_F)
	desk._mouse(MOUSE_BUTTON_RIGHT, true)
	desk._mouse(MOUSE_BUTTON_RIGHT, false)
	desk._key(KEY_Q)
	if RationDeskRules.desk(Game.state) != ink or desk.card.incision_openness_at(Vector2(47, 285)) < .48:
		failures.append("inspection or interrupted flip lost permanent ink/incision")
	desk._key(KEY_F)
	desk._restart()
	await desk._wait_customer()
	if desk._object_inspector.active or not desk.card.visible or desk.player.look_locked:
		failures.append("restart during inspection left a stale object or camera lock")
	print("[held inspection regressions] %s" % ("PASS: early F, same-object pickup, rotate/release, bounded zoom, reverse/reset, Escape/Q/focus/restart, placement footprint, physical stamp guide/angle" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	return failures
