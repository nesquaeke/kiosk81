# KIOSK '81 development context

The user chose the ration-card interaction as the main game mechanic. Read
`docs/RATION_DESK_DESIGN.md` before changing card rules or desk interactions.
Its class categories, entitlements and seals are intentionally fictional game
design; do not impose historical-simulation requirements the user has rejected.
`docs/KIOSK_SIMULATOR_MASTER_PROMPT.md` documents the earlier physical-product
slice. README records implemented features and limitations.

Use Godot 4.7.2 standard and typed GDScript. In this cloud workspace the pinned
binary is `/workspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`;
the system `godot` binary may be older. Use existing checkouts; do not create a
Git worktree unless the user requests one.

Game owns CampaignState. Rules return effects; views do not mutate campaign
state. Preserve card cuts, marks, amounts and transaction idempotence. Sound
and animation contacts must stay synchronized. Fictional UI paperwork must
not expose the answer to the inspection before the player decides.

Validation from the repository root:

- `godot --headless --path . res://tests/run_tests.tscn -- --ci`
- `godot --headless --path . res://scenes/kiosk/ration_desk.tscn -- --selftest`
- Run the desk selftest with a graphical display when changing mouse/drag,
  rotation, scale, layout or animations. Headless checks alone missed a real
  pointer-coordinate issue previously.

Don't run `tools/setup_project.gd` or the whole scene generator casually; they
rewrite existing project files/scenes. Dedicated product and audio generators
are documented in README. Fetch Git LFS assets before importing a new checkout.
Update the design document when agreed mechanics or scope change; report
implemented and planned features separately. Share file ownership with other
contributors before concurrent edits to the same files.
