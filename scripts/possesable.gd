extends Sprite2D

@export var hover_outline_size = 50.0
@export var animation_speed = 5.0
@export var object_name = ""
@export var required_spider = 1

var target_outline: float = 0.0
var current_outline: float = 0.0

func _process(delta):
	current_outline = lerp(current_outline, target_outline, animation_speed * delta)
	material.set_shader_parameter("outline_thickness", current_outline)

func _on_area_2d_mouse_entered() -> void:
	target_outline = hover_outline_size

func _on_area_2d_mouse_exited() -> void:
	target_outline = 0.0

func _on_area_2d_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton:
		SignalBus.possess.emit(object_name, global_position)
