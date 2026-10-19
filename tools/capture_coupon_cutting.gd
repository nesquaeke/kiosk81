extends "res://tools/capture_desk_interaction.gd"
## One complete paper-only customer through real viewport input. This capture
## never supplies a selftest cursor, changes a card, or writes campaign state.

var _partial_length: float = 0.0


func run() -> void:
	output = "/tmp/kiosk81-coupon-cutting"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="): output = argument.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	desk = load("res://scenes/kiosk/ration_desk_focus.tscn").instantiate()
	root.add_child(desk)
	await frames(70)
	var game: Node = root.get_node("Game")
	var opening_money: Dictionary = game.state.money.duplicate(true)
	var opening_stock: Dictionary = game.state.stock.duplicate(true)
	await point(desk.card.global_position)
	desk._key(KEY_E)
	await frames(18)
	if not check(desk.card_held, "the customer must hand over the same physical ration card"): return
	await point(desk.workmat.global_position)
	desk._key(KEY_G)
	await frames(34)
	if not check(desk._desk_inspecting and not desk._selftest and not desk._desk_cursor_override.is_finite(), "capture requires the normal overhead viewport"): return
	await point(desk.props["scissors"].global_position + Vector3.UP * .015)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == desk.props["scissors"], "normal cursor must pick up the actual scissors"): return
	var rectangle: Rect2 = RationCardView.coupon_rect(0)
	await paper_point(rectangle.position)
	await frames(8)
	if not check(desk._cut_guide.visible, "the physical cutting guide must be visible while aiming at paper"): return
	recording = true
	await shot("coupon-guide")
	button(MOUSE_BUTTON_LEFT, true)
	await frames(2)
	if not check(desk._cut_index >= 0, "native pointer must start the scissors on the coupon boundary"): return
	# Native desktop pixels round the ray slightly. Measure from that actual
	# sampled start instead of claiming an ideal subpixel pointer position.
	var sampled_start: Vector2 = desk._cut_tip
	var partial_end: Vector2 = sampled_start + Vector2(.02 * 640.0 / RationCard3D.WIDTH, 0)
	desk._key_down(KEY_SHIFT, true)
	if not await trace(partial_end): return
	_partial_length = desk._cut_length_m
	button(MOUSE_BUTTON_LEFT, false)
	desk._key_down(KEY_SHIFT, false)
	await frames(12)
	var work: Dictionary = RationDeskRules.desk(game.state)
	if not check(absf(_partial_length - .02) < .0015 and not work.get("incisions", []).is_empty(), "a two-centimetre cut must persist at its real measured length"): return
	if not check(work.get("cuts", []).is_empty() and work.get("collected", []).is_empty() and desk._find_coupon("meat") == null, "a short cut must neither detach nor archive the coupon"): return
	await shot("coupon-two-centimetres")
	# Re-enter at the actual endpoint and continue all four sides. Corners are
	# observed while the blade opens; pointer motion never fills missing edges.
	await paper_point(partial_end)
	button(MOUSE_BUTTON_LEFT, true)
	if not await trace(Vector2(rectangle.end.x, rectangle.position.y)): return
	await paper_point(rectangle.end)
	await frames(1)
	if not await wait_until(func() -> bool: return desk._cut_controller.aligning, 60):
		if not check(false, "a ninety-degree corner must visibly open before turning"): return
	await frames(3)
	await shot("coupon-corner")
	if not await reach_sampled_target(): return
	if not await trace(Vector2(rectangle.position.x, rectangle.end.y)): return
	if not await trace(rectangle.position): return
	button(MOUSE_BUTTON_LEFT, false)
	await frames(4)
	var coupon: CouponFragment3D = desk._find_coupon("meat")
	if not check(coupon != null, "the fully severed coupon must be a separate physical object"): return
	if not await wait_until(func() -> bool: return not coupon.get_meta("settling", false), 120):
		if not check(false, "the loose coupon must settle on the desk"): return
	if not check(not coupon.archived and RationDeskRules.desk(game.state).get("collected", []).is_empty(), "detachment must not automatically file the coupon"): return
	await shot("coupon-loose")
	if not await park_tool(): return
	await point(coupon.global_position + Vector3.UP * .001)
	if not check(desk._ray().get("collider") == coupon, "the normal cursor must reach the loose paper"): return
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == coupon and coupon.held, "E must take the actual severed piece into the hand"): return
	desk._key(KEY_Q)
	await frames(16)
	desk._key(KEY_F)
	await frames(12)
	if not check(desk._object_inspector.object == coupon, "F must inspect the same physical fragment"): return
	var initial_distance: float = desk._object_inspector._distance
	button(MOUSE_BUTTON_WHEEL_UP, true)
	button(MOUSE_BUTTON_WHEEL_UP, false)
	await frames(4)
	if not check(desk._object_inspector._distance < initial_distance - .001, "normal wheel-up must actually bring a readable flat coupon closer"): return
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(42, -24))
	button(MOUSE_BUTTON_LEFT, false)
	await frames(10)
	await shot("coupon-inspect")
	button(MOUSE_BUTTON_RIGHT, true)
	button(MOUSE_BUTTON_RIGHT, false)
	await frames(10)
	await shot("coupon-reverse")
	desk._key(KEY_F)
	# An ordinary free tabletop drop is deliberately not a filing action.
	await point(desk.workmat.global_position + Vector3(-.27, .01, .16))
	desk._key(KEY_G)
	await frames(18)
	if not check(desk.held_tool == null and not coupon.archived and RationDeskRules.desk(game.state).get("collected", []).is_empty(), "dropping the coupon on the desk must preserve an unfiled piece"): return
	await point(coupon.global_position + Vector3.UP * .001)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == coupon, "a dropped fragment must remain pickable"): return
	await point(desk.coupon_bin.global_position + Vector3.UP * .018)
	desk._key(KEY_G)
	await frames(1)
	if not check(RationDeskRules.desk(game.state).get("collected", []).is_empty(), "filing must wait for physical contact with the tray"): return
	await shot("coupon-filing")
	if not await wait_until(func() -> bool: return coupon.archived, 120):
		if not check(false, "the piece must reach the filing tray"): return
	if not check(desk.held_tool == null and coupon.collision_layer == 0 and RationDeskRules.desk(game.state).get("collected", []) == ["meat"], "physical tray contact must archive exactly one requested coupon"): return
	await shot("coupon-filed")
	recording = false
	if not await approve_and_return(): return
	work = RationDeskRules.desk(game.state)
	if not check(work.get("done", false) and work.get("results", []).size() == 1 and work["results"][0]["correct"], "the normal paper-only customer must complete correctly"): return
	if not check(game.state.money == opening_money and game.state.stock == opening_stock, "paperwork must not change money or provisions"): return
	if not check(not desk._selftest and not desk._desk_cursor_override.is_finite(), "normal capture must never enable the selftest cursor"): return
	print("[coupon normal viewport capture] PASS: guide, %.2f cm persistent fine cut, opened corner, loose physical coupon, F/rotate/zoom/flip, free-table drop, contact-only filing, stamp and return, unchanged economy; %d frames" % [_partial_length * 100.0, saved])
	quit()


