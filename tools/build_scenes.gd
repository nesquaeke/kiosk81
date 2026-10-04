extends Node
## Builds the grey-box scenes from code (roadmap 1.6b, 2.1):
##   scenes/kiosk/kiosk_world.tscn      the kiosk, the street, lights and snow (shared)
##   scenes/sketch/visual_sketch.tscn   the look-only visual sketch
##   scenes/kiosk/prototype.tscn        the playable prototype day
## Real dimensions from the roadmap (Yol Plani, gri kutu olculeri), colours from the
## visual target palette (Gorsel Hedef, section 3). Edit this file, not the .tscn files.
## Run: godot --headless --path . res://tools/build_scenes.tscn
## (a scene, not --script, because the scene scripts use autoloads).
## Coordinates: metres; the kiosk floor centre is the origin; the window looks toward -Z.

const WORLD_PATH: String = "res://scenes/kiosk/kiosk_world.tscn"
const SKETCH_PATH: String = "res://scenes/sketch/visual_sketch.tscn"
const PROTOTYPE_PATH: String = "res://scenes/kiosk/prototype.tscn"
const WORLD_SHADER: Shader = preload("res://assets/shaders/lofi_world.gdshader")
const BLOCK_SHADER: Shader = preload("res://assets/shaders/panel_block.gdshader")
const INTERACTABLE_LAYER: int = 2  # physics layer 2 "Interactable"
const CUSTOMER_SPOT: Vector3 = Vector3(-0.1, 0, -1.3)

# Kiosk interior (Yol Plani): 1.6 w x 1.4 d x 2.1 h; window 1.0 x 0.7, sill at 1.05;
# counter 0.95 high, 45 cm deep; seated eye height 1.25; vertical FOV 65.
const W: float = 1.6
const D: float = 1.4
const H: float = 2.1
const WALL: float = 0.06
const WIN_W: float = 1.0
const WIN_H: float = 0.7
const WIN_SILL: float = 1.05
const COUNTER_H: float = 0.95
const COUNTER_D: float = 0.45
const EYE_H: float = 1.25

var _grime: NoiseTexture2D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 1981
	_grime = _make_grime()
	var results: PackedStringArray = []
	var world: Node3D = Node3D.new()
	world.name = "World"
	_build_environment(world)
	_build_kiosk(world)
	_build_street(world)
	_build_snow(world)
	_build_seat(world)
	_set_owner_recursive(world, world)
	var ok: bool = _save(world, WORLD_PATH, results)
	world.free()
	if ok:
		ok = _compose("VisualSketch", "res://scenes/sketch/visual_sketch.gd", SKETCH_PATH, _build_sketch_ui, results)
	if ok:
		ok = _compose("Prototype", "res://scenes/kiosk/prototype.gd", PROTOTYPE_PATH, _build_prototype_ui, results)
	for line: String in results:
		print("[build] " + line)
	get_tree().quit(0 if ok else 1)


## Root script + LoFiView + SubViewport + the shared world + a customer + UI.
func _compose(root_name: String, script_path: String, out_path: String, build_ui: Callable, results: PackedStringArray) -> bool:
	var root: Node = Node.new()
	root.name = root_name
	root.set_script(load(script_path))
	var view: SubViewportContainer = SubViewportContainer.new()
	view.name = "LoFiView"
	view.set_script(load("res://scenes/fx/lofi_view.gd"))
	view.stretch = true
	root.add_child(view)
	var vp: SubViewport = SubViewport.new()
	vp.name = "SubViewport"
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.positional_shadow_atlas_size = 2048
	vp.audio_listener_enable_3d = true
	view.add_child(vp)
	var world: Node = (load(WORLD_PATH) as PackedScene).instantiate()
	world.name = "World"
	vp.add_child(world)
	var customer: Node3D = Node3D.new()
	customer.name = "Customer"
	customer.set_script(load("res://scenes/customer/customer_placeholder.gd"))
	customer.position = CUSTOMER_SPOT
	vp.add_child(customer)
	build_ui.call(root)
	# Own only what this scene created; the world keeps its own nodes (instance).
	for node: Node in [view, vp, world, customer]:
		node.owner = root
	for child: Node in root.get_children():
		if child != view:
			child.owner = root
			_set_owner_recursive(child, root)
	var ok: bool = _save(root, out_path, results)
	root.free()
	return ok


func _save(root: Node, path: String, results: PackedStringArray) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var packed: PackedScene = PackedScene.new()
	var err: Error = packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, path)
	results.append("%s: %s" % [path, error_string(err)])
	return err == OK


