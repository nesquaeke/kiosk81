extends TestCase


func test_visual_coverage_leaves_short_uncut_attachments_visible() -> void:
	var incisions: Array = [{"points": [[0, 0], [35, 0]]}, {"points": [[35.5, 0], [100, 0]]}]
	var spans: Array[Dictionary] = ScissorCutGuide.boundary_spans(incisions, Vector2.ZERO, Vector2(100, 0))
	var uncut_length: float = 0.0
	for span: Dictionary in spans:
		if not span["cut"]:
			uncut_length += float(span["to"]) - float(span["from"])
	assert_true(absf(uncut_length - 0.5) < 0.000001, "the visual guide must expose even a sub-tolerance attachment, never invent a completed cut")
	assert_eq(incisions[0]["points"][1], [35, 0], "reading the guide cannot extend actual incision coordinates")


func test_diagonal_crossing_does_not_hide_an_uncut_boundary() -> void:
	var spans: Array[Dictionary] = ScissorCutGuide.boundary_spans([{"points": [[25, -20], [75, 20]]}], Vector2.ZERO, Vector2(100, 0))
	assert_eq(spans, [{"from": 0.0, "to": 100.0, "cut": false}])


func test_reversed_overlapping_and_clipped_strokes_preserve_actual_coverage() -> void:
	var incisions: Array = [{"points": [[40, 10], [-20, 10]]}, {"points": [[20, 10], [70, 10]]}, {"points": [[150, 10], [70, 10]]}]
	var spans: Array[Dictionary] = ScissorCutGuide.boundary_spans(incisions, Vector2(0, 10), Vector2(100, 10))
	var cut_length: float = 0.0
	for span: Dictionary in spans:
		assert_true(span["cut"])
		cut_length += float(span["to"]) - float(span["from"])
	assert_true(absf(cut_length - 100.0) < 0.000001, "overlaps are counted once and strokes are clipped to the physical edge")


func test_malformed_or_perpendicular_strokes_cannot_create_a_cut_rail() -> void:
	var strokes: Array = [null, {}, {"points": [[0, 0], [0, 90]]}, {"points": [[0, 0], ["bad", 0]]}]
	var spans: Array[Dictionary] = ScissorCutGuide.boundary_spans(strokes, Vector2.ZERO, Vector2(100, 0))
	assert_eq(spans, [{"from": 0.0, "to": 100.0, "cut": false}])
