extends TestCase
## CampaignState: defaults, copies and save round trips (roadmap 1.5).


func _sample() -> CampaignState:
	var s: CampaignState = CampaignState.new()
	s.day = 3
	s.phase = "shift"
	s.minute_of_day = 600
	s.rng_seed = 81
	s.money["till"] = 1290
	s.money["pocket"] = 500
	s.stock["shelf"]["itm_cigarettes"] = 5
	s.stock["backroom"]["itm_cigarettes"] = 10
	s.register.append({"item": "itm_cigarettes", "qty": 1, "price": 1290, "day": 3, "minute": 600})
	var who: Dictionary = s.ensure_character("chr_old_woman")
	who["relations"]["trust"] = 2
	(who["memories"] as Array).append({"type": "sold_with_bad_coupon", "day": 3})
	s.flags["decree_b_series_only"] = true
	s.decision_log.append({"type": "sale", "day": 3, "minute": 600})
	return s


func test_defaults() -> void:
	var s: CampaignState = CampaignState.new()
	assert_eq(s.day, 1)
	assert_eq(s.phase, "morning")
	assert_eq(s.minute_of_day, 450)
	assert_eq(s.money["till"], 0)
	assert_eq(s.stock_count("shelf", "itm_cigarettes"), 0)


func test_dict_round_trip_keeps_everything() -> void:
	var original: CampaignState = _sample()
	var copy: CampaignState = CampaignState.from_dict(original.to_dict())
	assert_eq(copy.to_dict(), original.to_dict())


func test_json_round_trip_keeps_ints() -> void:
	var original: CampaignState = _sample()
	var text: String = JSON.stringify(original.to_dict())
	var parsed: Variant = JSON.parse_string(text)
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "JSON should parse")
	var restored: CampaignState = CampaignState.from_dict(parsed)
	assert_eq(restored.to_dict(), original.to_dict())
	assert_eq(typeof(restored.money["till"]), TYPE_INT, "money stays an int")
	assert_eq(typeof(restored.stock["shelf"]["itm_cigarettes"]), TYPE_INT, "stock stays an int")


func test_duplicate_is_independent() -> void:
	var original: CampaignState = _sample()
	var copy: CampaignState = original.duplicate_state()
	copy.money["till"] = 0
	copy.stock["shelf"]["itm_cigarettes"] = 0
	(copy.characters["chr_old_woman"]["memories"] as Array).clear()
	assert_eq(original.money["till"], 1290)
	assert_eq(original.stock_count("shelf", "itm_cigarettes"), 5)
	assert_eq((original.characters["chr_old_woman"]["memories"] as Array).size(), 1)


func test_missing_fields_use_defaults() -> void:
	var s: CampaignState = CampaignState.from_dict({"day": 4})
	assert_eq(s.day, 4)
	assert_eq(s.phase, "morning")
	assert_eq(s.money["pocket"], 0)
	assert_eq(s.stock.keys().size(), 5)
	assert_eq(s.stock_count("hand", "itm_matches"), 0)
	assert_eq(s.stock_count("counter", "itm_matches"), 0)


func test_ensure_character_is_neutral() -> void:
	var s: CampaignState = CampaignState.new()
	var who: Dictionary = s.ensure_character("chr_marek")
	assert_eq(who["status"], "active")
	assert_eq(who["relations"]["trust"], 0)
	assert_eq((who["memories"] as Array).size(), 0)
