extends Control
## Tactile document workstation. All outcomes are evaluated after the player's decision.

var rules: RationDeskRules
var card_view: RationCardView
var foley: RationFoley
var customer_label: Label
var money_label: Label
var status: Label
var stock_label: Label
var parcel_label: Label
var next_button: Button
var official_button: Button
var hidden_button: Button
var reference: PanelContainer
var report: PanelContainer
var report_text: RichTextLabel
var tools: HBoxContainer
var sound_controls: HBoxContainer
var return_zone: Rect2
var seize_zone: Rect2
var bin_zone: Rect2
var _case_index: int = -1
var _epoch: int = 0
var _busy: bool = false
var _selftest: bool = false
var _capture_dir: String = ""
var _tokens: Array[Control] = []
var _tweens: Array[Tween] = []
var _font: Font = ThemeDB.fallback_font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--selftest":
			_selftest = true
		elif arg.begins_with("--capture="):
			_capture_dir = arg.trim_prefix("--capture=")
	rules = RationDeskRules.new(ContentDB.all_of("ration_case"))
	foley = RationFoley.new()
	add_child(foley)
	_build_ui()
	resized.connect(_layout)
	Game.state_changed.connect(_refresh)
	_layout()
	_restart()
	if _selftest:
		_run_selftest()


