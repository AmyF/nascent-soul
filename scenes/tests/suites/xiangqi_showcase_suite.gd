extends "res://scenes/tests/shared/test_harness.gd"

const XIANGQI_SCENE = preload("res://scenes/examples/xiangqi.tscn")

func _init() -> void:
	_suite_name = "xiangqi-showcase"

func _run_suite() -> void:
	await _test_initial_setup_and_turn_state()
	await _reset_root()
	await _test_toolbar_buttons_and_undo_history()
	await _reset_root()
	await _test_general_advisor_and_elephant_rules()
	await _reset_root()
	await _test_horse_chariot_cannon_and_soldier_rules()
	await _reset_root()
	await _test_turn_capture_and_facing_generals_constraints()
	await _reset_root()
	await _test_compact_layout_keeps_board_targetable()
	await _reset_root()
	await _test_checkmate_game_over_detection()

func _spawn_scene() -> Control:
	var scene = XIANGQI_SCENE.instantiate()
	add_child(scene)
	await _settle_frames(4)
	return scene

func _spawn_scene_in_host(host_size: Vector2) -> Control:
	var scene = XIANGQI_SCENE.instantiate()
	await _mount_scene_in_host(scene, host_size)
	await _settle_frames(2)
	return scene

func _load_state(scene: Control, current_side: String, pieces: Array) -> void:
	scene.call("load_debug_state", {
		"current_side": current_side,
		"pieces": pieces
	})
	await _settle_frames(3)

func _test_initial_setup_and_turn_state() -> void:
	var scene = await _spawn_scene()
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/XiangqiBoardZone") as Zone
	_check(board_zone != null and board_zone.get_item_count() == 32, "xiangqi should load the full 32-piece starting setup")
	_check(scene.call("get_current_side") == &"red", "xiangqi should begin with red to move")
	var red_general = scene.call("get_piece_at_coords", Vector2i(4, 9))
	var black_general = scene.call("get_piece_at_coords", Vector2i(4, 0))
	_check(red_general != null and red_general.piece_type == &"general", "xiangqi should place the red general at the standard home square")
	_check(black_general != null and black_general.piece_type == &"general", "xiangqi should place the black general at the standard home square")
	_check(not scene.call("is_side_in_check", &"red"), "xiangqi initial setup should not start with red in check")
	_check(not scene.call("is_side_in_check", &"black"), "xiangqi initial setup should not start with black in check")

func _test_toolbar_buttons_and_undo_history() -> void:
	var scene = await _spawn_scene()
	var new_game_button = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/NewGameButton") as Button
	var undo_button = scene.get_node_or_null("RootMargin/RootVBox/Toolbar/UndoButton") as Button
	_check(new_game_button != null, "xiangqi should expose a New Game toolbar button")
	_check(undo_button != null, "xiangqi should expose an Undo toolbar button")
	_check(undo_button != null and undo_button.disabled, "xiangqi should disable Undo before any move has been made")
	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "horse", Vector2i(4, 7))
	])
	_check(scene.call("try_move_at", Vector2i(4, 7), Vector2i(6, 8)), "xiangqi undo test should make a legal move first")
	await _settle_frames(2)
	_check(scene.call("get_current_side") == &"black", "xiangqi should pass the turn after a successful move")
	_check(undo_button != null and not undo_button.disabled and scene.call("can_undo"), "xiangqi should enable Undo after a successful move")
	undo_button.pressed.emit()
	await _settle_frames(2)
	_check(scene.call("get_current_side") == &"red", "xiangqi undo should restore the previous side to move")
	_check(scene.call("get_piece_at_coords", Vector2i(4, 7)) != null, "xiangqi undo should restore the moved piece to its original square")
	_check(scene.call("get_piece_at_coords", Vector2i(6, 8)) == null, "xiangqi undo should clear the destination square")
	_check(undo_button != null and undo_button.disabled and not scene.call("can_undo"), "xiangqi should disable Undo again after returning to the initial snapshot")
	new_game_button.pressed.emit()
	await _settle_frames(2)
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/XiangqiBoardZone") as Zone
	_check(board_zone != null and board_zone.get_item_count() == 32, "xiangqi new game should restore the full starting setup")
	_check(scene.call("get_current_side") == &"red", "xiangqi new game should restore red to move")
	_check(undo_button != null and undo_button.disabled and not scene.call("can_undo"), "xiangqi new game should reset the undo history")

