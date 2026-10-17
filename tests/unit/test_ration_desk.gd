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


func _incise_perimeter(item: String) -> void:
	var index: int = RationDeskRules.PRODUCT_ORDER.find(item)
	var left: float = 30.0 + 195.0 * index
	assert_true(_apply(rules.incise(state, [[left, 285.0], [left + 180.0, 285.0],
		[left + 180.0, 375.0], [left, 375.0], [left, 285.0]])))


func _physical_stamp(kind: String) -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.stamp(state, kind, Vector2(540, 190), true)))


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


func test_cut_precedes_goods_and_matches_request() -> void:
	_stamp("approve")
	assert_false(rules.prepare(state, "official", "meat", true)["ok"])
	assert_false(rules.cut(state, "sugar")["ok"])
	assert_true(_apply(rules.cut(state, "meat")))
	assert_false(rules.cut(state, "meat")["ok"])
	assert_eq(RationDeskRules.desk(state)["cuts"], ["meat"])
	assert_eq(RationDeskRules.desk(state)["parcel"], {})
	assert_true(_apply(rules.prepare(state, "official", "meat", true)))


func test_preparation_reserves_without_spending_stock() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	var prepared: Dictionary = state.to_dict()
	assert_false(rules.prepare(state, "official")["ok"])
	assert_false(rules.prepare(state, "hidden")["ok"])
	assert_eq(state.to_dict(), prepared)
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
	data["hidden"]["meat"] = 0
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


func test_fps_card_placement_controls_physical_tools() -> void:
	assert_true(_apply(rules.take(state)))
	assert_eq(RationDeskRules.desk(state)["placement"], "hand")
	assert_false(rules.stamp(state, "approve", Vector2(540, 190), true)["ok"])
	assert_false(rules.move_card(state, "teleport")["ok"])
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	assert_true(_apply(rules.prepare(state, "official", "meat")))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))


func test_fps_wrong_shelf_does_not_reserve_another_product() -> void:
	_stamp("approve")
	assert_false(rules.prepare(state, "official", "soap")["ok"])
	assert_eq(RationDeskRules.desk(state)["parcel"], {})
	assert_eq(RationDeskRules.desk(state)["official"]["soap"], 4)


func test_fps_product_must_be_carried_and_cut_before_handoff() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_false(rules.deliver_parcel(state)["ok"])
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_false(rules.deliver_parcel(state)["ok"])
	assert_true(_apply(rules.cut(state, "meat")))
	assert_true(_apply(rules.move_parcel(state, "table")))
	assert_false(rules.deliver_parcel(state)["ok"])
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	assert_false(rules.deliver_parcel(state)["ok"])
	assert_false(rules.move_parcel(state, "hand")["ok"])
	assert_false(rules.prepare(state, "hidden")["ok"])


func test_fps_card_and_product_are_both_required_for_final_transaction() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.cut(state, "meat")))
	assert_false(rules.finish(state, "return", true)["ok"])
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	assert_eq(state.money["till"], 2000, "the combined transaction waits for the card")
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_true(_apply(rules.move_card(state, "table")))
	assert_false(rules.finish(state, "return", true)["ok"])
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_eq(state.money["till"], 5000)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 0)
	assert_false(rules.finish(state, "return", true)["ok"])


func test_fps_physical_state_survives_json_roundtrip() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.cut(state, "meat")))
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	var restored: CampaignState = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(restored.to_dict(), state.to_dict())
	assert_true(rules.finish(restored, "return", true)["ok"])


func test_delivered_product_locks_decision_until_card_return() -> void:
	_stamp("approve")
	assert_true(_apply(rules.prepare(state, "official")))
	assert_true(_apply(rules.cut(state, "meat")))
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	var before: Dictionary = state.to_dict()
	assert_false(rules.stamp(state, "reject", Vector2(540, 190))["ok"])
	assert_false(rules.stamp(state, "seize", Vector2(540, 190))["ok"])
	assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 0)
	assert_eq(state.money["till"], 5000)


func test_card_3d_coordinates_match_printed_fields_and_flip() -> void:
	var paper: RationCard3D = RationCard3D.new()
	var world: Node3D = Node3D.new()
	Game.add_child(world)
	world.add_child(paper)
	world.transform = Transform3D(Basis.from_euler(Vector3(0.2, 0.7, 0)), Vector3(1, 2, 3))
	for flipped: bool in [false, true]:
		paper.rotation = Vector3(-PI / 2, PI if flipped else 0, 0)
		# A quarter-width, quarter-height point corresponds to printed pixel 480,100.
		var point: Vector3 = paper.global_transform * Vector3(RationCard3D.WIDTH * 0.25, RationCard3D.HEIGHT * 0.25, 0.001)
		var normal: Vector3 = paper.global_basis.z
		var measured: Vector2 = paper.ray_pixel(point + normal, -normal)
		assert_true(measured.distance_to(Vector2(480, 100)) < 0.001)
		assert_true(paper.pixel_to_world(Vector2(480, 100)).distance_to(point) < 0.00001)
		assert_eq(paper.ray_pixel(point - normal, -normal), Vector2(-1, -1), "rays behind the card must not hit its front")
	world.free()


