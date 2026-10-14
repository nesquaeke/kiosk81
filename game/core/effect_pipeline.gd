class_name EffectPipeline
extends RefCounted
## Applies a list of effects to a COPY of the campaign state.
## Either every effect applies and every invariant holds, or nothing
## changes and the caller gets the reason. Effects are plain dictionaries
## like {"op": "money_add", "account": "till", "amount": 290}.
## The "when" op branches on a condition (docs/CONDITION_LANGUAGE.md); the
## condition sees the state as left by the effects before it in the list.


## Required fields per op (name -> Variant type). Shared by apply() and validate_effects().
## Fields with a fixed set of values are checked against CampaignState lists too.
const OP_FIELDS: Dictionary = {
	"money_add": {"account": TYPE_STRING, "amount": TYPE_INT},
	"stock_add": {"location": TYPE_STRING, "item": TYPE_STRING, "qty": TYPE_INT},
	"stock_move": {"from": TYPE_STRING, "to": TYPE_STRING, "item": TYPE_STRING, "qty": TYPE_INT},
	"register_append": {"entry": TYPE_DICTIONARY},
	"flag_set": {"key": TYPE_STRING, "value": TYPE_NIL},  # TYPE_NIL = any type
	"flag_add": {"key": TYPE_STRING, "amount": TYPE_INT},  # counter; a missing flag counts as 0
	"clock_advance": {"minutes": TYPE_INT},
	"phase_set": {"phase": TYPE_STRING},
	"relation_add": {"character": TYPE_STRING, "dimension": TYPE_STRING, "amount": TYPE_INT},
	"memory_add": {"character": TYPE_STRING, "memory": TYPE_DICTIONARY},
	"decision_log": {"entry": TYPE_DICTIONARY},
	"day_advance": {},  # next morning: day + 1, date + 1, 07:30, phase "morning"
	"meter_add": {"meter": TYPE_STRING, "amount": TYPE_INT},  # clamped to the meter's range
	"when": {"if": TYPE_NIL, "then": TYPE_ARRAY},
}
const OPTIONAL_FIELDS: Dictionary = {"when": ["else"]}


class Result:
	extends RefCounted
	var ok: bool = false
	var state: CampaignState = null
	var error: String = ""
	var op_index: int = -1


static func apply(state: CampaignState, effects: Array[Dictionary]) -> Result:
	var result: Result = Result.new()
	var work: CampaignState = state.duplicate_state()
	for i: int in effects.size():
		var error: String = _apply_one(work, effects[i])
		if error != "":
			result.error = "effect %d (%s): %s" % [i, str(effects[i].get("op", "?")), error]
			result.op_index = i
			return result
	var broken: String = check_invariants(work)
	if broken != "":
		result.error = "invariant: " + broken
		return result
	result.ok = true
	result.state = work
	return result


## Returns "" when the state is valid, otherwise the first problem found.
static func check_invariants(s: CampaignState) -> String:
	for account: String in s.money:
		if not account in CampaignState.ACCOUNTS:
			return "unknown account '%s'" % account
		if s.money[account] < 0:
			return "account '%s' is negative (%d)" % [account, s.money[account]]
	for location: String in s.stock:
		if not location in CampaignState.STOCK_LOCATIONS:
			return "unknown stock location '%s'" % location
		var items: Dictionary = s.stock[location]
		for item_id: String in items:
			if int(items[item_id]) < 0:
				return "stock %s/%s is negative" % [location, item_id]
	for location: String in ["hand", "counter"]:
		var units: int = 0
		for item_id: String in s.stock.get(location, {}):
			units += s.stock_count(location, item_id)
		if units > 1:
			return "%s can hold only one product" % location
	for meter: String in s.meters:
		if not CampaignState.METERS.has(meter):
			return "unknown meter '%s'" % meter
		var bounds: Array = CampaignState.METERS[meter]
		if s.meters[meter] < int(bounds[0]) or s.meters[meter] > int(bounds[1]):
			return "meter '%s' out of range (%d)" % [meter, s.meters[meter]]
	if not s.phase in CampaignState.PHASES:
		return "unknown phase '%s'" % s.phase
	if s.minute_of_day < 0 or s.minute_of_day >= 24 * 60:
		return "minute_of_day out of range (%d)" % s.minute_of_day
	return ""


