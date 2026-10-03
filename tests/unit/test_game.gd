extends TestCase
## Game autoload logic, tested on a fresh instance (roadmap 1.6).

const GameScript: GDScript = preload("res://game/core/game.gd")

var changed: int = 0
var rejected: PackedStringArray = []


func _on_changed(_s: CampaignState) -> void:
	changed += 1


func _on_rejected(reason: String) -> void:
	rejected.append(reason)


func test_apply_effects_success_and_failure() -> void:
	var game: Node = GameScript.new()
	game.state_changed.connect(_on_changed)
	game.effects_rejected.connect(_on_rejected)
	game.new_campaign(81)
	assert_eq(changed, 1)
	var good: Array[Dictionary] = [{"op": "money_add", "account": "till", "amount": 100}]
	assert_true(game.apply_effects(good))
	assert_eq(game.state.money["till"], 100)
	var bad: Array[Dictionary] = [{"op": "money_add", "account": "till", "amount": -500}]
	assert_false(game.apply_effects(bad))
	assert_eq(game.state.money["till"], 100, "failed effects change nothing")
	assert_eq(rejected.size(), 1)
	assert_eq(changed, 2)
	game.free()
