class_name Dice
extends RefCounted
## Deterministic chance: the same campaign seed, day and purpose always give the
## same roll, so a loaded save replays exactly and the simulator is repeatable.


## 0.0 <= roll < 1.0
static func roll(state: CampaignState, purpose: String) -> float:
	return _rng(state, purpose).randf()


## lo <= result <= hi
static func range_int(state: CampaignState, purpose: String, lo: int, hi: int) -> int:
	return _rng(state, purpose).randi_range(lo, hi)


## True with the given chance in per-mille (0..1000).
static func chance_permille(state: CampaignState, purpose: String, permille: int) -> bool:
	return roll(state, purpose) * 1000.0 < float(permille)


static func _rng(state: CampaignState, purpose: String) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash([state.rng_seed, state.day, purpose])
	return rng
