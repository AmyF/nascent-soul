# Transfers And Targeting

NascentSoul separates movement from choice.

That is one of the most important ideas in the addon.

## Transfer

Use transfer when the item should:

- move to another zone
- move within the same zone
- land on a specific cell
- be transformed into another runtime item such as a spawned piece

The main entry point is `ZoneTransferCommand`.

```gdscript
hand.perform_transfer(
	ZoneTransferCommand.transfer_between(
		hand,
		board,
		[card],
		ZonePlacementTarget.linear(board.get_item_count())
	)
)
```

Resolved transfer targets stay explicit: ordered zones expose `linear_index`, while battlefields keep `grid_coordinates`.

Policies decide whether the transfer is allowed and how it resolves.

Common transfer policy patterns:

- allow-all
- capacity-limited
- source-restricted
- occupancy-limited
- composite
- rule-table

## Targeting

Use targeting when the source item should stay where it is, but the player still needs to choose:

- another item
- a board cell
- an item or a cell, depending on the action

The main entry point is `ZoneTargetingIntent`.

```gdscript
var intent := ZoneTargetingIntent.new()
intent.allowed_candidate_kinds = PackedInt32Array([
	ZoneTargetCandidate.CandidateKind.ITEM,
	ZoneTargetCandidate.CandidateKind.PLACEMENT
])

zone.begin_targeting(
	ZoneTargetingCommand.explicit_for_item(zone, item, intent)
)
```

The result arrives through the zone's targeting signals. Your gameplay code decides what to do with it.

## Visual Styles

NascentSoul ships with built-in targeting style presets:

- `Classic Arrow`
- `Arcane Bolt`
- `Strike Vector`
- `Tactical Beam`

Preset resources live in `addons/nascentsoul/presets/targeting/`.

You can set a default style on the zone config or override the style for one targeting session via `ZoneTargetingIntent.style_override`.

## When To Use Which

Choose transfer when:

- the card should be played into a lane
- the piece should move to another cell
- the item should change zones or spawn something

Choose targeting when:

- a spell points at a target
- a piece chooses a destination as part of a separate rule evaluation step
- an ability needs a richer preview loop before resolution

The Xiangqi showcase is a good example of explicit targeting driving legal move previews, while the final board update is still handled by gameplay logic.

## Good Files To Inspect

- [`addons/nascentsoul/model/zone_transfer_command.gd`](../addons/nascentsoul/model/zone_transfer_command.gd)
- [`addons/nascentsoul/model/zone_targeting_command.gd`](../addons/nascentsoul/model/zone_targeting_command.gd)
- [`scenes/showcases/freecell/showcase.gd`](../scenes/showcases/freecell/showcase.gd)
- [`scenes/showcases/xiangqi/showcase.gd`](../scenes/showcases/xiangqi/showcase.gd)
