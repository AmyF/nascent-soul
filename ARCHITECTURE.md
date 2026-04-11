# Architecture

NascentSoul has two audiences:

1. **users of the addon** who build card or battlefield UIs on top of the public API
2. **maintainers of the addon** who evolve the runtime itself

This document defines the boundary between those two audiences.

## Public Surface

These are the parts game code, showcase code, and open-source users are expected to rely on directly.

| Area | Paths | Notes |
| --- | --- | --- |
| Runtime nodes | `addons/nascentsoul/core/` | `Zone`, `CardZone`, `BattlefieldZone`, `ZoneItemControl` |
| Data + commands | `addons/nascentsoul/model/` | `ZoneTransferCommand`, `ZoneTargetingCommand`, `ZonePlacementTarget`, decisions, visual-state models |
| Extension-point resources | `addons/nascentsoul/resources/` | `ZoneConfig`, `ZoneLayoutPolicy`, `ZoneTransferPolicy`, `ZoneTargetingPolicy`, `ZoneDisplayStyle`, `ZoneDragVisualFactory`, `ZoneItemSpawnFactory`, `ZoneSpaceModel`, `ZoneSortPolicy`, `ZoneInteraction` |
| Built-in item types | `addons/nascentsoul/cards/`, `addons/nascentsoul/pieces/` | `ZoneCard`, `ZonePiece`, `CardData`, `PieceData` |
| Built-in concrete implementations | `addons/nascentsoul/impl/` | Stock layouts, policies, spaces, displays, targeting styles, factories |
| Starter configs | `addons/nascentsoul/presets/` | Inspector-friendly presets for common zone families |
| Editor entry points | `addons/nascentsoul/nascentsoul.gd` | Plugin registration and editor menu actions |

## Internal Runtime

These types exist to make the public surface work, but they are **not** intended as stable extension points.

| Area | Paths | Notes |
| --- | --- | --- |
| Runtime bootstrap | `addons/nascentsoul/runtime/zone_runtime_bootstrap.gd` | Owns the shared store/context/service wiring for a `Zone` |
| Runtime port | `addons/nascentsoul/runtime/zone_runtime_port.gd` | Owns signal emission, refresh, coordinator lookup, and cross-zone runtime lookup so services stay off the `Zone` facade |
| Runtime hooks | `addons/nascentsoul/runtime/zone_runtime_hooks.gd` | Owns internal-only operations that coordinators, tests, and showcase scaffolding may need without keeping `_runtime_*` hooks on `Zone` itself |
| Display cache | `addons/nascentsoul/runtime/zone_display_state_cache.gd` | Holds per-style tween/cache state so `ZoneStore` stays focused on logical item state |
| Transfer staging | `addons/nascentsoul/runtime/zone_transfer_staging.gd` | Holds transfer handoffs and snapshot staging used while items move between zones |
| Internal root host | `addons/nascentsoul/runtime/zone_internal_roots.gd` | Keeps `ItemsRoot` / `PreviewRoot` present, ordered, and editor-safe |
| Transfer workflow | `addons/nascentsoul/runtime/zone_transfer_service.gd`, `zone_transfer_command_router.gd`, `zone_drag_start_flow.gd`, `zone_transfer_decision_resolver.gd`, `zone_transfer_execution.gd`, `zone_drag_session_cleanup.gd` | `ZoneTransferService` stays as the orchestration facade while command routing, drag-start, decision resolution, execution, and cleanup each live in focused helpers |
| Input workflow | `addons/nascentsoul/runtime/zone_input_service.gd`, `zone_input_selection_controller.gd` | Gesture capture stays separate from selection / hover / keyboard flow |
| Render workflow | `addons/nascentsoul/runtime/zone_render_service.gd`, `zone_drag_preview_feedback.gd` | Layout application stays separate from ghost + hover-preview state |
| Targeting workflow | `addons/nascentsoul/runtime/zone_targeting_service.gd`, `zone_target_resolution.gd`, `zone_target_feedback.gd` | Candidate discovery stays separate from feedback state and signal emission |
| Viewport coordinators | `addons/nascentsoul/runtime/*coordinator.gd` | Drag and targeting session orchestration |
| Runtime state holders | `addons/nascentsoul/runtime/zone_context.gd`, `zone_store.gd` | `ZoneContext` assembles config + runtime state collaborators, while `ZoneStore` now stays focused on logical items / targets / selection |
| Internal workflow helpers | parts of `addons/nascentsoul/model/` | Request/session/candidate types that primarily support runtime flows |

**Rule of thumb:** user code should call methods on `Zone`, configure `ZoneConfig`, and react to signals. It should not reach into `runtime/` helpers or private `_get_*()` accessors on `Zone`.

## Directory Responsibilities

### `core/`

Public node types. This layer should stay readable from a user's point of view.

- `Zone` is the public facade
- `CardZone` and `BattlefieldZone` are specialized public entry points
- `ZoneItemControl` is the base class for managed items

### `model/`