static func _apply_one(s: CampaignState, effect: Dictionary) -> String:
	var op: String = str(effect.get("op", ""))
	match op:
		"money_add":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var account: String = effect["account"]
			if not account in CampaignState.ACCOUNTS:
				return "unknown account '%s'" % account
			s.money[account] = s.money.get(account, 0) + int(effect["amount"])
		"stock_add":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var location: String = effect["location"]
			if not location in CampaignState.STOCK_LOCATIONS:
				return "unknown stock location '%s'" % location
			var items: Dictionary = s.stock[location]
			var item_id: String = effect["item"]
			items[item_id] = int(items.get(item_id, 0)) + int(effect["qty"])
		"stock_move":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var qty: int = effect["qty"]
			if qty <= 0:
				return "qty must be positive"
			var from_loc: String = effect["from"]
			var to_loc: String = effect["to"]
			if not from_loc in CampaignState.STOCK_LOCATIONS or not to_loc in CampaignState.STOCK_LOCATIONS:
				return "unknown stock location"
			var item: String = effect["item"]
			if s.stock_count(from_loc, item) < qty:
				return "not enough %s in %s" % [item, from_loc]
			s.stock[from_loc][item] = s.stock_count(from_loc, item) - qty
			s.stock[to_loc][item] = s.stock_count(to_loc, item) + qty
		"register_append":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var entry: Dictionary = (effect["entry"] as Dictionary).duplicate(true)
			entry["day"] = s.day
			entry["minute"] = s.minute_of_day
			s.register.append(entry)
		"flag_set":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			s.flags[effect["key"]] = effect["value"]
		"flag_add":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var current: Variant = s.flags.get(effect["key"], 0)
			if typeof(current) != TYPE_INT:
				return "flag '%s' is not a counter" % effect["key"]
			s.flags[effect["key"]] = int(current) + int(effect["amount"])
		"meter_add":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var meter: String = effect["meter"]
			if not CampaignState.METERS.has(meter):
				return "unknown meter '%s'" % meter
			var bounds: Array = CampaignState.METERS[meter]
			s.meters[meter] = clampi(int(s.meters.get(meter, bounds[2])) + int(effect["amount"]), bounds[0], bounds[1])
		"day_advance":
			s.day += 1
			s.calendar_date = next_date(s.calendar_date)
			s.minute_of_day = CampaignState.DAY_START_MINUTE
			s.phase = "morning"
		"clock_advance":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			if int(effect["minutes"]) <= 0:
				return "minutes must be positive"
			s.minute_of_day += int(effect["minutes"])
		"phase_set":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			if not effect["phase"] in CampaignState.PHASES:
				return "unknown phase '%s'" % effect["phase"]
			s.phase = effect["phase"]
		"relation_add":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var dimension: String = effect["dimension"]
			if not dimension in CampaignState.RELATIONS:
				return "unknown relation '%s'" % dimension
			var character: Dictionary = s.ensure_character(effect["character"])
			var relations: Dictionary = character["relations"]
			relations[dimension] = int(relations.get(dimension, 0)) + int(effect["amount"])
		"memory_add":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var memory: Dictionary = (effect["memory"] as Dictionary).duplicate(true)
			memory["day"] = s.day
			var who: Dictionary = s.ensure_character(effect["character"])
			(who["memories"] as Array).append(memory)
		"decision_log":
			var need: String = _require(effect, OP_FIELDS[op])
			if need != "":
				return need
			var decision: Dictionary = (effect["entry"] as Dictionary).duplicate(true)
			decision["day"] = s.day
			decision["minute"] = s.minute_of_day
			s.decision_log.append(decision)
		"when":
			return _apply_when(s, effect)
		"":
			return "missing 'op'"
		_:
			return "unknown op '%s'" % op
	return ""


