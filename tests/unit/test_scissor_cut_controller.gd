extends TestCase


func test_opening_and_closed_rest_do_not_move_the_cutting_tip() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2(20, 30))
	var target: Vector2 = Vector2(600, 30)
	assert_eq(control.advance(0.10, target), 0.0)
	assert_eq(control.tip, Vector2(20, 30))
	assert_true(control.jaw_angle() > 0.45)
	assert_true(control.advance(0.10, target) > 0.0)
	control.advance(0.14, target)
	var before: Vector2 = control.tip
	assert_eq(control.advance(0.06, target), 0.0)
	assert_eq(control.tip, before)


func test_two_centimetre_target_stops_at_the_exact_target_without_extra_damage() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	var two_cm: float = 0.02 * ScissorCutController.PIXELS_PER_METRE
	control.start(Vector2(100, 160))
	var target: Vector2 = control.tip + Vector2(two_cm, 0)
	var travelled: float = control.advance(1.0, target)
	assert_true(absf(travelled / ScissorCutController.PIXELS_PER_METRE - 0.02) < 0.000001)
	assert_eq(control.tip, target, "a large mouse jump is still clamped to real target distance")
	assert_eq(control.advance(10.0, target), 0.0, "resting on the endpoint never extends its incision")
	assert_eq(control.tip, target)


func test_short_closure_remains_short_and_does_not_complete_a_whole_cycle() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2.ZERO)
	var travelled: float = control.advance(0.14, Vector2(1000, 0))
	var metres: float = travelled / ScissorCutController.PIXELS_PER_METRE
	assert_true(absf(metres - 0.02 * ScissorStroke.CLOSING_SPEED) < 0.000001)
	assert_true(metres < 0.004, "only the first 20 ms of actual closure has touched paper")


func test_sharp_corner_reopens_and_rotates_without_moving_or_cutting() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2.ZERO)
	control.advance(0.30, Vector2(300, 0))
	var corner: Vector2 = control.tip
	var jaw_before: float = control.jaw_angle()
	var target: Vector2 = corner + Vector2(0, 200)
	assert_eq(control.advance(0.06, target), 0.0)
	assert_true(control.aligning)
	assert_eq(control.tip, corner)
	assert_eq(control.direction, Vector2.RIGHT, "reopen before steering the blade")
	assert_true(control.jaw_angle() > jaw_before)
	assert_eq(control.advance(0.06, target), 0.0)
	var before_direction: Vector2 = control.direction
	assert_eq(control.advance(0.10, target), 0.0)
	assert_true(absf(before_direction.angle_to(control.direction)) <= ScissorCutController.TURN_SPEED * 0.10 + 0.000001)
	assert_true(control.jaw_angle() > 0.53)
	assert_eq(control.tip, corner, "no diagonal incision is inferred through the turn")
	assert_true(control.advance(0.50, target) > 0.0)
	assert_false(control.aligning)
	assert_true(absf(control.tip.x - corner.x) < 0.00001)
	assert_true(control.tip.y > corner.y)


func test_cutting_distance_and_corner_pause_are_frame_rate_independent() -> void:
	var fast: ScissorCutController = _trajectory(60)
	var slow: ScissorCutController = _trajectory(20)
	assert_true(fast.tip.distance_to(slow.tip) < 0.0001, "opening/turning consume elapsed time, not extra render frames")
	assert_true(absf(fast.jaw_angle() - slow.jaw_angle()) < 0.0001)
	assert_eq(fast.cycle(), slow.cycle())
	assert_eq(fast.aligning, slow.aligning)


