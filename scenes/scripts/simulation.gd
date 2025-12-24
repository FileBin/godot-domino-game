extends Node2D

const object_to_paint = preload("res://objects/cluster-unit.tscn")

const cluster_preload = preload("res://objects/domino-cluster.tscn")

const G = 6.67 * 1000000

# Distance in pixels the mouse must move before spawning another object
@export var brush_spacing : float = 50.0

var last_paint_position : Vector2 = Vector2.ZERO
var is_painting : bool = false

var physical_bodies: Array[DominoCluster] = [];

var simulation_space: Node2D

func _ready():
	simulation_space =Node2D.new()
	simulation_space.name = "simulation_space"
	add_child(simulation_space);
	
func _physics_process(_delta: float) -> void:
	apply_gravity()

func _process(_delta):
	# Check for left mouse button click/hold
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var current_mouse_pos = get_global_mouse_position()
		
		# If it's the first click or we've moved further than the spacing distance
		if !is_painting or current_mouse_pos.distance_to(last_paint_position) > brush_spacing:
			paint_object(current_mouse_pos)
			last_paint_position = current_mouse_pos
			is_painting = true
	else:
		is_painting = false

func paint_object(pos):
	if object_to_paint == null:
		print("Please assign a scene to 'object_to_paint' in the Inspector!")
		return
		
	# Instantiate and add to the scene tree
	var obj = object_to_paint.instantiate()
	var domino_physical = obj as ClusterUnit
	domino_physical.data_initialized.connect(randomize_tile.bind(domino_physical))

	var new_cluster = cluster_preload.instantiate() as DominoCluster

	new_cluster.add_unit(domino_physical) 

	new_cluster.global_position = pos
	new_cluster.rotation = randf_range(0, TAU) 
	simulation_space.add_child(new_cluster)

func randomize_tile(domino_physical: ClusterUnit):
	domino_physical.tile.top_number = randi()%7
	domino_physical.tile.bottom_number = randi()%7

func apply_gravity():
	var nodes: Array[DominoCluster] = []
	nodes.assign(simulation_space.get_children());

	var n = nodes.size()
	for i in range(n):
		for j in range(i + 1, n):
			var a = nodes[i]
			var b = nodes[j]

			var r = b.to_global(b.center_of_mass) - a.to_global(a.center_of_mass)

			var r2 = r.length_squared()
			var force = G * a.mass * b.mass / r2

			a.apply_central_force(force * r.normalized())
			b.apply_central_force(- force * r.normalized())
		