func _build_ui() -> void:
	var title: Label = _label(self, "KIOSK '81   /   KARNE MASASI", 32, Color("e9d8b1"))
	title.position = Vector2(30, 22)
	var subtitle: Label = _label(self, "Kâğıdı incele. Kuponu kes. Kararının sorumluluğunu al.", 19, Color("a9bdb0"))
	subtitle.position = Vector2(32, 68)
	customer_label = _label(self, "", 24, Color("ece5d0"))
	customer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	money_label = _label(self, "", 19, Color("b6c5b9"))
	status = _label(self, "", 20, Color("e9d8b1"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reference = _panel(self)
	var ref_rows: VBoxContainer = VBoxContainer.new()
	_margin(reference).add_child(ref_rows)
	_label(ref_rows, "KURAL DEFTERİ", 24, Color("e9d8b1"))
	_label(ref_rows, "ŞUBAT 1982 · SATIŞ TALİMATI", 15, Color("b6c5b9"))
	var book: RichTextLabel = RichTextLabel.new()
	book.bbcode_enabled = true
	book.scroll_active = true
	book.fit_content = false
	book.size_flags_vertical = Control.SIZE_EXPAND_FILL
	book.custom_minimum_size.y = 480
	book.add_theme_font_size_override("normal_font_size", 21)
	book.add_theme_font_size_override("bold_font_size", 21)
	book.text = "[b]İŞÇİ[/b]\nEt 750 g · Kurum F14\n\n[b]ÖĞRETMEN[/b]\nEt 500 g · Kurum S03\n\n[b]EMEKLİ[/b]\nEt 250 g · Kurum E02\n\nHer sınıf: şeker 1000 g, sabun 1 adet.\n\n[b]Arka yüz:[/b] kurum kodu ve onay mührü gerekli.\n\nEski ay, eksik onay veya bitmiş kupon: [b]RET[/b].\n\nSınıf/kurum çelişkisi veya değiştirilmiş et hakkı: [b]ALIKOY[/b].\n\nYıpranmış kart tek başına sahte değildir.\n\nStok yoksa kupon kesme."
	ref_rows.add_child(book)
	card_view = RationCardView.new()
	add_child(card_view)
	card_view.pickup_requested.connect(_take_card)
	card_view.dropped.connect(_drop_card)
	card_view.stamp_requested.connect(_stamp)
	card_view.cut_requested.connect(_cut)
	card_view.contact.connect(foley.play_sound)
	card_view.feedback.connect(_message)
	tools = HBoxContainer.new()
	tools.add_theme_constant_override("separation", 9)
	add_child(tools)
	var group: ButtonGroup = ButtonGroup.new()
	for entry: Array in [["hand", "EL / TAŞI"], ["approve", "SATIŞ DAMGASI"], ["reject", "RET DAMGASI"], ["seize", "ALIKOY DAMGASI"], ["scissors", "MAKAS / KES"]]:
		var button: Button = _button(tools, entry[1], func() -> void: _select_tool(entry[0]))
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = entry[0] == "hand"
		button.custom_minimum_size = Vector2(165, 56)
	_button(tools, "ÇEVİR  [F]", card_view.flip)
	official_button = _button(self, "RESMÎ STOKTAN HAZIRLA", func() -> void: _prepare("official"))
	hidden_button = _button(self, "GİZLİ STOKTAN HAZIRLA", func() -> void: _prepare("hidden"))
	stock_label = _label(self, "", 20, Color("c8d3c6"))
	parcel_label = _label(self, "", 20, Color("e9d8b1"))
	parcel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_button = _button(self, "SONRAKİ MÜŞTERİ →", _next)
	sound_controls = HBoxContainer.new()
	add_child(sound_controls)
	_label(sound_controls, "SES", 17, Color("b6c5b9"))
	var volume: HSlider = HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.01
	volume.value = 0.56
	volume.custom_minimum_size = Vector2(135, 32)
	volume.value_changed.connect(foley.set_level)
	sound_controls.add_child(volume)
	var motion: CheckButton = CheckButton.new()
	motion.text = "Hareket azalt"
	motion.add_theme_font_size_override("font_size", 16)
	motion.toggled.connect(func(on: bool) -> void: card_view.reduced_motion = on)
	sound_controls.add_child(motion)
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.name = "Navigation"
	add_child(navigation)
	_button(navigation, "Ürün tezgâhı", func() -> void: get_tree().change_scene_to_file("res://scenes/kiosk/simulator.tscn"))
	_button(navigation, "Yeni deneme", _restart)
	report = _panel(self)
	var report_rows: VBoxContainer = VBoxContainer.new()
	_margin(report).add_child(report_rows)
	_label(report_rows, "GÜN SONU / KARAR DEFTERİ", 28, Color("e9d8b1"))
	report_text = RichTextLabel.new()
	report_text.bbcode_enabled = true
	report_text.custom_minimum_size = Vector2(760, 530)
	report_text.add_theme_font_size_override("normal_font_size", 22)
	report_text.add_theme_font_size_override("bold_font_size", 22)
	report_rows.add_child(report_text)
	_button(report_rows, "Masayı yeniden aç", _restart)
	report.visible = false


func _layout() -> void:
	if card_view == null:
		return
	return_zone = Rect2(size.x - 345, 168, 305, 150)
	seize_zone = Rect2(size.x - 345, size.y - 330, 305, 140)
	bin_zone = Rect2(size.x * 0.5 - 105, size.y - 265, 210, 85)
	customer_label.position = Vector2(365, 104)
	customer_label.size = Vector2(size.x - 760, 87)
	money_label.position = Vector2(size.x - 650, 85)
	status.position = Vector2(365, size.y - 170)
	status.size = Vector2(size.x - 735, 58)
	reference.position = Vector2(26, 190)
	reference.size = Vector2(305, size.y - 310)
	tools.position = Vector2(365, size.y - 95)
	sound_controls.position = Vector2(26, size.y - 70)
	get_node("Navigation").position = Vector2(size.x - 385, 27)
	official_button.position = Vector2(size.x - 345, 352)
	official_button.size = Vector2(305, 54)
	hidden_button.position = Vector2(size.x - 345, 416)
	hidden_button.size = Vector2(305, 54)
	stock_label.position = Vector2(size.x - 345, 491)
	stock_label.size = Vector2(305, 100)
	parcel_label.position = Vector2(size.x - 345, 605)
	parcel_label.size = Vector2(305, 95)
	next_button.position = Vector2(size.x - 345, size.y - 115)
	next_button.size = Vector2(305, 56)
	report.position = Vector2(size.x / 2 - 410, size.y / 2 - 355)
	report.size = Vector2(820, 710)
	if not card_view.busy:
		card_view.position = _desk_position()
	queue_redraw()


func _desk_position() -> Vector2:
	return Vector2(size.x / 2 - 325, size.y * 0.48 - 200)


func _restart() -> void:
	_epoch += 1
	_busy = false
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	for token: Control in _tokens:
		if is_instance_valid(token):
			token.queue_free()
	_tokens.clear()
	_case_index = -1
	card_view.reset_pose()
	report.visible = false
	Game.new_campaign(1982, rules.opening())
	_message("Müşterinin uzattığı karta tıkla. F / sağ tık: çevir; tekerlek: yakınlaştır; Q/E: eğ.")


func _refresh(state: CampaignState) -> void:
	var work: Dictionary = RationDeskRules.desk(state)
	var encounter: Dictionary = rules.current(state)
	var index: int = int(work.get("index", 0))
	if encounter.is_empty():
		card_view.visible = false
		customer_label.text = "Müşteri sırası tamamlandı."
		_show_report(work)
	else:
		if index != _case_index:
			_case_index = index
			card_view.reset_pose()
			card_view.position = Vector2(size.x / 2 - 325, 145)
			card_view.scale = Vector2.ONE * 0.72
			card_view.visible = true
		card_view.show_card(encounter["card"], work)
		customer_label.text = "%d / %d · %s\n%s  —  %s" % [index + 1, rules.cases.size(), encounter["customer"], encounter["line"], RationDeskRules.amount_text(encounter["request"]["item"], int(encounter["request"]["amount"]))]
	money_label.text = "15 ŞUBAT 1982  ·  KASA %s  ·  CEP %s" % [Money.format(state.money["till"]), Money.format(state.money["pocket"])]
	var official: Dictionary = work.get("official", {})
	var hidden: Dictionary = work.get("hidden", {})
	stock_label.text = "Resmî stok\nEt: %d g · Şeker: %d g\nSabun: %d adet\nGizli et: %d g" % [official.get("meat", 0), official.get("sugar", 0), official.get("soap", 0), hidden.get("meat", 0)]
	var parcel: Dictionary = work.get("parcel", {})
	parcel_label.text = "Hazır ürün yok.\nKuponu hazırlamadan kesme." if parcel.is_empty() else "HAZIR: %s\n%s · %s" % [RationDeskRules.GOODS[parcel["item"]], RationDeskRules.amount_text(parcel["item"], int(parcel["amount"])), "Resmî stok" if parcel["source"] == "official" else "Kayıt dışı stok"]
	var inactive: bool = work.get("done", false) or encounter.is_empty()
	official_button.disabled = inactive
	hidden_button.disabled = inactive
	next_button.visible = work.get("done", false) and not encounter.is_empty()
	queue_redraw()


func _take_card() -> void:
	if _busy or not _execute(rules.take(Game.state)):
		return
	foley.play_sound("paper_pick")
	if card_view.reduced_motion:
		card_view.position = _desk_position()
		card_view.scale = Vector2.ONE
		return
	card_view.busy = true
	var tween: Tween = create_tween().set_parallel(true)
	_tweens.append(tween)
	tween.tween_property(card_view, "position", _desk_position(), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(card_view, "scale", Vector2.ONE, 0.28)
	tween.chain().tween_callback(func() -> void: card_view.busy = false)
	_message("Kart masada. Ön yüzü ve arka yüzdeki kurum onayını defterle karşılaştır.")


func _select_tool(tool: String) -> void:
	if _busy or card_view.busy:
		return
	card_view.tool = tool
	_message({"hand": "Kartı taşı. İade veya alıkoyma bölmesine sürükleyebilirsin.", "approve": "SATIŞ: ön yüzdeki KARAR alanına kısa süre basılı tut.", "reject": "RET: ön yüzdeki KARAR alanına kısa süre basılı tut.", "seize": "ALIKOY: ön yüzdeki KARAR alanına kısa süre basılı tut.", "scissors": "Ürün hazırsa ilgili kuponun sol üst çizgisinden sağa doğru kes."}[tool])


func _stamp(kind: String, at: Vector2) -> void:
	if _busy or not card_view.front:
		return
	if _execute(rules.stamp(Game.state, kind, at)):
		foley.play_sound("stamp_lift")
		_message("Damga basıldı. Kararın doğruluğu gün sonunda değerlendirilecek.")


func _prepare(source: String) -> void:
	if _busy:
		return
	if _execute(rules.prepare(Game.state, source)):
		foley.play_sound("paper_place")
		_message("Ürün hazır. MAKAS ile ilgili kuponu kes, EL ile kartı müşteriye iade et.")


func _cut(item: String) -> void:
	if _busy:
		return
	if not _execute(rules.cut(Game.state, item)):
		return
	var index: int = RationDeskRules.PRODUCT_ORDER.find(item)
	var rect: Rect2 = RationCardView.coupon_rect(index)
	var token: PanelContainer = _panel(self, Color("ded1ae"))
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.position = card_view.get_global_transform() * rect.position
	token.size = rect.size
	var label: Label = _label(token, RationDeskRules.GOODS[item], 20, Color("393a31"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	token.rotation = card_view.rotation
	_tokens.append(token)
	var generation: int = _epoch
	var tween: Tween = create_tween().set_parallel(true)
	_tweens.append(tween)
	tween.tween_property(token, "position", bin_zone.position + Vector2(28 + randf_range(0, 55), 16), 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(token, "scale", Vector2.ONE * 0.45, 0.48)
	tween.tween_property(token, "rotation", randf_range(-0.13, 0.13), 0.48)
	tween.chain().tween_callback(func() -> void:
		if generation == _epoch:
			foley.play_sound("coupon_drop")
			queue_redraw()
		token.queue_free())
	_message("Kupon ayrıldı. EL aracını seçip kalan kartı MÜŞTERİYE İADE bölmesine sürükle.")


func _drop_card(at: Vector2) -> void:
	if _busy:
		return
	var destination: String = ""
	if return_zone.has_point(at):
		destination = "return"
	elif seize_zone.has_point(at):
		destination = "seize"
	if destination == "":
		card_view.position.x = clampf(card_view.position.x, 350, size.x - 655)
		card_view.position.y = clampf(card_view.position.y, 160, size.y - 560)
		return
	if not _execute(rules.finish(Game.state, destination)):
		card_view.position = _desk_position()
		return
	foley.play_sound("drawer" if destination == "seize" else "paper_place")
	_message("İşlem kaydedildi. Sonraki müşteriyi çağırabilirsin.")
	if card_view.reduced_motion:
		card_view.visible = false
		return
	_busy = true
	card_view.busy = true
	var generation: int = _epoch
	var tween: Tween = create_tween().set_parallel(true)
	_tweens.append(tween)
	tween.tween_property(card_view, "scale", Vector2.ONE * 0.32, 0.28)
	tween.tween_property(card_view, "position", (return_zone if destination == "return" else seize_zone).get_center() - RationCardView.PAPER_SIZE / 2, 0.28)
	tween.chain().tween_callback(func() -> void:
		if generation == _epoch:
			card_view.visible = false
			card_view.busy = false
			_busy = false)


func _next() -> void:
	if _busy or card_view.busy:
		return
	if _execute(rules.next(Game.state)):
		_message("Yeni müşteri kartını uzattı. Kartı masaya al.")


func _execute(command: Dictionary) -> bool:
	if not command["ok"]:
		_message(command["error"])
		return false
	var effects: Array[Dictionary] = []
	effects.assign(command["effects"])
	if not Game.apply_effects(effects):
		_message("İşlem uygulanamadı; durum değiştirilmedi.")
		return false
	return true


func _message(text: String) -> void:
	status.text = text


func _show_report(work: Dictionary) -> void:
	var lines: PackedStringArray = []
	var correct: int = 0
	var turnover: int = 0
	for result: Dictionary in work.get("results", []):
		correct += 1 if result["correct"] else 0
		turnover += int(result["revenue"])
		lines.append("[b]%s[/b] — %s" % [result["customer"], {"approve": "SATIŞ", "reject": "RET", "seize": "ALIKOY"}[result["decision"]]])
		var explanation: String = "; ".join(result["issues"])
		if explanation == "":
			explanation = "Belge geçerli" + ("; resmî stok yetersiz" if result["shortage"] else "")
		lines.append("%s · %s%s\n" % ["Doğru karar" if result["correct"] else "Yanlış karar", explanation, " · kayıt dışı satış" if result["source"] == "hidden" else ""])
	report_text.text = "[b]%d / %d doğru karar · Ciro %s[/b]\nDenetim riski: %d\n\n%s" % [correct, (work.get("results", []) as Array).size(), Money.format(turnover), Game.state.meters["suspicion"], "\n".join(lines)]
	report.visible = true
	report.move_to_front()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_F: card_view.flip()
		KEY_Q: card_view.tilt(-5)
		KEY_E: card_view.tilt(5)
		KEY_ESCAPE: _select_tool("hand")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("263b35"))
	for y: int in range(180, int(size.y) - 120, 95):
		draw_rect(Rect2(345, y, size.x - 720, 91), Color("354844"))
		draw_line(Vector2(360, y + 90), Vector2(size.x - 395, y + 90), Color(0, 0, 0, 0.14), 1)
	if return_zone.size == Vector2.ZERO:
		return
	_draw_zone(return_zone, "MÜŞTERİYE İADE", "EL ile kartı buraya sürükle", Color("51665a"))
	_draw_zone(seize_zone, "ALIKONULAN BELGELER", "ALIKOY damgası + kart", Color("514940"))
	_draw_zone(bin_zone, "KUPON KUTUSU", "", Color("655c48"))
	var work: Dictionary = RationDeskRules.desk(Game.state)
	var count: int = (work.get("cuts", []) as Array).size()
	for result: Dictionary in work.get("results", []):
		count += (result.get("cuts", []) as Array).size()
	for i: int in mini(count, 9):
		draw_rect(Rect2(bin_zone.position + Vector2(24 + i * 13, 42 - (i % 2) * 5), Vector2(65, 26)), Color("d4c49f"))
	if card_view != null and card_view.visible:
		draw_string(_font, Vector2(size.x / 2 - 140, 205), "MÜŞTERİNİN UZATTIĞI KART", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("b3c0ae"))


func _draw_zone(rect: Rect2, title: String, hint: String, color: Color) -> void:
	draw_style_box(_style(color), rect)
	draw_rect(rect.grow(-8), Color("a69f7d"), false, 1)
	draw_string(_font, rect.position + Vector2(18, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ece4ca"))
	if hint != "":
		draw_string(_font, rect.position + Vector2(18, 70), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("c4c9b5"))


func _panel(parent: Control, color: Color = Color("1f302b")) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(panel)
	return panel


func _style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style


func _margin(parent: Control) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	parent.add_child(margin)
	return margin


func _label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _style(Color("4c6254")))
	button.add_theme_stylebox_override("hover", _style(Color("63765f")))
	button.add_theme_stylebox_override("pressed", _style(Color("806b4d")))
	button.add_theme_stylebox_override("disabled", _style(Color("35433b")))
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(pressed)
	parent.add_child(button)
	return button


func _run_selftest() -> void:
	await get_tree().process_frame
	card_view.reduced_motion = true
	var failures: PackedStringArray = []
	for i: int in rules.cases.size():
		var encounter: Dictionary = rules.current(Game.state)
		_pointer(card_view.get_global_transform() * Vector2(320, 150), true)
		_pointer(card_view.get_global_transform() * Vector2(320, 150), false)
		if RationDeskRules.desk(Game.state)["location"] != "desk":
			failures.append("mouse pickup failed: " + encounter["id"])
		var flip: InputEventKey = InputEventKey.new()
		flip.physical_keycode = KEY_F
		flip.pressed = true
		Input.parse_input_event(flip)
		Input.flush_buffered_events()
		if card_view.front:
			failures.append("keyboard flip failed")
		if i == 0:
			await _capture("02_back")
		card_view.flip()
		if i == 0:
			await _capture("01_front")
		var kind: String = "approve" if RationDeskRules.issues(encounter).is_empty() else ("seize" if RationDeskRules.is_forged(encounter) else "reject")
		_select_tool(kind)
		var stamp_at: Vector2 = card_view.get_global_transform() * Vector2(540, 190)
		_pointer(stamp_at, true)
		await get_tree().create_timer(0.10).timeout
		_pointer(stamp_at, false)
		if RationDeskRules.desk(Game.state)["stamp"] != kind:
			failures.append("stamp gesture failed: " + encounter["id"])
		if kind == "approve":
			var source: String = "hidden" if i == 7 else "official"
			(hidden_button if source == "hidden" else official_button).pressed.emit()
			var item: String = encounter["request"]["item"]
			var rect: Rect2 = RationCardView.coupon_rect(RationDeskRules.PRODUCT_ORDER.find(item))
			_select_tool("scissors")
			if i == 0:
				_pointer(card_view.get_global_transform() * rect.position, true)
				_move_pointer(card_view.get_global_transform() * (rect.position + Vector2(50, 0)))
				_pointer(card_view.get_global_transform() * (rect.position + Vector2(50, 0)), false)
				if not (RationDeskRules.desk(Game.state)["cuts"] as Array).is_empty():
					failures.append("short cut consumed coupon")
			_pointer(card_view.get_global_transform() * rect.position, true)
			for step: int in range(1, 9):
				_move_pointer(card_view.get_global_transform() * (rect.position + Vector2(rect.size.x * step / 8, 0)))
			_pointer(card_view.get_global_transform() * (rect.position + Vector2(rect.size.x, 0)), false)
			if not item in RationDeskRules.desk(Game.state)["cuts"]:
				failures.append("cut gesture failed: " + encounter["id"])
			if i == 0:
				await _capture("03_cut_and_stamp")
		_select_tool("hand")
		var target: Vector2 = (seize_zone if kind == "seize" else return_zone).get_center()
		var from: Vector2 = card_view.get_global_transform() * Vector2(320, 200)
		_pointer(from, true)
		_move_pointer(target)
		_pointer(target, false)
		if not RationDeskRules.desk(Game.state).get("done", false):
			failures.append("drag delivery failed: " + encounter["id"])
			_execute(rules.finish(Game.state, "seize" if kind == "seize" else "return"))
		next_button.pressed.emit()
	var results: Array = RationDeskRules.desk(Game.state).get("results", [])
	if results.size() != 8:
		failures.append("expected eight completed cases")
	for result: Dictionary in results:
		if not result["correct"]:
			failures.append("unexpected audit failure: " + result["case"])
	for sound: String in ["paper_pick", "paper_flip", "stamp_down", "stamp_lift", "snip", "paper_place", "drawer"]:
		if not sound in foley.events:
			failures.append("missing foley contact: " + sound)
	await _capture("04_day_end")
	# Restarting during a flip must not mutate the new customer's card later.
	_restart()
	card_view.reduced_motion = false
	_take_card()
	await get_tree().create_timer(0.32).timeout
	card_view.flip()
	await get_tree().create_timer(0.06).timeout
	_restart()
	await get_tree().create_timer(0.36).timeout
	if not card_view.front or card_view.busy or RationDeskRules.desk(Game.state).get("location") != "intake":
		failures.append("restart did not cancel the old flip")
	print("[ration selftest] %s" % ("PASS: 8 customers, mouse pickup/stamp/cut/drag, flip, audit and sound contacts" if failures.is_empty() else "FAIL: " + "; ".join(failures)))
	foley.stop_all()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if failures.is_empty() else 1)


func _pointer(at: Vector2, pressed: bool) -> void:
	_move_pointer(at)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.position = get_viewport().get_final_transform() * at
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _move_pointer(at: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = get_viewport().get_final_transform() * at
	event.global_position = event.position
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _capture(name: String) -> void:
	if _capture_dir == "" or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(_capture_dir)
	for i: int in 4:
		await get_tree().process_frame
	var err: Error = get_viewport().get_texture().get_image().save_png(_capture_dir.path_join(name + ".png"))
	if err != OK:
		push_error("Screenshot failed: " + error_string(err))