func test_paperwork_survives_leaving_before_hidden_goods_collection() -> void:
	_case(7)
	var opening: Dictionary = RationDeskRules.desk(state).duplicate(true)
	opening["official"]["meat"] = 0
	state.flags[RationDeskRules.KEY] = opening
	_stamp("approve")
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	var restored: CampaignState = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	state = restored
	assert_eq(RationDeskRules.desk(state)["placement"], "table")
	assert_eq(RationDeskRules.desk(state)["parcel"], {})
	assert_eq(RationDeskRules.desk(state)["cuts"], ["meat"])
	assert_false(rules.prepare(state, "official", "meat", true)["ok"])
	assert_true(_apply(rules.prepare(state, "hidden", "meat", true)))
	assert_eq(RationDeskRules.desk(state)["hidden"]["meat"], 500)
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_eq(RationDeskRules.desk(state)["hidden"]["meat"], 250)
	assert_eq(state.money["pocket"], 1000)


func test_prepared_undelivered_goods_survive_a_changed_mind_without_duplication() -> void:
	_stamp("approve")
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	assert_true(_apply(rules.prepare(state, "official", "meat", true)))
	assert_true(_apply(rules.move_parcel(state, "table")))
	var prepared: Dictionary = RationDeskRules.desk(state)["parcel"].duplicate(true)
	assert_true(_apply(rules.stamp(state, "reject", Vector2(540, 190), true)))
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(RationDeskRules.desk(state)["parcel"], prepared)
	assert_eq(RationDeskRules.desk(state)["cuts"], ["meat"])
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_false(rules.deliver_parcel(state)["ok"], "a prepared package cannot bypass a changed decision")
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	assert_false(rules.prepare(state, "official", "meat", true)["ok"])
	assert_false(rules.prepare(state, "hidden", "meat", true)["ok"])
	assert_true(_apply(rules.deliver_parcel(state)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_eq(state.money["till"], 5000)
	assert_eq(state.register.size(), 1)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 0)
	assert_eq(RationDeskRules.desk(state)["results"][0]["marks"].size(), 3)


func test_reject_or_seize_cleans_undelivered_parcel_without_charging_stock() -> void:
	for kind: String in ["reject", "seize"]:
		before_each()
		_stamp("approve")
		assert_true(_apply(rules.cut(state, "meat")))
		assert_true(_apply(rules.prepare(state, "official", "meat", true)))
		assert_true(_apply(rules.move_parcel(state, "hand")))
		assert_true(_apply(rules.stamp(state, kind, Vector2(540, 190))))
		assert_true(_apply(rules.finish(state, "seize" if kind == "seize" else "return", true)))
		assert_eq(RationDeskRules.desk(state)["parcel"], {})
		assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
		assert_eq(state.money["till"], 2000)
		assert_eq(state.money["pocket"], 0)
		assert_eq(state.register.size(), 0)
		var result: Dictionary = RationDeskRules.desk(state)["results"][0]
		assert_eq(result["cuts"], ["meat"], "a cancelled sale must not restore the removed paper")
		assert_false(result["correct"], "damaging the entitlement before rejection is audited")
		assert_eq(result["revenue"], 0)
		assert_eq(result["source"], "")
		assert_true(_apply(rules.next(state)))
		assert_eq(RationDeskRules.desk(state)["parcel"], {})
		assert_eq(RationDeskRules.desk(state)["cuts"], [])
		assert_eq(RationDeskRules.desk(state)["results"].size(), 1)


func test_restored_parcel_must_match_request_before_delivery_or_accounting() -> void:
	for mismatch: Dictionary in [{"item": "soap"}, {"amount": 500}, {"amount": -750}, {"source": "shelf"}]:
		before_each()
		_stamp("approve")
		assert_true(_apply(rules.cut(state, "meat")))
		assert_true(_apply(rules.prepare(state, "official", "meat", true)))
		assert_true(_apply(rules.move_parcel(state, "hand")))
		var saved: Dictionary = state.to_dict()
		var parcel: Dictionary = saved["flags"][RationDeskRules.KEY]["parcel"]
		parcel.merge(mismatch, true)
		state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(saved)))
		var before: Dictionary = state.to_dict()
		assert_false(rules.deliver_parcel(state)["ok"])
		assert_false(rules.finish(state, "return")["ok"])
		assert_eq(state.to_dict(), before)
		assert_eq(state.money["till"], 2000)
		assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)


