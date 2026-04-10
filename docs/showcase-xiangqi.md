# Showcase: Xiangqi

The Xiangqi showcase is a full local two-player implementation built on `BattlefieldZone` and targeting.

Primary files:

- [`scenes/examples/xiangqi.tscn`](../scenes/examples/xiangqi.tscn)
- [`scenes/examples/xiangqi.gd`](../scenes/examples/xiangqi.gd)
- [`scenes/examples/xiangqi/xiangqi_piece.gd`](../scenes/examples/xiangqi/xiangqi_piece.gd)
- [`scenes/examples/xiangqi/xiangqi_target_policy.gd`](../scenes/examples/xiangqi/xiangqi_target_policy.gd)
- [`scenes/examples/xiangqi/xiangqi_board_overlay.gd`](../scenes/examples/xiangqi/xiangqi_board_overlay.gd)

## What It Demonstrates

- a square-grid battlefield used as a real game board
- explicit targeting for move preview and validation
- piece-specific rule evaluation in example-side gameplay code
- capture handling, turn flow, check detection, and end-state evaluation

## Board Model

The showcase uses:

- a `BattlefieldZone`
- a `ZoneSquareGridSpaceModel` with 9 columns and 10 rows
- explicit `ZonePlacementTarget.square(x, y)` positions for every piece

The custom board overlay only draws the visual board. The battlefield zone remains the interaction surface.

## Rule Coverage

The controller enforces:

- general movement and palace limits
- advisor movement
- elephant movement, blocked eyes, and river restriction
- horse movement and blocked legs
- chariot movement and path blocking
- cannon screens and capture rules
- soldier forward and post-river sideways movement
- turn order
- capture tracking
- facing-generals prevention
- self-check prevention
- checkmate and no-legal-move end states

## Why It Matters For The Library

Xiangqi shows that NascentSoul can support a tactical board game without a separate game-board framework.

The addon supplies:

- board placement
- target candidates
- targeting visuals
- managed items
- battlefield transfer/runtime services

The example supplies:

- move legality
- turn logic
- victory conditions
- piece presentation

## Regression Coverage

The Xiangqi suite validates:

- initial setup and side-to-move state
- legal and illegal movement for every piece family
- palace, river, blocker, and cannon-screen rules
- capture updates and turn alternation
- facing-generals prevention
- checkmate detection
