class_name RationDeskRules
extends RefCounted
## Fictional game rules, not historical regulations. Every command is atomic via Game.

const KEY: String = "ration_desk"
const MONTH: String = "1982-02"
const CLASSES: Dictionary = {
	"worker": {"name": "İŞÇİ / ROBOTNIK", "institution": "F14", "meat": 750, "color": Color("a98053")},
	"teacher": {"name": "ÖĞRETMEN / NAUCZYCIEL", "institution": "S03", "meat": 500, "color": Color("618398")},
	"retired": {"name": "EMEKLİ / EMERYT", "institution": "E02", "meat": 250, "color": Color("738970")},
}
const GOODS: Dictionary = {"meat": "ET / MIĘSO", "sugar": "ŞEKER / CUKIER", "soap": "SABUN / MYDŁO"}
const PRODUCT_ORDER: PackedStringArray = ["meat", "sugar", "soap"]
const MAX_INK_TIME_STEP: float = 60.0
const MAX_INK_CLOCK: float = 1.0e12
const MAX_INK_RUBS: int = 32
const FINGER_RADIUS_PX: float = 6.0

var cases: Array[Dictionary] = []


func _init(records: Array) -> void:
	for record: Dictionary in records:
		cases.append(record.duplicate(true))
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])


func opening(require_coupon_collection: bool = false) -> Dictionary:
	return {"calendar_date": "1982-02-15", "phase": "shift", "money": {"till": 2000}, "flags": {
		KEY: {"index": 0, "location": "intake", "placement": "customer", "stamp": "", "marks": [], "cuts": [], "incisions": [], "collected": [], "require_coupon_collection": require_coupon_collection, "parcel": {}, "done": false, "ink_clock": 0,
			"official": {"meat": 750, "sugar": 3000, "soap": 4}, "hidden": {"meat": 500, "sugar": 0, "soap": 0}, "results": []}}}


static func desk(state: CampaignState) -> Dictionary:
	return state.flags.get(KEY, {})


func current(state: CampaignState) -> Dictionary:
	var index: int = int(desk(state).get("index", 0))
	return cases[index] if index >= 0 and index < cases.size() else {}


## Elapsed physical time belongs to the shift, not to the current customer.
## The view requests small ticks only while ink is wet; loading/switching a
## customer cannot make a contact fresh again or modify its immutable timestamp.
func advance_ink_time(state: CampaignState, delta: Variant) -> Dictionary:
	if not _is_finite_number(delta) or float(delta) < 0.0:
		return _reject("Mürekkep zamanı sonlu ve negatif olmayan bir değer olmalı.")
	var work: Dictionary = desk(state).duplicate(true)
	if work.is_empty():
		return _reject("Mürekkep zamanı için açık bir vardiya gerekli.")
	var clock: float = _bounded_number(work.get("ink_clock", 0.0), 0.0, 0.0, MAX_INK_CLOCK)
	work["ink_clock"] = minf(clock + minf(float(delta), MAX_INK_TIME_STEP), MAX_INK_CLOCK)
	return _commit(_stable_record(work))


static func amount_text(item: String, amount: int) -> String:
	return "%d adet" % amount if item == "soap" else "%d g" % amount


func take(state: CampaignState) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if current(state).is_empty() or work.get("done", false):
		return _reject("Bu müşteriyle işlem tamamlandı.")
	if work.get("location") != "intake":
		return _reject("Kart zaten masada.")
	work["location"] = "desk"
	work["placement"] = "hand"
	return _commit(work)


func move_card(state: CampaignState, placement: String) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or not placement in ["hand", "table"]:
		return _reject("Aktif kart elde veya masada olmalı.")
	work["placement"] = placement
	return _commit(work)


