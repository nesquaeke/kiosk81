extends TestCase
## A magnifier must photograph the physical world without photographing itself.

var fixture: Node3D


func before_each() -> void:
	fixture = Node3D.new()
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var test_scene: Node = tree.root.get_child(tree.root.get_child_count() - 1)
	test_scene.add_child(fixture)


func after_each() -> void:
	fixture.free()


func test_optical_camera_shares_the_world_but_cannot_see_its_own_lens() -> void:
	var loupe: InspectionLoupe = InspectionLoupe.new()
	loupe.configure(fixture.get_world_3d())
	fixture.add_child(loupe)
	assert_eq(loupe.action, "loupe")
	assert_eq(loupe.viewport.world_3d, fixture.get_world_3d(), "the lens renders actual paper, stamps and damage")
	assert_eq(loupe.focus_camera.cull_mask & InspectionLoupe.LENS_LAYER, 0, "the magnifier cannot cause recursive feedback")
	assert_eq(loupe.lens.layers, InspectionLoupe.LENS_LAYER)
	assert_true(loupe.focus_camera.size < InspectionLoupe.LENS_DIAMETER, "the lens magnifies a smaller real-world area")
	assert_true(loupe.get_node_or_null("LensPickupVolume") is CollisionShape3D, "the tool can be physically picked up")


func test_focus_before_ready_is_applied_in_world_space_without_moving_the_tool() -> void:
	var loupe: InspectionLoupe = InspectionLoupe.new()
	var focus: Vector3 = Vector3(-0.2, 0.978, -2.1)
	loupe.update_focus(focus)
	fixture.add_child(loupe)
	loupe.position = Vector3(0.3, 1.1, -1.9)
	loupe.rotation = Vector3(0.0, 0.6, 0.0)
	assert_true(loupe.focus_camera.global_position.is_equal_approx(focus + Vector3.UP * InspectionLoupe.CAMERA_HEIGHT), "the optical camera stays on the paper point rather than following the hand")
	assert_true((-loupe.focus_camera.global_basis.z).is_equal_approx(Vector3.DOWN))
	var held_pose: Transform3D = loupe.global_transform
	loupe.update_focus(focus + Vector3.RIGHT * 0.01)
	assert_eq(loupe.global_transform, held_pose, "focusing never teleports the physical tool")


func test_inactive_loupe_stops_rendering_and_preserves_its_last_valid_focus() -> void:
	var loupe: InspectionLoupe = InspectionLoupe.new()
	fixture.add_child(loupe)
	loupe.update_focus(Vector3(0.1, 0.98, -2.0))
	var last: Vector3 = loupe.focus_camera.global_position
	loupe.set_active(true)
	assert_true(loupe.is_active())
	assert_eq(loupe.viewport.render_target_update_mode, SubViewport.UPDATE_ALWAYS)
	loupe.update_focus(Vector3(INF, 0, 0))
	assert_eq(loupe.focus_camera.global_position, last, "invalid aim rays cannot corrupt the camera transform")
	loupe.set_active(false)
	assert_false(loupe.is_active())
	assert_eq(loupe.viewport.render_target_update_mode, SubViewport.UPDATE_DISABLED, "a stored magnifier has no continuous render cost")
