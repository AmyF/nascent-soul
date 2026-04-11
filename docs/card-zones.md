# Card Zones

`CardZone` is the ordered branch of NascentSoul.

Use it when the main question is:

> **What order are these items in?**

Typical uses:

- hands
- decks
- discard piles
- market rows
- tableau lanes
- kanban columns
- board rows

If your UI mainly cares about explicit cells instead of order, read [Battlefields](battlefields.md) instead.

## What Makes A Card Zone Work

A `CardZone` still gets its behavior from `ZoneConfig`.

The most important pieces are:

| Config field | Why card zones care about it |
| --- | --- |
| `space_model` | usually linear target resolution |
| `layout_policy` | how the lane looks: hand, row, column, or pile |
| `display_style` | how placements are applied visually |
| `interaction` | click / drag / keyboard behavior |
| `sort_policy` | whether idle items auto-sort |
| `transfer_policy` | what moves or reorders are legal |
| `drag_visual_factory` | what drag ghosts and proxies look like |

The layout changes the appearance.  
The policy changes the rules.  
Those are intentionally separate decisions.

## Smallest Working Example

```gdscript
var deck := CardZone.new()
deck.config = load("res://addons/nascentsoul/presets/pile_zone_config.tres")
add_child(deck)

var hand := CardZone.new()
hand.config = load("res://addons/nascentsoul/presets/hand_zone_config.tres")
add_child(hand)
```

Add a card:

```gdscript
var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Meteor"
card.face_up = true

hand.add_item(card)
```

## Common Operations

### Add an item

```gdscript
hand.add_item(card)
```

### Reorder inside the same zone

```gdscript
hand.perform_transfer(
	ZoneTransferCommand.reorder_within(
		hand,
		[card],
		ZonePlacementTarget.linear(0)
	)
)
```

### Move between card zones

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

Card-zone targets resolve to `ZonePlacementTarget.linear(...)`, and the resolved target exposes `linear_index`.

## Built-In Layout Choices

NascentSoul ships with four common linear layouts:

- `ZoneHandLayout`
- `ZoneHBoxLayout`
- `ZoneVBoxLayout`
- `ZonePileLayout`

Use them to communicate the role of a lane:

| Layout | Good fit |
| --- | --- |
| `ZoneHandLayout` | readable player hands |
| `ZoneHBoxLayout` | deliberate horizontal rows |
| `ZoneVBoxLayout` | list-like lanes and columns |
| `ZonePileLayout` | stacked compact piles |

The visual layout does **not** define the legal move rules.

Examples:

- a pile layout can still allow cross-zone transfers
- a horizontal row can still reject moves by capacity
- a vertical column can still allow only one item at a time

Those rules belong in the transfer policy, not the layout.

## Inspector-First Pattern

For scene-authored card lanes, the recommended pattern is:

1. start from `hand_zone_config.tres`, `pile_zone_config.tres`, `board_zone_config.tres`, or `discard_zone_config.tres`
2. duplicate the resource into a local resource or subresource
3. override only the fields that differ for this scene
4. keep the actual `CardZone` nodes authored in the scene

That is the pattern used by the public showcases.

## What To Read Next

- read [Transfers and Targeting](transfers-and-targeting.md) if you are deciding whether an action should move or choose
- read [Extending Policies](extending-policies.md) if the built-in rules are close but not enough
- read [Extending Layouts](extending-layouts.md) if the lane geometry or visual application needs to change
- read [Showcase: Workflow Board](showcase-workflow-board.md) for the smallest scene-authored card-lane example
- read [Showcase: FreeCell](showcase-freecell.md) for a full rules-heavy card-game implementation

## Good Files To Inspect

- [`addons/nascentsoul/presets/hand_zone_config.tres`](../addons/nascentsoul/presets/hand_zone_config.tres)
- [`addons/nascentsoul/presets/pile_zone_config.tres`](../addons/nascentsoul/presets/pile_zone_config.tres)
- [`addons/nascentsoul/impl/layouts/zone_hand_layout.gd`](../addons/nascentsoul/impl/layouts/zone_hand_layout.gd)
- [`addons/nascentsoul/impl/layouts/zone_vbox_layout.gd`](../addons/nascentsoul/impl/layouts/zone_vbox_layout.gd)
- [`scenes/showcases/workflow_board/showcase.tscn`](../scenes/showcases/workflow_board/showcase.tscn)
- [`scenes/showcases/freecell/showcase.tscn`](../scenes/showcases/freecell/showcase.tscn)
