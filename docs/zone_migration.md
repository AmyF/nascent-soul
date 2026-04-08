# Zone Migration Guide

NascentSoul 的 `Zone` 已经从“逻辑协调器 + 外部 container”重构为真正的 Godot UI 组件：

- 旧形态：`Zone extends Node`，需要绑定一个外部 `container`
- 新形态：`Zone extends Control`，区域本体就是 `Zone` 自己

这是 `0.x` 阶段的 hard break。仓库内场景已经同步迁移，但外部项目里的旧 `.tscn` 需要手动替换，不提供自动重写承诺。

## 变化摘要

- 删除 `zone.container` 作为主接口。
- `Zone` 内部固定维护两个子节点：
  - `ItemsRoot`：只承载受管 item。
  - `PreviewRoot`：只承载 ghost / preview。
- 受管 item 的唯一来源是 `ItemsRoot` 的 direct children。
- `preset: ZonePreset` 成为主配置入口。
- 单项 override 仍保留，优先级固定为：`override 非空 > preset 值 > 默认内置值`。

## 手动迁移步骤

1. 在场景里用新的 `Zone` 控件替换旧的 zone 节点。
2. 把旧 container 上的 UI 属性迁到 `Zone` 自身：
   - `custom_minimum_size` / `size`
   - `clip_contents`
   - `mouse_filter`
   - theme stylebox / panel 样式
   - anchors / offsets / size flags
3. 把旧 container 里的受管卡牌或 item 移到 `Zone/ItemsRoot` 下。
4. 删除旧脚本中的 `zone.container = ...` 绑定。
5. 如果旧工程里手写了多套 layout / display / interaction / permission / sort / drag visual 组合，优先考虑改成 `ZonePreset`，再只保留少量 override。

## 旧写法与新写法

旧写法：

```gdscript
var zone := Zone.new()
zone.container = $HandPanel
zone.layout_policy = ZoneHandLayout.new()
$HandPanel.add_child(zone)
```

新写法：

```gdscript
var zone := Zone.new()
zone.custom_minimum_size = Vector2(320, 220)
zone.size = zone.custom_minimum_size
zone.preset = load("res://addons/nascentsoul/presets/hand_zone_preset.tres")
add_child(zone)
```

添加 item 仍然用显式 API：

```gdscript
zone.add_item(card)
zone.insert_item(card, 0)
zone.reorder_item(card, 2)
zone.move_item_to(card, other_zone)
zone.transfer_items(cards, other_zone, 1)
```

## 编辑器使用建议

- 如果你在 SceneTree 里手动放卡牌，请放到 `ItemsRoot` 下，不要直接挂在 `Zone` 本体上。
- `PreviewRoot` 是运行时专用节点，不要把游戏内容放进去。
- 示例里的 `HandZonePreset`、`BoardZonePreset`、`PileZonePreset`、`DiscardZonePreset` 可以直接作为起点。
- 插件菜单里的 `Create Zone From Preset` 会创建一个可直接编辑的 `Zone`。

## 这次没有做的事

- 没切换到 Godot 内建 `_get_drag_data()` / `_drop_data()` 拖拽 API。
- 没重做 `ZoneCard` 数据模型。
- 没新增回合、战斗或效果层系统。