func test_invalid_request_amount_cannot_cut_prepare_or_pay() -> void:
	for bad_amount: Variant in [0, -750, 1.5]:
		before_each()
		rules.cases[0]["request"]["amount"] = bad_amount
		_stamp("approve")
		var before: Dictionary = state.to_dict()
		assert_false(rules.cut(state, "meat")["ok"])
		assert_false(rules.prepare(state, "official")["ok"])
		assert_false(rules.finish(state, "return")["ok"])
		assert_eq(state.to_dict(), before)


func test_entitlement_amount_cannot_be_bypassed_by_collecting_first() -> void:
	rules.cases[0]["request"]["amount"] = 751
	_stamp("approve")
	var work: Dictionary = RationDeskRules.desk(state).duplicate(true)
	work["official"]["meat"] = 2000
	state.flags[RationDeskRules.KEY] = work
	assert_true(_apply(rules.prepare(state, "official")), "legacy logical preparation does not consume stock")
	assert_false(rules.cut(state, "meat")["ok"])
	assert_false(rules.finish(state, "return")["ok"])
	assert_eq(RationDeskRules.desk(state)["cuts"], [])
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 2000)
	assert_eq(state.money["till"], 2000)


func test_valid_soap_sale_uses_units_and_charges_once_after_physical_handoff() -> void:
	# Demo soap customers need rejection; use a valid card to cover the sale route.
	rules.cases[0]["request"] = {"item": "soap", "amount": 1}
	assert_true(RationDeskRules.issues(rules.cases[0]).is_empty())
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	_incise_perimeter("soap")
	assert_true(_apply(rules.cut(state, "soap", true)))
	assert_eq(RationDeskRules.desk(state)["parcel"], {}, "the paperwork precedes collecting goods")
	assert_true(_apply(rules.prepare(state, "official", "soap", true)))
	assert_eq(RationDeskRules.desk(state)["parcel"]["amount"], 1)
	assert_eq(RationDeskRules.desk(state)["official"]["soap"], 4)
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	assert_eq(state.money["till"], 2000, "accounting waits for the card's return")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_eq(RationDeskRules.desk(state)["official"]["soap"], 3)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(RationDeskRules.desk(state)["official"]["sugar"], 3000)
	assert_eq(state.money["till"], 2800)
	assert_eq(state.register.size(), 1)
	assert_eq(state.register[0]["item"], "ration_soap")
	assert_eq(state.register[0]["amount"], 1)
	assert_eq(state.register[0]["price"], 800)
	assert_true(RationDeskRules.desk(state)["results"][0]["correct"])
	var completed: Dictionary = state.to_dict()
	assert_false(rules.deliver_parcel(state)["ok"])
	assert_false(rules.finish(state, "return", true)["ok"])
	assert_eq(state.to_dict(), completed)


func test_two_centimeter_cut_is_permanent_but_does_not_consume_a_coupon() -> void:
	_stamp("approve")
	assert_true(_apply(rules.move_card(state, "table")))
	var end_x: float = 30.0 + 0.02 * 640.0 / 0.36
	assert_true(_apply(rules.incise(state, [[30.0, 285.0], [end_x, 285.0]])))
	var work: Dictionary = RationDeskRules.desk(state)
	assert_true(absf(work["incisions"][0]["length_m"] - 0.02) < 0.0000001, "two cm of blade travel must remain two cm")
	assert_true(absf(work["incisions"][0]["points"][1][0] - end_x) < 0.000001)
	assert_eq(work["incisions"][0]["points"][1][1], 285)
	assert_eq(work["cuts"], [])
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_false(rules.prepare(state, "official", "meat", true)["ok"])
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.move_card(state, "table")))
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(RationDeskRules.desk(state)["incisions"], work["incisions"], "leaving, lifting and JSON must not heal partial cuts")
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(state.money["till"], 2000)


func test_one_complete_edge_does_not_detach_the_other_three_edges() -> void:
	_stamp("approve")
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.incise(state, [[30.0, 285.0], [210.0, 285.0]])))
	assert_false(PaperCutGeometry.coupon_is_severed(RationDeskRules.desk(state)["incisions"], Rect2(30, 285, 180, 90)))
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_true(_apply(rules.incise(state, [[210.0, 285.0], [210.0, 375.0], [30.0, 375.0]])))
	assert_false(rules.cut(state, "meat", true)["ok"], "last attached side still carries the coupon")
	assert_true(_apply(rules.incise(state, [[30.0, 375.0], [30.0, 285.0]])))
	assert_true(_apply(rules.cut(state, "meat", true)))
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_eq(RationDeskRules.desk(state)["cuts"], ["meat"])
	assert_eq(RationDeskRules.desk(state)["incisions"].size(), 3)


