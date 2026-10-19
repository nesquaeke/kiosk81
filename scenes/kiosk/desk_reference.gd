class_name RationDeskReference
extends Node3D
## A small cloth-backed desk reference, printed on real world-space paper.
## Its examples describe the game's issuing rules; they never inspect a card
## or reveal whether the current customer is honest.

const FOOTPRINT: Vector2 = Vector2(0.244, 0.229)
const PAGE_SIZE: Vector2 = Vector2(0.231, 0.216)
const FRONT_LEAF_POSITION: Vector3 = Vector3(0.003, 0.0085, 0)
const BACK_LEAF_POSITION: Vector3 = Vector3(0.003, -0.0002, 0)
const BACK_LEAF_ROTATION: Vector3 = Vector3(0, 0, PI)
const CLOTH_SHADER: Shader = preload("res://assets/shaders/workbench_surface.gdshader")
@export var valid_month: String = RationDeskRules.MONTH
var page_viewport: SubViewport
var evidence_viewport: SubViewport
var evidence_page: int = 0
var _evidence_leaf: EvidenceLeaf


## Changes only a printed reference page. These fixed examples never read the
## current encounter, its hidden expected decision, or campaign state.
func next_evidence_page() -> int:
	evidence_page = (evidence_page + 1) % 2
	if is_instance_valid(_evidence_leaf):
		_evidence_leaf.page = evidence_page
		_evidence_leaf.queue_redraw()
	if is_instance_valid(evidence_viewport):
		evidence_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return evidence_page


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
	page_viewport = _build_leaf(ReferenceLeaf.new(), "ClassAndIssuer", FRONT_LEAF_POSITION)
	_evidence_leaf = EvidenceLeaf.new()
	_evidence_leaf.page = evidence_page
	evidence_viewport = _build_leaf(_evidence_leaf, "PaperEvidence", BACK_LEAF_POSITION, true)


func _build_leaf(printing: ReferenceLeaf, title: String, at: Vector3, reverse: bool = false) -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.name = "Printed" + title + "Leaf"
	viewport.size = Vector2i(1536, 1440)
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	printing.month = valid_month
	printing.scale = Vector2.ONE * 2.4
	printing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(printing)
	var leaf: MeshInstance3D = MeshInstance3D.new()
	leaf.name = "World" + title + "Leaf"
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = PAGE_SIZE
	leaf.mesh = mesh
	leaf.position = at
	# The existing inspector flips in camera space: Ry(PI) * Rx(PI/2).
	# A local Z half-turn makes this underside face outward with its print
	# upright after that flip. An X half-turn would mirror the printed page.
	if reverse: leaf.rotation = BACK_LEAF_ROTATION
	var ink: StandardMaterial3D = _solid(Color.WHITE)
	ink.albedo_texture = viewport.get_texture()
	ink.roughness = 0.94
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaf.material_override = ink
	add_child(leaf)
	return viewport


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
		_text(Vector2(28, 495), "Przed odłączeniem porównać normę i pieczęć instytucji.", 12, SERIF)
		_text(Vector2(28, 523), "Zużycie papieru nie unieważnia karty. Nie niszczyć pól ewidencyjnych.", 10, ITALIC, FADED)
		_text(Vector2(28, 548), "Karşılaştır: sınıf • et hakkı • arka yüz kurum kodu ve mühür.", 10, SERIF, FADED)
		_text(Vector2(28, 560), "İKİ REHBER SAYFASI ARKADA · F incele / sağ tık çevir / Tab sayfa", 8, MONO, FADED)
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


