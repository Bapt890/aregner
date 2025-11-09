extends Sprite2D

# Manages if the spider can be seen by NPC. Invisible if 1 or higher.
var safe_zone_count : int = 0

func _process(_delta):
	if Globals.current_object != "none" or safe_zone_count >= 1:
		$Area2D.set_deferred("monitorable", false) 
		await get_tree().process_frame
		$Area2D.hide()
	elif safe_zone_count <= 0:
		$Area2D.set_deferred("monitorable", true) 
		await get_tree().process_frame
		$Area2D.show()

func _on_area_2d_area_entered(area):
	# If safe zone, spiders cannot be seen
	if area.is_in_group("safezone"): safe_zone_count += 1

func _on_area_2d_area_exited(area):
	# If safe zone, if there is no safe zone, makes spiders visible again
	if area.is_in_group("safezone"): safe_zone_count -= 1
