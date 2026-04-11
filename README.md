# NascentSoul

NascentSoul is a Godot 4.6 addon for building card-driven interfaces and tactical battlefields with one consistent zone model.

It gives you:

- `Zone`, a UI-native control that owns items, selection, drag/drop, previews, and targeting.
- `ZoneConfig`, a resource that wires space, layout, display, interaction, sorting, transfer rules, drag visuals, and targeting.
- `CardZone` for ordered card containers such as hands, decks, discard piles, shops, and board rows.
- `BattlefieldZone` for square and hex grids with explicit placement targets.
- `ZoneItemControl`, `ZoneCard`, and `ZonePiece` as managed items that stay inside the zone runtime.

NascentSoul is designed so card lanes and tactical boards share the same mental model without forcing the same spatial behavior.

## Core Mental Model

- A `Zone` is the runtime surface.
- A `ZoneConfig` defines how that surface behaves.
- A `ZoneItemControl` is the thing the player sees and interacts with.
- A `ZonePlacementTarget` says where an item should land.
- Transfer moves or spawns items between zones.
- Targeting chooses an item or board cell without moving the source item.

That split is enough to build hands, decks, discard piles, board rows, square battlefields, hex battlefields, drag-driven abilities, and explicit click-to-target workflows with the same API family.

## Install

1. Copy `addons/nascentsoul` into your Godot project.
2. Open `Project Settings > Plugins`.
3. Enable `NascentSoul`.
4. Start from the preset configs in `addons/nascentsoul/presets/` or create zones from the editor plugin menu.

The editor plugin adds:

- `Create Card Zone`
- `Create Square Battlefield Zone`
- `Create Hex Battlefield Zone`

## Quick Start

### Card Zone

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

### Battlefield Zone

```gdscript
var field := BattlefieldZone.new()
field.custom_minimum_size = Vector2(560, 420)
field.size = field.custom_minimum_size
field.config = load("res://addons/nascentsoul/presets/battlefield_square_zone_config.tres")
add_child(field)

var piece := ZonePiece.new()
piece.data = PieceData.new()
piece.data.title = "Guardian"

field.add_item(piece, ZonePlacementTarget.square(1, 1))
```

### Transfer Between Zones

```gdscript
hand.perform_transfer(
	ZoneTransferCommand.transfer_between(
		hand,
		field,
		[card],
		ZonePlacementTarget.square(2, 1)
	)
)
```

### Explicit Targeting

```gdscript
var intent := ZoneTargetingIntent.new()
intent.allowed_candidate_kinds = PackedInt32Array([
	ZoneTargetCandidate.CandidateKind.ITEM,
	ZoneTargetCandidate.CandidateKind.PLACEMENT
])

battlefield.begin_targeting(
	ZoneTargetingCommand.explicit_for_item(battlefield, piece, intent)
)
```

## Showcases

The launcher scene is [`scenes/main_menu.tscn`](scenes/main_menu.tscn). It is the public first screen and exposes direct entries for all 10 examples:

- `Transfer`
- `Layouts`
- `Rules`
- `Recipes`
- `Square`
- `Hex`
- `Modes`
- `Targeting`
- `FreeCell`
- `Xiangqi`

[`scenes/demo.tscn`](scenes/demo.tscn) remains as a compatibility shell when you open it directly. It keeps only the eight editor-facing demos together:

- `Transfer`
- `Layouts`
- `Rules`
- `Recipes`
- `Square`
- `Hex`
- `Modes`
- `Targeting`

The two full playable showcases still live separately:

- `FreeCell`: a complete single-player FreeCell implementation built from `CardZone`, transfer policies, and an example-side tableau layout.
- `Xiangqi`: a complete local two-player Xiangqi implementation built on `BattlefieldZone`, square placement targets, and zone targeting.

The showcase scenes live at:

- [`scenes/examples/freecell.tscn`](scenes/examples/freecell.tscn)
- [`scenes/examples/xiangqi.tscn`](scenes/examples/xiangqi.tscn)

## Documentation

- [Getting Started](docs/getting-started.md)
- [Card Zones](docs/card-zones.md)
- [Battlefields](docs/battlefields.md)
- [Transfers and Targeting](docs/transfers-and-targeting.md)
- [Showcase: FreeCell](docs/showcase-freecell.md)
- [Showcase: Xiangqi](docs/showcase-xiangqi.md)
- [Testing](docs/testing.md)

## Validation

Validated on Godot 4.6.1:

- Headless regression runner passes with `697` checks.
- Headless editor load succeeds with the plugin enabled.
- Demo smoke coverage confirms the main-menu launcher, the compatibility shell, and both showcase scenes.

Run the full suite with:

```bash
godot --headless --path . scenes/tests/regression_runner.tscn
```

## Status

NascentSoul `1.0.0` is the stable public baseline for this addon. The current focus is on bug fixes, examples, documentation, and disciplined API evolution driven by real use cases.
