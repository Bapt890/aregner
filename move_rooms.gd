extends Node2D

@onready var camera: Camera2D = $"../Camera"
@onready var button_left: TextureButton = $"../CanvasLayer/ButtonLeft"
@onready var button_right: TextureButton = $"../CanvasLayer/ButtonRight"

enum CameraState { LEFT, MIDDLE, RIGHT }
var current_state: CameraState = CameraState.MIDDLE
var is_tweening: bool = false

const POSITION_LEFT: float = -1920.0
const POSITION_MIDDLE: float = 0.0
const POSITION_RIGHT: float = 1920.0

func _ready() -> void:
	update_button_visibility()

func _on_button_left_pressed() -> void:
	if is_tweening:
		return
	
	match current_state:
		CameraState.MIDDLE: move_camera_to(POSITION_LEFT, CameraState.LEFT)
		CameraState.RIGHT: move_camera_to(POSITION_MIDDLE, CameraState.MIDDLE)
		CameraState.LEFT: move_camera_to(POSITION_RIGHT, CameraState.RIGHT)

func _on_button_right_pressed() -> void:
	if is_tweening:
		return
	
	match current_state:
		CameraState.LEFT: move_camera_to(POSITION_MIDDLE, CameraState.MIDDLE)
		CameraState.MIDDLE: move_camera_to(POSITION_RIGHT, CameraState.RIGHT)
		CameraState.RIGHT: move_camera_to(POSITION_LEFT, CameraState.LEFT)

func move_camera_to(target_x: float, new_state: CameraState) -> void:
	is_tweening = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(camera, "position:x", target_x, 0.5)
	tween.tween_callback(on_tween_completed.bind(new_state))

func on_tween_completed(new_state: CameraState) -> void:
	current_state = new_state
	is_tweening = false
	update_button_visibility()

func update_button_visibility() -> void:
	pass
	#match current_state:
		#CameraState.LEFT:
			#button_left.visible = false
			#button_right.visible = true
		#CameraState.MIDDLE:
			#button_left.visible = true
			#button_right.visible = true
		#CameraState.RIGHT:
			#button_left.visible = true
			#button_right.visible = false
