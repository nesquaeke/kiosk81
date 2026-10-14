class_name ContentSchema
extends RefCounted
## Record types for content files (roadmap 1.8) and their field rules.
## A content file is JSON: {"type": "<record type>", "records": [ {...}, ... ]}.
## Field kinds:
##   id            the record id; must start with the type's prefix, a-z 0-9 _
##   text          non-empty player-facing text (English source; translated by key)
##   string        non-empty text that players never see
##   int / int>=0  whole number
##   bool
##   enum:a,b,c    one of the listed words
##   ref:<type>    id of another record of that type
##   condition     condition language (docs/CONDITION_LANGUAGE.md)
##   effects       effect list (same document)
##   speakers      list of speakers: character ids or roles (player, customer, narrator)
##   nodes         dialogue nodes (docs/adr/ADR-001-dialogue-format.md)
##   state         a scenario's opening state (fields of CampaignState)
##   visits        a scenario's customer visits (see _check_visits)
## A trailing "?" marks an optional field.

const ID_PATTERN: String = "^[a-z][a-z0-9_]*$"
const SPEAKER_ROLES: PackedStringArray = ["player", "customer", "narrator"]

const TYPES: Dictionary = {
	"ration_case": {
		"prefix": "rc_",
		"fields": {"id": "id", "customer": "text", "line": "text", "request": "dict", "card": "dict"},
	},
	"item": {
		"prefix": "itm_",
		"fields": {
			"id": "id",
			"name": "text",
			"category": "enum:newspaper,periodical,tobacco,matches,household,food,underground,other",
			"price": "int>=0",
			"legal": "bool",
			"rationed": "bool?",
			"notes": "string?",
		},
	},
	"character": {
		"prefix": "chr_",
		"fields": {
			"id": "id",
			"name": "text",
			"role": "string",
			"notes": "string?",
		},
	},
	"scenario": {
		"prefix": "scn_",
		"fields": {
			"id": "id",
			"name": "text",
			"start": "state",
			"visits": "visits",
			"notes": "string?",
		},
	},
	"balance": {
		"prefix": "bal_",
		"fields": {
			"id": "id",
			"economy": "dict",
			"risk": "dict",
			"notes": "string?",
		},
	},
	"dialogue": {
		"prefix": "dlg_",
		"fields": {
			"id": "id",
			"speakers": "speakers",
			"start": "string",
			"nodes": "nodes",
			"if": "condition?",
			"notes": "string?",
		},
	},
}

const NODE_FIELDS: PackedStringArray = ["lines", "effects", "choices", "goto", "end"]
const LINE_FIELDS: PackedStringArray = ["speaker", "text", "if"]
const CHOICE_FIELDS: PackedStringArray = ["text", "if", "effects", "goto", "end"]
const VISIT_FIELDS: PackedStringArray = ["customer", "dialogue", "look", "document", "arrive_minutes", "if"]
const LOOK_FIELDS: PackedStringArray = ["coat", "height_cm", "hat"]
const STATE_FIELDS: PackedStringArray = ["day", "phase", "minute_of_day", "calendar_date", "rng_seed", "money", "stock", "register", "characters", "flags", "decision_log"]


