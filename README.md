# NascentSoul

NascentSoul is a Godot 4.6 addon for building **card-style lanes** and **tactical board surfaces** with one consistent zone model.

It is designed for teams who want:

- **scene-authored workflows** that stay friendly to the Inspector
- one public API family for ordered lanes and explicit-cell battlefields
- reusable extension seams for layout, transfer rules, targeting, display, sorting, and drag visuals
- examples that teach how to use the library instead of bypassing it

## Why It Exists

Many card and tactics UIs need the same core behaviors:

- item ownership
- selection
- drag and drop
- reorder vs. cross-zone movement
- explicit placement targets
- hover / preview / targeting feedback

NascentSoul puts those behaviors behind a single mental model so you do not need one system for card lanes and another for tactical boards.

## Core Mental Model

Everything starts with three public ideas:

| Concept | Role | Typical question it answers |
| --- | --- | --- |
| `Zone` | The runtime surface | "Where do items live and how do players interact with them?" |
| `ZoneConfig` | The behavior bundle | "How should this zone lay out, sort, animate, accept drops, and resolve targets?" |
| `ZoneItemControl` | The managed item base | "What is the thing the player sees, selects, drags, or targets?" |

Two more concepts complete the picture:

| Concept | Role |
| --- | --- |
| `ZonePlacementTarget` | Describes where an item should land: a linear index for ordered zones, or grid coordinates for battlefields |
| Transfer vs. targeting | **Transfer** moves or spawns items. **Targeting** chooses an item or cell without moving the source item yet |

If you understand those five ideas, the rest of the addon becomes much easier to place.

## Install

1. Copy `addons/nascentsoul/` into your project.
2. Enable the **NascentSoul** plugin in `Project Settings > Plugins`.
3. Start from the preset configs in `addons/nascentsoul/presets/`, or create zones from the editor menu.

The plugin adds three editor actions:

- `Create Card Zone`
- `Create Square Battlefield Zone`
- `Create Hex Battlefield Zone`

## Quick Start

### Card lane

```gdscript
var hand := CardZone.new()
hand.custom_minimum_size = Vector2(360, 220)
hand.size = hand.custom_minimum_size
hand.config = load("res://addons/nascentsoul/presets/hand_zone_config.tres")
add_child(hand)

var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Spark"
card.face_up = true

hand.add_item(card)
```

### Battlefield

```gdscript
var field := BattlefieldZone.new()
field.custom_minimum_size = Vector2(640, 480)
field.size = field.custom_minimum_size
field.config = load("res://addons/nascentsoul/presets/battlefield_square_zone_config.tres")
add_child(field)

var piece := ZonePiece.new()
piece.data = PieceData.new()
piece.data.title = "Guardian"

field.add_item(piece, ZonePlacementTarget.square(1, 1))
```

## Inspector-First Workflow

NascentSoul is happiest when the scene explains the setup directly.

Recommended pattern:

1. assign a preset `.tres`
2. duplicate it into a local resource or local subresource
3. override only the fields that differ for this scene
4. keep the actual `Zone` nodes scene-authored whenever possible

Start here:

- `addons/nascentsoul/presets/hand_zone_config.tres`
- `addons/nascentsoul/presets/pile_zone_config.tres`
- `addons/nascentsoul/presets/board_zone_config.tres`
- `addons/nascentsoul/presets/discard_zone_config.tres`
- `addons/nascentsoul/presets/battlefield_square_zone_config.tres`
- `addons/nascentsoul/presets/battlefield_hex_zone_config.tres`

## Public Showcase Path

Use [`scenes/main_menu.tscn`](scenes/main_menu.tscn) as the public first screen.

Walk the examples in this order:

1. **`Workflow Board`**  
   Smallest useful starter. Three scene-authored lanes, two local `ZoneConfig` resources, and one tiny example-side WIP rule.
2. **`FreeCell`**  
   Full card-game reference implementation built on `CardZone`, example-side rules, history, and scene-authored lanes.
3. **`Xiangqi`**  
   Full board-game reference implementation built on `BattlefieldZone`, explicit placement targets, targeting, and move-rule orchestration.

[`scenes/demo.tscn`](scenes/demo.tscn) still exists as a compatibility shell for directly opening the two full game showcases together, but it is **not** the recommended starting point.

## Documentation Map

### Start here

- [Getting Started](docs/getting-started.md) — first working card lane, first battlefield, and the public types to learn first
- [Decision Framework](docs/decision-framework.md) — how to decide which surface or extension seam to use

### Learn the public surfaces

- [Card Zones](docs/card-zones.md)
- [Battlefields](docs/battlefields.md)
- [Transfers and Targeting](docs/transfers-and-targeting.md)

### Extend the addon behavior

- [Extending Policies](docs/extending-policies.md)
- [Extending Layouts](docs/extending-layouts.md)

### Study real examples

- [Showcase: Workflow Board](docs/showcase-workflow-board.md)
- [Showcase: FreeCell](docs/showcase-freecell.md)
- [Showcase: Xiangqi](docs/showcase-xiangqi.md)
- [Game Implementation Checklist](docs/game-implementation-checklist.md)

### Maintain the library

- [Architecture](ARCHITECTURE.md)
- [Testing](docs/testing.md)

## Learning Paths

### If you want to build with the addon

1. [Getting Started](docs/getting-started.md)
2. [Decision Framework](docs/decision-framework.md)
3. [Card Zones](docs/card-zones.md) and/or [Battlefields](docs/battlefields.md)
4. [Transfers and Targeting](docs/transfers-and-targeting.md)
5. [Extending Policies](docs/extending-policies.md) and [Extending Layouts](docs/extending-layouts.md)
6. `Workflow Board` -> `FreeCell` -> `Xiangqi`
7. [Game Implementation Checklist](docs/game-implementation-checklist.md)

### If you want to maintain the addon

1. [Architecture](ARCHITECTURE.md)
2. `addons/nascentsoul/core/zone.gd`
3. `addons/nascentsoul/runtime/zone_runtime_bootstrap.gd`
4. `addons/nascentsoul/runtime/zone_runtime_port.gd`
5. `addons/nascentsoul/runtime/zone_runtime_hooks.gd`
6. one workflow at a time:
   - transfer: `zone_transfer_service.gd` -> `zone_transfer_execution.gd` -> `zone_drag_session_cleanup.gd`
   - input: `zone_input_service.gd` -> `zone_input_selection_controller.gd`
   - targeting: `zone_targeting_service.gd` -> `zone_target_resolution.gd` -> `zone_target_feedback.gd`
   - render: `zone_render_service.gd` -> `zone_drag_preview_feedback.gd`

## Validation

Validated on Godot 4.6.1:

- headless regression runner passes with **648 checks**
- headless editor load succeeds with the plugin enabled
- the public launcher path is `Workflow Board` -> `FreeCell` -> `Xiangqi`

Useful commands:

```bash
godot --headless --path . scenes/tests/regression_runner.tscn
godot --headless --editor --quit --path .
godot --path .
```

`godot --path .` opens the project so you can launch the public examples from `scenes/main_menu.tscn`.

## Status

NascentSoul `1.0.0` is the current stable public baseline.

The project is intentionally maintained as both:

- a reusable addon
- a teaching repository where docs, examples, and tests are part of the product
