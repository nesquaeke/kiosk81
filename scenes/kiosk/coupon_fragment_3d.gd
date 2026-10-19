class_name CouponFragment3D
extends Interactable
## One detached piece of the original sheet. Its ink/damage meshes are supplied
## once by RationCard3D; moving or archiving the piece never edits entitlements.

var source_rect: Rect2
var world_size: Vector2 = Vector2(0.10125, 0.050625)
var dimensions: Vector3 = Vector3(0.10125, 0.050625, 0.00028)
var source_card_id: String = ""
var source_serial: String = ""
var archived: bool = false
var held: bool = false
var _collision: CollisionShape3D


func configure(rect: Rect2, size: Vector2, thickness: float, document: Dictionary, product: String) -> void:
	source_rect = rect
	world_size = size
	dimensions = Vector3(size.x, size.y, thickness)
	source_serial = str(document.get("serial", ""))
	source_card_id = str(document.get("id", source_serial))
	item_id = product
	set_meta("card_id", source_card_id)
	set_meta("serial", source_serial)
	set_meta("item", item_id)
	set_meta("paper_thickness", thickness)
	_update_collision()


func _ready() -> void:
	action = "coupon"
	collision_layer = 0 if held else 2
	collision_mask = 0
	_collision = CollisionShape3D.new()
	_collision.name = "CouponSelectionShape"
	add_child(_collision)
	_update_collision()


func _update_collision() -> void:
	if _collision == null: return
	var shape: BoxShape3D = BoxShape3D.new()
	# The visible sheet keeps its true stock thickness. A small, symmetric
	# selection depth lets either face be picked without enlarging its outline.
	shape.size = Vector3(world_size.x, world_size.y, maxf(dimensions.z, 0.003))
	_collision.shape = shape


func set_held(value: bool) -> void:
	held = value
	collision_layer = 0 if held else 2
	# A small coupon stays flat. Reusing the full sheet's bend independently
	# on cropped faces and a canonical rim would separate their cut edges.


func set_archived(value: bool) -> void:
	archived = value
	set_meta("archived", value)


static func table_orientation(front: bool = true) -> Quaternion:
	return Quaternion(Vector3.RIGHT, -PI / 2) * Quaternion(Vector3.UP, 0.0 if front else PI)
