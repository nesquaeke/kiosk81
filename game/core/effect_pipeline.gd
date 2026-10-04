class_name EffectPipeline
extends RefCounted
## Applies a list of effects to a COPY of the campaign state.
## Either every effect applies and every invariant holds, or nothing
## changes and the caller gets the reason. Effects are plain dictionaries
## like {"op": "money_add", "account": "till", "amount": 290}.
## The "when" op branches on a condition (docs/CONDITION_LANGUAGE.md); the
## condition sees the state as left by the effects before it in the list.


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
	if not s.phase in CampaignState.PHASES:
		return "unknown phase '%s'" % s.phase
	if s.minute_of_day < 0 or s.minute_of_day >= 24 * 60:
		return "minute_of_day out of range (%d)" % s.minute_of_day
	return ""


static func _apply_one(s: CampaignState, effect: Dictionary) -> String:
	var op: String = str(effect.get("op", ""))
	match op:
		"money_add":
			var need: String = _require(effect, {"account": TYPE_STRING, "amount": TYPE_INT})
			if need != "":
				return need
			var account: String = effect["account"]
			if not account in CampaignState.ACCOUNTS:
				return "unknown account '%s'" % account
			s.money[account] = s.money.get(account, 0) + int(effect["amount"])
		"stock_add":
			var need: String = _require(effect, {"location": TYPE_STRING, "item": TYPE_STRING, "qty": TYPE_INT})
			if need != "":
				return need
			var location: String = effect["location"]
			if not location in CampaignState.STOCK_LOCATIONS:
				return "unknown stock location '%s'" % location
			var items: Dictionary = s.stock[location]
			var item_id: String = effect["item"]
			items[item_id] = int(items.get(item_id, 0)) + int(effect["qty"])
		"stock_move":
			var need: String = _require(effect, {"from": TYPE_STRING, "to": TYPE_STRING, "item": TYPE_STRING, "qty": TYPE_INT})
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
			var need: String = _require(effect, {"entry": TYPE_DICTIONARY})
			if need != "":
				return need
			var entry: Dictionary = (effect["entry"] as Dictionary).duplicate(true)
			entry["day"] = s.day
			entry["minute"] = s.minute_of_day
			s.register.append(entry)
		"flag_set":
			var need: String = _require(effect, {"key": TYPE_STRING})
			if need != "":
				return need
			if not effect.has("value"):
				return "missing field 'value'"
			s.flags[effect["key"]] = effect["value"]
		"clock_advance":
			var need: String = _require(effect, {"minutes": TYPE_INT})
			if need != "":
				return need
			if int(effect["minutes"]) <= 0:
				return "minutes must be positive"
			s.minute_of_day += int(effect["minutes"])
		"phase_set":
			var need: String = _require(effect, {"phase": TYPE_STRING})
			if need != "":
				return need
			s.phase = effect["phase"]
		"relation_add":
			var need: String = _require(effect, {"character": TYPE_STRING, "dimension": TYPE_STRING, "amount": TYPE_INT})
			if need != "":
				return need
			var dimension: String = effect["dimension"]
			if not dimension in CampaignState.RELATIONS:
				return "unknown relation '%s'" % dimension
			var character: Dictionary = s.ensure_character(effect["character"])
			var relations: Dictionary = character["relations"]
			relations[dimension] = int(relations.get(dimension, 0)) + int(effect["amount"])
		"memory_add":
			var need: String = _require(effect, {"character": TYPE_STRING, "memory": TYPE_DICTIONARY})
			if need != "":
				return need
			var memory: Dictionary = (effect["memory"] as Dictionary).duplicate(true)
			memory["day"] = s.day
			var who: Dictionary = s.ensure_character(effect["character"])
			(who["memories"] as Array).append(memory)
		"decision_log":
			var need: String = _require(effect, {"entry": TYPE_DICTIONARY})
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


## Checks that every required field exists with the right type.
static func _require(effect: Dictionary, fields: Dictionary) -> String:
	for field: String in fields:
		if not effect.has(field):
			return "missing field '%s'" % field
		if typeof(effect[field]) != int(fields[field]):
			return "field '%s' has the wrong type" % field
	return ""
