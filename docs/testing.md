# Testing

NascentSoul ships with a headless regression runner in:

- [`scenes/tests/regression_runner.tscn`](../scenes/tests/regression_runner.tscn)

Run it with:

```bash
godot --headless --path . scenes/tests/regression_runner.tscn
```

## Current Validation Baseline

Validated on Godot 4.6.1:

- full regression runner passes with `697` checks
- headless editor load succeeds with the plugin enabled
- demo smoke covers the main-menu launcher, the compatibility shell, and both showcase scenes

## What The Suite Covers

- core zone state
- card-zone interaction
- battlefield behavior
- layout visual contracts
- targeting flows and targeting visuals
- performance smoke checks
- launcher and compatibility-shell smoke coverage
- FreeCell showcase rules
- Xiangqi showcase rules

## Showcase Suites

The new showcase-specific suites live at:

- [`scenes/tests/suites/freecell_showcase_suite.gd`](../scenes/tests/suites/freecell_showcase_suite.gd)
- [`scenes/tests/suites/xiangqi_showcase_suite.gd`](../scenes/tests/suites/xiangqi_showcase_suite.gd)

They are intended to protect the examples as first-class reference implementations, not as disposable demos.

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
