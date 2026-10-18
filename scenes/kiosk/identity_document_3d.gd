class_name IdentityDocument3D
extends Interactable
## A companion world document, held and inspected through the same FPS hand.
## Printing consumes supplied identity data only; it does not evaluate a card.

const WIDTH: float = 0.224
const HEIGHT: float = 0.14
const THICKNESS: float = 0.0012
var identity: Dictionary = {}
var _views: Array[SubViewport] = []
var _prints: Array[IdentityPrint] = []


func _ready() -> void:
	name = "CustomerIdentityDocument"
	action = "identity"
	collision_layer = 0
	collision_mask = 0
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(WIDTH, HEIGHT, 0.006)
	collision.shape = shape
	add_child(collision)
	var edge: MeshInstance3D = MeshInstance3D.new()
	var stock: BoxMesh = BoxMesh.new()
	stock.size = Vector3(WIDTH, HEIGHT, THICKNESS)
	edge.mesh = stock
	var paper: StandardMaterial3D = StandardMaterial3D.new()
	paper.albedo_color = Color("a8a080")
	paper.roughness = 1
	edge.material_override = paper
	add_child(edge)
	for back: bool in [false, true]:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = Vector2i(1920, 1200)
		viewport.disable_3d = true
		viewport.gui_disable_input = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(viewport)
		var printing: IdentityPrint = IdentityPrint.new()
		printing.scale = Vector2.ONE * 3
		printing.reverse = back
		printing.data = identity
		printing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		viewport.add_child(printing)
		_views.append(viewport)
		_prints.append(printing)
		var face: MeshInstance3D = MeshInstance3D.new()
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(WIDTH, HEIGHT)
		face.mesh = quad
		face.position.z = (-1 if back else 1) * (THICKNESS * 0.5 + 0.00002)
		face.rotation.y = PI if back else 0
		var ink: StandardMaterial3D = StandardMaterial3D.new()
		ink.albedo_texture = viewport.get_texture()
		ink.roughness = 0.96
		ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		face.material_override = ink
		add_child(face)


func configure(data: Dictionary) -> void:
	identity = data.duplicate(true)
	for index: int in _prints.size():
		_prints[index].data = identity
		_prints[index].queue_redraw()
		_views[index].render_target_update_mode = SubViewport.UPDATE_ONCE


class IdentityPrint extends Control:
	const SERIF: Font = preload("res://assets/fonts/LiberationSerif-Regular.ttf")
	const BOLD: Font = preload("res://assets/fonts/LiberationSerif-Bold.ttf")
	const MONO: Font = preload("res://assets/fonts/LiberationMono-Regular.ttf")
	const ITALIC: Font = preload("res://assets/fonts/LiberationSerif-Italic.ttf")
	const INK: Color = Color("383e36")
	var data: Dictionary = {}
	var reverse: bool = false


	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 400), Color("d5d6b9"))
		for index: int in 620:
			var at: Vector2 = Vector2(5 + (index * 149) % 628, 3 + (index * 103) % 391)
			draw_line(at, at + Vector2(2.5, 0.3), Color(0.25, 0.32, 0.22, 0.045), 0.45)
		for inset: int in [12, 17]:
			draw_rect(Rect2(inset, inset, 640 - inset * 2, 400 - inset * 2), Color("778166"), false, 0.8)
		for strand: int in 5:
			var wave: PackedVector2Array = []
			for step: int in 121:
				wave.append(Vector2(24 + step * 4.9, 191 + sin(step * 0.18 + strand * 0.55) * 88))
			draw_polyline(wave, Color(0.2, 0.4, 0.3, 0.07), 0.5, true)
		if reverse:
			_center(53, "DOWÓD OSOBISTY", 23, BOLD)
			_center(80, "POLSKA RZECZPOSPOLITA LUDOWA", 12, SERIF)
			_line(98)
			_text(Vector2(39, 133), "ORGAN WYDAJĄCY", 11, SERIF)
			_text(Vector2(39, 162), "URZĄD DZIELNICOWY WARSZAWA–WOLA", 16, BOLD)
			_text(Vector2(39, 204), "MIEJSCE WYDANIA   WARSZAWA", 13, MONO)
			_text(Vector2(39, 232), "SERIA I NUMER    " + str(data.get("number", "")), 16, MONO)
			_text(Vector2(39, 282), "Okazać łącznie z kartą zaopatrzenia.", 17, ITALIC)
			_text(Vector2(39, 306), "Przy zwrocie sprawdzić komplet dokumentów.", 14, SERIF)
			_line(329)
			_center(355, "Kimlik • İsim, numara ve fotoğrafı karneyle karşılaştır.", 13, SERIF)
		else:
			_center(43, "POLSKA RZECZPOSPOLITA LUDOWA", 14, BOLD)
			_center(75, "DOWÓD OSOBISTY", 27, BOLD)
			_line(92)
			DocumentPortrait.draw(self, Rect2(36, 115, 132, 163), int(data.get("portrait_variant", 0)))
			_text(Vector2(195, 128), "NAZWISKO I IMIĘ / AD SOYAD", 10, SERIF)
			_text(Vector2(195, 165), str(data.get("holder", "")), 23, BOLD)
			_text(Vector2(195, 200), "SERIA I NUMER / KİMLİK NO", 10, SERIF)
			_text(Vector2(195, 233), str(data.get("number", "")), 23, MONO)
			_text(Vector2(195, 272), "WARSZAWA–WOLA   •   1981", 12, MONO)
			for offset: float in [0, 3.2]:
				draw_arc(Vector2(164, 269), 31 + offset, 0, TAU, 72, Color(0.34, 0.25, 0.4, 0.48), 0.9, true)
			_text(Vector2(142, 273), "UD 81", 10, BOLD)
			_text(Vector2(38, 319), "Podpis posiadacza", 11, SERIF)
			_text(Vector2(184, 323), str(data.get("holder", "")), 20, ITALIC)
			_line(340)
			_center(363, "DOKUMENT TOŻSAMOŚCI  /  KİMLİK BELGESİ", 11, MONO)


	func _text(at: Vector2, value: String, size: int, font: Font) -> void:
		draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)


	func _center(y: float, value: String, size: int, font: Font) -> void:
		_text(Vector2((640 - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x) / 2, y), value, size, font)


	func _line(y: float) -> void:
		draw_line(Vector2(30, y), Vector2(610, y), Color("879174"), 0.7)