func test_perimeter_coverage_does_not_bridge_a_gap_or_count_diagonal_shortcuts() -> void:
	var rectangle: Rect2 = Rect2(30, 285, 180, 90)
	var disconnected: Array = [{"points": [[30, 285], [110, 285]]}, {"points": [[112, 285], [210, 285], [210, 375], [30, 375], [30, 285]]}]
	assert_false(PaperCutGeometry.coupon_is_severed(disconnected, rectangle), "a 1.125 mm uncut gap must keep the coupon attached")
	disconnected.append({"points": [[110, 285], [112, 285]]})
	assert_true(PaperCutGeometry.coupon_is_severed(disconnected, rectangle))
	assert_false(PaperCutGeometry.coupon_is_severed([{"points": [[30, 285], [210, 375], [30, 375], [210, 285], [30, 285]]}], rectangle))


func test_incisions_validate_active_table_and_preserve_state_on_bad_coordinates() -> void:
	assert_false(rules.incise(state, [[30, 285], [65, 285]])["ok"])
	assert_true(_apply(rules.take(state)))
	assert_false(rules.incise(state, [[30, 285], [65, 285]])["ok"])
	assert_true(_apply(rules.move_card(state, "table")))
	for points: Array in [[], [[30, 285]], [[30, 285], [30, 285]], [[-1, 285], [30, 285]], [[30, 285], [641, 285]], [[30, 285], [35, 401]], [[30, 285], [INF, 285]], [[30, 285], [NAN, 285]], [[30, 285], ["35", 285]]]:
		var before: Dictionary = state.to_dict()
		assert_false(rules.incise(state, points)["ok"])
		assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.incise(state, [[30, 285], [65, 285]])), "physical paper can be damaged before a decision without auto-approving it")
	assert_eq(RationDeskRules.desk(state)["stamp"], "")
	assert_eq(RationDeskRules.desk(state)["cuts"], [])


func test_actual_stroke_length_is_not_projected_to_coupon_progress() -> void:
	var points: Array = [[30, 285], [50, 285], [50, 305]]
	assert_true(absf(PaperCutGeometry.path_length_m(points) - 0.0225) < 0.0000001)
	assert_true(PaperCutGeometry.path_length_m([[30, 285], [30, 285]]) == 0.0)
	assert_false(PaperCutGeometry.coupon_is_severed([], Rect2(30, 285, 180, 90)))


func test_stamp_motion_is_preserved_as_stable_json_impression_data() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	var contact: Dictionary = {"speed": 0.82, "dwell": 0.44, "pressure": 0.91, "angle": 0.12, "smudge": 0.004, "smudge_direction": [3.0, 4.0]}
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540.25, 190.75), true, contact)))
	var impression: Dictionary = RationDeskRules.desk(state)["marks"][0].duplicate(true)
	assert_eq(impression["x"], 540.25)
	assert_eq(impression["y"], 190.75)
	assert_eq(impression["speed"], 0.82)
	assert_eq(impression["dwell"], 0.44)
	assert_eq(impression["pressure"], 0.91)
	assert_eq(impression["smudge"], 0.004)
	assert_eq(impression["serial"], 1)
	assert_true(absf(impression["smudge_direction"][0] - 0.6) < 0.000001)
	assert_true(absf(impression["smudge_direction"][1] - 0.8) < 0.000001)
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(RationDeskRules.desk(state)["marks"][0], impression)
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true, {"speed": 0.12, "dwell": 0.08, "pressure": 0.30})))
	assert_eq(RationDeskRules.desk(state)["marks"][1]["serial"], 2)
	assert_eq(RationDeskRules.desk(state)["marks"][0], impression, "later impressions cannot reroll prior ink")


func test_stamp_motion_is_bounded_finite_and_legacy_contacts_remain_supported() -> void:
	assert_true(_apply(rules.take(state)))
	var before: Dictionary = state.to_dict()
	assert_false(rules.stamp(state, "approve", Vector2(NAN, 190))["ok"])
	assert_false(rules.stamp(state, "approve", Vector2(540, INF))["ok"])
	assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), false,
		{"speed": INF, "dwell": -1, "pressure": 5.0, "angle": NAN, "smudge": 400, "smudge_direction": [NAN, INF], "serial": 99999})))
	var impression: Dictionary = RationDeskRules.desk(state)["marks"][0]
	assert_eq(impression["speed"], 0.35)
	assert_eq(impression["dwell"], 0)
	assert_eq(impression["pressure"], 1)
	assert_eq(impression["angle"], 0)
	assert_eq(impression["smudge"], 0.02)
	assert_eq(impression["smudge_direction"], [0, 0])
	assert_eq(impression["serial"], 1)
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190))))
	assert_eq(RationDeskRules.desk(state)["marks"][1]["pressure"], 0.65)


