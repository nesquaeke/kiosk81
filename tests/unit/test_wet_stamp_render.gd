extends TestCase

const Impression: GDScript = preload("res://scenes/kiosk/stamp_impression_renderer.gd")
const WetView: GDScript = preload("res://scenes/kiosk/stamp_wetness_view.gd")


func _mark() -> Dictionary:
	return {"kind": "approve", "serial": 3, "x": 538.25, "y": 182.0, "angle": 0.17, "pressure": 0.72, "speed": 0.35, "dwell": 0.25, "ink_load": 0.8, "tilt": 0.12, "contact_time": 10.0, "dry_duration": 10.0}


func test_empty_rubber_transfers_no_ink_and_depleted_rubber_exposes_more_fibres() -> void:
	var full: Dictionary = Impression.ink_features({"ink_load": 1.0})
	var depleted: Dictionary = Impression.ink_features({"ink_load": 0.12})
	var empty: Dictionary = Impression.ink_features({"ink_load": 0.0})
	assert_true(float(depleted["density"]) < float(full["density"]) * 0.2)
	assert_true(float(depleted["dropout"]) > float(full["dropout"]))
	assert_eq(empty["density"], 0.0)
	assert_eq(Impression.ink_features({}), full, "legacy marks default to the old fully inked transfer")


func test_opposite_tilts_keep_same_mass_and_grain_but_reverse_dry_shoulder() -> void:
	var left: Dictionary = Impression.ink_features({"tilt": -0.24})
	var right: Dictionary = Impression.ink_features({"tilt": 0.24})
	var flat: Dictionary = Impression.ink_features({"tilt": 0.0})
	assert_eq(left["seed"], right["seed"], "angle must not reroll paper pores")
	assert_eq(left["density"], right["density"])
	assert_true(float(left["density"]) < float(flat["density"]))
	assert_true(float(left["dropout"]) > float(flat["dropout"]))
	var impression: Control = Impression.new()
	impression.set_impression({"tilt": -0.24})
	assert_eq((impression.material as ShaderMaterial).get_shader_parameter("contact_tilt"), -0.24)
	impression.free()


func test_wet_mask_reuses_exact_imprint_registration_and_grain() -> void:
	var mark: Dictionary = _mark()
	var ink: Control = Impression.new()
	var mask: Control = Impression.new()
	mask.wet_mask = true
	ink.set_impression(mark)
	mask.set_impression(mark)
	assert_eq(mask.position, ink.position)
	assert_eq(mask.rotation, ink.rotation)
	assert_eq(mask.features, ink.features)
	var ink_material: ShaderMaterial = ink.material
	var mask_material: ShaderMaterial = mask.material
	for parameter: String in ["grain_seed", "ink_density", "dropout", "contact_pressure", "contact_tilt"]:
		assert_eq(mask_material.get_shader_parameter(parameter), ink_material.get_shader_parameter(parameter))
	assert_eq(ink_material.get_shader_parameter("wet_mask"), false)
	assert_eq(mask_material.get_shader_parameter("wet_mask"), true)
	ink.free()
	mask.free()


func test_explicit_paused_time_preserves_wetness_and_all_permanent_print_data() -> void:
	var mark: Dictionary = _mark()
	var snapshot: Dictionary = mark.duplicate(true)
	var mask: Control = Impression.new()
	mask.wet_mask = true
	mask.set_impression(mark)
	mask.set_game_time(14.0)
	var wetness: float = mask.current_wetness
	var features: Dictionary = mask.features.duplicate(true)
	for frame: int in 100:
		assert_false(mask.set_game_time(14.0), "paused frames do not dry the paper")
	assert_eq(mask.current_wetness, wetness)
	assert_eq(mask.features, features)
	assert_eq(mask.impression, snapshot)
	assert_eq(mark, snapshot)
	mask.free()


func test_drying_removes_only_liquid_sheen_not_the_stain() -> void:
	var mask: Control = Impression.new()
	mask.wet_mask = true
	mask.set_impression(_mark())
	mask.set_game_time(10.0)
	assert_eq(mask.current_wetness, 1.0)
	var original: Dictionary = mask.features.duplicate(true)
	mask.set_game_time(15.0)
	assert_true(mask.current_wetness > 0.0 and mask.current_wetness < 1.0)
	mask.set_game_time(20.0)
	assert_eq(mask.current_wetness, 0.0)
	assert_eq(mask.features, original)
	assert_false(mask.impression.is_empty())
	mask.free()


