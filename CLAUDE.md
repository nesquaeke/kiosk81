> FPS task and acceptance criteria: [RATION_FPS_MASTER_PROMPT.md](docs/RATION_FPS_MASTER_PROMPT.md).
> Read it with the implementation design; paperwork precedes collecting goods.

# Shared project context

Read `AGENTS.md`, `README.md` and `docs/RATION_DESK_DESIGN.md` before continuing
the ration-card mechanic. The user chose this as the main interaction and
explicitly permits fictional class cards, quotas and rules. Preserve the
physical paper / scissors / stamp feel and its sound contacts.

The 2D desk prototype was rejected. Implement every interaction in 3D from the
character's first-person camera, using hands, world surfaces and physical
tools. Do not revive the old desk dashboard. The current entry scene is
`scenes/kiosk/fps_kiosk.tscn`; the design document records this correction.

`docs/KIOSK_SIMULATOR_MASTER_PROMPT.md` records the product-handling prototype.
Use the same shared task scope and file ownership with Codex and the human
contributor. Keep the design document current; distinguish implemented features
from the roadmap. There is no requirement to ask permission for ordinary fixes
or reversible implementation work already requested by the user.