# ---------------------------------------------------------------- helpers

func _make_grime() -> NoiseTexture2D:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.06
	noise.fractal_octaves = 4
	noise.seed = 81
	var tex: NoiseTexture2D = NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.noise = noise
	return tex


func _mat(color: String, opts: Dictionary = {}) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = WORLD_SHADER
	m.set_shader_parameter("albedo", Color(color))
	m.set_shader_parameter("grime_texture", _grime)
	m.set_shader_parameter("grime", opts.get("grime", 0.4))
	m.set_shader_parameter("grime_density", opts.get("density", 0.4))
	m.set_shader_parameter("roughness", opts.get("rough", 0.85))
	m.set_shader_parameter("metallic", opts.get("metal", 0.0))
	m.set_shader_parameter("lofi_weight", opts.get("lofi", 1.0))
	if opts.has("lines"):
		m.set_shader_parameter("line_width", opts["lines"])
		m.set_shader_parameter("line_scale", opts.get("line_scale", Vector2.ONE))
		m.set_shader_parameter("line_color", Color(String(opts.get("line_color", "#1a1412"))))
	if opts.has("emit"):
		m.set_shader_parameter("emission_color", Color(String(opts["emit"])))
		m.set_shader_parameter("emission_energy", opts.get("energy", 1.0))
	return m


func _box(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material,
		rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	# Small triangles keep affine wobble subtle on big, close surfaces.
	mesh.subdivide_width = clampi(int(size.x / 0.35), 0, 12)
	mesh.subdivide_height = clampi(int(size.y / 0.35), 0, 12)
	mesh.subdivide_depth = clampi(int(size.z / 0.35), 0, 12)
	mesh.material = mat
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _plane(parent: Node, node_name: String, size: Vector2, pos: Vector3, mat: Material,
		rot_deg: Vector3 = Vector3.ZERO, subdiv: int = 8) -> MeshInstance3D:
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = subdiv
	mesh.subdivide_depth = subdiv
	mesh.material = mat
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


func _cyl(parent: Node, node_name: String, radius: float, height: float, pos: Vector3,
		mat: Material, top_radius: float = -1.0) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	mesh.material = mat
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	return mi


func _group(parent: Node, node_name: String, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var n: Node3D = Node3D.new()
	n.name = node_name
	n.position = pos
	parent.add_child(n)
	return n


## Places a light at `from` (parent space) shining toward `to`. look_at() needs
## the node in a tree, which a builder script does not have.
func _aim(node: Node3D, from: Vector3, to: Vector3) -> void:
	node.transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), from)


## A box the player can click: StaticBody3D (layer Interactable) + mesh + collision.
func _interactable_box(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: Material,
		action: String, item_id: String) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.set_script(load("res://scenes/interactables/interactable.gd"))
	body.position = pos
	body.collision_layer = INTERACTABLE_LAYER
	body.collision_mask = 0
	body.set("action", action)
	body.set("item_id", item_id)
	parent.add_child(body)
	var mesh: MeshInstance3D = _box(body, "Mesh", size, Vector3.ZERO, mat)
	mesh.name = "Mesh"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size + Vector3(0.01, 0.01, 0.01)
	var col: CollisionShape3D = CollisionShape3D.new()
	col.name = "Shape"
	col.shape = shape
	body.add_child(col)
	var paths: Array[NodePath] = [NodePath("Mesh")]
	body.set("highlight_meshes", paths)
	return body


## Anchors on the lowest shelves; the prototype fills them with one box per unit on the shelf.
func _build_displays(k: Node3D, hw: float) -> void:
	var displays: Node3D = _group(k, "Displays")
	var y: float = 1.15 + 0.01
	var x: float = hw - 0.13
	# item, position, unit size, step between units, max units, colour
	var specs: Array[Array] = [
		["itm_trybuna_ludu", Vector3(-x, y, -0.06), Vector3(0.2, 0.012, 0.22), Vector3(0, 0.012, 0), 12, "#c9c3b5"],
		["itm_zolnierz_wolnosci", Vector3(-x, y, 0.2), Vector3(0.2, 0.012, 0.22), Vector3(0, 0.012, 0), 12, "#b8ad96"],
		["itm_cigarettes_popularne", Vector3(x, y, -0.17), Vector3(0.055, 0.085, 0.022), Vector3(0, 0, 0.026), 8, "#7a2e24"],
		["itm_matches", Vector3(x, y, 0.16), Vector3(0.05, 0.015, 0.035), Vector3(0, 0.015, 0), 10, "#3a4a33"],
	]
	for spec: Array in specs:
		var anchor: Node3D = _group(displays, "Display_" + str(spec[0]), spec[1])
		anchor.add_to_group("stock_display", true)
		anchor.set_meta("item_id", spec[0])
		anchor.set_meta("unit_size", spec[2])
		anchor.set_meta("unit_step", spec[3])
		anchor.set_meta("max_units", spec[4])
		anchor.set_meta("color", Color(String(spec[5])))


