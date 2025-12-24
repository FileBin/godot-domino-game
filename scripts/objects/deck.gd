extends Container

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		var children: Array[Control] = []
		children.assign(get_children())
		var step = 1./len(children)
		var pos = .0
		for c in children:
			var size_fac = size.y / c.size.y
			c.size *= size_fac
			c.position = Vector2(pos * size.x + (step*size.x - c.size.x)*.5, 0)
			pos+=step
