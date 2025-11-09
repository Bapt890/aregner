extends Node2D

enum State {IDLE, WALK, INSPECT, CALL, TRAPPED}
enum Orientation {UPLEFT, UPRIGHT, DOWNLEFT, DOWNRIGHT}

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

func _process(delta):
	if spider_sighted >= 1:
		tween.stop()
		current_state = State.CALL
	match current_state:
		State.WALK:
			if position.distance_to(previous_pos) <= 0.01 * delta: 
				# Stopped moving
				# Pauses according to reached destination
				if target.cause_stop: 
					current_destination = target
					current_orientation = current_destination.orientation as Orientation
					target = null
					doing_job = true
					current_state = State.IDLE
				# Gives new destination
				else: 
					current_destination = target
					target = target.get_random_destination()
					current_orientation = current_destination.get_path_orientation() as Orientation
					go_to()
			previous_pos = position
		State.IDLE:
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
			position = position
			#if $Timer.is_stopped(): $Timer.start()
			#await $Timer.timeout
			#Globals._on_game_over()
	match current_orientation:
		Orientation.UPLEFT: $SightArea/Polygon2D.rotation_degrees = 135
		Orientation.UPRIGHT: $SightArea/Polygon2D.rotation_degrees = 225
		Orientation.DOWNLEFT: $SightArea/Polygon2D.rotation_degrees = 45
		Orientation.DOWNRIGHT: $SightArea/Polygon2D.rotation_degrees = 315

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
