class_name Money
extends RefCounted
## Money is stored as whole grosze (1 złoty = 100 groszy). Formatting only lives here.


## 1234 -> "12,34 zł"; -50 -> "-0,50 zł" (Polish style: comma for decimals).
static func format(grosze: int) -> String:
	var sign: String = "-" if grosze < 0 else ""
	var g: int = absi(grosze)
	return "%s%d,%02d zł" % [sign, g / 100, g % 100]
