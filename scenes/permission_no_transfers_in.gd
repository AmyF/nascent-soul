# Permission_NoTransfersIn.gd
class_name Permission_NoTransfersIn
extends ZonePermission

## 这个权限模块的规则是：
## 1. 允许通过 add_item() 添加对象（继承基类行为）。
## 2. 明确【禁止】任何从其他Zone通过 transfer_item_to() 移入的对象。

# 我们只重写 can_transfer_in 方法
func can_transfer_in(item: Control, from_zone: Zone, target_zone: Zone) -> bool:
	# 无论什么情况，都直接返回false，阻止任何移入操作。
	return false
