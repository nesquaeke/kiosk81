class_name StampPlacementGuide
extends Node3D
## Transient work aid on the real sheet. It never enters the document's ink
## viewport, mark history, forgery evidence, detached coupons or save data.

var viewport: SubViewport
var drawing: GuideDrawing
var _last: Array = []


class GuideDrawing extends Control:
	var kind: String = "approve"
	var pixel: Vector2 = Vector2(INF, INF)
	var angle: float = 0.0
	var assist: bool = true
	var contacted: bool = false

	func _draw() -> void:
		var outline: Color = Color(0.95, 0.82, 0.48, 0.85)
		if assist:
			draw_rect(RationCardView.DECISION_RECT.grow(3), Color(0.95, 0.82, 0.48, 0.07))
			draw_rect(RationCardView.DECISION_RECT, outline, false, 1.4)
		if not pixel.is_finite() or contacted: return
		draw_set_transform(pixel, angle)
		# Same die dimensions, lettering and angle as the eventual impression.
		var ghost: Color = Color(0.20, 0.24, 0.22, 0.48)
		draw_rect(Rect2(-65, -22, 130, 44), ghost, false, 1.2)
		draw_rect(Rect2(-61.8, -18.8, 123.6, 37.6), Color(ghost, 0.28), false, 0.65)
		var label: String = {"approve": "SPRZEDANO", "reject": "ODMOWA", "seize": "ZATRZYMANO"}.get(kind, "SPRZEDANO")
		var width: float = RationCardView.SERIF_BOLD.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(RationCardView.SERIF_BOLD, Vector2(-width / 2, 0.8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ghost)
		draw_line(Vector2(-52, 5), Vector2(52, 5), ghost, 0.7)
		var date: String = "15.II.1982  /  PZ-81"
		width = RationCardView.TYPEWRITER.get_string_size(date, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		draw_string(RationCardView.TYPEWRITER, Vector2(-width / 2, 15), date, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, ghost)
		draw_set_transform(Vector2.ZERO)
		# Show spill beyond the paper with a neutral outline, never a green/red
		# authenticity answer. Position is otherwise entirely player-controlled.
		var footprint: PackedVector2Array = PackedVector2Array()
		for corner: Vector2 in [Vector2(-65, -22), Vector2(65, -22), Vector2(65, 22), Vector2(-65, 22), Vector2(-65, -22)]:
			footprint.append(pixel + corner.rotated(angle))
		draw_polyline(footprint, outline, 0.8, true)


func _ready() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1280, 800)
	viewport.disable_3d = true
	viewport.transparent_bg = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	drawing = GuideDrawing.new()
	drawing.scale = Vector2.ONE * 2.0
	drawing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(drawing)
	var surface: MeshInstance3D = MeshInstance3D.new()
	var mesh: QuadMesh = QuadMesh.new()
	# A wider transparent margin lets the projected die visibly overhang paper.
	mesh.size = Vector2(RationCard3D.WIDTH, RationCard3D.HEIGHT) * 1.32
	surface.mesh = mesh
	surface.position.z = 0.00065
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.cull_mode = BaseMaterial3D.CULL_BACK
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)
	# The viewport has a 32% outer margin as well; paper pixels retain scale.
	drawing.scale = Vector2.ONE * (2.0 / 1.32)
	drawing.position = Vector2(1280, 800) * (0.16 / 1.32)
	visible = false


func show_guide(kind: String, pixel: Vector2, angle: float, assist: bool, contacted: bool) -> void:
	visible = true
	var values: Array = [kind, pixel.round(), snappedf(angle, 0.001), assist, contacted]
	if values == _last: return
	_last = values
	drawing.kind = kind
	drawing.pixel = pixel.round()
	drawing.angle = angle
	drawing.assist = assist
	drawing.contacted = contacted
	drawing.queue_redraw()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
