extends TestCase
## EffectPipeline: atomic changes and invariants (roadmap 1.6).

var state: CampaignState


func before_each() -> void:
	state = CampaignState.new()
	state.phase = "shift"
	state.minute_of_day = 600
	state.stock["shelf"]["itm_cigarettes"] = 5
	state.stock["backroom"]["itm_cigarettes"] = 10


func _apply(effects: Array[Dictionary]) -> EffectPipeline.Result:
	return EffectPipeline.apply(state, effects)


func test_money_add() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "money_add", "account": "till", "amount": 1290}])
	assert_true(r.ok, r.error)
	assert_eq(r.state.money["till"], 1290)


func test_original_state_is_never_mutated() -> void:
	var before: Dictionary = state.to_dict()
	var r: EffectPipeline.Result = _apply([{"op": "money_add", "account": "till", "amount": 1290}])
	assert_true(r.ok, r.error)
	assert_eq(state.to_dict(), before, "apply works on a copy")


func test_sale_updates_stock_till_and_register() -> void:
	# The shape of AC-03: shelf -1, till +price, one register line.
	var r: EffectPipeline.Result = _apply([
		{"op": "stock_add", "location": "shelf", "item": "itm_cigarettes", "qty": -1},
		{"op": "money_add", "account": "till", "amount": 1290},
		{"op": "register_append", "entry": {"item": "itm_cigarettes", "qty": 1, "price": 1290}},
	])
	assert_true(r.ok, r.error)
	assert_eq(r.state.stock_count("shelf", "itm_cigarettes"), 4)
	assert_eq(r.state.money["till"], 1290)
	assert_eq(r.state.register.size(), 1)
	assert_eq(r.state.register[0]["day"], 1)
	assert_eq(r.state.register[0]["minute"], 600)


func test_selling_from_empty_shelf_is_rejected() -> void:
	# The shape of AC-04: nothing changes when the item is not there.
	state.stock["shelf"]["itm_cigarettes"] = 0
	var before: Dictionary = state.to_dict()
	var r: EffectPipeline.Result = _apply([
		{"op": "stock_add", "location": "shelf", "item": "itm_cigarettes", "qty": -1},
		{"op": "money_add", "account": "till", "amount": 1290},
	])
	assert_false(r.ok)
	assert_true(r.error.begins_with("invariant"), r.error)
	assert_eq(state.to_dict(), before)


func test_all_or_nothing() -> void:
	# The shape of AC-05: a bad second effect cancels the first one too.
	var r: EffectPipeline.Result = _apply([
		{"op": "money_add", "account": "till", "amount": 1290},
		{"op": "stock_move", "from": "backroom", "to": "shelf", "item": "itm_cigarettes", "qty": 99},
	])
	assert_false(r.ok)
	assert_eq(r.op_index, 1)
	assert_eq(r.state, null, "no new state on failure")
	assert_eq(state.money["till"], 0)


func test_negative_money_is_rejected() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "money_add", "account": "pocket", "amount": -1}])
	assert_false(r.ok)


func test_stock_move() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "stock_move", "from": "backroom", "to": "shelf", "item": "itm_cigarettes", "qty": 3}])
	assert_true(r.ok, r.error)
	assert_eq(r.state.stock_count("backroom", "itm_cigarettes"), 7)
	assert_eq(r.state.stock_count("shelf", "itm_cigarettes"), 8)


func test_unknown_op_is_rejected() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "teleport"}])
	assert_false(r.ok)
	assert_true(r.error.contains("unknown op"), r.error)


func test_missing_field_is_rejected() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "money_add", "account": "till"}])
	assert_false(r.ok)
	assert_true(r.error.contains("missing field 'amount'"), r.error)


func test_wrong_type_is_rejected() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "money_add", "account": "till", "amount": "12.90"}])
	assert_false(r.ok)
	assert_true(r.error.contains("wrong type"), r.error)


func test_clock_cannot_pass_midnight() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "clock_advance", "minutes": 900}])
	assert_false(r.ok)
	var ok: EffectPipeline.Result = _apply([{"op": "clock_advance", "minutes": 15}])
	assert_true(ok.ok, ok.error)
	assert_eq(ok.state.minute_of_day, 615)


func test_relation_and_memory() -> void:
	var r: EffectPipeline.Result = _apply([
		{"op": "relation_add", "character": "chr_old_woman", "dimension": "trust", "amount": 2},
		{"op": "memory_add", "character": "chr_old_woman", "memory": {"type": "refused"}},
	])
	assert_true(r.ok, r.error)
	var who: Dictionary = r.state.characters["chr_old_woman"]
	assert_eq(who["relations"]["trust"], 2)
	assert_eq((who["memories"] as Array)[0]["type"], "refused")
	assert_eq((who["memories"] as Array)[0]["day"], 1)


func test_unknown_relation_is_rejected() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "relation_add", "character": "chr_x", "dimension": "love", "amount": 1}])
	assert_false(r.ok)


func test_unknown_phase_is_rejected() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "phase_set", "phase": "lunch"}])
	assert_false(r.ok)


# ---------------------------------------------------------------- "when" (roadmap 1.7)

func _when_low_stock() -> Dictionary:
	return {
		"op": "when",
		"if": {"if": "stock", "location": "shelf", "item": "itm_cigarettes", "cmp": "<", "value": 3},
		"then": [{"op": "stock_move", "from": "backroom", "to": "shelf", "item": "itm_cigarettes", "qty": 5}],
		"else": [{"op": "flag_set", "key": "shelf_ok", "value": true}],
	}


func test_when_takes_else_branch() -> void:
	var r: EffectPipeline.Result = _apply([_when_low_stock()])
	assert_true(r.ok, r.error)
	assert_eq(r.state.flags.get("shelf_ok"), true)
	assert_eq(r.state.stock_count("shelf", "itm_cigarettes"), 5)


func test_when_sees_earlier_effects_in_the_list() -> void:
	# Selling 3 leaves 2 on the shelf, so the restock branch runs.
	var r: EffectPipeline.Result = _apply([
		{"op": "stock_add", "location": "shelf", "item": "itm_cigarettes", "qty": -3},
		_when_low_stock(),
	])
	assert_true(r.ok, r.error)
	assert_eq(r.state.stock_count("shelf", "itm_cigarettes"), 7)
	assert_eq(r.state.stock_count("backroom", "itm_cigarettes"), 5)
	assert_false(r.state.flags.has("shelf_ok"))


func test_when_without_else_does_nothing_when_false() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "when", "if": false, "then": [{"op": "money_add", "account": "till", "amount": 5}]}])
	assert_true(r.ok, r.error)
	assert_eq(r.state.money["till"], 0)


func test_when_with_broken_condition_rejects_everything() -> void:
	var r: EffectPipeline.Result = _apply([
		{"op": "money_add", "account": "till", "amount": 100},
		{"op": "when", "if": {"if": "day", "cmp": ">="}, "then": []},
	])
	assert_false(r.ok)
	assert_true(r.error.contains("condition"), r.error)
	assert_eq(state.money["till"], 0, "original untouched")


func test_when_branch_errors_name_the_step() -> void:
	var r: EffectPipeline.Result = _apply([{"op": "when", "if": true, "then": [{"op": "money_add", "account": "till", "amount": -1}]}])
	assert_false(r.ok, "negative till breaks the invariant")
	var bad: EffectPipeline.Result = _apply([{"op": "when", "if": true, "then": [{"op": "teleport"}]}])
	assert_true(bad.error.contains("then[0] (teleport)"), bad.error)