func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)


# ---------------------------------------------------------------- environment

func _build_environment(world: Node3D) -> void:
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#161218")       # dis gece golgesi
	sky_mat.sky_horizon_color = Color("#4a4250")   # city glow in the fog
	sky_mat.ground_bottom_color = Color("#161218")
	sky_mat.ground_horizon_color = Color("#4a4250")
	sky_mat.sun_angle_max = 0.0
	sky_mat.energy_multiplier = 1.0
	var sky: Sky = Sky.new()
	sky.sky_material = sky_mat

	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#2f2c39")     # dis gece orta tonu
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("#3e3a43")
	env.fog_density = 1.0
	env.fog_depth_begin = 2.0
	env.fog_depth_end = 260.0
	env.fog_depth_curve = 0.6
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.82               # low saturation (section 6)
	env.adjustment_contrast = 1.05

	var we: WorldEnvironment = WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	world.add_child(we)


# ---------------------------------------------------------------- kiosk

func _build_kiosk(world: Node3D) -> void:
	var k: Node3D = _group(world, "Kiosk")
	var wall_mat: ShaderMaterial = _mat("#7c6350", {"grime": 0.55})         # sepya ic mekan
	var wainscot_mat: ShaderMaterial = _mat("#533b2d", {"grime": 0.5})
	var wood_mat: ShaderMaterial = _mat("#463321", {"grime": 0.45})          # ic kahve
	var dark_wood: ShaderMaterial = _mat("#2c1f15", {"grime": 0.4})
	var frame_mat: ShaderMaterial = _mat("#2a2622", {"grime": 0.3, "rough": 0.6, "metal": 0.3})
	var ceiling_mat: ShaderMaterial = _mat("#6f6556", {"grime": 0.5})
	var floor_mat: ShaderMaterial = _mat("#4a3a2e", {"grime": 0.5, "line_scale": Vector2(2.5, 2.5),
			"lines": 0.04, "line_color": "#2a201a"})                          # 40 cm linoleum tiles

	var hw: float = W * 0.5
	var hd: float = D * 0.5
	# Floor and ceiling.
	_plane(k, "Floor", Vector2(W, D), Vector3(0, 0, 0), floor_mat)
	_box(k, "Ceiling", Vector3(W + 2 * WALL, WALL, D + 2 * WALL), Vector3(0, H + WALL * 0.5, 0), ceiling_mat)

	# Front wall with the window opening (z = -hd, looking out toward -Z).
	var fz: float = -hd - WALL * 0.5
	var front: Node3D = _group(k, "FrontWall")
	_box(front, "Below", Vector3(W + 2 * WALL, WIN_SILL, WALL), Vector3(0, WIN_SILL * 0.5, fz), wainscot_mat)
	var top_h: float = H - (WIN_SILL + WIN_H)
	_box(front, "Above", Vector3(W + 2 * WALL, top_h, WALL), Vector3(0, H - top_h * 0.5, fz), wall_mat)
	var side_w: float = (W - WIN_W) * 0.5 + WALL
	var side_x: float = WIN_W * 0.5 + side_w * 0.5
	for s: float in [-1.0, 1.0]:
		_box(front, "Side%s" % ("L" if s < 0 else "R"), Vector3(side_w, WIN_H, WALL),
				Vector3(s * side_x, WIN_SILL + WIN_H * 0.5, fz), wall_mat)
	# Window frame, mullion and the sliding service hatch (30 x 20 cm).
	var win: Node3D = _group(k, "Window")
	var fw: float = 0.04
	var wz: float = -hd - WALL * 0.5
	_box(win, "FrameTop", Vector3(WIN_W, fw, WALL + 0.02), Vector3(0, WIN_SILL + WIN_H - fw * 0.5, wz), frame_mat)
	_box(win, "FrameBottom", Vector3(WIN_W, fw, WALL + 0.06), Vector3(0, WIN_SILL + fw * 0.5, wz + 0.01), frame_mat)
	for s: float in [-1.0, 1.0]:
		_box(win, "FrameSide%s" % ("L" if s < 0 else "R"), Vector3(fw, WIN_H, WALL + 0.02),
				Vector3(s * (WIN_W * 0.5 - fw * 0.5), WIN_SILL + WIN_H * 0.5, wz), frame_mat)
	_box(win, "HatchTop", Vector3(0.34, 0.02, 0.03), Vector3(0, WIN_SILL + 0.21, wz), frame_mat)
	for s: float in [-1.0, 1.0]:
		_box(win, "HatchSide%s" % ("L" if s < 0 else "R"), Vector3(0.02, 0.2, 0.03),
				Vector3(s * 0.16, WIN_SILL + 0.11, wz), frame_mat)
	var glass_mat: StandardMaterial3D = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.62, 0.68, 0.68, 0.10)
	glass_mat.roughness = 0.15
	glass_mat.metallic_specular = 0.8
	# Glass around the open hatch: left, right and above it.
	var inner_h: float = WIN_H - 2 * fw
	var pane_w: float = WIN_W * 0.5 - fw - 0.17
	for s: float in [-1.0, 1.0]:
		_box(win, "Glass%s" % ("L" if s < 0 else "R"), Vector3(pane_w, inner_h, 0.006),
				Vector3(s * (0.17 + pane_w * 0.5), WIN_SILL + fw + inner_h * 0.5, wz), glass_mat)
	var top_pane_h: float = WIN_SILL + WIN_H - fw - (WIN_SILL + 0.22)
	_box(win, "GlassTop", Vector3(0.34, top_pane_h, 0.006),
			Vector3(0, WIN_SILL + 0.22 + top_pane_h * 0.5, wz), glass_mat)

	# Side and back walls.
	for s: float in [-1.0, 1.0]:
		_box(k, "Wall%s" % ("L" if s < 0 else "R"), Vector3(WALL, H, D + 2 * WALL),
				Vector3(s * (hw + WALL * 0.5), H * 0.5, 0), wall_mat)
	_box(k, "WallBack", Vector3(W + 2 * WALL, H, WALL), Vector3(0, H * 0.5, hd + WALL * 0.5), wall_mat)
	_box(k, "Door", Vector3(0.7, 1.9, 0.03), Vector3(0.35, 0.95, hd - 0.015), dark_wood)
	_box(k, "DoorHandle", Vector3(0.1, 0.025, 0.04), Vector3(0.08, 1.0, hd - 0.04), frame_mat)
	_box(k, "Calendar", Vector3(0.3, 0.42, 0.005), Vector3(-0.45, 1.45, hd - 0.005),
			_mat("#b8ad96", {"grime": 0.6}))

	# Counter along the front wall.
	var counter: Node3D = _group(k, "Counter")
	_box(counter, "Top", Vector3(W, 0.04, COUNTER_D), Vector3(0, COUNTER_H - 0.02, -hd + COUNTER_D * 0.5), wood_mat)
	# Only a front lip: the vendor's knees go under the counter, cartons sit below.
	_box(counter, "Apron", Vector3(W, 0.08, 0.02), Vector3(0, COUNTER_H - 0.08, -hd + COUNTER_D - 0.01), dark_wood)
	_box(counter, "Ledger", Vector3(0.22, 0.025, 0.31), Vector3(0.02, COUNTER_H + 0.012, -0.44),
			_mat("#3b2619", {"grime": 0.3}), Vector3(0, -6, 0))
	_box(counter, "LedgerPage", Vector3(0.2, 0.004, 0.29), Vector3(0.02, COUNTER_H + 0.027, -0.44),
			_mat("#a89f8a", {"grime": 0.2, "line_scale": Vector2(0, 40), "lines": 0.08, "line_color": "#7a7062"}), Vector3(0, -6, 0))
	_box(counter, "MoneyTray", Vector3(0.24, 0.02, 0.16), Vector3(0.0, COUNTER_H + 0.01, -0.63),
			_mat("#5a5a58", {"grime": 0.3, "rough": 0.5, "metal": 0.5}))
	var stamp: Node3D = _group(counter, "Stamp", Vector3(0.32, COUNTER_H, -0.4))
	_cyl(stamp, "Base", 0.03, 0.03, Vector3(0, 0.015, 0), _mat("#2a2622", {"grime": 0.2}))
	_cyl(stamp, "Handle", 0.015, 0.07, Vector3(0, 0.065, 0), _mat("#3b2619", {"grime": 0.3}), 0.02)
	_box(counter, "InkPad", Vector3(0.09, 0.015, 0.06), Vector3(0.45, COUNTER_H + 0.008, -0.42),
			_mat("#2c3a55", {"grime": 0.3}))

	# Desk lamp: the one light the player controls (2700 K tungsten).
	var lamp: Node3D = _group(k, "DeskLamp", Vector3(-0.52, COUNTER_H, -0.5))
	var lamp_mat: ShaderMaterial = _mat("#2e3b30", {"grime": 0.3, "rough": 0.5, "metal": 0.4})
	_cyl(lamp, "Base", 0.07, 0.02, Vector3(0, 0.01, 0), lamp_mat)
	_box(lamp, "Arm", Vector3(0.015, 0.38, 0.015), Vector3(0.04, 0.2, 0.02), lamp_mat, Vector3(0, 0, -12))
	var shade: MeshInstance3D = _cyl(lamp, "Shade", 0.08, 0.1, Vector3(0.1, 0.38, 0.02), lamp_mat, 0.03)
	shade.rotation_degrees = Vector3(0, 0, 35)
	var bulb_mat: ShaderMaterial = _mat("#ffd9a0", {"grime": 0.0, "emit": "#ffc880", "energy": 3.0})
	var bulb: MeshInstance3D = _cyl(lamp, "Bulb", 0.025, 0.03, Vector3(0.12, 0.345, 0.02), bulb_mat)
	bulb.name = "Bulb"
	var spot: SpotLight3D = SpotLight3D.new()
	spot.name = "Light"
	spot.light_color = Color(1.0, 0.71, 0.42)
	spot.light_energy = 1.4
	spot.spot_range = 1.8
	spot.spot_angle = 50.0
	spot.shadow_enabled = true
	_aim(spot, Vector3(0.12, 0.33, 0.02), Vector3(0.5, -0.25, 0.08))
	lamp.add_child(spot)

	# Ceiling fluorescent (cold white-green, ~4000 K, GECICI).
	var tube_mat: ShaderMaterial = _mat("#d4dad8", {"grime": 0.0, "emit": "#d4dad8", "energy": 2.2})
	_box(k, "FluorescentTube", Vector3(1.0, 0.035, 0.035), Vector3(0, H - 0.05, 0.1), tube_mat)
	_box(k, "FluorescentHousing", Vector3(1.1, 0.03, 0.09), Vector3(0, H - 0.02, 0.1), frame_mat)
	var fluo: OmniLight3D = OmniLight3D.new()
	fluo.name = "FluorescentLight"
	fluo.light_color = Color("#d4dad8")
	fluo.light_energy = 0.9
	fluo.omni_range = 3.2
	fluo.shadow_enabled = false  # a long tube gives soft light; hard point shadows look wrong
	fluo.position = Vector3(0, H - 0.12, 0.1)
	k.add_child(fluo)

	# Warm spill out of the window onto the snow (#a49471 from outside).
	var spill: SpotLight3D = SpotLight3D.new()
	spill.name = "WindowSpill"
	spill.light_color = Color("#e0b878")
	spill.light_energy = 0.9
	spill.spot_range = 9.0
	spill.spot_angle = 45.0
	spill.shadow_enabled = true
	_aim(spill, Vector3(0, 2.0, -0.35), Vector3(0, 0, -4.5))
	k.add_child(spill)

	_build_shelves(k, hw, hd)

	# Ruch cartons under the counter: click one to refill that item's shelf (prototype).
	var cartons: Node3D = _group(k, "Cartons")
	var carton_specs: Array[Array] = [
		["itm_trybuna_ludu", -0.6, "#8a8070"], ["itm_zolnierz_wolnosci", -0.33, "#7a7060"],
		["itm_cigarettes_popularne", 0.33, "#6e3a2a"], ["itm_matches", 0.6, "#4a5a3a"],
	]
	for spec: Array in carton_specs:
		_interactable_box(cartons, "Restock_" + str(spec[0]), Vector3(0.24, 0.26, 0.3),
				Vector3(spec[1], 0.13, -0.5), _mat(spec[2], {"grime": 0.6}), "restock", spec[0])
	# The customer's document lies on the money tray (shown only when there is one).
	var doc: StaticBody3D = _interactable_box(k, "TrayDocument", Vector3(0.1, 0.004, 0.07),
			Vector3(0.02, COUNTER_H + 0.024, -0.63), _mat("#cfc4a8", {"grime": 0.2, "lofi": 0.0}), "document", "")
	doc.rotation_degrees.y = 8.0
	_build_displays(k, hw)
	var heater: Node3D = _group(k, "Heater", Vector3(0.6, 0, 0.5))
	_box(heater, "Body", Vector3(0.3, 0.45, 0.14), Vector3(0, 0.25, 0), _mat("#3a3632", {"grime": 0.5, "metal": 0.3}))
	_box(heater, "Grille", Vector3(0.24, 0.2, 0.01), Vector3(0, 0.27, -0.075),
			_mat("#ff5a1a", {"grime": 0.2, "emit": "#ff5a1a", "energy": 1.4}))


