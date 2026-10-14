class_name KioskCatalog
extends RefCounted
## Visual descriptions only. ContentDB owns legality and prices.

const PRODUCTS: Array[Dictionary] = [
	{"id": "itm_trybuna_ludu", "tr": "Trybuna Ludu", "en": "Trybuna Ludu", "shape": "newspaper", "color": Color("d8ccb0")},
	{"id": "itm_zolnierz_wolnosci", "tr": "Żołnierz Wolności", "en": "Żołnierz Wolności", "shape": "newspaper", "color": Color("c1c7b0")},
	{"id": "itm_przekroj", "tr": "Przekrój dergisi", "en": "Przekrój magazine", "shape": "magazine", "color": Color("a84639")},
	{"id": "itm_matches", "tr": "Kibrit", "en": "Matches", "shape": "matches", "color": Color("c5954e")},
	{"id": "itm_bus_ticket", "tr": "Otobüs / tramvay bileti", "en": "Bus / tram ticket", "shape": "ticket", "color": Color("dfb989")},
	{"id": "itm_envelope", "tr": "Zarf", "en": "Envelope", "shape": "envelope", "color": Color("eee0c3")},
	{"id": "itm_soap", "tr": "Sabun", "en": "Soap", "shape": "soap", "color": Color("abc3aa")},
	{"id": "itm_shoelaces", "tr": "Ayakkabı bağı", "en": "Shoelaces", "shape": "laces", "color": Color("493931")},
	{"id": "itm_razor_blades", "tr": "Jilet paketi", "en": "Razor blades", "shape": "blades", "color": Color("517387")},
	{"id": "itm_pencil", "tr": "Kurşun kalem", "en": "Pencil", "shape": "pencil", "color": Color("ce9a3e")},
	{"id": "itm_notebook", "tr": "Defter", "en": "Notebook", "shape": "notebook", "color": Color("466b5d")},
	{"id": "itm_hard_candy", "tr": "Ambalajlı şeker", "en": "Wrapped candy", "shape": "candy", "color": Color("c34d49")},
]


static func product(item_id: String) -> Dictionary:
	for spec: Dictionary in PRODUCTS:
		if spec["id"] == item_id:
			return spec
	return {}


static func title(item_id: String, language: String = "tr") -> String:
	return str(product(item_id).get(language, item_id))
