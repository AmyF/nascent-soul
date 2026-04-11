# Getting Started

NascentSoul is easiest to understand if you start with three ideas:

- `Zone` is the runtime node.
- `ZoneConfig` is the behavior bundle.
- `ZoneItemControl` is the managed item base.

Everything else builds on that.

If you plan to extend the addon itself, or want to understand which types are public vs. internal, read the repo-level [Architecture](../ARCHITECTURE.md) guide before diving into `runtime/`.

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

## Config Workflow

Pick one of two composition styles:

1. **Inspector-first**: assign one of the preset `.tres` files, then duplicate it into a local resource or local subresource before applying scene-specific overrides.
2. **Script-first**: start from `ZoneConfig.make_card_defaults()` or `ZoneConfig.make_battlefield_defaults()` and use `with_overrides(...)` for the fields you want to replace.

```gdscript
var config := ZoneConfig.make_card_defaults().with_overrides({
	"layout_policy": ZoneHBoxLayout.new(),
	"transfer_policy": my_transfer_policy
})
hand.config = config
```

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

Read the shared target type the same way: ordered zones resolve `ZonePlacementTarget.linear(...)` and expose `linear_index`, while battlefields expose `grid_coordinates` and optional `grid_cell_id`.

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

- Read [Decision Framework](decision-framework.md) if you are unsure which surface to extend.
- Read [Card Zones](card-zones.md) for linear containers.
- Read [Battlefields](battlefields.md) for square and hex spaces.
- Read [Transfers and Targeting](transfers-and-targeting.md) for cross-zone actions and targeting flows.
- Read [Extending Policies](extending-policies.md) and [Extending Layouts](extending-layouts.md) once the stock presets are no longer enough.
- Read [Game Implementation Checklist](game-implementation-checklist.md) when you are turning a prototype into a real game scene.
- Open [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) and start with the two public showcases: `FreeCell`, then `Xiangqi`. Open [`scenes/demo.tscn`](../scenes/demo.tscn) only if you specifically want the compatibility shell that keeps those same two showcases together when launched directly.
