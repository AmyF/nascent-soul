# Showcase: Xiangqi

The Xiangqi showcase is a full local two-player implementation built on `BattlefieldZone` and targeting.

Primary files:

- [`scenes/showcases/xiangqi/showcase.tscn`](../scenes/showcases/xiangqi/showcase.tscn)
- [`scenes/showcases/xiangqi/showcase.gd`](../scenes/showcases/xiangqi/showcase.gd)
- [`scenes/showcases/xiangqi/xiangqi_board_registry.gd`](../scenes/showcases/xiangqi/xiangqi_board_registry.gd)
- [`scenes/showcases/xiangqi/xiangqi_state_model.gd`](../scenes/showcases/xiangqi/xiangqi_state_model.gd)
- [`scenes/showcases/xiangqi/xiangqi_move_rules.gd`](../scenes/showcases/xiangqi/xiangqi_move_rules.gd)
- [`scenes/showcases/xiangqi/xiangqi_history.gd`](../scenes/showcases/xiangqi/xiangqi_history.gd)
- [`scenes/showcases/xiangqi/xiangqi_piece.gd`](../scenes/showcases/xiangqi/xiangqi_piece.gd)
- [`scenes/showcases/xiangqi/xiangqi_target_policy.gd`](../scenes/showcases/xiangqi/xiangqi_target_policy.gd)
- [`scenes/showcases/xiangqi/xiangqi_board_overlay.gd`](../scenes/showcases/xiangqi/xiangqi_board_overlay.gd)

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

## Controller Decomposition

The Xiangqi showcase now follows the same helper-oriented pattern as FreeCell:

- `xiangqi.gd` stays focused on scene wiring, targeting callbacks, status messages, and turn orchestration
- `xiangqi_board_registry.gd` owns piece lookup, piece spawning, and candidate-to-board resolution
- `xiangqi_state_model.gd` owns initial setup, serialized state shape, board snapshots, and state signatures
- `xiangqi_move_rules.gd` owns move legality, check detection, legal-move search, and piece attack rules
- `xiangqi_history.gd` owns undo snapshots, transition history, and undo-animation state

That split keeps the learning path stable:

1. read the scene and controller first
2. read the state model to see the serialized board shape
3. read the move rules to understand Xiangqi legality
4. read history last to understand undo/restore flow

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
