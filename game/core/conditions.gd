class_name Conditions
extends RefCounted
## Condition language v0 (roadmap 1.7). Full description: docs/CONDITION_LANGUAGE.md.
## A condition is plain data and only READS the campaign state:
##   true / false                       always / never
##   [c1, c2]                           shorthand for {"all": [c1, c2]}
##   {"all": [...]} {"any": [...]} {"not": c}
##   {"if": "relation", "character": "halina", "dimension": "trust", "cmp": ">=", "value": 3}
## The whole tree is validated before it is evaluated, so a typo in a branch
## that short-circuiting would skip is still reported.

const COMPARATORS: PackedStringArray = ["==", "!=", "<", "<=", ">", ">="]
const STOCK_TOTAL: String = "total"  # stock test: sum over every location
const DEFAULT_STATUS: String = "active"

## Leaf tests: field -> kind of value. A trailing "?" marks an optional field.
const LEAVES: Dictionary = {
	"flag": {"key": "string", "cmp?": "cmp", "value?": "any"},
	"relation": {"character": "string", "dimension": "relation", "cmp": "cmp", "value": "int"},
	"money": {"account": "account", "cmp": "cmp", "value": "int"},
	"meter": {"meter": "meter", "cmp": "cmp", "value": "int"},
	"stock": {"location": "stock_location", "item": "string", "cmp": "cmp", "value": "int"},
	"day": {"cmp": "cmp", "value": "int"},
	"date": {"cmp": "cmp", "value": "date"},
	"time": {"cmp": "cmp", "value": "time"},
	"phase": {"is": "phases"},
	"status": {"character": "string", "is": "names"},
	"memory": {"character": "string", "id": "string"},
	"decision": {"id": "string"},
}


class Result:
	extends RefCounted
	var ok: bool = true
	var value: bool = false
	var error: String = ""


## Validates, then evaluates. On a malformed condition ok is false and value is false.
static func evaluate(state: CampaignState, condition: Variant) -> Result:
	var result: Result = Result.new()
	var errors: PackedStringArray = validate(condition)
	if not errors.is_empty():
		result.ok = false
		result.error = errors[0]
		return result
	result.value = _eval(state, condition)
	return result


## Convenience for game code: a malformed condition is reported and counts as false.
static func is_true(state: CampaignState, condition: Variant) -> bool:
	var result: Result = evaluate(state, condition)
	if not result.ok:
		push_error("[conditions] " + result.error)
	return result.value


## Structural check without a state (ContentDB uses it at load time).
## Returns every problem found, each prefixed with its path, e.g. "all[1].not: ...".
static func validate(condition: Variant, path: String = "") -> PackedStringArray:
	var errors: PackedStringArray = []
	var here: String = path if path != "" else "condition"
	match typeof(condition):
		TYPE_BOOL:
			pass
		TYPE_ARRAY:
			var items: Array = condition
			for i: int in items.size():
				errors.append_array(validate(items[i], "%s[%d]" % [path, i]))
		TYPE_DICTIONARY:
			errors.append_array(_validate_dict(condition, path, here))
		TYPE_NIL:
			errors.append("%s: condition is empty (null)" % here)
		_:
			errors.append("%s: a condition must be true/false, a list or an object" % here)
	return errors


