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

var cases: Array[Dictionary] = []


func _init(records: Array) -> void:
	for record: Dictionary in records:
		cases.append(record.duplicate(true))
	cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])


func opening() -> Dictionary:
	return {"calendar_date": "1982-02-15", "phase": "shift", "money": {"till": 2000}, "flags": {
		KEY: {"index": 0, "location": "intake", "placement": "customer", "stamp": "", "marks": [], "cuts": [], "incisions": [], "parcel": {}, "done": false,
			"official": {"meat": 750, "sugar": 3000, "soap": 4}, "hidden": {"meat": 500, "sugar": 0, "soap": 0}, "results": []}}}


static func desk(state: CampaignState) -> Dictionary:
	return state.flags.get(KEY, {})


func current(state: CampaignState) -> Dictionary:
	var index: int = int(desk(state).get("index", 0))
	return cases[index] if index >= 0 and index < cases.size() else {}


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
	if not position.is_finite() or position.x < 460 or position.x > 620 or position.y < 135 or position.y > 225:
		return _reject("Damgayı ön yüzdeki KARAR alanına bas.")
	work["stamp"] = kind
	var mark: Dictionary = {"kind": kind, "x": position.x, "y": position.y,
		"physical": physical, "serial": (work["marks"] as Array).size() + 1}
	(work["marks"] as Array).append(_with_impression(mark, impression))
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
		"incisions": (work.get("incisions", []) as Array).duplicate(true), "marks": marks.duplicate(true)}
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
	return out


static func is_forged(encounter: Dictionary) -> bool:
	var card: Dictionary = encounter["card"]
	var spec: Dictionary = CLASSES.get(card.get("class", ""), {})
	return spec.is_empty() or card.get("institution") != spec.get("institution") or int(card.get("meat", 0)) != int(spec.get("meat", 0))


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
