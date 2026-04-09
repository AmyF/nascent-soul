# Changelog

## 2.1.0 - 2026-04-09

NascentSoul 2.1.0 adds a dedicated targeting system on top of the 2.0 card/battlefield runtime. Drag/drop transfer is still responsible for moving objects between zones, but zones and items can now also enter a separate arrow-driven targeting flow for spell cards, abilities, and cell picking.

### Highlights

- Added `ZoneTargetingIntent`, `ZoneTargetCandidate`, `ZoneTargetRequest`, `ZoneTargetDecision`, and `ZoneTargetingSession`.
- Added `ZoneTargetingPolicy`, `ZoneTargetAllowAllPolicy`, `ZoneTargetCompositePolicy`, and `ZoneTargetRuleTablePolicy`.
- Added `ZoneTargetingStyle`, `ZoneArrowTargetingStyle`, `ZoneArrowTargetingOverlay`, and `ZoneTargetingCoordinator` for dynamic arrow/ring targeting visuals.
- Added target anchors on `ZoneSpaceModel`, plus default target highlight behavior on `ZoneCard` and `ZonePiece`.
- Added `begin_targeting()`, targeting signals, and drag-threshold intent branching on `Zone`.
- Added `scenes/examples/targeting_lab.tscn` to demonstrate drag-to-target spells and explicit piece ability targeting.
- Added targeting smoke coverage for drag entry, explicit entry, candidate resolution, policy merge behavior, overlay state transitions, and cleanup.

### Validation

- Headless regression suite passes on Godot 4.6.1 with 383 checks.
- Existing transfer, battlefield, and layout suites remain green after introducing the targeting coordinator.

## 2.0.0 - 2026-04-09

NascentSoul 2.0.0 expands the library from a card-zone toolkit into a unified card and battlefield zone system. The runtime still centers on `Zone`, but drop resolution now flows through `ZonePlacementTarget`, `ZoneTransferRequest`, `ZoneTransferDecision`, and pluggable `ZoneSpaceModel` resources so linear card containers and square/hex battlefields can share one drag/drop core.

### Highlights

- Added `CardZone` and `BattlefieldZone` as first-class families on top of the shared `Zone` core.
- Replaced index-only drop semantics with `ZonePlacementTarget`, covering linear slots, square cells, and hex cells.
- Added `ZoneLinearSpaceModel`, `ZoneSquareGridSpaceModel`, and `ZoneHexGridSpaceModel` to separate spatial hit-testing from visual layout.
- Added `ZoneBattlefieldLayout`, occupancy transfer rules, rule-table transfer rules, and piece spawning support for card-to-battlefield handoff.
- Added `ZonePiece` and `PieceData` so tactical boards ship with an official example piece type alongside `ZoneCard`.
- Expanded the editor plugin with `Create Card Zone`, `Create Square Battlefield Zone`, and `Create Hex Battlefield Zone`.
- Added square battlefield, hex battlefield, and transfer-mode example scenes plus battlefield regression coverage.

### Validation

- Headless regression suite passes on Godot 4.6.1 with 334 checks.
- Existing card-zone demos and regression suites remain green after the protocol migration.
- Battlefield smoke coverage now validates square/hex placement, occupancy rejection, spawn-piece transfers, and same-zone piece movement.

## 1.0.0 - 2026-04-09

NascentSoul 1.0.0 establishes the current public shape of the plugin: `Zone` is now a real `Control`, runtime state is owned by `ZoneRuntime`, and presets/resources are the primary way to compose layout, interaction, sorting, transfer policies, and drag visuals.

### Highlights

- `Zone` now owns `ItemsRoot` and `PreviewRoot`, so zone scenes behave like native Godot UI instead of wrapper-based coordinators.
- Drag/drop behavior is more predictable across reorder, transfer, reject, preview, and animation handoff paths.
- Demo scenes were migrated to inspector-driven configuration and cleaned up as working examples instead of code-heavy setup scripts.
- Documentation was rewritten around value and architecture, with `README.md` as the single top-level entry point.
- The plugin package is now self-contained for clean installs: editor icons and presets ship inside the addon, and the editor plugin only exposes addon-local functionality.

### Validation

- Headless editor plugin load passes on Godot 4.6.1.
- Runtime regression suite passes in the repository project.
- Clean-project install smoke passes by copying only `addons/nascentsoul` into a fresh Godot project and enabling the plugin.
