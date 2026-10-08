extends TestCase
## Demo steps 1-2: the money skeleton (Economy), the attention model (Risk)
## and whole simulated days (DaySimulator).

const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")
const SimulateScript: GDScript = preload("res://tools/simulate.gd")

var db: Node
var balance: Balance
var items: Array
var eco: Economy
var s: CampaignState


func before_each() -> void:
	db = ContentDBScript.new()
	db.load_roots(ContentDBScript.DEFAULT_ROOTS)
	balance = Balance.from_record(db.get_record("balance", Balance.RECORD_ID))
	items = db.all_of("item")
	eco = Economy.new(balance, items)
	s = SimulateScript.start_state(7)  # Monday 14 December 1981, campaign day 2


func after_each() -> void:
	db.free()


func _apply(effects: Array[Dictionary]) -> void:
	var r: EffectPipeline.Result = EffectPipeline.apply(s, effects)
	assert_true(r.ok, r.error)
	if r.ok:
		s = r.state


func test_balance_file_is_valid() -> void:
	assert_eq(db.errors.size(), 0, "%s" % [db.errors])
	assert_eq(balance.e("commission_pct"), 10)
	var broken: Dictionary = db.get_record("balance", Balance.RECORD_ID).duplicate(true)
	(broken["risk"] as Dictionary).erase("daily_decay")
	(broken["economy"] as Dictionary)["typo_key"] = 1
	assert_eq(Balance.validate(broken, "b").size(), 2)


func test_calendar() -> void:
	assert_eq(Economy.weekday(s), 1, "14 December 1981 was a Monday")
	assert_true(eco.is_work_day(s))
	s.calendar_date = "1981-12-20"
	assert_false(eco.is_work_day(s), "Sunday")
	s.calendar_date = "1981-12-19"
	assert_true(eco.is_payday(s), "Saturday")


func test_monday_delivery_brings_the_week() -> void:
	var d: Dictionary = eco.delivery_effects(s)
	_apply(d["effects"])
	assert_true(s.stock_count("backroom", "itm_cigarettes_popularne") >= 480 * 85 / 100, "at most 15% short")
	assert_true(s.stock_count("backroom", "itm_trybuna_ludu") > 0, "newspapers every work day")
	s.calendar_date = "1981-12-15"
	var tuesday: Dictionary = eco.delivery_effects(s)
	assert_false((tuesday["delivered"] as Dictionary).has("itm_matches"), "weekly goods only on Monday")


func test_routine_sales_go_into_till_and_book() -> void:
	_apply(eco.delivery_effects(s)["effects"])
	_apply(eco.open_day_effects(s))
	var sales: Dictionary = eco.routine_sales(s)
	_apply(sales["effects"])
	assert_true(int(sales["revenue"]) > 250000, "a normal day is roughly 3000 zl")
	assert_eq(s.money["till"], 2000 + int(sales["revenue"]))
	assert_eq(int(ShiftPlan.ledger(s)["registered_total"]), int(sales["revenue"]))


func test_skimming_comes_back_as_manko() -> void:
	_apply(eco.delivery_effects(s)["effects"])
	_apply(eco.open_day_effects(s))
	var sales: Dictionary = eco.routine_sales(s, 10)
	_apply(sales["effects"])
	var skimmed: int = sales["skimmed"]
	assert_true(skimmed > 0)
	assert_eq(s.money["pocket"], skimmed)
	_apply(eco.closing_effects(s)["effects"])
	var before: int = s.money["household"]
	var settle: Dictionary = eco.settlement_effects(s)
	_apply(settle["effects"])
	assert_eq(settle["manko"], skimmed)
	assert_eq(s.money["household"], before + int(settle["commission"]) - skimmed, "Ruch takes the skim back")


func test_closing_returns_papers_and_hands_over_the_till() -> void:
	_apply(eco.delivery_effects(s)["effects"])
	_apply(eco.open_day_effects(s))
	_apply(eco.routine_sales(s)["effects"])
	var c: Dictionary = eco.closing_effects(s)
	_apply(c["effects"])
	assert_eq(s.stock_count("backroom", "itm_trybuna_ludu") + s.stock_count("shelf", "itm_trybuna_ludu"), 0, "unsold papers go back")
	assert_eq(s.money["till"], balance.e("till_float"))
	assert_eq(s.money["commission"], int(c["booked"]) / 10)


