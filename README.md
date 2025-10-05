
# 介绍

NascentSoul提供了一个模块化的框架，可以快速构建卡牌游戏中的常见功能，如牌库、手牌、弃牌堆等区域管理。

> 作者正在使用该库构建自己的卡牌游戏，会持续更新此库。欢迎提需求相关Issue。

这个插件的核心是 `Zone` 系统，它是一个区域管理器，通过组合不同的逻辑模块来实现各种游戏机制：

- **权限控制** (`ZonePermission`)：控制哪些对象可以进入特定区域
- **布局管理** (`ZoneLayout`)：处理对象在区域内的排列方式，包括弧形布局、堆叠布局、水平布局等
- **显示逻辑** (`ZoneDisplay`)：管理对象的视觉状态，如悬停效果、选中状态等
- **交互处理** (`ZoneInteraction`)：处理点击、拖拽、多选等用户交互
- **排序逻辑** (`ZoneSort`)：定义区域内对象的排序规则
- **动画处理** [待实现/To be realized] (`ZoneAniamtion`)：控制对象动画路径、效果

插件还提供了一个基础的卡牌实现 (`ZoneCard`)，支持翻面动画和高亮效果。

## 示例

项目提供了基本的Demo，包含：

- 牌库（Deck）：使用堆叠布局，禁止拖入
- 手牌（Hand）：使用弧形布局，支持拖拽排序
- 弃牌堆（Discard）：使用堆叠布局，接受拖入的牌

## 结构

```mermaid
graph TD
    subgraph "场景树结构 (Scene Tree Structure)"
        ParentControl["父容器 (Control)"]
        ParentControl -- "场景树包含" --> Zone["Zone (Node)<br/>核心协调器"]
        ParentControl -- "场景树包含" --> ManagedObject["被管理对象 (Control)<br/>卡牌/棋子"]
    end

    subgraph "逻辑与继承关系 (Logical & Inheritance Relationships)"
        subgraph "可配置的逻辑模块 (Logic Resources)"
            LP[ZonePermission<br/>权限]
            LS[ZoneSort<br/>排序]
            LD[ZoneDisplay<br/>显示]
            LL[ZoneLayout<br/>布局]
            LI[ZoneInteraction<br/>交互]
        end

        subgraph "具体实现 (Game-Specific Implementation)"
            CardDisplay["ZoneCardDisplay<br/>(继承自 ZoneDisplay)"]
        end

        %% 核心逻辑关系
        Zone -. "逻辑上管理 (引用)" .-> ManagedObject
        Zone -. "引用" .-> LP
        Zone -. "引用" .-> LS
        Zone -. "引用" .-> LD
        Zone -. "引用" .-> LL
        Zone -. "引用" .-> LI

        %% 交互关系
        LI -. "连接信号到" .-> ManagedObject

        %% 继承关系
        LD -- "可被继承为" --> CardDisplay
    end
```

## 类图

```mermaid
classDiagram
    %% --- Notes explaining the diagram conventions ---

    %% --- Classes in the Scene Tree ---
    class ParentControl {
        <<Control>>
    }
    class Zone {
        <<Node>>
        <<Properties>>
        +Control container
        +Array[Control] managed_items
        +Array[Control] selected_items
        +ZonePermission permission_logic
        +ZoneSort sort_logic
        +ZoneDisplay display_logic
        +ZoneLayout layout_logic
        +ZoneInteraction interaction_logic
        <<Methods>>
        +add_item(item) bool
        +remove_item(item) bool
        +transfer_item_to(item, target_zone) bool
        +force_update_layout()
        +select_item(item, additive)
        +deselect_item(item)
        +clear_selection()
        <<Signals>>
        +item_clicked(item, zone)
        +item_double_clicked(item, zone)
        +item_mouse_entered(item, zone)
        +item_mouse_exited(item, zone)
        +item_drag_started(item, zone)
        +item_dropped(item, zone)
        +item_dragging(item, global_pos, zone)
        +selection_changed(new_selection, zone)
    }
    class ManagedObject {
        <<Control>>
        + '用户的卡牌、棋子等'
    }

    %% --- Logic Module Base Classes (Resources) ---
    class ZonePermission {
        <<Resource>>
        <<Properties>>
        +int max_items
        +Array[StringName] allowed_groups
        +Array[StringName] denied_groups
        <<Methods>>
        +can_add(item, zone) bool
        +can_transfer_in(item, from, to) bool
    }
    class ZoneSort {
        <<Resource>>
        <<Methods>>
        +sort(items) Array
    }
    class ZoneLayout {
        <<Resource>>
        <<Properties>>
        +bool enable_ghost_slot_feedback
        <<Methods>>
        +calculate_transforms(items, rect, ghost_index, dragged_item) Dictionary
        +get_drop_index_at_position(pos, items, rect) int
    }
    class ZoneDisplay {
        <<Resource>>
        <<Properties>>
        +int max_visible_items
        +bool enable_enlarge_on_hover
        +Vector2 hover_scale_multiplier
        +Vector2 hover_offset
        +int hover_z_index_increment
        <<Methods>>
        +filter_visible_items(items) Array
        +apply_display_state(item, state)
    }
    class ZoneInteraction {
        <<Resource>>
        <<Properties>>
        +bool enable_click
        +bool enable_double_click
        +bool enable_drag
        +bool enable_hover_events
        +bool enable_multi_select
        +Key multi_select_modifier
        <<Methods>>
        +setup_item_signals(item, zone)
        +cleanup_item_signals(item)
    }

    %% --- User's Custom Implementation Example ---
    class ZoneCardDisplay {
        <<Resource>>
        <<Properties>>
        +bool show_as_backside
        +bool highlight_on_hover
        +bool highlight_on_select
        +bool face_up_on_hover
        <<Methods>>
        +apply_display_state(item, state)
    }
    class ZoneCard {
        <<Control>>
        + '内置卡牌基类'
        <<Properties>>
        +NodePath front_node_path
        +NodePath back_node_path
        +NodePath highlight_node_path
        +bool starts_face_up
        +FlipAnimation flip_animation_type
        +float flip_duration
        <<Methods>>
        +is_face_up()
        +set_highlight(is_highlighted)
        +set_face_up(is_up, animate)

    }

    %% --- Relationships ---
    note for ParentControl "场景树中, ParentControl<br/>同时包含 Zone 和 ManagedObject"

    Zone o-- "1" ParentControl : Operates Within
    Zone o-- "1" ZonePermission
    Zone o-- "1" ZoneSort
    Zone o-- "1" ZoneLayout
    Zone o-- "1" ZoneDisplay
    Zone o-- "1" ZoneInteraction

    Zone ..> "0..*" ManagedObject : Manages List Of

    ZoneInteraction ..> ManagedObject : Interacts With

    ZoneCardDisplay ..> ZoneCard : Control

    ZoneDisplay <|-- ZoneCardDisplay
```

## 项目状态

⚠️ 此项目仍在早期开发阶段，API 可能会有变化。