func stamp(state: CampaignState, kind: String, position: Vector2, physical: bool = false, impression: Dictionary = {}) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if physical and work.get("placement") != "table":
		return _reject("Damga basmak için kartı masaya bırak.")
	if not _active(work) or not kind in ["approve", "reject", "seize"]:
		return _reject("Kartı masaya al ve bir karar damgası seç.")
	if (work.get("parcel", {}) as Dictionary).get("delivered", false) and kind != "approve":
		return _reject("Ürün teslim edildi; satışı kartı iade ederek tamamla.")
	if not position.is_finite() or position.x < 0 or position.x >= 640 or position.y < 0 or position.y >= 400:
		return _reject("Damgayı kâğıdın üzerine bas.")
	if physical:
		var available: Array = current(state).get("card", {}).get("available", [])
		for index: int in PRODUCT_ORDER.size():
			var rectangle: Rect2 = Rect2(30 + index * 195, 285, 180, 90)
			if rectangle.has_point(position) and (not PRODUCT_ORDER[index] in available or PRODUCT_ORDER[index] in work.get("cuts", []) or PaperCutGeometry.coupon_is_severed(work.get("incisions", []), rectangle)):
				return _reject("Bu kupon bölgesinde artık kâğıt yok.")
	var in_decision_area: bool = Rect2(460, 135, 160, 90).has_point(position)
	if not physical and not in_decision_area:
		return _reject("Damgayı ön yüzdeki KARAR alanına bas.")
	var mark: Dictionary = {"kind": kind, "x": position.x, "y": position.y,
		"physical": physical, "serial": (work["marks"] as Array).size() + 1}
	mark = _with_impression(mark, impression)
	if float(mark["ink_load"]) <= 0.0:
		return _reject("Damgada mürekkep kalmadı; mürekkep pedine bastır.")
	if float(mark["contact_time"]) >= 0.0:
		mark["contact_time"] = minf(float(mark["contact_time"]), _bounded_number(work.get("ink_clock", 0.0), 0.0, 0.0, MAX_INK_CLOCK))
		mark = _stable_record(mark)
	# A physical misplaced contact is still permanent ink, but must not approve,
	# reject or confiscate the document through an unrelated printed field.
	if in_decision_area: work["stamp"] = kind
	(work["marks"] as Array).append(mark)
	return _commit(work)


## Continued pressure and sideways drag develop the same physical ink contact;
## they must never append another decision or move the original impact point.
func update_impression(state: CampaignState, serial: int, impression: Dictionary) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or work.get("placement") != "table":
		return _reject("Baskıyı geliştirmek için kart masada olmalı.")
	var marks: Array = work.get("marks", [])
	for index: int in range(marks.size()):
		var mark: Dictionary = marks[index]
		if int(mark.get("serial", -1)) == serial and serial > 0:
			var developed: Dictionary = mark.duplicate(true)
			var sanitized: Dictionary = _with_impression(mark, impression)
			for key: String in ["speed", "dwell", "pressure", "angle", "smudge", "smudge_direction"]:
				if impression.has(key):
					developed[key] = sanitized[key]
			marks[index] = developed
			return _commit(work)
	return _reject("Geliştirilecek damga teması bulunamadı.")


