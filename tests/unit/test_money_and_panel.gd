extends TestCase
## Money formatting and the developer panel summary (roadmap 1.12).

const DevPanelScript: GDScript = preload("res://game/debug/dev_panel.gd")


func test_money_format() -> void:
	assert_eq(Money.format(0), "0,00 zł")
	assert_eq(Money.format(290), "2,90 zł")
	assert_eq(Money.format(123456), "1234,56 zł")
	assert_eq(Money.format(-50), "-0,50 zł")


func test_panel_describes_the_state() -> void:
	var s: CampaignState = CampaignState.new()
	s.money["till"] = 290
	s.stock["shelf"]["itm_matches"] = 4
	s.ensure_character("chr_marek")["relations"]["suspicion"] = 2
	s.flags["met_marek"] = true
	s.decision_log.append({"id": "hid_leaflets", "day": 1, "minute": 500})
	var text: String = DevPanelScript.describe(s)
	assert_true(text.contains("DAY 1 · 1981-12-13 · 07:30 · morning"), text)
	assert_true(text.contains("till 2,90 zł"), text)
	assert_true(text.contains("matches ×4"), text)
	assert_true(text.contains("suspicion +2"), text)
	assert_true(text.contains("met_marek=true"), text)
	assert_true(text.contains("08:20  hid_leaflets"), text)
