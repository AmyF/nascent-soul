# Extending Policies

Policies answer two questions:

1. **Is this interaction allowed?**
2. **If it is allowed, how should it resolve?**

Read this guide when the built-in presets are close, but your rules are game-specific.

## Prefer Composition Before Subclassing

Before writing a new script:

- try a preset config
- try a built-in transfer or targeting policy
- try a composite policy
- try a rule-table policy

Subclass only when the rule is truly specific to your game or scene.

## Transfer Policies

`ZoneTransferPolicy` exposes two main hooks:

```gdscript
func evaluate_drag_start(context: ZoneContext, anchor_item: ZoneItemControl, selected_items: Array[ZoneItemControl])
func evaluate_transfer(context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision
```

### `evaluate_drag_start(...)`

Use this hook when you need to decide:

- whether the drag may start
- which items actually belong to the drag

Return a `ZoneDragStartDecision` to:

- allow
- reject
- narrow the dragged set

### `evaluate_transfer(...)`

Use this hook when you need to decide:

- whether the drop is legal
- whether the target should be rewritten
- whether the transfer should spawn a different item

The request gives you the important context:

- `request.source_zone`
- `request.target_zone`
- `request.items`
- `request.placement_target`
- `request.global_position`

Helpful shortcut:

- `request.is_reorder()`

### Minimal Transfer Policy Example

```gdscript
extends ZoneTransferPolicy

@export var capacity: int = 5

func evaluate_transfer(context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision:
	if request == null:
		return ZoneTransferDecision.new(false, "Invalid transfer.", ZonePlacementTarget.invalid())
	if request.is_reorder():
		return ZoneTransferDecision.new(true, "", request.placement_target)
	if context.get_item_count() + request.items.size() > capacity:
		return ZoneTransferDecision.new(false, "This lane is full.", request.placement_target)
	return ZoneTransferDecision.new(true, "", request.placement_target)
```

## Targeting Policies

`ZoneTargetingPolicy` exposes one main hook:

```gdscript
func evaluate_target(context: ZoneContext, request: ZoneTargetRequest) -> ZoneTargetDecision
```

Use it when you need to decide:

- whether the current candidate is valid
- whether the candidate should be rewritten
- what rejection reason should be surfaced to the player

The request gives you:

- `request.source_zone`
- `request.source_item`
- `request.intent`
- `request.candidate`
- `request.global_position`

Targeting evaluation usually happens in two stages:

1. the source-side intent policy says what the action wants
2. the destination zone's targeting policy says what the zone accepts

That split lets an ability describe intent without taking ownership of the destination zone's rules.

### Minimal Targeting Policy Example

```gdscript
extends ZoneTargetingPolicy

func evaluate_target(_context: ZoneContext, request: ZoneTargetRequest) -> ZoneTargetDecision:
	var candidate = request.candidate
	if candidate == null or not candidate.is_valid():
		return ZoneTargetDecision.new(false, "Choose a valid target.", ZoneTargetCandidate.invalid())
	if candidate.target_item == request.source_item:
		return ZoneTargetDecision.new(false, "This action cannot target itself.", candidate)
	return ZoneTargetDecision.new(true, "", candidate)
```

## Good Policy Design Rules

- keep policies deterministic
- read state from `context`, `request`, exports, and item metadata
- return a decision instead of mutating unrelated scene state
- keep rejection messages short and actionable
- leave turn flow, scoring, history, and win logic in the game controller

Policies should answer **can this happen?** and **how does it resolve?**  
They should not quietly become your game's central state machine.

## When To Use Decision Metadata

`ZoneTransferDecision` and `ZoneTargetDecision` both expose `metadata`.

Use metadata when downstream code or visuals need extra rule information, for example:

- why a target is special
- which move mode was chosen
- whether a target was upgraded or normalized

Do **not** use metadata as a hidden transport for broad scene mutation.

## Which References Should You Read?

- read **Workflow Board** for the smallest example-side transfer policy
- read **FreeCell** for a richer card-lane transfer policy
- read **Xiangqi** for targeting-heavy rule flow

## Good Files To Inspect

- [`addons/nascentsoul/resources/zone_transfer_policy.gd`](../addons/nascentsoul/resources/zone_transfer_policy.gd)
- [`addons/nascentsoul/resources/zone_targeting_policy.gd`](../addons/nascentsoul/resources/zone_targeting_policy.gd)
- [`addons/nascentsoul/impl/permissions/zone_capacity_transfer_policy.gd`](../addons/nascentsoul/impl/permissions/zone_capacity_transfer_policy.gd)
- [`addons/nascentsoul/impl/permissions/zone_composite_transfer_policy.gd`](../addons/nascentsoul/impl/permissions/zone_composite_transfer_policy.gd)
- [`scenes/showcases/workflow_board/workflow_wip_limit_policy.gd`](../scenes/showcases/workflow_board/workflow_wip_limit_policy.gd)
- [`scenes/showcases/freecell/rules/freecell_zone_policy.gd`](../scenes/showcases/freecell/rules/freecell_zone_policy.gd)
- [`scenes/showcases/xiangqi/rules/xiangqi_target_policy.gd`](../scenes/showcases/xiangqi/rules/xiangqi_target_policy.gd)
