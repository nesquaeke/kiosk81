extends Node
## Game (autoload): owns the CampaignState, the single source of truth.
## Every change goes through apply_effects(): all effects apply or none.
## Scenes never write to the state; they listen to state_changed.

signal state_changed(state: CampaignState)
signal effects_rejected(reason: String)

var state: CampaignState = CampaignState.new()


## Starts a campaign. `start` may override any state field (a scenario's
## opening: date, money, stock ...); missing fields keep their defaults.
func new_campaign(campaign_seed: int, start: Dictionary = {}) -> void:
	state = CampaignState.from_dict(start) if not start.is_empty() else CampaignState.new()
	state.rng_seed = campaign_seed
	state_changed.emit(state)


## Replaces the state with a loaded one (SaveManager result).
func load_state(loaded: CampaignState) -> void:
	state = loaded
	state_changed.emit(state)


## Applies the effects atomically. Returns true on success.
func apply_effects(effects: Array[Dictionary]) -> bool:
	var result: EffectPipeline.Result = EffectPipeline.apply(state, effects)
	if not result.ok:
		effects_rejected.emit(result.error)
		return false
	state = result.state
	state_changed.emit(state)
	return true
