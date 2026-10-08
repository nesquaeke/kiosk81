class_name Economy
extends RefCounted
## The kiosk's money skeleton (demo step 1). Pure rules: every function reads
## the state and returns effects (plus a summary); nothing changes until the
## caller applies them through EffectPipeline / Game.apply_effects.
## The model (Demo Yol Haritasi, "Oyunun matematigi"):
##   * Goods belong to Ruch. The till goes to Ruch every evening (a small float stays).
##   * Tadeusz earns a commission on what is WRITTEN IN THE BOOK, paid on Saturday.
##   * Coins kept off the book become "manko" at Saturday's settlement: Ruch takes
##     them back out of the commission. Skimming moves money, it does not make it.
##   * The money that really pays is under the counter: rationed goods sold without
##     a coupon at a premium. Ruch gets its price, the premium goes to the pocket,
##     and every missing coupon waits for an inspector until Saturday, when the
##     week's coupon sheets go to the office (and a big gap raises suspicion).
##   * The family pays its costs every evening from the household budget, then the pocket.

var balance: Balance
var items: Dictionary = {}  # item id -> record


func _init(b: Balance, item_records: Array) -> void:
	balance = b
	for record: Dictionary in item_records:
		items[record["id"]] = record


# ---------------------------------------------------------------- calendar

## 0 = Sunday ... 6 = Saturday.
static func weekday(state: CampaignState) -> int:
	return int(Time.get_datetime_dict_from_datetime_string(state.calendar_date + "T12:00:00", true)["weekday"])


func is_work_day(state: CampaignState) -> bool:
	return weekday(state) in (balance.economy["work_weekdays"] as Array)


func is_payday(state: CampaignState) -> bool:
	return weekday(state) == balance.e("payday_weekday")


func price(item_id: String) -> int:
	return int((items.get(item_id, {}) as Dictionary).get("price", 0))


func is_legal(item_id: String) -> bool:
	return bool((items.get(item_id, {}) as Dictionary).get("legal", true))


# ---------------------------------------------------------------- morning

## Ruch's deliveries into the back room: newspapers every work day, other goods
## once a week. Each delivery may come short by up to shortage_max_pct.
func delivery_effects(state: CampaignState) -> Dictionary:
	var out: Array[Dictionary] = []
	var delivered: Dictionary = {}
	if not is_work_day(state):
		return {"effects": out, "delivered": delivered}
	var lists: Array[Dictionary] = [balance.economy["daily_delivery"]]
	if weekday(state) == balance.e("weekly_delivery_weekday"):
		lists.append(balance.economy["weekly_delivery"])
	for list: Dictionary in lists:
		for item_id: String in list:
			var short_pct: int = Dice.range_int(state, "short_" + item_id, 0, balance.e("shortage_max_pct"))
			var qty: int = int(list[item_id]) * (100 - short_pct) / 100
			if qty > 0:
				out.append({"op": "stock_add", "location": "backroom", "item": item_id, "qty": qty})
				delivered[item_id] = int(delivered.get(item_id, 0)) + qty
	return {"effects": out, "delivered": delivered}


## Marks where today's book starts, so the closing knows today's sales.
func open_day_effects(state: CampaignState) -> Array[Dictionary]:
	return [
		{"op": "flag_set", "key": "day_start_register", "value": state.register.size()},
		{"op": "flag_set", "key": "day_start_till", "value": state.money.get("till", 0)},
	]


# ---------------------------------------------------------------- the shift

