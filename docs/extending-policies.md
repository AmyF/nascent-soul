# Extending Policies

Policies answer two questions:

1. **Is this interaction allowed?**
2. **If it is allowed, what should it resolve to?**

Start here when built-in presets are close, but your game still needs custom rules.

## Prefer Composition Before Subclassing

Before writing a new script:

- try a built-in preset
- try a built-in policy
- try a composite or rule-table style setup

Subclass only when the rule is genuinely game-specific.

## Transfer Policies

`ZoneTransferPolicy` exposes two hooks:

```gdscript
func evaluate_drag_start(context: ZoneContext, anchor_item: ZoneItemControl, selected_items: Array[ZoneItemControl])
func evaluate_transfer(context: ZoneContext, request: ZoneTransferRequest) -> ZoneTransferDecision
```

### `evaluate_drag_start(...)`

Use this when you need to decide:

- whether the drag may begin
- which items are actually part of the drag

Return `ZoneDragStartDecision` to allow, reject, or narrow the dragged set.

### `evaluate_transfer(...)`

Use this when you need to decide:

- whether the drop is legal
- which target should actually be used
- whether the transfer should spawn a piece instead of directly moving the item

The request gives you:

- `request.target_zone`
- `request.source_zone`
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

`ZoneTargetingPolicy` exposes one hook:

```gdscript
func evaluate_target(context: ZoneContext, request: ZoneTargetRequest) -> ZoneTargetDecision
```

Use it when you need to decide:

- whether the current candidate is valid
- whether the candidate should be rewritten to a more specific resolved target
- what hover rejection message should be shown

The request gives you:

- `request.source_zone`
- `request.source_item`
- `request.intent`
- `request.candidate`
- `request.global_position`

Targeting evaluation happens in two stages:

1. the source-side `ZoneTargetingIntent.policy`
2. the target zone's `ZoneTargetingPolicy`

That split lets an ability describe **what it wants**, while the destination zone still controls **what it accepts**.

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

- Keep policies **deterministic** and **side-effect light**.
- Read state from `context`, `request`, item metadata, or your own exported configuration.
- Return a decision instead of mutating unrelated scene state.
- Keep UI copy short and actionable when returning `reason`.
- Put turn logic, scoring, deck generation, and win conditions in the game controller, not in the policy.

## When To Return Metadata

Both `ZoneTransferDecision` and `ZoneTargetDecision` expose `metadata`.

Use it when you want downstream code or visuals to know extra rule information, for example:

- why a target is special
- which movement mode was chosen
- whether an ability upgraded the resolved target

Do not use metadata as a hidden transport for broad scene mutation.

## Good Files To Inspect

- [`addons/nascentsoul/resources/zone_transfer_policy.gd`](../addons/nascentsoul/resources/zone_transfer_policy.gd)
- [`addons/nascentsoul/resources/zone_targeting_policy.gd`](../addons/nascentsoul/resources/zone_targeting_policy.gd)
- [`scenes/examples/policy_lab.tscn`](../scenes/examples/policy_lab.tscn)
- [`scenes/examples/targeting_lab.tscn`](../scenes/examples/targeting_lab.tscn)
- [`scenes/examples/freecell.gd`](../scenes/examples/freecell.gd)
- [`scenes/examples/xiangqi.gd`](../scenes/examples/xiangqi.gd)
