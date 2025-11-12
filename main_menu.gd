extends Control

func _slide_in(page):
	var tween = create_tween()
	page.position.y = 1080
	tween.tween_property(page, "position:y", 0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func _slide_out(page: Control):
	var tween = create_tween()
	tween.tween_property(page, "position:y", 1080, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

func _on_credits_pressed() -> void:
	_slide_in($credits)

func _on_close_credits_pressed() -> void:
	_slide_out($credits)

func _on_controls_pressed() -> void:
	_slide_in($controls)

func _on_close_controls_pressed() -> void:
	_slide_out($controls)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
