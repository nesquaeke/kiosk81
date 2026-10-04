extends TestCase
## DialogueRunner over the format-test dialogue (ADR-001, roadmap 1.10).

const ContentDBScript: GDScript = preload("res://game/content/content_db.gd")

var db: Node
var state: CampaignState
var runner: DialogueRunner
var _locale_before: String = ""


func before_each() -> void:
	_locale_before = TranslationServer.get_locale()
	Loc.load_tables()
	TranslationServer.set_locale("en")
	db = ContentDBScript.new()
	db.load_roots(ContentDBScript.DEFAULT_ROOTS)
	state = CampaignState.new()
	state.phase = "shift"
	state.stock["shelf"]["itm_trybuna_ludu"] = 3
	runner = DialogueRunner.new(db.get_record("dialogue", "dlg_test_newspaper"))


func after_each() -> void:
	db.free()
	TranslationServer.set_locale(_locale_before)


func _apply(effects: Array[Dictionary]) -> void:
	var r: EffectPipeline.Result = EffectPipeline.apply(state, effects)
	assert_true(r.ok, r.error)
	if r.ok:
		state = r.state


func _texts(items: Array[Dictionary]) -> PackedStringArray:
	var out: PackedStringArray = []
	for item: Dictionary in items:
		out.append(item["text"])
	return out


func test_start_filters_lines_and_choices() -> void:
	var step: DialogueRunner.Step = runner.start(state)
	assert_eq(step.node_id, "ask")
	assert_eq(_texts(step.lines), PackedStringArray(["Trybuna Ludu, please."]), "complaint line needs the flag")
	assert_eq(step.choices.size(), 2, "no hidden stock, so no under-the-counter offer")
	assert_eq(step.choices[0]["key"], "dlg_test_newspaper.ask.c0")


func test_sale_returns_effects_and_ends() -> void:
	runner.start(state)
	var fx: Array[Dictionary] = runner.choose(0)
	assert_eq(fx.size(), 4)
	_apply(fx)
	assert_eq(state.money["till"], 100)
	assert_eq(state.stock_count("shelf", "itm_trybuna_ludu"), 2)
	assert_eq(state.register.size(), 1)
	var step: DialogueRunner.Step = runner.next(state)
	assert_eq(step.node_id, "thanks")
	assert_true(step.finished)
	assert_true(step.choices.is_empty())
	assert_eq(runner.next(state), null)
	assert_true(runner.is_over())


func test_earlier_choice_changes_a_later_visit() -> void:
	runner.start(state)
	_apply(runner.choose(1))  # "Sold out" sets the flag
	var second: DialogueRunner = DialogueRunner.new(db.get_record("dialogue", "dlg_test_newspaper"))
	var step: DialogueRunner.Step = second.start(state)
	assert_eq(step.lines.size(), 2, "the customer remembers")


func test_hidden_choice_appears_with_hidden_stock() -> void:
	state.stock["hidden"]["itm_tygodnik_mazowsze"] = 1
	var step: DialogueRunner.Step = runner.start(state)
	assert_eq(step.choices.size(), 3)
	assert_eq(step.choices[2]["index"], 2)


func test_choice_not_on_offer_is_refused() -> void:
	runner.start(state)
	var fx: Array[Dictionary] = runner.choose(2)  # hidden: no underground paper
	assert_true(fx.is_empty())
	assert_true(runner.error.contains("not on offer"))
	assert_false(runner.is_over(), "nothing moved")


func test_runner_never_changes_the_state() -> void:
	var before: Dictionary = state.to_dict()
	runner.start(state)
	runner.choose(0)
	runner.next(state)
	assert_eq(state.to_dict(), before, "effects are only returned, not applied")


func test_goto_node_offers_continue() -> void:
	var record: Dictionary = {
		"id": "dlg_t", "speakers": ["narrator"], "start": "a",
		"nodes": {"a": {"lines": [{"speaker": "narrator", "text": "Snow."}], "goto": "b"}, "b": {"lines": [{"speaker": "narrator", "text": "More snow."}], "end": true}},
	}
	var r: DialogueRunner = DialogueRunner.new(record)
	var step: DialogueRunner.Step = r.start(state)
	assert_eq(step.choices.size(), 1)
	assert_eq(step.choices[0]["index"], DialogueRunner.CONTINUE)
	assert_eq(step.choices[0]["text"], "Continue")
	r.choose(DialogueRunner.CONTINUE)
	assert_eq(r.next(state).node_id, "b")


func test_lines_follow_the_language() -> void:
	TranslationServer.set_locale("tr")
	var step: DialogueRunner.Step = runner.start(state)
	assert_eq(step.lines[0]["text"], "Trybuna Ludu, lütfen.")
	assert_eq(step.choices[1]["text"], "Bitti, kusura bakmayın.")
