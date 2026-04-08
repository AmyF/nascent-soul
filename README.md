# NascentSoul

NascentSoul 是一个面向 Godot 4.6 的卡牌区域插件。它把“牌在哪个区、如何摆放、如何拖拽、能不能进入、如何展示”拆成可组合的模块，同时把运行时状态从共享 `Resource` 中拿出来，放到每个 `Zone` 自己的 runtime controller 里。

## 核心架构

- `Zone`：真正的 Godot `Control` 组件。区域本体、输入、尺寸、裁剪和主题样式都挂在 `Zone` 自身，内部固定维护 `ItemsRoot` 与 `PreviewRoot`。
- `ZoneLayoutPolicy`：只负责计算 `ZonePlacement`，内置手牌弧线、横向、纵向和堆叠布局。
- `ZoneDisplayStyle`：只保存显示参数；Tween 缓存等运行时状态由 `ZoneRuntime` 管理。
- `ZoneInteraction`：纯配置资源，定义拖拽阈值、长按、多选、Shift 范围选择、背景点击清空选择等输入行为。
- `ZonePermissionPolicy` / `ZoneSortPolicy`：控制拖放准入和展示顺序。
- `ZoneDragVisualFactory`：可选的 ghost / cursor proxy 生成扩展点，让拖拽视觉不再硬编码在 runtime 里。
- `ZoneDragCoordinator`：场景级拖拽协调器，替代旧的全局静态上下文。

## 卡牌层

仓库现在自带可选的卡牌实现：

- `CardData`：卡牌数据资源，包含 `id`、`title`、`cost`、`tags`、正反贴图和扩展数据。
- `ZoneCard`：通用卡牌节点，支持翻面、高亮、hover/selected 视觉状态，并保留 `create_zone_ghost()` / `create_drag_proxy()` 兼容扩展点。
- `ZoneCardDisplay`：在 `ZoneTweenDisplay` 之上增加卡牌 hover 抬升和选中缩放效果。

## 快速开始

```gdscript
var zone := Zone.new()
zone.custom_minimum_size = Vector2(320, 220)
zone.size = zone.custom_minimum_size
zone.preset = load("res://addons/nascentsoul/presets/hand_zone_preset.tres")
add_child(zone)

var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Spark"
card.face_up = true
zone.add_item(card)
```

配置解析优先级固定为：

- `override 非空 > preset 值 > Zone 默认内置值`

内部节点约定：

- `ItemsRoot`：只承载受管 item，逻辑顺序只看它的 direct children。
- `PreviewRoot`：只承载 ghost / drop preview，不参与逻辑顺序。
- 不要再绑定外部 `container`；如果你在编辑器里手动摆卡，请把 item 放进 `ItemsRoot`。

## Public API

推荐对外只依赖这些显式命令和查询接口：

- `add_item(item)`
- `insert_item(item, index)`
- `remove_item(item)`
- `reorder_item(item, index)`
- `move_item_to(item, target_zone, index := -1)`
- `transfer_items(items, target_zone, index := -1)`
- `get_items()`
- `get_selected_items()`
- `is_selected(item)`
- `clear_selection()`
- `refresh()`

本轮新增并文档化的结构性信号：

- `item_added(item, index)`
- `item_removed(item, from_index)`

其余拖拽相关信号继续保留原语义：`item_reordered`、`item_transferred`、`drop_rejected`、`drop_preview_changed`、`drag_started`。

拖拽 hover 状态现在另外提供：

- `drop_hover_state_changed(items, target_zone, decision)`

其中 `decision.allowed = false` 且 `decision.target_index >= 0` 表示“鼠标正悬停在这个 zone 上，但当前 drop 会被拒绝”，不会再伪装成可落下的 preview slot。

默认交互约定：

- 单击选中，`Ctrl` 单击切换多选，`Shift` 单击按当前 anchor 做范围选择。
- 左键拖拽会触发 `drag_started`，目标区会通过 `drop_preview_changed(items, zone, index)` 连续报告预览插入位。
- `drop_preview_changed(..., -1)` 表示当前预览已清空。
- `drop_hover_state_changed(..., decision)` 会额外报告当前 hover 是否允许落下；已满或权限拒绝时不会显示标准 preview 占位。
- 同区拖放完成后发 `item_reordered`；跨区拖放完成后会先由目标区发 `item_transferred`，再由源区镜像发一次。
- 左键点击 zone 背景会清空 hover 和 selection。

## 内置模块

- 布局：`ZoneHandLayout`、`ZoneHBoxLayout`、`ZoneVBoxLayout`、`ZonePileLayout`
- 显示：`ZoneTweenDisplay`、`ZoneCardDisplay`
- 权限：`ZoneAllowAllPermission`、`ZoneCapacityPermission`、`ZoneSourcePermission`、`ZoneCompositePermission`
- 排序：`ZoneManualSort`、`ZonePropertySort`、`ZoneGroupSort`
- 拖拽视觉：`ZoneConfigurableDragVisualFactory`

## Examples

项目默认主场景现在是 example hub：`[scenes/demo.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/demo.tscn)`。

