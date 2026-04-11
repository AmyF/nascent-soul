# Showcase: FreeCell

The FreeCell showcase is a full playable solitaire example built on top of card zones.

Primary files:

- [`scenes/showcases/freecell/showcase.tscn`](../scenes/showcases/freecell/showcase.tscn)
- [`scenes/showcases/freecell/showcase.gd`](../scenes/showcases/freecell/showcase.gd)
- [`scenes/showcases/freecell/ui/freecell_zone_registry.gd`](../scenes/showcases/freecell/ui/freecell_zone_registry.gd)
- [`scenes/showcases/freecell/state/freecell_state_model.gd`](../scenes/showcases/freecell/state/freecell_state_model.gd)
- [`scenes/showcases/freecell/rules/freecell_move_rules.gd`](../scenes/showcases/freecell/rules/freecell_move_rules.gd)
- [`scenes/showcases/freecell/state/freecell_history.gd`](../scenes/showcases/freecell/state/freecell_history.gd)
- [`scenes/showcases/freecell/cards/freecell_card.gd`](../scenes/showcases/freecell/cards/freecell_card.gd)
- [`scenes/showcases/freecell/ui/freecell_tableau_layout.gd`](../scenes/showcases/freecell/ui/freecell_tableau_layout.gd)
- [`scenes/showcases/freecell/rules/freecell_zone_policy.gd`](../scenes/showcases/freecell/rules/freecell_zone_policy.gd)
- [`scenes/showcases/shared/ui/showcase_zone_lane_view.gd`](../scenes/showcases/shared/ui/showcase_zone_lane_view.gd)
- [`scenes/showcases/shared/ui/showcase_number_prompt.tscn`](../scenes/showcases/shared/ui/showcase_number_prompt.tscn)

## What It Demonstrates

- multiple card-zone families in one scene
- example-side transfer policy delegation
- a custom tableau layout built outside the addon
- multi-card movement with carry-capacity checks
- legal move validation without changing the core addon API

## Zone Breakdown

- 8 tableau zones
- 4 free cells
- 4 suit foundations

The scene now authors the actual `Zone` nodes and shared `ZoneConfig` resources directly in `showcase.tscn`.

The controller no longer constructs lane zones in code. Instead it coordinates a few focused helpers:

- `ui/freecell_zone_registry.gd` owns scene zone discovery, role/index metadata, and policy binding
- `state/freecell_state_model.gd` owns serialized state shape, normalization, and restore plans
- `rules/freecell_move_rules.gd` owns transfer validation, drag-start expansion, carry-capacity checks, and foundation legality
- `state/freecell_history.gd` owns snapshot dedupe, undo checkpoints, and restore orchestration state
- `shared/ui/showcase_zone_lane_view.gd` carries the Inspector-authored lane metadata that keeps the scene readable without string-based discovery
- `shared/ui/showcase_number_prompt.tscn` provides the reusable numeric prompt widget used for the Select Game dialog

## Showcase Pattern

FreeCell is the reference card-game decomposition in this repository:

1. **scene wiring** stays in `showcase.tscn`
2. **zone discovery + role metadata** live in `ui/freecell_zone_registry.gd`
3. **serialized game state** lives in `state/freecell_state_model.gd`
4. **move legality** lives in `rules/freecell_move_rules.gd`
5. **undo / restore history** lives in `state/freecell_history.gd`
6. **UI/status orchestration** stays in `showcase.gd`

That split keeps the public addon API visible while moving game-specific rules and history into small example-side helpers.

## Rule Coverage

The showcase as a whole implements:

- shuffled one-deck deals
- tableau moves with descending alternating color rules
- free-cell occupancy rules
- foundation building by suit from Ace to King
- multi-card tableau moves constrained by open free cells and empty tableau columns
- replayable seeded deals
- manual foundation moves for exposed legal cards, including double-click / right-click shortcuts
- solved-state detection

## Why It Matters For The Library

FreeCell proves that NascentSoul's card-zone runtime can support a complete rules-driven solitaire game without needing showcase-specific engine hooks.

The addon supplies:

- zone management
- selection
- drag/drop
- transfer plumbing
- layout and visuals

The example supplies:

- rule evaluation
- seeded setup
- game state messaging

That is the intended boundary.

## Regression Coverage

The FreeCell suite validates:

- initial deal counts
- legal tableau, free-cell, and foundation moves
- direct transfer-surface rule evaluation
- history snapshot dedupe and undo-state restoration
- illegal move rejection
- multi-card carry-capacity limits
- victory detection