## Checks one record. `refs` collects [kind, id, path] for the second pass.
static func check_record(type_name: String, record: Variant, path: String, refs: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(record) != TYPE_DICTIONARY:
		errors.append("%s: a record must be an object" % path)
		return errors
	var spec: Dictionary = TYPES[type_name]
	var fields: Dictionary = spec["fields"]
	var rec: Dictionary = record
	for raw: String in fields:
		var optional: bool = raw.ends_with("?") or str(fields[raw]).ends_with("?")
		var field: String = raw.trim_suffix("?")
		var kind: String = str(fields[raw]).trim_suffix("?")
		if not rec.has(field):
			if not optional:
				errors.append("%s: missing field '%s'" % [path, field])
			continue
		errors.append_array(_check_field(kind, rec[field], "%s.%s" % [path, field], spec, rec, refs))
	for field: Variant in rec:
		if not fields.has(str(field)) and not fields.has(str(field) + "?"):
			errors.append("%s: unknown field '%s'" % [path, str(field)])
	if type_name == "balance":
		errors.append_array(Balance.validate(rec, path))
	return errors


static func _check_field(kind: String, value: Variant, path: String, spec: Dictionary, rec: Dictionary, refs: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	if kind.begins_with("enum:"):
		var options: PackedStringArray = kind.trim_prefix("enum:").split(",")
		if typeof(value) != TYPE_STRING or not value in options:
			errors.append("%s: must be one of %s" % [path, ", ".join(options)])
		return errors
	if kind.begins_with("ref:"):
		if typeof(value) != TYPE_STRING or value == "":
			errors.append("%s: must be an id" % path)
		else:
			refs.append([kind.trim_prefix("ref:"), value, path])
		return errors
	match kind:
		"id":
			if typeof(value) != TYPE_STRING or RegEx.create_from_string(ID_PATTERN).search(value) == null:
				errors.append("%s: id must use a-z, 0-9 and _" % path)
			elif not str(value).begins_with(str(spec["prefix"])):
				errors.append("%s: id must start with '%s'" % [path, spec["prefix"]])
		"text", "string":
			if typeof(value) != TYPE_STRING or str(value).strip_edges() == "":
				errors.append("%s: must be a non-empty text" % path)
		"int":
			if typeof(value) != TYPE_INT:
				errors.append("%s: must be a whole number" % path)
		"int>=0":
			if typeof(value) != TYPE_INT or int(value) < 0:
				errors.append("%s: must be a whole number, 0 or more" % path)
		"bool":
			if typeof(value) != TYPE_BOOL:
				errors.append("%s: must be true or false" % path)
		"condition":
			errors.append_array(Conditions.validate(value, path))
		"effects":
			errors.append_array(EffectPipeline.validate_effects(value, path))
		"speakers":
			errors.append_array(_check_speakers(value, path, refs))
		"nodes":
			errors.append_array(_check_nodes(value, path, rec, refs))
		"dict":
			if typeof(value) != TYPE_DICTIONARY:
				errors.append("%s: must be an object" % path)
		"state":
			errors.append_array(_check_state(value, path))
		"visits":
			errors.append_array(_check_visits(value, path, refs))
		_:
			errors.append("%s: schema error, unknown kind '%s'" % [path, kind])
	return errors


static func _check_speakers(value: Variant, path: String, refs: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(value) != TYPE_ARRAY or (value as Array).is_empty():
		errors.append("%s: must be a non-empty list" % path)
		return errors
	var list: Array = value
	for i: int in list.size():
		var speaker: Variant = list[i]
		if typeof(speaker) != TYPE_STRING:
			errors.append("%s[%d]: must be a text" % [path, i])
		elif str(speaker).begins_with("chr_"):
			refs.append(["character", speaker, "%s[%d]" % [path, i]])
		elif not speaker in SPEAKER_ROLES:
			errors.append("%s[%d]: '%s' is neither a character id nor one of %s" % [path, i, speaker, ", ".join(SPEAKER_ROLES)])
	return errors


## Dialogue graph: every goto points to an existing node, every node can end or move on.
static func _check_nodes(value: Variant, path: String, rec: Dictionary, _refs: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(value) != TYPE_DICTIONARY or (value as Dictionary).is_empty():
		errors.append("%s: must be an object of nodes" % path)
		return errors
	var nodes: Dictionary = value
	var speakers: Array = rec.get("speakers", []) if typeof(rec.get("speakers")) == TYPE_ARRAY else []
	if typeof(rec.get("start")) == TYPE_STRING and not nodes.has(rec["start"]):
		errors.append("%s: start node '%s' does not exist" % [path, rec["start"]])
	for node_id: Variant in nodes:
		var here: String = "%s.%s" % [path, str(node_id)]
		if typeof(nodes[node_id]) != TYPE_DICTIONARY:
			errors.append("%s: a node must be an object" % here)
			continue
		var node: Dictionary = nodes[node_id]
		errors.append_array(_unknown_fields(node, NODE_FIELDS, here))
		var lines: Variant = node.get("lines", [])
		if typeof(lines) != TYPE_ARRAY:
			errors.append("%s.lines: must be a list" % here)
		else:
			for i: int in (lines as Array).size():
				errors.append_array(_check_line(lines[i], "%s.lines[%d]" % [here, i], speakers))
		if node.has("effects"):
			errors.append_array(EffectPipeline.validate_effects(node["effects"], here + ".effects"))
		var exits: int = 0
		if node.has("goto"):
			exits += 1
			errors.append_array(_check_goto(node["goto"], nodes, here + ".goto"))
		if node.get("end", false) == true:
			exits += 1
		if node.has("choices"):
			exits += 1
			var choices: Variant = node["choices"]
			if typeof(choices) != TYPE_ARRAY or (choices as Array).is_empty():
				errors.append("%s.choices: must be a non-empty list" % here)
			else:
				for i: int in (choices as Array).size():
					errors.append_array(_check_choice(choices[i], "%s.choices[%d]" % [here, i], nodes))
		if exits != 1:
			errors.append("%s: needs exactly one of 'choices', 'goto' or 'end': true" % here)
	return errors


static func _check_line(line: Variant, path: String, speakers: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(line) != TYPE_DICTIONARY:
		errors.append("%s: a line must be an object" % path)
		return errors
	var d: Dictionary = line
	errors.append_array(_unknown_fields(d, LINE_FIELDS, path))
	if typeof(d.get("speaker")) != TYPE_STRING or not d["speaker"] in speakers:
		errors.append("%s.speaker: must be one of the dialogue's speakers" % path)
	if typeof(d.get("text")) != TYPE_STRING or str(d["text"]).strip_edges() == "":
		errors.append("%s.text: must be a non-empty text" % path)
	if d.has("if"):
		errors.append_array(Conditions.validate(d["if"], path + ".if"))
	return errors


static func _check_choice(choice: Variant, path: String, nodes: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(choice) != TYPE_DICTIONARY:
		errors.append("%s: a choice must be an object" % path)
		return errors
	var d: Dictionary = choice
	errors.append_array(_unknown_fields(d, CHOICE_FIELDS, path))
	if typeof(d.get("text")) != TYPE_STRING or str(d["text"]).strip_edges() == "":
		errors.append("%s.text: must be a non-empty text" % path)
	if d.has("if"):
		errors.append_array(Conditions.validate(d["if"], path + ".if"))
	if d.has("effects"):
		errors.append_array(EffectPipeline.validate_effects(d["effects"], path + ".effects"))
	var has_goto: bool = d.has("goto")
	var ends: bool = d.get("end", false) == true
	if has_goto == ends:
		errors.append("%s: needs exactly one of 'goto' or 'end': true" % path)
	elif has_goto:
		errors.append_array(_check_goto(d["goto"], nodes, path + ".goto"))
	return errors


static func _check_goto(target: Variant, nodes: Dictionary, path: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(target) != TYPE_STRING or not nodes.has(target):
		errors.append("%s: node '%s' does not exist" % [path, str(target)])
	return errors


static func _unknown_fields(d: Dictionary, allowed: PackedStringArray, path: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	for field: Variant in d:
		if not str(field) in allowed:
			errors.append("%s: unknown field '%s'" % [path, str(field)])
	return errors


## A scenario's opening state: known CampaignState fields only, and the
## invariants must hold (no negative money or stock, a real phase ...).
static func _check_state(value: Variant, path: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("%s: must be an object" % path)
		return errors
	var d: Dictionary = value
	errors.append_array(_unknown_fields(d, STATE_FIELDS, path))
	if d.has("calendar_date") and (typeof(d["calendar_date"]) != TYPE_STRING or not Conditions._is_date(d["calendar_date"])):
		errors.append("%s.calendar_date: must be a date like 1982-02-15" % path)
	var broken: String = EffectPipeline.check_invariants(CampaignState.from_dict(d))
	if broken != "":
		errors.append("%s: %s" % [path, broken])
	return errors


static func _check_visits(value: Variant, path: String, refs: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(value) != TYPE_ARRAY or (value as Array).is_empty():
		errors.append("%s: must be a non-empty list" % path)
		return errors
	var list: Array = value
	for i: int in list.size():
		var here: String = "%s[%d]" % [path, i]
		if typeof(list[i]) != TYPE_DICTIONARY:
			errors.append("%s: a visit must be an object" % here)
			continue
		var v: Dictionary = list[i]
		errors.append_array(_unknown_fields(v, VISIT_FIELDS, here))
		if typeof(v.get("customer")) != TYPE_STRING or str(v["customer"]).strip_edges() == "":
			errors.append("%s.customer: must be a non-empty text" % here)
		if typeof(v.get("dialogue")) != TYPE_STRING:
			errors.append("%s.dialogue: must be a dialogue id" % here)
		else:
			refs.append(["dialogue", v["dialogue"], here + ".dialogue"])
		if v.has("arrive_minutes") and (typeof(v["arrive_minutes"]) != TYPE_INT or int(v["arrive_minutes"]) <= 0):
			errors.append("%s.arrive_minutes: must be a whole number above 0" % here)
		if v.has("if"):
			errors.append_array(Conditions.validate(v["if"], here + ".if"))
		if v.has("document"):
			errors.append_array(DocumentRules.validate(v["document"], here + ".document"))
		if v.has("look"):
			if typeof(v["look"]) != TYPE_DICTIONARY:
				errors.append("%s.look: must be an object" % here)
			else:
				var look: Dictionary = v["look"]
				errors.append_array(_unknown_fields(look, LOOK_FIELDS, here + ".look"))
				if look.has("coat") and (typeof(look["coat"]) != TYPE_STRING or not Color.html_is_valid(look["coat"])):
					errors.append("%s.look.coat: must be a colour like #2f2c39" % here)
				if look.has("height_cm") and (typeof(look["height_cm"]) != TYPE_INT or int(look["height_cm"]) < 140 or int(look["height_cm"]) > 205):
					errors.append("%s.look.height_cm: must be 140-205" % here)
				if look.has("hat") and typeof(look["hat"]) != TYPE_BOOL:
					errors.append("%s.look.hat: must be true or false" % here)
	return errors
