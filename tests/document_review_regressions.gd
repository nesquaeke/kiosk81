extends RefCounted
## Physical paper separation must work before the player chooses a stamp.

func run(desk: Node3D) -> PackedStringArray:
	var failures: PackedStringArray = []
	desk._restart()
	await desk._wait_customer()
	desk.player.position = Vector3(0, 0.025, -1.25)
	desk.player.velocity = Vector3.ZERO
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	await desk._wait_hands()
	desk._aim(desk.workmat.global_position)
	desk._key(KEY_G)
	await desk._wait_hands()
	await desk._test_camera_settled()
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	await desk._test_camera_settled()
	desk._aim(desk.props["scissors"].global_position + Vector3.UP * .012)
	desk._key(KEY_E)
	await desk._wait_hands()
	if desk.held_tool != desk.props["scissors"]:
		failures.append("unapproved cutting could not pick up scissors")
	else:
		var rect: Rect2 = RationCardView.coupon_rect(0)
		desk._aim(desk.card.pixel_to_world(rect.position))
		desk._mouse(MOUSE_BUTTON_LEFT, true)
		for corner: Vector2 in [Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]:
			if not await desk._test_trace(corner): failures.append("unapproved perimeter travel timed out")
		desk._mouse(MOUSE_BUTTON_LEFT, false)
		if desk.card.has_paper_at(rect.get_center()) or desk._tokens.size() != 1: failures.append("severed paper waited for approval or duplicated its fragment")
		if not RationDeskRules.desk(Game.state).get("cuts", []).is_empty(): failures.append("unapproved damage granted an entitlement")
		desk._aim(desk.homes[desk.held_tool].origin + Vector3.UP * .003)
		desk._key(KEY_G)
		await desk._wait_hands()
		desk._aim(desk.props["stamp_approve"].global_position + Vector3.UP * .08)
		desk._key(KEY_E)
		await desk._wait_hands()
		if desk.held_tool != desk.props["stamp_approve"]:
			failures.append("cut-first flow could not pick up stamp")
		else:
			desk._aim(desk.card.pixel_to_world(Vector2(540, 183)))
			desk._mouse(MOUSE_BUTTON_LEFT, true)
			desk._test_motion(Vector2(0, 180))
			if not await desk._test_until(func() -> bool: return desk._stamp_contacted): failures.append("cut-first stamp failed to contact")
			desk._mouse(MOUSE_BUTTON_LEFT, false)
			await desk._wait_hands()
			if RationDeskRules.desk(Game.state).get("cuts", []) != ["meat"] or desk._tokens.size() != 1: failures.append("approval after cutting did not process exactly one original fragment")
			desk._aim(desk.homes[desk.held_tool].origin + Vector3.UP * .003)
			desk._key(KEY_G)
			await desk._wait_hands()
			if not await desk._test_file_coupon("meat"): failures.append("cut-first physical coupon could not be filed")
			desk._key(KEY_Q)
			await desk._test_camera_settled()
			desk._aim(desk.card.global_position)
			desk._key(KEY_R)
			await desk._wait_hands()
			desk._aim(desk.customer_target.global_position + Vector3.UP * .4)
			desk._key(KEY_E)
			await desk._wait_hands()
			if not RationDeskRules.desk(Game.state).get("done", false): failures.append("cut-first card handback failed")
	print("[document regressions] %s" % ("PASS: unapproved physical separation, cut-first approval, single fragment and handback" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	desk._restart()
	return failures