func _test_general_advisor_and_elephant_rules() -> void:
	var scene = await _spawn_scene()
	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(4, 9))
	])
	_check(scene.call("try_move_at", Vector2i(4, 9), Vector2i(4, 8)), "xiangqi should allow a general to move one point orthogonally inside the palace")
	await _settle_frames(2)
	_check(scene.call("get_piece_at_coords", Vector2i(4, 8)) != null, "xiangqi should update the general position after a legal palace move")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(4, 9))
	])
	_check(not scene.call("try_move_at", Vector2i(4, 9), Vector2i(6, 9)), "xiangqi should reject general moves that leave the palace")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(4, 9)),
		_piece("red", "advisor", Vector2i(4, 8))
	])
	_check(scene.call("try_move_at", Vector2i(4, 8), Vector2i(5, 9)), "xiangqi should allow an advisor to move diagonally inside the palace")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "advisor", Vector2i(4, 8))
	])
	_check(not scene.call("try_move_at", Vector2i(4, 8), Vector2i(4, 7)), "xiangqi should reject advisor moves that are not single-step diagonals")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "elephant", Vector2i(2, 5))
	])
	_check(scene.call("try_move_at", Vector2i(2, 5), Vector2i(0, 7)), "xiangqi should allow an elephant to move two points diagonally on its own side")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "elephant", Vector2i(2, 5))
	])
	_check(not scene.call("try_move_at", Vector2i(2, 5), Vector2i(4, 3)), "xiangqi should reject elephant moves that cross the river")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "elephant", Vector2i(0, 9)),
		_piece("red", "soldier", Vector2i(1, 8))
	])
	_check(not scene.call("try_move_at", Vector2i(0, 9), Vector2i(2, 7)), "xiangqi should reject elephant moves when the eye point is blocked")

func _test_horse_chariot_cannon_and_soldier_rules() -> void:
	var scene = await _spawn_scene()
	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "horse", Vector2i(4, 7))
	])
	_check(scene.call("try_move_at", Vector2i(4, 7), Vector2i(6, 8)), "xiangqi should allow a horse to move in an L shape when the leg is clear")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "horse", Vector2i(4, 7)),
		_piece("red", "soldier", Vector2i(5, 7))
	])
	_check(not scene.call("try_move_at", Vector2i(4, 7), Vector2i(6, 8)), "xiangqi should reject horse moves when the leg is blocked")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "chariot", Vector2i(0, 5))
	])
	_check(scene.call("try_move_at", Vector2i(0, 5), Vector2i(0, 2)), "xiangqi should allow an unobstructed chariot move along a file")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "chariot", Vector2i(0, 5)),
		_piece("red", "soldier", Vector2i(0, 4))
	])
	_check(not scene.call("try_move_at", Vector2i(0, 5), Vector2i(0, 2)), "xiangqi should reject chariot moves that jump over a blocker")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "cannon", Vector2i(1, 7)),
		_piece("red", "soldier", Vector2i(1, 5)),
		_piece("black", "soldier", Vector2i(1, 3))
	])
	_check(scene.call("try_move_at", Vector2i(1, 7), Vector2i(1, 3)), "xiangqi should allow a cannon capture with exactly one intervening screen")
	await _settle_frames(2)
	_check((scene.call("get_captured_glyphs", &"red") as Array).has("卒"), "xiangqi should record cannon captures for the moving side")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "cannon", Vector2i(1, 7)),
		_piece("red", "soldier", Vector2i(1, 6))
	])
	_check(not scene.call("try_move_at", Vector2i(1, 7), Vector2i(1, 4)), "xiangqi should reject cannon moves that jump when not capturing")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "cannon", Vector2i(1, 7)),
		_piece("black", "soldier", Vector2i(1, 3))
	])
	_check(not scene.call("try_move_at", Vector2i(1, 7), Vector2i(1, 3)), "xiangqi should reject cannon captures without a screen")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "soldier", Vector2i(4, 6))
	])
	_check(scene.call("try_move_at", Vector2i(4, 6), Vector2i(4, 5)), "xiangqi should allow a soldier to move one step forward before crossing the river")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "soldier", Vector2i(4, 6))
	])
	_check(not scene.call("try_move_at", Vector2i(4, 6), Vector2i(5, 6)), "xiangqi should reject sideways soldier moves before crossing the river")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "soldier", Vector2i(4, 4))
	])
	_check(scene.call("try_move_at", Vector2i(4, 4), Vector2i(5, 4)), "xiangqi should allow sideways soldier moves after crossing the river")

