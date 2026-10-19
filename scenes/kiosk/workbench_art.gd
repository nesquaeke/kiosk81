class_name WorkbenchArt
extends RefCounted
## Close-view workstation geometry, expressed in metres. Tool origins sit on
## the contact surface; the stamp die meets paper at local y=0. Scissors cut
## towards +X, pivot at x=0, blade tips at x=0.105, finger loops behind the pivot.

const SURFACE: Shader = preload("res://assets/shaders/workbench_surface.gdshader")


static func desk_material() -> ShaderMaterial:
	return _surface(Color("4f3c2d"), 0, 0.65, 0.0, 0.55)


static func mat_material() -> ShaderMaterial:
	return _surface(Color("30483f"), 1, 0.80, 0.0, 0.35)


static func metal_material(tint: Color = Color("a9adaa"), roughness: float = 0.23) -> ShaderMaterial:
	return _surface(tint, 2, roughness, 0.80, 0.32)


static func _surface(color: Color, kind: int, roughness: float, metallic: float, wear: float) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SURFACE
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("surface_kind", kind)
	material.set_shader_parameter("base_roughness", roughness)
	material.set_shader_parameter("metalness", metallic)
	material.set_shader_parameter("wear_amount", wear)
	return material


static func bevel_box(size: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var result: MeshInstance3D = MeshInstance3D.new()
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: Vector3 = size * 0.5
	var bevel: float = minf(radius, minf(half.x, minf(half.y, half.z)) * 0.98)
	var inner: Vector3 = half - Vector3.ONE * bevel
	# Matching face grids preserve continuous rounded edges and smooth normals.
	var normals: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]
	for normal: Vector3 in normals:
		var u: Vector3 = Vector3.UP if absf(normal.x) > 0.5 else Vector3.RIGHT
		var v: Vector3 = normal.cross(u)
		var hu: float = absf(u.dot(half))
		var hv: float = absf(v.dot(half))
		var hn: float = absf(normal.dot(half))
		var us: PackedFloat32Array = _bevel_grid(hu, bevel)
		var vs: PackedFloat32Array = _bevel_grid(hv, bevel)
		for x: int in us.size() - 1:
			for y: int in vs.size() - 1:
				var corners: Array[Vector2] = [Vector2(us[x], vs[y]), Vector2(us[x + 1], vs[y]), Vector2(us[x + 1], vs[y + 1]), Vector2(us[x], vs[y + 1])]
				# Godot uses clockwise front faces.
				for corner: int in [0, 2, 1, 0, 3, 2]:
					var raw: Vector3 = normal * hn + u * corners[corner].x + v * corners[corner].y
					var nearest: Vector3 = raw.clamp(-inner, inner)
					var rounded_normal: Vector3 = (raw - nearest).normalized()
					surface.set_normal(rounded_normal)
					surface.set_uv(Vector2(corners[corner].x / (hu * 2.0) + 0.5, corners[corner].y / (hv * 2.0) + 0.5))
					surface.add_vertex(nearest + rounded_normal * bevel)
	result.mesh = surface.commit()
	result.material_override = material
	return result


static func _bevel_grid(half: float, radius: float) -> PackedFloat32Array:
	return PackedFloat32Array([-half, -half + radius * 0.2, -half + radius * 0.5,
		-half + radius, half - radius, half - radius * 0.5, half - radius * 0.2, half])