func _build_shelves(k: Node3D, hw: float, hd: float) -> void:
	var shelf_mat: ShaderMaterial = _mat("#3b2619", {"grime": 0.45})
	var item_colors: PackedStringArray = ["#6e2a22", "#2c3a55", "#c9c3b5", "#3a4a33", "#7c6350", "#a59a82"]
	var paper_mat: ShaderMaterial = _mat("#b8ad96", {"grime": 0.55})
	var shelves: Node3D = _group(k, "Shelves")
	var z0: float = -hd + COUNTER_D + 0.05
	var z1: float = hd - 0.05
	var length: float = z1 - z0
	for s: float in [-1.0, 1.0]:
		var side: String = "L" if s < 0 else "R"
		for row: int in 3:
			var y: float = 1.15 + row * 0.3
			var x: float = s * (hw - 0.13)
			_box(shelves, "Shelf%s%d" % [side, row], Vector3(0.26, 0.02, length), Vector3(x, y, (z0 + z1) * 0.5), shelf_mat)
			# Row 0 near the window holds the stock displays (prototype); filler starts after them.
			var z: float = (0.34 if row == 0 else z0 + 0.04)
			var i: int = 0
			while z < z1 - 0.08:
				var is_paper: bool = row == 1 and s < 0
				var w: float = _rng.randf_range(0.06, 0.12) if not is_paper else 0.2
				var h: float = _rng.randf_range(0.05, 0.22) if not is_paper else _rng.randf_range(0.03, 0.09)
				var dpt: float = _rng.randf_range(0.12, 0.2)
				var mat: ShaderMaterial = paper_mat if is_paper else _mat(item_colors[_rng.randi() % item_colors.size()], {"grime": 0.5})
				_box(shelves, "Item%s%d_%d" % [side, row, i], Vector3(dpt, h, w),
						Vector3(x + s * 0.02, y + 0.01 + h * 0.5, z + w * 0.5), mat, Vector3(0, _rng.randf_range(-4.0, 4.0), 0))
				z += w + _rng.randf_range(0.005, 0.03)
				i += 1


