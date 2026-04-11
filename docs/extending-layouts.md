# Extending Layouts

Use this guide when the built-in lane and battlefield layouts are close, but not quite what your game needs.

## Three Different Responsibilities

NascentSoul keeps spatial work split across three extension points:

| You want to change... | Extend... |
| --- | --- |
| where items should be placed in a container | `ZoneLayoutPolicy` |
| how board targets and anchors are resolved | `ZoneSpaceModel` |
| how placements are applied visually | `ZoneDisplayStyle` |

If you only want different animation or interpolation, do **not** rewrite the layout.  
If you only want different board geometry, do **not** rewrite the display.

## Extending `ZoneLayoutPolicy`

`ZoneLayoutPolicy` exposes:

```gdscript
func calculate(context: ZoneContext, items: Array[ZoneItemControl], container_size: Vector2, ghost_item: Control = null, ghost_hint = null) -> Array[ZonePlacement]
func get_insertion_index(items: Array[ZoneItemControl], container_size: Vector2, mouse_pos: Vector2) -> int
func resolve_item_size(item: Control) -> Vector2
```

### What `calculate(...)` Should Do

Turn the current item list into `ZonePlacement` values.

Each placement controls:

- `position`
- `rotation`
- `scale`
- `z_index`
- `instant`

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

Use `ZoneSpaceModel` when the question is **what target exists in this geometry**.

Important hooks:

- `resolve_hover_target(...)`
- `normalize_target(...)`
- `resolve_add_target(...)`
- `resolve_render_target(...)`
- `resolve_item_position(...)`
- `resolve_target_size(...)`
- `resolve_target_anchor(...)`

That is usually the right place for:

- square-grid math
- hex-grid math
- occupancy-aware target normalization
- mapping cells to render anchors

## Extending `ZoneDisplayStyle`

Use `ZoneDisplayStyle` when the placements are already correct, but you want different application behavior:

- tweens
- snap vs animate rules
- card-face presentation
- custom z-index handling during transitions

The surface is intentionally small:

```gdscript
func apply(context: ZoneContext, placements: Array[ZonePlacement]) -> void
```

`ZoneDisplayStyle` should trust the layout's `ZonePlacement`s instead of recomputing layout semantics from scratch.

## Good Design Rules

- Keep layout code focused on placement math.
- Keep space-model code focused on target math.
- Keep display code focused on visual application.
- Reuse `resolve_item_size(...)` instead of hard-coding item dimensions when possible.
- Prefer starting from a built-in layout or space model and adjusting it.

## Good Files To Inspect

- [`addons/nascentsoul/resources/zone_layout_policy.gd`](../addons/nascentsoul/resources/zone_layout_policy.gd)
- [`addons/nascentsoul/resources/zone_space_model.gd`](../addons/nascentsoul/resources/zone_space_model.gd)
- [`addons/nascentsoul/resources/zone_display_style.gd`](../addons/nascentsoul/resources/zone_display_style.gd)
- [`addons/nascentsoul/impl/layouts/zone_hbox_layout.gd`](../addons/nascentsoul/impl/layouts/zone_hbox_layout.gd)
- [`addons/nascentsoul/impl/layouts/zone_battlefield_layout.gd`](../addons/nascentsoul/impl/layouts/zone_battlefield_layout.gd)
- [`addons/nascentsoul/impl/spaces/zone_square_grid_space_model.gd`](../addons/nascentsoul/impl/spaces/zone_square_grid_space_model.gd)
- [`addons/nascentsoul/impl/spaces/zone_hex_grid_space_model.gd`](../addons/nascentsoul/impl/spaces/zone_hex_grid_space_model.gd)
- [`addons/nascentsoul/impl/displays/zone_card_display.gd`](../addons/nascentsoul/impl/displays/zone_card_display.gd)
