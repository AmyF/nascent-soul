# Decision Framework

Use this guide when you are deciding **which NascentSoul surface to extend**.

## Choose In This Order

1. **Zone family**: `CardZone` or `BattlefieldZone`
2. **Config workflow**: Inspector-first or script-first
3. **Workflow type**: transfer or targeting
4. **Extension seam**: policy, layout, space, display, drag visuals, interaction, or sorting
5. **Responsibility split**: addon runtime or game/example controller

## 1. Pick The Zone Family

Choose `CardZone` when your items mainly care about **order**:

- hands
- decks
- discard piles
- shops
- tableau lanes

Choose `BattlefieldZone` when your items mainly care about **explicit cells**:

- square grids
- hex grids
- tactics boards
- chess-like movement spaces

If your UI has both, use both. NascentSoul is designed for mixed card-and-board flows.

## 2. Pick The Config Workflow

### Inspector-first

Use this when:

- the zone is mostly scene-authored
- artists or designers should be able to inspect it directly
- you want `.tscn` and local subresources to explain the setup

Recommended pattern:

1. assign a preset `.tres`
2. duplicate it into a local resource or local subresource
3. override only the fields that differ for this scene

### Script-first

Use this when:

- the zone is created dynamically
- variants are generated at runtime
- you want reusable config composition helpers in code

Recommended pattern:

```gdscript
var config := ZoneConfig.make_card_defaults().with_overrides({
	"layout_policy": ZoneHBoxLayout.new(),
	"transfer_policy": my_transfer_policy
})
zone.config = config
```

## 3. Choose Transfer Or Targeting

Use **transfer** when the source item should move or spawn:

- reorder within a lane
- move between zones
- place onto a board cell
- deploy a card and spawn a piece

Use **targeting** when the source item should stay put while the player chooses:

- another item
- a board cell
- an item-or-cell candidate for an ability

Rule of thumb:

- **transfer** changes ownership or placement
- **targeting** chooses first, then your gameplay code decides what happens next

## 4. Pick The Right Extension Seam

| If you want to change... | Extend... | Why |
| --- | --- | --- |
| Whether a drag or drop is allowed | `ZoneTransferPolicy` | It owns drag-start and transfer decisions |
| Whether a candidate is targetable | `ZoneTargetingPolicy` | It owns targeting decisions |
| Where items are arranged in a lane | `ZoneLayoutPolicy` | It turns items into `ZonePlacement`s |
| How placements are applied visually | `ZoneDisplayStyle` | It owns motion and visual application |
| How drag ghosts or cursor proxies look | `ZoneDragVisualFactory` | It owns preview visuals |
| How targets and anchors are resolved in space | `ZoneSpaceModel` | It owns board geometry and hover targets |
| How selection / keyboard gestures behave | `ZoneInteraction` | It configures input behavior without rewriting runtime code |
| How idle items auto-sort | `ZoneSortPolicy` | It owns deterministic ordering when sorting is enabled |

## 5. Keep The Right Code In The Right Layer

Put this in the **addon/runtime surface**:

- reusable layout logic
- reusable transfer rules
- reusable targeting rules
- reusable drag visuals
- reusable board geometry

Put this in the **game controller or example scene**:

- turn order
- scoring
- deck setup
- card text interpretation
- win/lose state
- showcase-specific UI copy

The addon should answer **how zones behave**.  
Your game code should answer **what the game means**.

## Suggested Learning Path

Read and run things in this order:

1. [Getting Started](getting-started.md)
2. [Card Zones](card-zones.md) or [Battlefields](battlefields.md)
3. [Transfers and Targeting](transfers-and-targeting.md)
4. [Extending Policies](extending-policies.md)
5. [Extending Layouts](extending-layouts.md)
6. [Game Implementation Checklist](game-implementation-checklist.md)
7. [Architecture](../ARCHITECTURE.md)

Then walk the two public main-menu showcases in order:

1. `FreeCell`
2. `Xiangqi`

For smaller transfer/layout/targeting questions, use the focused docs above instead of looking for the old deleted demo scenes.
