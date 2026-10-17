class_name RationDeskReference
extends Node3D
## A small cloth-backed desk reference, printed on real world-space paper.
## Its examples describe the game's issuing rules; they never inspect a card
## or reveal whether the current customer is honest.

const FOOTPRINT: Vector2 = Vector2(0.244, 0.229)
const PAGE_SIZE: Vector2 = Vector2(0.231, 0.216)
const CLOTH_SHADER: Shader = preload("res://assets/shaders/workbench_surface.gdshader")
@export var valid_month: String = RationDeskRules.MONTH
var page_viewport: SubViewport


func _ready() -> void:
	name = "ClassAndIssuerReference"
	var cloth: ShaderMaterial = ShaderMaterial.new()
	cloth.shader = CLOTH_SHADER
	cloth.set_shader_parameter("base_color", Color("39473b"))
	cloth.set_shader_parameter("surface_kind", 1)
	cloth.set_shader_parameter("base_roughness", 0.88)
	cloth.set_shader_parameter("metalness", 0.0)
	cloth.set_shader_parameter("wear_amount", 0.35)
	_box(Vector3(FOOTPRINT.x, 0.0045, FOOTPRINT.y), Vector3(0, 0.00225, 0), cloth)
	_box(Vector3(0.009, 0.009, FOOTPRINT.y), Vector3(-0.1175, 0.0045, 0), cloth)
	# Separate signatures give the closed edges thickness without a slab-like
	# white backing. The actual printed leaf is the top plane, not a screen.
	for index: int in 5:
		var paper: StandardMaterial3D = _solid(Color("c8bda0").lightened(float(index % 3) * 0.035))
		_box(Vector3(PAGE_SIZE.x - 0.001, 0.00065, PAGE_SIZE.y - 0.001), Vector3(0.003, 0.0048 + index * 0.00067, 0), paper)
	var bookmark: StandardMaterial3D = _solid(Color("7a4335"))
	_box(Vector3(0.009, 0.00065, 0.030), Vector3(-0.077, 0.0049, 0.113), bookmark)
	_build_print()
	# A faint raised seam where the page leaves the binding catches close light.
	var thread: StandardMaterial3D = _solid(Color("9c936f"))
	for index: int in 8:
		_box(Vector3(0.0005, 0.0004, 0.0032), Vector3(-0.1126, 0.0082, -0.086 + index * 0.024), thread)


func _build_print() -> void:
	page_viewport = SubViewport.new()
	page_viewport.name = "PrintedReferenceLeaf"
	page_viewport.size = Vector2i(1536, 1440)
	page_viewport.disable_3d = true
	page_viewport.gui_disable_input = true
	page_viewport.transparent_bg = false
	page_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(page_viewport)
	var printing: ReferenceLeaf = ReferenceLeaf.new()
	printing.month = valid_month
	printing.scale = Vector2.ONE * 2.4
	printing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_viewport.add_child(printing)
	var leaf: MeshInstance3D = MeshInstance3D.new()
	leaf.name = "WorldPaperLeaf"
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = PAGE_SIZE
	leaf.mesh = mesh
	leaf.position = Vector3(0.003, 0.0085, 0)
	var ink: StandardMaterial3D = _solid(Color.WHITE)
	ink.albedo_texture = page_viewport.get_texture()
	ink.roughness = 0.94
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaf.material_override = ink
	add_child(leaf)


func _box(dimensions: Vector3, at: Vector3, material: Material) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	add_child(instance)


func _solid(tint: Color) -> StandardMaterial3D:
	var result: StandardMaterial3D = StandardMaterial3D.new()
	result.albedo_color = tint
	result.roughness = 0.9
	return result


