extends Node2D


func _on_texture_rect_2_pressed() -> void:
	$TextureRect2.visible = false


func _on_start_2_pressed() -> void:
	$TextureRect2.visible = true



func _on_button_pressed() -> void:
	pass # Replace with function body.


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_Texture_rect3_pressed() -> void:
	$TextureRect3.visible = false

func _on_controles_pressed() -> void:
	$TextureRect3.visible = true
