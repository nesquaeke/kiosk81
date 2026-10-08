extends SceneTree
## Balance simulator (demo steps 1-2). Plays the first four weeks of martial law
## (from Monday 14 December 1981) many times for each play style and writes a
## report: docs/BALANCE_REPORT.md. Only the background half of each day is
## simulated (no story customers), so it measures the systems, not the story.
## Run: godot --headless --path . --script res://tools/simulate.gd [-- --runs=300 --days=28]

const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")
const OUT: String = "res://docs/BALANCE_REPORT.md"
const START_DATE: String = "1981-12-14"
const STYLES: Array[Array] = [
	["honest", "Dürüst", {"skim_pct": 0, "under_counter": 0, "usd_sunday_pct": 0}],
	["skimmer", "Kasadan çalan (rutin satışın %10'u)", {"skim_pct": 10, "under_counter": 0, "usd_sunday_pct": 0}],
	["careful", "Dikkatli tezgâh altı (günde 10 paket)", {"skim_pct": 0, "under_counter": 10, "usd_sunday_pct": 80}],
	["greedy", "Açgözlü tezgâh altı (günde 30 paket)", {"skim_pct": 0, "under_counter": 30, "usd_sunday_pct": 80}],
]


func _init() -> void:
	var runs: int = 300
	var days: int = 28
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = arg.trim_prefix("--runs=").to_int()
		elif arg.begins_with("--days="):
			days = arg.trim_prefix("--days=").to_int()
	var db: Node = ContentDBScript.new()
	if not db.load_roots(ContentDBScript.DEFAULT_ROOTS):
		printerr("\n".join(db.errors))
		db.free()
		quit(1)
		return
	var balance: Balance = Balance.from_record(db.get_record("balance", Balance.RECORD_ID))
	var items: Array = db.all_of("item")
	var lines: PackedStringArray = []
	lines.append("# Denge raporu (otomatik)")
	lines.append("")
	lines.append("`tools/simulate.gd` üretti · %s · %d gün (%s başlangıç) · her oyun tarzı için %d tohum. Yalnız arka plan sistemleri: hikâye müşterileri yok." % [Time.get_date_string_from_system(), days, START_DATE, runs])
	lines.append("")
	lines.append("| Oyun tarzı | Servet değişimi (ortalama) | Kötü %10 / iyi %10 | Dolar (ort.) | Denetim (ort.) | En az bir ceza | Ruhsat kaybı | Ev açığı yaşanan | Şüphe sonu (ort.) |")
	lines.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	var all_ok: bool = true
	var summary: Dictionary = {}
	for style: Array in STYLES:
		var result: Dictionary = _run_style(balance, items, style[2], runs, days)
		summary[style[0]] = result
		all_ok = all_ok and result["errors"] == 0
		lines.append("| %s | %s | %s / %s | %.0f $ | %.1f | %d%% | %d%% | %d%% | %.0f |" % [
			style[1], _zl(result["mean_change"]), _zl(result["p10"]), _zl(result["p90"]), result["usd"],
			result["inspections"], result["fined_pct"], result["license_pct"], result["shortfall_pct"], result["suspicion"]])
	lines.append("")
	lines.append("Servet = ev bütçesi + cep + bekleyen prim − manko + dolar (karaborsa kuruyla) − borç; başlangıç %s." % _zl(_start_wealth(balance, items)))
	var f: FileAccess = FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("\n".join(lines))
	print("[simulate] %s; errors: %s" % [OUT, "none" if all_ok else "SEE ABOVE"])
	db.free()
	quit(0 if all_ok else 1)


static func start_state(seed_value: int) -> CampaignState:
	var s: CampaignState = CampaignState.new()
	s.rng_seed = seed_value
	s.calendar_date = START_DATE
	s.day = 2  # the prologue night is day 1
	s.money["household"] = 2000000
	s.money["till"] = 2000
	s.stock["backroom"] = {"itm_cigarettes_popularne": 0, "itm_matches": 0}
	s.stock["hidden"] = {}
	return s


func _start_wealth(balance: Balance, items: Array) -> int:
	return Economy.new(balance, items).wealth(start_state(0))


func _run_style(balance: Balance, items: Array, policy: Dictionary, runs: int, days: int) -> Dictionary:
	var changes: Array[int] = []
	var usd_total: float = 0.0
	var inspections: float = 0.0
	var fined: int = 0
	var lost: int = 0
	var short: int = 0
	var suspicion: float = 0.0
	var errors: int = 0
	for run: int in runs:
		var sim: DaySimulator = DaySimulator.new(start_state(1000 + run), balance, items)
		sim.policy = policy
		var start: int = sim.economy.wealth(sim.state)
		sim.run_days(days)
		if not sim.errors.is_empty():
			errors += 1
			if errors == 1:
				printerr("\n".join(sim.errors))
		changes.append(sim.economy.wealth(sim.state) - start)
		usd_total += float(sim.state.money["usd"]) / 100.0
		inspections += float(sim.state.flags.get("inspections", 0))
		if int(sim.state.flags.get("fines_paid", 0)) > 0:
			fined += 1
		if sim.state.flags.get("license_lost", false) == true:
			lost += 1
		if int(sim.state.flags.get("household_shortfall", 0)) > 0:
			short += 1
		suspicion += float(sim.state.meters["suspicion"])
	changes.sort()
	var total: int = 0
	for c: int in changes:
		total += c
	return {
		"mean_change": total / runs, "p10": changes[runs / 10], "p90": changes[runs * 9 / 10],
		"usd": usd_total / runs, "inspections": inspections / runs, "fined_pct": fined * 100 / runs,
		"license_pct": lost * 100 / runs, "shortfall_pct": short * 100 / runs, "suspicion": suspicion / runs, "errors": errors,
	}


static func _zl(grosze: int) -> String:
	return ("+" if grosze > 0 else "") + Money.format(grosze)
