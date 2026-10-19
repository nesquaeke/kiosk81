extends RefCounted
## Physical companion identity, reversible two-document inspection and printed
## reference pages. Fixtures move the player; interactions use ordinary input.


func run(desk: Node3D) -> PackedStringArray:
	var failures: PackedStringArray = []
	var previous_review_day: bool = desk.review_day_only
	desk._start_review_day()
	await desk._wait_customer()
	var identity: IdentityDocument3D = desk.identity_document
	var reference: RationDeskReference = desk.props["book"].get_node("ClassAndIssuerReference")
	var identity_instance: int = identity.get_instance_id()
	if desk.rules.cases.size() != 8:
		failures.append("review-day entry did not select the eight comparison cases")
	if identity.identity != desk.rules.current(Game.state).get("identity", {}) or identity.identity.is_empty():
		failures.append("current customer's physical identity was not configured")
	if identity.visible or identity.collision_layer != 0:
		failures.append("companion identity appeared or blocked input before handoff")
	desk.player.position = Vector3(0, .025, -1.25)
	desk.player.velocity = Vector3.ZERO
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	if identity.collision_layer != 0:
		failures.append("identity became selectable before its handoff animation settled")
	await desk._wait_hands()
	await desk._test_until(func() -> bool: return identity.collision_layer == 2, 1200)
	if not identity.visible or identity.collision_layer != 2 or identity.global_position.distance_to(desk.homes[identity].origin) > .001:
		failures.append("card handoff did not deliver the physical companion identity onto the table")
	if not desk.card_held:
		failures.append("review-day E failed to receive the offered card")
		await _restore(desk, previous_review_day)
		return _report(failures)
	desk._aim(desk.workmat.global_position)
	desk._key(KEY_G)
	await desk._wait_hands()
	await desk._test_camera_settled()
	# Test the initial view before _aim, which is allowed to pan test fixtures.
	var frame: Rect2 = desk.get_viewport().get_visible_rect().grow(-24)
	if not desk._desk_inspecting or desk.player.camera.is_position_behind(identity.global_position) or not frame.has_point(desk.player.camera.unproject_position(identity.global_position)):
		failures.append("companion identity was unreachable in the initial overhead viewport")
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var world_corner: Vector3 = identity.to_global(Vector3(corner.x * IdentityDocument3D.WIDTH * .5, corner.y * IdentityDocument3D.HEIGHT * .5, 0))
		if not frame.has_point(desk.player.camera.unproject_position(world_corner)):
			failures.append("initial overhead cropped part of the physical identity document")
	# Tall adjacent stamp proxies must not occlude the empty parking surface.
	# Exercise the actual physics ray, including the initial perspective view.
	for kind: String in ["approve", "reject", "seize"]:
		var tool: Interactable = desk.props["stamp_" + kind]
		desk._aim(tool.global_position + Vector3.UP * .08)
		desk._key(KEY_E)
		await desk._wait_hands()
		if desk.held_tool != tool:
			failures.append("initial view could not pick up " + kind + " stamp")
			await _restore(desk, previous_review_day)
			return _report(failures)
		desk._aim(desk.homes[tool].origin + Vector3.UP * .003)
		var support: Node = desk._ray().get("collider")
		if support != desk.workmat and (support == null or support.get_meta("surface", "") != "table"):
			failures.append("neighboring tool blocked the empty " + kind + " stamp parking surface")
		desk._key(KEY_G)
		await desk._wait_hands()
		if desk.held_tool != null:
			failures.append("stamp could not be returned to its empty table position: " + kind)
			await _restore(desk, previous_review_day)
			return _report(failures)
	var work: Dictionary = RationDeskRules.desk(Game.state).duplicate(true)
	desk._aim(identity.global_position + Vector3.UP * .003)
	if desk._ray().get("collider") != identity:
		failures.append("visible companion identity could not be reached by the desk ray")
	desk._key(KEY_E)
	await desk._wait_hands()
	if desk.held_tool != identity:
		failures.append("E did not pick up the real companion identity")
		await _restore(desk, previous_review_day)
		return _report(failures)
	desk._key(KEY_Q)
	await desk._test_camera_settled()
	var held_identity: Transform3D = identity.transform
	desk._key(KEY_F)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	if not desk._object_inspector.active or desk._object_inspector.object != identity:
		failures.append("F did not inspect the same held identity document")
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._test_motion(Vector2(63, -29))
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	desk._mouse(MOUSE_BUTTON_WHEEL_UP, true)
	desk._mouse(MOUSE_BUTTON_RIGHT, true)
	desk._mouse(MOUSE_BUTTON_RIGHT, false)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	if identity.basis.z.dot(Vector3.FORWARD) < .99:
		failures.append("identity inspection did not expose its physical reverse")
	var page: int = reference.evidence_page
	desk._key(KEY_T)
	desk._key(KEY_TAB)
	if desk._object_inspector.backlight_enabled or reference.evidence_page != page:
		failures.append("paper light or reference-page input affected the identity")
	desk._key(KEY_Q)
	if desk._object_inspector.active or desk.player.look_locked or identity.get_parent() != desk.player.camera or not identity.transform.is_equal_approx(held_identity):
		failures.append("identity inspection exit did not restore the exact held pose and controls")
	if RationDeskRules.desk(Game.state) != work:
		failures.append("identity pickup or inspection altered document evidence/work")
	# Both originals stay held; C alternates the inspector without making copies.
	desk._aim(desk.card.global_position)
	desk._key(KEY_R)
	await desk._wait_hands()
	if not desk.card_held or desk.held_tool != identity:
		failures.append("card could not be taken while the companion identity was held")
	var card_pose: Transform3D = desk.card.transform
	held_identity = identity.transform
	work = RationDeskRules.desk(Game.state).duplicate(true)
	desk._key(KEY_F)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	desk._key(KEY_TAB)
	if reference.evidence_page != page:
		failures.append("Tab on a ration card changed the reference book")
	desk._mouse(MOUSE_BUTTON_RIGHT, true)
	desk._mouse(MOUSE_BUTTON_RIGHT, false)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	for step: int in 2: desk._mouse(MOUSE_BUTTON_WHEEL_UP, true)
	var card_comparison_pose: Transform3D = desk.card.transform
	if desk.card.basis.z.dot(Vector3.FORWARD) < .99:
		failures.append("comparison fixture did not expose the card's reverse")
	desk._key(KEY_T)
	await desk._test_until(func() -> bool: return desk.card.inspection_light_strength > .98, 1200)
	desk._key(KEY_C)
	if desk._object_inspector.object != identity or desk.card.visible or not identity.visible or desk.card.inspection_light_strength != 0 or desk._object_inspector.backlight_enabled:
		failures.append("C did not switch card to identity and clear paper-only lighting")
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._test_motion(Vector2(-24, 18))
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	for step: int in 3: desk._mouse(MOUSE_BUTTON_WHEEL_DOWN, true)
	var identity_comparison_pose: Transform3D = identity.transform
	desk._key(KEY_C)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	if desk._object_inspector.object != desk.card or not desk.card.visible or identity.visible:
		failures.append("C did not switch back to the original ration card")
	if not desk.card.transform.is_equal_approx(card_comparison_pose) or not desk._inspection_back or desk.card.basis.z.dot(Vector3.FORWARD) < .99:
		failures.append("C roundtrip lost the card's reverse orientation or inspection zoom")
	desk._key(KEY_C)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	if not identity.transform.is_equal_approx(identity_comparison_pose):
		failures.append("C roundtrip lost the identity's inspection orientation or zoom")
	desk._key(KEY_C)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	desk._key(KEY_Q)
	if not desk.card.visible or not identity.visible or not desk.card.transform.is_equal_approx(card_pose) or not identity.transform.is_equal_approx(held_identity):
		failures.append("two-document comparison did not restore both physical held objects")
	if RationDeskRules.desk(Game.state) != work or identity.get_instance_id() != identity_instance:
		failures.append("C comparison mutated work or replaced the identity object")
	for key: int in [KEY_W, KEY_A, KEY_S, KEY_D]:
		desk._key(KEY_F)
		desk._key(KEY_C)
		desk._key(key)
		if desk._object_inspector.active or desk.player.look_locked or desk.pause.visible:
			failures.append("movement key %d left two-document inspection locked" % key)
	desk._key(KEY_F)
	desk._key(KEY_C)
	var selftest: bool = desk._selftest
	desk._selftest = false
	desk._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	desk._selftest = selftest
	if desk._object_inspector.active or not desk.pause.visible or not desk.card.visible or not identity.visible or identity.collision_layer != 0:
		failures.append("focus loss failed to close companion inspection safely")
	desk._key(KEY_ESCAPE)
	desk._key(KEY_F)
	desk._key(KEY_C)
	desk._restart()
	await desk._wait_customer()
	if desk._object_inspector.active or desk.player.look_locked or desk.held_tool != null or identity.visible or identity.collision_layer != 0 or identity.get_parent() != desk:
		failures.append("restart during identity inspection left stale visibility, collision or a held object")
	# A transfer callback from the previous epoch cannot resurrect the document.
	desk.player.position = Vector3(0, .025, -1.25)
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	desk._restart()
	await desk.get_tree().create_timer(.42).timeout
	await desk._wait_customer()
	if identity.visible or identity.collision_layer != 0 or not identity.global_transform.is_equal_approx(desk.homes[identity]):
		failures.append("cancelled identity handoff later restored stale visibility/collision")
	# Reference Tab changes only the underside printing and faces it toward the
	# same camera; the class/issuer page and mesh/collider dimensions stay fixed.
	desk.player.position = Vector3(0, .025, -1.25)
	await desk.get_tree().physics_frame
	desk._aim(desk.props["book"].global_position + Vector3.UP * .012)
	desk._key(KEY_E)
	await desk._wait_hands()
	if desk.held_tool != desk.props["book"]:
		failures.append("physical comparison book could not be picked up")
	else:
		var book_pose: Transform3D = desk.props["book"].transform
		var front_leaf: MeshInstance3D = reference.get_node("WorldClassAndIssuerLeaf")
		var back_leaf: MeshInstance3D = reference.get_node("WorldPaperEvidenceLeaf")
		var front_pose: Transform3D = front_leaf.transform
		var back_pose: Transform3D = back_leaf.transform
		var front_viewport: int = reference.page_viewport.get_instance_id()
		page = reference.evidence_page
		work = RationDeskRules.desk(Game.state).duplicate(true)
		desk._key(KEY_F)
		desk._key(KEY_TAB)
		await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
		if reference.evidence_page != (page + 1) % 2 or reference._evidence_leaf.page != reference.evidence_page:
			failures.append("book Tab did not change the existing physical evidence printing")
		var camera_normal: Vector3 = desk.player.camera.global_basis.inverse() * back_leaf.global_basis.y
		if camera_normal.dot(Vector3.BACK) < .99:
			failures.append("book Tab did not expose its readable physical underside")
		desk._key(KEY_T)
		if desk._object_inspector.backlight_enabled:
			failures.append("T enabled paper transmission on the reference book")
		desk._key(KEY_TAB)
		await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
		if reference.evidence_page != page or reference.page_viewport.get_instance_id() != front_viewport or not front_leaf.transform.is_equal_approx(front_pose) or not back_leaf.transform.is_equal_approx(back_pose):
			failures.append("reference page cycling replaced the front page or altered physical leaf geometry")
		desk._key(KEY_Q)
		if not desk.props["book"].transform.is_equal_approx(book_pose) or RationDeskRules.desk(Game.state) != work:
			failures.append("reference inspection changed document work or lost its held pose")
	await _seize_with_held_identity(desk, failures)
	await _restore(desk, previous_review_day)
	return _report(failures)


