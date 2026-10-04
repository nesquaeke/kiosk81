class_name ShiftPlan
extends RefCounted
## One working day at the kiosk window (roadmap 2.8–2.10, prototype version).
## Pure logic: it reads the scenario and the state and returns effects; the
## scene applies them through Game.apply_effects and plays the visit.
##   plan.opening_effects(state)        morning -> shift, remember the opening till
##   plan.next_visit(state)             the next visit whose condition holds, or {}
##   plan.arrival_effects(visit, state) time passes, document flags are set
##   plan.departure_effects(visit)      document flags cleared, visit counted
##   plan.closing_effects(state)        clock to 18:00, phase closing
##   ShiftPlan.ledger(state)            the day's figures for the closing book

const OPENING_MINUTES: int = 15
const CLOSING_MINUTE: int = 18 * 60
const DEFAULT_ARRIVE_MINUTES: int = 10

var scenario: Dictionary
var _index: int = -1


func _init(scenario_record: Dictionary) -> void:
	scenario = scenario_record


func visits() -> Array:
	return scenario.get("visits", [])


func current_index() -> int:
	return _index


func opening_effects(state: CampaignState) -> Array[Dictionary]:
	return [
		{"op": "phase_set", "phase": "shift"},
		{"op": "clock_advance", "minutes": OPENING_MINUTES},
		{"op": "flag_set", "key": "day_start_till", "value": state.money.get("till", 0)},
		{"op": "flag_set", "key": "day_start_register", "value": state.register.size()},
	]


## Moves to the next visit that may happen now. Returns {} when the day is done.
func next_visit(state: CampaignState) -> Dictionary:
	var list: Array = visits()
	while _index + 1 < list.size():
		_index += 1
		var visit: Dictionary = list[_index]
		var arrive: int = int(visit.get("arrive_minutes", DEFAULT_ARRIVE_MINUTES))
		if state.minute_of_day + arrive >= CLOSING_MINUTE:
			_index = list.size()
			return {}
		if visit.has("if") and not Conditions.is_true(state, visit["if"]):
			continue
		return visit
	return {}


func arrival_effects(visit: Dictionary, state: CampaignState) -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"op": "clock_advance", "minutes": int(visit.get("arrive_minutes", DEFAULT_ARRIVE_MINUTES))}]
	if visit.has("document"):
		out.append_array(DocumentRules.present_effects(visit["document"], state))
	else:
		out.append_array(DocumentRules.clear_effects())
	return out


func departure_effects(_visit: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = DocumentRules.clear_effects()
	out.append({"op": "flag_add", "key": "visits_served", "amount": 1})
	return out


func closing_effects(state: CampaignState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if state.minute_of_day < CLOSING_MINUTE:
		out.append({"op": "clock_advance", "minutes": CLOSING_MINUTE - state.minute_of_day})
	out.append({"op": "phase_set", "phase": "closing"})
	return out


## Visit key for the customer's display name: "<scenario id>.v<index>.customer".
func customer_key(index: int) -> String:
	return "%s.v%d.customer" % [str(scenario.get("id", "")), index]


## The day's figures. Registered sales should explain every grosz the till
## gained; coins kept in the pocket and bad cards are what an inspector finds.
static func ledger(state: CampaignState) -> Dictionary:
	var start_till: int = int(state.flags.get("day_start_till", 0))
	var first_entry: int = int(state.flags.get("day_start_register", 0))
	var registered_total: int = 0
	var registered_count: int = 0
	for i: int in range(first_entry, state.register.size()):
		var entry: Dictionary = state.register[i]
		registered_total += int(entry.get("price", 0)) * int(entry.get("qty", 1))
		registered_count += int(entry.get("qty", 1))
	var till: int = int(state.money.get("till", 0))
	return {
		"till": till,
		"till_gain": till - start_till,
		"registered_total": registered_total,
		"registered_count": registered_count,
		"till_mismatch": (till - start_till) - registered_total,
		"pocket": int(state.money.get("pocket", 0)),
		"unregistered_sales": int(state.flags.get("unregistered_sales", 0)),
		"bad_cards_accepted": int(state.flags.get("bad_cards_accepted", 0)),
		"good_cards_refused": int(state.flags.get("good_cards_refused", 0)),
		"visits_served": int(state.flags.get("visits_served", 0)),
	}
