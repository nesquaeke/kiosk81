class_name PaperStockProfile
extends RefCounted
## A paper supply, not a verdict. No occupation, quota or authenticity field is
## read here. Serial-derived variation remains identical after refresh/turning.

const STOCKS: PackedStringArray = ["thin", "medium", "thick"]


static func stable_seed(serial: String) -> int:
	# Bounded arithmetic stays stable across runs and platforms, without the
	# engine's String.hash implementation or a global random-number generator.
	var value: int = 5381
	for index: int in serial.length():
		value = (value * 131 + serial.unicode_at(index)) % 2147483647
	return value


static func resolve(document: Dictionary) -> Dictionary:
	var seed: int = stable_seed(str(document.get("serial", "")))
	var stock: String = str(document.get("paper_stock", "")).strip_edges().to_lower()
	if not stock in STOCKS:
		stock = STOCKS[seed % STOCKS.size()]
	var thickness: float = 0.00028
	var tint: Color = Color(0.985, 0.985, 0.975)
	var fibre_strength: float = 1.0
	var grain_scale: float = 1.0
	var stiffness: float = 1.0
	var label: String = "Papier kancelaryjny"
	match stock:
		"thin":
			thickness = 0.00014
			tint = Color(1.0, 0.995, 0.965)
			fibre_strength = 0.70
			grain_scale = 1.18
			stiffness = 0.72
			label = "Papier cienki"
		"thick":
			thickness = 0.00048
			tint = Color(0.975, 0.945, 0.875)
			fibre_strength = 1.45
			grain_scale = 0.80
			stiffness = 1.45
			label = "Papier sztywny"
	var wear: float = 0.80 if bool(document.get("worn", false)) else 0.12 + float(seed % 17) * 0.009
	var explicit_wear: Variant = document.get("paper_wear")
	if (explicit_wear is float or explicit_wear is int) and is_finite(float(explicit_wear)):
		wear = clampf(float(explicit_wear), 0.0, 1.0)
	return {
		"stock": stock,
		"label": label,
		"thickness": thickness,
		"sheet_half_thickness": thickness * 0.5,
		"stock_tint": tint,
		"fibre_strength": fibre_strength,
		"grain_scale": grain_scale,
		"bend_stiffness": stiffness,
		"wear": wear,
		"sheet_seed": float(seed % 65521),
	}