class ReferenceLeaf extends Control:
	const SERIF: Font = preload("res://assets/fonts/LiberationSerif-Regular.ttf")
	const BOLD: Font = preload("res://assets/fonts/LiberationSerif-Bold.ttf")
	const ITALIC: Font = preload("res://assets/fonts/LiberationSerif-Italic.ttf")
	const MONO: Font = preload("res://assets/fonts/LiberationMono-Regular.ttf")
	const INK: Color = Color("34372c")
	const FADED: Color = Color("4f503f")
	var month: String = "1982-02"


	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 600), Color("e3d9bc"))
		# Fixed fibres and subtle ink stock variations remain still while viewed.
		for index: int in 250:
			var point: Vector2 = Vector2(8 + (index * 181) % 625, 5 + (index * 109) % 590)
			draw_line(point, point + Vector2(1.6, 0.21), Color(0.35, 0.28, 0.14, 0.045), 0.4)
		_rosette(Vector2(48, 46), 25, Color("68745b"), 0.26)
		_center(Vector2(48, 47), "PZ", 16, BOLD)
		_center(Vector2(48, 59), "81", 9, SERIF, FADED)
		_text(Vector2(91, 25), "WARSZAWSKA SPÓŁDZIELNIA ZAOPATRZENIA", 9, SERIF, FADED)
		_text(Vector2(89, 54), "WZORY KART", 29, BOLD)
		_text(Vector2(91, 72), "Podręczna instrukcja dla punktu sprzedaży nr 81", 11, ITALIC, FADED)
		_center(Vector2(544, 43), _month_label(), 12, MONO)
		_center(Vector2(544, 59), "WYDANIE 02 / PZ–81", 7, SERIF, FADED)
		_rule(85, 0.75)
		_rule(87.5, 0.3)
		_text(Vector2(28, 107), "KATEGORIA UPRAWNIONEGO", 8, SERIF, FADED)
		_text(Vector2(267, 107), "MIĘSO / MIESIĄC", 8, SERIF, FADED)
		_text(Vector2(408, 107), "INSTYTUCJA", 8, SERIF, FADED)
		_text(Vector2(524, 107), "WZÓR PIECZĘCI", 7, SERIF, FADED)
		var categories: Array[String] = ["worker", "teacher", "retired"]
		var names: Array[String] = ["ROBOTNIK", "NAUCZYCIEL", "EMERYT"]
		var descriptions: Array[String] = ["Zakład pracy • grupa produkcyjna", "Placówka oświatowa", "Rejestr emerytalny"]
		var translations: Array[String] = ["İŞÇİ", "ÖĞRETMEN", "EMEKLİ"]
		for index: int in 3:
			var spec: Dictionary = RationDeskRules.CLASSES[categories[index]]
			var tint: Color = spec["color"]
			var y: float = 125 + index * 88
			_text(Vector2(28, y + 25), names[index], 19, BOLD, tint.darkened(0.36))
			_text(Vector2(29, y + 44), descriptions[index], 10, ITALIC, FADED)
			_text(Vector2(29, y + 61), translations[index], 8, SERIF, FADED)
			_text(Vector2(269, y + 29), "%d g" % int(spec["meat"]), 23, MONO)
			_text(Vector2(269, y + 48), "norma miesięczna", 8, ITALIC, FADED)
			_text(Vector2(411, y + 29), str(spec["institution"]), 23, MONO)
			_text(Vector2(411, y + 48), "kod na odwrocie", 8, ITALIC, FADED)
			_seal(Vector2(558, y + 30), str(spec["institution"]), tint)
			_rule(y + 75, 0.4)
		_text(Vector2(28, 416), "DLA KAŻDEJ KATEGORII", 9, BOLD, FADED)
		_text(Vector2(213, 417), "CUKIER  1000 g    •    MYDŁO  1 szt.", 17, SERIF)
		_rule(432, 0.5)
		_text(Vector2(28, 453), "Kontrola: nazwisko, miesiąc, kategoria i pieczęć na odwrocie.", 12, SERIF)
		_text(Vector2(28, 474), "Odłączyć wyłącznie odcinek wydawanego towaru.", 12, SERIF)
		_text(Vector2(28, 495), "Przed odłączeniem sprawdzić dostępność towaru.", 12, SERIF)
		_text(Vector2(28, 523), "Zużycie papieru nie unieważnia karty. Nie niszczyć pól ewidencyjnych.", 10, ITALIC, FADED)
		_text(Vector2(28, 548), "Karşılaştır: sınıf • et hakkı • arka yüz kurum kodu ve mühür.", 10, SERIF, FADED)
		_rule(565, 0.4)
		_text(Vector2(28, 582), "PZ–81 / INSTRUKCJA WEWNĘTRZNA       EGZEMPLARZ SŁUŻBOWY", 7, MONO, FADED)
		_text(Vector2(574, 582), "02 / 82", 7, MONO, FADED)


	func _seal(at: Vector2, code: String, tint: Color) -> void:
		var ink: Color = Color("67546e")
		_rosette(at, 33, Color(tint.darkened(0.16), 0.16), 0.6)
		for segment: int in 36:
			if segment not in [6, 23]:
				var angle: float = float(segment) / 36.0 * TAU
				draw_arc(at, 29, angle, angle + 0.15, 4, Color(ink, 0.65 + (segment % 3) * 0.055), 1.15, true)
		draw_arc(at, 26, 0, TAU, 64, Color(ink, 0.6), 0.55, true)
		_center(at + Vector2(0, -10), "WARSZAWA · WOLA", 5, SERIF, Color(ink, 0.77))
		_center(at + Vector2(0, 6), code, 17, BOLD, Color(ink, 0.85))
		_center(at + Vector2(0, 18), "ZATWIERDZONO", 5, SERIF, Color(ink, 0.74))


	func _rosette(at: Vector2, radius: float, tint: Color, weight: float) -> void:
		for strand: int in 3:
			var points: PackedVector2Array = PackedVector2Array()
			for step: int in 193:
				var angle: float = float(step) / 192 * TAU
				var r: float = radius * (0.78 + 0.16 * sin(angle * 13 + strand * 0.7))
				points.append(at + Vector2(cos(angle), sin(angle)) * r)
			draw_polyline(points, tint, weight, true)


	func _rule(y: float, weight: float) -> void:
		draw_line(Vector2(28, y), Vector2(612, y), Color("9b9278"), weight)


	func _text(at: Vector2, value: String, font_size: int, face: Font, color: Color = INK) -> void:
		draw_string(face, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


	func _center(at: Vector2, value: String, font_size: int, face: Font, color: Color = INK) -> void:
		var width: float = face.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		_text(at - Vector2(width * 0.5, 0), value, font_size, face, color)


	func _month_label() -> String:
		var parts: PackedStringArray = month.split("-")
		if parts.size() != 2:
			return month
		var names: Array[String] = ["STYCZEŃ", "LUTY", "MARZEC", "KWIECIEŃ", "MAJ", "CZERWIEC", "LIPIEC", "SIERPIEŃ", "WRZESIEŃ", "PAŹDZIERNIK", "LISTOPAD", "GRUDZIEŃ"]
		var index: int = parts[1].to_int() - 1
		return "%s %s" % [names[index], parts[0]] if index >= 0 and index < names.size() else month
