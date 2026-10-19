extends TestCase

var fixture: Node3D


func before_each() -> void:
	fixture = Node3D.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.get_child(tree.root.get_child_count() - 1).add_child(fixture)


func after_each() -> void:
	fixture.free()


func test_all_coupons_keep_actual_crop_dimensions_and_two_face_selection() -> void:
	var card: RationCard3D = _card()
	for index: int in 3:
		var piece: CouponFragment3D = card.create_coupon(index)
		fixture.add_child(piece)
		var rect: Rect2 = RationCardView.coupon_rect(index)
		var expected: Vector2 = rect.size / RationCardView.PAPER_SIZE * Vector2(RationCard3D.WIDTH, RationCard3D.HEIGHT)
		assert_true(piece.world_size.is_equal_approx(expected), "a cropped coupon must not retain full card dimensions")
		var shape: BoxShape3D = piece._collision.shape as BoxShape3D
		assert_true(Vector2(shape.size.x, shape.size.y).is_equal_approx(expected))
		assert_true(piece._collision.position.is_zero_approx(), "front and back share a centered selection volume")
		assert_eq(piece.item_id, RationDeskRules.PRODUCT_ORDER[index])
		assert_eq(piece.action, "coupon")
		for front: bool in [true, false]:
			piece.quaternion = CouponFragment3D.table_orientation(front)
			var normal: Vector3 = piece.basis * Vector3.BACK
			assert_true(normal.is_equal_approx(Vector3.UP if front else Vector3.DOWN), "turning the fragment exposes its other physical face")


func test_hand_archive_and_next_document_preserve_the_same_fragment_and_print() -> void:
	var card: RationCard3D = _card()
	var piece: CouponFragment3D = card.create_coupon(1)
	fixture.add_child(piece)
	var original_children: Array[Node] = piece.get_children()
	var original_serial: String = piece.source_serial
	var original_dimensions: Vector3 = piece.dimensions
	for repeat: int in 3:
		piece.set_held(true)
		assert_eq(piece.collision_layer, 0, "a held fragment must not occlude the desk ray")
		piece.set_archived(true)
		piece.set_held(false)
		assert_eq(piece.collision_layer, 2, "archived paper remains physically retrievable")
	var other: Dictionary = (ContentDB.all_of("ration_case")[1] as Dictionary)["card"].duplicate(true)
	card.refresh(other, {"cuts": [], "marks": []})
	assert_eq(piece.get_children(), original_children, "holding and archiving keep the original two faces and edge")
	assert_eq(piece.source_serial, original_serial)
	assert_eq(piece.get_meta("serial"), original_serial)
	assert_eq(piece.dimensions, original_dimensions)
	var printed_faces: int = 0
	for child: Node in piece.get_children():
		if child is SubViewport:
			var renderer: RationCardView = child.get_child(0) as RationCardView
			if renderer == null: continue # Liquid mask is not another printed face.
			printed_faces += 1
			assert_eq(renderer.card["serial"], original_serial, "the next customer's print must not replace a collected fragment")
	assert_eq(printed_faces, 2, "both original printed faces must remain on the same fragment")


func _card() -> RationCard3D:
	var card: RationCard3D = RationCard3D.new()
	fixture.add_child(card)
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	document["paper_stock"] = "thick"
	card.refresh(document, {"cuts": [], "marks": []})
	return card