# ---------------------------------------------------------------- street

func _build_street(world: Node3D) -> void:
	var st: Node3D = _group(world, "Street")
	var snow: ShaderMaterial = _mat("#b9b8c0", {"grime": 0.3, "density": 0.15, "rough": 0.9})
	_plane(st, "SnowGround", Vector2(160, 160), Vector3(0, -0.01, -60), snow, Vector3.ZERO, 32)
	# The avenue runs from the kiosk toward the Palace of Culture, slightly right.
	var start: Vector3 = Vector3(3, 0, -8)
	var target: Vector3 = Vector3(120, 0, -750)
	var dir: Vector3 = (target - start).normalized()
	var yaw: float = rad_to_deg(atan2(-dir.x, -dir.z))
	var road_len: float = start.distance_to(target) + 20.0
	var road_mid: Vector3 = start + dir * road_len * 0.5
	_plane(st, "Road", Vector2(14, road_len), Vector3(road_mid.x, 0.0, road_mid.z),
			_mat("#2e2b33", {"grime": 0.5, "density": 0.1}), Vector3(0, yaw, 0), 40)
	# Snow banks along the kerbs.
	var bank: ShaderMaterial = _mat("#c4c3cb", {"grime": 0.35})
	var right: Vector3 = Vector3(-dir.z, 0, dir.x)
	for i: int in 10:
		for s: float in [-1.0, 1.0]:
			var p: Vector3 = start + dir * (6.0 + i * 9.0 + _rng.randf_range(-2.0, 2.0)) + right * s * 7.6
			var pile: MeshInstance3D = MeshInstance3D.new()
			var sm: SphereMesh = SphereMesh.new()
			sm.radial_segments = 10
			sm.rings = 5
			sm.material = bank
			pile.mesh = sm
			pile.name = "Bank%d%s" % [i, "L" if s < 0 else "R"]
			pile.position = p + Vector3(0, -0.1, 0)
			pile.scale = Vector3(_rng.randf_range(1.6, 3.0), _rng.randf_range(0.5, 0.9), _rng.randf_range(2.5, 5.0))
			pile.rotation_degrees.y = yaw
			st.add_child(pile)
	# Street lamps: colour still to be checked against period photos [TARIH ?], GECICI.
	var pole_mat: ShaderMaterial = _mat("#2a2830", {"grime": 0.3, "metal": 0.4})
	var head_mat: ShaderMaterial = _mat("#f0c890", {"grime": 0.0, "emit": "#f0c088", "energy": 4.0})
	for i: int in 8:
		var s: float = -1.0 if i % 2 == 0 else 1.0
		var p: Vector3 = start + dir * (10.0 + i * 26.0) + right * s * 8.4
		var lamp: Node3D = _group(st, "StreetLamp%d" % i, p)
		lamp.rotation_degrees.y = yaw
		_box(lamp, "Pole", Vector3(0.16, 7.5, 0.16), Vector3(0, 3.75, 0), pole_mat)
		_box(lamp, "Arm", Vector3(1.4, 0.1, 0.1), Vector3(-s * 0.7, 7.4, 0), pole_mat)
		_box(lamp, "Head", Vector3(0.5, 0.12, 0.26), Vector3(-s * 1.3, 7.3, 0), head_mat)
		if i < 4:
			var light: OmniLight3D = OmniLight3D.new()
			light.name = "Light"
			light.light_color = Color(0.95, 0.76, 0.52)
			light.light_energy = 4.0
			light.omni_range = 20.0
			light.omni_attenuation = 1.2
			light.position = Vector3(-s * 1.3, 7.0, 0)
			lamp.add_child(light)
	# Prefab panel blocks (wielka plyta).
	_panel_block(st, "BlockA", Vector3(-30, 0, -36), Vector3(64, 33.6, 12), 35.0, 1.0)
	_panel_block(st, "BlockB", Vector3(70, 0, -118), Vector3(64, 33.6, 12), -23.0, 2.0)
	_panel_block(st, "BlockC", Vector3(-44, 0, -210), Vector3(90, 28.0, 12), 11.0, 3.0)
	_panel_block(st, "BlockD", Vector3(110, 0, -300), Vector3(70, 39.2, 12), -15.0, 4.0)
	_build_palace(st)


