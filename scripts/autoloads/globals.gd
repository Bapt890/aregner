extends Node

signal fear_changed(current, change)
signal panic_triggered
var current_object = "none"
var fear = 0
var max_fear = 100
var panic_limit = 30

func _ready():
	start_game()

func start_game():
	fear = 0
	emit_signal("fear_changed", fear, 0)

func add_fear(amount):
	fear += amount
	if fear > max_fear:
		fear = max_fear
	if fear < 0:
		fear = 0

	if amount >= panic_limit:
		_on_game_over()

	SignalBus.emit_signal("fear_changed")

func _on_game_over():
	get_tree().change_scene_to_file("res://game_over.tscn")
