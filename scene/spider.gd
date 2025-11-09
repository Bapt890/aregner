extends Sprite2D

# Manages if the spider can be seen by NPC. Invisible if 1 or higher.
var safe_zone_count : int = 0

func _on_area_2d_area_entered(area):
	if area.is_in_group("safezone"): 
		safe_zone_count += 1
		$Area2D.set_deferred("monitorable", false) 
		print($Area2D.monitorable)

func _on_area_2d_area_exited(area):
	if area.is_in_group("safezone"): 
		safe_zone_count -= 1
		#if safe_zone_count <= 0: $Area2D.monitorable = true
