# Decision Framework

Use this guide when you already know the basic public types and now need to decide:

- which kind of zone to use
- whether to stay Inspector-first or move to code
- which extension seam owns the behavior you want
- whether code belongs in the addon layer or in your game / example layer

## Step 1: What Kind Of Surface Are You Building?

### Use `CardZone` when order is the main idea

Typical examples:

- hands
- decks
- discard piles
- market rows
- tableau lanes
- kanban-style columns

### Use `BattlefieldZone` when explicit cells are the main idea

Typical examples:

- square boards
- hex boards
- tactics maps
- chess-like movement spaces

If your game has both, use both. NascentSoul is designed for mixed card-and-board flows.

## Step 2: Should The Scene Explain Itself?

### Choose Inspector-first when:

- the zone is mostly scene-authored
- designers should be able to inspect it directly
- you want `.tscn` + local resources to explain the setup
- the zone belongs to a reusable showcase or a readable game scene

Recommended pattern:

1. start from a preset `.tres`
2. duplicate it into a local resource or local subresource
3. override only the fields that differ for this scene

### Choose script-first when:

- zones are created dynamically
- variants are generated at runtime
- you want reusable config composition helpers in code

Typical starting points:

- `ZoneConfig.make_card_defaults()`
- `ZoneConfig.make_zone_defaults()`
- `ZoneConfig.make_battlefield_defaults()`

## Step 3: Are You Changing Movement Or Choice?

### Choose transfer when the item should move or spawn

Use transfer for:

- reordering within a lane
- moving between zones
- placing an item onto a board cell
- deploying a card that becomes another item

Public surface:

- `ZoneTransferCommand`
- `ZoneTransferPolicy`
- `ZoneTransferDecision`

### Choose targeting when the source should stay put while the player chooses

Use targeting for:

- selecting another item
- selecting a board cell
- choosing from item-or-cell candidates for an ability

Public surface:

- `ZoneTargetingCommand`
- `ZoneTargetingIntent`
- `ZoneTargetingPolicy`
- `ZoneTargetDecision`

Rule of thumb:

- **transfer** changes ownership or placement
- **targeting** chooses first, then your gameplay code decides what happens

## Step 4: Which Extension Seam Owns The Change?

| You want to change... | Extend... | Why |
| --- | --- | --- |
| whether a drag or drop is allowed | `ZoneTransferPolicy` | transfer legality and resolution belong here |
| whether a candidate is valid for targeting | `ZoneTargetingPolicy` | targeting acceptance belongs here |
| where items should be placed | `ZoneLayoutPolicy` | layout owns placement math |
| what target exists in a space | `ZoneSpaceModel` | geometry and target normalization belong here |
| how placements are applied visually | `ZoneDisplayStyle` | motion and visual application belong here |
| how drag ghosts or cursor proxies look | `ZoneDragVisualFactory` | preview visuals belong here |
| how idle items auto-sort | `ZoneSortPolicy` | deterministic reordering belongs here |
| how click / keyboard / drag toggles behave | `ZoneInteraction` | input configuration belongs here |

If you only want different animation, do **not** rewrite the layout.  
If you only want different geometry, do **not** rewrite the display.  
If you only want different legality, do **not** rewrite the controller.

## Step 5: Which Layer Should Own The Code?

Put code in the **addon layer** when it is reusable across many games:

- reusable layouts
- reusable transfer rules
- reusable targeting rules
- reusable drag visuals
- reusable board geometry
- reusable item bases

Put code in the **game or showcase layer** when it gives the rules meaning:

- turn order
- deck setup
- scoring
- win / lose state
- showcase-specific UI copy
- history / undo models
- seeded scenario setup

The addon should answer **how zones behave**.  
Your game code should answer **what the game means**.

## Step 6: Which Reference Should You Read?

Start with the smallest example that matches your question:

1. **`Workflow Board`** — smallest useful scene-authored example with one tiny custom transfer rule
2. **`FreeCell`** — full card-game example with rules, history, and scene-authored lanes
3. **`Xiangqi`** — full battlefield example with explicit placement targets, targeting, and turn-based rule orchestration

Then jump to the focused guide that matches the seam:

- [Card Zones](card-zones.md)
- [Battlefields](battlefields.md)
- [Transfers and Targeting](transfers-and-targeting.md)
- [Extending Policies](extending-policies.md)
- [Extending Layouts](extending-layouts.md)

## One Practical Checklist

Before adding new code, ask:

1. is this an ordered lane or an explicit-cell board?
2. can I explain the setup directly in the scene?
3. is this a transfer problem or a targeting problem?
4. am I changing policy, layout, space, display, drag visuals, sorting, or input?
5. is this reusable library behavior, or just this game's meaning?

If those answers are clear, the implementation path is usually clear too.
