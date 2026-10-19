extends TestCase
## Real Godot transforms: a flat-table back flip must expose the reverse face.

var fixture: Node3D


func before_each() -> void:
	fixture = Node3D.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var test_scene: Node = tree.root.get_child(tree.root.get_child_count() - 1)
	test_scene.add_child(fixture)


func after_each() -> void:
	fixture.free()


func _card() -> RationCard3D:
	var result: RationCard3D = RationCard3D.new()
	fixture.add_child(result)
	return result


func test_table_flip_exposes_opposite_printed_face_in_real_basis() -> void:
	var front: Basis = Basis(RationCard3D.table_orientation(true))
	var back: Basis = Basis(RationCard3D.table_orientation(false))
	assert_true((front * Vector3.BACK).is_equal_approx(Vector3.UP), "front printed normal points up")
	assert_true((back * Vector3.BACK).is_equal_approx(Vector3.DOWN), "front printed normal points down after flipping")
	assert_true((back * Vector3.FORWARD).is_equal_approx(Vector3.UP), "reverse printed normal is now exposed")
	assert_true(front.y.is_equal_approx(back.y), "flip is around the sheet's vertical axis")
	assert_true(front.x.is_equal_approx(-back.x), "left/right order physically reverses")


func test_table_flip_is_not_a_spin_of_the_front_in_default_yxz_eulers() -> void:
	var euler_spin: Basis = Basis.from_euler(Vector3(-PI / 2, PI, 0))
	assert_true((euler_spin * Vector3.BACK).is_equal_approx(Vector3.UP), "regression: old Euler pose still shows front")
	assert_false(Basis(RationCard3D.table_orientation(false)).is_equal_approx(euler_spin))
	var node: Node3D = Node3D.new()
	fixture.add_child(node)
	node.quaternion = RationCard3D.table_orientation(false)
	assert_true(node.global_basis.z.is_equal_approx(Vector3.DOWN), "Node3D uses the tested orientation")


func test_mirrored_reverse_coupon_pixels_map_to_same_physical_hole() -> void:
	var card: RationCard3D = _card()
	var reverse: MeshInstance3D
	for child: Node in card.get_children():
		if child is MeshInstance3D:
			var material: Material = (child as MeshInstance3D).material_override
			if material is ShaderMaterial and (material as ShaderMaterial).get_shader_parameter("back_face"):
				reverse = child as MeshInstance3D
	assert_true(reverse != null)
	if reverse == null:
		return
	card.position = Vector3(0.13, 0.98, -2.17)
	for showing_front: bool in [true, false]:
		card.quaternion = RationCard3D.table_orientation(showing_front)
		for index: int in 3:
			var rect: Rect2 = RationCardView.coupon_rect(index)
			for pixel: Vector2 in [rect.position, rect.get_center(), rect.end]:
				var reversed_pixel: Vector2 = Vector2(640 - pixel.x, pixel.y)
				var reverse_local: Vector3 = Vector3((reversed_pixel.x / 640.0 - 0.5) * RationCard3D.WIDTH, (0.5 - reversed_pixel.y / 400.0) * RationCard3D.HEIGHT, 0)
				var reverse_point: Vector3 = reverse.global_transform * reverse_local
				var front_point: Vector3 = card.pixel_to_world(pixel)
				# The two faces differ only by thickness along the sheet normal.
				var separation: Vector3 = front_point - reverse_point
				var tangent_separation: Vector3 = separation - card.global_basis.z * separation.dot(card.global_basis.z)
				assert_true(tangent_separation.length() < 0.000001, "reverse ink/hole lies behind the same paper position")


func test_ray_print_coordinate_roundtrip_for_front_and_reverse_table_poses() -> void:
	var card: RationCard3D = _card()
	card.position = Vector3(-0.21, 0.98, -2.15)
	for front: bool in [true, false]:
		card.quaternion = RationCard3D.table_orientation(front)
		for pixel: Vector2 in [Vector2(30, 285), Vector2(120, 330), Vector2(540, 180), Vector2(600, 375)]:
			var point: Vector3 = card.pixel_to_world(pixel)
			var normal: Vector3 = card.global_basis.z.normalized()
			var mapped: Vector2 = card.ray_pixel(point + normal * 0.5, -normal)
			assert_true(mapped.distance_to(pixel) < 0.001, "ray still hits the printed point after physical flip")


