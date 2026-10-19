extends "res://tools/capture_coupon_cutting.gd"
## One original, valid customer through native viewport input. This records
## physical pad contact, two different hand impressions, wet finger transfer,
## drying, the requested coupon and correct handback. No campaign, reservoir,
## clock, inspection state or selftest cursor is supplied by the capture.

var _light_mark: Dictionary = {}
var _firm_mark: Dictionary = {}
var _pad_load_before: float = 0.0
var _pad_load_after: float = 0.0


func run() -> void:
	output = "/tmp/kiosk81-ink-desk"
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
	if not check(desk.card_held, "native handoff must take the same physical ration card"): return
	await point(desk.workmat.global_position)
	desk._key(KEY_G)
	await frames(34)
	if not check(desk._desk_inspecting and not desk._selftest and not desk._desk_cursor_override.is_finite(), "capture requires normal overhead input"): return
	recording = true
	await shot("ink-workstation")
	await point(desk.props["stamp_approve"].global_position + Vector3.UP * .08)
	if not check(desk._ray().get("collider") == desk.props["stamp_approve"], "the actual onay stamp must be reachable"): return
	desk._key(KEY_E)
	await frames(14)
	if not check(desk.held_tool == desk.props["stamp_approve"], "E must take the physical onay stamp"): return
	_pad_load_before = desk._stamp_inks["approve"].load
	await point(desk.ink_pad.felt_world_point())
	if not check(desk._ray().get("collider") == desk.ink_pad, "the felt must be reachable with the normal cursor"): return
	button(MOUSE_BUTTON_LEFT, true)
	await frames(3)
	if not check(desk._stamp_charging and desk._stamp_surface == "pad" and not desk._stamp_contacted, "hovering above felt must not count as contact"): return
	if not check(is_equal_approx(desk._stamp_inks["approve"].load, _pad_load_before), "approaching the pad must not refill the reservoir"): return
	await shot("ink-pad-approach")
	motion(Vector2(0, 180))
	if not await wait_until(func() -> bool: return desk._stamp_contacted and desk.ink_pad.pressure > 0.0, 120):
		if not check(false, "the die must physically reach and compress the felt"): return
	if not await wait_until(func() -> bool: return desk._stamp_dwell >= .35, 120):
		if not check(false, "the stamp must absorb ink during real felt contact"): return
	_pad_load_after = desk._stamp_inks["approve"].load
	if not check(_pad_load_after > _pad_load_before + .03 and _pad_load_after <= 1.0, "felt contact must gradually refill a finite reservoir"): return
	if not check(RationDeskRules.desk(game.state).get("marks", []).is_empty(), "a pad contact must never print a paper decision"): return
	await shot("ink-pad-contact")
	button(MOUSE_BUTTON_LEFT, false)
	if not await wait_until(func() -> bool: return not desk._busy and not desk._stamp_animating, 120): return
	if not check(desk.ink_pad.pressure == 0.0, "lifting must release the actual felt"): return
	if not await inspect_loaded_stamp(): return
	# Move closer using the player's normal wheel. The pad has already been
	# demonstrated at the wide desk framing; both paper impressions now fit.
	wheel(MOUSE_BUTTON_WHEEL_UP, 2)
	await frames(6)
	# A slow, light contact outside the decision field: real ink with no verdict.
	desk._key_down(KEY_ALT, true)
	wheel(MOUSE_BUTTON_WHEEL_UP, 4)
	desk._key_down(KEY_ALT, false)
	if not check(absf(desk._stamp_tilt) > .15, "Alt-wheel must visibly tilt the held rubber face"): return
	await paper_point(Vector2(290, 180))
	button(MOUSE_BUTTON_LEFT, true)
	for step: int in 31:
		motion(Vector2(0, 5))
		await frames(3)
	if not await wait_until(func() -> bool: return desk._stamp_contacted, 120):
		if not check(false, "the slow light press must reach the physical sheet"): return
	await frames(3)
	await shot("ink-tilted-contact")
	button(MOUSE_BUTTON_LEFT, false)
	if not await wait_until(func() -> bool: return not desk._busy and not desk._stamp_animating, 120): return
	var work: Dictionary = RationDeskRules.desk(game.state)
	if not check(work.get("marks", []).size() == 1 and work.get("stamp", "") == "", "misplaced light ink must remain on paper without deciding the case"): return
	_light_mark = work["marks"][0].duplicate(true)
	if not check(float(_light_mark.get("pressure", 1.0)) < .3 and absf(float(_light_mark.get("tilt", 0.0))) > .15, "the actual light impression must preserve measured pressure and tilt"): return
	# Restore the tool with the inverse gesture, then give a firm flat decision.
	desk._key_down(KEY_ALT, true)
	wheel(MOUSE_BUTTON_WHEEL_DOWN, 4)
	desk._key_down(KEY_ALT, false)
	if not check(absf(desk._stamp_tilt) < .001, "the inverse Alt-wheel gesture must restore the flat die"): return
	await paper_point(Vector2(540, 183))
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(0, 180))
	if not await wait_until(func() -> bool: return desk._stamp_contacted and desk._stamp_dwell >= .28, 120):
		if not check(false, "the firm decision must physically contact the paper"): return
	await shot("ink-firm-contact")
	button(MOUSE_BUTTON_LEFT, false)
	if not await wait_until(func() -> bool: return not desk._busy and not desk._stamp_animating, 120): return
	work = RationDeskRules.desk(game.state)
	if not check(work.get("marks", []).size() == 2 and work.get("stamp", "") == "approve", "two contacts must leave two physical marks and one onay decision"): return
	_firm_mark = work["marks"][1].duplicate(true)
	if not check(float(_firm_mark.get("pressure", 0.0)) > float(_light_mark.get("pressure", 1.0)) + .5, "light and firm marks must derive from different actual presses"): return
	if not await park_tool(): return
	if not check(desk.card.wet_view.has_wet_ink(), "fresh ink must still have a liquid coating after lift"): return
	await shot("ink-light-and-firm")
	var working_distance: float = desk._desk_distance
	wheel(MOUSE_BUTTON_WHEEL_UP, 3)
	await frames(5)
	if not await rub_paper(Vector2(500, 177), Vector2(586, 220), true): return
	work = RationDeskRules.desk(game.state)
	if not check(not work["marks"][1].get("rubs", []).is_empty(), "an empty-hand finger pull must persist directional wet ink transfer"): return
	if not check(work["stamp"] == "approve" and work["marks"].size() == 2, "finger transfer must not append ink contacts or rewrite the decision"): return
	await shot("ink-smeared-wet")
	if not await check_wet_mask(false): return
	write_optical_framing()
	# The ordinary game clock dries the coating. Neither shader TIME nor this
	# capture advances campaign time or edits a mark to make it dry.
	if not await wait_until(func() -> bool: return not desk.card.wet_view.has_wet_ink(), 1800):
		if not check(false, "the liquid coating must dry under the running game's own clock"): return
	await shot("ink-dry")
	if not await check_wet_mask(true): return
	var dried_marks: Array = RationDeskRules.desk(game.state)["marks"].duplicate(true)
	if not await rub_paper(Vector2(500, 177), Vector2(586, 220), false): return
	if not check(RationDeskRules.desk(game.state)["marks"] == dried_marks, "the same finger gesture over dry ink must leave every print record unchanged"): return
	wheel(MOUSE_BUTTON_WHEEL_DOWN, 3)
	await frames(5)
	if not check(absf(desk._desk_distance - working_distance) < .000001, "native close-up and inverse wheel gestures must restore the working camera distance exactly"): return
	if not await cut_and_file(): return
	if not check(RationDeskRules.desk(game.state)["marks"] == dried_marks, "cutting and filing must preserve both original impressions and their smear"): return
	desk._key(KEY_Q)
	await frames(16)
	await point(desk.card.global_position)
	desk._key(KEY_R)
	await frames(16)
	await point(desk.customer_target.global_position + Vector3.UP * .4)
	desk._key(KEY_E)
	await frames(18)
	work = RationDeskRules.desk(game.state)
	if not check(work.get("done", false) and work.get("results", []).size() == 1 and work["results"][0]["correct"], "the original valid customer must complete with a correct audit"): return
	if not check(game.state.money == opening_money and game.state.stock == opening_stock, "the focused paperwork must leave money and provisions unchanged"): return
	if not check(not desk._selftest and not desk._desk_cursor_override.is_finite(), "capture must never enable a selftest or synthetic cursor"): return
	await shot("ink-customer-complete")
	recording = false
	print("[ink normal viewport capture] PASS: real pad contact/load %.3f -> %.3f; Q/F loaded rubber die rotation/flip/zoom; light pressure %.3f / tilt %.3f; firm pressure %.3f; close-up wet finger transfer, actual wet glyph mask/clear outside and fully empty dry mask, natural dry/no further transfer, requested coupon manually filed, correct original customer, unchanged economy; %d frames" % [_pad_load_before, _pad_load_after, _light_mark["pressure"], _light_mark["tilt"], _firm_mark["pressure"], saved])
	quit(0)


