extends Node2D

const object_to_paint = preload("res://objects/cluster-unit.tscn")

const cluster_preload = preload("res://objects/domino-cluster.tscn")

# Distance in pixels the mouse must move before spawning another object
@export var brush_spacing: float = 50.0

var last_paint_position: Vector2 = Vector2.ZERO
var is_painting: bool = false

var physical_bodies: Array[DominoCluster] = [];

var simulation_space: Node2D

func _ready():
	simulation_space = Node2D.new()
	simulation_space.name = "simulation_space"
	add_child(simulation_space);
	
func _physics_process(_delta: float) -> void:
	apply_gravity()

var last_mouse_position = Vector2.ZERO

func _process(_delta):
	# Check for left mouse button click/hold
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var current_mouse_pos = get_global_mouse_position()
		
		# If it's the first click or we've moved further than the spacing distance
		var distance = current_mouse_pos - last_paint_position

		if !is_painting or distance.length() > brush_spacing:
			var movement = current_mouse_pos - last_mouse_position
			var l = movement.length()
			var n = ceili(l/brush_spacing)
			var dir = movement/l

			for i in range(n):
				paint_object(last_mouse_position + dir * brush_spacing * i)
			
			last_paint_position = current_mouse_pos
			is_painting = true
			
	else:
		is_painting = false

	last_mouse_position = get_global_mouse_position()
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
	domino_physical.tile.top_number = randi() % 7
	domino_physical.tile.bottom_number = randi() % 7

func apply_gravity():
	var clusters: Array[DominoCluster] = []
	clusters.assign(simulation_space.get_children());

	var clusters_units: Array = clusters.map(func(cluster: DominoCluster): return cluster.get_gravity_simulation_units());

	var simulation_units: Array[GravitySimualtionUnit] = []

	simulation_units.assign(flatten(clusters_units))
	
	var unit_forces = GravitySimulation.runGPU(simulation_units);

	for i in range(unit_forces.size()):
		var unit = simulation_units[i]
		var force = unit_forces[i]

		var cluster = instance_from_id(unit.cluster_instance_id) as DominoCluster

		if cluster:

			cluster.apply_force(force, unit.global_position - cluster.global_position)

func flatten(list: Array) -> Array:
	var out := []
	for item in list:
		if typeof(item) == TYPE_ARRAY:
			out += flatten(item) # Recursively call the function if the item is an array
		else:
			out.append(item) # Append the item if it's not an array
	return out