static func build_stamp(kind: String) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "CarvedStamp"
	var steel: ShaderMaterial = metal_material(Color("8c918e"), 0.29)
	var wood: ShaderMaterial = _surface(Color("483322"), 0, 0.51, 0.0, 0.37)
	wood.set_shader_parameter("grain_axis", 1)
	var rubber: ShaderMaterial = _surface(Color("25221f"), 1, 0.87, 0.0, 0.18)
	var accent: Color = {"approve": Color("3e5142"), "reject": Color("733c31"), "seize": Color("343c50")}.get(kind, Color("3e5142"))
	var rim: MeshInstance3D = bevel_box(Vector3(0.082, 0.014, 0.034), 0.0032, steel)
	rim.position.y = 0.014
	root.add_child(rim)
	var die: MeshInstance3D = bevel_box(Vector3(130, 0, 44) * (RationCard3D.WIDTH / 640.0) + Vector3(0, 0.006, 0), 0.0012, rubber)
	die.position.y = 0.003
	root.add_child(die)
	# Lathed hardwood handle: flared shoulder, pinched neck and full palm grip.
	var profile: Array[Vector2] = [Vector2(0.022, 0.018), Vector2(0.024, 0.023),
		Vector2(0.020, 0.029), Vector2(0.013, 0.034), Vector2(0.010, 0.043),
		Vector2(0.010, 0.081), Vector2(0.012, 0.093), Vector2(0.020, 0.104),
		Vector2(0.028, 0.113), Vector2(0.031, 0.124), Vector2(0.030, 0.135),
		Vector2(0.025, 0.145), Vector2(0.015, 0.152), Vector2(0.001, 0.155)]
	var handle: MeshInstance3D = _lathe(profile, wood, 48)
	root.add_child(handle)
	_cylinder(root, 0.0125, 0.009, Vector3(0, 0.043, 0), steel)
	_cylinder(root, 0.0118, 0.006, Vector3(0, 0.082, 0), _solid(accent, 0.36))
	# Slotted screws and a thin collar make the base a manufactured assembly.
	for x: float in [-0.035, 0.035]:
		_cylinder(root, 0.0031, 0.0015, Vector3(x, 0.0213, 0), steel)
		var slot: MeshInstance3D = bevel_box(Vector3(0.0042, 0.0004, 0.0007), 0.00015, _solid(Color("242623"), 0.53))
		slot.position = Vector3(x, 0.0222, 0)
		slot.rotation.y = 0.35 if x < 0 else -0.54
		root.add_child(slot)
	_combine_static_meshes(root)
	var printing_face: StampDieFace = StampDieFace.new()
	printing_face.configure(kind)
	root.add_child(printing_face)
	return root


static func build_scissors() -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "ForgedScissors"
	var steel: ShaderMaterial = metal_material(Color("bdc0b9"), 0.21)
	var bevel: ShaderMaterial = metal_material(Color("d3d5ce"), 0.16)
	var dark_steel: ShaderMaterial = metal_material(Color("646962"), 0.35)
	var inside: ShaderMaterial = metal_material(Color("8b9289"), 0.25)
	for i: int in 2:
		var blade: Node3D = Node3D.new()
		blade.name = "Blade%d" % i
		blade.rotation.y = -0.17 if i == 0 else 0.17
		root.add_child(blade)
		# Tapered blade with a real cutting bevel, rounded shoulders and point.
		var outline: PackedVector2Array = PackedVector2Array([Vector2(-0.019, -0.007), Vector2(0.012, -0.009),
			Vector2(0.083, -0.005), Vector2(0.107, -0.0005), Vector2(0.103, 0.0013),
			Vector2(0.018, 0.006), Vector2(-0.014, 0.008)])
		var blade_y: float = 0.008 + i * 0.003
		var blade_mesh: MeshInstance3D = _blade(outline, blade_y, 0.0024, steel, bevel)
		blade.add_child(blade_mesh)
		# Narrow forged shank joins the blade tang to oval finger loops.
		var shank: MeshInstance3D = bevel_box(Vector3(0.057, 0.0048, 0.009), 0.0017, dark_steel)
		shank.position = Vector3(-0.035, blade_y, 0.002 if i == 0 else -0.002)
		shank.rotation.y = -0.055 if i == 0 else 0.055
		blade.add_child(shank)
		var ring: MeshInstance3D = _oval_ring(0.026 if i == 0 else 0.031, 0.019, 0.0035, inside)
		ring.position = Vector3(-0.077 if i == 0 else -0.081, blade_y, 0)
		blade.add_child(ring)
		if i == 0:
			_cylinder(blade, 0.0061, 0.003, Vector3(0, 0.0165, 0), dark_steel)
			_cylinder(blade, 0.0045, 0.0011, Vector3(0, 0.0186, 0), steel)
			var pivot_slot: MeshInstance3D = bevel_box(Vector3(0.0062, 0.0005, 0.0009), 0.0002, _solid(Color("343932"), 0.48))
			pivot_slot.position = Vector3(0, 0.0193, 0)
			pivot_slot.rotation.y = 0.28
			blade.add_child(pivot_slot)
		_combine_static_meshes(blade)
	return root


