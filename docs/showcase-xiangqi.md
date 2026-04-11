# Showcase: Xiangqi

Xiangqi is the repository's full **battlefield-game reference implementation**.

It is a local two-player game built on `BattlefieldZone`, explicit placement targets, targeting, and example-side move rules.

## Primary Files

- [`scenes/showcases/xiangqi/showcase.tscn`](../scenes/showcases/xiangqi/showcase.tscn)
- [`scenes/showcases/xiangqi/showcase.gd`](../scenes/showcases/xiangqi/showcase.gd)
- [`scenes/showcases/xiangqi/board/xiangqi_board_surface.tscn`](../scenes/showcases/xiangqi/board/xiangqi_board_surface.tscn)
- [`scenes/showcases/xiangqi/board/xiangqi_board_registry.gd`](../scenes/showcases/xiangqi/board/xiangqi_board_registry.gd)
- [`scenes/showcases/xiangqi/state/xiangqi_state_model.gd`](../scenes/showcases/xiangqi/state/xiangqi_state_model.gd)
- [`scenes/showcases/xiangqi/rules/xiangqi_move_rules.gd`](../scenes/showcases/xiangqi/rules/xiangqi_move_rules.gd)
- [`scenes/showcases/xiangqi/state/xiangqi_history.gd`](../scenes/showcases/xiangqi/state/xiangqi_history.gd)
- [`scenes/showcases/xiangqi/pieces/xiangqi_piece.gd`](../scenes/showcases/xiangqi/pieces/xiangqi_piece.gd)
- [`scenes/showcases/xiangqi/rules/xiangqi_target_policy.gd`](../scenes/showcases/xiangqi/rules/xiangqi_target_policy.gd)
- [`scenes/showcases/xiangqi/board/xiangqi_board_overlay.gd`](../scenes/showcases/xiangqi/board/xiangqi_board_overlay.gd)

## What It Demonstrates

- a square-grid battlefield used as a real game board
- explicit targeting for move preview and validation
- piece-specific move rules in example-side gameplay code
- capture handling, turn flow, check detection, and end-state evaluation

## Board Model

The showcase uses:

- a scene-authored board surface in `board/xiangqi_board_surface.tscn`
- a `BattlefieldZone`
- a `ZoneSquareGridSpaceModel` with 9 columns and 10 rows
- explicit `ZonePlacementTarget.square(x, y)` positions for every piece

The custom board overlay only draws the board art.  
The battlefield zone remains the interaction surface.

## Reference Decomposition Pattern

Xiangqi now follows the same helper-oriented pattern as [Showcase: FreeCell](showcase-freecell.md):

1. **scene wiring and turn/status orchestration** stay in `showcase.gd`
2. **piece lookup and board-facing scene helpers** live in `board/xiangqi_board_registry.gd`
3. **serialized board state** lives in `state/xiangqi_state_model.gd`
4. **move legality and check logic** live in `rules/xiangqi_move_rules.gd`
5. **undo snapshots and transition history** live in `state/xiangqi_history.gd`

That keeps the learning path stable:

1. read the scene and controller first
2. inspect the board surface and registry
3. inspect the state model
4. inspect move rules
5. inspect history last

## Rule Coverage

The showcase enforces:

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

Xiangqi shows that NascentSoul can support a tactical board game without a second board-specific framework.

The addon supplies:

- board placement
- target candidates
- targeting visuals
- managed items
- battlefield transfer/runtime plumbing

The example supplies:

- move legality
- turn logic
- victory conditions
- piece presentation
- board-side status and capture UI

That is the intended boundary.

## Read This With

- start with [Showcase: Workflow Board](showcase-workflow-board.md) if you want the smallest scene-authored reference first
- compare it with [Showcase: FreeCell](showcase-freecell.md) to see the same helper-oriented split in a card-game showcase
- pair this showcase with [Battlefields](battlefields.md) and [Transfers and Targeting](transfers-and-targeting.md) for the public surface it exercises
- use [Testing](testing.md) to find the suites that lock the board rules down

## Regression Coverage

The Xiangqi suite validates:

- initial setup and side-to-move state
- legal and illegal movement for every piece family
- palace, river, blocker, and cannon-screen rules
- capture updates and turn alternation
- facing-generals prevention
- checkmate detection
- compact embedded board behavior
