# Showcase: FreeCell

The FreeCell showcase is a full playable solitaire example built on top of card zones.

Primary files:

- [`scenes/examples/freecell.tscn`](../scenes/examples/freecell.tscn)
- [`scenes/examples/freecell.gd`](../scenes/examples/freecell.gd)
- [`scenes/examples/freecell/freecell_zone_registry.gd`](../scenes/examples/freecell/freecell_zone_registry.gd)
- [`scenes/examples/freecell/freecell_state_model.gd`](../scenes/examples/freecell/freecell_state_model.gd)
- [`scenes/examples/freecell/freecell_move_rules.gd`](../scenes/examples/freecell/freecell_move_rules.gd)
- [`scenes/examples/freecell/freecell_history.gd`](../scenes/examples/freecell/freecell_history.gd)
- [`scenes/examples/freecell/freecell_card.gd`](../scenes/examples/freecell/freecell_card.gd)
- [`scenes/examples/freecell/freecell_tableau_layout.gd`](../scenes/examples/freecell/freecell_tableau_layout.gd)
- [`scenes/examples/freecell/freecell_zone_policy.gd`](../scenes/examples/freecell/freecell_zone_policy.gd)

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

The scene now authors the actual `Zone` nodes and shared `ZoneConfig` resources directly in `freecell.tscn`.

The controller no longer constructs lane zones in code. Instead it coordinates a few focused helpers:

- `freecell_zone_registry.gd` owns scene zone discovery, role/index metadata, and policy binding
- `freecell_state_model.gd` owns serialized state shape, normalization, and restore plans
- `freecell_move_rules.gd` owns transfer validation, drag-start expansion, carry-capacity checks, and foundation legality
- `freecell_history.gd` owns snapshot dedupe, undo checkpoints, and restore orchestration state

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
