extends Node

signal timer_changed(time_remaining)

var current_object = "none"
var pnj1_fear = 0
var pnj2_fear = 0
var max_fear = 100
var fear = 0
var pnj1_active = true
var pnj2_active = false


var table_pnj1 = {
	"TV": "faible",
	"Bookshelf": "fort",
	"Lamp": "faible",
	"Pumpkin": "faible",
}

var table_pnj2 = {
	"Bookshelf": "fort",
	"TV": "faible",
	"Pumpkin": "fort",
	"Lamp": "fort",
}

var max_time = 180.0
var time_remaining = 180.0

func _ready():
	start_game()
	SignalBus.use.connect(scare)

func _process(delta):
	if time_remaining > 0:
		time_remaining -= delta
		if time_remaining <= 0:
			time_remaining = 0
			_on_game_over()
		emit_signal("timer_changed", time_remaining)

func start_game():
	pnj1_fear = 0
	pnj2_fear = 0
	time_remaining = max_time
	current_object = "none"

func set_current_object(object_name):
	current_object = object_name

func set_pnj_active(pnj_name, active):
	if pnj_name == "pnj1":
		pnj1_active = active
	elif pnj_name == "pnj2":
		pnj2_active = active

func calculate_fear(affinity, level):
	# low + faible = 8
	# low + fort = 20
	# high + faible = 18
	# high + fort = 45
	
	if level == "low":
		if affinity == "faible":
			return 8
		elif affinity == "fort":
			return 20
	elif level == "high":
		if affinity == "faible":
			return 18
		elif affinity == "fort":
			return 45
	
	return 0

func scare(pnj1, level):
	if current_object == "none":
		return
	if pnj1 == false:
		pnj1_active = false
	else:
		pnj1_active = true
	var total_before = pnj1_fear + pnj2_fear
	
	if pnj1_active:
		$fearMale.play()
		var affinity1 = table_pnj1.get(current_object, "none")
		var amount1 = calculate_fear(affinity1, level)
		
		pnj1_fear = min(pnj1_fear + amount1, max_fear)
		
		if pnj1_fear >= max_fear:
			_on_game_over()
			return
	
	if pnj2_active:
		var affinity2 = table_pnj2.get(current_object, "none")
		var amount2 = calculate_fear(affinity2, level)
		
		pnj2_fear = min(pnj2_fear + amount2, max_fear)
		$fearFemale.play()
		if pnj2_fear >= max_fear:
			_on_game_over()
			return
	fear = pnj1_fear + pnj2_fear
	var total_now = pnj1_fear + pnj2_fear
	SignalBus.emit_signal("fear_changed")

func _on_game_over():
	get_tree().change_scene_to_file("res://game_over.tscn")

func _on_victory():
	get_tree().change_scene_to_file("res://victory.tscn")
