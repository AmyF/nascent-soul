# Architecture

This document explains how NascentSoul is structured, which surfaces are meant to be public, and how to read the repo without getting lost in runtime details too early.

NascentSoul has two audiences:

1. **builders** who want to compose card lanes or battlefields with the public API
2. **maintainers** who need to understand or evolve the runtime itself

The most important rule is simple:

> **Learn the public surface first. Read the runtime second.**

## Design Principles

NascentSoul is organized around a few stable principles:

- **one mental model** for ordered lanes and explicit-cell battlefields
- **Inspector-first authoring** whenever a scene can explain itself directly
- **public facade first**: game code should stay on `Zone`, `ZoneConfig`, commands, and signals
- **runtime isolation**: internal helpers should live in `runtime/`, not leak through day-to-day usage
- **examples as reference consumers**: showcases should demonstrate the public surface, not bypass it
- **docs, tests, and examples move together**: structure is part of the product

## System Overview

| Layer | Paths | What it is for |
| --- | --- | --- |
| Public runtime nodes | `addons/nascentsoul/core/` | `Zone`, `CardZone`, `BattlefieldZone`, `ZoneItemControl` |
| Public data + commands | `addons/nascentsoul/model/` | placement targets, commands, requests, decisions, visual-state models |
| Public extension seams | `addons/nascentsoul/resources/` | layouts, policies, spaces, display styles, drag visuals, sorting, interaction |
| Built-in implementations | `addons/nascentsoul/impl/` | stock layouts, spaces, displays, targeting styles, factories, policies |
| Built-in item types | `addons/nascentsoul/cards/`, `addons/nascentsoul/pieces/` | `ZoneCard`, `ZonePiece`, `CardData`, `PieceData` |
| Presets | `addons/nascentsoul/presets/` | ready-to-duplicate `ZoneConfig` resources for common setups |
| Internal runtime | `addons/nascentsoul/runtime/` | service graph, context/state holders, coordinators, cleanup helpers |
| Editor entry points | `addons/nascentsoul/nascentsoul.gd` | plugin registration and editor menu actions |
| Reference consumers | `scenes/showcases/` | examples that teach the public API in real scenes |
| Validation surface | `scenes/tests/` | regression suites that protect the addon's contract and examples |

## Public Surface

These are the parts user code is expected to depend on directly.

### Runtime nodes

- `Zone`
- `CardZone`
- `BattlefieldZone`
- `ZoneItemControl`

Use these when you need a runtime surface that owns items, interaction, selection, transfer, layout refresh, and targeting.

### Data, commands, and public models

Important files include:

- `addons/nascentsoul/model/zone_transfer_command.gd`
- `addons/nascentsoul/model/zone_targeting_command.gd`
- `addons/nascentsoul/model/zone_placement_target.gd`
- `addons/nascentsoul/model/zone_target_candidate.gd`
- `addons/nascentsoul/model/zone_transfer_decision.gd`
- `addons/nascentsoul/model/zone_target_decision.gd`
- `addons/nascentsoul/model/zone_item_visual_state.gd`

These files describe what the runtime is doing without forcing callers to know how the runtime is internally assembled.

### Extension seams

These are the customization points most users should extend:

| If you want to change... | Extend... |
| --- | --- |
| drag/drop legality or resolution | `ZoneTransferPolicy` |
| targeting legality or candidate rewriting | `ZoneTargetingPolicy` |
| item placement in a lane or board | `ZoneLayoutPolicy` |
| target geometry and anchor math | `ZoneSpaceModel` |
| visual application of placements | `ZoneDisplayStyle` |
| drag ghosts and proxies | `ZoneDragVisualFactory` |
| spawned-item behavior | `ZoneItemSpawnFactory` |
| idle reordering | `ZoneSortPolicy` |
| input behavior toggles | `ZoneInteraction` |

Compose these through `ZoneConfig`.

### Built-in item types

- `ZoneCard`
- `ZonePiece`
- `CardData`
- `PieceData`

These are reusable defaults, not the only valid way to build items. Custom item types should still be able to extend `ZoneItemControl` directly.

## Internal Runtime

The `runtime/` directory exists to make the public surface work. It is intentionally **not** the normal extension surface.

### The most important internal files

| File | Responsibility |
| --- | --- |
| `zone_runtime_bootstrap.gd` | Assembles the zone's runtime collaborators |
| `zone_runtime_port.gd` | Gives services a way to emit public signals, request refreshes, and resolve sibling runtime helpers without bloating `Zone` |
| `zone_runtime_hooks.gd` | Exposes internal-only operations needed by coordinators, tests, and example scaffolding without keeping `_runtime_*` APIs on `Zone` |
| `zone_context.gd` | Shared internal view of `zone`, `config`, logical state, display cache, and transfer staging |
| `zone_store.gd` | Logical item / target / selection state |
| `zone_display_state_cache.gd` | Visual tween/cache state |
| `zone_transfer_staging.gd` | Transfer handoffs and transfer snapshots while items move between zones |

### Workflow services

