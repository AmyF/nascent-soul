# NascentSoul

NascentSoul 是一个面向 Godot 4.6 的卡牌区域插件。它把“牌在哪个区、如何摆放、如何拖拽、能不能进入、如何展示”拆成可组合的模块，同时把运行时状态从共享 `Resource` 中拿出来，放到每个 `Zone` 自己的 runtime controller 里。

## 核心架构

- `Zone`：外部入口，提供 `add_item`、`insert_item`、`remove_item`、`move_item_to`、`reorder_item` 这些显式命令 API。
- `ZoneLayoutPolicy`：只负责计算 `ZonePlacement`，内置手牌弧线、横向、纵向和堆叠布局。
- `ZoneDisplayStyle`：只保存显示参数；Tween 缓存等运行时状态由 `ZoneRuntime` 管理。
- `ZoneInteraction`：纯配置资源，定义拖拽阈值、长按、多选、Shift 范围选择、背景点击清空选择等输入行为。
- `ZonePermissionPolicy` / `ZoneSortPolicy`：控制拖放准入和展示顺序。
- `ZoneDragCoordinator`：场景级拖拽协调器，替代旧的全局静态上下文。

## 卡牌层

仓库现在自带可选的卡牌实现：

- `CardData`：卡牌数据资源，包含 `id`、`title`、`cost`、`tags`、正反贴图和扩展数据。
- `ZoneCard`：通用卡牌节点，支持翻面、高亮、hover/selected 视觉状态和 ghost/proxy 生成。
- `ZoneCardDisplay`：在 `ZoneTweenDisplay` 之上增加卡牌 hover 抬升和选中缩放效果。

## 快速开始

```gdscript
var zone := Zone.new()
zone.container = $HandPanel
zone.layout_policy = ZoneHandLayout.new()
zone.display_style = ZoneCardDisplay.new()
zone.sort_policy = ZoneManualSort.new()
zone.permission_policy = ZoneAllowAllPermission.new()
zone.interaction = ZoneInteraction.new()
$HandPanel.add_child(zone)

var card := ZoneCard.new()
card.data = CardData.new()
card.data.title = "Spark"
card.face_up = true
zone.add_item(card)
```

默认交互约定：

- 单击选中，`Ctrl` 单击切换多选，`Shift` 单击按当前 anchor 做范围选择。
- 左键拖拽会触发 `drag_started`，目标区会通过 `drop_preview_changed(items, zone, index)` 连续报告预览插入位。
- `drop_preview_changed(..., -1)` 表示当前预览已清空。
- 同区拖放完成后发 `item_reordered`；跨区拖放完成后会先由目标区发 `item_transferred`，再由源区镜像发一次。
- 左键点击 zone 背景会清空 hover 和 selection。

## 内置模块

- 布局：`ZoneHandLayout`、`ZoneHBoxLayout`、`ZoneVBoxLayout`、`ZonePileLayout`
- 显示：`ZoneTweenDisplay`、`ZoneCardDisplay`
- 权限：`ZoneAllowAllPermission`、`ZoneCapacityPermission`、`ZoneSourcePermission`
- 排序：`ZoneManualSort`、`ZonePropertySort`

## Examples

项目默认主场景现在是 example hub：`[scenes/demo.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/demo.tscn)`。

示例资产按能力拆到了 `scenes/examples/`：

- `[transfer_playground.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/transfer_playground.tscn)`：牌库、手牌、战场、弃牌堆之间的拖拽和显式 `move_item_to`
- `[layout_gallery.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/layout_gallery.tscn)`：手牌弧线、横向、纵向、堆叠布局对比
- `[permission_lab.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/permission_lab.tscn)`：容量限制和来源限制
- `[zone_recipes.tscn](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/zone_recipes.tscn)`：Deck / Hand / Board / Discard 四区 starter recipe，可直接复制到新项目
- `[example_support.gd](/Users/unko/repo/github.com/AmyF/nascent-soul/scenes/examples/shared/example_support.gd)`：共享的示例卡牌/zone 构造辅助

直接用 Godot 4.6 打开仓库即可运行。插件菜单里现在提供了：

- `Open NascentSoul Example Hub`
- `Open NascentSoul Zone Recipes`
- `Open NascentSoul README`

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

- `calculate()` 只接收逻辑顺序 items；不要直接读 container child 顺序。
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
