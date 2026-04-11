# Testing

NascentSoul ships with a headless regression runner:

- [`scenes/tests/regression_runner.tscn`](../scenes/tests/regression_runner.tscn)

Run it with:

```bash
godot --headless --path . scenes/tests/regression_runner.tscn
```

## Current Validation Baseline

Validated on Godot 4.6.1:

- full regression runner passes with **648 checks**
- headless editor load succeeds with the plugin enabled
- the public launcher path is `Workflow Board` -> `FreeCell` -> `Xiangqi`

Run the editor-load check with:

```bash
godot --headless --editor --quit --path .
```

## What The Suite Covers

- core zone contracts
- core transfer contracts
- core runtime resilience, cleanup, and targeting edge cases
- battlefield behavior
- interaction smoke behavior
- layout visual contracts
- performance smoke checks
- three-entry launcher navigation
- Workflow Board starter contracts
- FreeCell rules, history, and interaction contracts
- Xiangqi rules and board-surface contracts

## Contract Coverage vs. Implementation Coverage

When adding tests:

1. prefer **contract coverage** for public behavior on `Zone`, `ZoneConfig`, commands, signals, presets, and showcase flows
2. add **implementation-support coverage** only when an internal helper split needs focused protection

That split keeps internal refactors free to move code around while still protecting the public learning surface.

## Suite Layout

### Core contract suites

- [`scenes/tests/suites/core_state_suite.gd`](../scenes/tests/suites/core_state_suite.gd) — zone/config/runtime-port surface
- [`scenes/tests/suites/core_transfer_suite.gd`](../scenes/tests/suites/core_transfer_suite.gd) — transfer behavior, routing, and signal chains
- [`scenes/tests/suites/core_runtime_resilience_suite.gd`](../scenes/tests/suites/core_runtime_resilience_suite.gd) — cleanup, drag visuals, targeting edge cases, and resilience paths

### Showcase suites

- [`scenes/tests/suites/workflow_board_showcase_suite.gd`](../scenes/tests/suites/workflow_board_showcase_suite.gd)
- [`scenes/tests/suites/freecell_showcase_suite.gd`](../scenes/tests/suites/freecell_showcase_suite.gd)
- [`scenes/tests/suites/freecell_history_suite.gd`](../scenes/tests/suites/freecell_history_suite.gd)
- [`scenes/tests/suites/freecell_interaction_suite.gd`](../scenes/tests/suites/freecell_interaction_suite.gd)
- [`scenes/tests/suites/xiangqi_showcase_suite.gd`](../scenes/tests/suites/xiangqi_showcase_suite.gd)

### Launcher + smoke suites

- [`scenes/tests/suites/demo_smoke_suite.gd`](../scenes/tests/suites/demo_smoke_suite.gd)
- [`scenes/tests/suites/battlefield_smoke_suite.gd`](../scenes/tests/suites/battlefield_smoke_suite.gd)
- [`scenes/tests/suites/interaction_smoke_suite.gd`](../scenes/tests/suites/interaction_smoke_suite.gd)
- [`scenes/tests/suites/layout_visual_contract_suite.gd`](../scenes/tests/suites/layout_visual_contract_suite.gd)
- [`scenes/tests/suites/performance_smoke_suite.gd`](../scenes/tests/suites/performance_smoke_suite.gd)
- [`scenes/tests/suites/targeting_smoke_suite.gd`](../scenes/tests/suites/targeting_smoke_suite.gd)
- [`scenes/tests/suites/targeting_visual_framework_suite.gd`](../scenes/tests/suites/targeting_visual_framework_suite.gd)

## What The Showcase Suites Protect

### Workflow Board

Protects the starter onboarding path:

- seeded lane counts and sample cards
- starter copy
- WIP-limit rejection behavior
- reset behavior
- scrollable lane-body structure

### FreeCell

Protects the card-game reference path:

- initial deal counts
- legal and illegal lane moves
- carry-capacity limits
- history snapshot dedupe
- undo restoration
- compact-layout interaction behavior
- victory detection

### Xiangqi

Protects the battlefield reference path:

- initial setup and side-to-move state
- piece-family movement rules
- capture and turn updates
- facing-generals prevention
- checkmate and no-legal-move end states
- board surface and visible status chrome

## Useful Commands

Run the public launcher in the editor:

```bash
godot --path .
```

Use [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) as the first screen.

[`scenes/demo.tscn`](../scenes/demo.tscn) remains only a compatibility shell for directly opening `FreeCell` and `Xiangqi` together.

## Updating The Baseline

If you add new public behavior or a new showcase:

1. extend the regression runner in the same change
2. update the relevant docs in the same change
3. refresh the documented baseline after rerunning validation

The library, the examples, and the docs are expected to stay in lockstep.