## A finger may lift still-wet ink after the rubber has been removed. Endpoints
## are actual paper pixels; each saved rub stays in that impression's local
## coordinates so rotating/moving the sheet never changes the drag direction.
func smear_wet_ink(state: CampaignState, start: Vector2, end: Vector2, gesture_id: int = 0) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or work.get("placement") != "table":
		return _reject("Mürekkebe dokunmak için aktif kart masada olmalı.")
	if gesture_id < 0 or gesture_id > 2147483647:
		return _reject("Mürekkep hareketinin kimliği geçersiz.")
	var sheet: Rect2 = Rect2(Vector2.ZERO, Vector2(640, 400))
	if not start.is_finite() or not end.is_finite() or not sheet.has_point(start):
		return _reject("Parmağın kâğıdın üzerinde başlamalı.")
	if start.distance_to(end) < 0.1 or start.distance_to(end) > 4096.0:
		return _reject("Mürekkep sürükleme yolu geçersiz.")
	var paper_path: PackedVector2Array = _clip_ink_segment(start, end, sheet)
	if paper_path.size() != 2 or paper_path[0].distance_to(paper_path[1]) < 0.1:
		return _reject("Parmak kâğıt üzerinde ilerlemedi.")
	var clock: float = _bounded_number(work.get("ink_clock", 0.0), 0.0, 0.0, MAX_INK_CLOCK)
	var marks: Array = work.get("marks", [])
	var changed: bool = false
	for index: int in marks.size():
		var mark: Dictionary = marks[index]
		var wetness: float = _ink_wetness(mark, clock)
		if wetness <= 0.0:
			continue
		var rubs: Array = (mark.get("rubs", []) as Array).duplicate(true)
		var center: Vector2 = Vector2(float(mark.get("x", 0.0)), float(mark.get("y", 0.0)))
		var angle: float = _bounded_number(mark.get("angle", 0.0), 0.0, -TAU * 100.0, TAU * 100.0)
		var local_start: Vector2 = (paper_path[0] - center).rotated(-angle)
		var local_end: Vector2 = (paper_path[1] - center).rotated(-angle)
		if not rubs.is_empty() and _can_extend_ink_rub(rubs[-1], local_start, local_end, gesture_id):
			var extended: Dictionary = (rubs[-1] as Dictionary).duplicate(true)
			extended["to"] = [local_end.x, local_end.y]
			rubs[-1] = _stable_record(extended)
			mark["rubs"] = rubs
			marks[index] = mark
			changed = true
			continue
		if rubs.size() >= MAX_INK_RUBS:
			continue
		var contact: PackedVector2Array = _clip_ink_segment(local_start, local_end,
			Rect2(-65, -22, 130, 44).grow(FINGER_RADIUS_PX))
		if contact.size() != 2 or contact[0].distance_to(contact[1]) < 0.1:
			continue
		# Keep the actual pull after the first wet contact, including departure
		# from the print. Rendering clips lifted fibres, never the whole stamp.
		var rub: Dictionary = _stable_record({"from": [contact[0].x, contact[0].y],
			"to": [local_end.x, local_end.y], "wetness": wetness})
		if gesture_id > 0:
			rub["gesture_id"] = gesture_id
		if not rubs.is_empty() and rubs[-1] == rub:
			continue # Replaying the same contact tick cannot double the damage.
		rubs.append(rub)
		mark["rubs"] = rubs
		marks[index] = mark
		changed = true
	if not changed:
		return _reject("Bu hareketin altında bulaşabilecek yaş mürekkep yok.")
	work["marks"] = marks
	return _commit(work)


func prepare(state: CampaignState, source: String, item: String = "", physical: bool = false) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or work.get("stamp") != "approve":
		return _reject("Ürün hazırlamak için SATIŞ damgasını bas.")
	if not source in ["official", "hidden"]:
		return _reject("Geçersiz tedarik kaynağı.")
	var request: Dictionary = current(state)["request"]
	if not _valid_request(request):
		return _reject("Siparişin ürün ve miktar bilgisi geçersiz.")
	if item != "" and item != request["item"]:
		return _reject("Müşteri bu ürünü istemedi.")
	if physical and not request["item"] in work.get("cuts", []):
		return _reject("Önce karne işlemlerini tamamla: satış damgası ve ilgili kupon kesimi gerekli.")
	if not (work.get("parcel", {}) as Dictionary).is_empty():
		return _reject("Ürün zaten hazırlandı; mevcut paketi masadan al veya teslim et.")
	var stock: Dictionary = work[source]
	if int(stock.get(request["item"], 0)) < int(request["amount"]):
		return _reject("Bu kaynakta istenen miktar yok; diğer stoku kontrol et.")
	work["parcel"] = {"item": request["item"], "amount": request["amount"], "source": source, "placement": "shelf", "delivered": false}
	return _commit(work)


func move_parcel(state: CampaignState, placement: String) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	var parcel: Dictionary = work.get("parcel", {})
	if not _active(work) or parcel.is_empty() or parcel.get("delivered", false) or not placement in ["hand", "table"]:
		return _reject("Taşınabilecek hazırlanmış ürün yok.")
	parcel["placement"] = placement
	return _commit(work)


func deliver_parcel(state: CampaignState) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	var parcel: Dictionary = work.get("parcel", {})
	if not _active(work) or parcel.is_empty() or parcel.get("placement") != "hand" or parcel.get("delivered", false):
		return _reject("Teslim edilecek ürün elinde olmalı.")
	if not _parcel_matches_request(parcel, current(state).get("request", {})):
		return _reject("Hazırlanan paketin ürün, miktar veya kaynak bilgisi siparişle uyuşmuyor.")
	if work.get("stamp") != "approve" or not parcel["item"] in work["cuts"]:
		return _reject("Önce satış damgası ve uygun kupon kesimi gerekli.")
	if int(work[parcel["source"]].get(parcel["item"], 0)) < int(parcel["amount"]):
		return _reject("Teslimat için stok yeterli değil.")
	parcel["placement"] = "customer"
	parcel["delivered"] = true
	return _commit(work)


