class_name HeldObjectInspector
extends Node
## Operates on the existing world object. No copy, inventory icon or card GUI.
## The owner restores hands, movement and pointer; this node restores exact pose.

const NEAR_MARGIN: float = 0.015

var active: bool = false
var dragging: bool = false
var object: Node3D
var _camera: Camera3D
var _rest: Transform3D
var _rest_attributes: CameraAttributes
var _attributes: CameraAttributesPractical
var _base: Quaternion
var _distance: float = 0.5
var _fit_distance: float = 0.5
var _zoom: float = 1.0
var _radius: float = 0.22
var _dimensions: Vector3 = Vector3.ONE
var _center: Vector3 = Vector3.ZERO
var _turn: Tween
var _light: OmniLight3D
var backlight_enabled: bool = false
var backlight_amount: float = 0.0
var _backlight: SpotLight3D


func open(target: Node3D, camera: Camera3D, readable: Quaternion, dimensions: Vector3, center: Vector3 = Vector3.ZERO) -> void:
	if active: return
	object = target
	_camera = camera
	_rest = object.transform
	_rest_attributes = camera.attributes
	_base = readable
	_center = center
	_dimensions = dimensions.abs()
	_radius = dimensions.length() * 0.5
	var aspect: float = maxf(0.35, camera.get_viewport().get_visible_rect().size.aspect())
	var half_fov: float = atan(tan(deg_to_rad(camera.fov * 0.5)) * minf(1.0, aspect))
	# Fit a bounding sphere so portrait windows and edge-on rotations stay usable.
	_fit_distance = maxf(_radius + camera.near + 0.06, _radius / sin(half_fov) * 1.02)
	_zoom = 1.0
	_distance = _fit_distance
	active = true
	dragging = false
	_light = OmniLight3D.new()
	_light.position = Vector3(-0.18, 0.20, -0.12)
	_light.light_color = Color("fff0d8")
	# Enough fill to read the reverse without clipping the high-albedo stock;
	# raking room light should still reveal grain, folds and the pasted edge.
	_light.light_energy = 0.035
	_light.omni_range = 1.2
	_light.shadow_enabled = false
	camera.add_child(_light)
	backlight_enabled = false
	backlight_amount = 0.0
	if target is RationCard3D:
		_backlight = SpotLight3D.new()
		_backlight.name = "InspectionTransmissionLight"
		_backlight.light_color = Color("ffe8b9")
		_backlight.light_energy = 0.0
		_backlight.spot_range = 0.9
		_backlight.spot_angle = 48.0
		_backlight.shadow_enabled = false
		camera.add_child(_backlight)
		(target as RationCard3D).set_inspection_light(0.0)
	# Compatibility rendering has no depth-of-field support. Keep its actual
	# 3D background rather than substituting a static fake room image.
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		_attributes = null
	else:
		_attributes = CameraAttributesPractical.new()
		_attributes.dof_blur_far_enabled = true
		_attributes.dof_blur_far_transition = 0.8
		_attributes.dof_blur_amount = 0.12
		camera.attributes = _attributes
	_move_to(readable, 0.22)


func rotate_object(movement: Vector2) -> void:
	if not active or not dragging: return
	_stop_turn()
	var horizontal: Quaternion = Quaternion(Vector3.UP, movement.x * 0.008)
	var vertical: Quaternion = Quaternion(Vector3.RIGHT, movement.y * 0.008)
	object.quaternion = (horizontal * vertical * object.quaternion).normalized()
	_update_position()


func zoom(step: float) -> void:
	if not active: return
	_stop_turn()
	_zoom = clampf(_zoom * pow(1.12, step), 0.60, 1.60)
	_update_position()


func readable_face(back: bool) -> void:
	if active:
		_move_to(Quaternion(Vector3.UP, PI if back else 0.0) * _base, 0.20)


func reset_pose() -> void:
	if not active: return
	_zoom = 1.0
	_distance = _fit_distance
	_move_to(_base, 0.20)


func capture_view() -> Dictionary:
	return {"rotation": object.quaternion, "zoom": _zoom} if active else {}


func restore_view(view: Dictionary) -> void:
	if not active or view.is_empty(): return
	_zoom = clampf(float(view.get("zoom", 1.0)), 0.60, 1.60)
	_move_to(view.get("rotation", _base), 0.20)


