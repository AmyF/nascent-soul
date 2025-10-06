# ZoneAnimator.gd
class_name ZoneAnimator
extends Resource

## ZoneAnimator 负责编排Zone内对象在布局变化时的动画过渡。
## 它将动画的时长、曲线、交错效果等视觉表现逻辑从 Zone 中分离出来，
## 使其成为一个可配置、可替换的模块。

#=============================================================================
# 1. 导出属性 (Inspector配置)
#=============================================================================

@export_group("Timing")
## 动画的基础时长（秒）。
@export_range(0.0, 2.0, 0.01) var duration: float = 0.3
## 相邻两个对象开始动画之间的交错延迟时间（秒）。
## 0 表示所有对象同时开始动画。
@export_range(0.0, 0.5, 0.01) var stagger_delay: float = 0.05

@export_group("Curve")
## 动画的过渡类型 (例如: Linear, Sine, Elastic, Bounce)。
@export var transition_type: Tween.TransitionType = Tween.TRANS_SINE
## 动画的缓动类型 (例如: In, Out, In-Out)。
@export var ease_type: Tween.EaseType = Tween.EASE_OUT


#=============================================================================
# 2. 核心方法 (由Zone调用)
#=============================================================================

## 执行动画编排
func animate(tween: Tween, final_transforms: Dictionary):
	var delay = 0.0
	
	for item in final_transforms.keys():
		var to_transform = final_transforms[item]

		# 确保所有动画属性都从正确的起点开始
		# 注意：我们不再使用 .from()，因为 from_transform 可能不存在（新加入的item）
		# 我们在Zone中直接设置item的初始状态，然后tween到最终状态
		
		# 为每个属性创建补间动画
		if to_transform.has("position"):
			var prop_tween = tween.tween_property(item, "position", to_transform.position, duration)
			prop_tween.set_delay(delay)
			prop_tween.set_trans(transition_type)
			prop_tween.set_ease(ease_type)

		if to_transform.has("rotation_degrees"):
			var prop_tween = tween.tween_property(item, "rotation_degrees", to_transform.rotation_degrees, duration)
			prop_tween.set_delay(delay)
			prop_tween.set_trans(transition_type)
			prop_tween.set_ease(ease_type)

		if to_transform.has("scale"):
			var prop_tween = tween.tween_property(item, "scale", to_transform.scale, duration)
			prop_tween.set_delay(delay)
			prop_tween.set_trans(transition_type)
			prop_tween.set_ease(ease_type)
		
		# 增加下一个item的延迟
		delay += stagger_delay