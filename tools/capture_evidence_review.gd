extends "res://tools/capture_desk_interaction.gd"
## The actual eight-case comparison day through normal FPS/viewport inputs.
## No card edits, campaign fixture, cursor override or authenticity overlay.

func run() -> void:
	output = "/tmp/kiosk81-evidence-review"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): output = arg.trim_prefix("--capture=")
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	desk = load("res://scenes/kiosk/ration_review_day.tscn").instantiate()
	root.add_child(desk)
	await frames(70)
	for index: int in 8:
		print("[evidence capture] case %d receive" % (index + 9))
		await take_card()
		if not check(desk.card_held and desk.identity_document.visible, "both supplied documents must be physical"): return
		await point(desk.workmat.global_position)
		desk._key(KEY_G)
		await frames(34)
		if not check(desk._desk_inspecting, "case %d placement failed: held %s cardheld %s message %s" % [index + 9, desk.held_tool.action if desk.held_tool != null else "none", desk.card_held, desk.message.text]): return
		if index == 0:
			recording = true
			await shot("01_two_documents_on_desk")
			await point(desk.identity_document.global_position)
			if not check(desk._ray().get("collider") == desk.identity_document, "real cursor must hit identity"): return
			desk._key(KEY_E)
			await frames(12)
			desk._key(KEY_Q)
			await frames(16)
			desk._key(KEY_F)
			await frames(12)
			if not check(desk._object_inspector.object == desk.identity_document): return
			await shot("02_identity_in_hand")
			desk._key(KEY_F)
			await point(desk.card.global_position)
			desk._key(KEY_R)
			await frames(16)
			desk._key(KEY_F)
			await frames(12)
			button(MOUSE_BUTTON_RIGHT, true)
			button(MOUSE_BUTTON_RIGHT, false)
			await frames(12)
			await shot("03_matching_card_photo")
			desk._key(KEY_C)
			await frames(12)
			if not check(desk._object_inspector.object == desk.identity_document): return
			await shot("04_compare_same_identity")
			desk._key(KEY_F)
			await point(desk.homes[desk.identity_document].origin + Vector3.UP * .002)
			desk._key(KEY_G)
			await frames(12)
			if not check(desk.held_tool == null, "identity must be parked before card placement"): return
			await point(desk.workmat.global_position)
			desk._key(KEY_G)
			await frames(34)
			recording = false
		elif index in [1, 2, 3, 4, 5, 6, 7]:
			await point(desk.card.global_position)
			desk._key(KEY_R)
			await frames(14)
			desk._key(KEY_F)
			await frames(12)
			if index in [1, 4, 5, 6]:
				if index == 1: recording = true
				for tick: int in 3:
					button(MOUSE_BUTTON_WHEEL_UP, true)
					button(MOUSE_BUTTON_WHEEL_UP, false)
				await frames(12)
				await shot(["", "05_altered_date", "", "", "08_replaced_coupon", "09_previous_issue", "10_worn_valid_card"][index])
			if index in [2, 3, 6, 7]:
				button(MOUSE_BUTTON_RIGHT, true)
				button(MOUSE_BUTTON_RIGHT, false)
				await frames(12)
				await shot({2:"06_broken_photo_seal",3:"07_identity_mismatch",6:"11_faded_continuous_seal",7:"12_different_photo"}[index])
			desk._key(KEY_F)
			await point(desk.workmat.global_position)
			desk._key(KEY_G)
			await frames(34)
			recording = false
		if index == 1:
			await point(desk.props["book"].global_position + Vector3.UP * .012)
			desk._key(KEY_E)
			await frames(12)
			desk._key(KEY_Q)
			await frames(14)
			desk._key(KEY_F)
			await frames(12)
			desk._key(KEY_TAB)
			await frames(12)
			await shot("13_forgery_reference")
			desk._key(KEY_F)
			if not await park_tool(): return
			await point(desk.card.global_position)
			desk._key(KEY_E)
			await frames(28)
		if not await finish_case(index): return
	var results: Array = RationDeskRules.desk(root.get_node("Game").state).get("results", [])
	if not check(results.size() == 8 and not desk._selftest and not desk._desk_cursor_override.is_finite()): return
	for result: Dictionary in results:
		if not check(result["correct"], "normal input audit failed: " + result["case"]): return
	print("[evidence normal viewport capture] PASS: eight physical document decisions, identity pickup/F/C comparison, date/photo/serial/prior-issue evidence, Tab book page, real-pointer stamps/cuts/handback; %d frames" % saved)
	quit()


func take_card() -> void:
	for frame: int in 180:
		if desk._window_ready: break
		await frames(1)
	await point(desk.card.global_position)
	desk._key(KEY_E)
	await frames(18)


