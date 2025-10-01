extends Control
class_name Card

signal flipped(is_face_up: bool)

@export var is_face_up: bool = true
@export var flip_duration: float = 0.3

@onready var card_front: Control = $CardFront
@onready var card_back: Control = $CardBack

func _ready() -> void:
	_update_card_display()


func flip(animate: bool = true) -> void:
	is_face_up = !is_face_up
	
	if animate:
		_animate_flip()
	else:
		_update_card_display()
		
	flipped.emit(is_face_up)


func set_face_up(face_up: bool, animate: bool = true) -> void:
	if is_face_up == face_up:
		return
		
	is_face_up = face_up
	
	if animate:
		_animate_flip()
	else:
		_update_card_display()
		
	flipped.emit(is_face_up)


func _update_card_display() -> void:
	if card_front:
		card_front.visible = is_face_up
	if card_back:
		card_back.visible = !is_face_up


func _animate_flip() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "scale:x", 0.0, flip_duration / 2)
	tween.tween_property(self, "scale:x", 1.0, flip_duration / 2)