func _test_turn_capture_and_facing_generals_constraints() -> void:
	var scene = await _spawn_scene()
	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "horse", Vector2i(1, 7)),
		_piece("black", "soldier", Vector2i(2, 5))
	])
	_check(scene.call("try_move_at", Vector2i(1, 7), Vector2i(2, 5)), "xiangqi should allow a legal capture on the active side's turn")
	await _settle_frames(2)
	_check(scene.call("get_current_side") == &"black", "xiangqi should pass the turn after a successful move")
	_check((scene.call("get_captured_glyphs", &"red") as Array).has("卒"), "xiangqi should list captured pieces for the side that moved")

	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(4, 0)),
		_piece("red", "general", Vector2i(4, 9)),
		_piece("red", "chariot", Vector2i(4, 5))
	])
	_check(not scene.call("is_side_in_check", &"red"), "xiangqi should treat a blocker between the generals as a safe position")
	_check(not scene.call("try_move_at", Vector2i(4, 5), Vector2i(5, 5)), "xiangqi should reject moves that expose the generals to face each other")

func _test_checkmate_game_over_detection() -> void:
	var scene = await _spawn_scene()
	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(4, 0)),
		_piece("red", "general", Vector2i(8, 9)),
		_piece("red", "chariot", Vector2i(3, 1)),
		_piece("red", "chariot", Vector2i(5, 1)),
		_piece("red", "chariot", Vector2i(4, 3))
	])
	_check(scene.call("try_move_at", Vector2i(4, 3), Vector2i(4, 2)), "xiangqi should allow the mating move into the checking file")
	await _settle_frames(2)
	_check(scene.call("get_winner") == &"red", "xiangqi should declare the moving side as the winner after checkmate")
	_check(scene.call("get_last_status_message").to_lower().contains("checkmate"), "xiangqi should explain checkmate in the status state")

func _test_compact_layout_keeps_board_targetable() -> void:
	var scene = await _spawn_scene_in_host(Vector2(960, 900))
	await _settle_frames(3)
	var content_row = scene.get_node_or_null("RootMargin/RootVBox/ContentRow") as Control
	var board_column = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn") as Control
	var board_panel = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel") as Panel
	var board_zone = scene.get_node_or_null("RootMargin/RootVBox/ContentRow/BoardColumn/BoardPanel/BoardHost/XiangqiBoardZone") as Zone
	_check(board_panel != null and board_zone != null and _rect_inside(board_panel.get_global_rect(), board_zone.get_global_rect(), 4.0), "xiangqi compact layout should keep the board zone inside the visible board panel")
	_check(content_row != null and board_column != null and content_row.get_child_count() == 1 and content_row.get_child(0) == board_column, "xiangqi compact layout should keep the simplified board-only content centered")
	await _load_state(scene, "red", [
		_piece("black", "general", Vector2i(3, 0)),
		_piece("red", "general", Vector2i(5, 9)),
		_piece("red", "horse", Vector2i(4, 7))
	])
	_check(scene.call("try_move_at", Vector2i(4, 7), Vector2i(6, 8)), "xiangqi compact layout should keep the board interactive after reflow")

func _piece(side: String, piece_type: String, coords: Vector2i) -> Dictionary:
	return {
		"side": side,
		"type": piece_type,
		"coords": coords
	}