func point(world: Vector3) -> void:
	if desk._desk_inspecting:
		var screen: Vector2 = desk.player.camera.unproject_position(world)
		if not check(root.get_visible_rect().has_point(screen), "the real desk target must be inside the viewport: %s" % screen): return
		root.warp_mouse(screen.round())
	else:
		desk.player.camera.look_at(world, Vector3.UP)
	await frames(4)


func wheel(which: int, count: int) -> void:
	for click: int in count:
		button(which, true)
		button(which, false)


func check_wet_mask(expect_dry: bool) -> bool:
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = desk.card.wet_view.get_parent() as SubViewport
	var mask: Image = viewport.get_texture().get_image()
	mask.save_png(output.path_join("ink-dry-mask.png" if expect_dry else "ink-wet-mask.png"))
	if expect_dry:
		return check(maximum_alpha(mask, Rect2i(Vector2i.ZERO, mask.get_size())) == 0.0, "the actual rendered dry ink mask must be fully transparent")
	var center: Vector2i = Vector2i(Vector2(float(_firm_mark["x"]), float(_firm_mark["y"])).round())
	var glyph_region: Rect2i = Rect2i(center - Vector2i(65, 22), Vector2i(130, 44))
	return check(maximum_alpha(mask, glyph_region) > .01 and maximum_alpha(mask, Rect2i(20, 100, 70, 45)) == 0.0, "the actual rendered wet mask must contain the physical glyphs and leave untouched paper clear")