func test_fullsheet_mask_owns_snapshot_and_excludes_legacy_dry_and_zero_ink_marks() -> void:
	var mark: Dictionary = _mark()
	var empty: Dictionary = _mark()
	empty["ink_load"] = 0.0
	var source: Array = [{"kind": "approve"}, mark, empty]
	var mask: Control = WetView.new()
	mask.set_game_time(12.0)
	mask.set_marks(source)
	assert_eq(mask.size, Vector2(640, 400))
	assert_eq(mask.wet_count(), 1)
	assert_true(mask.has_wet_ink())
	mark["x"] = 0
	source.clear()
	assert_eq(mask.marks.size(), 3)
	assert_eq(mask.marks[1]["x"], 538.25, "later customers cannot replace a detached coupon's wet ink")
	mask.set_game_time(20.0)
	assert_false(mask.has_wet_ink())
	mask.free()


func test_mask_requests_viewport_redraw_only_on_changed_explicit_game_time() -> void:
	var viewport: SubViewport = SubViewport.new()
	var mask: Control = WetView.new()
	viewport.add_child(mask)
	mask.set_game_time(10.0)
	mask.set_marks([_mark()])
	assert_eq(viewport.render_target_update_mode, SubViewport.UPDATE_ONCE)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	assert_false(mask.set_game_time(10.0))
	assert_false(mask.set_game_time(10.02), "wet texture refresh is capped at 20 Hz")
	assert_eq(viewport.render_target_update_mode, SubViewport.UPDATE_DISABLED)
	assert_true(mask.set_game_time(10.1))
	assert_eq(viewport.render_target_update_mode, SubViewport.UPDATE_ONCE)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	assert_true(mask.set_game_time(20.0), "the exact final dry state must be rendered")
	assert_eq(viewport.render_target_update_mode, SubViewport.UPDATE_ONCE)
	assert_false(mask.set_game_time(25.0), "dry footprints no longer spend rendering work")
	viewport.free()


func test_rub_sampling_keeps_actual_direction_and_rejects_untouched_or_malformed_paths() -> void:
	var rub: Dictionary = Impression.rub_features({"from": [-20.0, 0.0], "to": [-20.0, 35.5555556], "wetness": 0.7})
	assert_eq(rub["from"], Vector2(-20, 0))
	assert_true(absf((rub["delta"] as Vector2).length() - 0.02 * 640.0 / 0.36) < 0.00001)
	assert_eq(rub["radius"], 6.0)
	assert_true(Impression.rub_features({"from": [90, 80], "to": [180, 100], "wetness": 1.0}).is_empty())
	assert_true(Impression.rub_features({"from": [0, 0], "to": [0, 0], "wetness": 1.0}).is_empty())
	assert_true(Impression.rub_features({"from": [0, 0], "to": [30, 0], "wetness": 0.0}).is_empty())
	assert_true(Impression.rub_features({"from": ["bad", 0], "to": [30, 0], "wetness": 1.0}).is_empty())


func test_rub_transfer_only_copies_touched_ink_and_survives_drying_without_translation_changes() -> void:
	var mark: Dictionary = _mark()
	mark["rubs"] = [{"from": [-20.0, 0.0], "to": [30.0, 15.0], "wetness": 0.7}]
	var ink: Control = Impression.new()
	ink.set_impression(mark)
	var positions: Array[Vector2] = []
	var pull: Vector2 = Vector2(50, 15)
	assert_true(ink.get_child_count() > 1, "a pull must distribute touched pigment along the actual path")
	for child: Node in ink.get_children():
		var transfer: Control = child as Control
		var material: ShaderMaterial = transfer.material
		positions.append(transfer.position)
		var along: float = transfer.position.dot(pull) / pull.length_squared()
		assert_true(along > 0.0 and along <= 1.00001)
		assert_true(transfer.position.distance_to(pull * along) < .00001, "pigment cannot move sideways out of its sampled pull")
		assert_eq(material.get_shader_parameter("finger_clip"), true)
		assert_eq(material.get_shader_parameter("finger_from"), Vector2(-20, 0))
		assert_eq(material.get_shader_parameter("finger_to"), Vector2(30, 15))
	assert_true(positions[-1].distance_to(pull) < .00001, "the farthest transfer ends at the actual finger destination")
	ink.set_game_time(100.0)
	var dried_positions: Array[Vector2] = []
	for child: Node in ink.get_children(): dried_positions.append((child as Control).position)
	assert_eq(dried_positions, positions, "drying never erases or moves a permanent fingerprint pull")
	assert_eq(ink.position, Vector2(538.25, 182))
	assert_eq(ink.impression, mark)
	ink.free()


func test_load_tilt_and_finger_stains_are_deterministic_after_json_round_trip() -> void:
	var mark: Dictionary = _mark()
	mark["rubs"] = [{"from": [0.2, -4.0], "to": [30.7, 12.0], "wetness": 0.54}]
	var restored: Dictionary = JSON.parse_string(JSON.stringify(mark))
	assert_eq(Impression.ink_features(mark), Impression.ink_features(restored))
	assert_eq(Impression.rub_features(mark["rubs"][0]), Impression.rub_features(restored["rubs"][0]))