## Store actual blade travel as permanent damage. Leaving the desk or releasing
## the button stops cutting; it does not heal the paper or consume a whole coupon.
func incise(state: CampaignState, points: Array, physical: bool = true) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or (physical and work.get("placement") != "table"):
		return _reject("Kâğıdı kesmek için aktif kartı masaya bırak.")
	if points.size() < 2 or points.size() > 4096:
		return _reject("Kesim gerçek bir bıçak yolu içermeli.")
	var path: Array = []
	for point: Variant in points:
		if not point is Array or point.size() != 2 or not _is_finite_number(point[0]) or not _is_finite_number(point[1]):
			return _reject("Kesim noktası geçersiz.")
		var x: float = float(point[0])
		var y: float = float(point[1])
		if x < 0.0 or x > PaperCutGeometry.PRINT_SIZE.x or y < 0.0 or y > PaperCutGeometry.PRINT_SIZE.y:
			return _reject("Kesim yolu kâğıdın üzerinde olmalı.")
		if path.is_empty() or Vector2(x, y).distance_squared_to(Vector2(path[-1][0], path[-1][1])) > 0.000001:
			path.append([x, y])
	var length_m: float = PaperCutGeometry.path_length_m(path)
	if length_m < 0.00005:
		return _reject("Makas henüz kâğıt üzerinde ilerlemedi.")
	var incisions: Array = work.get("incisions", [])
	incisions.append(_stable_record({"points": path, "length_m": length_m}))
	work["incisions"] = incisions
	return _commit(work)


func cut(state: CampaignState, item: String, physical: bool = false) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if physical and work.get("placement") != "table":
		return _reject("Kesmek için kartı masaya bırak.")
	if not _active(work) or work.get("stamp") != "approve":
		return _reject("Kesmeden önce SATIŞ damgası gerekli.")
	var request: Dictionary = current(state)["request"]
	if not _valid_request(request):
		return _reject("Siparişin ürün ve miktar bilgisi geçersiz.")
	if request["item"] != item:
		return _reject("Yalnızca müşterinin istediği ürünün kuponunu kes.")
	if int(work["official"].get(item, 0)) < int(request["amount"]) and int(work["hidden"].get(item, 0)) < int(request["amount"]):
		return _reject("İki kaynakta da yeterli stok yok; kuponu kesme.")
	var card: Dictionary = current(state)["card"]
	if not item in card["available"] or item in work["cuts"]:
		return _reject("Bu kupon yok veya zaten kesildi.")
	if int(card.get(item, 0)) < int(request["amount"]):
		return _reject("Kupondaki miktar istenen üründen az.")
	if physical:
		var index: int = PRODUCT_ORDER.find(item)
		var rectangle: Rect2 = Rect2(30 + index * 195, 285, 180, 90)
		if not PaperCutGeometry.coupon_is_severed(work.get("incisions", []), rectangle):
			return _reject("Kupon hâlâ kâğıda bağlı; dört kenardaki kesimi tamamla.")
	(work["cuts"] as Array).append(item)
	return _commit(work)


## Filing is a physical bookkeeping fact, separate from severing the paper and
## consuming its entitlement. It can happen before the decision stamp, but only
## after this encounter's actual coupon has been completely detached.
func file_coupon(state: CampaignState, item: String, physical_contact: bool = true) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	var encounter: Dictionary = current(state)
	if not _active(work) or encounter.is_empty():
		return _reject("Dosyalanacak aktif kupon yok.")
	if not physical_contact:
		return _reject("Kestiğin kuponu elinle kupon kutusuna bırak.")
	var card: Dictionary = encounter.get("card", {})
	if not item in PRODUCT_ORDER or not item in card.get("available", []):
		return _reject("Bu karneye ait kullanılabilir kupon bulunamadı.")
	var collected: Array = work.get("collected", [])
	if item in collected:
		return _reject("Bu kupon zaten dosyalandı.")
	var index: int = PRODUCT_ORDER.find(item)
	if not PaperCutGeometry.coupon_is_severed(work.get("incisions", []), Rect2(30 + index * 195, 285, 180, 90)):
		return _reject("Kupon hâlâ karneye bağlı; önce dört kenarını tamamen kes.")
	collected.append(item)
	work["collected"] = collected
	return _commit(work)