func test_completed_card_audits_permanent_strokes_and_resets_only_the_next_sheet() -> void:
	_stamp("approve")
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.incise(state, [[30, 285], [65, 285]])))
	var strokes: Array = RationDeskRules.desk(state)["incisions"].duplicate(true)
	assert_true(_apply(rules.stamp(state, "reject", Vector2(540, 190), true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_eq(RationDeskRules.desk(state)["results"][0]["incisions"], strokes)
	assert_true(_apply(rules.next(state)))
	assert_eq(RationDeskRules.desk(state)["incisions"], [])
	assert_eq(RationDeskRules.desk(state)["results"][0]["incisions"], strokes)


func test_held_stamp_develops_one_existing_impression_without_changing_decisions() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.stamp(state, "approve", Vector2(530.25, 185.75), true, {"pressure": 0.2, "dwell": 0.01, "angle": 0.3})))
	assert_true(_apply(rules.stamp(state, "reject", Vector2(545.5, 192.25), true)))
	var initial: Dictionary = RationDeskRules.desk(state)["marks"][0].duplicate(true)
	var later: Dictionary = RationDeskRules.desk(state)["marks"][1].duplicate(true)
	assert_true(_apply(rules.update_impression(state, 1, {"dwell": 0.73, "pressure": 0.88, "smudge": 0.003,
		"smudge_direction": [0, -1], "kind": "seize", "x": 0, "y": 0, "serial": 999})))
	var work: Dictionary = RationDeskRules.desk(state)
	assert_eq(work["marks"].size(), 2, "continued contact must not append duplicate stamps")
	assert_eq(work["stamp"], "reject")
	var developed: Dictionary = work["marks"][0]
	for field: String in ["kind", "x", "y", "serial", "speed", "angle"]:
		assert_eq(developed[field], initial[field])
	assert_eq(developed["dwell"], 0.73)
	assert_eq(developed["pressure"], 0.88)
	assert_eq(developed["smudge"], 0.003)
	assert_eq(developed["smudge_direction"], [0, -1])
	assert_eq(work["marks"][1], later)
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(RationDeskRules.desk(state)["marks"][0], developed)
	assert_true(_apply(rules.update_impression(state, 1, {})))
	assert_eq(RationDeskRules.desk(state)["marks"][0], developed, "a no-op must not perturb previous impression physics")


func test_held_stamp_updates_validate_contact_and_sanitize_only_metadata() -> void:
	_stamp("approve")
	assert_false(rules.update_impression(state, 1, {"dwell": 1.0})["ok"], "held paper cannot support a desk stamp")
	assert_true(_apply(rules.move_card(state, "table")))
	for serial: int in [-1, 0, 2, 999]:
		var before: Dictionary = state.to_dict()
		assert_false(rules.update_impression(state, serial, {"dwell": 1.0})["ok"])
		assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.update_impression(state, 1, {"pressure": INF, "dwell": 100, "smudge": -1})))
	var mark: Dictionary = RationDeskRules.desk(state)["marks"][0]
	assert_eq(mark["pressure"], 0.65, "nonfinite input retains existing pressure")
	assert_eq(mark["dwell"], 15)
	assert_eq(mark["smudge"], 0)
	assert_true(_apply(rules.stamp(state, "reject", Vector2(540, 190), true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish(state, "return", true)))
	assert_false(rules.update_impression(state, 1, {"dwell": 1.0})["ok"], "closed customer cards cannot change")


func test_native_pointer_cut_join_tolerance_is_at_most_half_a_millimeter() -> void:
	var rectangle: Rect2 = Rect2(30, 285, 180, 90)
	var almost_joined: Array = [{"points": [[30, 285], [110, 285]]}, {"points": [[110.8, 285], [210, 285], [210, 375], [30, 375], [30, 285]]}]
	assert_true(PaperCutGeometry.coupon_is_severed(almost_joined, rectangle), "0.45 mm native pointer gap is within blade contact tolerance")
	almost_joined[1]["points"][0] = [112, 285]
	assert_false(PaperCutGeometry.coupon_is_severed(almost_joined, rectangle), "a physical gap over 1 mm cannot vanish")
	assert_true(PaperCutGeometry.JOIN_TOLERANCE_PX * 0.36 / 640.0 <= 0.000500001)


func test_document_review_approval_needs_only_physical_paperwork_and_card_return() -> void:
	var original_money: Dictionary = state.money.duplicate(true)
	var original_stock: Dictionary = state.stock.duplicate(true)
	var official: Dictionary = RationDeskRules.desk(state)["official"].duplicate(true)
	var hidden: Dictionary = RationDeskRules.desk(state)["hidden"].duplicate(true)
	_physical_stamp("approve")
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	assert_false(rules.finish_review(state, "return")["ok"], "returned paper must be in the player's hand")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var work: Dictionary = RationDeskRules.desk(state)
	assert_true(work["done"])
	assert_eq(work["location"], "return")
	assert_eq(work["placement"], "customer")
	assert_eq(work["parcel"], {})
	assert_eq(state.money, original_money)
	assert_eq(state.stock, original_stock)
	assert_eq(work["official"], official)
	assert_eq(work["hidden"], hidden)
	assert_eq(state.register.size(), 0)
	assert_eq(state.decision_log.size(), 1)
	var audit: Dictionary = work["results"][0]
	assert_true(audit["document_review"])
	assert_true(audit["correct"])
	assert_eq(audit["revenue"], 0)
	assert_eq(audit["source"], "")
	assert_eq(audit["cuts"], ["meat"])
	assert_eq(audit["incisions"], work["incisions"])
	assert_eq(audit["marks"], work["marks"])
	var completed: Dictionary = state.to_dict()
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_false(rules.finish(state, "return", true)["ok"])
	assert_eq(state.to_dict(), completed, "neither completion path can repeat an audit or transaction")
	assert_true(_apply(rules.next(state)))
	assert_eq(RationDeskRules.desk(state)["index"], 1)
	assert_eq(RationDeskRules.desk(state)["results"].size(), 1)
	assert_eq(RationDeskRules.desk(state)["incisions"], [])


func test_document_review_rejections_return_physical_cards_without_goods() -> void:
	for index: int in [2, 4, 6]:
		before_each()
		_case(index)
		_physical_stamp("reject")
		assert_false(rules.finish_review(state, "return")["ok"], "table paper has not been handed back")
		assert_true(_apply(rules.move_card(state, "hand")))
		assert_true(_apply(rules.finish_review(state, "return")))
		var work: Dictionary = RationDeskRules.desk(state)
		assert_eq(work["placement"], "customer")
		assert_true(work["results"][0]["correct"])
		assert_true(work["results"][0]["document_review"])
		assert_eq(work["parcel"], {})
		assert_eq(state.money["till"], 2000)
		assert_eq(state.register.size(), 0)
		assert_true(_apply(rules.next(state)))
		assert_eq(RationDeskRules.desk(state)["index"], index + 1)


func test_document_review_seizure_hands_card_to_drawer_and_checks_destination() -> void:
	for index: int in [3, 5]:
		before_each()
		_case(index)
		_physical_stamp("seize")
		assert_false(rules.finish_review(state, "seize")["ok"], "paper on the table has not been carried to the drawer")
		assert_true(_apply(rules.move_card(state, "hand")))
		assert_false(rules.finish_review(state, "return")["ok"], "a seized card cannot be returned to the customer")
		assert_false(rules.finish_review(state, "teleport")["ok"])
		assert_true(_apply(rules.finish_review(state, "seize")))
		var work: Dictionary = RationDeskRules.desk(state)
		assert_eq(work["location"], "seize")
		assert_eq(work["placement"], "drawer")
		assert_true(work["results"][0]["correct"])
		assert_eq(work["results"][0]["revenue"], 0)
		assert_eq(work["official"]["meat"], 750)
		assert_eq(work["hidden"]["meat"], 500)
		assert_eq(state.money["till"], 2000)
		assert_false(rules.finish_review(state, "return")["ok"])


func test_document_review_requires_real_stamp_contact_and_complete_requested_coupon() -> void:
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_true(_apply(rules.take(state)))
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190))))
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_false(rules.finish_review(state, "return")["ok"], "logical/legacy stamp flags are not physical contact")
	assert_true(_apply(rules.move_card(state, "table")))
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))


