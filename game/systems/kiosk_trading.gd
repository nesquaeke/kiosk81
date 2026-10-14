class_name KioskTrading
extends RefCounted
## Pure commands; Game applies the returned effects atomically.
## One unit per display slot, hand and sale tray. All locations are saved.

const SLOTS_KEY: String = "kiosk_slots"
const ORDER_KEY: String = "kiosk_order"
const ORIGIN_KEY: String = "kiosk_origin"
const SLOT_COUNT: int = 12

var items: Dictionary = {}
var order: PackedStringArray = []


func _init(records: Array) -> void:
	for record: Dictionary in records:
		items[record["id"]] = record
	for spec: Dictionary in KioskCatalog.PRODUCTS:
		var record: Dictionary = items.get(spec["id"], {})
		if not record.is_empty() and record.get("legal", false) and not record.get("rationed", false):
			order.append(spec["id"])


func opening() -> Dictionary:
	var shelf: Dictionary = {}
	var backroom: Dictionary = {}
	var slots: Array[String] = []
	for item_id: String in order:
		backroom[item_id] = 4
		if slots.size() < SLOT_COUNT:
			shelf[item_id] = 1
			slots.append(item_id)
	while slots.size() < SLOT_COUNT:
		slots.append("")
	return {"calendar_date": "1982-02-15", "phase": "shift", "money": {"till": 2000},
		"stock": {"shelf": shelf, "backroom": backroom},
		"flags": {SLOTS_KEY: slots, ORDER_KEY: 0, ORIGIN_KEY: ""}}


func requested(state: CampaignState) -> String:
	var index: int = int(state.flags.get(ORDER_KEY, 0))
	return order[index] if index >= 0 and index < order.size() else ""


static func located(state: CampaignState, location: String) -> String:
	for item_id: String in state.stock.get(location, {}):
		if state.stock_count(location, item_id) > 0:
			return item_id
	return ""


static func slots(state: CampaignState) -> Array:
	return state.flags.get(SLOTS_KEY, [])


func take_storage(state: CampaignState, item_id: String) -> Dictionary:
	if not item_id in order:
		return _reject("Bu ürün satış seçkisinde değil.")
	if located(state, "hand") != "":
		return _reject("Önce elindeki ürünü bırak.")
	if state.stock_count("backroom", item_id) <= 0:
		return _reject("Depo kutusu boş.")
	return _ok([_move("backroom", "hand", item_id), _flag(ORIGIN_KEY, "backroom")])


func use_slot(state: CampaignState, index: int) -> Dictionary:
	var layout: Array = slots(state).duplicate()
	if index < 0 or index >= layout.size():
		return _reject("Geçersiz tezgâh yeri.")
	var held: String = located(state, "hand")
	var displayed: String = str(layout[index])
	if held != "":
		if displayed != "":
			return _reject("Bu yer dolu. Boş bir yere bırak.")
		layout[index] = held
		return _ok([_move("hand", "shelf", held), _flag(SLOTS_KEY, layout), _flag(ORIGIN_KEY, "")])
	if displayed == "":
		return _reject("Bu yer boş; depodan bir ürün al.")
	layout[index] = ""
	return _ok([_move("shelf", "hand", displayed), _flag(SLOTS_KEY, layout), _flag(ORIGIN_KEY, index)])


func return_storage(state: CampaignState, item_id: String) -> Dictionary:
	if located(state, "hand") != item_id:
		return _reject("Ürünü kendi depo kutusuna geri bırak.")
	return _ok([_move("hand", "backroom", item_id), _flag(ORIGIN_KEY, "")])


func use_tray(state: CampaignState) -> Dictionary:
	var held: String = located(state, "hand")
	var staged: String = located(state, "counter")
	if held != "" and staged != "":
		return _reject("Satış tablası dolu.")
	if held != "":
		return _ok([_move("hand", "counter", held), _flag(ORIGIN_KEY, "")])
	if staged != "":
		return _ok([_move("counter", "hand", staged), _flag(ORIGIN_KEY, "counter")])
	return _reject("Satış tablasına bir ürün bırak.")


func cancel_hand(state: CampaignState) -> Dictionary:
	var held: String = located(state, "hand")
	if held == "":
		return _reject("Elinde ürün yok.")
	var origin: Variant = state.flags.get(ORIGIN_KEY, "backroom")
	if typeof(origin) == TYPE_INT:
		return use_slot(state, int(origin))
	if origin == "counter":
		return use_tray(state)
	return return_storage(state, held)


func sell(state: CampaignState) -> Dictionary:
	var want: String = requested(state)
	var staged: String = located(state, "counter")
	if want == "":
		return _reject("Bugünkü müşteri sırası bitti.")
	if staged != want:
		return _reject("Müşterinin istediği ürünü satış tablasına koy.")
	var record: Dictionary = items.get(staged, {})
	if not record.get("legal", false) or record.get("rationed", false):
		return _reject("Bu satış için gerekli izin/karne akışı yok.")
	var price: int = int(record.get("price", 0))
	return _ok([
		{"op": "stock_add", "location": "counter", "item": staged, "qty": -1},
		{"op": "money_add", "account": "till", "amount": price},
		{"op": "register_append", "entry": {"item": staged, "qty": 1, "price": price, "kiosk": true}},
		_flag(ORDER_KEY, int(state.flags.get(ORDER_KEY, 0)) + 1),
		{"op": "clock_advance", "minutes": 1},
	])


static func _move(from: String, to: String, item_id: String) -> Dictionary:
	return {"op": "stock_move", "from": from, "to": to, "item": item_id, "qty": 1}


static func _flag(key: String, value: Variant) -> Dictionary:
	return {"op": "flag_set", "key": key, "value": value}


static func _ok(effects: Array[Dictionary]) -> Dictionary:
	return {"ok": true, "error": "", "effects": effects}


static func _reject(message: String) -> Dictionary:
	var empty: Array[Dictionary] = []
	return {"ok": false, "error": message, "effects": empty}
