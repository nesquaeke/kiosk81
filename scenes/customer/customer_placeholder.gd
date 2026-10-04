class_name CustomerPlaceholder
extends Node3D
## Faceless stand-in for a customer at the window (roadmap 2.8, prototype).
## Only coat colour, height and hat change. The head uses an exempt material
## (lofi_weight 0): faces are never distorted, per the readability rules.

signal arrived
signal left

const WORLD_SHADER: Shader = preload("res://assets/shaders/lofi_world.gdshader")
const WALK_SECONDS: float = 1.4
const OFFSTAGE_X: float = 2.6

@export var coat: Color = Color("#2f2c39")
@export var height_cm: int = 175
@export var hat: bool = true

var stand_x: float = 0.0
var time_scale: float = 1.0
var _body: Node3D


func _ready() -> void:
	stand_x = position.x
	rebuild()


func setup(look: Dictionary) -> void:
	coat = Color(String(look.get("coat", "#2f2c39")))
	height_cm = int(look.get("height_cm", 175))
	hat = bool(look.get("hat", true))
	rebuild()


func rebuild() -> void:
	if _body != null:
		_body.free()
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var k: float = float(height_cm) / 175.0
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.24
	capsule.height = 1.5 * k
	capsule.radial_segments = 12
	capsule.rings = 4
	capsule.material = _mat(coat, 1.0)
	_add_mesh(capsule, Vector3(0, 0.75 * k, 0), Vector3(1.15, 1.0, 0.75))
	var head: SphereMesh = SphereMesh.new()
	head.radius = 0.11
	head.height = 0.25
	head.material = _mat(Color("#796142"), 0.0)
	_add_mesh(head, Vector3(0, 1.62 * k, 0), Vector3.ONE)
	var scarf: BoxMesh = BoxMesh.new()
	scarf.size = Vector3(0.3, 0.07, 0.22)
	scarf.material = _mat(coat.darkened(0.35), 1.0)
	_add_mesh(scarf, Vector3(0, 1.47 * k, 0), Vector3.ONE)
	if hat:
		var cap: CylinderMesh = CylinderMesh.new()
		cap.top_radius = 0.11
		cap.bottom_radius = 0.12
		cap.height = 0.12
		cap.radial_segments = 10
		cap.material = _mat(Color("#1f1a20"), 1.0)
		_add_mesh(cap, Vector3(0, 1.76 * k, 0), Vector3.ONE)


## Walks in from the left and stops at the window.
func arrive() -> void:
	visible = true
	position.x = stand_x - OFFSTAGE_X
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", stand_x, WALK_SECONDS * time_scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void: arrived.emit())


## Walks off to the right.
func leave() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", stand_x + OFFSTAGE_X, WALK_SECONDS * time_scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		visible = false
		left.emit())


func _add_mesh(mesh: Mesh, pos: Vector3, scale_by: Vector3) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scale_by
	_body.add_child(mi)


func _mat(color: Color, lofi: float) -> ShaderMaterial:
	var m: ShaderMaterial = ShaderMaterial.new()
	m.shader = WORLD_SHADER
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("grime", 0.25)
	m.set_shader_parameter("lofi_weight", lofi)
	return m