static func build_hand(gripping: bool = false, pointing: bool = false) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "WorkHand"
	var skin: StandardMaterial3D = _solid(Color("ab8061"), 0.64)
	var knuckle: StandardMaterial3D = _solid(Color("9f735b"), 0.68)
	var nail: StandardMaterial3D = _solid(Color("bda08b"), 0.41)
	var cloth: ShaderMaterial = _surface(Color("3e4b40"), 1, 0.96, 0.0, 0.30)
	# Palm and thenar pad are separate overlapping ellipsoids. Curved finger
	# segments form a relaxed work grip instead of rigid, rectangular digits.
	_ellipsoid(root, Vector3(0.034, 0.013, 0.045), Vector3(0, 0, 0.003), skin)
	_ellipsoid(root, Vector3(0.017, 0.014, 0.029), Vector3(-0.023, -0.001, 0.012), skin)
	_segment(root, Vector3(0, -0.003, 0.032), Vector3(0, -0.008, 0.083), 0.024, 0.029, skin)
	for i: int in 4:
		var x: float = -0.024 + i * 0.016
		var length: float = [0.061, 0.071, 0.067, 0.052][i]
		var radius: float = [0.0073, 0.0077, 0.0072, 0.0063][i]
		var spread: float = [-0.003, -0.001, 0.001, 0.004][i]
		var a: Vector3 = Vector3(x, 0.001, -0.030)
		var b: Vector3 = a + Vector3(spread * 0.4, -0.002, -length * 0.43)
		var c: Vector3 = b + Vector3(spread * 0.35, -0.010, -length * 0.34)
		var d: Vector3 = c + Vector3(spread * 0.25, -0.011, -length * 0.23)
		if gripping or (pointing and i > 0):
			# Proximal fingers bend down around the handle; the distal pads turn
			# back towards the palm instead of leaving four open straight digits.
			b = a + Vector3(spread * 0.4, -length * 0.20, -length * 0.30)
			c = b + Vector3(spread * 0.35, -length * 0.39, length * 0.035)
			d = c + Vector3(spread * 0.25, -length * 0.18, length * 0.24)
			if pointing:
				b.y += 0.015
				c.y += 0.015
				d.y += 0.015
		_segment(root, a, b, radius, radius * 0.92, skin)
		_segment(root, b, c, radius * 0.92, radius * 0.83, skin)
		_segment(root, c, d, radius * 0.83, radius * 0.65, skin)
		_ellipsoid(root, Vector3(radius * 1.03, radius * 0.64, radius * 0.88), b + Vector3(0, 0.002, 0), knuckle)
		_ellipsoid(root, Vector3(radius * 0.80, radius * 0.85, radius * 0.80), c, skin)
		_ellipsoid(root, Vector3(radius * 0.62, radius * 0.65, radius * 0.68), d, skin)
		var nail_mesh: MeshInstance3D = _ellipsoid(root, Vector3(radius * 0.69, 0.0011, length * 0.080), c.lerp(d, 0.61) + Vector3(0, radius * 0.64, 0.001), nail)
		nail_mesh.rotation.x = -1.85 if gripping or (pointing and i > 0) else -0.45
	# Thumb bends across the side of a handle, with a fleshy base at the palm.
	var thumb_a: Vector3 = Vector3(-0.029, -0.003, 0.009)
	var thumb_b: Vector3 = Vector3(-0.045, -0.007, -0.012)
	var thumb_c: Vector3 = Vector3(-0.047, -0.015, -0.036)
	if gripping or pointing:
		thumb_b = Vector3(-0.037, -0.016, -0.013)
		thumb_c = Vector3(-0.011, -0.030, -0.029)
	_segment(root, thumb_a, thumb_b, 0.010, 0.009, skin)
	_segment(root, thumb_b, thumb_c, 0.009, 0.0073, skin)
	_ellipsoid(root, Vector3(0.009, 0.008, 0.009), thumb_b, skin)
	_ellipsoid(root, Vector3(0.0072, 0.0070, 0.0080), thumb_c, skin)
	var thumbnail: MeshInstance3D = _ellipsoid(root, Vector3(0.0063, 0.0012, 0.0078), thumb_c + Vector3(0, 0.0055, 0.002), nail)
	thumbnail.rotation.x = -0.85 if gripping else -0.22
	# A rolled cuff covers the forearm; no rigid five-box hand silhouette.
	_segment(root, Vector3(0, -0.011, 0.077), Vector3(0, -0.034, 0.28), 0.034, 0.044, cloth)
	var cuff: MeshInstance3D = _oval_ring(0.032, 0.024, 0.005, cloth)
	cuff.position = Vector3(0, -0.009, 0.080)
	cuff.rotation.x = PI / 2.0
	root.add_child(cuff)
	_combine_static_meshes(root)
	return root


