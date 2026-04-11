# Testing

NascentSoul ships with a headless regression runner in:

- [`scenes/tests/regression_runner.tscn`](../scenes/tests/regression_runner.tscn)

Run it with:

```bash
godot --headless --path . scenes/tests/regression_runner.tscn
```

## Current Validation Baseline

Validated on Godot 4.6.1:

- full regression runner passes with `576` checks
- headless editor load succeeds with the plugin enabled
- launcher regression coverage now focuses on the two public showcase entry points

## What The Suite Covers

- core zone contracts
- core transfer contracts
- core runtime resilience and cleanup
- card-zone interaction
- battlefield behavior
- layout visual contracts
- targeting flows and targeting visuals
- performance smoke checks
- two-entry launcher and showcase-shell navigation coverage
- FreeCell showcase rules and helper contracts
- Xiangqi showcase rules

## Contract vs. Implementation Coverage

When adding tests:

1. prefer **contract coverage** for public behavior on `Zone`, `ZoneConfig`, commands, signals, presets, and showcase flows
2. add **implementation-support coverage** only when an internal helper split needs direct protection

That keeps refactors free to move internal code around while still protecting the public learning surface.

## Showcase Suites

The new showcase-specific suites live at:

- [`scenes/tests/suites/freecell_showcase_suite.gd`](../scenes/tests/suites/freecell_showcase_suite.gd)
- [`scenes/tests/suites/xiangqi_showcase_suite.gd`](../scenes/tests/suites/xiangqi_showcase_suite.gd)

They are intended to protect the examples as first-class reference implementations, not as disposable demos.

## Launcher Suite

The launcher-facing suite now lives at:

- [`scenes/tests/suites/demo_smoke_suite.gd`](../scenes/tests/suites/demo_smoke_suite.gd)

It checks the two-entry main menu plus the compatibility shell that swaps between `FreeCell` and `Xiangqi`.

## Core Contract Suites

The addon-core contract coverage now splits into:

- [`scenes/tests/suites/core_state_suite.gd`](../scenes/tests/suites/core_state_suite.gd) for zone/config/runtime-port surface
- [`scenes/tests/suites/core_transfer_suite.gd`](../scenes/tests/suites/core_transfer_suite.gd) for transfer behavior, signal chains, and drag-finalize flow
- [`scenes/tests/suites/core_runtime_resilience_suite.gd`](../scenes/tests/suites/core_runtime_resilience_suite.gd) for rejection cleanup, drag visuals, reconciliation, and resilience cases

That keeps the core regression output closer to the way a maintainer reads the addon surface: first the facade, then transfer behavior, then failure and cleanup guarantees.

## Useful Commands

Run the headless editor load:

```bash
godot --headless --editor --quit --path .
```

Open the project in the editor and run the public launcher:

```bash
godot --path .
```

Use [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) as the first screen. [`scenes/demo.tscn`](../scenes/demo.tscn) is now only a compatibility shell for directly opening `FreeCell` and `Xiangqi` together.

## Updating The Baseline

If you add new public behavior or a new showcase, extend the regression runner in the same change. The library and the examples are expected to stay in lockstep.
