# Game Implementation Checklist

Use this when you are turning NascentSoul from a demo or prototype into a full game-specific scene.

## 1. Map Your Surfaces

Decide which parts of the game are:

- ordered lanes -> `CardZone`
- explicit boards -> `BattlefieldZone`
- pure UI state with no zone behavior -> regular Godot controls

Do not force everything into one zone type.

## 2. Start From A Working Config

Prefer:

1. a preset `.tres`
2. a local duplicated resource or subresource
3. narrow overrides for the scene

If the game creates zones dynamically, start from:

- `ZoneConfig.make_card_defaults()`
- `ZoneConfig.make_battlefield_defaults()`

Keep the built-in pieces aligned:

- `CardZone` + `ZoneLinearSpaceModel`
- `BattlefieldZone` + `ZoneSquareGridSpaceModel` / `ZoneHexGridSpaceModel`
- linear layouts (`ZoneHBoxLayout`, `ZoneHandLayout`, `ZonePileLayout`) + linear spaces
- `ZoneBattlefieldLayout` + grid spaces

The editor now warns on those incompatible built-in combinations. Treat configuration warnings as setup bugs, not as optional polish.

## 3. Decide What Lives In Item Data

Store per-item gameplay facts in your item data or metadata, for example:

- card title
- faction
- cost
- piece owner
- movement tags

Do not hide core game state inside runtime-only helpers.

## 4. Write Transfer Rules

Ask:

- what may be dragged?
- what may be reordered?
- which destination zones accept it?
- should the transfer directly place or spawn something?

Encode those answers in `ZoneTransferPolicy` and scene-side orchestration.

## 5. Write Targeting Rules

Ask:

- does the action target an item, a cell, or both?
- does the source item define extra constraints?
- does the destination zone define acceptance rules?
- what hover feedback should the player see?

Encode those answers in `ZoneTargetingIntent` and `ZoneTargetingPolicy`.

## 6. Keep Game Meaning In The Controller

Your scene or controller script should still own:

- turn flow
- setup and shuffling
- score or victory logic
- rule sequencing after a transfer or target resolves
- save/load or replay logic

Zones should stay reusable.  
Your controller should stay game-specific.

When the controller starts growing, use the same helper pattern as the fuller built-in showcases:

1. keep **scene wiring** in the `.tscn` and thin controller
2. move **zone lookup / board lookup** into a registry helper
3. move **serialized state shape** into a state-model helper
4. move **move legality / rule evaluation** into a rules helper
5. move **undo / restore stacks** into a history helper

Workflow Board shows the thin starter version of that split. FreeCell and Xiangqi both follow the fuller registry/state/rules/history pattern.

## 7. Teach Through References

Walk the reference material in this order when you need help:

1. [Transfers and Targeting](transfers-and-targeting.md)
2. [Extending Policies](extending-policies.md)
3. [Extending Layouts](extending-layouts.md)
4. `Workflow Board`
5. `FreeCell`
6. `Xiangqi`

| Reference | What it teaches |
| --- | --- |
| `Workflow Board` | scene-authored starter lanes, local `ZoneConfig` resources, thin controller boundaries, and a tiny example-side WIP policy |
| `FreeCell` | scene-authored card lanes, move rules, carry-capacity checks, history/restore structure |
| `Xiangqi` | scene-authored battlefield setup, board targeting, state orchestration, and side-panel UX |

Use [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) as the public first screen for the showcase half of this path.

## 8. Add Regression Coverage

Before calling the implementation done:

1. add or update a regression suite for the new public behavior
2. run the headless regression runner
3. run the headless editor load

The repository treats examples and docs as part of the product, so keep them in lockstep with the code.

When a suite gets too large, split it by story:

- scene contracts / serialized authoring checks
- launcher and navigation flows
- showcase behavior stories
- showcase-specific rule suites

The current core, launcher, and showcase suites are organized that way on purpose.
