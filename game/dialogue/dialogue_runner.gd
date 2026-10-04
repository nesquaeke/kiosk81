class_name DialogueRunner
extends RefCounted
## Walks one dialogue record (format: docs/adr/ADR-001-dialogue-format.md).
## The runner never changes the campaign state. Each step hands back the
## effects to apply; the caller applies them through Game.apply_effects and
## then asks for the next step with the new state.
##   var step := runner.start(Game.state)        # apply step.effects
##   var fx := runner.choose(step.choices[0].index)  # apply fx
##   step = runner.next(Game.state)              # null when the dialogue is over
## A node's line and choice conditions see the state before that node's own effects.

const CONTINUE: int = -1  # choice index for nodes that only "goto" onward

class Step:
	extends RefCounted
	var node_id: String = ""
	## {"speaker": String, "key": String, "text": String}
	var lines: Array[Dictionary] = []
	## {"index": int, "key": String, "text": String}; empty when the node ends the dialogue.
	var choices: Array[Dictionary] = []
	## Effects of entering this node.
	var effects: Array[Dictionary] = []
	## True when the dialogue ends after these lines.
	var finished: bool = false


var record: Dictionary
var error: String = ""
var _node_id: String = ""
var _pending: String = ""
var _offered: Array[int] = []
var _over: bool = false


func _init(dialogue_record: Dictionary) -> void:
	record = dialogue_record


func dialogue_id() -> String:
	return str(record.get("id", ""))


func is_over() -> bool:
	return _over


func start(state: CampaignState) -> Step:
	_over = false
	return _enter(state, str(record["start"]))


## Picks one of the choices offered by the last step. Returns the choice's effects.
## An index that was not offered is refused: error is set and nothing moves.
func choose(index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	error = ""
	if _over or not index in _offered:
		error = "choice %d is not on offer" % index
		return out
	var node: Dictionary = (record["nodes"] as Dictionary)[_node_id]
	if index == CONTINUE:
		_pending = str(node["goto"])
		return out
	var choice: Dictionary = (node["choices"] as Array)[index]
	for effect: Dictionary in choice.get("effects", []):
		out.append(effect.duplicate(true))
	if choice.get("end", false) == true:
		_pending = ""
		_over = true
	else:
		_pending = str(choice["goto"])
	return out


## Shows the current node again for a changed state (stock refilled, language
## switched). Its effects are NOT returned again: they were applied on entry.
func refresh(state: CampaignState) -> Step:
	var step: Step = _enter(state, _node_id)
	step.effects.clear()
	return step


## Enters the node chosen last; null when the dialogue is over.
func next(state: CampaignState) -> Step:
	if _over or _pending == "":
		_over = true
		return null
	var target: String = _pending
	_pending = ""
	return _enter(state, target)


func _enter(state: CampaignState, node_id: String) -> Step:
	_node_id = node_id
	_offered.clear()
	var node: Dictionary = (record["nodes"] as Dictionary)[node_id]
	var step: Step = Step.new()
	step.node_id = node_id
	var id: String = dialogue_id()
	var lines: Array = node.get("lines", [])
	for i: int in lines.size():
		var line: Dictionary = lines[i]
		if line.has("if") and not Conditions.is_true(state, line["if"]):
			continue
		var key: String = Loc.line_key(id, node_id, i)
		step.lines.append({"speaker": line["speaker"], "key": key, "text": Loc.text(key, line["text"])})
	for effect: Dictionary in node.get("effects", []):
		step.effects.append(effect.duplicate(true))
	if node.get("end", false) == true:
		step.finished = true
		_over = true
	elif node.has("goto"):
		_offered.append(CONTINUE)
		step.choices.append({"index": CONTINUE, "key": "ui.dialogue.continue", "text": Loc.ui("ui.dialogue.continue")})
	else:
		var choices: Array = node.get("choices", [])
		for i: int in choices.size():
			var choice: Dictionary = choices[i]
			if choice.has("if") and not Conditions.is_true(state, choice["if"]):
				continue
			var key: String = Loc.choice_key(id, node_id, i)
			_offered.append(i)
			step.choices.append({"index": i, "key": key, "text": Loc.text(key, choice["text"])})
		if step.choices.is_empty():
			# Content bug: every choice is hidden. End instead of trapping the player.
			push_warning("[dialogue] %s.%s: no choice is available" % [id, node_id])
			step.finished = true
			_over = true
	return step