| Workflow | Main facade | Focused helpers |
| --- | --- | --- |
| transfer | `zone_transfer_service.gd` | `zone_transfer_command_router.gd`, `zone_drag_start_flow.gd`, `zone_transfer_decision_resolver.gd`, `zone_transfer_execution.gd`, `zone_drag_session_cleanup.gd` |
| input | `zone_input_service.gd` | `zone_input_binding_registry.gd`, `zone_input_pointer_flow.gd`, `zone_input_selection_controller.gd` |
| targeting | `zone_targeting_service.gd` | `zone_target_resolution.gd`, `zone_target_feedback.gd` |
| render | `zone_render_service.gd` | `zone_drag_preview_feedback.gd` |

The runtime has been deliberately split so maintainers can follow one workflow at a time instead of reading one monolithic service file.

## How One Zone Is Assembled

At runtime, a `Zone` behaves roughly like this:

1. `Zone` ensures its internal roots (`ItemsRoot`, `PreviewRoot`) exist.
2. `ZoneRuntimeBootstrap` assembles or reattaches the internal collaborators:
   - logical store
   - display cache
   - transfer staging
   - shared context
   - runtime port
   - runtime hooks
   - input / render / transfer / targeting services
3. `ZoneRuntimePort` gives those services a narrow way to:
   - emit public signals
   - request a zone refresh
   - resolve viewport-level drag/targeting coordinators
   - resolve sibling runtime helpers for another zone
4. `Zone` stays the public facade for builders:
   - `add_item(...)`
   - `remove_item(...)`
   - `perform_transfer(...)`
   - `begin_targeting(...)`
   - signals such as `item_transferred`, `drop_rejected`, and `targeting_resolved`

That split is why user code should stay on `Zone` instead of depending on the runtime services directly.

## Directory Responsibilities

### `core/`

Public nodes. This layer should read like the external API, not like an internal runtime service directory.

### `model/`

Public command / placement / decision / visual-state types plus a few workflow-support models that are still part of the public contract story.

### `resources/`

Public extension seams. This is the right place to look when the question is:

- how do I change layout?
- how do I change transfer legality?
- how do I change targeting acceptance?
- how do I change drag visuals or display behavior?

### `impl/`

Reusable built-in concrete implementations of the `resources/` layer. These are public to reuse, but conceptually downstream of the abstract seams.

### `runtime/`

Maintainer-facing machinery. This is where orchestration, cleanup, runtime lookup, and workflow details live.

### `cards/` and `pieces/`

Reusable default item implementations that demonstrate the expected item surface.

### `presets/`

Inspector-friendly starting points. These are meant to be duplicated and localized, not treated as immutable one-size-fits-all configs.

## Public Boundary Rules

### What user code should do

- create or reference `Zone` / `CardZone` / `BattlefieldZone`
- assign `ZoneConfig`
- use `ZoneTransferCommand` / `ZoneTargetingCommand`
- react to zone signals
- subclass public resource seams when behavior must change
- keep game rules in game code or example-specific helpers

### What user code should avoid

- `runtime/*service.gd`
- `runtime/*coordinator.gd`
- `runtime/zone_runtime_hooks.gd`
- `ZoneContext`
- `ZoneStore`
- private `_get_*()` helpers on `Zone`

If a showcase needs new power, the preferred fix is a **small public facade improvement**, not teaching users to depend on runtime internals.

## Addon vs. Example Boundary

The addon should provide:

- zone ownership
- selection and drag loops
- transfer / targeting infrastructure
- configurable layouts, spaces, styles, and policies
- reusable item bases and presets

Examples should provide:

- game-specific rules
- seed/state setup
- history / undo models
- turn flow
- UI copy and showcase affordances

That is why `Workflow Board`, `FreeCell`, and `Xiangqi` are reference consumers of the addon rather than part of the addon runtime contract itself.

## Reading Order

### For addon users

1. `README.md`
2. `docs/getting-started.md`
3. `docs/decision-framework.md`
4. relevant surface guides (`card-zones`, `battlefields`, `transfers-and-targeting`)
5. showcase docs in public order:
   - `Workflow Board`
   - `FreeCell`
   - `Xiangqi`

### For maintainers

1. `addons/nascentsoul/core/zone.gd`
2. `addons/nascentsoul/runtime/zone_runtime_bootstrap.gd`
3. `addons/nascentsoul/runtime/zone_runtime_port.gd`
4. `addons/nascentsoul/runtime/zone_runtime_hooks.gd`
5. one workflow at a time:
   - transfer: `zone_transfer_service.gd` -> `zone_transfer_execution.gd` -> `zone_drag_session_cleanup.gd`
   - input: `zone_input_service.gd` -> `zone_input_selection_controller.gd`
   - targeting: `zone_targeting_service.gd` -> `zone_target_resolution.gd` -> `zone_target_feedback.gd`
   - render: `zone_render_service.gd` -> `zone_drag_preview_feedback.gd`

This order keeps the mental model stable: **public facade first, assembly second, workflow details last**.

## Validation Contract

NascentSoul treats documentation, examples, and tests as part of the same product.

When public behavior changes:

- update docs in the same change
- update examples in the same change
- update tests in the same change

Current validation baseline:

- Godot 4.6.1
- headless regression runner passes with **648 checks**
- headless editor load succeeds with the plugin enabled

This repo is intended to be teachable, so explanation quality and structural clarity are not optional polish. They are part of the architecture.