推荐按下面顺序浏览。demo hub 和场景内说明现在都采用同一套中英双语 onboarding：

1. `[transfer_playground.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/transfer_playground.tscn)`
   目标：先理解 `Deck -> Hand -> Board -> Discard` 的主线流转。
   重点：拖拽、双击、右键三种路径如何共用同一套 `Zone` API；Board 容量满时为什么不会继续显示标准 preview slot。
2. `[layout_gallery.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/layout_gallery.tscn)`
   目标：比较 hand、row、grouped list、pile 四种布局如何影响阅读体验。
   重点：layout 与 sort 是独立可组合的；`Row` 的当前排序模式会显式显示在工具栏中。
3. `[permission_lab.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/permission_lab.tscn)`
   目标：先读规则，再试准入。
   重点：`Board` 演示容量限制，`Sanctum` 演示“来源 + 容量”的组合权限；场景内会持续显示允许来源、当前数量和拒绝反馈。
4. `[zone_recipes.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/zone_recipes.tscn)`
   目标：把 `Deck / Hand / Board / Discard` 当成 starter recipe，而不是纯演示。
   重点：每个区都写明推荐 preset、layout、permission 和最适合先改的部分，方便你复制到自己的项目里。

共享 demo 构造与主题资源在：

- `[example_support.gd](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/shared/example_support.gd)`：共享卡牌构造、贴图缓存和双语字符串 helper
- `[example_card_spec.gd](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/shared/example_card_spec.gd)`：示例卡牌的轻量 `Resource`，让 demo 的样例列表也能直接在 Inspector 中编辑
- `[demo_theme.tres](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/shared/demo_theme.tres)`：共享 demo 标题、说明、状态和按钮的 Theme variation，减少 scene Inspector 里的重复样式覆盖

直接用 Godot 4.6 打开仓库即可运行。插件菜单里现在提供了：

- `Create Zone From Preset`
- `Open NascentSoul Example Hub`
- `Open NascentSoul Zone Recipes`
- `Open NascentSoul README`
- `Open Zone Migration Guide`

## 迁移说明

这次 `Zone: Control` 重构是 `0.x` 阶段的明确 hard break，不承诺旧 `.tscn` 自动兼容，也不会自动重写旧场景文件。

手动迁移旧场景时，按下面步骤处理：

1. 用新的 `Zone` 控件替换旧的 `Node` 型 zone。
2. 把旧 container 的 `size`、style、`clip_contents`、`mouse_filter` 等 UI 属性搬到 `Zone` 自身。
3. 把原来由 zone 管理的 item 移到 `ItemsRoot` 下。
4. 删除旧的 `container` 绑定和相关脚本代码。
5. 如果想统一配置，改为给 `Zone.preset` 绑定 `Hand / Board / Pile / Discard` preset，再按需填单项 override。

详细迁移文档见 `docs/zone_migration.md`。

## 扩展点约定

自定义布局：

```gdscript
class_name CenterStackLayout extends ZoneLayoutPolicy

func calculate(items: Array[Control], container_size: Vector2, ghost_item: Control = null, ghost_index: int = -1) -> Array[ZonePlacement]:
	var placements: Array[ZonePlacement] = []
	var cursor = Vector2(container_size.x * 0.5 - 60.0, container_size.y * 0.5 - 90.0)
	for index in range(items.size()):
		placements.append(ZonePlacement.new(items[index], cursor + Vector2(index * 12.0, 0.0), 0.0, Vector2.ONE, index))
	if ghost_item != null and ghost_index >= 0:
		placements.insert(ghost_index, ZonePlacement.new(ghost_item, cursor + Vector2(ghost_index * 12.0, 0.0), 0.0, Vector2.ONE, ghost_index, true))
	return placements
```

约定：

- `calculate()` 只接收逻辑顺序 items；不要直接读 `ItemsRoot` 的 child 顺序来代替逻辑数据。
- ghost 由 `ghost_item + ghost_index` 显式传入。
- `get_insertion_index()` 应该只根据可见 items 和鼠标位置推导插入位。

自定义显示：

```gdscript
class_name SnapDisplay extends ZoneDisplayStyle

func apply(zone: Node, runtime, placements: Array[ZonePlacement]) -> void:
	for item in runtime.get_items():
		if is_instance_valid(item):
			item.scale = Vector2.ONE
			item.rotation = 0.0
	for placement in placements:
		if is_instance_valid(placement.item):
			placement.item.position = placement.position
			placement.item.rotation = placement.rotation
			placement.item.scale = placement.scale
			placement.item.z_index = placement.z_index
```

约定：

- `apply()` 除了处理 placements，也要把这轮没有参与 placement 的 item 复位。
- 运行时缓存请放进 `runtime.get_display_state(self)`，不要写回共享 `Resource`。

自定义权限和排序：

```gdscript
class_name TaggedOnlyPermission extends ZonePermissionPolicy

@export var required_tag := "attack"

func evaluate_drop(request: ZoneDropRequest) -> ZoneDropDecision:
	for item in request.items:
		if item is ZoneCard and item.data != null and required_tag in item.data.tags:
			continue
		return ZoneDropDecision.new(false, "Only attack cards may enter this zone.", request.requested_index)
	return ZoneDropDecision.new(true, "", request.requested_index)
```

