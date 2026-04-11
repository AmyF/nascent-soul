# Showcase: Workflow Board

Workflow Board is the **smallest useful public example** in this repository.

It answers the question:

> "What does a real NascentSoul scene look like before I build a full game?"

## Primary Files

- [`scenes/showcases/workflow_board/showcase.tscn`](../scenes/showcases/workflow_board/showcase.tscn)
- [`scenes/showcases/workflow_board/showcase.gd`](../scenes/showcases/workflow_board/showcase.gd)
- [`scenes/showcases/workflow_board/workflow_task_card.gd`](../scenes/showcases/workflow_board/workflow_task_card.gd)
- [`scenes/showcases/workflow_board/workflow_wip_limit_policy.gd`](../scenes/showcases/workflow_board/workflow_wip_limit_policy.gd)

## What It Demonstrates

- three scene-authored `CardZone` lanes
- two local `ZoneConfig` resources inside one `.tscn`
- a tiny example-side `ZoneTransferPolicy`
- `ZoneCard`-based task cards instead of a custom item framework
- a thin controller that only seeds sample data, resets the board, updates counts, and surfaces visible teaching copy

## Lane Model

The board has three columns:

- `Backlog`
- `In Progress`
- `Done`

Only `In Progress` changes the default move rules. It mounts `workflow_wip_limit_policy.gd` as a local scene resource and caps the lane at three tasks.

The lane bodies are scrollable, but the public lesson stays small:

1. author the lanes in the scene
2. wire config through local resources
3. change one rule with one small policy script
4. keep the controller thin

## Why It Comes First

`FreeCell` and `Xiangqi` are full showcase projects. They are great references, but they are not the smallest first read.

Workflow Board is the first public stop because it makes these questions easy to answer:

- what does a useful `Zone` scene look like?
- where should `ZoneConfig` live in a scene-authored setup?
- how small can a custom `ZoneTransferPolicy` be?
- what stays in the controller, and what stays in the scene or policy?

Start here from [`scenes/main_menu.tscn`](../scenes/main_menu.tscn), then move on to `FreeCell`, then `Xiangqi`.

## Controller Boundary

The controller is intentionally thinner than the two game showcases.

It owns:

- sample task creation
- reset behavior
- lane counts
- visible status / teaching copy

It does **not** own:

- lane construction
- `ZoneConfig` composition
- drag/drop runtime wiring
- the WIP legality rule

Those stay in the scene or the example-side policy.

## Why It Matters For The Library

Workflow Board proves that NascentSoul can be useful **before** you build a full game.

The addon supplies:

- ordered zones
- drag/drop runtime behavior
- layout and display plumbing
- public transfer commands

The example supplies:

- domain-specific task-card presentation
- one tiny WIP rule
- starter-friendly UI copy

That is the intended boundary.

## Regression Coverage

The showcase has its own suite:

- [`scenes/tests/suites/workflow_board_showcase_suite.gd`](../scenes/tests/suites/workflow_board_showcase_suite.gd)

It protects:

- seeded lane counts and sample cards
- visible starter copy
- WIP-limit rejection behavior
- reset behavior
- embedded launcher layout
- scrollable lane-body structure