func _panel_block(parent: Node, node_name: String, base: Vector3, size: Vector3, yaw: float, block_seed: float) -> void:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = BLOCK_SHADER
	m.set_shader_parameter("seed", block_seed)
	m.set_shader_parameter("wall_color", Color("#6d6a73"))
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.subdivide_width = 16
	mesh.subdivide_height = 8
	mesh.subdivide_depth = 2
	mesh.material = m
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = base + Vector3(0, size.y * 0.5, 0)
	mi.rotation_degrees.y = yaw
	parent.add_child(mi)


func _build_palace(parent: Node) -> void:
	# A plain stepped silhouette at the end of the avenue; it reads only as a shape in the fog.
	var p: Node3D = _group(parent, "PalaceSilhouette", Vector3(120, 0, -750))
	var m: ShaderMaterial = _mat("#231e26", {"grime": 0.2})
	var tiers: Array[Vector3] = [
		Vector3(150, 30, 70), Vector3(90, 60, 55), Vector3(50, 120, 42), Vector3(38, 150, 34),
		Vector3(28, 172, 26), Vector3(18, 190, 18), Vector3(9, 205, 9),
	]
	for i: int in tiers.size():
		var t: Vector3 = tiers[i]
		_box(p, "Tier%d" % i, Vector3(t.x, t.y, t.z), Vector3(0, t.y * 0.5, 0), m)
	_cyl(p, "Spire", 2.5, 32.0, Vector3(0, 221, 0), m, 0.2)