## The many ordinary sales the player does not see one by one. Stock comes from
## the back room first, then the shelf. skim_pct of them go into the pocket
## without a line in the book (they come back as manko on Saturday).
func routine_sales(state: CampaignState, skim_pct: int = 0) -> Dictionary:
	var out: Array[Dictionary] = []
	var units: Dictionary = {}
	var revenue: int = 0
	var skimmed: int = 0
	if not is_work_day(state):
		return {"effects": out, "units": units, "revenue": revenue, "skimmed": skimmed}
	var day_pct: int = balance.e("saturday_demand_pct") if weekday(state) == 6 else 100
	var jitter: int = balance.e("demand_jitter_pct")
	for entry: Dictionary in balance.economy["routine"]:
		var item_id: String = entry["item"]
		var swing: int = Dice.range_int(state, "demand_" + item_id, -jitter, jitter)
		var demand: int = int(entry["per_day"]) * day_pct / 100 * (100 + swing) / 100
		var sold: int = mini(demand, state.stock_count("backroom", item_id) + state.stock_count("shelf", item_id))
		if sold <= 0:
			continue
		out.append_array(_take_stock(state, item_id, sold))
		var skim: int = sold * clampi(skim_pct, 0, 100) / 100
		var booked: int = sold - skim
		var p: int = price(item_id)
		if booked > 0:
			out.append({"op": "money_add", "account": "till", "amount": booked * p})
			out.append({"op": "register_append", "entry": {"item": item_id, "qty": booked, "price": p, "routine": true}})
		if skim > 0:
			out.append({"op": "money_add", "account": "pocket", "amount": skim * p})
			out.append({"op": "flag_add", "key": "unregistered_value", "amount": skim * p})
			out.append({"op": "flag_add", "key": "unregistered_sales", "amount": skim})
		units[item_id] = sold
		revenue += sold * p
		skimmed += skim * p
	return {"effects": out, "units": units, "revenue": revenue, "skimmed": skimmed}


## Rationed goods sold without a coupon: Ruch's price into the till and the book,
## the premium into the pocket, one missing coupon per pack.
func under_counter(state: CampaignState, packs: int) -> Dictionary:
	var out: Array[Dictionary] = []
	var item_id: String = balance.economy["under_counter_item"]
	if packs <= 0 or not is_work_day(state):
		return {"effects": out, "sold": 0, "premium": 0}
	var jitter: int = balance.e("demand_jitter_pct")
	var demand: int = balance.e("under_counter_demand") * (100 + Dice.range_int(state, "uc_demand", -jitter, jitter)) / 100
	var sold: int = mini(mini(packs, demand), state.stock_count("backroom", item_id) + state.stock_count("shelf", item_id))
	if sold <= 0:
		return {"effects": out, "sold": 0, "premium": 0}
	var p: int = price(item_id)
	var premium: int = sold * p * balance.e("under_counter_premium_pct") / 100
	out.append_array(_take_stock(state, item_id, sold))
	out.append({"op": "money_add", "account": "till", "amount": sold * p})
	out.append({"op": "register_append", "entry": {"item": item_id, "qty": sold, "price": p, "no_coupon": true}})
	out.append({"op": "money_add", "account": "pocket", "amount": premium})
	out.append({"op": "flag_add", "key": "coupon_shortfall", "amount": sold})
	var suspicion: int = (sold * balance.r("under_counter_suspicion_per_10") + 5) / 10
	if suspicion > 0:
		out.append({"op": "meter_add", "meter": "suspicion", "amount": suspicion})
	return {"effects": out, "sold": sold, "premium": premium}


# ---------------------------------------------------------------- closing

## Unsold newspapers go back to Ruch, the commission on today's book is earned,
## and the till (minus the float) goes to Ruch.
func closing_effects(state: CampaignState) -> Dictionary:
	var out: Array[Dictionary] = []
	var returned: Dictionary = {}
	for item_id: String in balance.economy["daily_delivery"]:
		for location: String in ["shelf", "backroom"]:
			var left: int = state.stock_count(location, item_id)
			if left > 0:
				out.append({"op": "stock_add", "location": location, "item": item_id, "qty": -left})
				returned[item_id] = int(returned.get(item_id, 0)) + left
	var booked: int = int(ShiftPlan.ledger(state)["registered_total"])
	var commission: int = booked * balance.e("commission_pct") / 100
	if commission > 0:
		out.append({"op": "money_add", "account": "commission", "amount": commission})
	var handover: int = int(state.money.get("till", 0)) - balance.e("till_float")
	if handover > 0:
		out.append({"op": "money_add", "account": "till", "amount": -handover})
	return {"effects": out, "returned": returned, "booked": booked, "commission": commission, "handover": maxi(handover, 0)}