func test_under_the_counter() -> void:
	_apply(eco.delivery_effects(s)["effects"])
	var uc: Dictionary = eco.under_counter(s, 10)
	_apply(uc["effects"])
	assert_eq(uc["sold"], 10)
	assert_eq(s.money["pocket"], 10 * 1800 / 2, "50% premium")
	assert_eq(s.flags["coupon_shortfall"], 10)
	assert_eq(s.meters["suspicion"], 6, "start 5, +1 per 10 packs")


func test_household_pays_from_budget_then_pocket() -> void:
	s.money["household"] = 10000
	s.money["pocket"] = 5000
	var h: Dictionary = eco.household_effects(s)
	_apply(h["effects"])
	assert_eq(s.money["household"], 0)
	assert_eq(s.money["pocket"], 0)
	assert_eq(s.flags["household_shortfall"], 15000)
	assert_eq(s.meters["family"], 57)


func test_buy_dollars() -> void:
	s.money["pocket"] = 100000  # 1000 zl
	var usd: Dictionary = eco.buy_dollars(s, 100000)
	_apply(usd["effects"])
	assert_eq(usd["dollars"], 2, "400 zl a dollar")
	assert_eq(s.money["usd"], 200)
	assert_eq(s.money["pocket"], 20000)


func test_inspection_chance_grows_with_suspicion() -> void:
	s.meters["suspicion"] = 0
	assert_eq(Risk.inspection_permille(s, balance), 15)
	s.meters["suspicion"] = 50
	assert_eq(Risk.inspection_permille(s, balance), 265)
	s.meters["suspicion"] = 100
	assert_eq(Risk.inspection_permille(s, balance), 500, "capped")
	s.day = 1
	s.meters["suspicion"] = 100
	assert_false(Risk.inspection_today(s, balance), "never on the first day")


func test_inspection_clean_and_fined() -> void:
	var clean: Dictionary = Risk.inspection(s, balance, eco)
	_apply(clean["effects"])
	assert_true(clean["clean"])
	assert_eq(s.meters["suspicion"], 0, "a clean inspection reassures")
	# A big coupon gap is found often; force it by trying seeds until one detects.
	var found: Dictionary = {}
	for seed_value: int in 40:
		s.rng_seed = seed_value
		s.flags["coupon_shortfall"] = 120
		found = Risk.inspection(s, balance, eco)
		if found["found_coupons"]:
			break
	assert_true(found["found_coupons"], "90% detection for 120 missing coupons")
	assert_eq(found["fine"], 120 * 1800)
	assert_eq(found["strikes"], 1, "a big gap is a strike")


func test_three_strikes_lose_the_license() -> void:
	s.flags["strikes"] = 2
	s.stock["hidden"]["itm_tygodnik_mazowsze"] = 5
	var lost: Dictionary = {}
	for seed_value: int in 60:
		s.rng_seed = seed_value
		lost = Risk.inspection(s, balance, eco)
		if lost["found_hidden"]:
			break
	assert_true(lost["found_hidden"])
	assert_true(lost["license_lost"])
	_apply(lost["effects"])
	assert_eq(s.stock_count("hidden", "itm_tygodnik_mazowsze"), 0, "confiscated")
	assert_eq(s.flags["license_lost"], true)


func test_simulated_week_is_repeatable_and_clean() -> void:
	var a: DaySimulator = DaySimulator.new(SimulateScript.start_state(42), balance, items)
	var b: DaySimulator = DaySimulator.new(SimulateScript.start_state(42), balance, items)
	a.policy = {"skim_pct": 0, "under_counter": 10, "usd_sunday_pct": 50}
	b.policy = a.policy
	a.run_days(7)
	b.run_days(7)
	assert_eq(a.errors.size(), 0, "%s" % [a.errors])
	assert_eq(a.state.to_dict(), b.state.to_dict(), "same seed, same week")
	assert_eq(a.state.calendar_date, "1981-12-21")
	assert_eq(a.days.size(), 7)
	assert_eq(a.state.money["commission"], 0, "paid out on Saturday")


func test_honest_month_drifts_down_slowly() -> void:
	var sim: DaySimulator = DaySimulator.new(SimulateScript.start_state(3), balance, items)
	var start: int = sim.economy.wealth(sim.state)
	sim.run_days(28)
	var change: int = sim.economy.wealth(sim.state) - start
	assert_true(change < 0 and change > -start / 10, "honest: the family slowly loses ground (%s)" % Money.format(change))