```gdscript
class_name NameSort extends ZoneSortPolicy

func sort_items(items: Array[Control]) -> Array[Control]:
	var sorted_items = items.duplicate()
	sorted_items.sort_custom(func(a: Control, b: Control) -> bool:
		return a.name.naturalnocasecmp_to(b.name) < 0
	)
	return sorted_items
```

如果你想把多个权限模块叠起来，可以直接用内置的 `ZoneCompositePermission`：

```gdscript
var source_only := ZoneSourcePermission.new()
source_only.allowed_source_zone_names = PackedStringArray(["HandZone"])

var capacity := ZoneCapacityPermission.new()
capacity.max_items = 2

var composite := ZoneCompositePermission.new()
composite.combine_mode = ZoneCompositePermission.CombineMode.ALL
composite.policies = [source_only, capacity]
zone.permission_policy = composite
```

如果你想先分组、再在组内排序，可以直接用 `ZoneGroupSort`：

```gdscript
var group_sort := ZoneGroupSort.new()
group_sort.group_metadata_key = "example_primary_tag"
group_sort.group_order = PackedStringArray(["attack", "skill", "power"])
group_sort.item_metadata_key = "example_cost"
zone.sort_policy = group_sort
```

`group_order` 会先决定组的整体顺序；同组内部再按 `item_*` 字段排序。如果组和值都相同，`ZoneGroupSort` 会保持原始插入顺序稳定不变。

如果你想把 drag ghost / cursor proxy 做成可配置模块，可以直接用 `ZoneConfigurableDragVisualFactory`：

```gdscript
var drag_visuals := ZoneConfigurableDragVisualFactory.new()
drag_visuals.prefer_item_methods = false
drag_visuals.ghost_mode = ZoneConfigurableDragVisualFactory.GhostMode.OUTLINE_PANEL
drag_visuals.ghost_fill_color = Color(0.96, 0.93, 0.84, 0.08)
drag_visuals.ghost_border_color = Color(0.96, 0.80, 0.30, 0.72)
drag_visuals.proxy_mode = ZoneConfigurableDragVisualFactory.ProxyMode.DUPLICATE
drag_visuals.proxy_modulate = Color(1, 1, 1, 0.88)
drag_visuals.proxy_scale = Vector2(1.04, 1.04)
zone.drag_visual_factory = drag_visuals
```

约定：

- 工厂优先决定当前 zone 的 ghost / proxy 生成方式。
- 如果工厂为空，runtime 会继续回落到旧的 `ZoneCard.create_zone_ghost()` / `create_drag_proxy()` 与 `zone_ghost_scene` meta 兼容路径。
- ghost 由目标 zone 的工厂生成；cursor proxy 由 source zone 的工厂生成。

## Regression Runner

仓库内置了一个不依赖第三方框架的 headless 回归场景：

- `res://scenes/tests/regression_runner.tscn`
- `res://scenes/tests/suites/core_state_suite.tscn`
- `res://scenes/tests/suites/interaction_smoke_suite.tscn`
- `res://scenes/tests/suites/layout_visual_contract_suite.tscn`
- `res://scenes/tests/suites/performance_smoke_suite.tscn`

覆盖内容：

- `core-state`：增删改排、跨区转移、权限拒绝、拖拽取消、外部 child reconciliation、释放中的对象清理
- `interaction-smoke`：hover、click、`Ctrl` 多选、`Shift` 范围选择、long press、drop preview 清除
- `layout-visual-contract`：手牌/横排/纵排/堆叠默认布局不越界，pile ghost 预览不越界，recipe scene 可直接加载
- `performance-smoke`：`50 / 100 / 200` 张卡的 refresh / reorder / transfer 冒烟与基线输出

常用命令：

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --editor --path . --quit
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . scenes/tests/regression_runner.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 2
```

仓库也包含一个最小 CI 工作流：`[ci.yml](/Users/unko/repo/github.com/AmyF/nascent-soul/.github/workflows/ci.yml)`。

## 人工 GUI 验收清单

- 鼠标进入和离开卡牌后，hover 抬升和 overlay 能正常出现与消失。
- 单击、`Ctrl` 单击、`Shift` 单击分别对应单选、切换多选、范围选择。
- 点击 zone 背景会清空 hover 和 selection。
- 快速双击、右键、长按不会互相吞掉信号。
- 拖到区外取消、权限拒绝、跨区成功 drop 后，都不会残留 ghost、proxy、hover 或 selected 样式。
- `clip_contents = true` 的容器会收到 inspector warning，并且开发者知道 hover/ghost 可能被裁切。
- recipe scene、example hub、permission lab 三个示例在 Godot 4.6.1 下都能直接打开和交互。

## 项目状态

项目仍处于 `0.x` 阶段，API 允许继续演进；当前默认基线是 Godot `4.6.1 stable`，当前插件版本为 `0.7`。
