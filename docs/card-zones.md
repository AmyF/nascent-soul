# Card Zones

`CardZone` is the ordered, linear branch of NascentSoul.

Use it for:

- hands
- decks
- discard piles
- market rows
- tableau lanes
- board rows

## How A Card Zone Works

A card zone resolves behavior from its `ZoneConfig`:

- `space_model`
- `layout_policy`
- `display_style`
- `interaction`
- `sort_policy`
- `transfer_policy`
- `drag_visual_factory`
- `targeting_style`
- `targeting_policy`

For most card UIs, the default pattern is:

- linear space model
- one of the hand/hbox/vbox/pile layouts
- a card display style
- a transfer policy that matches the gameplay rules

## Basic Example

```gdscript
var deck := CardZone.new()
deck.config = load("res://addons/nascentsoul/presets/pile_zone_config.tres")
add_child(deck)

var hand := CardZone.new()
hand.config = load("res://addons/nascentsoul/presets/hand_zone_config.tres")
add_child(hand)
```

## Adding Items

```gdscript
var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Meteor"
card.face_up = true

hand.add_item(card)
```

Items stay managed by the zone runtime. That means:

- the zone tracks order
- the zone owns selection state
- the layout and display layers can update consistently
- transfer and targeting systems can inspect the same item model

## Reordering

If your zone allows manual ordering, you can reorder within the same zone:

```gdscript
hand.perform_transfer(
	ZoneTransferCommand.reorder_within(
		hand,
		[card],
		ZonePlacementTarget.linear(0)
	)
)
```

Linear card-zone targets resolve to `ZonePlacementTarget.linear(...)`, and the resolved target exposes `linear_index`.

## Moving Between Card Zones

```gdscript
deck.perform_transfer(
	ZoneTransferCommand.transfer_between(
		deck,
		hand,
		[top_card],
		ZonePlacementTarget.linear(hand.get_item_count())
	)
)
```

The final decision always comes from the destination zone's `transfer_policy`.

## Layout Choices

NascentSoul ships with four common linear layouts:

- `ZoneHandLayout`
- `ZoneHBoxLayout`
- `ZoneVBoxLayout`
- `ZonePileLayout`

Use them to communicate the role of a lane:

- hands should feel fan-shaped and readable
- piles should feel stacked and compact
- board rows should feel deliberate and spatially clear
- list-like lanes should favor vertical or horizontal rhythm

## Policies Matter More Than Layout

The visual layout does not define the gameplay rule.

Examples:

- A pile layout can still accept full drag/drop transfers.
- A horizontal row can still reject moves based on capacity.
- A tableau lane can allow multi-card moves if its transfer policy approves them.

That separation is what lets the FreeCell showcase keep all game rules in the example controller while still using the stock zone runtime.

## Good Files To Inspect

- [`addons/nascentsoul/presets/hand_zone_config.tres`](../addons/nascentsoul/presets/hand_zone_config.tres)
- [`addons/nascentsoul/presets/pile_zone_config.tres`](../addons/nascentsoul/presets/pile_zone_config.tres)
- [`scenes/examples/freecell.tscn`](../scenes/examples/freecell.tscn)
- [`scenes/examples/freecell/freecell_zone_registry.gd`](../scenes/examples/freecell/freecell_zone_registry.gd)
