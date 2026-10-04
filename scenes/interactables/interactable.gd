class_name Interactable
extends StaticBody3D
## Something in the kiosk the player can point at and click (roadmap 2.3, prototype).
## Pointing lights it up softly; there is no on-screen text (Yol Plani, interaction rules).
## The scene that owns the kiosk decides what `action` means.

const HIGHLIGHT_COLOR: Color = Color(1.0, 0.85, 0.55, 0.22)

## For example "restock" or "document".
@export var action: String = ""
## Item the action is about (restock cartons).
@export var item_id: String = ""
## Meshes that light up while pointed at.
@export var highlight_meshes: Array[NodePath] = []

static var _overlay: StandardMaterial3D


func set_hovered(on: bool) -> void:
	if _overlay == null:
		_overlay = StandardMaterial3D.new()
		_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_overlay.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_overlay.albedo_color = HIGHLIGHT_COLOR
	for path: NodePath in highlight_meshes:
		var mesh: MeshInstance3D = get_node_or_null(path) as MeshInstance3D
		if mesh != null:
			mesh.material_overlay = _overlay if on else null


## A small shake: the diegetic "nothing here" (an empty carton).
func nudge() -> void:
	var start: Vector3 = position
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", start + Vector3(0.012, 0, 0), 0.05)
	tween.tween_property(self, "position", start - Vector3(0.012, 0, 0), 0.08)
	tween.tween_property(self, "position", start, 0.05)
