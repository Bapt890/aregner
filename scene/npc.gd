extends Node2D

# Minimal patrol:
# - Put Marker2D children under route_parent in order.
# - Metadata on each Marker2D:
#     wait          -> number of seconds to pause on arrival (default 0)
#     arrive_orient -> "UPLEFT" | "UPRIGHT" | "DOWNLEFT" | "DOWNRIGHT" or 0..3

enum State { IDLE, WALK }
enum Orientation { UPLEFT, UPRIGHT, DOWNLEFT, DOWNRIGHT }

@export_enum("Male:1", "Female:2") var id_pnj = 1
@export var speed = 300.0
@export var route_parent: Node2D

var _markers = []       # Marker2D[]
var _idx = 0
var _state = State.IDLE
var _orientation = Orientation.UPLEFT
var _tween = null

func _ready():
	_collect_markers()
	if _markers.size() == 0:
		push_warning("No Marker2D found under 'route_parent'.")
		return
	global_position = _markers[0].global_position
	if _markers.size() > 1:
		_go_to(1)  # start heading to the second point

func _process(delta):
	if _state == State.WALK and _markers.size() > 0:
		var to_pos = _markers[_idx].global_position
		var dir = to_pos - global_position
		_update_orientation_from_vector(dir)
		_update_animation()

func _collect_markers():
	_markers.clear()
	if route_parent:
		for c in route_parent.get_children():
			if c is Marker2D:
				_markers.append(c)

func _go_to(next_index):
	if _markers.size() < 2:
		return
	_idx = next_index % _markers.size()
	var to_pos = _markers[_idx].global_position
	var dist = global_position.distance_to(to_pos)
	var dur = 0.0001
	if dist > 0.0:
		dur = dist / speed

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_state = State.WALK
	_update_animation()
	_tween.tween_property(self, "global_position", to_pos, dur)
	_tween.finished.connect(func(): _on_arrive())

func _on_arrive():
	_state = State.IDLE
	_update_animation()

	# Read arrival metadata on the current marker
	var m = _markers[_idx]
	var wait_sec = 0.0
	if m.has_meta("wait"):
		var mw = m.get_meta("wait")
		if typeof(mw) == TYPE_FLOAT or typeof(mw) == TYPE_INT:
			wait_sec = max(0.0, float(mw))
		elif typeof(mw) == TYPE_STRING:
			var parsed = String(mw).to_float()
			if parsed == parsed:
				wait_sec = max(0.0, parsed)

	if m.has_meta("arrive_orient"):
		var o = _parse_orient(m.get_meta("arrive_orient"))
		if o != -1:
			_orientation = o
			_update_animation()

	if wait_sec > 0.0:
		await get_tree().create_timer(wait_sec).timeout

	_go_to(_idx + 1) # simple loop

func _update_orientation_from_vector(v):
	# 4-way facing based on direction
	if v.y < 0:
		if v.x < 0:
			_orientation = Orientation.UPLEFT
		else:
			_orientation = Orientation.UPRIGHT
	else:
		if v.x < 0:
			_orientation = Orientation.DOWNLEFT
		else:
			_orientation = Orientation.DOWNRIGHT

func _parse_orient(val):
	if typeof(val) == TYPE_INT:
		var oi = int(val)
		if oi >= 0 and oi <= 3:
			return oi
	elif typeof(val) == TYPE_STRING:
		var s = String(val).to_upper()
		if s == "UPLEFT": return Orientation.UPLEFT
		if s == "UPRIGHT": return Orientation.UPRIGHT
		if s == "DOWNLEFT": return Orientation.DOWNLEFT
		if s == "DOWNRIGHT": return Orientation.DOWNRIGHT
	return -1

func _update_animation():
	var prefix = "fe" if id_pnj == 2 else ""
	match _orientation:
		Orientation.UPLEFT:
			_change_sprite("res://assets/npc/%smale_walk_back.png" % prefix, "res://assets/npc/%smale_idle_back.png" % prefix)
			$Sprite2D.flip_h = true
		Orientation.UPRIGHT:
			_change_sprite("res://assets/npc/%smale_walk_back.png" % prefix, "res://assets/npc/%smale_idle_back.png" % prefix)
			$Sprite2D.flip_h = false
		Orientation.DOWNLEFT:
			_change_sprite("res://assets/npc/%smale_walk_front.png" % prefix, "res://assets/npc/%smale_idle_front.png" % prefix)
			$Sprite2D.flip_h = false
		Orientation.DOWNRIGHT:
			_change_sprite("res://assets/npc/%smale_walk_front.png" % prefix, "res://assets/npc/%smale_idle_front.png" % prefix)
			$Sprite2D.flip_h = true

func _change_sprite(walk, idle):
	if _state == State.WALK:
		$Sprite2D.hframes = 4
		$Sprite2D.texture = load(walk)
		if not $AnimationPlayer.is_playing():
			$AnimationPlayer.play()
	else:
		$Sprite2D.hframes = 1
		$Sprite2D.texture = load(idle)
		if $AnimationPlayer.is_playing():
			$AnimationPlayer.stop()