## Complete only the document exercise. This is deliberately separate from a
## sale: no invented parcel, delivery, register entry, stock loss or payment.
## Both outcomes are real handoffs: held paper goes to the customer or drawer.
func finish_review(state: CampaignState, destination: String) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	var encounter: Dictionary = current(state)
	if not _active(work) or encounter.is_empty():
		return _reject("Aktif karne incelemesi yok.")
	if not (work.get("parcel", {}) as Dictionary).is_empty():
		return _reject("Ürün hazırlanmış işlemi satış akışıyla tamamla.")
	var kind: String = work.get("stamp", "")
	if not kind in ["approve", "reject", "seize"]:
		return _reject("Önce karar damgasını kâğıda bas.")
	var marks: Array = work.get("marks", [])
	if marks.is_empty() or marks[-1].get("kind", "") != kind or not marks[-1].get("physical", false):
		return _reject("İncelemeyi bitirmek için fiziksel damga teması gerekli.")
	if not destination in ["return", "seize"] or (destination == "seize") != (kind == "seize"):
		return _reject("Karar damgasıyla belgeyi vereceğin yer uyuşmuyor.")
	if work.get("placement") != "hand":
		return _reject("Teslim edeceğin karneyi eline al.")
	var request: Dictionary = encounter.get("request", {})
	if not _valid_request(request):
		return _reject("Siparişin ürün ve miktar bilgisi geçersiz.")
	var cuts: Array = work.get("cuts", [])
	if kind == "approve":
		var item: String = request["item"]
		var card: Dictionary = encounter.get("card", {})
		if cuts.size() != 1 or cuts[0] != item or not item in card.get("available", []) or int(card.get(item, 0)) < int(request["amount"]):
			return _reject("Onay için istenen ürünün kullanılabilir ve yeterli kuponunu kes.")
		var index: int = PRODUCT_ORDER.find(item)
		if not PaperCutGeometry.coupon_is_severed(work.get("incisions", []), Rect2(30 + index * 195, 285, 180, 90)):
			return _reject("Onay için kuponun dört kenarını fiziksel olarak tamamen kes.")
		if work.get("require_coupon_collection", false) and not item in work.get("collected", []):
			return _reject("Onay için kesilen kuponu elinle kupon kutusuna bırak.")
	var problems: PackedStringArray = issues(encounter)
	var forged: bool = is_forged(encounter)
	var physical_detached: Array = []
	var available: Array = encounter.get("card", {}).get("available", [])
	for index: int in range(PRODUCT_ORDER.size()):
		var item: String = PRODUCT_ORDER[index]
		if item in available and PaperCutGeometry.coupon_is_severed(work.get("incisions", []), Rect2(30 + index * 195, 285, 180, 90)):
			physical_detached.append(item)
	var correct: bool = false
	if kind == "approve":
		correct = problems.is_empty() and physical_detached.size() == 1 and physical_detached[0] == request["item"]
	elif kind == "seize":
		correct = forged and cuts.is_empty() and physical_detached.is_empty()
	else:
		correct = not forged and not problems.is_empty() and cuts.is_empty() and physical_detached.is_empty()
	# Explain damage only in the completed audit. The pre-decision document
	# evidence returned by issues(encounter) must remain independent of our work.
	var audit_issues: PackedStringArray = problems.duplicate()
	for item: String in physical_detached:
		if kind == "approve" and item != request["item"]:
			audit_issues.append("Talep dışı kupon kesildi: " + str(GOODS[item]))
		elif kind != "approve":
			audit_issues.append("Ret/alıkoyma işleminde kupon kesildi: " + str(GOODS[item]))
	var result: Dictionary = {"case": encounter["id"], "customer": encounter["customer"], "decision": kind,
		"document_review": true, "correct": correct, "issues": Array(audit_issues), "forged": forged,
		"source": "", "revenue": 0, "shortage": false, "cuts": cuts.duplicate(), "physical_detached": physical_detached,
		"incisions": (work.get("incisions", []) as Array).duplicate(true), "marks": marks.duplicate(true),
		"collected": (work.get("collected", []) as Array).duplicate()}
	(work["results"] as Array).append(result)
	work["done"] = true
	work["location"] = "seize" if kind == "seize" else "return"
	work["placement"] = "drawer" if kind == "seize" else "customer"
	var extra: Array[Dictionary] = []
	if not correct:
		extra.append({"op": "meter_add", "meter": "suspicion", "amount": 8 if kind == "approve" else 3})
	extra.append({"op": "decision_log", "entry": result})
	extra.append({"op": "clock_advance", "minutes": 2})
	return _commit(work, extra)


