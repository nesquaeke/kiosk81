extends TestCase

const DECISIONS: PackedStringArray = ["approve", "seize", "seize", "seize", "seize", "reject", "approve", "seize"]

var records: Array[Dictionary] = []
var rules: RationDeskRules
var state: CampaignState


func before_each() -> void:
	records.assign(ContentDB.all_of("ration_review_case"))
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])


func test_focused_content_adds_eight_visible_cases_without_replacing_legacy_sales() -> void:
	assert_eq(records.size(), 8)
	assert_eq(ContentDB.all_of("ration_case").size(), 8)
	for index: int in range(records.size()):
		var encounter: Dictionary = records[index]
		assert_eq(encounter["id"], "rc_%02d" % (index + 9))
		assert_true(encounter.has("identity"))
		assert_true(encounter["card"].has("evidence"))
		assert_true(int(encounter["request"]["amount"]) > 0)
		assert_eq(_expected(encounter), DECISIONS[index])


func test_optional_evidence_does_not_change_any_original_case_verdict() -> void:
	var legacy: Array[Dictionary] = []
	legacy.assign(ContentDB.all_of("ration_case"))
	legacy.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	var expected: PackedStringArray = ["approve", "approve", "reject", "seize", "reject", "seize", "reject", "approve"]
	for index: int in range(legacy.size()):
		assert_true(RationEvidence.inspect(legacy[index]).is_empty())
		assert_eq(_expected(legacy[index]), expected[index])


func test_date_forgery_requires_different_visible_underprint_not_scraped_paper() -> void:
	var encounter: Dictionary = records[1].duplicate(true)
	assert_true(_codes(encounter).has("altered_month"))
	assert_true(RationDeskRules.is_forged(encounter))
	encounter["card"]["evidence"]["date"]["underprint_month"] = "1982-02"
	assert_true(RationDeskRules.issues(encounter).is_empty(), "a scrape with the same retyped month is not a changed date")
	encounter["card"]["evidence"]["date"]["abrasion"] = 1.0
	assert_false(RationDeskRules.is_forged(encounter))


func test_photo_attachment_is_legal_until_the_crossing_seal_is_discontinuous() -> void:
	var encounter: Dictionary = records[2].duplicate(true)
	assert_true(_codes(encounter).has("portrait_seal"))
	encounter["card"]["evidence"]["portrait"]["seal_offset"] = [2, 0]
	assert_false(RationDeskRules.is_forged(encounter), "within print registration tolerance")
	assert_true(RationDeskRules.issues(encounter).is_empty())
	encounter["card"]["evidence"]["portrait"]["seal_offset"] = [2.01, 0]
	assert_true(RationDeskRules.is_forged(encounter))
	encounter["card"]["evidence"]["portrait"]["seal_offset"] = [0, 0]
	encounter["card"]["evidence"]["portrait"]["pasted"] = true
	assert_true(RationDeskRules.issues(encounter).is_empty(), "a pasted photo alone is normal document construction")


func test_identity_compares_printed_name_and_number_independently() -> void:
	var encounter: Dictionary = records[3].duplicate(true)
	assert_true(_codes(encounter).has("identity_holder"))
	assert_true(_codes(encounter).has("identity_number"))
	encounter["identity"]["holder"] = encounter["card"]["holder"]
	assert_false(_codes(encounter).has("identity_holder"))
	assert_true(_codes(encounter).has("identity_number"))
	encounter["identity"]["number"] = "  " + str(encounter["card"]["identity_number"]).to_lower() + " "
	assert_true(RationDeskRules.issues(encounter).is_empty(), "case and surrounding whitespace are not discrepancies")
	encounter.erase("identity")
	assert_false(RationDeskRules.is_forged(encounter), "missing optional ID on old content cannot become a secret mismatch")


func test_different_visible_portraits_are_evidence_only_when_both_documents_have_photos() -> void:
	var encounter: Dictionary = records[7].duplicate(true)
	assert_eq(_codes(encounter), PackedStringArray(["identity_portrait"]))
	assert_true(RationDeskRules.is_forged(encounter))
	encounter["identity"]["portrait_variant"] = encounter["card"]["portrait_variant"]
	assert_true(RationDeskRules.issues(encounter).is_empty())
	encounter["identity"].erase("portrait_variant")
	assert_false(RationDeskRules.is_forged(encounter))


func test_portrait_evidence_matches_the_rendered_variant_instead_of_hidden_raw_ids() -> void:
	var encounter: Dictionary = records[0].duplicate(true)
	encounter["card"]["portrait_variant"] = 0
	encounter["identity"]["portrait_variant"] = 8
	assert_eq(RationEvidence.portrait_key(0), RationEvidence.portrait_key(8))
	assert_true(RationDeskRules.issues(encounter).is_empty(), "both papers render the same visible portrait")
	assert_false(RationDeskRules.is_forged(encounter))
	encounter["identity"]["portrait_variant"] = -8
	assert_false(RationDeskRules.is_forged(encounter), "negative aliases are the same visible portrait too")
	encounter["identity"]["portrait_variant"] = 9
	assert_true(RationDeskRules.is_forged(encounter), "a different rendered portrait remains evidence")