Command, target, request, decision, and state objects used to describe workflows.

Current reality:

- most files here are already **public extension contracts**
- policy authors depend on request/decision types from this directory
- style and item authors depend on placement, candidate, and visual-state types from this directory
- `ZonePlacementTarget` keeps shared targeting APIs readable by exposing `linear_index` for ordered zones and `grid_coordinates` / `grid_cell_id` for board cells

Refactor direction:

- keep public command/request/decision/placement types in `model/`
- keep runtime-only session/coordinator state in `runtime/`
- stop introducing new internal-only workflow objects into `model/` without an explicit public reason

### `resources/`

Abstract or configurable extension points.

This is where users should look when they ask:

- how do I change layout?
- how do I change transfer rules?
- how do I change targeting rules?
- how do I customize visuals or drag previews?

### `impl/`

Built-in concrete implementations of the resource layer.

Examples:

- layouts
- spaces
- transfer policies
- targeting policies
- displays
- factories

This directory is public in the sense that users may reuse these implementations, but it should remain conceptually downstream of `resources/`.

### `runtime/`

Internal machinery that powers `Zone`.

This layer should be treated as maintainers' code, not as the addon's day-to-day extension surface.

Two files matter most when reading it:

- `zone_runtime_bootstrap.gd` shows **which collaborators exist**
- `zone_runtime_port.gd` shows **how those collaborators talk back to the public `Zone` facade**

### `cards/` and `pieces/`

Default item implementations that demonstrate the intended item API.

They are public and reusable, but they should not become the only way to extend the system. Custom item types should still be able to build on `ZoneItemControl`.

## Extension Rules

## How to Read the Addon Core

If you are learning from the implementation rather than only using the public API, read the addon in this order:

1. **`core/zone.gd`**: learn the public signals and methods first. Stop at the facade level before diving into runtime details.
2. **`runtime/zone_runtime_bootstrap.gd`**: see which internal collaborators a `Zone` assembles.
3. **`runtime/zone_runtime_port.gd`**: see how services emit public signals, request redraws, and resolve sibling runtime helpers without calling back into `Zone` directly.
4. **`runtime/zone_runtime_hooks.gd`**: see where internal-only runtime hooks now live after being moved off the public `Zone` facade.
5. Pick one workflow and follow it end-to-end:
   - transfer: `zone_transfer_service.gd` → `zone_transfer_execution.gd` → `zone_drag_session_cleanup.gd`
   - input: `zone_input_service.gd` → `zone_input_selection_controller.gd`
   - targeting: `zone_targeting_service.gd` → `zone_target_resolution.gd` → `zone_target_feedback.gd`
   - render: `zone_render_service.gd` → `zone_drag_preview_feedback.gd`

That reading order keeps the mental model stable: **public facade first, assembly second, workflow details last**.

### Expected extension points

Use these when customizing behavior:

- subclass `ZoneTransferPolicy`
- subclass `ZoneTargetingPolicy`
- subclass `ZoneLayoutPolicy`
- subclass `ZoneDisplayStyle`
- subclass `ZoneDragVisualFactory`
- subclass `ZoneItemSpawnFactory`
- subclass `ZoneSpaceModel`
- compose them through `ZoneConfig`

### Expected runtime entry points

Use these from gameplay code:

- `zone.add_item(...)`
- `zone.remove_item(...)`
- `zone.perform_transfer(...)`
- `zone.begin_targeting(...)`
- zone signals such as `item_transferred`, `drop_rejected`, `targeting_resolved`

### Things user code should avoid

- `runtime/*service.gd`
- `runtime/*coordinator.gd`
- `runtime/zone_runtime_hooks.gd`
- `ZoneContext`
- `ZoneStore`
- private `Zone._get_*()` helpers
- examples that bypass the public surface instead of demonstrating it

## Addon vs. Example Boundary

The addon should provide:

- zone ownership and item management
- selection
- drag/drop and preview loops
- transfer and targeting command evaluation flow
- configurable policy/style/layout/factory hooks

Examples should provide:

- game rules
- seed/state setup
- UI copy and example-specific affordances
- showcase-specific orchestration

Examples are reference consumers of the addon, not part of the addon's runtime contract.

## Target Refactor Direction

The current plan treats this as a **direct cutover to a cleaner target architecture**, not a long compatibility migration.

Target direction:

1. `Zone` becomes a thinner public facade
2. runtime services get narrower responsibilities
3. `model/` makes public contract types vs. runtime-support types explicit
4. examples stop using private addon internals
5. docs describe the final structure directly instead of teaching both old and new paths

Current status:

1. `Zone` runtime bootstrap and internal roots are already split out
2. transfer, input, render, and targeting workflows now each have narrower helper seams
3. examples now stay on the public `Zone` surface instead of calling private runtime services directly

## Validation Contract

NascentSoul keeps library code, examples, and tests in lockstep.

When architecture changes:

- update docs in the same change
- update examples in the same change
- update tests in the same change

This repository is intended to be a learning case, so structure and explanation are part of the product.
