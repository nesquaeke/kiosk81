extends RefCounted
## Native-input coverage for detached paper: cutting does not collect it,
## inspecting keeps the original piece, and only physical filing records it.

var _desk: Node3D
var _failures: PackedStringArray = []


func run(desk: Node3D) -> PackedStringArray:
	_desk = desk
	_failures.clear()
	await _collection_before_stamp()
	await _finished_piece_before_bell()
	await _stale_piece_after_customer()
	await _restart_during_fall()
	await _restart_before_bin_contact()
	_desk._restart()
	await _desk._wait_customer()
	print("[coupon cutting regressions] %s" % ("PASS: real cut-first separation, loose E/LMB pickup, F rotate/zoom/reverse, exact pose/focus recovery, table/floor drops, contact-only single filing, approval audit, completed-case archive before bell, preserved old paper, restart during fall/filing" if _failures.is_empty() else "FAIL: " + "; ".join(_failures)))
	return _failures


func _collection_before_stamp() -> void:
	await _fresh_table()
	var encounter: Dictionary = _desk.rules.current(Game.state).duplicate(true)
	var item: String = encounter["request"]["item"]
	var piece: CouponFragment3D = await _cut_requested()
	if piece == null: return
	_check(_work().get("require_coupon_collection", false), "focused review did not require physical collection")
	_check(_work().get("collected", []).is_empty() and _work().get("cuts", []).is_empty(), "detaching before a stamp collected or consumed the entitlement")
	_check(not piece.archived and piece.collision_layer == 2 and piece.get_parent() == _desk, "detached coupon was automatically archived or left unselectable")
	_check(piece.source_card_id == encounter["id"] and piece.source_serial == encounter["card"]["serial"] and piece.item_id == item, "detached paper lost its original customer/serial/product")
	_check(_desk._tokens.size() == 1, "one cut produced multiple physical fragments")
	var source: Dictionary = _snapshot(piece)
	_check(source["print"].size() == 2, "loose coupon did not carry both original printed faces")
	await _park_tool()
	_check(not _desk._cut_guide.visible, "cutting guide stayed visible after parking scissors")
	if not await _pickup(piece, false): return
	_desk._key(KEY_Q)
	await _desk._test_camera_settled()
	var held_pose: Transform3D = piece.transform
	var work: Dictionary = _work().duplicate(true)
	_desk._key(KEY_F)
	await _wait_inspection()
	_check(_desk._object_inspector.active and _desk._object_inspector.object == piece, "F did not inspect the original detached paper")
	_check(not _desk._cut_guide.visible, "cutting guide leaked into detached-paper inspection")
	var distance: float = piece.position.length()
	for step: int in 3: _desk._mouse(MOUSE_BUTTON_WHEEL_UP, true)
	_check(piece.position.length() < distance - .001, "coupon inspection zoom did not move the fragment closer")
	var initial: Quaternion = piece.quaternion
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._test_motion(Vector2(77, -41))
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	_check(not piece.quaternion.is_equal_approx(initial), "coupon inspection did not rotate the physical fragment")
	_desk._mouse(MOUSE_BUTTON_RIGHT, true)
	_desk._mouse(MOUSE_BUTTON_RIGHT, false)
	await _wait_inspection()
	_check(piece.basis.z.dot(Vector3.FORWARD) > .99, "coupon inspection did not reveal its real reverse face")
	_desk._key(KEY_Q)
	_check(not _desk._object_inspector.active and piece.transform.is_equal_approx(held_pose) and _desk.held_tool == piece, "Q lost the same coupon or its exact held pose")
	_check(_snapshot(piece) == source and _work() == work, "coupon inspection rewrote its original paper or bookkeeping")
	# Losing application focus closes inspection but keeps the original piece
	# in the hand; there is no invisible held object or silent filing.
	_desk._key(KEY_F)
	var selftest: bool = _desk._selftest
	_desk._selftest = false
	_desk._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_desk._selftest = selftest
	_check(not _desk._object_inspector.active and _desk.pause.visible and _desk.held_tool == piece and piece.visible, "focus loss hid or discarded the held coupon")
	_check(piece.transform.is_equal_approx(held_pose) and _work() == work, "focus loss changed coupon pose or collection")
	_desk._key(KEY_ESCAPE)
	# G on ordinary support is only a drop, then a left-click picks up the
	# very same piece again. Neither gesture files an entitlement by proximity.
	_desk._aim(Vector3(-.77, .961, -1.82))
	_desk._key(KEY_G)
	await _desk._wait_hands()
	_check(_desk.held_tool == null and piece.get_parent() == _desk and piece.collision_layer == 2 and not piece.archived, "G did not leave an accessible loose coupon on the table")
	_check(_work().get("collected", []).is_empty() and _snapshot(piece) == source, "ordinary tabletop drop filed or changed the coupon")
	if not await _pickup(piece, true): return
	_desk._aim(Vector3(0, .002, -.62))
	_desk._key(KEY_G)
	await _desk._wait_hands()
	_check(_desk.held_tool == null and piece.global_position.y < .03 and piece.collision_layer == 2 and not piece.archived, "G did not leave loose paper on the actual floor support")
	_check(_work().get("collected", []).is_empty() and _snapshot(piece) == source, "ordinary floor drop filed or changed the coupon")
	if not await _pickup(piece, false): return
	_desk._aim(_desk.coupon_bin.global_position + Vector3.UP * .025)
	_desk._key(KEY_E)
	_check(_work().get("collected", []).is_empty() and not piece.archived, "bin filing committed before physical contact")
	await _desk._wait_hands()
	_check(_work().get("collected", []) == [item] and piece.archived and piece.collision_layer == 0 and _desk.held_tool == null, "physical bin contact did not archive exactly the held coupon")
	_check(_desk._tokens.size() == 1 and _work().get("cuts", []).is_empty(), "filing duplicated the fragment or granted an unstamped entitlement")
	var filed: Dictionary = _work().duplicate(true)
	_desk._aim(piece.global_position)
	_desk._key(KEY_E)
	_desk._key(KEY_G)
	await _desk._wait_hands()
	_check(_work() == filed and _desk.held_tool != piece, "archived fragment could be collected twice")
	if not await _stamp("approve"): return
	_check(_work().get("cuts", []) == [item] and _work().get("collected", []) == [item] and _desk._tokens.size() == 1, "stamp after collection did not consume the single original coupon once")
	if not await _handback(): return
	var results: Array = _work().get("results", [])
	_check(results.size() == 1 and results[0].get("correct", false) and results[0].get("collected", []) == [item], "collected cut-first review did not produce one correct audit")
	await _next_customer()
	_check(is_instance_valid(piece) and _snapshot(piece) == source and piece.archived, "next customer rewrote or removed the filed paper snapshot")
	_check(_work().get("collected", []).is_empty() and _desk._find_coupon(item) != piece, "next customer inherited the previous collection or loose fragment lookup")