func finish(state: CampaignState, destination: String, physical: bool = false) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work):
		return _reject("Aktif kart işlemi yok.")
	if physical and work.get("placement") != "hand":
		return _reject("Teslim edeceğin kart elinde olmalı.")
	var kind: String = work.get("stamp", "")
	if (work.get("parcel", {}) as Dictionary).get("delivered", false) and kind != "approve":
		return _reject("Teslim edilen ürünün satışı tamamlanmalı.")
	if kind == "" or not destination in ["return", "seize"]:
		return _reject("Önce karar damgasını bas.")
	if (destination == "seize") != (kind == "seize"):
		return _reject("Karar damgasıyla belge bölmesi uyuşmuyor.")
	var encounter: Dictionary = current(state)
	var request: Dictionary = encounter.get("request", {})
	if not _valid_request(request):
		return _reject("Siparişin ürün ve miktar bilgisi geçersiz.")
	var problems: PackedStringArray = issues(encounter)
	var forged: bool = is_forged(encounter)
	var official: Dictionary = work["official"]
	var shortage: bool = int(official.get(request["item"], 0)) < int(request["amount"])
	var extra: Array[Dictionary] = []
	var source: String = ""
	var revenue: int = 0
	var correct: bool = false
	if kind == "approve":
		var parcel: Dictionary = work.get("parcel", {})
		if parcel.is_empty() or not request["item"] in work["cuts"]:
			return _reject("Ürünü hazırla ve uygun kuponu tamamen kes.")
		if not _parcel_matches_request(parcel, request):
			return _reject("Hazırlanan paketin ürün, miktar veya kaynak bilgisi siparişle uyuşmuyor.")
		if physical and not parcel.get("delivered", false):
			return _reject("Önce hazırlanan ürünü müşteriye uzat.")
		source = parcel["source"]
		var stock: Dictionary = work[source]
		if int(stock.get(request["item"], 0)) < int(request["amount"]):
			return _reject("Hazırlanan ürün için stok artık yeterli değil.")
		stock[request["item"]] = int(stock[request["item"]]) - int(request["amount"])
		revenue = price(request["item"], int(request["amount"]))
		extra.append({"op": "money_add", "account": "pocket" if source == "hidden" else "till", "amount": revenue})
		if source == "official":
			extra.append({"op": "register_append", "entry": {"item": "ration_" + request["item"], "qty": 1, "price": revenue, "amount": request["amount"], "ration": true}})
		else:
			extra.append({"op": "meter_add", "meter": "suspicion", "amount": 4})
		correct = problems.is_empty()
	elif kind == "seize":
		correct = forged and (work["cuts"] as Array).is_empty()
	else:
		correct = not forged and (not problems.is_empty() or shortage) and (work["cuts"] as Array).is_empty()
	if not correct:
		extra.append({"op": "meter_add", "meter": "suspicion", "amount": 8 if kind == "approve" else 3})
	var result: Dictionary = {"case": encounter["id"], "customer": encounter["customer"], "decision": kind,
		"correct": correct, "issues": Array(problems), "forged": forged, "source": source, "revenue": revenue,
		"cuts": (work["cuts"] as Array).duplicate(), "incisions": (work.get("incisions", []) as Array).duplicate(true),
		"marks": (work["marks"] as Array).duplicate(true), "shortage": shortage}
	(work["results"] as Array).append(result)
	work["done"] = true
	work["location"] = destination
	work["placement"] = "customer" if destination == "return" else "drawer"
	work["parcel"] = {}
	extra.append({"op": "decision_log", "entry": result})
	extra.append({"op": "clock_advance", "minutes": 2})
	return _commit(work, extra)


func next(state: CampaignState) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not work.get("done", false) or int(work.get("index", 0)) >= cases.size():
		return _reject("Önce mevcut müşteriyi tamamla.")
	work["index"] = int(work["index"]) + 1
	work["location"] = "intake"
	work["placement"] = "customer"
	work["stamp"] = ""
	work["marks"] = []
	work["cuts"] = []
	work["incisions"] = []
	work["collected"] = []
	work["parcel"] = {}
	work["done"] = false
	return _commit(work)


