class_name ClusterUnit extends CollisionShape2D

signal data_initialized

var tile: Domino 

@export var mass = 5

func _enter_tree() -> void:
	tile = $Domino
	data_initialized.emit()

func get_global_center_of_mass() -> Vector2:
	return tile.global_position