func _seize_with_held_identity(desk: Node3D, failures: PackedStringArray) -> void:
	# An intentionally wrong seizure is permitted on valid rc09. This checks
	# the physical two-document handoff, not the already-covered audit verdict.
	desk._restart()
	await desk._wait_customer()
	desk.player.position = Vector3(0, .025, -1.25)
	desk.player.velocity = Vector3.ZERO
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	await desk._wait_hands()
	desk._aim(desk.workmat.global_position)
	desk._key(KEY_G)
	await desk._wait_hands()
	await desk._test_camera_settled()
	desk._aim(desk.props["stamp_seize"].global_position + Vector3.UP * .08)
	desk._key(KEY_E)
	await desk._wait_hands()
	if desk.held_tool != desk.props["stamp_seize"]:
		failures.append("held-identity seizure fixture could not pick up its physical stamp")
		return
	desk._aim(desk.card.pixel_to_world(Vector2(540, 183)))
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._test_motion(Vector2(0, 180))
	var contacted: bool = await desk._test_until(func() -> bool: return desk._stamp_contacted, 1800)
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	await desk._wait_hands()
	if not contacted or RationDeskRules.desk(Game.state).get("stamp") != "seize":
		failures.append("held-identity seizure fixture did not create its real physical decision")
		return
	desk._aim(desk.homes[desk.held_tool].origin + Vector3.UP * .003)
	desk._key(KEY_G)
	await desk._wait_hands()
	var identity: IdentityDocument3D = desk.identity_document
	desk._aim(identity.global_position + Vector3.UP * .003)
	desk._key(KEY_E)
	await desk._wait_hands()
	desk._aim(desk.card.global_position)
	desk._key(KEY_R)
	await desk._wait_hands()
	if desk.held_tool != identity or not desk.card_held:
		failures.append("seizure could not hold both original documents")
		return
	desk._aim(desk.drawer.global_position + Vector3.UP * .04)
	var before_return: Transform3D = identity.global_transform
	desk._key(KEY_E)
	if not RationDeskRules.desk(Game.state).get("done", false) or RationDeskRules.desk(Game.state).get("location") != "seize":
		failures.append("native E did not complete seizure while holding the identity")
		return
	if not identity.global_transform.is_equal_approx(before_return):
		failures.append("identity teleported from the held pose when the ration card was seized")
	if desk.held_tool != null or desk.right_hand.visible or desk.right_hand.get_parent() != desk.player.camera or identity.get_parent() != desk or identity.collision_layer != 0:
		failures.append("seizure did not clear the identity's held hand and collision")
	await desk._wait_hands()
	if identity.visible or desk.card.visible or identity.collision_layer != 0 or identity.global_position.distance_to(Vector3(-.10, 1.08, -2.79)) > .001:
		failures.append("identity was not returned and hidden separately from the seized ration card")


func _restore(desk: Node3D, previous_review_day: bool) -> void:
	desk.review_day_only = previous_review_day
	desk._load_cases()
	desk._restart()
	await desk._wait_customer()


func _report(failures: PackedStringArray) -> PackedStringArray:
	print("[evidence review regressions] %s" % ("PASS: physical ID handoff/reach/pickup, F/C view memory and exact held restoration, no evidence mutation, reference Tab pages, Q/WASD/focus/restart, stale transfer cleanup and held-ID seizure handoff" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	return failures
