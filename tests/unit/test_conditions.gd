extends TestCase
## Condition language v0 (roadmap 1.7, docs/CONDITION_LANGUAGE.md).

var s: CampaignState


func before_each() -> void:
	s = CampaignState.new()
	s.day = 3
	s.calendar_date = "1981-12-15"
	s.minute_of_day = 600  # 10:00
	s.phase = "shift"
	s.money["pocket"] = 1500
	s.stock["shelf"]["trybuna_ludu"] = 5
	s.stock["hidden"]["tygodnik_mazowsze"] = 2
	var halina: Dictionary = s.ensure_character("halina")
	halina["status"] = "interned"
	halina["relations"]["trust"] = 4
	s.ensure_character("marek")["memories"].append({"id": "saw_forgery", "day": 2})
	s.flags = {"met_marek": true, "marek_side": "state", "pressure": 3, "was_warned": false}
	s.decision_log.append({"id": "hid_leaflets", "day": 2, "minute": 700})


func _yes(condition: Variant, message: String = "") -> void:
	var r: Conditions.Result = Conditions.evaluate(s, condition)
	assert_true(r.ok, "unexpected error: %s %s" % [r.error, message])
	assert_true(r.value, "expected true: %s %s" % [var_to_str(condition), message])


func _no(condition: Variant, message: String = "") -> void:
	var r: Conditions.Result = Conditions.evaluate(s, condition)
	assert_true(r.ok, "unexpected error: %s %s" % [r.error, message])
	assert_false(r.value, "expected false: %s %s" % [var_to_str(condition), message])


func _invalid(condition: Variant, expected_text: String) -> void:
	var r: Conditions.Result = Conditions.evaluate(s, condition)
	assert_false(r.ok, "expected an error for %s" % var_to_str(condition))
	assert_false(r.value, "an invalid condition is never true")
	assert_true(r.error.contains(expected_text), "error '%s' should mention '%s'" % [r.error, expected_text])


func _rel(dimension: String, cmp: String, value: int, who: String = "halina") -> Dictionary:
	return {"if": "relation", "character": who, "dimension": dimension, "cmp": cmp, "value": value}


# ---------------------------------------------------------------- leaf tests

func test_literals() -> void:
	_yes(true)
	_no(false)


func test_relation() -> void:
	_yes(_rel("trust", ">=", 3))
	_yes(_rel("trust", "==", 4))
	_no(_rel("trust", ">", 4))
	_yes(_rel("suspicion", "<", 1))


func test_unknown_character_is_neutral_and_not_created() -> void:
	_yes(_rel("trust", "==", 0, "pan_kowalczyk"))
	_yes({"if": "status", "character": "pan_kowalczyk", "is": "active"})
	assert_false(s.characters.has("pan_kowalczyk"), "reading must not create a character")


func test_flag_truthiness() -> void:
	_yes({"if": "flag", "key": "met_marek"})
	_no({"if": "flag", "key": "was_warned"}, "false value")
	_no({"if": "flag", "key": "never_set"}, "missing flag")


func test_flag_comparisons() -> void:
	_yes({"if": "flag", "key": "marek_side", "cmp": "==", "value": "state"})
	_yes({"if": "flag", "key": "marek_side", "cmp": "!=", "value": "solidarity"})
	_yes({"if": "flag", "key": "pressure", "cmp": ">=", "value": 3})
	_no({"if": "flag", "key": "marek_side", "cmp": ">", "value": "a"}, "ordering on text is false")
	_no({"if": "flag", "key": "pressure", "cmp": "==", "value": "3"}, "number vs text")


func test_missing_flag_with_comparison() -> void:
	_no({"if": "flag", "key": "never_set", "cmp": "==", "value": 0})
	_yes({"if": "flag", "key": "never_set", "cmp": "!=", "value": 0})


