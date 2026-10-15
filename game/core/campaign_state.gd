class_name CampaignState
extends RefCounted
## The whole campaign in one object: the single source of truth.
## Holds plain data only (int, String, Array, Dictionary) so it can be
## copied, compared and saved as JSON. Money is stored in grosze
## (1 zloty = 100 grosze) to avoid rounding errors; dollars in cents.

const SCHEMA_VERSION: int = 1
## till: the kiosk's cash (goes to Ruch every evening) · commission: earned, paid on
## Saturday · pocket: off-the-book cash · household: the family budget · usd: dollar
## stash in CENTS (demo plan: money flow).
const ACCOUNTS: PackedStringArray = ["till", "commission", "pocket", "household", "usd"]
const STOCK_LOCATIONS: PackedStringArray = ["shelf", "backroom", "hidden", "hand", "counter"]
const PHASES: PackedStringArray = ["morning", "shift", "closing", "evening", "night"]
const RELATIONS: PackedStringArray = ["trust", "suspicion", "debt", "leverage", "affinity"]
const DAY_START_MINUTE: int = 450  # 07:30
## Meter -> [min, max, start]. Demo plan, "Taraflar ve aile" and "Risk".
const METERS: Dictionary = {
	"suspicion": [0, 100, 5],      # how closely the state watches Tadeusz (S)
	"solidarity": [0, 100, 10],    # trust of the Solidarity network (D)
	"cooperation": [0, 100, 0],    # cooperation with the state (K)
	"family": [0, 100, 60],        # family bond (A)
	"belief": [-100, 100, -10],    # -100 opposition ... +100 convinced socialist
	"marek_lean": [-100, 100, 20], # -100 state ... +100 Solidarity; +20 is Marek's own view
	"halina": [0, 100, 60],        # Halina's wellbeing in internment (H)
}

var day: int = 1
var phase: String = "morning"
var minute_of_day: int = DAY_START_MINUTE
var calendar_date: String = "1981-12-13"
var rng_seed: int = 0
## Account name -> amount in grosze.
var money: Dictionary[String, int] = {"till": 0, "commission": 0, "pocket": 0, "household": 0, "usd": 0}
## Meter -> value, always inside its METERS range.
var meters: Dictionary[String, int] = CampaignState.default_meters()
## Location -> {item_id: count}.
var stock: Dictionary[String, Dictionary] = {"shelf": {}, "backroom": {}, "hidden": {}, "hand": {}, "counter": {}}
## Entries written in the kiosk register book.
var register: Array[Dictionary] = []
## Character id -> {"status", "relations", "memories"}.
var characters: Dictionary[String, Dictionary] = {}
## Free-form story flags.
var flags: Dictionary[String, Variant] = {}
## Append-only record of important player decisions.
var decision_log: Array[Dictionary] = []


func stock_count(location: String, item_id: String) -> int:
	var items: Dictionary = stock.get(location, {})
	return int(items.get(item_id, 0))


static func default_meters() -> Dictionary[String, int]:
	var out: Dictionary[String, int] = {}
	for meter: String in METERS:
		out[meter] = int((METERS[meter] as Array)[2])
	return out


## Returns the character entry, creating a neutral one if needed.
func ensure_character(character_id: String) -> Dictionary:
	if not characters.has(character_id):
		var relations: Dictionary = {}
		for dimension: String in RELATIONS:
			relations[dimension] = 0
		characters[character_id] = {"status": "active", "relations": relations, "memories": []}
	return characters[character_id]


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"day": day,
		"phase": phase,
		"minute_of_day": minute_of_day,
		"calendar_date": calendar_date,
		"rng_seed": rng_seed,
		"money": money.duplicate(true),
		"stock": stock.duplicate(true),
		"register": register.duplicate(true),
		"meters": meters.duplicate(true),
		"characters": characters.duplicate(true),
		"flags": flags.duplicate(true),
		"decision_log": decision_log.duplicate(true),
	}


## Builds a state from a dictionary (for example parsed JSON). Missing
## fields keep their defaults; whole-number floats from JSON become ints.
static func from_dict(source: Dictionary) -> CampaignState:
	var data: Dictionary = normalize_numbers(source)
	var s: CampaignState = CampaignState.new()
	s.day = int(data.get("day", s.day))
	s.phase = str(data.get("phase", s.phase))
	s.minute_of_day = int(data.get("minute_of_day", s.minute_of_day))
	s.calendar_date = str(data.get("calendar_date", s.calendar_date))
	s.rng_seed = int(data.get("rng_seed", s.rng_seed))
	var money_in: Dictionary = data.get("money", {})
	for account: String in money_in:
		s.money[account] = int(money_in[account])
	var meters_in: Dictionary = data.get("meters", {})
	for meter: String in meters_in:
		s.meters[meter] = int(meters_in[meter])
	var stock_in: Dictionary = data.get("stock", {})
	for location: String in stock_in:
		s.stock[location] = (stock_in[location] as Dictionary).duplicate(true)
	var register_in: Array = data.get("register", [])
	s.register.assign(register_in.duplicate(true))
	var characters_in: Dictionary = data.get("characters", {})
	for character_id: String in characters_in:
		s.characters[character_id] = (characters_in[character_id] as Dictionary).duplicate(true)
	var flags_in: Dictionary = data.get("flags", {})
	for key: String in flags_in:
		s.flags[key] = flags_in[key]
	var log_in: Array = data.get("decision_log", [])
	s.decision_log.assign(log_in.duplicate(true))
	return s


## Deep copy through the same path the save system uses.
func duplicate_state() -> CampaignState:
	return CampaignState.from_dict(to_dict())


## JSON turns every number into a float; turn whole numbers back into ints.
static func normalize_numbers(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var f: float = value
			if is_finite(f) and f == floorf(f):
				return int(f)
			return f
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			var d: Dictionary = value
			for key: Variant in d:
				out[key] = normalize_numbers(d[key])
			return out
		TYPE_ARRAY:
			var arr: Array = []
			for item: Variant in value:
				arr.append(normalize_numbers(item))
			return arr
		_:
			return value
