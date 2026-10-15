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