func maximum_alpha(image: Image, region: Rect2i) -> float:
	var area: Rect2i = region.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var maximum: float = 0.0
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			maximum = maxf(maximum, image.get_pixel(x, y).a)
	return maximum


func write_optical_framing() -> void:
	# A stretched ViewportTexture can report its proxy resource dimensions.
	# Calibrate against the same actual image that shot() saves to disk.
	var image_size: Vector2 = Vector2(root.get_texture().get_image().get_size())
	var viewport_size: Vector2 = root.get_visible_rect().size
	var scale_to_image: Vector2 = image_size / viewport_size
	var decision: Rect2 = projected_paper_rect(Rect2(Vector2(float(_firm_mark["x"]) - 72, float(_firm_mark["y"]) - 30), Vector2(144, 60)), scale_to_image)
	var control: Rect2 = projected_paper_rect(Rect2(20, 100, 70, 45), scale_to_image)
	var data: Dictionary = {"image_size": [image_size.x, image_size.y], "viewport_size": [viewport_size.x, viewport_size.y],
		"decision_stamp": [decision.position.x, decision.position.y, decision.end.x, decision.end.y],
		"untouched_paper": [control.position.x, control.position.y, control.end.x, control.end.y],
		"desk_control": [20, 20, 120, 120], "game_time": desk._ink_now(), "decision_mark": _firm_mark.duplicate(true)}
	var file: FileAccess = FileAccess.open(output.path_join("ink-optical-framing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()


func projected_paper_rect(canonical: Rect2, scale_to_image: Vector2) -> Rect2:
	var corners: Array[Vector2] = [canonical.position, Vector2(canonical.end.x, canonical.position.y), canonical.end, Vector2(canonical.position.x, canonical.end.y)]
	var result: Rect2 = Rect2(desk.player.camera.unproject_position(desk.card.pixel_to_world(corners[0])) * scale_to_image, Vector2.ZERO)
	for corner: Vector2 in corners:
		result = result.expand(desk.player.camera.unproject_position(desk.card.pixel_to_world(corner)) * scale_to_image)
	return result


func inspect_loaded_stamp() -> bool:
	desk._key(KEY_Q)
	await frames(20)
	var rest: Transform3D = desk.held_tool.transform
	var load_before: float = desk._stamp_inks["approve"].load
	desk._key(KEY_F)
	await frames(16)
	if not check(desk._object_inspector.active and desk._object_inspector.object == desk.props["stamp_approve"], "Q then F must inspect the same loaded physical stamp"): return false
	button(MOUSE_BUTTON_RIGHT, true)
	button(MOUSE_BUTTON_RIGHT, false)
	await frames(16)
	if not check(desk._inspection_back, "right-click must flip the inspected stamp"): return false
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(20, -196))
	button(MOUSE_BUTTON_LEFT, false)
	wheel(MOUSE_BUTTON_WHEEL_UP, 3)
	await frames(10)
	var face: StampDieFace = desk.held_tool.find_child("RubberPrintingFace", true, false) as StampDieFace
	if not check(face != null and absf(face.ink_load - load_before) < .0001, "the same physical rubber underside must carry the reservoir's actual coating"): return false
	var toward_eye: Vector3 = (desk.player.camera.global_position - face.global_position).normalized()
	if not check((face.global_basis * Vector3.DOWN).dot(toward_eye) > .65, "normal drag must turn the inked underside toward the player's eye"): return false
	await shot("ink-loaded-rubber-die")
	desk._key(KEY_F)
	await frames(4)
	if not check(desk.held_tool.transform.is_equal_approx(rest) and is_equal_approx(desk._stamp_inks["approve"].load, load_before), "closing inspection must restore the exact held pose without consuming ink"): return false
	await point(desk.card.global_position)
	desk._key(KEY_E)
	await frames(34)
	return check(desk._desk_inspecting, "the same paper desk must reopen after rubber-face inspection")


func rub_paper(start: Vector2, end: Vector2, photograph: bool) -> bool:
	if not check(desk.held_tool == null and desk._desk_inspecting, "finger contact needs an empty hand at the physical desk"): return false
	await paper_point(start)
	desk._key_down(KEY_ALT, true)
	button(MOUSE_BUTTON_LEFT, true)
	await frames(2)
	if not check(desk._ink_rubbing and not desk._paper_dragging, "Alt-LMB must place a finger rather than pick up the paper"): return false
	for step: int in range(1, 9):
		await paper_point(start.lerp(end, float(step) / 8.0))
	if photograph: await shot("ink-finger-contact")
	button(MOUSE_BUTTON_LEFT, false)
	desk._key_down(KEY_ALT, false)
	await frames(5)
	return check(not desk._ink_rubbing, "releasing the button must lift the finger")


func cut_and_file() -> bool:
	await point(desk.props["scissors"].global_position + Vector3.UP * .015)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == desk.props["scissors"], "native cursor must take the scissors"): return false
	var rectangle: Rect2 = RationCardView.coupon_rect(0)
	await paper_point(rectangle.position)
	button(MOUSE_BUTTON_LEFT, true)
	await frames(2)
	if not check(desk._cut_index >= 0, "native pointer must start the requested meat coupon perimeter"): return false
	for corner: Vector2 in [Vector2(rectangle.end.x, rectangle.position.y), rectangle.end, Vector2(rectangle.position.x, rectangle.end.y), rectangle.position]:
		if not await trace(corner): return false
	button(MOUSE_BUTTON_LEFT, false)
	await frames(4)
	var coupon: CouponFragment3D = desk._find_coupon("meat")
	if not check(coupon != null, "four physically cut edges must detach the requested coupon"): return false
	if not await wait_until(func() -> bool: return not coupon.get_meta("settling", false), 120): return check(false, "the detached coupon must settle on real support")
	await shot("ink-coupon-cut")
	if not await park_tool(): return false
	await point(coupon.global_position + Vector3.UP * .001)
	if not check(desk._ray().get("collider") == coupon, "the native pointer must reach the same detached coupon"): return false
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == coupon, "E must pick up the actual severed coupon"): return false
	await point(desk.coupon_bin.global_position + Vector3.UP * .018)
	desk._key(KEY_G)
	await frames(1)
	if not check(RationDeskRules.desk(root.get_node("Game").state).get("collected", []).is_empty(), "filing must wait for the physical tray contact"): return false
	if not await wait_until(func() -> bool: return coupon.archived, 120): return check(false, "the piece must physically arrive in the coupon tray")
	if not check(RationDeskRules.desk(root.get_node("Game").state).get("collected", []) == ["meat"], "tray contact must collect exactly the requested coupon"): return false
	await shot("ink-filed")
	return true
