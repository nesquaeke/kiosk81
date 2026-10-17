extends RefCounted

func run(desk: Node3D) -> PackedStringArray:
	var failures: PackedStringArray = []
	desk._restart()
	await desk._wait_customer()
	desk.player.position = Vector3(0, 0.025, -1.25)
	await desk.get_tree().physics_frame
	desk._aim(desk.card.global_position)
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	await desk._wait_hands()
	if not desk.card_held: failures.append("one click did not take the offered document into the hand")
	desk._aim(desk.workmat.global_position)
	desk._key(KEY_G)
	await desk._wait_hands()
	await desk._test_camera_settled()
	if not desk._desk_inspecting or (-desk.player.camera.global_basis.z).dot(Vector3.DOWN) < .995:
		failures.append("placing the held card did not enter a true overhead view")
	var original: Vector3 = desk.card.global_position
	desk._aim(original)
	desk._mouse(MOUSE_BUTTON_LEFT, true)
	desk._aim(original + Vector3(.07, 0, .025))
	for frame: int in 12: await desk.get_tree().physics_frame
	if not desk._paper_dragging or desk.card.position.y < original.y + .025 or desk.card.position.distance_to(original) < .045:
		failures.append("direct paper dragging did not lift and move the world card")
	var anchor: Vector3 = desk.card.global_position
	desk._mouse(MOUSE_BUTTON_RIGHT, true)
	desk._aim(anchor + Vector3(.10, 0, .04))
	desk._test_motion(Vector2(55, 0))
	for frame: int in 4: await desk.get_tree().physics_frame
	if Vector2(desk.card.position.x - anchor.x, desk.card.position.z - anchor.z).length() > .004:
		failures.append("rotation translated the lifted sheet instead of holding its anchor")
	desk._mouse(MOUSE_BUTTON_RIGHT, false)
	desk._mouse(MOUSE_BUTTON_LEFT, false)
	await desk._wait_hands()
	if desk._paper_dragging or desk.card.position.y > 0.979 or absf(desk._table_yaw) < .1:
		failures.append("paper release/rotation did not settle back onto the physical surface")
	var rotation: float = desk._table_yaw
	desk._aim(desk.card.global_position)
	desk._key(KEY_F)
	await desk._wait_hands()
	if desk.card.front_showing or desk.card.global_basis.z.dot(Vector3.DOWN) < .99:
		failures.append("rotated card did not physically flip onto its back")
	if absf(desk._table_yaw - rotation) > .001: failures.append("flipping erased table rotation")
	desk._key(KEY_Q)
	await desk._test_camera_settled()
	desk._aim(Vector3(-.90, .96, -1.90))
	desk._key(KEY_E)
	await desk._test_camera_settled()
	if not desk._desk_inspecting: failures.append("the broad tabletop could not reopen overhead inspection")
	print("[direct desk regressions] %s" % ("PASS: single-click pickup, placement overhead, paper lift/drag/rotate/release, back flip and broad table interaction" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	desk._restart()
	return failures
