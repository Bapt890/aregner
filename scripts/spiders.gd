extends CharacterBody2D

@export var move_speed = 300.0
@export var jump_height = 100.0
@export var jump_duration = 0.5
@export var use_cooldown = 0.3

@onready var move_sound: AudioStreamPlayer = $MoveSound
@onready var jump_sound: AudioStreamPlayer = $JumpSound

var target = Vector2.ZERO
var last_use_time = -999.0
var is_jumping = false
var jump_progress = 0.0
var jump_start = Vector2.ZERO
var jump_end = Vector2.ZERO
var return_position = Vector2.ZERO

func _ready():
	SignalBus.possess.connect(_on_possess)
	SignalBus.use.connect(_on_use)

func _process(delta):
	if Input.is_action_just_pressed("use"):
		SignalBus.emit_signal("use", "low")
	elif Input.is_action_just_pressed("use_strong"):
		SignalBus.emit_signal("use", "high")
	
	if is_jumping:
		jump_progress += delta / jump_duration
		
		if jump_progress >= 1.0:
			global_position = jump_end
			target = jump_end
			is_jumping = false
		else:
			var t = jump_progress
			var base_pos = jump_start.lerp(jump_end, t)
			var arc = sin(t * PI) * jump_height
			global_position = base_pos + Vector2(0, -arc)
	else:
		var distance = global_position.distance_to(target)
		if distance > 1.0:
			velocity = (target - global_position).normalized() * move_speed
			move_and_slide()
			
			if not move_sound.playing:
				move_sound.play()
		else:
			velocity = Vector2.ZERO
			if move_sound.playing:
				move_sound.stop()

func _on_possess(object: String, pos: Vector2):
	if object != "none":
		return_position = global_position
		is_jumping = true
		jump_progress = 0.0
		jump_start = global_position
		jump_end = pos
		if jump_sound:
			jump_sound.play()
	else:
		target = pos

func _on_use(_intensity: String):
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_use_time < use_cooldown:
		return
	last_use_time = current_time
	
	is_jumping = true
	jump_progress = 0.0
	jump_start = global_position
	jump_end = return_position

func _on_move_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		_on_possess("none", get_global_mouse_position())
		Globals.current_object = "none"
