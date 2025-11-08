extends Node2D

enum State {IDLE, WALK, INSPECT, CALL, TRAPPED}
enum Direction {UPLEFT, UPRIGHT, DOWNLEFT, DOWNRIGHT}

const speed = 1000
# The destination to go to
@export var target : Destination = null
var current_destination : Destination = null
# Objects in FOV
var sighted_objects : Array
# Used for State Base Machine
var current_state = State.IDLE
var current_direction = Direction.UPLEFT
# Used to check movement
var previous_pos : Vector2 = Vector2.ZERO
var doing_job: bool = false

func _process(delta):
	match current_state:
		State.WALK:
			if position.distance_to(previous_pos) <= 0.01 * delta: 
				# Stopped moving
				# Pauses according to reached destination
				if target.cause_stop: 
					current_destination = target
					target = null
					doing_job = true
					current_state = State.IDLE
				# Gives new destination
				else: 
					current_destination = target
					target = target.get_random_destination()
					current_direction = current_destination.get_direction(target)
					go_to()
			previous_pos = position
		State.IDLE:
			# Stops to do its job, if any
			if doing_job:
				doing_job = false
				current_direction = current_destination.get_job_orientation()
				current_destination.start_job()
				await current_destination.end_job
				target = current_destination.get_random_destination()
				current_direction = current_destination.get_direction(target)
			# If it has a target, goes to it
			elif target: go_to()
	match current_direction:
		Direction.UPLEFT: $SightArea/CollisionPolygon2D.rotation_degrees = 135
		Direction.UPRIGHT: $SightArea/CollisionPolygon2D.rotation_degrees = 225
		Direction.DOWNLEFT: $SightArea/CollisionPolygon2D.rotation_degrees = 45
		Direction.DOWNRIGHT: $SightArea/CollisionPolygon2D.rotation_degrees = 315

func wait_job():
	target.start_job()
	await target.end_job
	target = target.get_random_destination()

func go_to():
	var tween = create_tween()
	tween.tween_property(self, "position", target.position, position.distance_to(target.position) / speed)
	target.set_coming_destination(current_destination)
	if current_destination: current_destination.set_coming_destination(null)
	current_state = State.WALK

#func _physics_process(delta):
	#var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#velocity = cartesian_to_isometric(direction * 10000 * delta)
	#move_and_slide()
	#
#func cartesian_to_isometric(cartesian):
	#var screen_pos = Vector2()
	#screen_pos.x = cartesian.x - cartesian.y
	#screen_pos.y = cartesian.x / 2 + cartesian.y / 2
	#return screen_pos