## {"op": "when", "if": <condition>, "then": [effects], "else": [effects]}; "else" is optional.
static func _apply_when(s: CampaignState, effect: Dictionary) -> String:
	if not effect.has("if"):
		return "missing field 'if'"
	if not effect.has("then"):
		return "missing field 'then'"
	var check: Conditions.Result = Conditions.evaluate(s, effect["if"])
	if not check.ok:
		return "condition: " + check.error
	var branch_name: String = "then" if check.value else "else"
	var branch: Variant = effect.get(branch_name, [])
	if typeof(branch) != TYPE_ARRAY:
		return "field '%s' must be a list of effects" % branch_name
	var steps: Array = branch
	for j: int in steps.size():
		if typeof(steps[j]) != TYPE_DICTIONARY:
			return "%s[%d] is not an effect" % [branch_name, j]
		var step: Dictionary = steps[j]
		var error: String = _apply_one(s, step)
		if error != "":
			return "%s[%d] (%s): %s" % [branch_name, j, str(step.get("op", "?")), error]
	return ""


## "1981-12-31" -> "1982-01-01".
static func next_date(iso_date: String) -> String:
	var unix: int = Time.get_unix_time_from_datetime_string(iso_date + "T12:00:00")
	return Time.get_date_string_from_unix_time(unix + 86400)


## Checks that every required field exists with the right type.
static func _require(effect: Dictionary, fields: Dictionary) -> String:
	for field: String in fields:
		if not effect.has(field):
			return "missing field '%s'" % field
		if int(fields[field]) != TYPE_NIL and typeof(effect[field]) != int(fields[field]):
			return "field '%s' has the wrong type" % field
	return ""


## Static shape check for content files (no state needed): op names, required
## fields and types, unknown fields, fixed value lists, nested "when" branches.
## Returns every problem, each prefixed with its path, e.g. "[2].then[0]: ...".
static func validate_effects(effects: Variant, path: String = "") -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(effects) != TYPE_ARRAY:
		errors.append("%s: effects must be a list" % (path if path != "" else "effects"))
		return errors
	var list: Array = effects
	for i: int in list.size():
		var here: String = "%s[%d]" % [path, i]
		if typeof(list[i]) != TYPE_DICTIONARY:
			errors.append("%s: an effect must be an object" % here)
			continue
		var effect: Dictionary = list[i]
		var op: String = str(effect.get("op", ""))
		if not OP_FIELDS.has(op):
			errors.append("%s: %s" % [here, "missing 'op'" if op == "" else "unknown op '%s'" % op])
			continue
		var fields: Dictionary = OP_FIELDS[op]
		var problem: String = _require(effect, fields)
		if problem == "":
			problem = _check_known_fields(op, effect)
		if problem == "":
			problem = _check_values(op, effect)
		if problem != "":
			errors.append("%s (%s): %s" % [here, op, problem])
			continue
		if op == "when":
			for problem_text: String in Conditions.validate(effect["if"], here + ".if"):
				errors.append(problem_text)
			errors.append_array(validate_effects(effect["then"], here + ".then"))
			if effect.has("else"):
				errors.append_array(validate_effects(effect["else"], here + ".else"))
	return errors


static func _check_known_fields(op: String, effect: Dictionary) -> String:
	var allowed: Array = (OP_FIELDS[op] as Dictionary).keys()
	allowed.append("op")
	allowed.append_array(OPTIONAL_FIELDS.get(op, []))
	for field: Variant in effect:
		if not field in allowed:
			return "unknown field '%s'" % str(field)
	return ""


static func _check_values(op: String, effect: Dictionary) -> String:
	match op:
		"money_add":
			if not effect["account"] in CampaignState.ACCOUNTS:
				return "unknown account '%s'" % effect["account"]
		"stock_add":
			if not effect["location"] in CampaignState.STOCK_LOCATIONS:
				return "unknown stock location '%s'" % effect["location"]
		"stock_move":
			if not effect["from"] in CampaignState.STOCK_LOCATIONS or not effect["to"] in CampaignState.STOCK_LOCATIONS:
				return "unknown stock location"
			if int(effect["qty"]) <= 0:
				return "qty must be positive"
		"clock_advance":
			if int(effect["minutes"]) <= 0:
				return "minutes must be positive"
		"phase_set":
			if not effect["phase"] in CampaignState.PHASES:
				return "unknown phase '%s'" % effect["phase"]
		"relation_add":
			if not effect["dimension"] in CampaignState.RELATIONS:
				return "unknown relation '%s'" % effect["dimension"]
		"meter_add":
			if not CampaignState.METERS.has(effect["meter"]):
				return "unknown meter '%s'" % effect["meter"]
	return ""
