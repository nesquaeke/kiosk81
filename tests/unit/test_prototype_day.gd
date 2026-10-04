extends TestCase
## Documents, the shift plan and a whole prototype day played without a screen.

const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")

var db: Node
var scenario: Dictionary
var state: CampaignState
var shown_lines: PackedStringArray = []


func before_each() -> void:
	db = ContentDBScript.new()
	db.load_roots(ContentDBScript.DEFAULT_ROOTS)
	scenario = db.get_record("scenario", "scn_prototype")
	state = CampaignState.from_dict(scenario["start"])
	shown_lines.clear()


func after_each() -> void:
	db.free()


func _apply(effects: Array[Dictionary]) -> void:
	var r: EffectPipeline.Result = EffectPipeline.apply(state, effects)
	assert_true(r.ok, r.error)
	if r.ok:
		state = r.state


## Plays the day. `prefer` lists choice keys to take when offered; otherwise the first choice.
func _play_day(prefer: PackedStringArray) -> void:
	var plan: ShiftPlan = ShiftPlan.new(scenario)
	_apply(plan.opening_effects(state))
	var guard: int = 0
	while guard < 50:
		guard += 1
		var visit: Dictionary = plan.next_visit(state)
		if visit.is_empty():
			break
		_apply(plan.arrival_effects(visit, state))
		var runner: DialogueRunner = DialogueRunner.new(db.get_record("dialogue", visit["dialogue"]))
		var step: DialogueRunner.Step = runner.start(state)
		var steps: int = 0
		while step != null and steps < 20:
			steps += 1
			_apply(step.effects)
			for line: Dictionary in step.lines:
				shown_lines.append(line["key"])
			if step.finished:
				break
			var pick: int = step.choices[0]["index"]
			for choice: Dictionary in step.choices:
				if choice["key"] in prefer:
					pick = choice["index"]
					break
			_apply(runner.choose(pick))
			step = runner.next(state)
		assert_true(runner.is_over(), "%s must end" % visit["dialogue"])
		_apply(plan.departure_effects(visit))
	_apply(plan.closing_effects(state))


func test_ration_card_rules() -> void:
	var card: Dictionary = {"kind": "ration_card", "holder": "Zofia Nowak", "month": "1982-02", "stamped": true, "coupons_left": 1, "category": "tobacco"}
	assert_eq(DocumentRules.problems(card, state), PackedStringArray())
	var old: Dictionary = card.duplicate()
	old["month"] = "1982-01"
	old["stamped"] = false
	assert_eq(DocumentRules.problems(old, state), PackedStringArray(["wrong_month", "no_stamp"]))
	var empty: Dictionary = card.duplicate()
	empty["coupons_left"] = 0
	empty["holder"] = ""
	assert_eq(DocumentRules.problems(empty, state), PackedStringArray(["no_name", "no_coupons"]))


func test_document_flags_reach_the_dialogue() -> void:
	var card: Dictionary = {"kind": "ration_card", "holder": "X", "month": "1982-01", "stamped": true, "coupons_left": 1, "category": "tobacco"}
	_apply(DocumentRules.present_effects(card, state))
	assert_eq(state.flags["doc_ok"], false)
	assert_eq(state.flags["doc_problem"], "wrong_month")
	_apply(DocumentRules.clear_effects())
	assert_eq(state.flags["doc_present"], false)


func test_scenario_document_validation() -> void:
	var errors: PackedStringArray = DocumentRules.validate({"kind": "ration_card", "holder": "X", "month": "Feb", "stamped": "yes", "category": "tobacco", "colour": 1}, "doc")
	assert_eq(errors.size(), 4, "%s" % [errors])  # month, stamped, missing coupons_left, unknown colour


func test_honest_day_balances_the_book() -> void:
	_play_day([])  # first choice everywhere: sell and write it in the book
	var book: Dictionary = ShiftPlan.ledger(state)
	assert_eq(book["visits_served"], 8)
	assert_eq(book["till_mismatch"], 0, "every grosz in the till is in the book")
	assert_eq(book["unregistered_sales"], 0)
	# Only two packs on the shelf and nobody restocks: the January card gets one,
	# the old woman with the unstamped card finds the shelf empty and is refused.
	assert_eq(book["bad_cards_accepted"], 1)
	assert_eq(state.stock_count("shelf", "itm_cigarettes_popularne"), 0)
	assert_eq(state.phase, "closing")
	assert_eq(state.minute_of_day, ShiftPlan.CLOSING_MINUTE)


func test_coins_in_the_pocket_show_up_in_the_ledger() -> void:
	_play_day(["dlg_proto_trybuna.ask.c1", "dlg_proto_matches.ask.c1"])
	var book: Dictionary = ShiftPlan.ledger(state)
	assert_eq(book["unregistered_sales"], 2)
	assert_eq(book["pocket"], 200)
	assert_eq(book["till_mismatch"], 0, "pocket money never touches the till")


func test_informing_reaches_marek_the_same_day() -> void:
	_play_day(["dlg_proto_neighbour.ask.c1", "dlg_proto_militia.ask.c1"])
	assert_true("dlg_proto_marek.ask.l1" in shown_lines, "Marek mentions Mrs. Kowalczyk")
	var informed: bool = false
	for entry: Dictionary in state.decision_log:
		informed = informed or entry.get("id") == "informed_on_neighbour"
	assert_true(informed)


func test_silence_keeps_marek_unaware() -> void:
	_play_day(["dlg_proto_militia.ask.c0"])
	assert_false("dlg_proto_marek.ask.l1" in shown_lines)


func test_bribe_only_for_the_january_card() -> void:
	_play_day(["dlg_proto_cigarettes.ask.c2"])
	var book: Dictionary = ShiftPlan.ledger(state)
	assert_eq(book["pocket"], 2000, "one bribe: only the young man offers it")


func test_day_ends_early_when_time_runs_out() -> void:
	state.minute_of_day = ShiftPlan.CLOSING_MINUTE - 5
	var plan: ShiftPlan = ShiftPlan.new(scenario)
	assert_true(plan.next_visit(state).is_empty())