func wait_until(predicate: Callable, limit: int = 300) -> bool:
	for index: int in limit:
		if predicate.call(): return true
		await frames(1)
	return predicate.call()


func trace(pixel: Vector2) -> bool:
	await paper_point(pixel)
	var sampled: Vector2 = desk._paper_pixel()
	var error: Vector2 = (sampled - pixel).abs()
	if not check(maxf(error.x, error.y) < PaperCutGeometry.EDGE_TOLERANCE_PX, "the native pointer must land within half a millimetre of the requested cut: %s / %s" % [pixel, sampled]): return false
	return await reach_sampled_target()


func paper_point(pixel: Vector2) -> void:
	# The display accepts whole mouse pixels. Round once before the native warp
	# instead of letting float conversion truncate the chosen point downward.
	var screen: Vector2 = desk.player.camera.unproject_position(desk.card.pixel_to_world(pixel))
	root.warp_mouse(screen.round())
	await frames(4)


func reach_sampled_target() -> bool:
	var sampled: Vector2 = desk._paper_pixel()
	var reached: bool = await wait_until(func() -> bool: return desk._cut_index >= 0 and desk._cut_tip.distance_to(sampled) < .05, 600)
	return check(reached, "native blade failed to reach the sampled target: %s / %s" % [desk._cut_tip, sampled])


func park_tool() -> bool:
	if not check(desk.held_tool != null, "parking requires a held tool"): return false
	await point(desk.homes[desk.held_tool].origin + Vector3.UP * .003)
	desk._key(KEY_G)
	await frames(12)
	return check(desk.held_tool == null, "the actual scissors or stamp must return to an accessible home: " + desk.message.text)


func approve_and_return() -> bool:
	await point(desk.card.global_position)
	desk._key(KEY_E)
	await frames(28)
	if not check(desk._desk_inspecting, "the table must reopen after fragment inspection"): return false
	await point(desk.props["stamp_approve"].global_position + Vector3.UP * .08)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == desk.props["stamp_approve"], "the onay stamp must be reachable"): return false
	await point(desk.card.pixel_to_world(Vector2(540, 183)))
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(0, 180))
	if not await wait_until(func() -> bool: return desk._stamp_contacted, 100): return check(false, "the decision stamp must physically contact the paper")
	await frames(9)
	button(MOUSE_BUTTON_LEFT, false)
	await frames(14)
	if not await park_tool(): return false
	desk._key(KEY_Q)
	await frames(16)
	await point(desk.card.global_position)
	desk._key(KEY_R)
	await frames(16)
	await point(desk.customer_target.global_position + Vector3.UP * .4)
	desk._key(KEY_E)
	await frames(18)
	return true
