extends TestCase
## Verify the physical near-plane geometry, not a fixed sphere-distance proxy.

var fixture: Node3D
var camera: Camera3D
var paper: Node3D
var inspector: HeldObjectInspector
var dimensions: Vector3 = Vector3(0.10125, 0.050625, 0.00028)


func before_each() -> void:
	fixture = Node3D.new()
	# The runner executes synchronously in its scene's _ready, while the root is
	# still adding that scene. An already-ready autoload can host the fixture.
	(Engine.get_main_loop() as SceneTree).root.get_node("Game").add_child(fixture)
	camera = Camera3D.new()
	camera.near = 0.05
	fixture.add_child(camera)
	paper = Node3D.new()
	camera.add_child(paper)
	paper.position = Vector3(0.1, -0.1, -0.48)
	inspector = HeldObjectInspector.new()
	fixture.add_child(inspector)


func after_each() -> void:
	inspector.close()
	fixture.free()


func test_flat_coupon_zoom_gets_closer_from_its_default_opening_pose() -> void:
	_open()
	var initial: float = inspector._distance
	inspector.zoom(-30.0)
	assert_eq(inspector._zoom, 0.60)
	assert_true(inspector._distance < initial * 0.80, "wheel-up must visibly enlarge a small flat fragment immediately")
	_assert_corners_clear()
	inspector.zoom(100.0)
	assert_eq(inspector._zoom, 1.60)
	assert_true(inspector._distance > initial)


func test_edge_on_rotation_moves_a_zoomed_coupon_back_only_as_far_as_needed() -> void:
	_open()
	inspector.zoom(-30.0)
	var flat: float = inspector._distance
	inspector.dragging = true
	inspector.rotate_object(Vector2(PI / 2.0 / 0.008, 0))
	assert_true(inspector._distance > flat + 0.005, "the wide paper edge must clear the near plane after rotation")
	var expected: float = camera.near + HeldObjectInspector.NEAR_MARGIN + dimensions.x * 0.5
	assert_true(absf(inspector._distance - expected) < 0.000001)
	_assert_corners_clear()


func test_all_eight_corners_clear_the_near_plane_at_many_drag_orientations() -> void:
	dimensions = Vector3(0.36, 0.225, 0.01)
	_open()
	inspector.zoom(-100.0)
	inspector.dragging = true
	for turn: int in 120:
		inspector.rotate_object(Vector2(13.0, 7.0))
		_assert_corners_clear()


func test_off_origin_scaled_stamp_centers_and_clears_its_actual_corners() -> void:
	dimensions = Vector3(0.105, 0.20, 0.07)
	var center: Vector3 = Vector3(0.0, 0.09, 0.0)
	paper.scale = Vector3(0.8, 1.2, 0.9)
	_open(Quaternion(Vector3.RIGHT, 0.35), center)
	inspector.zoom(-100.0)
	inspector.dragging = true
	for turn: int in 40:
		inspector.rotate_object(Vector2(17.0, 11.0))
		var optical_center: Vector3 = paper.position + paper.basis * center
		assert_true(absf(optical_center.x) < 0.000001)
		assert_true(absf(optical_center.y - 0.015) < 0.000001)
		_assert_corners_clear(center)


func test_zoomed_flip_keeps_every_intermediate_orientation_clear() -> void:
	_open()
	inspector.zoom(-100.0)
	var initial: float = inspector._distance
	var furthest: float = initial
	inspector.readable_face(true)
	for frame: int in 25:
		inspector._turn.custom_step(0.008)
		furthest = maxf(furthest, inspector._distance)
		_assert_corners_clear()
	assert_true(furthest > initial + 0.005, "flat safe endpoints do not guarantee a safe halfway flip")
	assert_true(paper.basis.z.dot(Vector3.FORWARD) > 0.99999)
	assert_true(absf(inspector._distance - initial) < 0.00001)


func test_cancel_mid_tween_restores_exact_transform_and_camera_attributes() -> void:
	var original: Transform3D = Transform3D(Basis.from_euler(Vector3(0.2, -0.3, 0.1)).scaled(Vector3(0.8, 1.2, 0.9)), Vector3(0.15, -0.1, -0.4))
	paper.transform = original
	var attributes: CameraAttributesPractical = CameraAttributesPractical.new()
	camera.attributes = attributes
	_open()
	inspector.zoom(-100.0)
	inspector.readable_face(true)
	inspector._turn.custom_step(0.08)
	_assert_corners_clear()
	inspector.close()
	assert_eq(paper.transform, original, "no inverse approximation may replace the saved local transform")
	assert_eq(camera.attributes, attributes)
	assert_false(inspector.active)
	assert_false(inspector._turn.is_valid(), "cancel must stop the pose callback before a later frame")


func test_view_restore_keeps_zoom_and_orientation_without_bypassing_clearance() -> void:
	_open()
	inspector.zoom(-100.0)
	inspector.dragging = true
	inspector.rotate_object(Vector2(145, -53))
	var view: Dictionary = inspector.capture_view()
	inspector.reset_pose()
	inspector._turn.custom_step(1.0)
	inspector.restore_view(view)
	for frame: int in 25:
		inspector._turn.custom_step(0.008)
		_assert_corners_clear()
	assert_eq(inspector._zoom, 0.60)
	assert_true(paper.quaternion.is_equal_approx(view["rotation"]))


func test_initial_opening_keeps_the_existing_bounding_sphere_fit() -> void:
	_open()
	var radius: float = dimensions.length() * 0.5
	var aspect: float = maxf(0.35, camera.get_viewport().get_visible_rect().size.aspect())
	var half_fov: float = atan(tan(deg_to_rad(camera.fov * 0.5)) * minf(1.0, aspect))
	var expected: float = maxf(radius + camera.near + 0.06, radius / sin(half_fov) * 1.02)
	assert_true(absf(inspector._fit_distance - expected) < 0.000001)
	assert_true(absf(inspector._distance - expected) < 0.000001)


func test_public_clearance_uses_rotated_half_extents_and_correct_optical_center() -> void:
	var flat: float = HeldObjectInspector.clearance_distance(dimensions, Quaternion.IDENTITY, 0.05)
	assert_true(absf(flat - (0.05 + 0.015 + dimensions.z * 0.5)) < 0.000001)
	var edge: Quaternion = Quaternion(Vector3.UP, PI / 2.0)
	var side: float = HeldObjectInspector.clearance_distance(dimensions, edge, 0.05)
	assert_true(absf(side - (0.05 + 0.015 + dimensions.x * 0.5)) < 0.000001)
	var offset: float = HeldObjectInspector.clearance_distance(dimensions, edge, 0.05, 0.015, Vector3(0, 0.09, 0.035))
	assert_true(absf(offset - side) < 0.000001, "the supplied center is compensated in the placement, not added to the sphere")


func _open(readable: Quaternion = Quaternion.IDENTITY, center: Vector3 = Vector3.ZERO) -> void:
	inspector.open(paper, camera, readable, dimensions, center)
	inspector._turn.custom_step(1.0)


func _assert_corners_clear(center: Vector3 = Vector3.ZERO) -> void:
	var half: Vector3 = dimensions * 0.5
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				var corner: Vector3 = paper.transform * (center + half * Vector3(x, y, z))
				assert_true(-corner.z >= camera.near + HeldObjectInspector.NEAR_MARGIN - 0.000001, "an actual transformed corner crossed the near-plane margin")
