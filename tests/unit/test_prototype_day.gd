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


func test_window_choices_move_the_meters() -> void:
	_play_day([])  # first choice everywhere
	# +3 for the January card, +6 for the underground paper given to Mrs. Kowalczyk
	assert_eq(state.meters["suspicion"], 5 + 3 + 6)
	assert_eq(state.meters["solidarity"], 10 + 5)
	assert_eq(state.flags["coupon_shortfall"], 1, "the bad card's coupon does not count")
	# "Where are you going?" pushes Marek off the street: dM = -y * b * 10 = +10
	assert_eq(state.meters["marek_lean"], 30)
	assert_eq(state.meters["family"], 58)


func test_off_book_sales_come_back_as_manko() -> void:
	_play_day(["dlg_proto_trybuna.ask.c1", "dlg_proto_matches.ask.c1"])
	assert_eq(state.flags["unregistered_value"], 200, "Ruch will miss one paper and two boxes of matches")
	assert_eq(state.meters["suspicion"], 5 + 3 + 6 + 2 + 2)


func test_informing_trades_trust_for_safety() -> void:
	_play_day(["dlg_proto_neighbour.ask.c1", "dlg_proto_militia.ask.c1"])
	assert_eq(state.meters["solidarity"], 0, "10 - 15, clamped")
	assert_eq(state.meters["cooperation"], 15)
	assert_eq(state.meters["suspicion"], 5 + 3 - 5)


## The unseen half of the day around the visible one, as the prototype scene runs it.
func test_background_day_closes_the_book() -> void:
	var balance: Balance = Balance.from_record(db.get_record("balance", Balance.RECORD_ID))
	var sim: DaySimulator = DaySimulator.new(state, balance, db.all_of("item"))
	var report: Dictionary = sim.morning()
	assert_false(report["inspection"], "never on the first day")
	assert_true(int(report["delivered"].get("itm_cigarettes_popularne", 0)) > 0, "15 Feb 1982 is a Monday: the week's goods arrive")
	state = sim.state
	_play_day([])
	var window: Dictionary = ShiftPlan.ledger(state)
	sim.state = state
	report = sim.evening(sim.close(report))
	assert_true(sim.errors.is_empty(), "%s" % [sim.errors])
	var day: Dictionary = DaySimulator.day_summary(report, sim.state, 5)
	assert_true(day["routine_units"] > 0)
	assert_eq(sim.state.money["till"], balance.e("till_float"), "the till goes to Ruch, the float stays")
	var booked: int = int(window["registered_total"]) + int(day["routine_revenue"])
	assert_eq(day["commission_today"], booked * balance.e("commission_pct") / 100)
	assert_eq(day["household"], 2000000 - balance.e("household_cost_per_day"))
	assert_eq(sim.state.stock_count("shelf", "itm_trybuna_ludu") + sim.state.stock_count("backroom", "itm_trybuna_ludu"), 0, "unsold papers go back")
	assert_eq(day["suspicion_to"], 14)
	sim.night({})
	assert_eq(sim.state.day, 2)
	assert_eq(sim.state.calendar_date, "1982-02-16")
	assert_eq(sim.state.meters["suspicion"], 13, "the night takes one point")