class EvidenceLeaf extends ReferenceLeaf:
	## Fixed reference examples, never a renderer of the current customer's
	## document. Ordinary wear and stock differences do not establish guilt.
	const DIAGRAM_INK: Color = Color("71654d")
	const PALE_INK: Color = Color("b1a381")
	var page: int = 0

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 640, 600), Color("e3d9bc"))
		for index: int in 220:
			var point: Vector2 = Vector2(8 + (index * 181) % 625, 5 + (index * 109) % 590)
			draw_line(point, point + Vector2(1.6, 0.21), Color(0.35, 0.28, 0.14, 0.045), 0.4)
		_text(Vector2(28, 27), "PZ–81 / PRÓBKI PORÓWNAWCZE", 9, MONO, FADED)
		if page == 1:
			_draw_document_guide()
			return
		_text(Vector2(28, 56), "PAPIER I NADRUK", 28, BOLD)
		_text(Vector2(28, 75), "Kâğıdı çevir, ışığa tut ve örnekle karşılaştır.", 13, SERIF, FADED)
		_rule(88, 0.7)
		_page_tabs()
		_watermark_example()
		_text(Vector2(221, 118), "01  IŞIKTAN GEÇEN DESEN", 16, BOLD)
		_lines(Vector2(221, 142), [
			"F ile yakından incele; T ile ışığa tut.",
			"Ortadaki rozet ve dalı iki yüzden karşılaştır.",
			"Kâğıt düz bakarken daha çok ışık geçirir.",
			"Ek bir katman deseni örtebilir: kota alanını",
			"eğerek kenarını da incele. Kalınlık farkı",
			"tek başına kartı geçersiz yapmaz."
		])
		_rule(251, 0.4)
		_patch_example()
		_text(Vector2(221, 281), "02  KOTA ALANININ KENARI", 16, BOLD)
		_lines(Vector2(221, 305), [
			"Yandan bak: yüzey basamak yapıyor mu?",
			"İnce bir tutkal çizgisi veya kesilmiş lif var mı?",
			"Baskı çizgileri ek parçanın altında kesiliyor mu?",
			"Büyüteçle sınırı, arka yüzde aynı yeri incele.",
			"Miktarı ön yüzdeki sınıf tablosuyla karşılaştır."
		])
		_rule(400, 0.4)
		_wear_example()
		_text(Vector2(221, 430), "03  KULLANIM İZLERİ", 16, BOLD)
		_lines(Vector2(221, 454), [
			"Kat izi, dağınık leke ve aşınmış kenar olağandır.",
			"İnce veya kalın kâğıt her sınıfta bulunabilir.",
			"Yıpranma tek başına ret ya da alıkoyma nedeni",
			"değildir. Tarih, kota ve kurumla birlikte incele."
		])
		_rule(542, 0.5)
		_guide_footer()


	func _page_tabs() -> void:
		# These are printed index tabs on the physical leaf, not clickable UI.
		var names: Array[String] = ["01 · KÂĞIT VE BASKI", "02 · BELGE KONTROLÜ"]
		for index: int in 2:
			var area: Rect2 = Rect2(28 + index * 190, 92, 182, 13)
			draw_rect(area, Color(DIAGRAM_INK, 0.13 if page == index else 0.035))
			draw_line(area.position + Vector2(0, 12), area.position + Vector2(area.size.x, 12), DIAGRAM_INK, 0.85 if page == index else 0.25)
			_text(area.position + Vector2(5, 10), names[index], 8, MONO, INK if page == index else FADED)


	func _guide_footer() -> void:
		_text(Vector2(28, 561), "Sabit örneklerdir; elindeki belge hakkında otomatik karar vermez.", 11, ITALIC)
		_text(Vector2(28, 583), "Kitapçıkta Tab: rehber sayfası · Sağ tık: ön / arka", 9, MONO, FADED)
		_text(Vector2(568, 583), "%02d / 02" % (page + 1), 7, MONO, FADED)


	func _draw_document_guide() -> void:
		_text(Vector2(28, 56), "DOKUMENT I ODCINKI", 28, BOLD)
		_text(Vector2(28, 75), "Tek izi suç sayma; birbiriyle çelişen bilgiyi ara.", 13, SERIF, FADED)
		_rule(88, 0.7)
		_page_tabs()
		_date_example()
		_guide_section(123, "01  AY ALANININ ALTINDAKİ BASKI", [
			"Silinmiş alanı büyüteçle ve eğerek incele.",
			"Alttaki ay, görünen aydan farklı mı?",
			"Yalnız kazınma izi değişiklik kanıtı değildir.",
			"Geçmiş tarih ile değiştirilmiş tarihi ayır."
		])
		_rule(213, 0.4)
		_portrait_example()
		_guide_section(229, "02  FOTOĞRAFI KESEN KURUM MÜHRÜ", [
			"Fotoğrafın sağ kenarındaki yarımları karşılaştır.",
			"Halka ve çizgiler kâğıt üzerinde devam etmeli.",
			"Kaymış iki yarı değiştirilmiş fotoğrafa işarettir.",
			"Tutkal ve soluk mürekkep tek başına yeterli değil."
		])
		_rule(319, 0.4)
		_coupon_example()
		_guide_section(335, "03  KUPON SERİSİ VE ESKİ TESLİM İZİ", [
			"Her kuponun serisi kartın serisiyle eşleşmeli.",
			"Farklı seri başka karttan alınmış kupona işarettir.",
			"WYDANO önceki teslim mührüdür.",
			"Kullanılmış kupon: ret; tek başına sahtecilik değil."
		])
		_rule(425, 0.4)
		_identity_example()
		_guide_section(441, "04  KİMLİKLE YAN YANA KARŞILAŞTIR", [
			"Karne ve ek kimlikte ad ile numarayı karşılaştır.",
			"İki fotoğraf aynı kişiyi göstermeli.",
			"Ad, numara veya fotoğraf çelişkisi önemlidir.",
			"Meslek, yıpranma ve tavır kimlik kanıtı değildir."
		])
		_rule(542, 0.5)
		_guide_footer()


	func _guide_section(y: float, title: String, lines: Array[String]) -> void:
		_text(Vector2(221, y), title, 15, BOLD)
		for index: int in lines.size():
			_text(Vector2(221, y + 20 + index * 17), lines[index], 13, SERIF)


	func _date_example() -> void:
		_sample(Rect2(36, 116, 160, 65))
		_text(Vector2(45, 132), "MIESIĄC", 8, SERIF, FADED)
		_text(Vector2(48, 160), "01 / 1982", 19, MONO, Color(DIAGRAM_INK, 0.32))
		for index: int in 24:
			var at: Vector2 = Vector2(50 + (index * 19) % 125, 139 + (index * 7) % 25)
			draw_line(at, at + Vector2(8, -1), Color("eee5d0"), 0.8)
		_text(Vector2(51, 163), "02 / 1982", 19, MONO, DIAGRAM_INK)
		_center(Vector2(116, 199), "Örnek: altta 01, üstte 02", 9, ITALIC, FADED)


	func _portrait_example() -> void:
		_sample(Rect2(36, 222, 160, 65))
		for index: int in 2:
			var origin: Vector2 = Vector2(45 + index * 80, 229)
			var photo: Rect2 = Rect2(origin, Vector2(39, 49))
			draw_rect(photo, Color("c8bea3"))
			draw_rect(photo, DIAGRAM_INK, false, 0.55)
			draw_circle(origin + Vector2(19, 16), 7, Color(DIAGRAM_INK, 0.42))
			draw_arc(origin + Vector2(19, 44), 14, PI, TAU, 24, Color(DIAGRAM_INK, 0.42), 5.5, true)
			var center: Vector2 = origin + Vector2(39, 27)
			var inside: Vector2 = center + Vector2(-5, 3) if index == 1 else center
			var seal: Color = Color("75617a")
			for radius: float in [11.0, 8.5]:
				draw_arc(inside, radius, PI * 0.5, PI * 1.5, 24, seal, 0.8, true)
				draw_arc(center, radius, -PI * 0.5, PI * 0.5, 24, seal, 0.8, true)
		_center(Vector2(76, 305), "Sürekli", 9, ITALIC, FADED)
		_center(Vector2(157, 305), "Kaymış", 9, ITALIC, FADED)


	func _coupon_example() -> void:
		_sample(Rect2(36, 328, 160, 65))
		_text(Vector2(43, 342), "KARTA  W–82–0417", 9, MONO, DIAGRAM_INK)
		var coupon: Rect2 = Rect2(44, 349, 143, 36)
		draw_rect(coupon, Color("e5d9b9"))
		draw_rect(coupon, DIAGRAM_INK, false, 0.65)
		_text(Vector2(49, 363), "ODCINEK  W–82–0963", 9, MONO, DIAGRAM_INK)
		for index: int in 17:
			var x: float = 46 + index * 8
			draw_line(Vector2(x, 348), Vector2(x + 2, 352 + index % 2), Color(DIAGRAM_INK, 0.7), 0.6, true)
		_text(Vector2(103, 381), "WYDANO 09.02", 9, BOLD, Color("80657c"))
		_center(Vector2(116, 411), "İki ayrı kontrol: seri / teslim izi", 9, ITALIC, FADED)


	func _identity_example() -> void:
		_sample(Rect2(36, 434, 160, 79))
		for index: int in 2:
			var origin: Vector2 = Vector2(43, 441 + index * 35)
			_text(origin + Vector2(0, 8), "KARNE" if index == 0 else "KİMLİK", 7, MONO, FADED)
			_text(origin + Vector2(37, 8), "ANNA KOWALSKA", 9, MONO)
			_text(origin + Vector2(37, 22), "AB 241703" if index == 0 else "AB 241708", 10, MONO)
			# A plain portrait placeholder marks the companion photograph field;
			# the comparison is about the person, never class or paper colour.
			draw_rect(Rect2(origin + Vector2(4, 12), Vector2(22, 17)), Color(DIAGRAM_INK, 0.13))
			draw_circle(origin + Vector2(15, 17), 3, Color(DIAGRAM_INK, 0.5))
			draw_arc(origin + Vector2(15, 28), 6, PI, TAU, 16, Color(DIAGRAM_INK, 0.5), 2.8, true)
		_center(Vector2(116, 532), "Örnek: ad aynı, numara farklı", 9, ITALIC, FADED)


	func _lines(at: Vector2, lines: Array[String]) -> void:
		for index: int in lines.size():
			_text(at + Vector2(0, index * 18), lines[index], 12, SERIF)


	func _sample(rect: Rect2) -> void:
		draw_rect(rect, Color("d7cdaf"))
		draw_rect(rect, PALE_INK, false, 0.75)
		for row: int in 5:
			if 13 + row * 15 > rect.size.y - 8: break
			draw_line(rect.position + Vector2(8, 13 + row * 15), rect.position + Vector2(rect.size.x - 8, 13 + row * 15), Color(DIAGRAM_INK, 0.16), 0.5)


	func _watermark_example() -> void:
		_sample(Rect2(36, 112, 160, 96))
		var center: Vector2 = Vector2(116, 158)
		_rosette(center, 31, Color(DIAGRAM_INK, 0.43), 0.65)
		draw_arc(center, 27, 0, TAU, 64, Color(DIAGRAM_INK, 0.26), 0.7, true)
		draw_line(center + Vector2(0, 18), center + Vector2(0, -17), Color(DIAGRAM_INK, 0.5), 1.0, true)
		for row: int in 3:
			var stem: Vector2 = center + Vector2(0, 9 - row * 10)
			draw_line(stem, stem + Vector2(-8, -6), Color(DIAGRAM_INK, 0.5), 1, true)
			draw_line(stem + Vector2(0, -2), stem + Vector2(10, -9), Color(DIAGRAM_INK, 0.5), 1, true)
		_center(Vector2(116, 228), "Şematik ışık görünümü", 10, ITALIC, FADED)


	func _patch_example() -> void:
		_sample(Rect2(36, 275, 160, 68))
		var patch: Rect2 = Rect2(80, 294, 94, 25)
		draw_rect(patch.grow(1.8), Color(DIAGRAM_INK, 0.22))
		draw_rect(patch, Color("e7ddc2"))
		draw_rect(patch, DIAGRAM_INK, false, 0.6)
		_text(Vector2(87, 312), "750 g", 16, MONO)
		# Cross section deliberately exaggerates the tiny raised lip so the
		# paper/glue boundary has an understandable reference at desk scale.
		draw_line(Vector2(38, 363), Vector2(194, 363), DIAGRAM_INK, 2.4)
		draw_line(Vector2(82, 360), Vector2(172, 360), PALE_INK, 1.1)
		draw_polyline(PackedVector2Array([Vector2(82, 357), Vector2(166, 357), Vector2(174, 354)]), DIAGRAM_INK, 1.5, true)
		_center(Vector2(116, 385), "Katman kenarı · büyütülmüş kesit", 9, ITALIC, FADED)


	func _wear_example() -> void:
		_sample(Rect2(36, 425, 160, 86))
		for ring: int in 5:
			draw_circle(Vector2(169, 490), 9 + ring * 3, Color(DIAGRAM_INK, 0.018))
		draw_line(Vector2(115, 426), Vector2(115, 510), Color(DIAGRAM_INK, 0.3), 1.3)
		draw_line(Vector2(116.5, 426), Vector2(116.5, 510), Color("eee5d0"), 0.8)
		for index: int in 9:
			var x: float = 40 + index * 17
			draw_line(Vector2(x, 508), Vector2(x + 3, 503 + index % 3), Color("b8a886"), 0.8, true)
		_center(Vector2(116, 529), "Kat izi ve yayılmış leke", 10, ITALIC, FADED)