func _finished_piece_before_bell() -> void:
	await _fresh_table()
	var case_id: String = str(_desk.rules.current(Game.state)["id"])
	var piece: CouponFragment3D = await _cut_requested()
	if piece == null: return
	var source: Dictionary = _snapshot(piece)
	await _park_tool()
	if not await _stamp("reject"): return
	if not await _handback(): return
	_check(_work().get("done", false) and str(_desk.rules.current(Game.state)["id"]) == case_id, "finished-piece fixture did not remain on the completed customer before the bell")
	var state: Dictionary = Game.state.to_dict()
	var work: Dictionary = _work().duplicate(true)
	if not await _pickup(piece, false): return
	_desk._aim(_desk.coupon_bin.global_position + Vector3.UP * .025)
	_desk._key(KEY_E)
	_check(not piece.archived and Game.state.to_dict() == state, "completed customer's loose coupon archived or changed state before contact")
	await _desk._wait_hands()
	_check(piece.archived and piece.collision_layer == 0 and _desk.held_tool == null, "completed customer's loose coupon could not be physically archived before calling the next customer")
	_check(_work() == work and Game.state.to_dict() == state, "archiving finished paperwork changed the completed audit or campaign state")
	_check(_snapshot(piece) == source, "archiving finished paperwork changed the original paper snapshot")