func test_fine_mode_slows_real_closure_and_does_not_change_metres_per_pixel() -> void:
	var normal: ScissorCutController = ScissorCutController.new()
	var fine: ScissorCutController = ScissorCutController.new()
	normal.start(Vector2.ZERO)
	fine.start(Vector2.ZERO)
	var target: Vector2 = Vector2(1000, 0)
	assert_true(normal.advance(0.20, target) > 0.0)
	assert_eq(fine.advance(0.20, target, true), 0.0, "fine scissors are still opening at 200 ms")
	for frame: int in 60:
		normal.advance(1.0 / 60.0, target)
		fine.advance(1.0 / 60.0, target, true)
	assert_true(fine.tip.x > 0.0 and fine.tip.x < normal.tip.x)
	var exact: Vector2 = fine.tip + Vector2(0.02 * ScissorCutController.PIXELS_PER_METRE, 0)
	var start: Vector2 = fine.tip
	var travelled: float = fine.advance(10.0, exact, true)
	assert_eq(fine.tip, exact)
	assert_true(absf(travelled / ScissorCutController.PIXELS_PER_METRE - 0.02) < 0.000001)
	assert_true(absf(fine.tip.distance_to(start) / ScissorCutController.PIXELS_PER_METRE - 0.02) < 0.000001)


func test_release_discards_unspent_motion_and_start_requires_a_new_opening() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2.ZERO)
	control.advance(0.25, Vector2(400, 0))
	var final_tip: Vector2 = control.tip
	control.release()
	assert_false(control.active)
	assert_false(control.aligning)
	assert_eq(control.advance(2.0, Vector2(600, 0)), 0.0)
	assert_eq(control.tip, final_tip, "release does not erase the incision endpoint")
	control.start(Vector2(75, 80))
	assert_eq(control.advance(0.10, Vector2(300, 80)), 0.0, "old closing travel is never banked")
	assert_eq(control.tip, Vector2(75, 80))
	control.reset()
	assert_false(control.active)
	assert_eq(control.tip, Vector2.ZERO)


func test_waiting_at_a_target_never_banks_cutting_distance_for_the_next_move() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2(50, 80))
	assert_eq(control.advance(20.0, control.tip), 0.0)
	var travelled: float = control.advance(0.001, Vector2(500, 80))
	var maximum_one_ms: float = 0.001 * ScissorStroke.CLOSING_SPEED * ScissorCutController.PIXELS_PER_METRE
	assert_true(travelled <= maximum_one_ms + 0.000001, "twenty seconds of idle jaw motion supplies no future travel")


func test_target_changes_while_turning_do_not_create_a_cut_or_teleport() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2(40, 70))
	var first: Vector2 = control.tip
	control.advance(0.18, first + Vector2(0, 100))
	assert_true(control.aligning)
	assert_eq(control.tip, first)
	control.advance(0.05, first + Vector2(-100, 0))
	assert_true(control.aligning)
	assert_eq(control.tip, first)
	assert_true(control.advance(1.0, first + Vector2(-100, 0)) > 0.0)
	assert_true(control.tip.x < first.x)
	assert_true(absf(control.tip.y - first.y) < 0.00001)


func test_invalid_time_and_target_leave_all_physical_state_untouched() -> void:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2(10, 20), Vector2.ZERO)
	assert_eq(control.direction, Vector2.RIGHT)
	assert_eq(control.advance(-1.0, Vector2(200, 20)), 0.0)
	assert_eq(control.advance(1.0, Vector2(INF, 20)), 0.0)
	assert_eq(control.advance(INF, Vector2(200, 20)), 0.0)
	assert_eq(control.tip, Vector2(10, 20))
	assert_eq(control.stroke.elapsed, 0.0)


func _trajectory(fps: int) -> ScissorCutController:
	var control: ScissorCutController = ScissorCutController.new()
	control.start(Vector2(40, 70))
	# Same authored input times with actual corners; no route/coupon snapping.
	# Every target is deliberately out of reach so endpoint clamping cannot hide
	# a frame-dependent difference in reopening, steering or closing time.
	var headings: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for heading: Vector2 in headings:
		var target: Vector2 = control.tip + heading * 1000.0
		for frame: int in fps:
			control.advance(1.0 / float(fps), target)
	return control
