# KIOSK '81 development context

Read `docs/RATION_FPS_MASTER_PROMPT.md` for the current standalone task and
`docs/RATION_DESK_DESIGN.md` for the interaction/state contract. The latest
scope is ONLY customer handoff → physical card/table → evidence comparison →
cutting/stamping → return or retain the card. Do not expand the room, provisions,
hauling, stock accounting or economy while this interaction is being refined.

The main scene is `scenes/kiosk/ration_desk_focus.tscn`, using the shared
`fps_kiosk.gd` with `document_focus = true`. That mode completes paperwork
without gathering goods, spending stock or taking payment. The older full-sale
`fps_kiosk.tscn` remains a separate scene; do not silently reintroduce its goods
requirements into the focused task. Accepted future ideas are in the master
prompt, not current completion requirements.

The game is 3D with first-person approach/handheld inspection. The latest desk
interaction explicitly permits the SAME Camera3D to move above the physical
desk: visible cursor, right-drag pan, wheel zoom, then Q/WASD return to walking.
An old prohibition on moving the eye camera no longer describes this mode.
Focus handoff now takes the same card into the hand with one click/E. F opens
held-object inspection: LMB drag rotates, wheel zooms, RMB flips, R resets,
F/Esc/Q/WASD exits. E/G on the desk places the card with a physical footprint
preview and automatically enters overhead; broad tabletop click/E reopens it.
On the table F still flips the paper. Empty-hand LMB lifts/drags paper; RMB
while dragging rotates in place. ScissorStroke advances the blade only during its closing phase.
Documents and tools remain world objects. Do not revive the rejected 2D
dashboard; a Control/SubViewport may supply ink or optical rendering only.

Use Godot 4.7.2 standard and typed GDScript. The pinned cloud binary is
`/workspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`; the system
`godot` may be older. Use existing checkouts; no new Git worktree unless asked.
Preserve other contributors' changes and share ownership before concurrent edits.

Game owns CampaignState. Rules return effects; views do not directly mutate
campaign state. Fictional Polish class/quota/seal rules are game design, not
historical regulations. Occupation and paper wear do not establish guilt.
Physical references and a loupe should help inspect evidence without revealing
an authenticity answer through colors, labels or a success sound.

Partial cutting is NOW persistent physical damage: a 2 cm incision stays 2 cm
long after release/Q, flipping and returning to the desk. Do not restore the old
short-cut-heals behavior. A partial cut does not consume the entire coupon;
detachment requires its boundary to be severed. Preserve incisions, holes,
detached pieces and entitlement idempotence separately.
Stamp ink depends on contact speed, dwell, pressure/angle and smudge. It must
remain attached to the sheet. Abort before contact leaves no mark; after contact
preserves the mark. Synchronize ink/sounds with physical contact, once per event.

Validation from the repository root (commands, not a claim that they passed):

- `godot --headless --path . res://tests/run_tests.tscn -- --ci`
- `godot --headless --path . res://scenes/kiosk/ration_desk_focus.tscn -- --selftest`
- Run that focus selftest with a graphical display for mouse/optics/layout work.
  Tools must be inside the viewport; offscreen cursor overrides do not prove
  that a real player can pick them up. Include pan/zoom and restored camera/FOV.
- If changing shared full-sale paths, also check
  `godot --headless --path . res://scenes/kiosk/fps_kiosk.tscn -- --selftest`.

Current evidence belongs in `docs/RATION_FPS_ACCEPTANCE.md`; do not copy an old
test count as proof of new work. Procedural models/foley are prototypes, not
finished AAA art or verified listening quality.
Don't casually run `tools/setup_project.gd` or whole scene generators; they
overwrite scenes. Fetch Git LFS assets before importing a fresh checkout.

Current sequential feature list: `docs/CARD_INTERACTION_BACKLOG.md`. The original
user list is preserved there; the first five slices now include physical identity,
printed evidence, controlled cutting and manual coupon collection.
`HeldObjectInspector` works on the existing held card/tool and
restores its exact pose on exit. Don't append marks/cuts during inspection.
`StampPlacementGuide` is a transient mesh on the paper, outside the ink renderer
and campaign state. Stamp preview and actual ink use the same paper-local angle.
A physical stamp outside the decision field leaves ink without changing the
logical decision; an invalid position outside paper is rejected. Forward+ has
inspection depth of field; Compatibility does not. Check both first-person
cancellation and existing physical damage after these changes.

Paper inspection update: `docs/PAPER_INSPECTION_UPDATE.md`. `PaperStockProfile`
resolves only serial/paper_stock/worn/paper_wear, never occupation or guilt.
Three actual full thicknesses are 0.14/0.28/0.48 mm; faces sit at +/-half, edge
shaders scale their base thickness. Do not scale edges twice. Print hit planes
follow the visible face. Coupons keep canonical sheet_uv_rect, original stamp
ink, their own incision texture snapshot and stock; new customers cannot alter
old fragments. T in held F inspection enables directional simulated transmitted
light. It changes rendering only, never campaign/evidence or a verdict. Close,
focus loss and restart clear it. The physical book's underside teaches comparison;
existing inspector Ry(PI)*Rx(PI/2) must show it upright. No fullscreen hint panel.

Evidence review update: `docs/EVIDENCE_REVIEW_UPDATE.md`. F5 runs original8 +
review8; the Esc comparison-day button or ration_review_day.tscn starts review8.
The full-sale scene still uses original8 only. Companion identity is one physical
two-sided object; after E receive it settles on the desk. E picks it up, Q leaves
overhead, F inspects. With both documents held, C changes the inspector target,
restoring both exact poses and clearing card-only transmission lighting.
Tab during F book inspection changes only the static printed underside guide;
it never reads the current encounter. RationEvidence derives findings from
the same date/seal/identity/coupon fields that are printed. Portrait keys share
one canonicalization function with DocumentPortrait. Cosmetic wear, ink, paste,
stock and repeated matching date typing never establish guilt. Prior issuance
of a requested coupon means reject, not confiscate. Wrong decisions remain
possible and are audited after handback; no evidence renderer writes verdicts.

Controlled cutting update: `docs/COUPON_CUTTING_UPDATE.md`. FPS uses
ScissorCutController around the unchanged ScissorStroke; a sharp turn reopens
and rotates without cutting or moving the tip. Shift slows physical progression,
not canonical distance. ScissorCutGuide is transient, treats all remaining
coupons equally and never snaps paths or writes ink/evidence. Clear it on exit.

CouponFragment3D is the original detached print/stock/damage snapshot. In focus
it settles on real support, is picked up with E/click, inspected with Q then F,
and dropped with G. Only E/G at the physical coupon_bin starts filing; commit
rules.file_coupon at tray contact, once. opening(document_focus) enables the
focus collection requirement; approval needs the requested coupon in collected.
Legacy full-sale keeps its automatic tray transfer and old completion contract.
Do not mix cut damage, entitlement processing and collection. Old-case loose
pieces may be archived visually but never credited to the new case: check both
source_card_id and source_serial. Restart must kill transfer callbacks; only
archived fragments have selection disabled. Whole-world save reconstruction is
still outside this prototype; work.collected round-trips through CampaignState.

HeldObjectInspector now guards actual rotated half-extents against camera.near
plus 15 mm, including intermediate flip poses. Preserve initial fit framing,
real close zoom for small coupons and exact cancellation transforms. A fixed
radius-distance assertion can hide a broken zoom; test actual corner clearance.