func test_table_hand_table_roundtrip_preserves_document_work_and_holes() -> void:
	var card: RationCard3D = _card()
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	var work: Dictionary = {"cuts": ["meat"], "marks": [{"kind": "approve", "x": 540, "y": 180}]}
	card.refresh(document, work)
	card.position = Vector3(-0.2, 0.98, -2.15)
	card.quaternion = RationCard3D.table_orientation(false)
	var table_pose: Transform3D = card.global_transform
	var camera: Node3D = Node3D.new()
	camera.position = Vector3(0, 1.62, -1.1)
	fixture.add_child(camera)
	card.reparent(camera)
	card.position = Vector3(-0.03, -0.14, -0.48)
	card.quaternion = Quaternion(Vector3.UP, PI)
	card.reparent(fixture)
	card.global_transform = table_pose
	assert_true(card.global_basis.z.is_equal_approx(Vector3.DOWN), "reverse remains exposed after returning to table")
	for renderer: RationCardView in card.renderers:
		assert_eq(renderer.work["cuts"], work["cuts"])
		assert_eq(renderer.work["marks"], work["marks"])
	for material: ShaderMaterial in card.materials:
		assert_eq(material.get_shader_parameter("missing"), Vector3(1, 0, 0), "both faces retain the same cut")


func test_two_centimetre_incision_opens_only_the_actual_path_and_has_cut_wall_geometry() -> void:
	var card: RationCard3D = _card()
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	var end_x: float = 30.0 + 0.02 / (RationCard3D.WIDTH / 640.0)
	card.refresh(document, {"cuts": [], "marks": [], "incisions": [{"points": [[30.0, 285.0], [end_x, 285.0]]}]})
	assert_true(card.incision_openness_at(Vector2(48, 285)) > 0.48, "the cut is a transparent slit")
	assert_eq(card.incision_openness_at(Vector2(70, 285)), 0.0, "paper beyond two centimetres remains intact")
	assert_eq(card.incision_openness_at(Vector2(48, 290)), 0.0, "paper beside the actual path remains intact")
	for material: ShaderMaterial in card.materials:
		assert_eq(material.get_shader_parameter("missing"), Vector3.ZERO, "a partial cut cannot remove a coupon")
		assert_true(material.get_shader_parameter("has_incisions"))
	assert_eq(card.materials[0].get_shader_parameter("incision_texture"), card.materials[1].get_shader_parameter("incision_texture"), "the two printed faces share one physical opening")
	var edges: MeshInstance3D = card.get_node("ExposedCutWallsAndFibres") as MeshInstance3D
	assert_true(edges.visible and edges.mesh != null, "the slit has thickness, cut lips and fibre geometry")
	assert_true(absf(edges.mesh.get_aabb().size.x - 0.02) < 0.0001, "cut walls cover two centimetres, not a whole coupon")


func test_live_slit_preview_clears_without_healing_persisted_incisions() -> void:
	var card: RationCard3D = _card()
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	var work: Dictionary = {"cuts": [], "marks": [], "incisions": [{"points": [[30, 285], [60, 285]]}]}
	card.refresh(document, work)
	card.cut_preview(PackedVector2Array([Vector2(60, 285), Vector2(90, 285)]))
	assert_true(card.incision_openness_at(Vector2(75, 285)) > 0.48, "only the actual live blade path opens")
	card.clear_cut_preview()
	assert_eq(card.incision_openness_at(Vector2(75, 285)), 0.0, "uncommitted preview clears explicitly")
	assert_true(card.incision_openness_at(Vector2(45, 285)) > 0.48, "committed damage remains")
	assert_eq(card.renderers[0].work["incisions"], work["incisions"], "preview never mutates campaign work")


