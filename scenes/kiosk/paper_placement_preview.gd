class_name PaperPlacementPreview
extends Node3D
## A desk-space footprint of the actual placement; never a floating HUD card.

func _ready() -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.94, 0.87, 0.65, 0.62)
	material.no_depth_test = false
	var half: Vector2 = Vector2(RationCard3D.WIDTH, RationCard3D.HEIGHT) * 0.5
	for side: int in 4:
		var line: MeshInstance3D = MeshInstance3D.new()
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = Vector3(RationCard3D.WIDTH if side < 2 else 0.0018, 0.0008, 0.0018 if side < 2 else RationCard3D.HEIGHT)
		line.mesh = mesh
		line.position = Vector3(0, 0, half.y * (-1 if side == 0 else 1)) if side < 2 else Vector3(half.x * (-1 if side == 2 else 1), 0, 0)
		line.material_override = material
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(line)
	visible = false
