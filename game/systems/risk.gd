class_name Risk
extends RefCounted
## The state's attention (demo step 2). Suspicion S (meter "suspicion", 0-100)
## rises with what Tadeusz does and falls a little every day. Each morning an
## inspector may come:  p = min(max, base + per_point * S)  (per-mille).
## The inspector counts this week's coupons against rationed sales (older sheets
## have gone to the office with Saturday's settlement) and may find the hiding
## place. A fine and more suspicion follow; a big gap or the hiding place is also
## a strike, and enough strikes mean Ruch takes the kiosk away (license_lost).
## Inspections never happen on the campaign's first day.


static func inspection_permille(state: CampaignState, balance: Balance) -> int:
	var s: int = int(state.meters.get("suspicion", 0))
	return mini(balance.r("inspection_max_permille"),
			balance.r("inspection_base_permille") + balance.r("inspection_per_point_permille") * s)


static func inspection_today(state: CampaignState, balance: Balance) -> bool:
	if state.day <= 1 or state.flags.get("license_lost", false) == true:
		return false
	return Dice.chance_permille(state, "inspection", inspection_permille(state, balance))


## What the inspector finds today and its effects. economy pays the fine.
static func inspection(state: CampaignState, balance: Balance, economy: Economy) -> Dictionary:
	var out: Array[Dictionary] = [{"op": "flag_add", "key": "inspections", "amount": 1}]
	var strikes: int = 0
	var fine: int = 0
	var unpaid: int = 0
	var shortfall: int = int(state.flags.get("coupon_shortfall", 0))
	var found_coupons: bool = false
	if shortfall > balance.r("coupon_tolerance"):
		var detect_pct: int = mini(90, balance.r("coupon_detect_base_pct") + balance.r("coupon_detect_per_10") * shortfall / 10)
		found_coupons = Dice.roll(state, "inspect_coupons") * 100.0 < float(detect_pct)
	if found_coupons:
		fine = shortfall * balance.r("fine_per_coupon")
		var paid: Dictionary = economy.pay(state, fine)
		out.append_array(paid["effects"])
		unpaid = paid["unpaid"]
		if unpaid > 0:
			out.append({"op": "flag_add", "key": "debt", "amount": unpaid})
		out.append({"op": "flag_set", "key": "coupon_shortfall", "value": 0})
		out.append({"op": "flag_add", "key": "fines_paid", "amount": fine})
		out.append({"op": "meter_add", "meter": "suspicion", "amount": balance.r("fine_suspicion")})
		if shortfall >= balance.r("strike_min_coupons"):
			strikes += 1  # small gaps cost money; big ones go on the record
	var hidden: Dictionary = state.stock.get("hidden", {})
	var illegal: Array[String] = []
	for item_id: Variant in hidden:
		if int(hidden[item_id]) > 0 and not economy.is_legal(str(item_id)):
			illegal.append(str(item_id))
	var found_hidden: bool = not illegal.is_empty() and Dice.roll(state, "inspect_hidden") * 100.0 < float(balance.r("hidden_find_pct"))
	if found_hidden:
		for item_id: String in illegal:
			out.append({"op": "stock_add", "location": "hidden", "item": item_id, "qty": -int(hidden[item_id])})
		out.append({"op": "flag_set", "key": "underground_found", "value": true})
		out.append({"op": "meter_add", "meter": "suspicion", "amount": balance.r("hidden_found_suspicion")})
		strikes += 1
	var clean: bool = strikes == 0
	if clean:
		out.append({"op": "meter_add", "meter": "suspicion", "amount": -balance.r("clean_relief")})
	else:
		out.append({"op": "flag_add", "key": "strikes", "amount": strikes})
	var total_strikes: int = int(state.flags.get("strikes", 0)) + strikes
	var license_lost: bool = total_strikes >= balance.r("strikes_to_lose_license")
	if license_lost:
		out.append({"op": "flag_set", "key": "license_lost", "value": true})
	out.append({"op": "decision_log", "entry": {"id": "inspection_clean" if clean else "inspection_fined", "fine": fine}})
	return {"effects": out, "clean": clean, "found_coupons": found_coupons, "found_hidden": found_hidden,
			"fine": fine, "unpaid": unpaid, "strikes": total_strikes, "license_lost": license_lost}


## Every night the attention fades a little.
static func night_effects(balance: Balance) -> Array[Dictionary]:
	return [{"op": "meter_add", "meter": "suspicion", "amount": -balance.r("daily_decay")}]
