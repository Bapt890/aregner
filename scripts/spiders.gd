extends Node2D

@onready var spider = preload("res://scene/spider.tscn")

@export var spider_count = 30
@export var move_speed = 300.0
@export var base_spread = 50.0
@export var spider_scale = 1.0
@export var scale_variation = 0.2
@export var color_variation = 0.15
@export var flip_change_interval = 2.0
@export var jump_height = 100.0
@export var jump_duration = 0.5
@export var use_cooldown = 0.3
@export var use_duration = 1
@export var spritesheet: Texture2D
@export var move_sound: AudioStreamPlayer
@export var jump_sound: AudioStreamPlayer

const SPRITE_WIDTH = 96
const SPRITE_HEIGHT = 78
const FRAMES_PER_DIRECTION = 3
const ANIMATION_SPEED = 0.15

var spider_sprites = []
var positions = []
var delays = []
var targets = []
var jump_progress = []
var jump_start_pos = []
var is_jumping = []
var eject_positions = []
var sprite_frames = []
var frame_timers = []
var facing_left = []
var spider_scales = []
var flip_timers = []

var last_use_time = -999.0

func _ready():
	SignalBus.possess.connect(_on_possess)
	SignalBus.fear_changed.connect(update_spider_count)
	SignalBus.use.connect(_on_use)
	
	_initialize_spiders(spider_count)

func _initialize_spiders(count: int):
	for i in count:
		var sprite = spider.instantiate()
		sprite.texture = spritesheet
		sprite.hframes = 6
		sprite.vframes = 1
		sprite.centered = true
		
		#var color_shift = randf_range(-color_variation, color_variation)
		sprite.modulate = Color(
			1.0 + randf_range(-color_variation, color_variation),
			1.0 + randf_range(-color_variation, color_variation),
			1.0 + randf_range(-color_variation, color_variation),
			1.0
		)
		
		add_child(sprite)
		spider_sprites.append(sprite)
		positions.append(Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread())))
		delays.append(0.0)
		targets.append(Vector2.ZERO)
		jump_progress.append(0.0)
		jump_start_pos.append(Vector2.ZERO)
		is_jumping.append(false)
		eject_positions.append(Vector2.ZERO)
		
		var is_left = randf() > 0.5
		facing_left.append(is_left)
		sprite_frames.append(randi() % FRAMES_PER_DIRECTION)
		frame_timers.append(randf() * ANIMATION_SPEED)
		
		var scale_factor = spider_scale * randf_range(1.0 - scale_variation, 1.0 + scale_variation)
		spider_scales.append(scale_factor)
		
		sprite.flip_h = randf() > 0.5
		
		flip_timers.append(randf() * flip_change_interval)
		
		_update_visual(i)

func _process(delta: float):
	if Input.is_action_just_pressed("use"):
		SignalBus.emit_signal("use", "low")
	elif Input.is_action_just_pressed("use_strong"):
		SignalBus.emit_signal("use", "high")
	
	var all_finished = true
	
	for i in spider_count:
		delays[i] = max(0, delays[i] - delta)
		
		flip_timers[i] += delta
		if flip_timers[i] >= flip_change_interval:
			flip_timers[i] = 0.0
			spider_sprites[i].flip_h = randf() > 0.5
		
		var is_moving = false
		
		if delays[i] == 0:
			if is_jumping[i]:
				jump_progress[i] += delta / jump_duration
				
				if jump_progress[i] >= 1.0:
					jump_progress[i] = 1.0
					positions[i] = targets[i]
					is_jumping[i] = false
				else:
					all_finished = false
					is_moving = true
					var t = jump_progress[i]
					var new_pos = jump_start_pos[i].lerp(targets[i], t)
					
					if new_pos.x < positions[i].x:
						facing_left[i] = true
					elif new_pos.x > positions[i].x:
						facing_left[i] = false
					
					positions[i] = new_pos
					var jump_offset = sin(t * PI) * jump_height
					positions[i].y -= jump_offset
			else:
				var distance = positions[i].distance_to(targets[i])
				if distance > 1.0:
					all_finished = false
					is_moving = true
					
					var direction = targets[i] - positions[i]
					if direction.x < 0:
						facing_left[i] = true
					elif direction.x > 0:
						facing_left[i] = false
					
					positions[i] = positions[i].move_toward(targets[i], move_speed * delta)
		else:
			all_finished = false
		
		if is_moving:
			frame_timers[i] += delta
			if frame_timers[i] >= ANIMATION_SPEED:
				frame_timers[i] = 0.0
				sprite_frames[i] = (sprite_frames[i] + 1) % FRAMES_PER_DIRECTION
		
		_update_visual(i)
	
	if all_finished and move_sound and move_sound.playing:
		move_sound.stop()

func _update_visual(i: int):
	if i >= spider_sprites.size():
		return
	
	var sprite = spider_sprites[i]
	sprite.position = positions[i]
	sprite.scale = Vector2(spider_scales[i], spider_scales[i])
	
	var frame_offset = 0 if not facing_left[i] else FRAMES_PER_DIRECTION
	sprite.frame = frame_offset + sprite_frames[i]

func _on_possess(object: String, pos: Vector2) -> void:
	var use_jump = (object != "none")
	if move_sound:
		move_sound.play()
	
	for i in spider_count:
		delays[i] = randf() * 0.5
		targets[i] = pos + Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread()))
		
		if use_jump:
			if jump_sound and i == 0:
				jump_sound.play()
			is_jumping[i] = true
			jump_progress[i] = 0.0
			jump_start_pos[i] = positions[i]
			eject_positions[i] = positions[i]
		else:
			is_jumping[i] = false

func _on_use(_intensity: String) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_use_time < use_cooldown:
		return
	last_use_time = current_time
	
	for i in spider_count:
		if not is_jumping[i] or jump_progress[i] > 0.7:
			delays[i] = randf() * 0.5
			targets[i] = eject_positions[i] + Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread()))
			is_jumping[i] = true
			jump_progress[i] = 0.0
			jump_start_pos[i] = positions[i]

func _get_spread() -> float:
	return base_spread * sqrt(spider_count / 30.0)

func update_spider_count():
	var old_count = spider_count
	var new_count = Globals.fear/4
	spider_count = new_count
	
	if new_count > old_count:
		_initialize_spiders(new_count - old_count)


func _on_move_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		_on_possess("none", get_global_mouse_position())
		Globals.current_object = "none"