func test_money_in_grosze() -> void:
	_yes({"if": "money", "account": "pocket", "cmp": ">=", "value": 1500})
	_no({"if": "money", "account": "pocket", "cmp": ">", "value": 1500})
	_yes({"if": "money", "account": "till", "cmp": "==", "value": 0})


func test_stock_by_location_and_total() -> void:
	_yes({"if": "stock", "location": "shelf", "item": "trybuna_ludu", "cmp": "==", "value": 5})
	_no({"if": "stock", "location": "shelf", "item": "tygodnik_mazowsze", "cmp": ">", "value": 0})
	_yes({"if": "stock", "location": "total", "item": "tygodnik_mazowsze", "cmp": "==", "value": 2})


func test_day() -> void:
	_yes({"if": "day", "cmp": ">=", "value": 3})
	_no({"if": "day", "cmp": "<", "value": 3})


func test_calendar_date() -> void:
	_yes({"if": "date", "cmp": ">=", "value": "1981-12-13"})
	_yes({"if": "date", "cmp": "<", "value": "1982-01-01"})
	_yes({"if": "date", "cmp": "==", "value": "1981-12-15"})
	_no({"if": "date", "cmp": ">", "value": "1981-12-15"})


func test_time_of_day() -> void:
	_yes({"if": "time", "cmp": ">=", "value": "09:00"})
	_yes({"if": "time", "cmp": "==", "value": "10:00"})
	_no({"if": "time", "cmp": "<", "value": "10:00"})


func test_phase_one_or_many() -> void:
	_yes({"if": "phase", "is": "shift"})
	_yes({"if": "phase", "is": ["morning", "shift"]})
	_no({"if": "phase", "is": ["evening", "night"]})


func test_character_status() -> void:
	_yes({"if": "status", "character": "halina", "is": "interned"})
	_yes({"if": "status", "character": "marek", "is": ["active", "missing"]})
	_no({"if": "status", "character": "halina", "is": "active"})


func test_memory_and_decision() -> void:
	_yes({"if": "memory", "character": "marek", "id": "saw_forgery"})
	_no({"if": "memory", "character": "halina", "id": "saw_forgery"})
	_yes({"if": "decision", "id": "hid_leaflets"})
	_no({"if": "decision", "id": "informed_on_neighbour"})


# ---------------------------------------------------------------- combinators

func test_all_any_not() -> void:
	_yes({"all": [_rel("trust", ">=", 3), {"if": "flag", "key": "met_marek"}]})
	_no({"all": [_rel("trust", ">=", 3), {"if": "flag", "key": "never_set"}]})
	_yes({"any": [{"if": "flag", "key": "never_set"}, {"if": "day", "cmp": "==", "value": 3}]})
	_yes({"not": {"if": "phase", "is": "night"}})
	_yes({"all": [{"any": [false, true]}, {"not": false}]}, "nested")


func test_list_is_shorthand_for_all() -> void:
	_yes([_rel("trust", ">=", 3), {"if": "day", "cmp": "==", "value": 3}])
	_no([_rel("trust", ">=", 3), false])


func test_empty_lists() -> void:
	_yes({"all": []}, "empty all is true")
	_no({"any": []}, "empty any is false")
	_yes([], "empty list is true")


# ---------------------------------------------------------------- errors

func test_typo_in_a_skipped_branch_is_still_reported() -> void:
	# "any" would stop at true, but validation runs over the whole tree first.
	_invalid({"any": [true, {"if": "relaton", "character": "halina"}]}, "unknown test 'relaton'")


func test_unknown_field_is_rejected() -> void:
	_invalid({"if": "day", "cmp": ">=", "value": 3, "vaule": 4}, "unknown field 'vaule'")


func test_missing_field_is_rejected() -> void:
	_invalid({"if": "relation", "character": "halina", "cmp": ">=", "value": 3}, "missing field 'dimension'")
	_invalid({"cmp": ">=", "value": 3}, "missing 'if'")


