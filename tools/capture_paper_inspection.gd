extends "res://tools/capture_desk_interaction.gd"
## Actual first customer, normal viewport inputs: transmitted paper light,
## free tilt/reverse, cleanup and the same physical book's underside guide.

func run() -> void:
	output = "/tmp/kiosk81-paper-inspection"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): output = arg.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	desk = load("res://scenes/kiosk/ration_desk_focus.tscn").instantiate()
	root.add_child(desk)
	await frames(70)
	await point(desk.card.global_position)
	desk._key(KEY_E)
	await frames(18)
	desk._key(KEY_F)
	await frames(12)
	if not check(desk.card_held and desk._object_inspector.active): return
	recording = true
	await shot("01_normal_paper")
	desk._key(KEY_T)
	await frames(14)
	if not check(desk.card.inspection_light_strength > .98): return
	await shot("02_transmitted_light")
	button(MOUSE_BUTTON_LEFT, true)
	for step: int in 12:
		motion(Vector2(5, -1.5))
		await frames(1)
	button(MOUSE_BUTTON_LEFT, false)
	await shot("03_tilted_fibres")
	button(MOUSE_BUTTON_RIGHT, true)
	button(MOUSE_BUTTON_RIGHT, false)
	await frames(12)
	if not check(desk.card.basis.z.dot(Vector3.FORWARD) > .99): return
	await shot("04_reverse_watermark")
	desk._key(KEY_ESCAPE)
	if not check(desk.card.inspection_light_strength == 0 and not desk.pause.visible): return
	await point(desk.workmat.global_position)
	desk._key(KEY_G)
	await frames(32)
	await point(desk.props["book"].global_position + Vector3.UP * .012)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == desk.props["book"]): return
	desk._key(KEY_Q)
	await frames(14)
	desk._key(KEY_F)
	await frames(12)
	button(MOUSE_BUTTON_RIGHT, true)
	button(MOUSE_BUTTON_RIGHT, false)
	await frames(12)
	if not check(desk._object_inspector.object == desk.props["book"]): return
	await shot("05_physical_evidence_guide")
	desk._key(KEY_F)
	await frames(12)
	if not check(not desk._object_inspector.active and not desk.player.look_locked): return
	if not check(not desk._selftest and not desk._desk_cursor_override.is_finite()): return
	recording = false
	print("[paper normal viewport capture] PASS: original card, T transmission, free tilt, physical reverse, light cleanup, same-book underside evidence guide; %d frames" % saved)
	quit()
