
# 介绍

NascentSoul提供了一个模块化的框架，可以快速构建卡牌游戏中的常见功能，如牌库、手牌、弃牌堆等区域管理。

> 作者正在使用该库构建自己的卡牌游戏，会持续更新此库。欢迎提需求相关Issue。

这个插件的核心是 `Zone` 系统，它是一个区域管理器，通过组合不同的逻辑模块来实现各种游戏机制：

- **权限控制** (`ZonePermission`)：控制哪些对象可以进入特定区域
- **布局管理** (`ZoneLayout`)：处理对象在区域内的排列方式，包括弧形布局、堆叠布局、水平布局等
- **显示逻辑** (`ZoneDisplay`)：管理对象的视觉状态，如悬停效果、选中状态等
- **交互处理** (`ZoneInteraction`)：处理点击、拖拽、多选等用户交互
- **排序逻辑** (`ZoneSort`)：定义区域内对象的排序规则

插件还提供了一个基础的卡牌实现 (`ZoneCard`)，支持翻面动画和高亮效果。

## 示例

一个简单的拖拽示例。

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

## 项目状态

⚠️ 此项目仍在早期开发阶段，API 可能会有变化。
