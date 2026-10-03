extends Node
## Game (autoload): owns the CampaignState, the single source of truth.
## Every change goes through apply_effects(): all effects apply or none.
## Scenes never write to the state; they listen to state_changed.

signal state_changed(state: CampaignState)
signal effects_rejected(reason: String)

var state: CampaignState = CampaignState.new()


func new_campaign(campaign_seed: int) -> void:
	state = CampaignState.new()
	state.rng_seed = campaign_seed
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
