extends RefCounted


func run(desk: Node3D) -> PackedStringArray:
	var failures: PackedStringArray = []
	desk._restart()
	await desk._wait_customer()
	desk.player.position = Vector3(0, .025, -1.25)
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._key(KEY_E)
	await desk._wait_hands()
	desk._key(KEY_F)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	var work: Dictionary = RationDeskRules.desk(Game.state).duplicate(true)
	desk._key(KEY_T)
	await desk._test_until(func() -> bool: return desk.card.inspection_light_strength > .98)
	if not desk._object_inspector.backlight_enabled or desk.card.inspection_light_strength < .98:
		failures.append("T did not light the physical paper in inspection")
	await desk._capture("18_paper_transmission_front")
	var direction: Vector3 = desk.card.materials[0].get_shader_parameter("inspection_light_direction_local")
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._test_motion(Vector2(75, -35))
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	for frame: int in 3: await desk.get_tree().process_frame
	var tilted_direction: Vector3 = desk.card.materials[0].get_shader_parameter("inspection_light_direction_local")
	if direction.distance_to(tilted_direction) < .25:
		failures.append("tilting the sheet did not change the transmitted-light incidence")
	await desk._capture("19_paper_transmission_tilt")
	desk._mouse(MOUSE_BUTTON_RIGHT, true)
	desk._mouse(MOUSE_BUTTON_RIGHT, false)
	await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
	if desk.card.basis.z.dot(Vector3.FORWARD) < .99:
		failures.append("backlight inspection could not expose the reverse face")
	await desk._capture("20_paper_transmission_reverse")
	for material: ShaderMaterial in desk.card.materials:
		if float(material.get_shader_parameter("inspection_backlight")) < .98:
			failures.append("reverse paper did not share the physical light state")
	if RationDeskRules.desk(Game.state) != work:
		failures.append("light/tilt inspection altered evidence or decided authenticity")
	desk._key(KEY_ESCAPE)
	if desk.card.inspection_light_strength != 0 or desk._object_inspector.backlight_enabled or desk.player.look_locked:
		failures.append("closing inspection left a transmission/light or look lock")
	desk._key(KEY_F)
	if desk._object_inspector.backlight_enabled: failures.append("light was silently enabled on next inspection")
	desk._key(KEY_T)
	var selftest: bool = desk._selftest
	desk._selftest = false
	desk._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	desk._selftest = selftest
	if desk.card.inspection_light_strength != 0 or not desk.pause.visible:
		failures.append("focus loss did not clear paper light and pause")
	desk._key(KEY_ESCAPE)
	desk._aim(desk.workmat.global_position)
	desk._key(KEY_G)
	await desk._wait_hands()
	await desk._test_camera_settled()
	desk._aim(desk.props["book"].global_position + Vector3.UP * .012)
	desk._key(KEY_E)
	await desk._wait_hands()
	desk._key(KEY_Q)
	await desk._test_camera_settled()
	desk._key(KEY_F)
	if desk._object_inspector.object != desk.props["book"]:
		failures.append("physical evidence reference could not be inspected")
	else:
		desk._mouse(MOUSE_BUTTON_RIGHT, true)
		desk._mouse(MOUSE_BUTTON_RIGHT, false)
		await desk._test_until(func() -> bool: return not desk._object_inspector._turn.is_valid())
		var reference: Node3D = desk.props["book"].get_node("ClassAndIssuerReference")
		var leaf: MeshInstance3D = reference.get_node("WorldPaperEvidenceLeaf") as MeshInstance3D
		var camera_normal: Vector3 = desk.player.camera.global_basis.inverse() * leaf.global_basis.y
		if camera_normal.dot(Vector3.BACK) < .99:
			failures.append("reversed reference did not expose its printed evidence guide")
		await desk._capture("21_paper_comparison_guide")
		desk._key(KEY_T)
		if desk._object_inspector.backlight_enabled:
			failures.append("paper light incorrectly activated on a non-paper tool")
	desk._restart()
	await desk._wait_customer()
	if desk.card.inspection_light_strength != 0 or desk._object_inspector.active:
		failures.append("restart kept a previous document's transmission state")
	print("[paper inspection regressions] %s" % ("PASS: T light/tilt/reverse, no evidence mutation, Esc/focus/restart cleanup, physical reverse comparison guide" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	return failures
