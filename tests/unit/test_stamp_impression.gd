extends TestCase
## Physics measurements survive saves and produce different rubber transfers.

const Impression: GDScript = preload("res://scenes/kiosk/stamp_impression_renderer.gd")


func test_light_contact_leaves_less_ink_and_more_dry_fibre_than_firm_contact() -> void:
	var light: Dictionary = Impression.ink_features({"pressure": 0.12, "speed": 0.3, "dwell": 0.1})
	var firm: Dictionary = Impression.ink_features({"pressure": 0.86, "speed": 0.3, "dwell": 0.1})
	assert_true(float(light["density"]) < float(firm["density"]), "light touch must visibly transfer less ink")
	assert_true(float(light["dropout"]) > float(firm["dropout"]), "uncontacted fibres remain visible")


func test_held_contact_wicks_more_ink_but_fast_impact_has_a_rebound_edge() -> void:
	var held: Dictionary = Impression.ink_features({"pressure": 0.8, "speed": 0.15, "dwell": 1.2})
	var impact: Dictionary = Impression.ink_features({"pressure": 0.8, "speed": 2.5, "dwell": 0.05})
	assert_true(float(held["spread"]) > float(impact["spread"]), "paper absorbs ink while the rubber is held down")
	assert_true(float(held["density"]) > float(impact["density"]))
	assert_true(float(impact["impact_offset"]) > float(held["impact_offset"]), "a fast rebound produces a slight doubled contour")


func test_lateral_transfer_uses_real_sheet_scale_and_direction() -> void:
	var mark: Dictionary = {"smudge": 0.01, "smudge_direction": [0.0, -1.0]}
	var ink: Dictionary = Impression.ink_features(mark)
	var displacement: Vector2 = ink["smudge_pixels"]
	assert_true(is_equal_approx(displacement.x, 0.0))
	assert_true(is_equal_approx(displacement.y, -640.0 * 0.01 / 0.36), "one centimetre of drag is one centimetre of print-space displacement")


func test_loading_the_same_contact_never_rerolls_print_or_mutates_saved_mark() -> void:
	var mark: Dictionary = {"kind": "approve", "x": 538.45, "y": 181.2, "serial": 3, "pressure": 0.7, "speed": 0.6, "dwell": 0.23, "angle": 0.1, "smudge": 0.003, "smudge_direction": [1.0, 0.0]}
	var snapshot: Dictionary = mark.duplicate(true)
	var restored: Dictionary = JSON.parse_string(JSON.stringify(mark))
	assert_eq(Impression.ink_features(mark), Impression.ink_features(restored), "ink remains anchored to the persisted contact")
	assert_eq(mark, snapshot, "rendering owns no campaign state")
