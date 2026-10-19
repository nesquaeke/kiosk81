extends TestCase

var fixture: Node3D
var pad: StampInkPad


func before_each() -> void:
	fixture = Node3D.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.get_child(tree.root.get_child_count() - 1).add_child(fixture)
	pad = StampInkPad.new()
	fixture.add_child(pad)


func after_each() -> void:
	fixture.free()


func test_felt_contact_coordinates_follow_the_physical_case() -> void:
	pad.position = Vector3(-0.48, 0.961, -1.86)
	pad.rotation.y = 0.37
	var local_xz: Vector2 = Vector2(0.020, -0.013)
	var world: Vector3 = pad.felt_world_point(local_xz)
	assert_true(world.is_equal_approx(pad.to_global(Vector3(local_xz.x, pad.felt_surface_y, local_xz.y))))
	assert_true(pad.contains_felt(world))
	assert_false(pad.contains_felt(pad.felt_world_point(Vector2(pad.felt_size.x, 0))))
	assert_eq(pad.action, "ink_pad")


func test_footprint_inset_cannot_accept_a_stamp_wider_than_the_felt() -> void:
	assert_true(pad.contains_felt(pad.felt_world_point(), 0.015))
	assert_false(pad.contains_felt(pad.felt_world_point(Vector2(0.060, 0)), 0.015))
	assert_false(pad.contains_felt(pad.felt_world_point(), pad.felt_size.x))
	assert_false(pad.contains_felt(Vector3(INF, 0, 0)))


func test_pressure_depresses_only_the_local_contact_and_releases_exactly() -> void:
	var contact: Vector2 = Vector2(0.016, 0.005)
	var original: Vector3 = pad.felt_world_point(contact)
	var corner: Vector3 = pad.felt_world_point(Vector2(-0.060, -0.030))
	pad.press_at(original, 0.5)
	assert_true(absf(pad.compression_depth - StampInkPad.MAX_COMPRESSION * 0.5) < 0.0000001)
	assert_true(absf((original.y - pad.felt_world_point(contact).y) - pad.compression_depth) < 0.0000001)
	assert_true(pad.felt_world_point(Vector2(-0.060, -0.030)).is_equal_approx(corner))
	pad.release_press()
	assert_eq(pad.pressure, 0.0)
	assert_true(pad.felt_world_point(contact).is_equal_approx(original))


func test_off_pad_contact_cannot_compress_the_felt_and_saturation_is_bounded() -> void:
	pad.press_at(pad.felt_world_point(Vector2(1, 0)), 1.0)
	assert_eq(pad.compression_depth, 0.0)
	pad.set_saturation(-1.0)
	assert_eq(pad.saturation, 0.0)
	pad.set_saturation(3.0)
	assert_eq(pad.saturation, 1.0)
	pad.set_saturation(NAN)
	assert_eq(pad.saturation, 1.0)
	assert_eq(pad._felt_material.get_shader_parameter("saturation"), pad.saturation)