func toggle_backlight() -> void:
	if active and object is RationCard3D:
		backlight_enabled = not backlight_enabled


func _process(delta: float) -> void:
	if not active or not object is RationCard3D: return
	backlight_amount = move_toward(backlight_amount, 1.0 if backlight_enabled else 0.0, delta * 5.0)
	_backlight.position = Vector3(0.035, 0.075, -_distance - _radius - 0.12)
	_backlight.look_at(object.global_position, _camera.global_basis.y)
	_backlight.light_energy = backlight_amount * 0.32
	var toward_light: Vector3 = object.global_basis.inverse() * (_backlight.global_position - object.global_position).normalized()
	(object as RationCard3D).set_inspection_light(backlight_amount, toward_light)


func close() -> void:
	if not active: return
	_stop_turn()
	dragging = false
	if object is RationCard3D: (object as RationCard3D).set_inspection_light(0.0)
	backlight_enabled = false
	backlight_amount = 0.0
	if is_instance_valid(_backlight): _backlight.queue_free()
	_backlight = null
	object.transform = _rest
	_camera.attributes = _rest_attributes
	if is_instance_valid(_light): _light.queue_free()
	_attributes = null
	object = null
	active = false


func _update_position() -> void:
	_distance = maxf(_fit_distance * _zoom, _pose_clearance())
	object.position = Vector3(0, 0.015, -_distance) - object.basis * _center
	if _attributes != null: _attributes.dof_blur_far_distance = _distance + _radius + 0.05


func _move_to(orientation: Quaternion, duration: float) -> void:
	_stop_turn()
	var from_rotation: Quaternion = object.quaternion
	var from_center: Vector3 = object.position + object.basis * _center
	_turn = create_tween()
	# Position and orientation cannot be independent tracks: a flat sheet can be
	# closer than its edge-on depth permits halfway through the same flip.
	_turn.tween_method(_turn_pose.bind(from_rotation, orientation.normalized(), from_center), 0.0, 1.0, duration)


func _turn_pose(progress: float, from_rotation: Quaternion, to_rotation: Quaternion, from_center: Vector3) -> void:
	if not active: return
	var rotation_weight: float = (1.0 - cos(progress * PI)) * 0.5
	object.quaternion = from_rotation.slerp(to_rotation, rotation_weight).normalized()
	var clearance: float = _pose_clearance()
	var requested: float = maxf(_fit_distance * _zoom, clearance)
	var position_weight: float = 1.0 - pow(1.0 - progress, 3.0)
	var optical_center: Vector3 = from_center.lerp(Vector3(0, 0.015, -requested), position_weight)
	optical_center.z = minf(optical_center.z, -clearance)
	_distance = -optical_center.z
	object.position = optical_center - object.basis * _center
	if _attributes != null: _attributes.dof_blur_far_distance = _distance + _radius + 0.05


func _pose_clearance() -> float:
	# Actual scale is retained by Node3D when its quaternion changes. Centering
	# uses the same full basis above, including an off-origin stamp head.
	var half: Vector3 = _dimensions * 0.5
	var depth: float = absf(object.basis.x.z) * half.x + absf(object.basis.y.z) * half.y + absf(object.basis.z.z) * half.z
	return _camera.near + NEAR_MARGIN + depth


static func clearance_distance(dimensions: Vector3, orientation: Quaternion, near: float, margin: float = NEAR_MARGIN, center: Vector3 = Vector3.ZERO) -> float:
	# Eight actual box corners are measured relative to their optical center.
	# The center cancels after correct placement, rather than adding the object's
	# origin offset to the needed clearance (which prevented small-paper zoom).
	var basis: Basis = Basis(orientation.normalized())
	var rotated_center: Vector3 = basis * center
	var half: Vector3 = dimensions.abs() * 0.5
	var closest: float = -INF
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			for z: float in [-1.0, 1.0]:
				var corner: Vector3 = center + half * Vector3(x, y, z)
				closest = maxf(closest, (basis * corner - rotated_center).z)
	return maxf(0.0, near) + maxf(0.0, margin) + closest


func _stop_turn() -> void:
	if _turn != null and _turn.is_valid(): _turn.kill()
