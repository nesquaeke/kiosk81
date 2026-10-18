extends "res://tools/capture_desk_interaction.gd"
## Ordinary scene and viewport input. Captures pickup, inspect/rotate/zoom/flip,
## placement, stamp guide and a real misplaced + correctly positioned contact.

func run() -> void:
	output = "/tmp/kiosk81-card-inspection"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): output = arg.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	desk = load("res://scenes/kiosk/ration_desk_focus.tscn").instantiate()
	root.add_child(desk)
	await frames(70)
	await point(desk.card.global_position)
	recording = true
	desk._key(KEY_E)
	await frames(18)
	if not check(desk.card_held and not desk._desk_inspecting, "E must take the card into the hand"): return
	await shot("01_card_in_hand")
	desk._key(KEY_F)
	await frames(12)
	if not check(desk._object_inspector.active, "F must open persistent object inspection"): return
	await shot("02_inspect_front")
	button(MOUSE_BUTTON_LEFT, true)
	for step: int in 10:
		motion(Vector2(7, -3))
		await frames(1)
	button(MOUSE_BUTTON_LEFT, false)
	button(MOUSE_BUTTON_WHEEL_UP, true)
	button(MOUSE_BUTTON_WHEEL_UP, true)
	await frames(10)
	await shot("03_inspect_rotated")
	button(MOUSE_BUTTON_RIGHT, true)
	button(MOUSE_BUTTON_RIGHT, false)
	await frames(12)
	if not check(desk.card.basis.z.dot(Vector3.FORWARD) > .99, "right click must expose the reverse"): return
	await shot("04_inspect_reverse")
	desk._key(KEY_ESCAPE)
	await frames(6)
	if not check(not desk.pause.visible and not desk._object_inspector.active and desk.card_held): return
	await point(desk.workmat.global_position)
	await shot("05_placement_footprint")
	if not check(desk._placement_preview.visible, "real ray must show the actual placement footprint"): return
	desk._key(KEY_G)
	await frames(32)
	if not check(desk._desk_inspecting and not desk.card_held): return
	await shot("06_overhead")
	await point(desk.props["stamp_approve"].global_position + Vector3.UP * .08)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == desk.props["stamp_approve"], "normal cursor must reach the stamp"): return
	await point(desk.card.pixel_to_world(Vector2(540, 180)))
	await frames(8)
	if not check(desk._stamp_guide.visible and desk._stamp_guide.drawing.pixel.distance_to(Vector2(540, 180)) < 2): return
	await shot("07_stamp_projection")
	# A misplaced contact must leave ink without silently making a decision.
	await point(desk.card.pixel_to_world(Vector2(330, 105)))
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(0, 180))
	await frames(14)
	if not check(desk._stamp_contacted, "misplaced physical stamp must still contact paper"): return
	button(MOUSE_BUTTON_LEFT, false)
	await frames(12)
	var work: Dictionary = RationDeskRules.desk(root.get_node("Game").state)
	if not check(work.get("stamp", "") == "" and work.get("marks", []).size() == 1): return
	await point(desk.card.pixel_to_world(Vector2(540, 180)))
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(0, 180))
	await frames(14)
	if not check(desk._stamp_contacted, "targeted stamp must contact the paper"): return
	button(MOUSE_BUTTON_LEFT, false)
	await frames(12)
	work = RationDeskRules.desk(root.get_node("Game").state)
	if not check(work.get("stamp", "") == "approve" and work.get("marks", []).size() == 2): return
	await point(desk.homes[desk.held_tool].origin + Vector3.UP * .003)
	desk._key(KEY_G)
	await frames(12)
	if not check(desk.held_tool == null, "park the tool to show only permanent ink"): return
	await point(desk.card.pixel_to_world(Vector2(200, 200)))
	await shot("08_permanent_ink")
	desk._key(KEY_Q)
	await frames(14)
	if not check(not desk.player.look_locked and not desk._desk_inspecting): return
	recording = false
	print("[card inspection normal viewport] PASS: E pickup, F inspection, rotate/zoom/reverse, Escape, placement footprint, overhead, real stamp projection, misplaced and decision ink; %d frames" % saved)
	quit()
