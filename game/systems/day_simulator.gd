class_name DaySimulator
extends RefCounted
## Plays whole days without a screen (demo steps 1-2): the background half of
## every real day, and the engine of tools/simulate.gd. The visible part of a
## day (customers at the window) is played by the kiosk scene in between
## morning() and close(); here it is simply skipped.
## A policy says how this player plays:
##   skim_pct        share of routine sales kept off the book (manko on Saturday)
##   under_counter   cigarette packs a day sold without a coupon, at a premium
##   usd_sunday_pct  share of the pocket changed into dollars every Sunday

var state: CampaignState
var economy: Economy
var balance: Balance
var policy: Dictionary = {"skim_pct": 0, "under_counter": 0, "usd_sunday_pct": 0}
var errors: PackedStringArray = []
## One summary per finished day, for reports.
var days: Array[Dictionary] = []


func _init(start: CampaignState, b: Balance, item_records: Array) -> void:
	state = start
	balance = b
	economy = Economy.new(b, item_records)


func apply(effects: Array[Dictionary]) -> bool:
	if effects.is_empty():
		return true
	var r: EffectPipeline.Result = EffectPipeline.apply(state, effects)
	if not r.ok:
		errors.append("day %d (%s): %s" % [state.day, state.calendar_date, r.error])
		return false
	state = r.state
	return true


## Morning: delivery, a possible inspection, the book is opened.
func morning() -> Dictionary:
	var report: Dictionary = {"day": state.day, "date": state.calendar_date, "weekday": Economy.weekday(state)}
	var delivery: Dictionary = economy.delivery_effects(state)
	apply(delivery["effects"])
	report["delivered"] = delivery["delivered"]
	report["inspection"] = false
	if economy.is_work_day(state) and Risk.inspection_today(state, balance):
		var found: Dictionary = Risk.inspection(state, balance, economy)
		apply(found["effects"])
		report["inspection"] = true
		report["inspection_result"] = found
	apply(economy.open_day_effects(state))
	apply([{"op": "phase_set", "phase": "shift"}])
	return report


## Closing: routine and under-the-counter sales, returns, commission, the till to Ruch.
## (The visible customers have already been played when the real game calls this.)
func close(report: Dictionary) -> Dictionary:
	var sales: Dictionary = economy.routine_sales(state, int(policy.get("skim_pct", 0)))
	apply(sales["effects"])
	var uc: Dictionary = economy.under_counter(state, int(policy.get("under_counter", 0)))
	apply(uc["effects"])
	var closing: Dictionary = economy.closing_effects(state)
	apply(closing["effects"])
	report["routine"] = sales
	report["under_counter"] = uc
	report["closing"] = closing
	if economy.is_payday(state):
		var settle: Dictionary = economy.settlement_effects(state)
		apply(settle["effects"])
		report["settlement"] = settle
	apply([{"op": "phase_set", "phase": "evening"}])
	return report


## Evening: family costs, and dollars on Sunday if the policy says so.
func evening(report: Dictionary) -> Dictionary:
	var home: Dictionary = economy.household_effects(state)
	apply(home["effects"])
	report["household"] = home
	if Economy.weekday(state) == 0 and int(policy.get("usd_sunday_pct", 0)) > 0:
		var budget: int = int(state.money.get("pocket", 0)) * int(policy["usd_sunday_pct"]) / 100
		var usd: Dictionary = economy.buy_dollars(state, budget)
		apply(usd["effects"])
		report["dollars_bought"] = usd["dollars"]
	return report


## Night: the attention fades, the next morning begins.
func night(report: Dictionary) -> Dictionary:
	apply(Risk.night_effects(balance))
	report["suspicion"] = state.meters["suspicion"]
	report["wealth"] = economy.wealth(state)
	apply([{"op": "phase_set", "phase": "night"}, {"op": "day_advance"}])
	days.append(report)
	return report


func evening_and_night(report: Dictionary) -> Dictionary:
	return night(evening(report))


## A full day without visible customers.
func run_day() -> Dictionary:
	var report: Dictionary = morning()
	close(report)
	return evening_and_night(report)


## The figures of a closed day for the closing book (prototype day-end panel).
## report: what morning(), close() and evening() returned; state: after evening().
static func day_summary(report: Dictionary, state: CampaignState, suspicion_from: int) -> Dictionary:
	var routine: Dictionary = report.get("routine", {})
	var closing: Dictionary = report.get("closing", {})
	var home: Dictionary = report.get("household", {})
	var units: int = 0
	for item_id: Variant in routine.get("units", {}):
		units += int(routine["units"][item_id])
	var returned: int = 0
	for item_id: Variant in closing.get("returned", {}):
		returned += int(closing["returned"][item_id])
	return {
		"routine_units": units,
		"routine_revenue": int(routine.get("revenue", 0)),
		"returned": returned,
		"handover": int(closing.get("handover", 0)),
		"commission_today": int(closing.get("commission", 0)),
		"commission_week": int(state.money.get("commission", 0)),
		"settlement": report.get("settlement", {}),
		"household_cost": int(home.get("cost", 0)),
		"unpaid": int(home.get("unpaid", 0)),
		"household": int(state.money.get("household", 0)),
		"pocket": int(state.money.get("pocket", 0)),
		"suspicion_from": suspicion_from,
		"suspicion_to": int(state.meters.get("suspicion", 0)),
		"inspection": report.get("inspection_result", {}),
	}


func run_days(count: int) -> void:
	for i: int in count:
		if state.flags.get("license_lost", false) == true:
			break
		run_day()
