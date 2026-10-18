extends TestCase

func test_opening_and_rest_frames_do_not_cut_paper() -> void:
	var stroke: ScissorStroke = ScissorStroke.new()
	assert_eq(stroke.advance(0.10, true), 0.0, "the opening blades cannot cut ahead of contact")
	assert_true(stroke.jaw_angle() > 0.45, "the actual upper blade opens visibly")
	assert_true(stroke.advance(0.10, true) > 0.0, "closing over paper produces real travel")
	stroke.advance(0.14, true)
	assert_eq(stroke.advance(0.06, true), 0.0, "closed rest does not continue cutting")
	assert_eq(stroke.jaw_angle(), 0.0)

func test_cut_travel_is_frame_rate_independent_across_multiple_closures() -> void:
	var fast: ScissorStroke = ScissorStroke.new()
	var slow: ScissorStroke = ScissorStroke.new()
	var a: float = 0.0
	var b: float = 0.0
	for frame: int in 252: a += fast.advance(1.0 / 60.0, true)
	for frame: int in 84: b += slow.advance(1.0 / 20.0, true)
	assert_true(absf(a - b) < 0.000001, "low FPS cannot invent or lose blade travel")
	assert_true(absf(a - 10.0 * 0.22 * 0.16) < 0.000001)

func test_moving_blades_without_paper_creates_no_cut_budget() -> void:
	var stroke: ScissorStroke = ScissorStroke.new()
	assert_eq(stroke.advance(0.42, false), 0.0)
	assert_true(stroke.advance(0.20, true) > 0.0)
