# Getting Started

This guide is for your **first successful contact** with NascentSoul.

The goal is not to learn every extension seam at once. The goal is to build a small working zone, understand the public types, and know what to read next.

## Learn These Three Names First

| Type | What it is | Why it matters |
| --- | --- | --- |
| `Zone` | The runtime surface | Owns items, input, layout refresh, transfer, and targeting |
| `ZoneConfig` | The behavior bundle | Decides how a zone lays out, sorts, animates, accepts drops, and resolves targets |
| `ZoneItemControl` | The managed item base | The base class for what the player sees, selects, drags, or targets |

Two supporting ideas complete the first mental model:

- `ZonePlacementTarget` describes **where** something should land
- **transfer** moves or spawns items, while **targeting** chooses without moving the source item yet

If you keep those ideas in mind, most of the public API will feel much more predictable.

## Install

1. Copy `addons/nascentsoul/` into your project.
2. Enable the **NascentSoul** plugin in `Project Settings > Plugins`.
3. Reopen the project if Godot asks you to.

The plugin adds three editor actions:

- `Create Card Zone`
- `Create Square Battlefield Zone`
- `Create Hex Battlefield Zone`

## Fastest Way To See The Addon Working

Open [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) and launch **Workflow Board** first.

That starter scene shows the smallest useful public setup in this repository:

- three scene-authored `CardZone` nodes
- two local `ZoneConfig` resources
- one small example-side transfer rule
- a thin controller that only seeds data and updates visible status copy

If you want to understand the addon from a real scene before writing code, inspect that showcase first and then come back here.

## Your First Card Zone

The simplest first zone is still a card lane.

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

What you get immediately:

- managed item ownership
- selection
- drag and drop
- layout + display refresh
- hover and drag visuals

You did **not** need to manually wire the runtime services yourself. `Zone` handles that behind the public facade.

## Your First Battlefield

Battlefields use the same public API family, but placement is explicit instead of purely ordered.

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

The important difference is the target:

- card lanes usually use `ZonePlacementTarget.linear(...)`
- battlefields use square or hex coordinates such as `ZonePlacementTarget.square(...)` or `ZonePlacementTarget.hex(...)`

## Two Configuration Styles

### Inspector-first

Use this when the zone should be readable from the scene:

1. assign a preset `.tres`
2. duplicate it into a local resource or local subresource
3. override only the fields that differ for this scene

This is the preferred style for public showcases and for most scene-authored game UIs.

### Script-first

Use this when zones are created dynamically or when you want reusable code-side composition.

```gdscript
var config := ZoneConfig.make_card_defaults().with_overrides({
	"layout_policy": ZoneHBoxLayout.new(),
	"transfer_policy": my_transfer_policy
})

zone.config = config
```

Use `ZoneConfig.make_zone_defaults()` when you want a simpler straight lane, and `ZoneConfig.make_battlefield_defaults()` when you want an explicit-cell board.

## Keep The Built-In Pieces Aligned

The built-in zone families, layouts, and space models are meant to match:

- `CardZone` -> `ZoneLinearSpaceModel`
- `BattlefieldZone` -> `ZoneSquareGridSpaceModel` or `ZoneHexGridSpaceModel`
- `ZoneHandLayout`, `ZoneHBoxLayout`, `ZoneVBoxLayout`, `ZonePileLayout` -> linear spaces
- `ZoneBattlefieldLayout` -> grid spaces

NascentSoul surfaces these mismatches as editor configuration warnings. If Godot shows a warning in the Inspector, fix the pairing before debugging rules or visuals.

## Public Types You Will Touch Most Often

- `Zone`
- `CardZone`
- `BattlefieldZone`
- `ZoneConfig`
- `ZonePlacementTarget`
- `ZoneTransferCommand`
- `ZoneTargetingCommand`
- `ZoneTransferPolicy`
- `ZoneTargetingPolicy`
- `ZoneCard`
- `ZonePiece`

## Where To Go Next

Choose the next document based on your question:

- read [Decision Framework](decision-framework.md) if you are unsure which seam to extend
- read [Card Zones](card-zones.md) if your UI mainly cares about order
- read [Battlefields](battlefields.md) if your UI mainly cares about explicit cells
- read [Transfers and Targeting](transfers-and-targeting.md) if you are deciding between movement and choice
- read [Showcase: Workflow Board](showcase-workflow-board.md) if you want the smallest real scene to inspect
- read [Showcase: FreeCell](showcase-freecell.md) or [Showcase: Xiangqi](showcase-xiangqi.md) once you want full reference implementations
- read [Architecture](../ARCHITECTURE.md) only after the public surface already feels familiar
