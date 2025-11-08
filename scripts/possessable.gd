extends AnimatedSprite2D

@export var hover_strength_size = 0.8
@export var animation_speed = 5.0
@export var object_name = ""
@export var required_spider = 1

@export var shake_time = 0.3
@export var shake_strength = 10.0
@export var shake_angle = 0.07
@export var shake_steps = 6

@export var bounce_scale = 1.2
@export var bounce_duration = 0.3

var target_strength = 0.0
var current_strength = 0.0

var base_pos = Vector2.ZERO
var base_rot = 0.0
var shake_tween = null

func _ready():
	var area = $Area2D
	area.mouse_entered.connect(_on_area_2d_mouse_entered)
	area.mouse_exited.connect(_on_area_2d_mouse_exited)
	area.input_event.connect(_on_area_2d_input_event)
	base_pos = position
	base_rot = rotation
	SignalBus.use.connect(on_use)

func _process(delta):
	current_strength = lerp(current_strength, target_strength, animation_speed * delta)
	material.set_shader_parameter("strength", current_strength)

func _on_area_2d_mouse_entered():
	target_strength = hover_strength_size

func _on_area_2d_mouse_exited():
	target_strength = 0.0

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		SignalBus.possess.emit(object_name, global_position)
		Globals.current_object = object_name
		start_bounce()

func on_use(level):
	if Globals.current_object == object_name:
		if level == "low":
			start_shake()
		else:
			self.play("use")
			$UsePlayer.play()
			if has_node("PointLight2D"):
				var point_light = $PointLight2D
				point_light.visible = true
				await self.animation_finished
				point_light.visible = false
		Globals.current_object = "none"

func start_bounce():
	var bounce_tween = create_tween()
	bounce_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(self, "scale", Vector2.ONE * bounce_scale, bounce_duration * 0.5)
	bounce_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(self, "scale", Vector2.ONE, bounce_duration * 0.5)

func start_shake():
	if shake_tween and shake_tween.is_running():
		shake_tween.kill()
	position = base_pos
	rotation = base_rot
	
	shake_tween = create_tween()
	shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var step_time = shake_time / max(1, shake_steps)
	for i in range(shake_steps):
		var off = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		var rot = randf_range(-shake_angle, shake_angle)
		shake_tween.tween_property(self, "position", base_pos + off, step_time * 0.7)
		shake_tween.parallel().tween_property(self, "rotation", rot, step_time * 0.7)
		shake_tween.tween_property(self, "position", base_pos, step_time * 0.3)
		shake_tween.parallel().tween_property(self, "rotation", base_rot, step_time * 0.3)
	
	shake_tween.finished.connect(_on_shake_finished)

func _on_shake_finished():
	position = base_pos
	rotation = base_rot
