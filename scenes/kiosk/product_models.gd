class_name KioskProductModels
extends RefCounted
## Metre-scale primitives. No external textures or historically invented brands.


static func create(item_id: String) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = item_id.trim_prefix("itm_").to_pascal_case()
	var spec: Dictionary = KioskCatalog.product(item_id)
	var color: Color = spec.get("color", Color.GRAY)
	var ink: Color = Color("35322b")
	match str(spec.get("shape", "")):
		"newspaper":
			for i: int in 3:
				_box(root, Vector3(0.22, 0.003, 0.16), Vector3(0, 0.002 + i * 0.003, 0), color.lightened(i * 0.03))
			_box(root, Vector3(0.19, 0.001, 0.018), Vector3(0, 0.01, -0.05), Color("9e3931"))
			for column: int in 3:
				for line: int in 6:
					_box(root, Vector3(0.05, 0.001, 0.002), Vector3(-0.065 + column * 0.065, 0.01, -0.02 + line * 0.014), ink)
		"magazine", "notebook":
			_box(root, Vector3(0.17, 0.015, 0.22), Vector3(0, 0.009, 0), Color("e7dfc7"))
			_box(root, Vector3(0.18, 0.002, 0.23), Vector3(0, 0.018, 0), color)
			_box(root, Vector3(0.015, 0.02, 0.23), Vector3(-0.087, 0.011, 0), color.darkened(0.3))
			_box(root, Vector3(0.12, 0.001, 0.055), Vector3(0, 0.02, -0.06), Color("e7dfc7"))
			_top_text(root, "PRZEKRÓJ" if spec["shape"] == "magazine" else "ZESZYT", Vector3(0, 0.022, -0.06), 0.0011)
		"matches", "blades":
			_box(root, Vector3(0.105, 0.027, 0.075), Vector3(0, 0.014, 0), color)
			_box(root, Vector3(0.106, 0.014, 0.003), Vector3(0, 0.014, 0.039), Color("654832"))
			_box(root, Vector3(0.072, 0.001, 0.05), Vector3(0, 0.028, 0), Color("efe3c7"))
			_top_text(root, "ZAPAŁKI" if spec["shape"] == "matches" else "ŻYLETKI", Vector3(0, 0.03, 0), 0.0007)
		"ticket":
			_box(root, Vector3(0.075, 0.003, 0.135), Vector3(0, 0.002, 0), color)
			for line: int in 5:
				_box(root, Vector3(0.055, 0.001, 0.002), Vector3(0, 0.005, 0.01 + line * 0.009), ink)
			_top_text(root, "BILET", Vector3(0, 0.006, -0.03), 0.0008)
		"envelope":
			_box(root, Vector3(0.20, 0.004, 0.13), Vector3(0, 0.003, 0), color)
			for direction: int in [-1, 1]:
				var flap: MeshInstance3D = _box(root, Vector3(0.105, 0.001, 0.002), Vector3(direction * 0.045, 0.006, -0.025), color.darkened(0.22))
				flap.rotation.y = direction * -0.55
		"soap":
			_box(root, Vector3(0.13, 0.035, 0.085), Vector3(0, 0.018, 0), color)
			_box(root, Vector3(0.055, 0.036, 0.087), Vector3(0, 0.019, 0), Color("e5dbbc"))
			_top_text(root, "MYDŁO", Vector3(0, 0.039, 0), 0.00065)
		"laces":
			_box(root, Vector3(0.085, 0.003, 0.15), Vector3(0, 0.002, 0), Color("c4b193"))
			for i: int in 5:
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 0.015
				ring.outer_radius = 0.020
				var mi: MeshInstance3D = _mesh(root, ring, Vector3(0, 0.01, -0.045 + i * 0.022), color)
				mi.scale.x = 1.5
		"pencil":
			var body: MeshInstance3D = _cylinder(root, 0.005, 0.005, 0.17, Vector3(0, 0.007, 0), color, 6)
			body.rotation.z = PI / 2
			var tip: MeshInstance3D = _cylinder(root, 0, 0.005, 0.018, Vector3(-0.094, 0.007, 0), Color("d9c5a0"), 6)
			tip.rotation.z = PI / 2
			var lead: MeshInstance3D = _cylinder(root, 0, 0.002, 0.008, Vector3(-0.105, 0.007, 0), ink, 6)
			lead.rotation.z = PI / 2
		"candy":
			var sweet: MeshInstance3D = _cylinder(root, 0.015, 0.015, 0.045, Vector3(0, 0.02, 0), color)
			sweet.rotation.z = PI / 2
			for direction: int in [-1, 1]:
				var wrapper: MeshInstance3D = _cylinder(root, 0.008, 0.018, 0.016, Vector3(direction * 0.031, 0.02, 0), Color("e8cc9c"), 6)
				wrapper.rotation.z = direction * PI / 2
	return root


static func _box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return _mesh(parent, box, at, color)


static func _cylinder(parent: Node3D, top: float, bottom: float, height: float, at: Vector3, color: Color, sides: int = 16) -> MeshInstance3D:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = sides
	return _mesh(parent, cylinder, at, color)


static func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance


static func _top_text(parent: Node3D, text: String, at: Vector3, pixel_size: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.font_size = 32
	label.pixel_size = pixel_size
	label.modulate = Color("39342c")
	label.outline_size = 0
	label.rotation_degrees.x = -90
	label.position = at
	parent.add_child(label)
