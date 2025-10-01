extends Control
class_name Card

signal flipped(is_face_up: bool)

@export var is_face_up: bool = true
@export var flip_duration: float = 0.3

@onready var card_front: Control = $CardFront
@onready var card_back: Control = $CardBack

@export var interaction_component: InteractionComponent

func _ready() -> void:
	if not interaction_component:
		_create_default_interaction()

	card_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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
	
	pivot_offset = size / 2

	tween.tween_property(self, "scale:x", 0.0, flip_duration / 2)
	tween.tween_callback(_update_card_display)
	tween.tween_property(self, "scale:x", 1.0, flip_duration / 2)


func _create_default_interaction() -> void:
	var component = InteractionComponent.new()
	component.target_control = self
	add_child(component)
	
	component.clicked.connect(_on_card_clicked)
	component.double_clicked.connect(_on_card_double_clicked)
	component.drag_started.connect(_on_card_drag_started)
	component.drag_ended.connect(_on_card_drag_ended)
	component.dragging.connect(_on_card_dragging)
	interaction_component = component


# 信号回调

func _on_card_clicked() -> void:
	pass


func _on_card_double_clicked() -> void:
	pass


func _on_card_drag_started() -> void:
	pass


func _on_card_drag_ended() -> void:
	pass


func _on_card_dragging(delta_position: Vector2) -> void:
	pass
