extends TestCase

var trading: KioskTrading
var state: CampaignState


func before_each() -> void:
	trading = KioskTrading.new(ContentDB.all_of("item"))
	state = CampaignState.from_dict(trading.opening())


func _apply(command: Dictionary) -> bool:
	if not command["ok"]:
		return false
	var effects: Array[Dictionary] = []
	effects.assign(command["effects"])
	var result: EffectPipeline.Result = EffectPipeline.apply(state, effects)
	assert_true(result.ok, result.error)
	if result.ok:
		state = result.state
	return result.ok


func _total(item_id: String) -> int:
	var count: int = 0
	for location: String in CampaignState.STOCK_LOCATIONS:
		count += state.stock_count(location, item_id)
	return count


func test_catalog_is_legal_and_unrationed() -> void:
	assert_eq(trading.order.size(), 12)
	assert_false("itm_tygodnik_mazowsze" in trading.order)
	assert_false("itm_cigarettes_popularne" in trading.order)
	for item_id: String in trading.order:
		assert_true(trading.items[item_id]["legal"])
		assert_false(trading.items[item_id].get("rationed", false))
	assert_false(trading.take_storage(state, "itm_tygodnik_mazowsze")["ok"])


func test_pickup_replace_and_cancel_preserve_stock_and_money() -> void:
	var before: Dictionary = state.to_dict()
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_eq(KioskTrading.located(state, "hand"), trading.order[0])
	assert_eq(state.stock_count("shelf", trading.order[0]), 0)
	assert_eq(_total(trading.order[0]), 5)
	assert_true(_apply(trading.cancel_hand(state)))
	assert_eq(state.money, before["money"])
	assert_eq(state.flags, before["flags"])
	assert_eq(state.stock["shelf"], before["stock"]["shelf"])
	assert_eq(state.stock["backroom"], before["stock"]["backroom"])
	assert_eq(KioskTrading.located(state, "hand"), "")
	assert_eq(state.register.size(), 0)


func test_product_can_be_moved_to_another_empty_slot() -> void:
	var first: String = trading.order[0]
	var second: String = trading.order[1]
	assert_true(_apply(trading.use_slot(state, 1)))
	assert_true(_apply(trading.return_storage(state, second)))
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_true(_apply(trading.use_slot(state, 1)))
	assert_eq(KioskTrading.slots(state)[0], "")
	assert_eq(KioskTrading.slots(state)[1], first)
	assert_eq(_total(first), 5)
	assert_eq(_total(second), 5)


func test_full_slot_full_hand_wrong_storage_and_invalid_slot_reject() -> void:
	assert_true(_apply(trading.use_slot(state, 0)))
	var before: Dictionary = state.to_dict()
	assert_false(trading.use_slot(state, 1)["ok"])
	assert_false(trading.take_storage(state, trading.order[1])["ok"])
	assert_false(trading.return_storage(state, trading.order[1])["ok"])
	assert_false(trading.use_slot(state, -1)["ok"])
	assert_false(trading.use_slot(state, 12)["ok"])
	assert_eq(state.to_dict(), before)


func test_empty_storage_rejects_without_phantom_product() -> void:
	state.stock["backroom"][trading.order[0]] = 0
	var before: Dictionary = state.to_dict()
	assert_false(trading.take_storage(state, trading.order[0])["ok"])
	assert_eq(state.to_dict(), before)


func test_pipeline_rejects_overfilled_hand_and_tray_atomically() -> void:
	for location: String in ["hand", "counter"]:
		var effects: Array[Dictionary] = [
			{"op": "stock_move", "from": "shelf", "to": location, "item": trading.order[0], "qty": 1},
			{"op": "stock_move", "from": "shelf", "to": location, "item": trading.order[1], "qty": 1},
		]
		assert_false(EffectPipeline.apply(state, effects).ok)
		assert_eq(state.stock_count("shelf", trading.order[0]), 1)
		assert_eq(KioskTrading.located(state, location), "")


func test_storage_to_display_and_storage_cancel() -> void:
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_true(_apply(trading.return_storage(state, trading.order[0])))
	assert_true(_apply(trading.take_storage(state, trading.order[1])))
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_eq(KioskTrading.slots(state)[0], trading.order[1])
	assert_eq(state.stock_count("shelf", trading.order[1]), 2)
	var before: Dictionary = state.to_dict()
	assert_true(_apply(trading.take_storage(state, trading.order[0])))
	assert_true(_apply(trading.cancel_hand(state)))
	assert_eq(state.to_dict(), before)


func test_tray_is_reversible_and_rejects_second_product() -> void:
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_true(_apply(trading.use_tray(state)))
	assert_eq(KioskTrading.located(state, "hand"), "")
	assert_eq(KioskTrading.located(state, "counter"), trading.order[0])
	assert_true(_apply(trading.use_slot(state, 1)))
	assert_false(trading.use_tray(state)["ok"])
	assert_true(_apply(trading.cancel_hand(state)))
	assert_true(_apply(trading.use_tray(state)))
	assert_true(_apply(trading.cancel_hand(state)))
	assert_eq(KioskTrading.located(state, "counter"), trading.order[0])
	assert_eq(state.money["till"], 2000)
	assert_eq(_total(trading.order[0]), 5)


func test_wrong_product_or_empty_tray_cannot_be_sold() -> void:
	assert_false(trading.sell(state)["ok"])
	assert_true(_apply(trading.use_slot(state, 1)))
	assert_true(_apply(trading.use_tray(state)))
	var before: Dictionary = state.to_dict()
	assert_false(trading.sell(state)["ok"])
	assert_eq(state.to_dict(), before)


func test_sale_changes_stock_cash_and_register_once() -> void:
	var item_id: String = trading.order[0]
	var price: int = trading.items[item_id]["price"]
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_true(_apply(trading.use_tray(state)))
	var command: Dictionary = trading.sell(state)
	assert_true(_apply(command))
	assert_eq(_total(item_id), 4)
	assert_eq(state.money["till"], 2000 + price)
	assert_eq(state.register.size(), 1)
	assert_eq(state.register[0]["item"], item_id)
	assert_eq(state.register[0]["qty"], 1)
	assert_eq(trading.requested(state), trading.order[1])
	assert_false(trading.sell(state)["ok"])
	var stale: Array[Dictionary] = []
	stale.assign(command["effects"])
	assert_false(EffectPipeline.apply(state, stale).ok, "even a stale repeated sale must be atomic")
	assert_eq(state.money["till"], 2000 + price)


func test_layout_hand_and_staged_sale_survive_json_roundtrip() -> void:
	assert_true(_apply(trading.use_slot(state, 0)))
	assert_true(_apply(trading.use_tray(state)))
	assert_true(_apply(trading.use_slot(state, 1)))
	var restored: CampaignState = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(restored.to_dict(), state.to_dict())
	assert_true(trading.cancel_hand(restored)["ok"])
	assert_true(trading.sell(restored)["ok"])


func test_complete_customer_sequence_records_exact_revenue() -> void:
	var total: int = 0
	for i: int in trading.order.size():
		var item_id: String = trading.order[i]
		total += int(trading.items[item_id]["price"])
		assert_true(_apply(trading.use_slot(state, i)))
		assert_true(_apply(trading.use_tray(state)))
		assert_true(_apply(trading.sell(state)))
		assert_eq(_total(item_id), 4)
	assert_eq(state.money["till"], 2000 + total)
	assert_eq(state.register.size(), 12)
	assert_eq(trading.requested(state), "")
	assert_false(trading.sell(state)["ok"])
