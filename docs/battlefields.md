# Battlefields

`BattlefieldZone` is the spatial branch of NascentSoul.

Use it when items must land on explicit cells instead of a single linear order.

## Space Models

NascentSoul ships with:

- `ZoneSquareGridSpaceModel`
- `ZoneHexGridSpaceModel`

These models define board geometry. The battlefield runtime then uses that geometry for:

- placement targets
- occupancy checks
- render positioning
- hover previews
- target candidates

## Placement Targets

Battlefields use `ZonePlacementTarget` instead of only linear insert indices.

Examples:

```gdscript
ZonePlacementTarget.square(2, 1)
ZonePlacementTarget.hex(3, 2)
```

Battlefield targets expose `grid_coordinates`, and space models can also attach a stable `grid_cell_id` when the board needs a named cell identity.

That is the core difference between `CardZone` and `BattlefieldZone`.

## Basic Example

```gdscript
var field := BattlefieldZone.new()
field.config = load("res://addons/nascentsoul/presets/battlefield_square_zone_config.tres")
add_child(field)

var piece := ZonePiece.new()
piece.data = PieceData.new()
piece.data.title = "Guardian"

field.add_item(piece, ZonePlacementTarget.square(1, 1))
```

## Moving Inside A Battlefield

Battlefields can also move items within the same zone:

```gdscript
field.perform_transfer(
	ZoneTransferCommand.transfer_between(
		field,
		field,
		[piece],
		ZonePlacementTarget.square(2, 1)
	)
)
```

This is the foundation used by the Xiangqi showcase.

## Occupancy And Rule Enforcement

Battlefields often combine:

- `ZoneOccupancyTransferPolicy`
- composite transfer policies
- rule-table policies

This lets you say things like:

- one item per cell
- cards may enter, pieces may not
- cards may enter and spawn pieces
- pieces can move between battlefields of the same family

## Card To Piece Spawning

A destination battlefield can consume a `ZoneCard` and insert a `ZonePiece` instead.

That happens when the destination transfer policy returns a `SPAWN_PIECE` decision for the transfer.

This is useful for:

- summons
- tactics games with hand-to-board deployment
- ability cards that become units

## Square And Hex Presets

Start with:

- [`addons/nascentsoul/presets/battlefield_square_zone_config.tres`](../addons/nascentsoul/presets/battlefield_square_zone_config.tres)
- [`addons/nascentsoul/presets/battlefield_hex_zone_config.tres`](../addons/nascentsoul/presets/battlefield_hex_zone_config.tres)

Then swap policies or styles as needed.

## Good Files To Inspect

- [`scenes/examples/battlefield_square_lab.tscn`](../scenes/examples/battlefield_square_lab.tscn)
- [`scenes/examples/battlefield_hex_lab.tscn`](../scenes/examples/battlefield_hex_lab.tscn)
- [`scenes/examples/battlefield_transfer_modes.tscn`](../scenes/examples/battlefield_transfer_modes.tscn)
- [`scenes/examples/xiangqi.tscn`](../scenes/examples/xiangqi.tscn)
