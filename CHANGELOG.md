# Changelog

## 1.0.0 - 2026-04-10

NascentSoul 1.0.0 formalizes the current public architecture of the plugin: `Zone` is a UI-native `Control`, `ZoneConfig` is the inspector-facing composition resource, runtime state is owned by typed services plus `ZoneStore`, and arrow-driven targeting is part of the addon itself.

### Highlights

- Replaced the old preset/runtime split with `ZoneConfig`, `ZoneStore`, `ZoneInputService`, `ZoneRenderService`, `ZoneTransferService`, and `ZoneTargetingService`.
- Added `ZoneItemControl` as the managed item base class, with `ZoneCard` and `ZonePiece` migrated onto the shared item contract.
- Unified card rows, battlefield grids, transfer policies, piece spawning, and targeting under one `ZonePlacementTarget`-based protocol.
- Added layered targeting visuals, including `ZoneLayeredTargetingStyle`, `ZoneTargetingVisualLayer`, `ZoneTargetingOverlayHost`, and the built-in `Classic Arrow`, `Arcane Bolt`, `Strike Vector`, and `Tactical Beam` presets.
- Kept demo scenes and regression coverage aligned with the new API, config model, and signal flow.
- Finalized the public node surface around `add_item`, `remove_item`, `perform_transfer`, and `begin_targeting`, while moving service/coordinator access back behind internal boundaries.

### Validation

- Headless regression suite passes on Godot 4.6.1 with `423` checks.
- Headless editor/plugin load passes without parse errors or preload failures.
- Transfer, battlefield, layout, and targeting suites remain green after the 1.0.0 API and signal-boundary cleanup.
