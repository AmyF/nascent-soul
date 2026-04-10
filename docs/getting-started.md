# Getting Started

NascentSoul is easiest to understand if you start with three ideas:

- `Zone` is the runtime node.
- `ZoneConfig` is the behavior bundle.
- `ZoneItemControl` is the managed item base.

Everything else builds on that.

## Installation

1. Copy `addons/nascentsoul` into your project.
2. Enable the `NascentSoul` plugin in `Project Settings > Plugins`.
3. Use the preset configs in `addons/nascentsoul/presets/` to get working zones immediately.

Available preset configs:

- `hand_zone_config.tres`
- `pile_zone_config.tres`
- `board_zone_config.tres`
- `discard_zone_config.tres`
- `battlefield_square_zone_config.tres`
- `battlefield_hex_zone_config.tres`

## First Card Zone

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

This gives you:

- managed item ownership
- selection
- drag/drop
- layout
- hover and drag visuals

## First Battlefield

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

Battlefields use the same zone API, but placement is explicit instead of linear.

## Editor Workflow

The plugin adds three menu actions:

- `Create Card Zone`
- `Create Square Battlefield Zone`
- `Create Hex Battlefield Zone`

Each action creates a zone node, assigns a preset config, and drops it into the edited scene.

## The Types You Will Use Most

- `Zone`
- `CardZone`
- `BattlefieldZone`
- `ZoneConfig`
- `ZonePlacementTarget`
- `ZoneTransferCommand`
- `ZoneTargetingIntent`
- `ZoneCard`
- `ZonePiece`

## Where To Go Next

- Read [Card Zones](card-zones.md) for linear containers.
- Read [Battlefields](battlefields.md) for square and hex spaces.
- Read [Transfers and Targeting](transfers-and-targeting.md) for cross-zone actions and targeting flows.
- Open [`scenes/demo.tscn`](../scenes/demo.tscn) and inspect the examples in motion.
