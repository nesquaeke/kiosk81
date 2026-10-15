class_name RationParcel3D
extends Interactable
## Reusable physical order, with its origin on the supporting surface.
## Labels are ink attached to packaging; source is bookkeeping, never a verdict cue.

const SUPPORTED: PackedStringArray = ["meat", "sugar", "soap"]
var amount: int = 750
var source: String = "official"
var caption: Label3D
var bounds_size: Vector3 = Vector3(0.23, 0.085, 0.16)
var grip_position: Vector3 = Vector3(-0.105, 0.035, 0.04)
var support_offset: float = 0.0
var _model: Node3D
var _collision: CollisionShape3D


func _ready() -> void:
	action = "parcel"
	collision_layer = 2
	collision_mask = 0
	_model = Node3D.new()
	_model.name = "Packaging"
	add_child(_model)
	_collision = CollisionShape3D.new()
	_collision.name = "OrderCollision"
	add_child(_collision)
	if item_id.is_empty(): item_id = "meat"
	_rebuild()


func configure(product: String, quantity: int, stock_source: String) -> void:
	if product not in SUPPORTED or quantity <= 0:
		push_error("A physical ration parcel needs a supported product and positive amount.")
		return
	var changed: bool = item_id != product
	item_id = product
	amount = quantity
	source = stock_source
	# configure is valid before entering the tree; _ready consumes these values.
	if _model == null: return
	if changed: _rebuild()
	else: _update_caption()


func carry_position() -> Vector3:
	return Vector3(0.17, -0.25, -0.43) if item_id != "soap" else Vector3(0.17, -0.22, -0.39)


func carry_rotation() -> Vector3:
	match item_id:
		"sugar": return Vector3(0.03, -0.08, -0.14)
		"soap": return Vector3(0.35, -0.05, -0.18)
	return Vector3(0.22, -0.1, -0.14)


func _rebuild() -> void:
	# Only packaging is replaced, never the interactable body or its world transform.
	for child: Node in _model.get_children():
		_model.remove_child(child)
		child.free()
	caption = null
	match item_id:
		"sugar": _sugar()
		"soap": _soap()
		_: _meat()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = bounds_size
	_collision.shape = shape
	_collision.position = Vector3(0, bounds_size.y / 2, 0)
	_update_caption()


func _meat() -> void:
	bounds_size = Vector3(0.23, 0.085, 0.16)
	grip_position = Vector3(-0.105, 0.035, 0.04)
	var paper: Color = Color("c9b794")
	_box(Vector3(0.226, 0.077, 0.154), Vector3(0, 0.0385, 0), paper)
	# Folded butcher-paper flaps and narrow raised creases catch grazing light.
	for side: float in [-1.0, 1.0]:
		var fold: MeshInstance3D = _box(Vector3(0.052, 0.003, 0.148), Vector3(side * 0.084, 0.078, 0), Color("d8c7a6"))
		fold.rotation.z = side * 0.045
		_box(Vector3(0.224, 0.004, 0.018), Vector3(0, 0.077, side * 0.061), paper.darkened(0.08))
	# Cotton twine wraps the body in two continuous loops rather than floating above it.
	var twine: Color = Color("81704f")
	for x: float in [-0.062, 0.062]:
		_segment(Vector3(x, 0.083, -0.078), Vector3(x, 0.083, 0.078), 0.0011, twine)
		_segment(Vector3(x, 0.002, -0.078), Vector3(x, 0.002, 0.078), 0.0011, twine)
		for z: float in [-0.078, 0.078]:
			_segment(Vector3(x, 0.002, z), Vector3(x, 0.083, z), 0.0011, twine)
	_segment(Vector3(-0.018, 0.084, -0.003), Vector3(0.012, 0.084, 0.007), 0.0013, twine)
	_label(Vector3(0, 0.082, -0.012), true, Color("744b42"), 0.00045)


func _sugar() -> void:
	bounds_size = Vector3(0.118, 0.192, 0.088)
	grip_position = Vector3(-0.055, 0.055, 0.018)
	var paper: Color = Color("d9d1b6")
	_box(Vector3(0.112, 0.172, 0.082), Vector3(0, 0.086, 0), paper)
	# Rolled/folded paper top, side gussets and a bottom seam.
	_box(Vector3(0.118, 0.014, 0.025), Vector3(0, 0.183, 0), Color("c0b69a"))
	_box(Vector3(0.114, 0.004, 0.051), Vector3(0, 0.174, 0), paper.lightened(0.03))
	for side: float in [-1.0, 1.0]:
		_box(Vector3(0.002, 0.151, 0.012), Vector3(side * 0.057, 0.09, 0), paper.darkened(0.12))
	_box(Vector3(0.108, 0.009, 0.084), Vector3(0, 0.008, 0), paper.darkened(0.05))
	_box(Vector3(0.096, 0.107, 0.0006), Vector3(0, 0.101, 0.0414), Color("e6dfc6"))
	_label(Vector3(0, 0.105, 0.042), false, Color("384b65"), 0.00037)


func _soap() -> void:
	bounds_size = Vector3(0.132, 0.046, 0.078)
	grip_position = Vector3(-0.064, 0.019, 0.022)
	_box(Vector3(0.13, 0.042, 0.074), Vector3(0, 0.021, 0), Color("b9bea1"))
	# A paper sleeve leaves the ends of the plain household bar visible.
	_box(Vector3(0.084, 0.046, 0.078), Vector3(0, 0.023, 0), Color("d8cdb1"))
	for x: float in [-0.038, 0.038]:
		_box(Vector3(0.004, 0.0008, 0.07), Vector3(x, 0.0464, 0), Color("71816d"))
	_label(Vector3(0, 0.0468, 0), true, Color("435749"), 0.00031)


func _update_caption() -> void:
	if caption == null: return
	match item_id:
		"meat": caption.text = "MIĘSO\n%d g" % amount
		"sugar": caption.text = "CUKIER\nKRYSZTAŁ\n%d g" % amount
		"soap": caption.text = "MYDŁO\n%d szt." % amount


func _label(at: Vector3, upward: bool, ink: Color, pixel: float) -> void:
	caption = Label3D.new()
	caption.name = "PrintedLabel"
	caption.position = at
	caption.font_size = 32
	caption.pixel_size = pixel
	caption.modulate = ink
	caption.outline_size = 0
	caption.shaded = true
	caption.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	if upward: caption.rotation.x = -PI / 2
	_model.add_child(caption)


func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _mesh(mesh, at, color)


func _segment(from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 8
	var node: MeshInstance3D = _mesh(mesh, (from + to) / 2, color)
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())


func _mesh(mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	node.material_override = material
	_model.add_child(node)
	return node
