# Game Implementation Checklist

Use this guide when you are moving from:

- a prototype
- a small demo
- or a one-off experiment

to a real game scene built on top of NascentSoul.

The checklist is intentionally practical. It helps you decide what should stay reusable in the addon surface and what should become game-specific code.

## 1. Map Your Surfaces

List your scene in three buckets:

- ordered lanes -> `CardZone`
- explicit boards -> `BattlefieldZone`
- pure UI state with no zone behavior -> regular Godot controls

Do not force everything into one zone type.

The right first question is not "How do I make one giant zone do everything?"  
The right first question is "Which parts are ordered, which parts are spatial, and which parts are just UI?"

## 2. Start From A Working Config

Prefer:

1. a preset `.tres`
2. a local duplicated resource or subresource
3. narrow overrides for the scene

If the game creates zones dynamically, start from:

- `ZoneConfig.make_card_defaults()`
- `ZoneConfig.make_zone_defaults()`
- `ZoneConfig.make_battlefield_defaults()`

Keep built-in pieces aligned:

- `CardZone` + `ZoneLinearSpaceModel`
- `BattlefieldZone` + `ZoneSquareGridSpaceModel` / `ZoneHexGridSpaceModel`
- linear layouts + linear spaces
- `ZoneBattlefieldLayout` + grid spaces

Treat configuration warnings as setup bugs, not optional polish.

## 3. Put Real Game State In Item Data

Store gameplay facts in your item data or metadata, for example:

- card title
- suit or faction
- cost
- side / owner
- movement tags
- ability-specific flags

Do not hide the meaning of the game inside runtime-only helpers.

The runtime should manage interaction and placement.  
Your item data should still explain what the pieces mean.

## 4. Write Transfer Rules Deliberately

Ask:

- what may be dragged?
- what may be reordered?
- which destination zones accept it?
- should the action place directly, or spawn something else?

Encode those answers in `ZoneTransferPolicy` plus game-side orchestration.

Transfer rules answer **can this move happen and how does it resolve?**

## 5. Write Targeting Rules Deliberately

Ask:

- does the action target an item, a cell, or both?
- does the source item define extra constraints?
- does the destination zone define acceptance rules?
- what hover feedback should the player see before commit?

Encode those answers in `ZoneTargetingIntent` and `ZoneTargetingPolicy`.

Targeting rules answer **what can be chosen before the game interprets the result?**

## 6. Keep Game Meaning In The Controller Layer

Your scene or controller should still own:

- turn flow
- setup and shuffling
- score or victory logic
- sequencing after a transfer or target resolves
- save/load or replay logic

Zones should stay reusable.  
Your controller should stay game-specific.

When the controller starts growing, follow the same pattern used by the built-in showcases:

1. keep **scene wiring** in the `.tscn` and a thin controller
2. move **zone lookup / board lookup** into a registry helper
3. move **serialized state shape** into a state-model helper
4. move **move legality / rule evaluation** into a rules helper
5. move **undo / restore stacks** into a history helper

`Workflow Board` demonstrates the thin starter version of that split.  
`FreeCell` and `Xiangqi` demonstrate the fuller helper-oriented version.

## 7. Teach Through References

Use the built-in references in this order:

1. [Transfers and Targeting](transfers-and-targeting.md)
2. [Extending Policies](extending-policies.md)
3. [Extending Layouts](extending-layouts.md)
4. `Workflow Board`
5. `FreeCell`
6. `Xiangqi`

| Reference | What it teaches |
| --- | --- |
| `Workflow Board` | scene-authored starter lanes, local `ZoneConfig` resources, thin controller boundaries, and a tiny example-side WIP policy |
| `FreeCell` | scene-authored card lanes, move rules, carry-capacity checks, seeded state, and history / restore structure |
| `Xiangqi` | scene-authored battlefield setup, targeting, move-rule orchestration, captures, and board-side UI state |

Use [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) as the public first screen for this path.

## 8. Add Regression Coverage Before Calling It Done

Before you consider the scene finished:

1. add or update a regression suite for the new public behavior
2. run the headless regression runner
3. run the headless editor load

The repository treats examples and docs as part of the product, so keep all three in lockstep with the scene.

When a suite gets too large, split it by story:

- scene contracts / serialized authoring checks
- launcher and navigation flows
- showcase behavior stories
- showcase-specific rule suites

That is why the current core, launcher, and showcase suites are organized as multiple focused files instead of one giant smoke test.