func _stale_piece_after_customer() -> void:
	await _fresh_table()
	var old_case: String = str(_desk.rules.current(Game.state)["id"])
	var piece: CouponFragment3D = await _cut_requested()
	if piece == null: return
	var source: Dictionary = _snapshot(piece)
	await _park_tool()
	# A mistaken RET is allowed and audited; it must not erase physical paper.
	if not await _stamp("reject"): return
	if not await _handback(): return
	await _next_customer()
	_check(str(_desk.rules.current(Game.state)["id"]) != old_case, "stale-paper fixture did not advance to another customer")
	_check(is_instance_valid(piece) and not piece.archived and _snapshot(piece) == source, "loose old coupon lost its original snapshot when the next card arrived")
	if not is_instance_valid(piece): return
	var work: Dictionary = _work().duplicate(true)
	_desk._aim(piece.global_position + Vector3.UP * .002)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	if _desk.held_tool == piece:
		_desk._aim(_desk.coupon_bin.global_position + Vector3.UP * .025)
		_desk._key(KEY_G)
		await _desk._wait_hands()
	_check(_work() == work, "old customer's loose coupon was credited against the new card")
	_check(_snapshot(piece) == source, "rejected old-paper filing changed its print or damage")


func _restart_during_fall() -> void:
	await _fresh_table()
	var piece: CouponFragment3D = await _cut_requested(false)
	if piece == null: return
	_check(not piece.archived and _work().get("collected", []).is_empty(), "falling coupon was already filed")
	_desk._restart()
	await _desk.get_tree().create_timer(.62).timeout
	await _desk._wait_customer()
	_check(not is_instance_valid(piece) and _desk._tokens.is_empty() and _work().get("collected", []).is_empty(), "old falling paper callback survived restart or filed the next day")
	_check(_desk.held_tool == null and not _desk._busy and not _desk._object_inspector.active, "restart during coupon fall left a held object or control lock")


func _restart_before_bin_contact() -> void:
	await _fresh_table()
	var piece: CouponFragment3D = await _cut_requested()
	if piece == null: return
	await _park_tool()
	if not await _pickup(piece, false): return
	_desk._aim(_desk.coupon_bin.global_position + Vector3.UP * .025)
	_desk._key(KEY_G)
	_check(not piece.archived and _work().get("collected", []).is_empty(), "G bin transfer filed before contact")
	_desk._restart()
	await _desk.get_tree().create_timer(.72).timeout
	await _desk._wait_customer()
	_check(not is_instance_valid(piece) and _desk._tokens.is_empty() and _work().get("collected", []).is_empty(), "cancelled bin transfer later archived paper in the new day")
	_check(_desk.held_tool == null and not _desk._busy and not _desk.player.look_locked and not _desk.right_hand.visible, "restart before bin contact left stale hands or locked controls")


func _fresh_table() -> void:
	_desk._restart()
	await _desk._wait_customer()
	_desk.player.position = Vector3(0, .025, -1.25)
	_desk.player.velocity = Vector3.ZERO
	await _desk.get_tree().physics_frame
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	_desk._aim(_desk.workmat.global_position)
	_desk._key(KEY_G)
	await _desk._wait_hands()
	await _desk._test_camera_settled()
	_check(_desk._desk_inspecting and _work().get("placement") == "table", "coupon fixture could not place the real customer card on the desk")


func _cut_requested(settle: bool = true) -> CouponFragment3D:
	var item: String = str(_desk.rules.current(Game.state)["request"]["item"])
	var index: int = RationDeskRules.PRODUCT_ORDER.find(item)
	var rectangle: Rect2 = RationCardView.coupon_rect(index)
	_desk._aim(_desk.props["scissors"].global_position + Vector3.UP * .012)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	if _desk.held_tool != _desk.props["scissors"]:
		_check(false, "coupon regression could not pick up scissors")
		return null
	_desk._aim(_desk.card.pixel_to_world(rectangle.position))
	await _desk.get_tree().physics_frame
	await _desk.get_tree().physics_frame
	_check(_desk._cut_guide.visible, "held scissors did not show the guide on the physical paper")
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	for corner: Vector2 in [Vector2(rectangle.end.x, rectangle.position.y), rectangle.end, Vector2(rectangle.position.x, rectangle.end.y), rectangle.position]:
		if not await _desk._test_trace(corner):
			_check(false, "coupon regression perimeter travel timed out")
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	var piece: CouponFragment3D = _desk._find_coupon(item)
	if piece == null:
		_check(false, "complete physical cut did not produce a loose coupon")
		return null
	_check(not _desk.card.has_paper_at(rectangle.get_center()), "cut coupon remained in the parent paper")
	if settle:
		_check(await _desk._test_until(func() -> bool: return not piece.get_meta("settling", false), 1800), "detached coupon did not reach a stable support")
		await _desk.get_tree().physics_frame
	return piece


