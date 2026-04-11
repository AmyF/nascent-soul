# Showcase: Workflow Board

The Workflow Board showcase is the smallest useful public example in this repository.

Primary files:

- [`scenes/showcases/workflow_board/showcase.tscn`](../scenes/showcases/workflow_board/showcase.tscn)
- [`scenes/showcases/workflow_board/showcase.gd`](../scenes/showcases/workflow_board/showcase.gd)
- [`scenes/showcases/workflow_board/workflow_task_card.gd`](../scenes/showcases/workflow_board/workflow_task_card.gd)
- [`scenes/showcases/workflow_board/workflow_wip_limit_policy.gd`](../scenes/showcases/workflow_board/workflow_wip_limit_policy.gd)

## What It Demonstrates

- three scene-authored `CardZone` lanes
- two local `ZoneConfig` resources in one `.tscn`
- a tiny example-side `ZoneTransferPolicy`
- `ZoneCard`-based task cards instead of a custom item framework
- a thin controller that only seeds sample data, resets the board, and updates teaching copy

## Lane Breakdown

- `Backlog`
- `In Progress`
- `Done`

Only `In Progress` changes the default transfer behavior. It mounts `workflow_wip_limit_policy.gd` as a local scene resource and caps the lane at three tasks.

That keeps the teaching goal narrow:

1. author lanes in the scene
2. wire config in the Inspector
3. change one behavior with one small policy script
4. let the controller stay small

## Why It Comes First

`FreeCell` and `Xiangqi` are full showcases. They are good reference projects, but they are not the smallest first read.

Workflow Board is the public answer to:

- what does a useful `Zone` scene look like without game rules?
- where should `ZoneConfig` live in a scene-authored project?
- how small can a custom `ZoneTransferPolicy` be?

If you are new to NascentSoul, start here from [`scenes/main_menu.tscn`](../scenes/main_menu.tscn), then move on to `FreeCell`, then `Xiangqi`.

## Controller Boundary

The controller intentionally stays thinner than the two game showcases.

It owns:

- sample task creation
- reset behavior
- lane counts
- visible status / teaching copy

It does **not** own:

- lane construction
- `ZoneConfig` composition
- drag/drop runtime plumbing
- WIP legality logic

Those stay in the scene or in the small example-side policy.

## Regression Coverage

The showcase now has its own suite:

- [`scenes/tests/suites/workflow_board_showcase_suite.gd`](../scenes/tests/suites/workflow_board_showcase_suite.gd)

It protects:

- seeded lane counts and sample cards
- visible starter copy
- WIP-limit rejection behavior
- reset behavior
- embedded layout bounds inside the launcher host
