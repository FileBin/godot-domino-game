extends Control

@export var initial_size = size

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * .5;

		var children2d: Array[Node2D] = []
		children2d.assign(get_children())
		
		for c in children2d:
			c.position = size * .5
			var factor2d = size / initial_size
			var factor = max(factor2d.x, factor2d.y)

			c.scale = Vector2.ONE * factor