func test_document_review_does_not_treat_logical_or_partial_cut_as_a_severed_coupon() -> void:
	_physical_stamp("approve")
	assert_true(_apply(rules.incise(state, [[30, 285], [65.5555555556, 285]])))
	assert_true(_apply(rules.cut(state, "meat")), "legacy logical rules remain available independently")
	assert_true(_apply(rules.move_card(state, "hand")))
	var before: Dictionary = state.to_dict()
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))


func test_document_review_allows_wrong_decisions_without_faking_a_sale() -> void:
	_case(3)
	_physical_stamp("approve")
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")), "forgery is judged after the player's decision")
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_false(audit["correct"])
	assert_true(audit["forged"])
	assert_eq(audit["revenue"], 0)
	assert_eq(state.money["till"], 2000)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(state.meters["suspicion"], 13)


func test_document_review_cannot_discard_a_prepared_or_delivered_sale() -> void:
	_physical_stamp("approve")
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	assert_true(_apply(rules.prepare(state, "official", "meat", true)))
	assert_true(_apply(rules.move_card(state, "hand")))
	var prepared: Dictionary = state.to_dict()
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_eq(state.to_dict(), prepared)
	assert_true(_apply(rules.move_parcel(state, "hand")))
	assert_true(_apply(rules.deliver_parcel(state)))
	var delivered: Dictionary = state.to_dict()
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_eq(state.to_dict(), delivered)
	assert_true(_apply(rules.finish(state, "return", true)), "legacy sales still settle delivered goods exactly once")
	assert_eq(state.money["till"], 5000)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 0)
	assert_eq(state.register.size(), 1)
	assert_false(RationDeskRules.desk(state)["results"][0].get("document_review", false))