func test_wrong_values_are_rejected() -> void:
	_invalid(_rel("trsut", ">=", 3), "unknown relation 'trsut'")
	_invalid({"if": "relation", "character": "halina", "dimension": "trust", "cmp": "=>", "value": 3}, "must be one of")
	_invalid({"if": "day", "cmp": ">=", "value": "3"}, "whole number")
	_invalid({"if": "money", "account": "wallet", "cmp": ">", "value": 0}, "unknown account 'wallet'")
	_invalid({"if": "stock", "location": "under_counter", "item": "x", "cmp": ">", "value": 0}, "unknown stock location")
	_invalid({"if": "phase", "is": "lunch"}, "unknown phase 'lunch'")
	_invalid({"if": "status", "character": "halina", "is": []}, "text or a list")


func test_bad_date_and_time_are_rejected() -> void:
	_invalid({"if": "date", "cmp": ">", "value": "15.12.1981"}, "date like")
	_invalid({"if": "date", "cmp": ">", "value": "1981-13-01"}, "date like")
	_invalid({"if": "time", "cmp": ">", "value": "7:30"}, "time like")
	_invalid({"if": "time", "cmp": ">", "value": "24:00"}, "time like")


func test_flag_needs_cmp_and_value_together() -> void:
	_invalid({"if": "flag", "key": "pressure", "cmp": ">="}, "go together")
	_invalid({"if": "flag", "key": "pressure", "value": 3}, "go together")


func test_malformed_shapes_are_rejected() -> void:
	_invalid(null, "null")
	_invalid(3, "must be true/false")
	_invalid({"all": true}, "needs a list")
	_invalid({"not": false, "all": []}, "only field")


func test_error_path_points_to_the_problem() -> void:
	var r: Conditions.Result = Conditions.evaluate(s, {"all": [true, {"not": {"if": "day", "cmp": "?", "value": 1}}]})
	assert_false(r.ok)
	assert_true(r.error.begins_with("all[1].not: day:"), "got '%s'" % r.error)


func test_validate_collects_every_problem() -> void:
	var errors: PackedStringArray = Conditions.validate([{"if": "nope"}, {"if": "day"}, true])
	assert_eq(errors.size(), 2, "two broken items, one fine")


# ---------------------------------------------------------------- integration

func test_evaluation_never_changes_the_state() -> void:
	var before: Dictionary = s.to_dict()
	Conditions.evaluate(s, {"any": [_rel("trust", ">", 9, "nobody"), {"if": "memory", "character": "ghost", "id": "x"}]})
	assert_eq(s.to_dict(), before)


func test_condition_from_json_text() -> void:
	# Content files are JSON: numbers arrive as floats until normalised (ContentDB does this).
	var text: String = '{"all": [{"if": "relation", "character": "halina", "dimension": "trust", "cmp": ">=", "value": 3}, {"if": "time", "cmp": "<", "value": "18:00"}]}'
	var parsed: Variant = JSON.parse_string(text)
	_invalid(parsed, "whole number")
	_yes(CampaignState.normalize_numbers(parsed))


func test_numbers_compare_by_value() -> void:
	assert_true(Conditions.compare(3, "==", 3.0))
	assert_true(Conditions.compare(2.5, "<", 3))
	assert_false(Conditions.compare("3", "==", 3))
	assert_true(Conditions.compare("a", "!=", 1))


func test_is_true_shortcut() -> void:
	assert_true(Conditions.is_true(s, _rel("trust", ">=", 3)))
	assert_false(Conditions.is_true(s, _rel("trust", ">=", 5)))


func test_meter_condition() -> void:
	s.meters["suspicion"] = 40
	_yes({"if": "meter", "meter": "suspicion", "cmp": ">=", "value": 40})
	_no({"if": "meter", "meter": "marek_lean", "cmp": "<", "value": 0})
	_invalid({"if": "meter", "meter": "fear", "cmp": ">", "value": 1}, "unknown meter 'fear'")