static func price(item: String, amount: int) -> int:
	match item:
		"meat": return amount * 4
		"sugar": return amount
		"soap": return amount * 800
	return 0


static func issues(encounter: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var card: Dictionary = encounter["card"]
	var spec: Dictionary = CLASSES.get(card.get("class", ""), {})
	if spec.is_empty():
		out.append("Tanınmayan kart sınıfı")
		return out
	if card.get("institution") != spec["institution"]:
		out.append("Kurum kodu ile meslek sınıfı uyuşmuyor")
	if int(card.get("meat", 0)) != int(spec["meat"]):
		out.append("Et hakkı sınıfın miktarıyla uyuşmuyor")
	if card.get("month") != MONTH:
		out.append("Geçerlilik ayı uygun değil")
	if not card.get("seal", false):
		out.append("Arka yüzde kurum onayı yok")
	var request: Dictionary = encounter["request"]
	if not request["item"] in card.get("available", []):
		out.append("İstenen ürünün kuponu kullanılmış")
	if int(card.get(request["item"], 0)) < int(request["amount"]):
		out.append("İstenen miktar kupon hakkını aşıyor")
	out.append_array(RationEvidence.issues(encounter))
	return out


static func is_forged(encounter: Dictionary) -> bool:
	var card: Dictionary = encounter["card"]
	var spec: Dictionary = CLASSES.get(card.get("class", ""), {})
	return spec.is_empty() or card.get("institution") != spec.get("institution") or int(card.get("meat", 0)) != int(spec.get("meat", 0)) or RationEvidence.is_forged(encounter)


static func _active(work: Dictionary) -> bool:
	return work.get("location") == "desk" and not work.get("done", false)


static func _valid_request(request: Dictionary) -> bool:
	return request.get("item", "") in PRODUCT_ORDER and typeof(request.get("amount")) == TYPE_INT and int(request["amount"]) > 0


static func _is_finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


static func _bounded_number(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	return clampf(float(value), minimum, maximum) if _is_finite_number(value) else fallback


static func _with_impression(mark: Dictionary, impression: Dictionary) -> Dictionary:
	var out: Dictionary = mark.duplicate(true)
	out["ink_load"] = _bounded_number(impression.get("ink_load", out.get("ink_load", 1.0)), 1.0, 0.0, 1.0)
	out["tilt"] = _bounded_number(impression.get("tilt", out.get("tilt", 0.0)), 0.0, -0.30, 0.30)
	out["contact_time"] = _ink_timestamp(impression.get("contact_time", out.get("contact_time", -1.0)))
	out["dry_duration"] = _bounded_number(impression.get("dry_duration", out.get("dry_duration", 10.0)), 10.0, 8.0, 12.0)
	out["speed"] = _bounded_number(impression.get("speed", out.get("speed", 0.35)), float(out.get("speed", 0.35)), 0.0, 5.0)
	out["dwell"] = _bounded_number(impression.get("dwell", out.get("dwell", 0.15)), float(out.get("dwell", 0.15)), 0.0, 15.0)
	out["pressure"] = _bounded_number(impression.get("pressure", out.get("pressure", 0.65)), float(out.get("pressure", 0.65)), 0.0, 1.0)
	out["angle"] = wrapf(_bounded_number(impression.get("angle", out.get("angle", 0.0)), float(out.get("angle", 0.0)), -TAU * 100.0, TAU * 100.0), -PI, PI)
	out["smudge"] = _bounded_number(impression.get("smudge", out.get("smudge", 0.0)), float(out.get("smudge", 0.0)), 0.0, 0.02)
	var direction: Variant = impression.get("smudge_direction", out.get("smudge_direction", [0.0, 0.0]))
	var direction_vector: Vector2 = Vector2.ZERO
	if direction is Vector2 and direction.is_finite():
		direction_vector = direction.normalized()
	elif direction is Array and direction.size() == 2 and _is_finite_number(direction[0]) and _is_finite_number(direction[1]):
		direction_vector = Vector2(float(direction[0]), float(direction[1]))
		direction_vector = direction_vector.normalized() if direction_vector.is_finite() else Vector2.ZERO
	out["smudge_direction"] = [direction_vector.x, direction_vector.y]
	return _stable_record(out)


## A missing/legacy timestamp is dry. Invalid negative values cannot create an
## in-between sentinel, and non-finite input never reaches a save or renderer.
static func _ink_timestamp(value: Variant) -> float:
	return minf(float(value), MAX_INK_CLOCK) if _is_finite_number(value) and float(value) >= 0.0 else -1.0


static func _ink_wetness(mark: Dictionary, clock: float) -> float:
	var timestamp: float = _ink_timestamp(mark.get("contact_time", -1.0))
	var load: float = _bounded_number(mark.get("ink_load", 1.0), 1.0, 0.0, 1.0)
	if timestamp < 0.0 or load <= 0.0:
		return 0.0
	var duration: float = _bounded_number(mark.get("dry_duration", 10.0), 10.0, 8.0, 12.0)
	return clampf(1.0 - maxf(clock - timestamp, 0.0) / duration, 0.0, 1.0)


## Live finger samples extend only the latest straight stroke from that exact
## gesture. A turn, reversal or another gesture keeps its own measured path.
static func _can_extend_ink_rub(previous: Dictionary, start: Vector2, end: Vector2, gesture_id: int) -> bool:
	if gesture_id <= 0 or int(previous.get("gesture_id", 0)) != gesture_id:
		return false
	var first_data: Array = previous.get("from", [])
	var last_data: Array = previous.get("to", [])
	if first_data.size() != 2 or last_data.size() != 2:
		return false
	var first: Vector2 = Vector2(float(first_data[0]), float(first_data[1]))
	var last: Vector2 = Vector2(float(last_data[0]), float(last_data[1]))
	var direction: Vector2 = last - first
	var continuation: Vector2 = end - start
	if direction.length_squared() < 0.01 or continuation.length_squared() < 0.01 or start.distance_to(last) >= 2.0:
		return false
	if direction.dot(continuation) <= 0.0:
		return false
	var unit: Vector2 = direction.normalized()
	return absf(unit.cross(start - first)) < 0.75 and absf(unit.cross(end - first)) < 0.75


## Slab clipping keeps the actual path; it neither projects onto a target nor
## rotates a diagonal gesture into a guessed horizontal/vertical line.
static func _clip_ink_segment(start: Vector2, end: Vector2, bounds: Rect2) -> PackedVector2Array:
	var direction: Vector2 = end - start
	var low: float = 0.0
	var high: float = 1.0
	for axis: int in 2:
		if absf(direction[axis]) < 0.000001:
			if start[axis] < bounds.position[axis] or start[axis] > bounds.end[axis]:
				return PackedVector2Array()
			continue
		var first: float = (bounds.position[axis] - start[axis]) / direction[axis]
		var last: float = (bounds.end[axis] - start[axis]) / direction[axis]
		low = maxf(low, minf(first, last))
		high = minf(high, maxf(first, last))
		if low > high:
			return PackedVector2Array()
	return PackedVector2Array([start + direction * low, start + direction * high])


## Canonicalize new physical records once at the command boundary. CampaignState
## normalizes integral floats during copies, and JSON has finite decimal precision;
## storing that same representation prevents saving from changing ink or paths.
static func _stable_record(record: Dictionary) -> Dictionary:
	return CampaignState.normalize_numbers(JSON.parse_string(JSON.stringify(record)))


## A saved or stale parcel must never deliver one quantity and bill another.
## These are order invariants; authenticity remains the player's decision.
static func _parcel_matches_request(parcel: Dictionary, request: Dictionary) -> bool:
	return _valid_request(request) and parcel.get("item") == request["item"] and typeof(parcel.get("amount")) == TYPE_INT and parcel["amount"] == request["amount"] and parcel.get("source", "") in ["official", "hidden"]


static func _commit(work: Dictionary, extra: Array[Dictionary] = []) -> Dictionary:
	var effects: Array[Dictionary] = [{"op": "flag_set", "key": KEY, "value": work}]
	effects.append_array(extra)
	return {"ok": true, "error": "", "effects": effects}


static func _reject(message: String) -> Dictionary:
	var effects: Array[Dictionary] = []
	return {"ok": false, "error": message, "effects": effects}
