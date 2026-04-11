# Transfers And Targeting

NascentSoul separates **movement** from **choice**.

That split is one of the most important ideas in the addon.

## Transfer

Use transfer when the source item should:

- move within a zone
- move to another zone
- land on a specific battlefield cell
- spawn or deploy into another runtime item

The public entry point is `ZoneTransferCommand`.

```gdscript
hand.perform_transfer(
	ZoneTransferCommand.transfer_between(
		hand,
		board,
		[card],
		ZonePlacementTarget.square(2, 1)
	)
)
```

### What resolves a transfer?

A transfer normally passes through two public concepts:

1. the **placement target** you requested
2. the destination zone's **transfer policy**

That policy decides:

- whether the move is legal
- whether the target should be rewritten
- whether the move should spawn or transform instead of directly inserting the same item

Common policy patterns:

- allow-all
- capacity-limited
- occupancy-limited
- source-restricted
- composite
- rule-table

## Targeting

Use targeting when the source item should stay where it is, but the player still needs to choose:

- another item
- a board cell
- an item-or-cell candidate for an ability

The public entry points are `ZoneTargetingIntent` and `ZoneTargetingCommand`.

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

The result arrives through targeting signals. Your gameplay code then decides what that choice means.

## A Good Rule Of Thumb

Choose **transfer** when:

- the action changes ownership or placement
- the player is directly moving an item
- the board should update immediately if the move is legal

Choose **targeting** when:

- the player is choosing before the effect resolves
- the source item should stay put during the preview loop
- you want richer candidate feedback before committing the action

In short:

- **transfer** = move now
- **targeting** = choose now, resolve meaning afterward

## Placement Targets Stay Explicit

NascentSoul keeps resolved targets explicit instead of hiding them in lane-specific code.

- ordered zones expose `linear_index`
- battlefields expose `grid_coordinates`
- space models may also assign `grid_cell_id`

That is why the same API family can support both card lanes and battlefields without pretending they are the same geometry.

## Targeting Visual Styles

NascentSoul ships with built-in targeting style presets in `addons/nascentsoul/presets/targeting/`.

These styles control how the targeting session looks, not whether the candidate is valid.

You can:

- assign a default targeting style on `ZoneConfig`
- override the style for one targeting session with `ZoneTargetingIntent.style_override`

## Which Showcase Teaches What?

- [Showcase: Workflow Board](showcase-workflow-board.md) teaches transfer with a tiny example-side policy
- [Showcase: FreeCell](showcase-freecell.md) teaches transfer-heavy game rules on card lanes
- [Showcase: Xiangqi](showcase-xiangqi.md) teaches explicit target choice and board-resolution feedback

If you are unsure whether an action should be transfer or targeting, [Showcase: Xiangqi](showcase-xiangqi.md) is the clearest reference for the targeting side of the split.

## What To Read Next

- read [Decision Framework](decision-framework.md) if you are still deciding which workflow owns the action
- read [Extending Policies](extending-policies.md) when the built-in legality or targeting rules are close but not enough
- read [Testing](testing.md) when you want regression coverage for the flow you just changed

## Good Files To Inspect

- [`addons/nascentsoul/model/zone_transfer_command.gd`](../addons/nascentsoul/model/zone_transfer_command.gd)
- [`addons/nascentsoul/model/zone_targeting_command.gd`](../addons/nascentsoul/model/zone_targeting_command.gd)
- [`addons/nascentsoul/model/zone_targeting_intent.gd`](../addons/nascentsoul/model/zone_targeting_intent.gd)
- [`addons/nascentsoul/resources/zone_transfer_policy.gd`](../addons/nascentsoul/resources/zone_transfer_policy.gd)
- [`addons/nascentsoul/resources/zone_targeting_policy.gd`](../addons/nascentsoul/resources/zone_targeting_policy.gd)
- [`scenes/showcases/workflow_board/workflow_wip_limit_policy.gd`](../scenes/showcases/workflow_board/workflow_wip_limit_policy.gd)
- [`scenes/showcases/freecell/showcase.gd`](../scenes/showcases/freecell/showcase.gd)
- [`scenes/showcases/xiangqi/showcase.gd`](../scenes/showcases/xiangqi/showcase.gd)
