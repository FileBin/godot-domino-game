extends Sprite2D

var _rotation = 0;

func _ready() -> void:
    _rotation = rotation;

func _process(_delta):
    # Make the sprite look at the global mouse position
    look_at(get_global_mouse_position())
    rotation += _rotation