func test_coupon_serial_proves_substitution_but_adhesive_seams_do_not() -> void:
	var encounter: Dictionary = records[4].duplicate(true)
	assert_eq(_codes(encounter), PackedStringArray(["coupon_serial_meat"]))
	assert_true(RationDeskRules.is_forged(encounter))
	encounter["card"]["evidence"]["coupons"]["meat"]["serial"] = encounter["card"]["serial"]
	assert_true(encounter["card"]["evidence"]["coupons"]["meat"]["reattached"])
	assert_true(RationDeskRules.issues(encounter).is_empty(), "matching repaired paper is not automatically counterfeit")
	encounter["card"]["evidence"]["coupons"]["soap"]["serial"] = "E-00000"
	assert_true(RationDeskRules.is_forged(encounter), "any visible available coupon can reveal substitution")
	encounter["card"]["available"].erase("soap")
	assert_false(RationDeskRules.is_forged(encounter), "an absent coupon has no visible paper serial to inspect")


func test_previous_issue_invalidates_only_requested_entitlement_without_inventing_forgery() -> void:
	var encounter: Dictionary = records[5].duplicate(true)
	assert_eq(_codes(encounter), PackedStringArray(["coupon_issued_sugar"]))
	assert_eq(_expected(encounter), "reject")
	assert_false(RationDeskRules.is_forged(encounter))
	encounter["request"] = {"item": "soap", "amount": 1}
	assert_true(RationDeskRules.issues(encounter).is_empty(), "using sugar does not invalidate a remaining soap entitlement")


func test_wear_ink_paste_stock_and_repaired_paper_are_not_authenticity_inputs() -> void:
	var encounter: Dictionary = records[6].duplicate(true)
	assert_true(RationDeskRules.issues(encounter).is_empty())
	encounter["card"]["paper_wear"] = 1.0
	encounter["card"]["paper_stock"] = "thick"
	encounter["card"]["evidence"]["ink_variation"] = {"density": 0.1, "unevenness": 1.0}
	encounter["card"]["evidence"]["date"]["abrasion"] = 1.0
	assert_true(RationDeskRules.issues(encounter).is_empty())
	assert_false(RationDeskRules.is_forged(encounter))


func test_authenticity_ignores_hidden_answer_booleans_and_inspection_never_mutates_content() -> void:
	var encounter: Dictionary = records[0].duplicate(true)
	encounter["forged"] = true
	encounter["card"]["forged"] = true
	encounter["card"]["evidence"]["forged"] = true
	var before: Dictionary = encounter.duplicate(true)
	assert_false(RationDeskRules.is_forged(encounter))
	assert_true(RationDeskRules.issues(encounter).is_empty())
	assert_eq(encounter, before)
	encounter = records[1].duplicate(true)
	encounter["forged"] = false
	encounter["card"]["forged"] = false
	assert_true(RationDeskRules.is_forged(encounter), "printed mismatch overrides any untrusted answer flag")


func test_all_new_cases_allow_correct_physical_reviews_without_goods_or_payment() -> void:
	for index: int in range(records.size()):
		_open(records[index])
		var money_before: Dictionary = state.money.duplicate(true)
		var stock_before: Dictionary = state.stock.duplicate(true)
		_complete(DECISIONS[index])
		var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
		assert_true(audit["correct"], str(records[index]["id"]))
		assert_true(audit["document_review"])
		assert_eq(state.money, money_before)
		assert_eq(state.stock, stock_before)
		assert_eq(state.register.size(), 0)
		assert_eq(audit["revenue"], 0)
		assert_eq(audit["issues"], Array(RationDeskRules.issues(records[index])))


func test_wrong_physical_decisions_remain_possible_and_are_audited_after_handoff() -> void:
	for index: int in range(records.size()):
		_open(records[index])
		var wrong: String = "approve" if DECISIONS[index] == "seize" else "seize"
		_complete(wrong)
		var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
		assert_false(audit["correct"], "wrong decision remains executable: " + str(records[index]["id"]))
		assert_eq(audit["decision"], wrong)
		assert_eq(state.register.size(), 0)


func test_json_round_trip_preserves_evidence_verdicts_and_completion_is_idempotent() -> void:
	for index: int in range(records.size()):
		var restored: Dictionary = CampaignState.normalize_numbers(JSON.parse_string(JSON.stringify(records[index])))
		assert_eq(restored, records[index])
		assert_eq(RationEvidence.inspect(restored), RationEvidence.inspect(records[index]))
		_open(restored)
		_complete(DECISIONS[index])
		state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
		var completed: Dictionary = state.to_dict()
		var destination: String = "seize" if DECISIONS[index] == "seize" else "return"
		assert_false(rules.finish_review(state, destination)["ok"])
		assert_eq(state.to_dict(), completed)
		assert_eq(state.decision_log.size(), 1)
		assert_eq(RationDeskRules.desk(state)["results"].size(), 1)


func _codes(encounter: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for finding: Dictionary in RationEvidence.inspect(encounter):
		out.append(finding["code"])
	return out


func _expected(encounter: Dictionary) -> String:
	if RationDeskRules.is_forged(encounter):
		return "seize"
	return "approve" if RationDeskRules.issues(encounter).is_empty() else "reject"


func _open(encounter: Dictionary) -> void:
	rules = RationDeskRules.new([encounter])
	state = CampaignState.from_dict(rules.opening())


func _complete(kind: String) -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.stamp(state, kind, Vector2(540, 190), true)), "evidence must not gate the chosen stamp")
	if kind == "approve":
		var item: String = rules.current(state)["request"]["item"]
		var left: float = 30.0 + 195.0 * RationDeskRules.PRODUCT_ORDER.find(item)
		assert_true(_apply(rules.incise(state, [[left, 285.0], [left + 180.0, 285.0],
			[left + 180.0, 375.0], [left, 375.0], [left, 285.0]])))
		assert_true(_apply(rules.cut(state, item, true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "seize" if kind == "seize" else "return")))


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
