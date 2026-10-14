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
		KEY: {"index": 0, "location": "intake", "stamp": "", "marks": [], "cuts": [], "parcel": {}, "done": false,
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
	return _commit(work)


func stamp(state: CampaignState, kind: String, position: Vector2) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or not kind in ["approve", "reject", "seize"]:
		return _reject("Kartı masaya al ve bir karar damgası seç.")
	if position.x < 460 or position.x > 620 or position.y < 135 or position.y > 225:
		return _reject("Damgayı ön yüzdeki KARAR alanına bas.")
	work["stamp"] = kind
	(work["marks"] as Array).append({"kind": kind, "x": int(position.x), "y": int(position.y)})
	return _commit(work)


func prepare(state: CampaignState, source: String) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or work.get("stamp") != "approve":
		return _reject("Ürün hazırlamak için SATIŞ damgasını bas.")
	if not source in ["official", "hidden"]:
		return _reject("Geçersiz tedarik kaynağı.")
	var request: Dictionary = current(state)["request"]
	var stock: Dictionary = work[source]
	if int(stock.get(request["item"], 0)) < int(request["amount"]):
		return _reject("Bu kaynakta istenen miktar yok; kuponu kesme.")
	work["parcel"] = {"item": request["item"], "amount": request["amount"], "source": source}
	return _commit(work)


func cut(state: CampaignState, item: String) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work) or work.get("stamp") != "approve":
		return _reject("Kesmeden önce SATIŞ damgası gerekli.")
	var parcel: Dictionary = work.get("parcel", {})
	if parcel.get("item", "") != item:
		return _reject("Önce müşterinin ürününü hazırla; yalnızca ilgili kuponu kes.")
	var card: Dictionary = current(state)["card"]
	if not item in card["available"] or item in work["cuts"]:
		return _reject("Bu kupon yok veya zaten kesildi.")
	if int(card.get(item, 0)) < int(parcel["amount"]):
		return _reject("Kupondaki miktar hazırlanan üründen az.")
	(work["cuts"] as Array).append(item)
	return _commit(work)


func finish(state: CampaignState, destination: String) -> Dictionary:
	var work: Dictionary = desk(state).duplicate(true)
	if not _active(work):
		return _reject("Aktif kart işlemi yok.")
	var kind: String = work.get("stamp", "")
	if kind == "" or not destination in ["return", "seize"]:
		return _reject("Önce karar damgasını bas.")
	if (destination == "seize") != (kind == "seize"):
		return _reject("Karar damgasıyla belge bölmesi uyuşmuyor.")
	var encounter: Dictionary = current(state)
	var problems: PackedStringArray = issues(encounter)
	var forged: bool = is_forged(encounter)
	var request: Dictionary = encounter["request"]
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
		"cuts": (work["cuts"] as Array).duplicate(), "marks": (work["marks"] as Array).duplicate(true), "shortage": shortage}
	(work["results"] as Array).append(result)
	work["done"] = true
	work["location"] = destination
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
	work["stamp"] = ""
	work["marks"] = []
	work["cuts"] = []
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


static func _commit(work: Dictionary, extra: Array[Dictionary] = []) -> Dictionary:
	var effects: Array[Dictionary] = [{"op": "flag_set", "key": KEY, "value": work}]
	effects.append_array(extra)
	return {"ok": true, "error": "", "effects": effects}


static func _reject(message: String) -> Dictionary:
	var effects: Array[Dictionary] = []
	return {"ok": false, "error": message, "effects": effects}
