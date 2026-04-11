# Extending Layouts

Use this guide when the built-in lane or battlefield layouts are close, but not quite right for your game.

The most important thing to remember is that NascentSoul splits spatial behavior across **three different responsibilities**.

## Three Responsibilities

| You want to change... | Extend... | Why |
| --- | --- | --- |
| where items should be placed | `ZoneLayoutPolicy` | layout owns placement math |
| how targets and anchors are resolved in a geometry | `ZoneSpaceModel` | space owns target math |
| how placements are applied visually | `ZoneDisplayStyle` | display owns motion and visual application |

If you only want different animation, do **not** rewrite the layout.  
If you only want different geometry, do **not** rewrite the display.

## Extending `ZoneLayoutPolicy`

`ZoneLayoutPolicy` is for placement math inside a container.

Important hooks:

```gdscript
func calculate(context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]
func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int
func resolve_item_size(item: Control) -> Vector2
```

### What `calculate(...)` Should Do

Turn the current render state into `ZonePlacement` values.

Each placement controls:

- position
- rotation
- scale
- z-index
- whether the placement should apply instantly

If your layout supports drag previews, respect `ghost_item` and `ghost_hint`.

### Minimal Linear Layout Example

```gdscript
@tool
extends ZoneLayoutPolicy

@export var spacing: float = 12.0
@export var padding: Vector2 = Vector2(16, 16)

func calculate(_context: ZoneContext, items: Array[ZoneItemControl], _container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]:
	var render_items: Array = items.duplicate()
	var ghost_index = ghost_hint as int if ghost_hint is int else -1
	if is_instance_valid(ghost_item) and ghost_index >= 0:
		render_items.insert(clampi(ghost_index, 0, render_items.size()), ghost_item)
	var placements: Array[ZonePlacement] = []
	var current_x = padding.x
	for index in range(render_items.size()):
		var item = render_items[index]
		placements.append(ZonePlacement.new(item, Vector2(current_x, padding.y), 0.0, Vector2.ONE, index, item == ghost_item))
		current_x += resolve_item_size(item).x + spacing
	return placements

func get_insertion_index(items: Array[ZoneItemControl], _container_size: Vector2, mouse_pos: Vector2) -> int:
	var current_x = padding.x
	for index in range(items.size()):
		var width = resolve_item_size(items[index]).x
		if mouse_pos.x < current_x + width * 0.5:
			return index
		current_x += width + spacing
	return items.size()
```

## Extending `ZoneSpaceModel`

Use `ZoneSpaceModel` when the question is:

> **What target exists in this geometry?**

Important hooks include:

- `resolve_hover_target(...)`
- `normalize_target(...)`
- `resolve_add_target(...)`
- `resolve_render_target(...)`
- `resolve_item_position(...)`
- `resolve_target_size(...)`
- `resolve_target_anchor(...)`

This is usually the right place for:

- square-grid math
- hex-grid math
- occupancy-aware target normalization
- mapping cells to render anchors

## Extending `ZoneDisplayStyle`

Use `ZoneDisplayStyle` when the placements are already correct, but the way they are applied should change.

Examples:

- tweens
- snap vs. animate rules
- card-face presentation
- custom z-index handling during transitions

The core surface stays intentionally small:

```gdscript
func apply(context: ZoneContext, placements: Array[ZonePlacement]) -> void
```

`ZoneDisplayStyle` should trust the layout's placements instead of recomputing layout semantics from scratch.

## Good Design Rules

- keep layout code focused on placement math
- keep space-model code focused on target math
- keep display code focused on visual application
- reuse `resolve_item_size(...)` instead of hard-coding dimensions when possible
- start from a built-in layout or space model when you can

## Which Example Matches Which Need?

- read [Decision Framework](decision-framework.md) if you are still deciding whether the change belongs in layout, space, or display
- read [Card Zones](card-zones.md) for lane-focused setups
- read [Battlefields](battlefields.md) for grid-focused setups
- use [Showcase: Workflow Board](showcase-workflow-board.md) when you want to understand a straightforward vertical lane
- use [Showcase: FreeCell](showcase-freecell.md) when you want to study a richer custom card layout
- use [Showcase: Xiangqi](showcase-xiangqi.md) when you want to study explicit-cell board rendering and targeting anchors
- pair the change with [Testing](testing.md) once the visual contract matters to public behavior

## Good Files To Inspect

- [`addons/nascentsoul/resources/zone_layout_policy.gd`](../addons/nascentsoul/resources/zone_layout_policy.gd)
- [`addons/nascentsoul/resources/zone_space_model.gd`](../addons/nascentsoul/resources/zone_space_model.gd)
- [`addons/nascentsoul/resources/zone_display_style.gd`](../addons/nascentsoul/resources/zone_display_style.gd)
- [`addons/nascentsoul/impl/layouts/zone_hbox_layout.gd`](../addons/nascentsoul/impl/layouts/zone_hbox_layout.gd)
- [`addons/nascentsoul/impl/layouts/zone_vbox_layout.gd`](../addons/nascentsoul/impl/layouts/zone_vbox_layout.gd)
- [`addons/nascentsoul/impl/layouts/zone_battlefield_layout.gd`](../addons/nascentsoul/impl/layouts/zone_battlefield_layout.gd)
- [`addons/nascentsoul/impl/spaces/zone_square_grid_space_model.gd`](../addons/nascentsoul/impl/spaces/zone_square_grid_space_model.gd)
- [`addons/nascentsoul/impl/spaces/zone_hex_grid_space_model.gd`](../addons/nascentsoul/impl/spaces/zone_hex_grid_space_model.gd)
- [`addons/nascentsoul/impl/displays/zone_card_display.gd`](../addons/nascentsoul/impl/displays/zone_card_display.gd)