static func _combine_static_meshes(parent: Node3D) -> void:
	# Keep interactive pivots as nodes, but batch their static detail by material.
	# A close-view hand has four draw calls rather than a draw call per knuckle.
	var batches: Dictionary[Material, SurfaceTool] = {}
	var originals: Array[MeshInstance3D] = []
	for child: Node in parent.get_children():
		if child is not MeshInstance3D: continue
		var instance: MeshInstance3D = child as MeshInstance3D
		originals.append(instance)
		for index: int in instance.mesh.get_surface_count():
			var material: Material = instance.get_active_material(index)
			if not batches.has(material):
				var surface: SurfaceTool = SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				batches[material] = surface
			batches[material].append_from(instance.mesh, index, instance.transform)
	for material: Material in batches:
		var combined: MeshInstance3D = MeshInstance3D.new()
		combined.mesh = batches[material].commit()
		combined.material_override = material
		parent.add_child(combined)
	for instance: MeshInstance3D in originals:
		parent.remove_child(instance)
		instance.free()


static func _ellipsoid(parent: Node3D, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = sphere
	result.scale = size
	result.position = position
	result.material_override = material
	parent.add_child(result)
	return result


static func _segment(parent: Node3D, from: Vector3, to: Vector3, start_radius: float, end_radius: float, material: Material) -> MeshInstance3D:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.bottom_radius = start_radius
	cylinder.top_radius = end_radius
	cylinder.height = from.distance_to(to)
	cylinder.radial_segments = 24
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = cylinder
	result.material_override = material
	result.position = (from + to) * 0.5
	result.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	parent.add_child(result)
	return result


static func _blade(outline: PackedVector2Array, y: float, thickness: float, steel: Material, edge: Material) -> MeshInstance3D:
	var mesh: ArrayMesh = ArrayMesh.new()
	var top: SurfaceTool = SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var inset: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in outline:
		inset.append(Vector2(point.x, point.y * 0.63))
	var triangulated: PackedInt32Array = Geometry2D.triangulate_polygon(inset)
	for i: int in range(0, triangulated.size(), 3):
		for index: int in [triangulated[i], triangulated[i + 1], triangulated[i + 2]]:
			var p: Vector2 = inset[index]
			top.set_normal(Vector3.UP)
			top.set_uv(p * 20.0)
			top.add_vertex(Vector3(p.x, y + thickness * 0.5, p.y))
		for index: int in [triangulated[i], triangulated[i + 2], triangulated[i + 1]]:
			var p: Vector2 = inset[index]
			top.set_normal(Vector3.DOWN)
			top.set_uv(p * 20.0)
			top.add_vertex(Vector3(p.x, y - thickness * 0.5, p.y))
	top.commit(mesh)
	mesh.surface_set_material(0, steel)
	var sides: SurfaceTool = SurfaceTool.new()
	sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in outline.size():
		var next: int = (i + 1) % outline.size()
		var outside_a: Vector3 = Vector3(outline[i].x, y, outline[i].y)
		var outside_b: Vector3 = Vector3(outline[next].x, y, outline[next].y)
		for sign_y: float in [-1.0, 1.0]:
			var inside_a: Vector3 = Vector3(inset[i].x, y + thickness * 0.5 * sign_y, inset[i].y)
			var inside_b: Vector3 = Vector3(inset[next].x, y + thickness * 0.5 * sign_y, inset[next].y)
			var triangles: Array[Vector3] = [inside_a, outside_b, outside_a, inside_a, inside_b, outside_b]
			if sign_y < 0: triangles.reverse()
			for j: int in range(0, triangles.size(), 3):
				var n: Vector3 = (triangles[j + 1] - triangles[j]).cross(triangles[j + 2] - triangles[j]).normalized()
				for k: int in [0, 2, 1]:
					sides.set_normal(n)
					sides.set_uv(Vector2(triangles[j + k].x, triangles[j + k].z) * 20.0)
					sides.add_vertex(triangles[j + k])
	sides.commit(mesh)
	mesh.surface_set_material(1, edge)
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = mesh
	return result


static func _lathe(profile: Array[Vector2], material: Material, segments: int = 48) -> MeshInstance3D:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row: int in profile.size() - 1:
		for segment: int in segments:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var r: int = row + corner.y
				var angle: float = TAU * (segment + corner.x) / segments
				var previous: Vector2 = profile[maxi(r - 1, 0)]
				var next: Vector2 = profile[mini(r + 1, profile.size() - 1)]
				var tangent: Vector2 = (next - previous).normalized()
				var outward: Vector3 = Vector3(cos(angle) * tangent.y, -tangent.x, sin(angle) * tangent.y).normalized()
				surface.set_normal(outward)
				surface.set_uv(Vector2(float(segment + corner.x) / segments, profile[r].y / 0.16))
				surface.add_vertex(Vector3(cos(angle) * profile[r].x, profile[r].y, sin(angle) * profile[r].x))
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = surface.commit()
	result.material_override = material
	return result


static func _oval_ring(radius_x: float, radius_z: float, tube: float, material: Material) -> MeshInstance3D:
	var surface: SurfaceTool = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var loops: int = 56
	var sides: int = 10
	for segment: int in loops:
		for side: int in sides:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var angle: float = TAU * (segment + corner.x) / loops
				var around: float = TAU * (side + corner.y) / sides
				var normal: Vector3 = Vector3(cos(angle) * cos(around), sin(around), sin(angle) * cos(around))
				surface.set_normal(normal)
				surface.set_uv(Vector2(float(segment + corner.x) / loops, float(side + corner.y) / sides))
				surface.add_vertex(Vector3(cos(angle) * radius_x, 0, sin(angle) * radius_z) + normal * tube)
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = surface.commit()
	result.material_override = material
	return result


static func _solid(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


static func _cylinder(parent: Node3D, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 48
	mesh.rings = 1
	var result: MeshInstance3D = MeshInstance3D.new()
	result.mesh = mesh
	result.material_override = material
	result.position = position
	parent.add_child(result)
	return result
