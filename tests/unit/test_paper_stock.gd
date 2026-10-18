extends TestCase

var fixture: Node3D


func before_each() -> void:
	fixture = Node3D.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.get_child(tree.root.get_child_count() - 1).add_child(fixture)


func after_each() -> void:
	fixture.free()


func test_stock_and_normal_wear_cannot_encode_an_authenticity_or_occupation_answer() -> void:
	var original: Dictionary = {"serial": "STOCK-81", "paper_stock": "thin", "worn": true}
	var profile: Dictionary = PaperStockProfile.resolve(original)
	for occupation: String in ["worker", "teacher", "retired"]:
		var altered: Dictionary = original.duplicate(true)
		altered.merge({"class": occupation, "patch": true, "seal": false, "institution": "WRONG", "meat": 9000})
		assert_eq(PaperStockProfile.resolve(altered), profile, "paper supply and ordinary age are independent of evidence")
	assert_true(float(profile["wear"]) > .5, "a perfectly genuine document may be visibly worn")
	assert_eq(original, {"serial": "STOCK-81", "paper_stock": "thin", "worn": true}, "rendering leaves the document untouched")


func test_serial_stock_survives_refresh_and_json_but_explicit_supply_can_override_it() -> void:
	var document: Dictionary = {"serial": "ŁÓDŹ-1982-034"}
	var expected: Dictionary = PaperStockProfile.resolve(document)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(document))
	for repeat: int in 5:
		assert_eq(PaperStockProfile.resolve(restored), expected)
	for stock: String in ["thin", "medium", "thick"]:
		restored["paper_stock"] = stock
		assert_eq(PaperStockProfile.resolve(restored)["stock"], stock)
	assert_eq(PaperStockProfile.resolve({"serial": document["serial"], "paper_stock": "unknown"}), expected)


func test_three_physical_thicknesses_reach_both_faces_edges_and_pointer_plane() -> void:
	var card: RationCard3D = RationCard3D.new()
	fixture.add_child(card)
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	var thicknesses: Dictionary = {"thin": .00014, "medium": .00028, "thick": .00048}
	for stock: String in thicknesses:
		document["paper_stock"] = stock
		card.refresh(document, {"cuts": [], "marks": []})
		assert_true(absf(card._faces[0].position.z - card._faces[1].position.z - float(thicknesses[stock])) < .0000001)
		for edge: ShaderMaterial in card._edge_materials:
			assert_true(absf(float(edge.get_shader_parameter("sheet_half_thickness")) * 2.0 - float(thicknesses[stock])) < .0000001)
		for front: bool in [true, false]:
			card.front_showing = front
			card.quaternion = RationCard3D.table_orientation(front)
			var point: Vector3 = card.pixel_to_world(Vector2(350, 225))
			var reconstructed: Vector2 = card.ray_pixel(point + Vector3.UP * .6, Vector3.DOWN)
			assert_true(reconstructed.distance_to(Vector2(350, 225)) < .001, "stock thickness cannot shift the printed hit target")


func test_coupon_keeps_stock_original_ink_and_an_independent_canonical_damage_snapshot() -> void:
	var card: RationCard3D = RationCard3D.new()
	fixture.add_child(card)
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	document["paper_stock"] = "thick"
	var work: Dictionary = {"cuts": [], "marks": [{"kind": "approve", "x": 100, "y": 330, "serial": 1}], "incisions": [{"points": [[50, 325], [70, 325]]}]}
	card.refresh(document, work)
	var piece: Node3D = card.create_coupon(0)
	fixture.add_child(piece)
	var stock_seed: float = float(card.paper_profile["sheet_seed"])
	document["serial"] = "NEXT-CUSTOMER"
	document["paper_stock"] = "thin"
	card.refresh(document, {"cuts": [], "marks": [], "incisions": []})
	assert_eq(piece.get_meta("paper_stock"), "thick")
	assert_true(absf(float(piece.get_meta("paper_thickness")) - .00048) < .0000001)
	var faces: int = 0
	for child: Node in piece.get_children():
		if child is SubViewport:
			var renderer: RationCardView = child.get_child(0) as RationCardView
			assert_eq(renderer.work["marks"], work["marks"], "a stamp crossing the coupon remains on the detached paper")
			assert_eq(renderer.card["serial"], "W-14281")
		elif child is MeshInstance3D:
			var material: ShaderMaterial = (child as MeshInstance3D).material_override as ShaderMaterial
			if material.shader != preload("res://assets/shaders/ration_paper.gdshader"): continue
			faces += 1
			assert_eq(material.get_shader_parameter("sheet_uv_rect"), Vector4(30.0 / 640.0, 285.0 / 400.0, 180.0 / 640.0, 90.0 / 400.0))
			assert_eq(material.get_shader_parameter("sheet_seed"), stock_seed)
			assert_true(material.get_shader_parameter("has_incisions"))
			assert_true(material.get_shader_parameter("incision_texture") != card._incision_texture, "new customer damage cannot change detached paper")
	assert_eq(faces, 2)


func test_reference_reverse_page_is_upright_and_physical_under_existing_inspector_flip() -> void:
	var reference: RationDeskReference = RationDeskReference.new()
	fixture.add_child(reference)
	var leaf: MeshInstance3D = reference.get_node("WorldPaperEvidenceLeaf") as MeshInstance3D
	var inspected: Basis = Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, PI / 2.0) * leaf.basis
	assert_true(inspected.x.is_equal_approx(Vector3.RIGHT), "printed left/right is not mirrored")
	assert_true(inspected.y.is_equal_approx(Vector3.BACK), "page normal faces the camera")
	assert_true((inspected * Vector3.FORWARD).is_equal_approx(Vector3.UP), "printed top points up")
	assert_true(leaf.position.y < 0 and (leaf.mesh as PlaneMesh).size == RationDeskReference.PAGE_SIZE)
	assert_eq(reference.evidence_viewport.gui_disable_input, true, "printed guidance is not a document dashboard")