func test_eight_document_reviews_progress_without_touching_any_goods_or_money() -> void:
	var money_before: Dictionary = state.money.duplicate(true)
	var stock_before: Dictionary = state.stock.duplicate(true)
	var decisions: Array[String] = ["approve", "approve", "reject", "seize", "reject", "seize", "reject", "approve"]
	for index: int in range(decisions.size()):
		var kind: String = decisions[index]
		_physical_stamp(kind)
		if kind == "approve":
			var item: String = rules.current(state)["request"]["item"]
			_incise_perimeter(item)
			assert_true(_apply(rules.cut(state, item, true)))
		assert_true(_apply(rules.move_card(state, "hand")))
		assert_true(_apply(rules.finish_review(state, "seize" if kind == "seize" else "return")))
		var audit: Dictionary = RationDeskRules.desk(state)["results"][index]
		assert_true(audit["correct"])
		assert_true(audit["document_review"])
		assert_eq(audit["revenue"], 0)
		assert_true(_apply(rules.next(state)))
	assert_true(rules.current(state).is_empty())
	assert_eq(state.money, money_before)
	assert_eq(state.stock, stock_before)
	assert_eq(RationDeskRules.desk(state)["official"], {"meat": 750, "sugar": 3000, "soap": 4})
	assert_eq(RationDeskRules.desk(state)["hidden"], {"meat": 500, "sugar": 0, "soap": 0})
	assert_eq(state.register.size(), 0)
	assert_eq(state.decision_log.size(), 8)


func test_unapproved_full_perimeter_is_physical_damage_without_entitlement_consumption() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	var damaged: Dictionary = RationDeskRules.desk(state).duplicate(true)
	assert_true(PaperCutGeometry.coupon_is_severed(damaged["incisions"], Rect2(30, 285, 180, 90)), "physical separation does not wait for an approval stamp")
	assert_eq(damaged["stamp"], "")
	assert_eq(damaged["cuts"], [], "separated paper alone does not authorize the requested entitlement")
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_false(rules.prepare(state, "official", "meat", true)["ok"])
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.move_card(state, "table")))
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(RationDeskRules.desk(state)["incisions"], damaged["incisions"])
	assert_eq(RationDeskRules.desk(state)["cuts"], [])
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(RationDeskRules.desk(state)["hidden"]["meat"], 500)
	assert_eq(state.money["till"], 2000)
	assert_eq(state.register.size(), 0)


func test_cut_before_stamp_can_be_approved_afterward_without_recutting_the_paper() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("meat")
	var original_strokes: Array = RationDeskRules.desk(state)["incisions"].duplicate(true)
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	assert_true(_apply(rules.cut(state, "meat", true)), "approval recognizes paper already physically cut")
	assert_eq(RationDeskRules.desk(state)["incisions"], original_strokes, "bookkeeping must not cut a second copy of the coupon")
	assert_false(rules.cut(state, "meat", true)["ok"])
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_true(audit["correct"])
	assert_true(audit["document_review"])
	assert_eq(audit["cuts"], ["meat"])
	assert_eq(audit["incisions"], original_strokes)
	assert_eq(audit["revenue"], 0)
	assert_eq(state.money["till"], 2000)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)


func test_closed_wrong_coupon_path_does_not_grant_the_requested_entitlement() -> void:
	assert_true(_apply(rules.take(state)))
	assert_true(_apply(rules.move_card(state, "table")))
	_incise_perimeter("sugar")
	var work: Dictionary = RationDeskRules.desk(state)
	assert_true(PaperCutGeometry.coupon_is_severed(work["incisions"], Rect2(225, 285, 180, 90)), "the wrong physical coupon is still really separated")
	assert_false(PaperCutGeometry.coupon_is_severed(work["incisions"], Rect2(30, 285, 180, 90)))
	assert_true(_apply(rules.stamp(state, "approve", Vector2(540, 190), true)))
	var before: Dictionary = state.to_dict()
	assert_false(rules.cut(state, "sugar", true)["ok"], "a closed path cannot substitute a product the customer did not request")
	assert_false(rules.cut(state, "meat", true)["ok"], "another coupon's perimeter cannot consume the requested entitlement")
	assert_false(rules.prepare(state, "official", "meat", true)["ok"])
	assert_eq(state.to_dict(), before)
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_false(rules.finish_review(state, "return")["ok"])
	assert_eq(RationDeskRules.desk(state)["cuts"], [])
	assert_eq(RationDeskRules.desk(state)["parcel"], {})
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(state.money["till"], 2000)