func _park_tool() -> void:
	if _desk.held_tool == null: return
	_desk._aim(_desk.homes[_desk.held_tool].origin + Vector3.UP * .003)
	_desk._key(KEY_G)
	await _desk._wait_hands()
	_check(_desk.held_tool == null, "coupon regression could not park its held tool")


func _pickup(piece: CouponFragment3D, click: bool) -> bool:
	await _desk.get_tree().physics_frame
	_desk._aim(piece.global_position + Vector3.UP * .001)
	_check(_desk._ray().get("collider") == piece, "actual interaction ray could not reach the loose paper")
	if click:
		_desk._mouse(MOUSE_BUTTON_LEFT, true)
		_desk._mouse(MOUSE_BUTTON_LEFT, false)
	else:
		_desk._key(KEY_E)
	await _desk._wait_hands()
	var picked_up: bool = _desk.held_tool == piece
	var expected_parent: Node = _desk if _desk._desk_inspecting else _desk.player.camera
	_check(picked_up and piece.get_parent() == expected_parent and piece.collision_layer == 0, "E/LMB did not pick up the original loose fragment")
	return picked_up


func _stamp(kind: String) -> bool:
	if not _desk._desk_inspecting:
		_desk._aim(_desk.card.global_position)
		_desk._key(KEY_E)
		await _desk._test_camera_settled()
	_desk._aim(_desk.props["stamp_" + kind].global_position + Vector3.UP * .08)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	if _desk.held_tool != _desk.props["stamp_" + kind]:
		_check(false, "coupon regression could not take its " + kind + " stamp")
		return false
	_desk._aim(_desk.card.pixel_to_world(Vector2(540, 183)))
	_desk._mouse(MOUSE_BUTTON_LEFT, true)
	_desk._test_motion(Vector2(0, 180))
	_check(await _desk._test_until(func() -> bool: return _desk._stamp_contacted), "coupon regression stamp never contacted the paper")
	_desk._mouse(MOUSE_BUTTON_LEFT, false)
	await _desk._wait_hands()
	await _park_tool()
	var stamped: bool = _work().get("stamp") == kind
	_check(stamped, "coupon regression stamp contact did not persist its decision")
	return stamped


func _handback() -> bool:
	_desk._key(KEY_Q)
	await _desk._test_camera_settled()
	_desk._aim(_desk.card.global_position)
	_desk._key(KEY_R)
	await _desk._wait_hands()
	_desk._aim(_desk.customer_target.global_position + Vector3.UP * .4)
	_desk._key(KEY_E)
	await _desk._wait_hands()
	var done: bool = _work().get("done", false)
	_check(done, "coupon regression could not hand the reviewed card back")
	return done


func _next_customer() -> void:
	_desk._aim(_desk.bell.global_position + Vector3.UP * .03)
	_desk._key(KEY_E)
	await _desk._wait_customer()
	await _desk.get_tree().physics_frame


func _wait_inspection() -> void:
	await _desk._test_until(func() -> bool: return not _desk._object_inspector._turn.is_valid(), 2000)


func _snapshot(piece: CouponFragment3D) -> Dictionary:
	var print_faces: Array = []
	var ink_masks: Array = []
	for child: Node in piece.get_children():
		if child is SubViewport:
			for renderer: Node in child.get_children():
				if renderer is RationCardView:
					print_faces.append({"front": renderer.front, "card": renderer.card.duplicate(true), "work": renderer.work.duplicate(true)})
		elif child is MeshInstance3D and child.material_override is ShaderMaterial:
			var material: ShaderMaterial = child.material_override
			var texture: Variant = material.get_shader_parameter("incision_texture")
			if texture is ImageTexture:
				ink_masks.append({"texture": texture.get_instance_id(), "data": hash(texture.get_image().get_data()), "sheet_uv_rect": material.get_shader_parameter("sheet_uv_rect")})
	return {"source": piece.source_card_id, "serial": piece.source_serial, "item": piece.item_id, "rect": piece.source_rect,
		"thickness": piece.get_meta("paper_thickness"), "print": print_faces, "incisions": ink_masks}


func _work() -> Dictionary:
	return RationDeskRules.desk(Game.state)


func _check(condition: bool, reason: String) -> void:
	if not condition: _failures.append(reason)
