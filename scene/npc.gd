extends Node2D

enum State {IDLE, WALK, INSPECT, CALL, TRAPPED}
enum Orientation {UPLEFT, UPRIGHT, DOWNLEFT, DOWNRIGHT}
@export_enum("Male:1", "Female:2") var id_pnj = 1
const speed = 1000
# The destination to go to
@export var target : Destination = null
var current_destination : Destination = null
# Objects in FOV
var sighted_objects : Array
# Used for State Base Machine
var current_state = State.IDLE
var current_orientation = Orientation.UPLEFT
# Used to check movement
var previous_pos : Vector2 = Vector2.ZERO
var doing_job: bool = false
var spider_sighted: int = 0
var objects_sighted: Array
# Tween for movement
@onready var tween : Tween = create_tween()
@onready var sight_area: Area2D = $SightArea

func _ready() -> void:
	if id_pnj == 1: sight_area.add_to_group("pnj1")
	else: sight_area.add_to_group("pnj2")
		
func _process(delta):
	# Stops when it sees spiders
	if spider_sighted >= 1:
		tween.stop()
		current_state = State.CALL
	# For sprite changing
	var prefix = "fe" if id_pnj == 2 else ""
	match current_state:
		State.WALK:
			if !$AnimationPlayer.is_playing(): 
				$AnimationPlayer.play()
			if position.distance_to(previous_pos) <= 0.01 * delta: 
				# Stopped moving
				current_destination = target
				# Pauses according to reached destination
				if target.cause_stop: 
					current_orientation = current_destination.orientation as Orientation
					target = null
					doing_job = true
					current_state = State.IDLE
				# Teleports
				#elif target.teleport_destination:
					#global_position = target.teleport_destination.global_position
					#current_orientation = target.teleport_destination.orientation as Orientation
					#target = target.teleport_destination.get_random_destination()
					#current_orientation = current_destination.get_path_orientation() as Orientation
					#go_to()
				# Gives new destination
				else:
					target = target.get_random_destination()
					current_orientation = current_destination.get_path_orientation() as Orientation
					go_to()
			previous_pos = position
		State.IDLE:
			if $AnimationPlayer.is_playing(): 
				$AnimationPlayer.stop()
			# If it does a job, wait for the job to end
			if doing_job:
				doing_job = false
				current_destination.start_job()
				await current_destination.end_job
				target = current_destination.get_random_destination()
				current_orientation = current_destination.get_path_orientation() as Orientation
			# If it has a target, goes to it
			elif target: go_to()
		State.CALL:
			# If calling, you are doomed after the timer
			if $Timer.is_stopped():
				$Timer.start()
				var emote_tween = create_tween()
				$EmoteSprite.show()
				emote_tween.tween_property($EmoteSprite, "position:y", -200, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
				await $Timer.timeout
				Globals._on_game_over()
			#
	match current_orientation:
		Orientation.UPLEFT: 
			$SightArea/Polygon2D.rotation_degrees = 135
			change_sprite("res://assets/npc/%smale_walk_back.png" % prefix, \
				"res://assets/npc/%smale_idle_back.png" % prefix)
			$Sprite2D.flip_h = true
		Orientation.UPRIGHT: 
			$SightArea/Polygon2D.rotation_degrees = 225
			change_sprite("res://assets/npc/%smale_walk_back.png" % prefix, \
				"res://assets/npc/%smale_idle_back.png" % prefix)
			$Sprite2D.flip_h = false
		Orientation.DOWNLEFT: 
			$SightArea/Polygon2D.rotation_degrees = 45
			change_sprite("res://assets/npc/%smale_walk_front.png" % prefix, \
				"res://assets/npc/%smale_idle_front.png" % prefix)
			$Sprite2D.flip_h = false
		Orientation.DOWNRIGHT: 
			$SightArea/Polygon2D.rotation_degrees = 315
			change_sprite("res://assets/npc/%smale_walk_front.png" % prefix, \
				"res://assets/npc/%smale_idle_front.png" % prefix)
			$Sprite2D.flip_h = true

func change_sprite(walk : String, idle : String):
	if current_state == State.WALK:
		$Sprite2D.hframes = 4
		$Sprite2D.texture = load(walk)
	else:
		$Sprite2D.hframes = 1
		$Sprite2D.texture = load(idle)

func wait_job():
	target.start_job()
	await target.end_job
	target = target.get_random_destination()

func go_to():
	tween = create_tween()
	tween.tween_property(self, "position", target.position, position.distance_to(target.position) / speed)
	target.set_coming_destination(current_destination)
	if current_destination: current_destination.set_coming_destination(null)
	current_state = State.WALK

func _on_sight_area_area_entered(area : Area2D):
	if area.is_in_group("player"): 
		spider_sighted += 1
	if area.is_in_group("object"): 
		objects_sighted.append(area)

func _on_sight_area_area_exited(area):
	if area.is_in_group("player"): 
		spider_sighted -= 1
	if area.is_in_group("object"): 
		objects_sighted.erase(area)
