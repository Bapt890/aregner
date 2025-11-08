extends MultiMeshInstance2D
@export var spider_count = 30
@export var move_speed = 300.0
@export var base_spread = 50.0
@export var spider_scale = 30.0
@export var jump_height = 100.0
@export var jump_duration = 0.5
@export var use_cooldown = 0.3
@export var use_duration = 1
# Chaque index = une araignée
var positions = []
var delays = []
var targets = []
var jump_progress = []
var jump_start_pos = []
var is_jumping = []
var eject_positions = []
var last_use_time = -999.0

func _ready():
	SignalBus.possess.connect(_on_possess)
	SignalBus.fear_changed.connect(update_spider_count)
	SignalBus.use.connect(_on_use)
	for i in spider_count:
		positions.append(Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread())))
		delays.append(0.0)
		targets.append(Vector2.ZERO)
		jump_progress.append(0.0)
		jump_start_pos.append(Vector2.ZERO)
		is_jumping.append(false)
		eject_positions.append(Vector2.ZERO)
		_update_visual(i)

func _process(delta: float):
	if Input.is_action_pressed("use"):
			SignalBus.emit_signal("use", "low")
	await get_tree().create_timer(use_duration).timeout
	for i in spider_count:
		delays[i] = max(0, delays[i] - delta)
		
		if delays[i] == 0:
			if is_jumping[i]:
				jump_progress[i] += delta / jump_duration
				
				if jump_progress[i] >= 1.0:
					jump_progress[i] = 1.0
					positions[i] = targets[i]
					is_jumping[i] = false
				else:
					var t = jump_progress[i]
					positions[i] = jump_start_pos[i].lerp(targets[i], t)
					
					var jump_offset = sin(t * PI) * jump_height
					positions[i].y -= jump_offset
			else:
				# Mouvement classique
				positions[i] = positions[i].move_toward(targets[i], move_speed * delta)
		
		_update_visual(i)

func _update_visual(i: int):
	var transform = Transform2D(0, Vector2(spider_scale, -spider_scale), 0, positions[i])
	multimesh.set_instance_transform_2d(i, transform)
	
func _on_possess(object: String, pos: Vector2) -> void:
	var use_jump = (object != "none")
	
	for i in spider_count:
		delays[i] = randf() * 0.5
		targets[i] = pos + Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread()))
		
		if use_jump:
			is_jumping[i] = true
			jump_progress[i] = 0.0
			jump_start_pos[i] = positions[i]
			eject_positions[i] = positions[i]
		else:
			is_jumping[i] = false

func _on_use(intensity: String) -> void:
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
	var new_count = Globals.fear
	spider_count = new_count
	multimesh.instance_count = new_count
	
	if new_count > old_count:
		for i in range(old_count, new_count):
			positions.append(Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread())))
			delays.append(0.0)
			targets.append(Vector2.ZERO)
			jump_progress.append(0.0)
			jump_start_pos.append(Vector2.ZERO)
			is_jumping.append(false)
			eject_positions.append(Vector2.ZERO)
			_update_visual(i)
	else:
		# On a pas prévu de baisser le nombre d'araignés
		positions.resize(new_count)
		delays.resize(new_count)
		targets.resize(new_count)
		jump_progress.resize(new_count)
		jump_start_pos.resize(new_count)
		is_jumping.resize(new_count)
		eject_positions.resize(new_count)

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		_on_possess("none", get_global_mouse_position())