func test_more_than_128_separate_cuts_render_without_silently_losing_old_damage() -> void:
	var card: RationCard3D = _card()
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	var incisions: Array = []
	for index: int in 140:
		incisions.append({"points": [[20 + index * 4, 100], [22 + index * 4, 100]]})
	card.refresh(document, {"cuts": [], "marks": [], "incisions": incisions})
	assert_true(card.incision_openness_at(Vector2(21, 100)) > 0.48, "the oldest cut is retained")
	assert_true(card.incision_openness_at(Vector2(577, 100)) > 0.48, "the newest cut is retained")
	assert_eq(card.incision_openness_at(Vector2(23, 100)), 0.0, "separate strokes are not joined by invented damage")


func test_paper_is_tessellated_for_held_flex_but_planar_for_desk_operations() -> void:
	var card: RationCard3D = _card()
	var surfaces: int = 0
	for child: Node in card.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).material_override is ShaderMaterial:
			var material: ShaderMaterial = (child as MeshInstance3D).material_override as ShaderMaterial
			if material.shader == preload("res://assets/shaders/ration_paper.gdshader"):
				assert_true((child as MeshInstance3D).mesh is ArrayMesh, "paper is geometry rather than a single quad")
				assert_true((child as MeshInstance3D).mesh.get_surface_count() > 0)
				surfaces += 1
	assert_eq(surfaces, 2)
	card.set_held(true)
	for material: ShaderMaterial in card.materials:
		assert_eq(material.get_shader_parameter("bend_amount"), 1.0)
	card.set_held(false)
	for material: ShaderMaterial in card.materials:
		assert_eq(material.get_shader_parameter("bend_amount"), 0.0, "desk cutting stays metrically planar")


func test_detached_piece_print_centre_matches_its_original_coupon_on_both_faces() -> void:
	# A resolution increase once cropped the holder's name onto the detached
	# coupon. Compare the actual viewport->print transform, not a scale constant.
	var card: RationCard3D = _card()
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	card.refresh(document, {"cuts": [], "marks": []})
	for index: int in 3:
		var piece: Node3D = card.create_coupon(index)
		fixture.add_child(piece)
		var count: int = 0
		for child: Node in piece.get_children():
			if not child is SubViewport: continue
			var viewport: SubViewport = child as SubViewport
			var printing: RationCardView = viewport.get_child(0) as RationCardView
			if printing == null: continue # Ignore the independent liquid mask.
			var sampled_print_point: Vector2 = printing.get_transform().affine_inverse() * (Vector2(viewport.size) / 2.0)
			var expected: Vector2 = RationCardView.coupon_rect(index).get_center()
			if not printing.front: expected.x = 640.0 - expected.x
			assert_true(sampled_print_point.distance_to(expected) < 0.001, "the detached face samples its own original product/amount, independent of render resolution")
			assert_eq(printing.card["serial"], document["serial"], "the original document's ink is retained")
			count += 1
		assert_eq(count, 2, "both physical faces carry the matching coupon ink")


func test_physically_severed_paper_detaches_before_approval_without_consuming_entitlement() -> void:
	var card: RationCard3D = _card()
	var document: Dictionary = (ContentDB.all_of("ration_case")[0] as Dictionary)["card"].duplicate(true)
	var rect: Rect2 = RationCardView.coupon_rect(1)
	var damage: Dictionary = {"cuts": [], "marks": [], "incisions": [{"points": [[rect.position.x, rect.position.y], [rect.end.x, rect.position.y], [rect.end.x, rect.end.y], [rect.position.x, rect.end.y], [rect.position.x, rect.position.y]]}]}
	card.refresh(document, damage)
	assert_false(card.has_paper_at(rect.get_center()), "four severed edges open a real hole even before a stamp")
	assert_true(card.has_paper_at(RationCardView.coupon_rect(0).get_center()), "other coupons remain present")
	assert_eq(damage["cuts"], [], "physical paper removal does not silently process a food entitlement")
	for material: ShaderMaterial in card.materials:
		assert_true((material.get_shader_parameter("missing") as Vector3).is_equal_approx(Vector3(0, 1, 0)), "both printed faces share the physical damage")