static func _validate_dict(c: Dictionary, path: String, here: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	for combinator: String in ["all", "any", "not"]:
		if c.has(combinator):
			if c.size() != 1:
				errors.append("%s: '%s' must be the only field in its object" % [here, combinator])
				return errors
			var inner_path: String = combinator if path == "" else "%s.%s" % [path, combinator]
			if combinator == "not":
				return validate(c["not"], inner_path)
			if typeof(c[combinator]) != TYPE_ARRAY:
				errors.append("%s: '%s' needs a list" % [here, combinator])
				return errors
			var items: Array = c[combinator]
			for i: int in items.size():
				errors.append_array(validate(items[i], "%s[%d]" % [inner_path, i]))
			return errors
	if not c.has("if"):
		errors.append("%s: missing 'if' (or all / any / not)" % here)
		return errors
	var kind: String = str(c["if"])
	if not LEAVES.has(kind):
		errors.append("%s: unknown test '%s'" % [here, kind])
		return errors
	var problem: String = _check_leaf(kind, c)
	if problem != "":
		errors.append("%s: %s: %s" % [here, kind, problem])
	return errors


static func _check_leaf(kind: String, c: Dictionary) -> String:
	var spec: Dictionary = LEAVES[kind]
	var known: PackedStringArray = ["if"]
	for raw_field: String in spec:
		var optional: bool = raw_field.ends_with("?")
		var field: String = raw_field.trim_suffix("?")
		known.append(field)
		if not c.has(field):
			if optional:
				continue
			return "missing field '%s'" % field
		var problem: String = _check_value(str(spec[raw_field]), field, c[field])
		if problem != "":
			return problem
	for field: Variant in c:
		if not str(field) in known:
			return "unknown field '%s'" % str(field)
	if kind == "flag" and c.has("cmp") != c.has("value"):
		return "'cmp' and 'value' go together"
	return ""


static func _check_value(expected: String, field: String, value: Variant) -> String:
	match expected:
		"any":
			return ""
		"string":
			if typeof(value) != TYPE_STRING or str(value) == "":
				return "field '%s' must be a non-empty text" % field
		"int":
			if typeof(value) != TYPE_INT:
				return "field '%s' must be a whole number" % field
		"cmp":
			if typeof(value) != TYPE_STRING or not str(value) in COMPARATORS:
				return "field '%s' must be one of %s" % [field, ", ".join(COMPARATORS)]
		"relation":
			if typeof(value) != TYPE_STRING or not str(value) in CampaignState.RELATIONS:
				return "unknown relation '%s'" % str(value)
		"meter":
			if typeof(value) != TYPE_STRING or not CampaignState.METERS.has(str(value)):
				return "unknown meter '%s'" % str(value)
		"account":
			if typeof(value) != TYPE_STRING or not str(value) in CampaignState.ACCOUNTS:
				return "unknown account '%s'" % str(value)
		"stock_location":
			if typeof(value) != TYPE_STRING or not (str(value) in CampaignState.STOCK_LOCATIONS or str(value) == STOCK_TOTAL):
				return "unknown stock location '%s'" % str(value)
		"date":
			if typeof(value) != TYPE_STRING or not _is_date(value):
				return "field '%s' must be a date like 1982-03-15" % field
		"time":
			if typeof(value) != TYPE_STRING or _parse_time(value) < 0:
				return "field '%s' must be a time like 07:30" % field
		"phases":
			for name: String in _names(value):
				if not name in CampaignState.PHASES:
					return "unknown phase '%s'" % name
			if _names(value).is_empty():
				return "field '%s' must be a phase or a list of phases" % field
		"names":
			if _names(value).is_empty():
				return "field '%s' must be a text or a list of texts" % field
	return ""


# ---------------------------------------------------------------- evaluation (input already valid)

static func _eval(s: CampaignState, c: Variant) -> bool:
	if typeof(c) == TYPE_BOOL:
		return c
	if typeof(c) == TYPE_ARRAY:
		return _eval_all(s, c)
	var d: Dictionary = c
	if d.has("all"):
		return _eval_all(s, d["all"])
	if d.has("any"):
		for item: Variant in d["any"]:
			if _eval(s, item):
				return true
		return false
	if d.has("not"):
		return not _eval(s, d["not"])
	return _eval_leaf(s, d)


static func _eval_all(s: CampaignState, items: Array) -> bool:
	for item: Variant in items:
		if not _eval(s, item):
			return false
	return true


static func _eval_leaf(s: CampaignState, c: Dictionary) -> bool:
	match str(c["if"]):
		"flag":
			if not c.has("cmp"):
				return _truthy(s.flags.get(c["key"], null))
			if not s.flags.has(c["key"]):
				return c["cmp"] == "!="
			return compare(s.flags[c["key"]], c["cmp"], c["value"])
		"relation":
			var relations: Dictionary = _character(s, c["character"]).get("relations", {})
			return compare(int(relations.get(c["dimension"], 0)), c["cmp"], c["value"])
		"money":
			return compare(int(s.money.get(c["account"], 0)), c["cmp"], c["value"])
		"meter":
			return compare(int(s.meters.get(c["meter"], 0)), c["cmp"], c["value"])
		"stock":
			var count: int = 0
			if c["location"] == STOCK_TOTAL:
				for location: String in CampaignState.STOCK_LOCATIONS:
					count += s.stock_count(location, c["item"])
			else:
				count = s.stock_count(c["location"], c["item"])
			return compare(count, c["cmp"], c["value"])
		"day":
			return compare(s.day, c["cmp"], c["value"])
		"date":
			# ISO dates (YYYY-MM-DD) sort correctly as text.
			return _compare_ordered(s.calendar_date.casecmp_to(str(c["value"])), c["cmp"])
		"time":
			return compare(s.minute_of_day, c["cmp"], _parse_time(c["value"]))
		"phase":
			return s.phase in _names(c["is"])
		"status":
			return str(_character(s, c["character"]).get("status", DEFAULT_STATUS)) in _names(c["is"])
		"memory":
			for memory: Variant in _character(s, c["character"]).get("memories", []):
				if typeof(memory) == TYPE_DICTIONARY and str((memory as Dictionary).get("id", "")) == c["id"]:
					return true
			return false
		"decision":
			for entry: Dictionary in s.decision_log:
				if str(entry.get("id", "")) == c["id"]:
					return true
			return false
	return false


## Numbers compare by value (int and float mix freely); other types only
## support == and != and must be the same type. Ordering on non-numbers is false.
static func compare(actual: Variant, cmp: String, expected: Variant) -> bool:
	var numeric: bool = _is_number(actual) and _is_number(expected)
	if numeric:
		var a: float = float(actual)
		var b: float = float(expected)
		return _compare_ordered(-1 if a < b else (1 if a > b else 0), cmp)
	var same: bool = typeof(actual) == typeof(expected) and actual == expected
	match cmp:
		"==":
			return same
		"!=":
			return not same
	return false


static func _compare_ordered(order: int, cmp: String) -> bool:
	match cmp:
		"==":
			return order == 0
		"!=":
			return order != 0
		"<":
			return order < 0
		"<=":
			return order <= 0
		">":
			return order > 0
		">=":
			return order >= 0
	return false


# ---------------------------------------------------------------- helpers

## Reads a character without creating it: unknown characters are neutral.
static func _character(s: CampaignState, character_id: String) -> Dictionary:
	return s.characters.get(character_id, {})


static func _truthy(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			return value != ""
		TYPE_ARRAY, TYPE_DICTIONARY:
			return not value.is_empty()
	return true


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _names(value: Variant) -> PackedStringArray:
	var out: PackedStringArray = []
	if typeof(value) == TYPE_STRING and value != "":
		out.append(value)
	elif typeof(value) == TYPE_ARRAY:
		for item: Variant in value:
			if typeof(item) != TYPE_STRING or item == "":
				return PackedStringArray()
			out.append(item)
	return out


static func _is_date(value: String) -> bool:
	var re: RegEx = RegEx.create_from_string("^\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\\d|3[01])$")
	return re.search(value) != null


## "07:30" -> 450; -1 when malformed.
static func _parse_time(value: String) -> int:
	var re: RegEx = RegEx.create_from_string("^([01]\\d|2[0-3]):([0-5]\\d)$")
	var m: RegExMatch = re.search(value)
	if m == null:
		return -1
	return int(m.get_string(1)) * 60 + int(m.get_string(2))
