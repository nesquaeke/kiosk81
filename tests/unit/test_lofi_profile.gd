extends TestCase
## Retro-intensity presets must match the visual target (Gorsel Hedef 5-7).

const FULL_HD: Vector2i = Vector2i(1920, 1080)


func test_default_is_medium() -> void:
	assert_eq(LoFiProfile.DEFAULT_LEVEL, LoFiProfile.Level.MEDIUM)


func test_medium_matches_visual_target() -> void:
	var p: LoFiProfile = LoFiProfile.for_level(LoFiProfile.Level.MEDIUM)
	assert_eq(p.internal_size(FULL_HD), Vector2i(960, 540))
	assert_eq(p.color_levels, 32, "32 levels per channel")
	assert_eq(p.dither, 1.0, "full 4x4 Bayer")
	assert_eq(p.affine, 0.4, "world affine 40%")


func test_off_disables_every_distortion() -> void:
	var p: LoFiProfile = LoFiProfile.for_level(LoFiProfile.Level.OFF)
	assert_eq(p.internal_size(FULL_HD), FULL_HD)
	assert_eq(p.affine, 0.0)
	assert_eq(p.jitter_grid, Vector2i.ZERO)
	assert_eq(p.dither, 0.0)
	assert_eq(p.barrel, 0.0)
	assert_eq(p.chroma_px, 0.0)
	assert_eq(p.grain, 0.0)


func test_chroma_never_exceeds_one_pixel() -> void:
	for level: int in range(4):
		assert_true(LoFiProfile.for_level(level).chroma_px <= 1.0, "level %d" % level)


func test_resolution_never_below_640x360() -> void:
	for level: int in range(4):
		var size: Vector2i = LoFiProfile.for_level(level).internal_size(FULL_HD)
		assert_true(size.x >= 640 and size.y >= 360, "level %d gave %s" % [level, size])


func test_intensity_grows_with_level() -> void:
	for level: int in range(1, 4):
		var lower: LoFiProfile = LoFiProfile.for_level(level - 1)
		var higher: LoFiProfile = LoFiProfile.for_level(level)
		assert_true(higher.affine >= lower.affine, "affine at level %d" % level)
		assert_true(higher.grain >= lower.grain, "grain at level %d" % level)
		assert_true(higher.color_levels <= lower.color_levels, "colour steps at level %d" % level)


func test_out_of_range_level_is_clamped() -> void:
	assert_eq(LoFiProfile.for_level(-5).level, LoFiProfile.Level.OFF)
	assert_eq(LoFiProfile.for_level(99).level, LoFiProfile.Level.STRONG)


func test_level_names_are_turkish() -> void:
	assert_eq(LoFiProfile.for_level(LoFiProfile.Level.MEDIUM).display_name(), "Orta")