## Saturday: Ruch settles the week. Manko (coins kept off the book) comes out
## of the commission first; the rest goes home.
func settlement_effects(state: CampaignState) -> Dictionary:
	var out: Array[Dictionary] = []
	var commission: int = int(state.money.get("commission", 0))
	var manko: int = int(state.flags.get("unregistered_value", 0))
	if commission > 0:
		out.append({"op": "money_add", "account": "commission", "amount": -commission})
	var payout: int = commission - manko
	var unpaid: int = 0
	if payout > 0:
		out.append({"op": "money_add", "account": "household", "amount": payout})
	elif payout < 0:
		var paid: Dictionary = pay(state, -payout)
		out.append_array(paid["effects"])
		unpaid = paid["unpaid"]
	# This week's coupon sheets go to the office: a big gap there raises suspicion.
	var shortfall: int = int(state.flags.get("coupon_shortfall", 0))
	if shortfall > 0:
		out.append({"op": "flag_set", "key": "coupon_shortfall", "value": 0})
		var office: int = shortfall * balance.r("settlement_suspicion_per_10") / 10
		if office > 0:
			out.append({"op": "meter_add", "meter": "suspicion", "amount": office})
	if manko > 0:
		out.append({"op": "flag_set", "key": "unregistered_value", "value": 0})
		out.append({"op": "flag_set", "key": "unregistered_sales", "value": 0})
		out.append({"op": "meter_add", "meter": "suspicion", "amount": balance.r("manko_suspicion")})
	return {"effects": out, "commission": commission, "manko": manko, "payout": maxi(payout, 0), "unpaid": unpaid}


# ---------------------------------------------------------------- evening

## One day of family costs: household budget first, then the pocket.
func household_effects(state: CampaignState) -> Dictionary:
	var cost: int = balance.e("household_cost_per_day")
	var paid: Dictionary = pay(state, cost)
	var out: Array[Dictionary] = paid["effects"]
	if int(paid["unpaid"]) > 0:
		out.append({"op": "flag_add", "key": "household_shortfall", "amount": int(paid["unpaid"])})
		out.append({"op": "meter_add", "meter": "family", "amount": -balance.r("family_shortfall_penalty")})
	return {"effects": out, "cost": cost, "unpaid": paid["unpaid"]}


## Pocket money changed into dollars on the black market (whole dollars only).
func buy_dollars(state: CampaignState, budget: int) -> Dictionary:
	var out: Array[Dictionary] = []
	var rate: int = balance.e("usd_rate")
	var dollars: int = mini(budget, int(state.money.get("pocket", 0))) / rate
	if dollars <= 0:
		return {"effects": out, "dollars": 0, "cost": 0}
	out.append({"op": "money_add", "account": "pocket", "amount": -dollars * rate})
	out.append({"op": "money_add", "account": "usd", "amount": dollars * 100})
	out.append({"op": "meter_add", "meter": "suspicion", "amount": balance.r("usd_buy_suspicion")})
	return {"effects": out, "dollars": dollars, "cost": dollars * rate}


# ---------------------------------------------------------------- helpers

## Pays an amount from the household budget, then the pocket. What cannot be
## paid is returned as "unpaid" (the caller decides: debt, hunger, a story beat).
func pay(state: CampaignState, amount: int) -> Dictionary:
	var out: Array[Dictionary] = []
	var left: int = amount
	for account: String in ["household", "pocket"]:
		var take: int = mini(left, int(state.money.get(account, 0)))
		if take > 0:
			out.append({"op": "money_add", "account": account, "amount": -take})
			left -= take
	return {"effects": out, "unpaid": left}


## Everything the family owns, in grosze (dollars at today's black-market rate).
func wealth(state: CampaignState) -> int:
	return int(state.money.get("household", 0)) + int(state.money.get("pocket", 0)) \
			+ int(state.money.get("commission", 0)) - int(state.flags.get("unregistered_value", 0)) \
			+ int(state.money.get("usd", 0)) * balance.e("usd_rate") / 100 - int(state.flags.get("debt", 0))


func _take_stock(state: CampaignState, item_id: String, qty: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var from_back: int = mini(qty, state.stock_count("backroom", item_id))
	if from_back > 0:
		out.append({"op": "stock_add", "location": "backroom", "item": item_id, "qty": -from_back})
	if qty - from_back > 0:
		out.append({"op": "stock_add", "location": "shelf", "item": item_id, "qty": -(qty - from_back)})
	return out
