extends Node2D

class_name Destination

# Stops the NPC
@export var cause_stop: bool = false
# Stops for how long ?
@export var stop_duration: int = 0
# Where do the NPC look ?
@export_enum("Up Left", "Up Right", "Down Left", "Down Right") var orientation: int
# Where do the NPC look when going to a new destination ?
@export var linked_destinations : Array[Destination]
# Last chosen destination, avoid immediate backtracking
@export_enum("Up Left", "Up Right", "Down Left", "Down Right") var destination_orientation: Array[int]
# Used for room transition
@export var teleport_destination : Destination = null
# The orientation of the NPC when changing room
@export_enum("Up Left", "Up Right", "Down Left", "Down Right") var teleport_orientation : int
# Array of linked destinations
var last_destination : Destination = null
# Used for associating the destination path and the associated orientation
var current_slot : int = 0

signal end_job()

# Sets up the timer
func _ready(): 
	if cause_stop: $Timer.wait_time = float(stop_duration)

func get_random_destination() -> Destination:
	# Get a random linked destination
	var new_dest = linked_destinations[randi_range(0, linked_destinations.size()-1)]
	# If this new destination is equal to the last one chosen, except if there is only one linked one, redo it
	while new_dest == last_destination and linked_destinations.size() > 1:
		new_dest = linked_destinations[randi_range(0, linked_destinations.size()-1)]
	current_slot = linked_destinations.find(new_dest)
	return new_dest

func get_path_orientation() -> int:
	return destination_orientation[current_slot]

func set_coming_destination(dest : Destination): last_destination = dest

func start_job(): if $Timer.is_stopped(): $Timer.start()

func _on_timer_timeout(): emit_signal("end_job")
