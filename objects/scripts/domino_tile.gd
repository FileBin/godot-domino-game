class_name Domino extends Node2D

@export var top_number = 0
@export var bottom_number = 0
@export var animation_time = 0.5

var DOT_SCENE = preload("res://objects/dot.tscn")

var game: Game

@onready var bounds = $Tile/Control as Control
@onready var tile = $"Tile" as Node2D

signal data_initialized

var tween_hover: Tween
var idle_animation_factor = 0.

func _ready() -> void:
	var zone = bounds.get_rect()

	var top_zone = Rect2(zone.position, zone.size * Vector2(1, 0.5))
	var bottom_zone = Rect2(zone.position + zone.size * Vector2(0, 0.5), zone.size * Vector2(1, 0.5))

	_create_dots(top_number, top_zone)
	_create_dots(bottom_number, bottom_zone)
	
	data_initialized.emit()

func _on_mouse_entered() -> void:
	_hover_enter_tween()

func _on_mouse_exited() -> void:
	_hover_exit_tween()

func _hover_exit_tween() -> void:
	tween_hover = _createTween(tween_hover)

	tween_hover.set_parallel()
	tween_hover.tween_property(animation_target(), "scale", Vector2.ONE, animation_time);
	tween_hover.tween_property(animation_target(), "position", Vector2.ZERO, animation_time)
	if game:
		tween_hover.finished.connect(game.restore_idle_tween)


func _hover_enter_tween() -> void:
	tween_hover = _createTween(tween_hover)

	tween_hover.set_parallel()
	tween_hover.tween_property(animation_target(), "scale", Vector2.ONE * 1.4, animation_time)
	tween_hover.tween_property(animation_target(), "position", Vector2.UP * get_size().y * 0.2, animation_time)
	if game:
		game.stop_idle_tween()
	

func is_hovered():
	return tween_hover and tween_hover.is_running()

func animation_target() -> Node2D:
	return tile

var offset: Vector2;
var initial_position: Vector2;
var is_dragging = false;

func _on_control_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					is_dragging = true
					offset = get_global_mouse_position() - global_position
					initial_position = global_position;
				elif event.is_released():
					global_position = initial_position;
					is_dragging = false

	if event is InputEventMouseMotion:
		if is_dragging:
			global_position = get_global_mouse_position() - offset

func get_tile_number_at(point: Vector2) -> int:
	var localPoint = to_local(point);
	
	if get_top_part().has_point(localPoint):
		return top_number

	if get_bottom_part().has_point(localPoint):
		return bottom_number

	return -1

func is_global_point_in_bounds(global_point: Vector2) -> bool:
	return bounds.get_rect().has_point(to_local(global_point))

func is_point_in_bounds(local_point: Vector2) -> bool:
	return bounds.get_rect().has_point(local_point)

## Utils

const DOMINO_SPREAD_FACTOR = 0.25

const DOT_POSITIONS = {
	1: [Vector2.ZERO],
	2: [Vector2.DOWN + Vector2.LEFT, Vector2.UP + Vector2.RIGHT],
	3: [-Vector2.ONE, Vector2.ZERO, Vector2.ONE],
	4: [Vector2.DOWN + Vector2.LEFT, Vector2.DOWN + Vector2.RIGHT, Vector2.UP + Vector2.RIGHT, Vector2.UP + Vector2.LEFT],
	5: [Vector2.DOWN + Vector2.LEFT, Vector2.DOWN + Vector2.RIGHT, Vector2.ZERO, Vector2.UP + Vector2.RIGHT, Vector2.UP + Vector2.LEFT],
	6: [Vector2.DOWN + Vector2.LEFT, Vector2.LEFT, Vector2.DOWN + Vector2.RIGHT, Vector2.UP + Vector2.RIGHT, Vector2.RIGHT, Vector2.UP + Vector2.LEFT],
}

func _create_dots(number: int, rect: Rect2):
	if DOT_POSITIONS.has(number):
		for pos in DOT_POSITIONS[number]:
			var dot = DOT_SCENE.instantiate() as Node2D;
			tile.add_child(dot)
			dot.position = rect.get_center() + pos * rect.size * DOMINO_SPREAD_FACTOR

func get_top_part() -> Rect2:
	var zone = bounds.get_rect()
	return Rect2(zone.position, zone.size * Vector2(1, 0.5))

func get_bottom_part() -> Rect2:
	var zone = bounds.get_rect()
	return Rect2(zone.position, zone.size * Vector2(1, 0.5))

func get_size():
	return bounds.get_rect().size * scale

func _createTween(tween_old: Tween):
	if tween_old and tween_old.is_running():
		tween_old.kill()
	return create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
