# Testing

NascentSoul ships with a headless regression runner in:

- [`scenes/tests/regression_runner.tscn`](../scenes/tests/regression_runner.tscn)

Run it with:

```bash
godot --headless --path . scenes/tests/regression_runner.tscn
```

## Current Validation Baseline

Validated on Godot 4.6.1:

- full regression runner passes with `1714` checks
- headless editor load succeeds with the plugin enabled
- demo regression coverage now splits into scene contracts, launcher flow, and example-story suites

## What The Suite Covers

- core zone state
- card-zone interaction
- battlefield behavior
- layout visual contracts
- targeting flows and targeting visuals
- performance smoke checks
- demo scene contracts and serialized authoring checks
- launcher and compatibility-shell navigation coverage
- demo example behavior stories
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

## Demo Story Suites

The demo-facing suites now split by concern:

- [`scenes/tests/suites/demo_scene_contract_suite.gd`](../scenes/tests/suites/demo_scene_contract_suite.gd) checks serialized authoring, naming, and static scene contracts
- [`scenes/tests/suites/demo_smoke_suite.gd`](../scenes/tests/suites/demo_smoke_suite.gd) checks launcher and compatibility-shell navigation
- [`scenes/tests/suites/demo_examples_suite.gd`](../scenes/tests/suites/demo_examples_suite.gd) checks example behavior stories and showcase loading

That split keeps the regression runner output closer to the way a learner reads the project.

## Useful Commands

Run the headless editor load:

```bash
godot --headless --editor --quit --path .
```

Open the project in the editor and run the public launcher:

```bash
godot --path .
```

Use [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) as the first screen. [`scenes/demo.tscn`](../scenes/demo.tscn) is now only a compatibility shell for directly opening the eight editor-facing demos together.

## Updating The Baseline

If you add new public behavior or a new showcase, extend the regression runner in the same change. The library and the examples are expected to stay in lockstep.
