extends MultiMeshInstance2D

@export var spider_count = 30
@export var move_speed = 300.0
@export var base_spread = 50.0
@export var spider_scale = 30.0

var positions = []
var delays = []
var targets = []

func _ready():
	SignalBus.possess.connect(_on_possess)
	for i in spider_count:
		positions.append(Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread())))
		delays.append(0.0)
		targets.append(Vector2.ZERO)
		_update_visual(i)

func _process(delta: float):
	for i in spider_count:
		delays[i] = max(0, delays[i] - delta)
		if delays[i] == 0:
			positions[i] = positions[i].move_toward(targets[i], move_speed * delta)
		_update_visual(i)

func _update_visual(i: int):
	var transform = Transform2D(0, Vector2(spider_scale, -spider_scale), 0, positions[i])
	multimesh.set_instance_transform_2d(i, transform)
	
func _on_possess(object: String, pos: Vector2) -> void:
	for i in spider_count:
		delays[i] = randf() * 0.5
		targets[i] = pos + Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread()))

func _get_spread() -> float:
	return base_spread * sqrt(spider_count / 30.0)

func update_spider_count(new_count: int):
	var old_count = spider_count
	spider_count = new_count
	multimesh.instance_count = new_count
	
	if new_count > old_count:
		for i in range(old_count, new_count):
			positions.append(Vector2(randf_range(-_get_spread(), _get_spread()), randf_range(-_get_spread(), _get_spread())))
			delays.append(0.0)
			targets.append(Vector2.ZERO)
			_update_visual(i)
	else:
		# On a pas prévu de baisser le nombre d'araignés
		positions.resize(new_count)
		delays.resize(new_count)
		targets.resize(new_count)
