class_name KioskFPSPlayer
extends CharacterBody3D
## A walking character; the camera never switches to a document screen.

var head: Node3D
var camera: Camera3D
var can_move: bool = true
var look_locked: bool = false
var sensitivity: float = 0.002
const WALK_SPEED: float = 2.6
const RUN_SPEED: float = 4.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = 0.24
	shape.height = 1.76
	collision.shape = shape
	collision.position.y = 0.88
	add_child(collision)
	head = Node3D.new()
	head.position.y = 1.62
	add_child(head)
	camera = Camera3D.new()
	camera.fov = 72
	camera.near = 0.035
	camera.current = true
	head.add_child(camera)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var input: Vector2 = Vector2.ZERO
	if can_move:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = global_basis * Vector3(input.x, 0, input.y)
	var speed: float = RUN_SPEED if Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 16)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 16)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not look_locked:
		var mouse: InputEventMouseMotion = event as InputEventMouseMotion
		rotation.y -= mouse.relative.x * sensitivity
		head.rotation.x = clampf(head.rotation.x - mouse.relative.y * sensitivity, -1.35, 1.35)
