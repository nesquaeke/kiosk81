class_name RationEvidence
extends RefCounted
## Findings are derived from facts printed on the paper and accompanying ID.
## Cosmetic wear, paste, paper stock and ink density are never verdict inputs.

const PRODUCTS: PackedStringArray = ["meat", "sugar", "soap"]
const PRODUCT_NAMES: Dictionary = {"meat": "Et", "sugar": "Şeker", "soap": "Sabun"}
const SEAL_ALIGNMENT_TOLERANCE: float = 2.0
const PORTRAIT_VARIANTS: int = 8


static func portrait_key(portrait_id: int) -> int:
	return posmod(portrait_id, PORTRAIT_VARIANTS)


static func inspect(encounter: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var card: Dictionary = encounter.get("card", {})
	var evidence: Dictionary = card.get("evidence", {})
	var date: Dictionary = evidence.get("date", {})
	var underprint: String = str(date.get("underprint_month", "")).strip_edges()
	if not underprint.is_empty() and underprint != str(card.get("month", "")):
		out.append(_finding("altered_month", "Silinti altındaki ay (%s) üstteki ayla (%s) uyuşmuyor" % [underprint, str(card.get("month", ""))], true))
	var portrait: Dictionary = evidence.get("portrait", {})
	var offset: Variant = portrait.get("seal_offset", [0, 0])
	if offset is Array and offset.size() == 2 and _finite_number(offset[0]) and _finite_number(offset[1]):
		if Vector2(float(offset[0]), float(offset[1])).length() > SEAL_ALIGNMENT_TOLERANCE:
			out.append(_finding("portrait_seal", "Fotoğrafın üstündeki mühür çizgisi karttaki devamıyla birleşmiyor", true))
	var identity: Dictionary = encounter.get("identity", {})
	if not identity.is_empty():
		if _different_text(card.get("holder", ""), identity.get("holder", "")):
			out.append(_finding("identity_holder", "Karne sahibi ile kimlikteki ad uyuşmuyor", true))
		if _different_text(card.get("identity_number", ""), identity.get("number", "")):
			out.append(_finding("identity_number", "Karnedeki kimlik numarası ek kimlik belgesiyle uyuşmuyor", true))
		if card.has("portrait_variant") and identity.has("portrait_variant") and portrait_key(int(card["portrait_variant"])) != portrait_key(int(identity["portrait_variant"])):
			out.append(_finding("identity_portrait", "Karnedeki fotoğraf ile kimlik belgesindeki fotoğraf farklı", true))
	var coupons: Dictionary = evidence.get("coupons", {})
	var available: Array = card.get("available", [])
	var request: Dictionary = encounter.get("request", {})
	for item: String in PRODUCTS:
		if not item in available:
			continue
		var coupon: Dictionary = coupons.get(item, {})
		if _different_text(coupon.get("serial", ""), card.get("serial", "")):
			out.append(_finding("coupon_serial_" + item, "Kupon seri numarası ana karneyle uyuşmuyor: " + str(PRODUCT_NAMES[item]), true))
		if request.get("item", "") == item and not str(coupon.get("previous_issue", "")).strip_edges().is_empty():
			out.append(_finding("coupon_issued_" + item, "İstenen kuponda önceki teslim tarihi var: " + str(coupon["previous_issue"]), false))
	return out


static func issues(encounter: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for finding: Dictionary in inspect(encounter):
		out.append(finding["message"])
	return out


static func is_forged(encounter: Dictionary) -> bool:
	for finding: Dictionary in inspect(encounter):
		if finding["forgery"]:
			return true
	return false


static func _finding(code: String, message: String, forgery: bool) -> Dictionary:
	return {"code": code, "message": message, "forgery": forgery}


static func _different_text(left: Variant, right: Variant) -> bool:
	var first: String = str(left).strip_edges().to_upper()
	var second: String = str(right).strip_edges().to_upper()
	return not first.is_empty() and not second.is_empty() and first != second


static func _finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))
