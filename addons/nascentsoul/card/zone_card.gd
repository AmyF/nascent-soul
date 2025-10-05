# ZoneCard.gd
class_name ZoneCard
extends Control

## ZoneCard 是一个“开箱即用”的卡牌基类。
## 它本身不处理任何游戏数据，只提供通用的【机制】：
## 1. 管理正面、背面和高亮节点的显示/隐藏。
## 2. 提供多种内置的翻面动画效果。
##
## 用户应创建继承自此类的新脚本，并在其中处理自己的游戏数据加载和逻辑。


#=============================================================================
# 1. 枚举 (Enums)
#=============================================================================

## 定义翻面动画的类型
enum FlipAnimation { INSTANT, FADE, SHRINK }


#=============================================================================
# 2. 导出属性 (Inspector配置)
#=============================================================================

## [必需] 指向卡牌正面内容的节点路径。
@export var front_node_path: NodePath
## [必需] 指向卡牌背面内容的节点路径。
@export var back_node_path: NodePath
## [可选] 指向高亮效果节点的节点路径。
@export var highlight_node_path: NodePath

## 卡牌在场景加载时是否默认正面朝上。
@export var starts_face_up: bool = true

## 翻面时使用的动画类型。
@export var flip_animation_type: FlipAnimation = FlipAnimation.SHRINK
## 翻面动画的持续时间（秒）。
@export var flip_duration: float = 0.2


#=============================================================================
# 3. 私有变量 (Internal State)
#=============================================================================

var _front_node: CanvasItem
var _back_node: CanvasItem
var _highlight_node: Control # 通常是UI节点
var _is_face_up: bool = true
var _tween: Tween


#=============================================================================
# 4. Godot生命周期方法 (Lifecycle Methods)
#=============================================================================

func _ready():
	# 通过NodePath获取对节点的实际引用
	# 使用 get_node_or_null 避免因配置错误导致游戏崩溃
	_front_node = get_node_or_null(front_node_path)
	_back_node = get_node_or_null(back_node_path)
	_highlight_node = get_node_or_null(highlight_node_path)
	
	if not _front_node or not _back_node:
		push_error("ZoneCard is missing a valid reference to its Front or Back node.")
		return
		
	# 根据初始设置，无动画地设置正反面
	set_face_up(starts_face_up, false)
	
	# 默认隐藏高亮
	if is_instance_valid(_highlight_node):
		_highlight_node.visible = false

#=============================================================================
# 5. 公共方法 (Public API)
#=============================================================================

## 返回卡牌当前是否正面朝上。
func is_face_up() -> bool:
	return _is_face_up

## 设置卡牌的高亮状态。
## 子类可以重写此方法以实现自定义高亮效果 (例如Shader)。
func set_highlight(is_highlighted: bool):
	if is_instance_valid(_highlight_node):
		_highlight_node.visible = is_highlighted

## 设置卡牌是否正面朝上，可以选择是否播放动画。
func set_face_up(is_up: bool, animate: bool = true):
	# 如果状态没有变化，则不做任何事
	if is_up == _is_face_up:
		return
		
	_is_face_up = is_up
	
	if animate and flip_animation_type != FlipAnimation.INSTANT:
		_animate_flip(_is_face_up)
	else:
		_set_nodes_visibility()

#=============================================================================
# 6. 私有/内部方法 (Internal Methods)
#=============================================================================

## 立即设置正面和背面节点的可见性。
func _set_nodes_visibility():
	if is_instance_valid(_front_node):
		_front_node.visible = _is_face_up
	if is_instance_valid(_back_node):
		_back_node.visible = not _is_face_up


## 执行翻面动画。
func _animate_flip(to_face_up: bool):
	# 如果上一个动画正在播放，则杀死它以开始新的动画
	if _tween and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween().set_parallel()

	var node_to_hide = _back_node if to_face_up else _front_node
	var node_to_show = _front_node if to_face_up else _back_node
	
	match flip_animation_type:
		FlipAnimation.FADE:
			# 淡出当前显示的节点
			_tween.tween_property(node_to_hide, "modulate:a", 0.0, flip_duration / 2.0)
			# 在动画中点，切换可见性并开始淡入新节点
			_tween.tween_callback(_set_nodes_visibility)
			_tween.tween_property(node_to_show, "modulate:a", 1.0, flip_duration / 2.0).from(0.0)

		FlipAnimation.SHRINK:
			# 水平缩小当前显示的节点
			_tween.tween_property(node_to_hide, "scale:x", 0.0, flip_duration / 2.0)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			
			# 在动画中点，切换可见性
			_tween.tween_callback(_set_nodes_visibility)
			_tween.tween_callback(func(): node_to_hide.scale.x = 1.0)
			
			# 将新显示的节点从水平缩放0放大回1
			node_to_show.scale.x = 0.0 # 确保起始缩放为0
			_tween.tween_property(node_to_show, "scale:x", 1.0, flip_duration / 2.0)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