# ---------------------------------------------------------------- snow and player

func _build_snow(world: Node3D) -> void:
	# Near flakes pass the window; far flakes fill the street.
	_snow_emitter(world, "SnowNear", 900, Vector3(0, 4.5, -6.5), Vector3(5, 0.3, 5), 0.045)
	_snow_emitter(world, "SnowFar", 2200, Vector3(0, 12, -32), Vector3(26, 0.5, 22), 0.07)


func _snow_emitter(world: Node3D, node_name: String, count: int, pos: Vector3, extents: Vector3, flake_size: float) -> void:
	var p: CPUParticles3D = CPUParticles3D.new()
	p.name = node_name
	p.amount = count
	p.lifetime = 12.0
	p.preprocess = 12.0
	p.position = pos
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = Vector3(0.15, -1, 0)
	p.spread = 12.0
	p.gravity = Vector3(0, -0.4, 0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(flake_size, flake_size)
	var flake: StandardMaterial3D = StandardMaterial3D.new()
	flake.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	flake.albedo_color = Color(0.82, 0.82, 0.86)
	quad.material = flake
	p.mesh = quad
	world.add_child(p)


func _build_seat(world: Node3D) -> void:
	_cyl(world, "Stool", 0.17, 0.05, Vector3(0, 0.78, 0.22), _mat("#3b2619", {"grime": 0.4}))
	_cyl(world, "StoolLeg", 0.03, 0.76, Vector3(0, 0.38, 0.22), _mat("#2a2622", {"grime": 0.3, "metal": 0.4}))
	var seat: Node3D = _group(world, "Seat", Vector3(0, EYE_H, 0.18))
	var cam: Camera3D = Camera3D.new()
	cam.name = "Camera3D"
	cam.fov = 65.0
	cam.near = 0.03
	cam.far = 1500.0
	cam.current = true
	seat.add_child(cam)


# ---------------------------------------------------------------- UI (full resolution, never distorted)

func _build_sketch_ui(root: Node) -> void:
	var ui: CanvasLayer = CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 10
	root.add_child(ui)
	var hint: Label = Label.new()
	hint.name = "Hint"
	hint.position = Vector2(24, 18)
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color("#d4dad8"))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("shadow_offset_x", 2)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(hint)

	# Test document: proves that documents stay crisp at every retro level.
	var doc: PanelContainer = PanelContainer.new()
	doc.name = "Document"
	doc.visible = false
	doc.position = Vector2(1180, 230)
	doc.custom_minimum_size = Vector2(560, 0)
	var paper: StyleBoxFlat = StyleBoxFlat.new()
	paper.bg_color = Color("#e6dcc4")
	paper.border_color = Color("#8a7a5a")
	paper.set_border_width_all(2)
	paper.set_content_margin_all(28)
	paper.shadow_color = Color(0, 0, 0, 0.5)
	paper.shadow_size = 12
	doc.add_theme_stylebox_override("panel", paper)
	ui.add_child(doc)
	var col: VBoxContainer = VBoxContainer.new()
	col.name = "Lines"
	col.add_theme_constant_override("separation", 10)
	doc.add_child(col)
	var lines: Array[Array] = [
		["WZÓR TESTOWY · nie jest dokumentem", 15, "#8a2a20"],
		["KARTKA ZAOPATRZENIA", 30, "#1e1a16"],
		["Wyroby tytoniowe · okres: I kwartał", 20, "#1e1a16"],
		["Nazwisko i imię: ...................................", 20, "#1e1a16"],
		["Nr kartki: 000 000 (test)", 20, "#1e1a16"],
		["Okienko testu czytelności: Aa Ąą Ćć Ęę Łł Ńń Óó Śś Źź Żż 0123456789", 16, "#3a3228"],
		["(Bu bir test belgesi; tarihsel bir belge değildir.)", 15, "#5a5040"],
	]
	for line: Array in lines:
		var l: Label = Label.new()
		l.text = line[0]
		l.add_theme_font_size_override("font_size", line[1])
		l.add_theme_color_override("font_color", Color(String(line[2])))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)


func _build_prototype_ui(root: Node) -> void:
	var ui: CanvasLayer = CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 10
	root.add_child(ui)
	var hints: Label = Label.new()
	hints.name = "Hints"
	hints.position = Vector2(24, 18)
	hints.add_theme_font_size_override("font_size", 17)
	hints.add_theme_color_override("font_color", Color("#d4dad8"))
	hints.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	hints.add_theme_constant_override("shadow_offset_x", 2)
	hints.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(hints)
	var panels: Array[Array] = [
		["Decree", "res://scenes/ui/decree_note.gd"],
		["Dialogue", "res://scenes/ui/dialogue_panel.gd"],
		["Document", "res://scenes/ui/document_view.gd"],
		["Watch", "res://scenes/ui/watch_overlay.gd"],
		["DayEnd", "res://scenes/ui/day_end_panel.gd"],
	]
	for spec: Array in panels:
		var panel: PanelContainer = PanelContainer.new()
		panel.name = spec[0]
		panel.set_script(load(spec[1]))
		ui.add_child(panel)
