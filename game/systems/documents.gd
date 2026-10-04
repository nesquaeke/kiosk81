class_name DocumentRules
extends RefCounted
## Documents customers hand over (roadmap 2.5, prototype version).
## Only the ration card exists yet. It is a simplified, invented card for the
## prototype: its look and rules are NOT a claim about the real 1982 cards.
## Rules of the day (shown on the decree note):
##   1. the card is for the current month   2. it carries the office stamp
##   3. it still has a coupon left           4. a name is written on it

const KINDS: Dictionary = {
	"ration_card": {"holder": "string", "month": "month", "stamped": "bool", "coupons_left": "int>=0", "category": "string"},
}
## Problem codes, in the order a careful vendor would notice them. UI text: ui.doc.problem.<code>
const PROBLEMS: PackedStringArray = ["no_name", "wrong_month", "no_stamp", "no_coupons"]


## What is wrong with this document today ([] = valid).
static func problems(doc: Dictionary, state: CampaignState) -> PackedStringArray:
	var out: PackedStringArray = []
	match str(doc.get("kind", "")):
		"ration_card":
			if str(doc.get("holder", "")).strip_edges() == "":
				out.append("no_name")
			if str(doc.get("month", "")) != state.calendar_date.substr(0, 7):
				out.append("wrong_month")
			if doc.get("stamped", false) != true:
				out.append("no_stamp")
			if int(doc.get("coupons_left", 0)) <= 0:
				out.append("no_coupons")
		_:
			out.append("unknown_kind")
	return out


## Effects that tell the dialogue about the document on the tray.
## Dialogue conditions read the flags doc_present, doc_ok and doc_problem.
static func present_effects(doc: Dictionary, state: CampaignState) -> Array[Dictionary]:
	var found: PackedStringArray = problems(doc, state)
	return [
		{"op": "flag_set", "key": "doc_present", "value": true},
		{"op": "flag_set", "key": "doc_ok", "value": found.is_empty()},
		{"op": "flag_set", "key": "doc_problem", "value": found[0] if not found.is_empty() else ""},
	]


static func clear_effects() -> Array[Dictionary]:
	return [
		{"op": "flag_set", "key": "doc_present", "value": false},
		{"op": "flag_set", "key": "doc_ok", "value": false},
		{"op": "flag_set", "key": "doc_problem", "value": ""},
	]


## Content check for a document written into a scenario.
static func validate(doc: Variant, path: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(doc) != TYPE_DICTIONARY:
		errors.append("%s: a document must be an object" % path)
		return errors
	var d: Dictionary = doc
	var kind: String = str(d.get("kind", ""))
	if not KINDS.has(kind):
		errors.append("%s.kind: unknown document kind '%s'" % [path, kind])
		return errors
	var spec: Dictionary = KINDS[kind]
	for field: String in spec:
		if not d.has(field):
			errors.append("%s: missing field '%s'" % [path, field])
			continue
		var value: Variant = d[field]
		match str(spec[field]):
			"string":
				if typeof(value) != TYPE_STRING:
					errors.append("%s.%s: must be a text (may be empty)" % [path, field])
			"bool":
				if typeof(value) != TYPE_BOOL:
					errors.append("%s.%s: must be true or false" % [path, field])
			"int>=0":
				if typeof(value) != TYPE_INT or int(value) < 0:
					errors.append("%s.%s: must be a whole number, 0 or more" % [path, field])
			"month":
				if typeof(value) != TYPE_STRING or RegEx.create_from_string("^\\d{4}-(0[1-9]|1[0-2])$").search(value) == null:
					errors.append("%s.%s: must be a month like 1982-02" % [path, field])
	for field: Variant in d:
		if field != "kind" and not spec.has(field):
			errors.append("%s: unknown field '%s'" % [path, str(field)])
	return errors
