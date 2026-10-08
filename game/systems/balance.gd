class_name Balance
extends RefCounted
## Every tunable number of the demo economy and risk model, read from
## content/balance/balance.json (record type "balance"). Money in grosze,
## dollars in cents, chances in per-mille or percent as the key says.
## The tools/simulate.gd report shows what these numbers do to a month.

const RECORD_ID: String = "bal_default"

## Required keys and their kinds. "int" = whole number, "items" = {item_id: int},
## "routine" = [{"item", "per_day"}], "weekdays" = [0..6].
const ECONOMY_KEYS: Dictionary = {
	"till_float": "int",
	"commission_pct": "int",
	"household_cost_per_day": "int",
	"usd_rate": "int",
	"payday_weekday": "int",
	"work_weekdays": "weekdays",
	"demand_jitter_pct": "int",
	"saturday_demand_pct": "int",
	"routine": "routine",
	"daily_delivery": "items",
	"weekly_delivery": "items",
	"weekly_delivery_weekday": "int",
	"shortage_max_pct": "int",
	"under_counter_item": "string",
	"under_counter_premium_pct": "int",
	"under_counter_demand": "int",
}
const RISK_KEYS: Dictionary = {
	"inspection_base_permille": "int",
	"inspection_per_point_permille": "int",
	"inspection_max_permille": "int",
	"daily_decay": "int",
	"coupon_tolerance": "int",
	"coupon_detect_base_pct": "int",
	"coupon_detect_per_10": "int",
	"strike_min_coupons": "int",
	"settlement_suspicion_per_10": "int",
	"fine_per_coupon": "int",
	"fine_suspicion": "int",
	"clean_relief": "int",
	"strikes_to_lose_license": "int",
	"under_counter_suspicion_per_10": "int",
	"manko_suspicion": "int",
	"usd_buy_suspicion": "int",
	"hidden_find_pct": "int",
	"hidden_found_suspicion": "int",
	"family_shortfall_penalty": "int",
}

var economy: Dictionary = {}
var risk: Dictionary = {}


static func from_record(record: Dictionary) -> Balance:
	var b: Balance = Balance.new()
	b.economy = record.get("economy", {})
	b.risk = record.get("risk", {})
	return b


func e(key: String) -> int:
	return int(economy[key])


func r(key: String) -> int:
	return int(risk[key])


static func validate(record: Dictionary, path: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	errors.append_array(_check_section(record.get("economy"), ECONOMY_KEYS, path + ".economy"))
	errors.append_array(_check_section(record.get("risk"), RISK_KEYS, path + ".risk"))
	return errors


static func _check_section(section: Variant, keys: Dictionary, path: String) -> PackedStringArray:
	var errors: PackedStringArray = []
	if typeof(section) != TYPE_DICTIONARY:
		errors.append("%s: must be an object" % path)
		return errors
	var d: Dictionary = section
	for key: String in keys:
		if not d.has(key):
			errors.append("%s: missing '%s'" % [path, key])
			continue
		var value: Variant = d[key]
		var ok: bool = true
		match str(keys[key]):
			"int":
				ok = typeof(value) == TYPE_INT
			"string":
				ok = typeof(value) == TYPE_STRING and value != ""
			"items":
				ok = typeof(value) == TYPE_DICTIONARY
				if ok:
					for item: Variant in value:
						ok = ok and typeof((value as Dictionary)[item]) == TYPE_INT and int((value as Dictionary)[item]) >= 0
			"weekdays":
				ok = typeof(value) == TYPE_ARRAY
				if ok:
					for w: Variant in value:
						ok = ok and typeof(w) == TYPE_INT and int(w) >= 0 and int(w) <= 6
			"routine":
				ok = typeof(value) == TYPE_ARRAY
				if ok:
					for entry: Variant in value:
						ok = ok and typeof(entry) == TYPE_DICTIONARY and typeof((entry as Dictionary).get("item")) == TYPE_STRING \
								and typeof((entry as Dictionary).get("per_day")) == TYPE_INT
		if not ok:
			errors.append("%s.%s: must be %s" % [path, key, keys[key]])
	for key: Variant in d:
		if not keys.has(str(key)):
			errors.append("%s: unknown key '%s'" % [path, str(key)])
	return errors
