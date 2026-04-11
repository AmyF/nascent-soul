# Showcase: FreeCell

FreeCell is the repository's full **card-game reference implementation**.

It is a playable solitaire example built on top of `CardZone`, example-side move rules, history, and scene-authored lane setup.

## Primary Files

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
- seeded setup, undo history, and restore flow

## Zone Breakdown

The scene contains:

- 8 tableau zones
- 4 free cells
- 4 suit foundations

Those `Zone` nodes and shared `ZoneConfig` resources are authored directly in `showcase.tscn`.

## Reference Decomposition Pattern

FreeCell is the reference pattern for a rules-heavy card game in this repository:

1. **scene wiring** stays in `showcase.tscn`
2. **zone discovery + role metadata** live in `ui/freecell_zone_registry.gd`
3. **serialized game state** lives in `state/freecell_state_model.gd`
4. **move legality** lives in `rules/freecell_move_rules.gd`
5. **undo / restore history** lives in `state/freecell_history.gd`
6. **UI/status orchestration** stays in `showcase.gd`

That split keeps the public addon API visible while moving game-specific rules and history into small example-side helpers.

## Rule Coverage

The showcase implements:

- shuffled one-deck deals
- tableau moves with descending alternating-color rules
- free-cell occupancy rules
- foundation building by suit from Ace to King
- multi-card tableau moves constrained by open free cells and empty tableau columns
- replayable seeded deals
- manual foundation moves for exposed legal cards, including shortcut input
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
- undo / restore meaning

That is the intended boundary.

## Regression Coverage

FreeCell is covered by multiple focused suites:

- [`scenes/tests/suites/freecell_showcase_suite.gd`](../scenes/tests/suites/freecell_showcase_suite.gd)
- [`scenes/tests/suites/freecell_history_suite.gd`](../scenes/tests/suites/freecell_history_suite.gd)
- [`scenes/tests/suites/freecell_interaction_suite.gd`](../scenes/tests/suites/freecell_interaction_suite.gd)

Together they protect:

- initial deal counts
- legal tableau, free-cell, and foundation moves
- transfer-surface rule evaluation
- history snapshot dedupe and undo-state restoration
- illegal move rejection
- multi-card carry-capacity limits
- compact-layout and interaction behavior
- victory detection
