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

## 7. Teach Through Examples

Walk the built-in examples in this order when you need a reference:

| Example | What it teaches |
| --- | --- |
| `Transfer` | basic cross-zone movement and destination-driven acceptance |
| `Layouts` | how layout choice changes the same runtime surface |
| `Rules` | transfer-policy variation and rule-focused behavior changes |
| `Recipes` | config composition patterns worth reusing |
| `Square` | square-grid targets and battlefield placement |
| `Hex` | hex-grid targets and battlefield placement |
| `Modes` | transfer outcomes such as direct placement vs spawned results |
| `Targeting` | explicit item/cell targeting and hover feedback |
| `FreeCell` | a full card game controller built on public APIs |
| `Xiangqi` | a full board game controller using battlefields and targeting |

Use [`scenes/main_menu.tscn`](../scenes/main_menu.tscn) as the public first screen for this path.

## 8. Add Regression Coverage

Before calling the implementation done:

1. add or update a regression suite for the new public behavior
2. run the headless regression runner
3. run the headless editor load

The repository treats examples and docs as part of the product, so keep them in lockstep with the code.
