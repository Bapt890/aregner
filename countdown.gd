extends Label

@export var time_left = 180.0

func _process(delta: float) -> void:
	time_left -= delta
	if time_left < 0:
		time_left = 0

	var m = int(time_left) / 60
	var s = int(time_left) % 60
	text = "%02d:%02d" % [m, s]