func park_tool() -> bool:
	if not check(desk.held_tool != null, "parking requires a held tool"): return false
	var kind: String = desk.held_tool.action
	await point(desk.homes[desk.held_tool].origin + Vector3.UP * .003)
	var hit: Node = desk._ray().get("collider")
	var hit_name: String = hit.action if hit is Interactable else (str(hit.get_meta("surface", "unknown")) if hit != null else "none")
	desk._key(KEY_G)
	await frames(12)
	if desk.held_tool != null: await shot("parking_failure")
	return check(desk.held_tool == null, "parking %s failed: desk %s ray %s camera %s home %s message %s" % [kind, desk._desk_inspecting, hit_name, desk.player.camera.global_position, desk.homes[desk.held_tool].origin if desk.held_tool != null else Vector3.ZERO, desk.message.text])


func finish_case(index: int) -> bool:
	var decision: String = ["approve", "seize", "seize", "seize", "seize", "reject", "approve", "seize"][index]
	await point(desk.props["stamp_" + decision].global_position + Vector3.UP * .08)
	desk._key(KEY_E)
	await frames(12)
	if not check(desk.held_tool == desk.props["stamp_" + decision]): return false
	await point(desk.card.pixel_to_world(Vector2(540, 183)))
	button(MOUSE_BUTTON_LEFT, true)
	motion(Vector2(0, 180))
	for frame: int in 100:
		if desk._stamp_contacted: break
		await frames(1)
	if not check(desk._stamp_contacted, "native stamp must physically contact"): return false
	await frames(9)
	button(MOUSE_BUTTON_LEFT, false)
	await frames(14)
	if not await park_tool(): return false
	if decision == "approve":
		var encounter: Dictionary = desk.rules.current(root.get_node("Game").state)
		var coupon: int = RationDeskRules.PRODUCT_ORDER.find(encounter["request"]["item"])
		var rectangle: Rect2 = RationCardView.coupon_rect(coupon)
		await point(desk.props["scissors"].global_position + Vector3.UP * .015)
		desk._key(KEY_E)
		await frames(12)
		await point(desk.card.pixel_to_world(rectangle.position))
		button(MOUSE_BUTTON_LEFT, true)
		for corner: Vector2 in [Vector2(rectangle.end.x, rectangle.position.y), rectangle.end, Vector2(rectangle.position.x, rectangle.end.y), rectangle.position]:
			await point(desk.card.pixel_to_world(corner))
			# A native OS cursor is quantized to screen pixels. Wait for the
			# blade to reach that sampled point, not an unreachable float ray.
			var sampled_target: Vector2 = desk._paper_pixel()
			var pointer_error: Vector2 = (sampled_target - corner).abs()
			if not check(maxf(pointer_error.x, pointer_error.y) < PaperCutGeometry.EDGE_TOLERANCE_PX, "native pointer missed the coupon boundary: wanted %s sampled %s cursor %s projection %s" % [corner, sampled_target, root.get_mouse_position(), desk.player.camera.unproject_position(desk.card.pixel_to_world(corner))]): return false
			for frame: int in 240:
				if desk._cut_tip.distance_to(sampled_target) < .05: break
				await frames(1)
			if not check(desk._cut_tip.distance_to(sampled_target) < .05, "native scissors perimeter timeout: tip %s target %s" % [desk._cut_tip, sampled_target]): return false
		button(MOUSE_BUTTON_LEFT, false)
		await frames(14)
		if not await park_tool(): return false
		var fragment: CouponFragment3D = desk._find_coupon(encounter["request"]["item"])
		if not check(fragment != null, "approved cut must leave a physical coupon"): return false
		for frame: int in 60:
			if not fragment.get_meta("settling", false): break
			await frames(1)
		await point(fragment.global_position + Vector3.UP * .001)
		desk._key(KEY_E)
		await frames(12)
		if not check(desk.held_tool == fragment, "the detached coupon must be picked up"): return false
		await point(desk.coupon_bin.global_position + Vector3.UP * .04)
		desk._key(KEY_E)
		await frames(18)
		if not check(fragment.archived, "the detached coupon must be filed by physical contact"): return false
	desk._key(KEY_Q)
	await frames(14)
	await point(desk.card.global_position)
	desk._key(KEY_R)
	await frames(14)
	await point(desk.drawer.global_position + Vector3.UP * .04 if decision == "seize" else desk.customer_target.global_position + Vector3.UP * .4)
	desk._key(KEY_E)
	await frames(16)
	if not check(RationDeskRules.desk(root.get_node("Game").state).get("done", false), "native decision handback failed"): return false
	await point(desk.bell.global_position + Vector3.UP * .03)
	desk._key(KEY_E)
	return true
