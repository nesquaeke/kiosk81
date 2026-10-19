extends TestCase
## A detached paper fragment, its entitlement and its filing are separate facts.

var rules: RationDeskRules
var state: CampaignState


func before_each() -> void:
	rules = RationDeskRules.new(ContentDB.all_of("ration_case"))
	state = CampaignState.from_dict(rules.opening(true))


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


func _place_card() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))


func _detach(item: String = "meat") -> void:
	var left: float = 30.0 + 195.0 * RationDeskRules.PRODUCT_ORDER.find(item)
	assert_true(_apply(rules.incise(state, [[left, 285.0], [left + 180.0, 285.0],
		[left + 180.0, 375.0], [left, 375.0], [left, 285.0]])))


func _approve() -> void:
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	assert_true(_apply(rules.cut(state, "meat", true)))


func test_requested_coupon_must_be_physically_filed_before_focused_approval() -> void:
	_place_card()
	_detach()
	_approve()
	assert_true(_apply(rules.move_card(state, "hand")))
	var before: Dictionary = state.to_dict()
	var missing: Dictionary = rules.finish_review(state, "return")
	assert_false(missing["ok"])
	assert_eq(missing["effects"], [])
	assert_true(missing["error"].contains("kupon kutusuna"))
	assert_eq(state.to_dict(), before, "a missing fragment cannot commit the review")
	assert_true(_apply(rules.file_coupon(state, "meat")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var result: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_true(result["correct"])
	assert_eq(result["collected"], ["meat"])
	assert_eq(result["physical_detached"], ["meat"])


func test_filing_before_stamp_does_not_consume_entitlement_or_change_other_work() -> void:
	_place_card()
	_detach()
	var before: Dictionary = state.to_dict()
	var expected: Dictionary = before.duplicate(true)
	expected["flags"][RationDeskRules.KEY]["collected"] = ["meat"]
	assert_true(_apply(rules.file_coupon(state, "meat")))
	assert_eq(state.to_dict(), expected, "filing changes only the physical collection fact")
	assert_eq(RationDeskRules.desk(state)["cuts"], [])
	assert_eq(RationDeskRules.desk(state)["stamp"], "")
	_approve()
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	assert_true(RationDeskRules.desk(state)["results"][0]["correct"])


func test_partial_cut_and_nonphysical_contact_cannot_file_paper() -> void:
	_place_card()
	assert_true(_apply(rules.incise(state, [[30.0, 285.0], [70.0, 285.0]])))
	var before: Dictionary = state.to_dict()
	assert_false(rules.file_coupon(state, "meat")["ok"])
	assert_eq(state.to_dict(), before)
	_detach()
	before = state.to_dict()
	var command: Dictionary = rules.file_coupon(state, "meat", false)
	assert_false(command["ok"])
	assert_eq(command["effects"], [])
	assert_eq(state.to_dict(), before)


func test_unavailable_unknown_or_inactive_coupon_cannot_be_filed() -> void:
	var before: Dictionary = state.to_dict()
	assert_false(rules.file_coupon(state, "meat")["ok"])
	assert_eq(state.to_dict(), before)
	var work: Dictionary = RationDeskRules.desk(state).duplicate(true)
	work["index"] = 4 # This customer's meat coupon has already been used.
	state.flags[RationDeskRules.KEY] = work
	_place_card()
	_detach()
	before = state.to_dict()
	assert_false(rules.file_coupon(state, "meat")["ok"])
	assert_false(rules.file_coupon(state, "unknown")["ok"])
	assert_eq(state.to_dict(), before)


func test_another_filed_coupon_does_not_satisfy_requested_approval() -> void:
	_place_card()
	_detach("sugar")
	assert_true(_apply(rules.file_coupon(state, "sugar")))
	_detach("meat")
	_approve()
	assert_true(_apply(rules.move_card(state, "hand")))
	var before: Dictionary = state.to_dict()
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.file_coupon(state, "meat")))
	assert_true(_apply(rules.finish_review(state, "return")))
	assert_false(RationDeskRules.desk(state)["results"][0]["correct"], "filing cannot forgive an extra severed coupon")


func test_repeated_filing_is_atomic_and_does_not_repeat_entitlement_or_effects() -> void:
	_place_card()
	_detach()
	_approve()
	assert_true(_apply(rules.file_coupon(state, "meat")))
	var before: Dictionary = state.to_dict()
	var repeated: Dictionary = rules.file_coupon(state, "meat")
	assert_false(repeated["ok"])
	assert_eq(repeated["effects"], [])
	assert_eq(state.to_dict(), before)
	assert_eq(RationDeskRules.desk(state)["cuts"], ["meat"])
	assert_eq(RationDeskRules.desk(state)["collected"], ["meat"])


func test_json_roundtrip_keeps_filing_and_next_resets_only_current_collection() -> void:
	_place_card()
	_detach()
	_approve()
	assert_true(_apply(rules.file_coupon(state, "meat")))
	var restored: CampaignState = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(restored.to_dict(), state.to_dict())
	state = restored
	assert_false(rules.file_coupon(state, "meat")["ok"])
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var complete: Dictionary = state.to_dict()
	assert_false(rules.file_coupon(state, "meat")["ok"])
	assert_eq(state.to_dict(), complete)
	assert_true(_apply(rules.next(state)))
	var work: Dictionary = RationDeskRules.desk(state)
	assert_true(work["require_coupon_collection"])
	assert_eq(work["collected"], [])
	assert_eq(work["cuts"], [])
	assert_eq(work["incisions"], [])
	assert_eq(work["results"][0]["collected"], ["meat"])
	_place_card()
	_detach("sugar")
	assert_true(_apply(rules.file_coupon(state, "sugar")), "the next customer's own fragment is independent")
	assert_eq(RationDeskRules.desk(state)["collected"], ["sugar"])


func test_retaining_or_rejecting_after_damage_remains_possible_but_is_audited() -> void:
	for kind: String in ["reject", "seize"]:
		state = CampaignState.from_dict(rules.opening(true))
		var work: Dictionary = RationDeskRules.desk(state).duplicate(true)
		work["index"] = 3 if kind == "seize" else 2
		state.flags[RationDeskRules.KEY] = work
		_place_card()
		_detach("meat")
		assert_true(_apply(rules.file_coupon(state, "meat")))
		assert_true(_apply(rules.stamp(state, kind, Vector2(540, 190), true)))
		assert_true(_apply(rules.move_card(state, "hand")))
		assert_true(_apply(rules.finish_review(state, "seize" if kind == "seize" else "return")))
		assert_false(RationDeskRules.desk(state)["results"][0]["correct"])


func test_default_and_older_saved_review_keep_their_existing_completion_contract() -> void:
	state = CampaignState.from_dict(rules.opening())
	assert_false(RationDeskRules.desk(state)["require_coupon_collection"])
	# Older saves have neither field. New commands must use backwards-safe defaults.
	(state.flags[RationDeskRules.KEY] as Dictionary).erase("require_coupon_collection")
	(state.flags[RationDeskRules.KEY] as Dictionary).erase("collected")
	_place_card()
	_detach()
	_approve()
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	assert_true(RationDeskRules.desk(state)["results"][0]["correct"])
	assert_eq(RationDeskRules.desk(state)["results"][0]["collected"], [])


func test_full_sale_finish_keeps_its_delivery_contract_without_collection_gate() -> void:
	_place_card()
	_detach()
	_approve()
	assert_true(_apply(rules.prepare(state, "official", "meat", true)))
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_true(RationDeskRules.desk(state)["results"][0]["correct"])
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 0)
	assert_eq(state.money["till"], 5000)
