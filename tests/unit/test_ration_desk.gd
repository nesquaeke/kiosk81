extends TestCase

var rules: RationDeskRules
var state: CampaignState


func before_each() -> void:
	rules = RationDeskRules.new(ContentDB.all_of("ration_case"))
	state = CampaignState.from_dict(rules.opening())


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


func _case(index: int) -> void:
	var data: Dictionary = RationDeskRules.desk(state).duplicate(true)
	data["index"] = index
	state.flags[RationDeskRules.KEY] = data


func _stamp(kind: String) -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.stamp(state, kind, Vector2(540, 190))))


func test_content_has_eight_solvable_cases_with_positive_amounts() -> void:
	assert_eq(rules.cases.size(), 8)
	for encounter: Dictionary in rules.cases:
		assert_true(int(encounter["request"]["amount"]) > 0)
		assert_true(encounter["request"]["item"] in RationDeskRules.PRODUCT_ORDER)
		assert_true(encounter["card"]["class"] in RationDeskRules.CLASSES)
	assert_true(RationDeskRules.issues(rules.cases[0]).is_empty())
	assert_true(RationDeskRules.issues(rules.cases[1]).is_empty(), "wear does not invalidate a card")


func test_expired_missing_seal_and_used_coupon_are_not_forgery() -> void:
	for index: int in [2, 4, 6]:
		assert_false(RationDeskRules.issues(rules.cases[index]).is_empty())
		assert_false(RationDeskRules.is_forged(rules.cases[index]))
	for index: int in [3, 5]:
		assert_true(RationDeskRules.is_forged(rules.cases[index]))


func test_card_must_be_on_desk_before_tools_work() -> void:
	var before: Dictionary = state.to_dict()
	assert_false(rules.stamp(state, "approve", Vector2(540, 190))["ok"])
	assert_false(rules.prepare(state, "official")["ok"])
	assert_false(rules.cut(state, "meat")["ok"])
	assert_false(rules.finish(state, "return")["ok"])
	assert_false(rules.next(state)["ok"])
	assert_eq(state.to_dict(), before)


func test_stamp_location_and_kind_are_validated() -> void:
	assert_true(_apply(rules.take(state)))
	assert_false(rules.stamp(state, "approve", Vector2(100, 100))["ok"])
	assert_false(rules.stamp(state, "unknown", Vector2(540, 190))["ok"])
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190))))
	assert_eq(RationDeskRules.desk(state)["marks"].size(), 1)


func test_cut_requires_preparation_and_matches_request() -> void:
	_stamp("approve")
	assert_false(rules.cut(state, "meat")["ok"])
	assert_true(_apply(rules.prepare(state, "official")))
	assert_false(rules.cut(state, "sugar")["ok"])
	assert_true(_apply(rules.cut(state, "meat")))
	assert_false(rules.cut(state, "meat")["ok"])
	assert_eq(RationDeskRules.desk(state)["cuts"], ["meat"])


func test_preparation_reserves_without_spending_stock() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.prepare(state, "official")))
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(state.money["till"], 2000)
	assert_eq(state.register.size(), 0)


func test_delivery_updates_grams_money_and_book_exactly_once() -> void:
	_stamp("approve")
	assert_false(rules.finish(state, "return")["ok"])
	assert_true(_apply(rules.prepare(state, "official")))
	assert_false(rules.finish(state, "return")["ok"])
	assert_true(_apply(rules.cut(state, "meat")))
	assert_true(_apply(rules.finish(state, "return")))
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 0)
	assert_eq(state.money["till"], 5000)
	assert_eq(state.register.size(), 1)
	assert_eq(state.register[0]["amount"], 750)
	assert_true(RationDeskRules.desk(state)["results"][0]["correct"])
	var before: Dictionary = state.to_dict()
	assert_false(rules.finish(state, "return")["ok"])
	assert_eq(state.to_dict(), before)


func test_destination_must_match_stamp() -> void:
	_stamp("reject")
	assert_false(rules.finish(state, "seize")["ok"])
	assert_true(_apply(rules.finish(state, "return")))
	assert_false(RationDeskRules.desk(state)["results"][0]["correct"], "rejecting a valid stocked card is a mistake")


func test_confiscation_can_be_wrong_and_is_audited() -> void:
	_stamp("seize")
	assert_true(_apply(rules.finish(state, "seize")))
	assert_false(RationDeskRules.desk(state)["results"][0]["correct"])
	assert_eq(state.money["till"], 2000)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(state.meters["suspicion"], 8)


func test_forgery_is_not_auto_blocked_but_approval_has_consequences() -> void:
	_case(3)
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.cut(state, "meat")))
	assert_true(_apply(rules.finish(state, "return")))
	assert_false(RationDeskRules.desk(state)["results"][0]["correct"])
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 250)
	assert_eq(state.meters["suspicion"], 13)


func test_no_stock_no_preparation_or_coupon_loss() -> void:
	_case(7)
	var data: Dictionary = RationDeskRules.desk(state).duplicate(true)
	data["official"]["meat"] = 0
	state.flags[RationDeskRules.KEY] = data
	_stamp("approve")
	assert_false(rules.prepare(state, "official")["ok"])
	assert_false(rules.cut(state, "meat")["ok"])
	assert_eq(RationDeskRules.desk(state)["cuts"], [])
	assert_true(_apply(rules.stamp(state, "reject", Vector2(540, 190))))
	assert_true(_apply(rules.finish(state, "return")))
	assert_true(RationDeskRules.desk(state)["results"][0]["correct"])


func test_hidden_stock_reduces_separately_and_goes_to_pocket() -> void:
	_case(7)
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "hidden")))
	assert_true(_apply(rules.cut(state, "meat")))
	assert_true(_apply(rules.finish(state, "return")))
	assert_eq(RationDeskRules.desk(state)["hidden"]["meat"], 250)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(state.money["pocket"], 1000)
	assert_eq(state.money["till"], 2000)
	assert_eq(state.register.size(), 0)
	assert_eq(state.meters["suspicion"], 9)


func test_stock_is_rechecked_at_delivery() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.cut(state, "meat")))
	var data: Dictionary = RationDeskRules.desk(state).duplicate(true)
	data["official"]["meat"] = 0
	state.flags[RationDeskRules.KEY] = data
	assert_false(rules.finish(state, "return")["ok"])
	assert_eq(state.money["till"], 2000)
	assert_eq(state.register.size(), 0)


func test_json_roundtrip_keeps_marks_cuts_prepared_product_and_stock() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.cut(state, "meat")))
	var restored: CampaignState = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(restored.to_dict(), state.to_dict())
	assert_true(rules.finish(restored, "return")["ok"])
	assert_false(rules.cut(restored, "meat")["ok"])


func test_next_customer_keeps_audit_but_resets_paper_state() -> void:
	_case(3)
	_stamp("seize")
	assert_true(_apply(rules.finish(state, "seize")))
	assert_true(_apply(rules.next(state)))
	assert_eq(RationDeskRules.desk(state)["index"], 4)
	assert_eq(RationDeskRules.desk(state)["results"].size(), 1)
	assert_eq(RationDeskRules.desk(state)["marks"], [])
	assert_eq(RationDeskRules.desk(state)["cuts"], [])
	assert_eq(RationDeskRules.desk(state)["parcel"], {})
