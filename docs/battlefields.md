# Battlefields

`BattlefieldZone` is the spatial branch of NascentSoul.

Use it when the main question is:

> **Which cell does this item occupy?**

Typical uses:

- square boards
- hex boards
- tactics maps
- chess-like movement spaces
- deployment grids

If your UI mainly cares about order instead of explicit cells, read [Card Zones](card-zones.md) instead.

## What Makes A Battlefield Different

Battlefields still use `Zone`, `ZoneConfig`, and `ZoneItemControl`.

The difference is that placement is no longer just a linear insert index.

Important pieces:

| Config field | Why battlefields care about it |
| --- | --- |
| `space_model` | defines board geometry and target normalization |
| `layout_policy` | turns targets into placements across the board |
| `display_style` | applies placements visually |
| `transfer_policy` | decides whether a cell can accept the move |
| `targeting_policy` | decides whether a candidate cell or item is targetable |

The built-in battlefield pattern is:

- grid space model
- battlefield layout
- occupancy-aware transfer rules

## Built-In Space Models

NascentSoul ships with:

- `ZoneSquareGridSpaceModel`
- `ZoneHexGridSpaceModel`

These models answer questions such as:

- what target is under the pointer?
- how should a target be normalized?
- where should this item render?
- what anchor should a targeting beam use?

That is why battlefields feel more spatial than card lanes without needing a different public API family.

## Smallest Working Example

```gdscript
var field := BattlefieldZone.new()
field.config = load("res://addons/nascentsoul/presets/battlefield_square_zone_config.tres")
add_child(field)

var piece := ZonePiece.new()
piece.data = PieceData.new()
piece.data.title = "Guardian"

field.add_item(piece, ZonePlacementTarget.square(1, 1))
```

Common targets:

```gdscript
ZonePlacementTarget.square(2, 1)
ZonePlacementTarget.hex(3, 2)
```

Resolved battlefield targets expose `grid_coordinates`, and a space model may also assign a stable `grid_cell_id`.

## Moving Inside The Same Battlefield

Battlefields can still move items within the same zone:

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

This is the core public operation behind board movement. The Xiangqi showcase uses the same API family even though its legal-move rules live in example-side code.

## Occupancy, Deployment, And Spawn Behavior

Battlefields often combine:

- `ZoneOccupancyTransferPolicy`
- composite transfer policies
- rule-table transfer policies

That lets you express things like:

- one item per cell
- cards may enter, pieces may not
- only certain sides may occupy certain cells
- a card may deploy and become a piece instead of remaining a card

## Card-To-Piece Spawning

A destination battlefield can consume a `ZoneCard` and insert a `ZonePiece` instead.

That happens when the destination transfer policy returns a spawn-oriented transfer decision.

This pattern is useful for:

- deployment from hand to board
- summon cards
- tactics games with card-to-piece conversion

The public surface is still the same: a transfer command is issued, then the policy decides how it resolves.

## Inspector-First Pattern

Start from:

- [`battlefield_square_zone_config.tres`](../addons/nascentsoul/presets/battlefield_square_zone_config.tres)
- [`battlefield_hex_zone_config.tres`](../addons/nascentsoul/presets/battlefield_hex_zone_config.tres)

Then duplicate locally and override only what the scene needs.

This keeps the scene readable while still making the board behavior explicit in the Inspector.

## What To Read Next

- read [Transfers and Targeting](transfers-and-targeting.md) if you are deciding whether a move should be direct transfer or a two-stage target choice
- read [Extending Policies](extending-policies.md) if cell legality or targeting acceptance must change
- read [Extending Layouts](extending-layouts.md) if board geometry, placement math, or visual application must change
- read [Showcase: Xiangqi](showcase-xiangqi.md) for the full battlefield reference implementation

## Good Files To Inspect

- [`addons/nascentsoul/presets/battlefield_square_zone_config.tres`](../addons/nascentsoul/presets/battlefield_square_zone_config.tres)
- [`addons/nascentsoul/presets/battlefield_hex_zone_config.tres`](../addons/nascentsoul/presets/battlefield_hex_zone_config.tres)
- [`addons/nascentsoul/impl/spaces/zone_square_grid_space_model.gd`](../addons/nascentsoul/impl/spaces/zone_square_grid_space_model.gd)
- [`addons/nascentsoul/impl/spaces/zone_hex_grid_space_model.gd`](../addons/nascentsoul/impl/spaces/zone_hex_grid_space_model.gd)
- [`addons/nascentsoul/impl/layouts/zone_battlefield_layout.gd`](../addons/nascentsoul/impl/layouts/zone_battlefield_layout.gd)
- [`scenes/showcases/xiangqi/showcase.tscn`](../scenes/showcases/xiangqi/showcase.tscn)
- [`scenes/showcases/xiangqi/board/xiangqi_board_surface.tscn`](../scenes/showcases/xiangqi/board/xiangqi_board_surface.tscn)
