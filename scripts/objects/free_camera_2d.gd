extends Camera2D

@export_group("Movement")
@export var zoom_speed : float = 0.1
@export var max_zoom : float = 5.0

func _unhandled_input(event):
	# Panning: Detect Mouse Motion while Middle Mouse Button is pressed
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			# Move the camera relative to mouse movement and current zoom
			global_position -= event.relative * (1 / zoom.x)

	# Zooming: Detect Scroll Wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(1.0 - zoom_speed)

func zoom_camera(factor: float):
	var new_zoom = min(zoom.x * factor, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)