func test_review_rejection_accepts_handback_but_audits_wrong_coupon_physically_removed() -> void:
	_case(2) # Expired card normally merits rejection.
	_physical_stamp("reject")
	_incise_perimeter("sugar")
	assert_eq(RationDeskRules.desk(state)["cuts"], [], "unapproved damage is independent of entitlement accounting")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")), "the player can return a document they damaged")
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_false(audit["correct"])
	assert_eq(audit["physical_detached"], ["sugar"])
	assert_true(audit["issues"].has("Ret/alıkoyma işleminde kupon kesildi: ŞEKER / CUKIER"))
	assert_eq(audit["cuts"], [])
	assert_eq(audit["revenue"], 0)
	assert_eq(state.decision_log[0]["physical_detached"], ["sugar"])
	assert_eq(state.money["till"], 2000)
	assert_eq(RationDeskRules.desk(state)["official"]["sugar"], 3000)
	assert_eq(state.register.size(), 0)
	assert_eq(state.meters["suspicion"], 8)
	state = CampaignState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	assert_eq(RationDeskRules.desk(state)["results"][0], audit, "physical damage evidence persists in the review audit")
	assert_true(_apply(rules.next(state)))
	assert_eq(RationDeskRules.desk(state)["results"][0]["physical_detached"], ["sugar"])


func test_review_approval_with_an_extra_physical_coupon_completes_but_is_incorrect() -> void:
	_physical_stamp("approve")
	_incise_perimeter("meat")
	assert_true(_apply(rules.cut(state, "meat", true)))
	_incise_perimeter("soap")
	assert_false(rules.cut(state, "soap", true)["ok"], "wrong paper damage does not become a second entitlement")
	assert_true(RationDeskRules.issues(rules.current(state)).is_empty(), "physical work must not change pre-decision authenticity evidence")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_false(audit["correct"])
	assert_eq(audit["physical_detached"], ["meat", "soap"])
	assert_eq(audit["issues"], ["Talep dışı kupon kesildi: SABUN / MYDŁO"])
	assert_true(RationDeskRules.issues(rules.current(state)).is_empty())
	assert_eq(audit["cuts"], ["meat"])
	assert_eq(audit["revenue"], 0)
	assert_eq(state.money["till"], 2000)
	assert_eq(RationDeskRules.desk(state)["official"]["meat"], 750)
	assert_eq(RationDeskRules.desk(state)["official"]["soap"], 4)
	assert_eq(state.meters["suspicion"], 13)


func test_review_seizure_does_not_hide_unapproved_physical_coupon_damage() -> void:
	_case(3) # Forged institution would normally merit seizure.
	_physical_stamp("seize")
	_incise_perimeter("soap")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "seize")))
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_false(audit["correct"])
	assert_true(audit["forged"])
	assert_eq(audit["physical_detached"], ["soap"])
	assert_true(audit["issues"].has("Ret/alıkoyma işleminde kupon kesildi: SABUN / MYDŁO"))
	assert_eq(audit["cuts"], [])
	assert_eq(RationDeskRules.desk(state)["placement"], "drawer")
	assert_eq(state.money["till"], 2000)
	assert_eq(state.register.size(), 0)


func test_small_nicks_do_not_count_as_a_removed_coupon_in_review_audit() -> void:
	_case(2)
	_physical_stamp("reject")
	assert_true(_apply(rules.incise(state, [[225.0, 285.0], [260.5555555556, 285.0]])))
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_true(audit["correct"])
	assert_eq(audit["physical_detached"], [])
	assert_eq(audit["incisions"].size(), 1, "a harmless partial nick is still preserved as visible paper damage")
	assert_eq(state.meters["suspicion"], 5)


func test_previously_used_absent_coupon_is_not_counted_as_new_review_damage() -> void:
	_case(4) # Meat coupon was already used before this customer arrived.
	_physical_stamp("reject")
	_incise_perimeter("meat")
	assert_true(_apply(rules.move_card(state, "hand")))
	assert_true(_apply(rules.finish_review(state, "return")))
	var audit: Dictionary = RationDeskRules.desk(state)["results"][0]
	assert_true(audit["correct"])
	assert_eq(audit["physical_detached"], [], "only previously available paper can be newly detached")
