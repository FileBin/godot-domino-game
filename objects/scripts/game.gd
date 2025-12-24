class_name Game extends Node2D

class Tile:
	var top: int
	var bottom: int

var deck: Array[Tile] = []
var idle_animation_factor = 0.;
var idle_animation_time = 0.;

var tween_idle_factor: Tween

var TILE_SCENE = preload("res://objects/domino-ui.tscn")

@onready var deck_ui = $UI/Deck as Container

@export var idle_animation_wave_offset = 0.3;
func _ready() -> void:
	restore_idle_tween()
	for top in range(0, 7):
		for bottom in range(top, 7):
			var tile = Tile.new()
			tile.top = top;
			tile.bottom = bottom;
			deck.append(tile)
	
	fisher_yates_shuffle(deck)

	for i in range(0, 6):
		draw_card()

func draw_card():
	var tile = deck.pop_front()
	var domino_ui = TILE_SCENE.instantiate()
	var domino = domino_ui.get_child(0) as Domino # TODO refactor this (ready order to avoid exact tree structure)
	domino.top_number = tile.top
	domino.bottom_number = tile.bottom
	domino.game = self
	deck_ui.add_child(domino_ui)

func fisher_yates_shuffle(arr: Array):
	var n = len(arr)
	for i in range(n - 1, 0, -1): # Iterate from last element down to second
		var j = randi_range(0, i) # Generate random index between 0 and i
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr

func _process(delta: float) -> void:

	idle_animation_time += delta * idle_animation_factor;

	var idle_animation_offset = 0.;

	for domino in dominos_on_hand():        
		var target_height = domino.get_size().y * 0.2 * sin(idle_animation_time + idle_animation_offset);
		domino.animation_target().position.y = lerp(domino.animation_target().position.y, target_height, idle_animation_factor);  
		idle_animation_offset += idle_animation_wave_offset;

func dominos_on_hand() -> Array[Domino]:
	var dominos: Array[Domino] = []
	dominos.assign(deck_ui.get_children().map(func(card): return card.get_child(0))); # TODO refactor this
	return dominos

func stop_idle_tween() -> Tween:
	tween_idle_factor = _createTween(tween_idle_factor)
	tween_idle_factor.set_parallel()
	tween_idle_factor.tween_property(self, "idle_animation_factor", 0., 0.5)
	for domino in dominos_on_hand():
		if domino.is_hovered():
			continue
		tween_idle_factor.tween_property(domino.animation_target(), "position", Vector2.ZERO, 0.5)

	return tween_idle_factor

func restore_idle_tween() -> Tween:
	for domino in dominos_on_hand():
		if domino.is_hovered():
			return
	
	tween_idle_factor = _createTween(tween_idle_factor)
	tween_idle_factor.tween_property(self, "idle_animation_factor", 1., 0.5)

	return tween_idle_factor

func _createTween(tween_old: Tween):
	if tween_old and tween_old.is_running():
		tween_old.kill()
	return create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
