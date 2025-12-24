class_name DominoCluster extends RigidBody2D

var grid_size = -1.0

func add_unit(unit: ClusterUnit):
	if grid_size < 0:
		unit.data_initialized.connect(init_grid.bind(unit))
	add_child(unit)
	add_mass(unit.global_position, unit.mass)

func init_grid(unit: ClusterUnit):
	var slot = unit.tile.data_initialized
	if not slot.is_connected(init_grid_tile):
		grid_size = slot.connect(init_grid_tile.bind(unit.tile))

func init_grid_tile(tile: Domino):
	grid_size = tile.bounds.get_rect().size.x

func destroy_cluster() -> Array[ClusterUnit]:
	var all_units: Array[ClusterUnit] = [];
	all_units.assign(get_children())
	
	queue_free()
	
	return all_units;

func get_tile_value(point: Vector2) -> int:
	for child in get_children():
		var unit = child as ClusterUnit
		if not unit:
			continue
		var number = unit.tile.get_tile_number_at(point)

		if number > 0:
			return number
	return -1

var last_linear_velocity = Vector2.ZERO
var last_angular_velocity = 0

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_queued_for_deletion(): return

	if state.get_contact_count() == 1:
		var other = state.get_contact_collider_object(0);
		var point = state.get_contact_collider_position(0);

		var cluster = other as DominoCluster

		if cluster and not cluster.is_queued_for_deletion():
			# replace it with scedule to merger in parent object (to do it not in _integrate_forces)
			if mass > cluster.mass:
				merge_other_cluster(point, cluster)
			else:
				cluster.merge_other_cluster(point, self)
			
	
	last_linear_velocity = state.linear_velocity
	last_angular_velocity = state.angular_velocity


func merge_other_cluster(point: Vector2, cluster: DominoCluster) -> void:
	if grid_size < 0: return

	var angle = get_aligning_angle_with(cluster)

	var total_mass = mass + cluster.mass

	var self_amount = mass / total_mass 
	var cluster_amount = cluster.mass / total_mass

	rotate_around(self, point, -angle*self_amount)
	rotate_around(cluster, point, angle*cluster_amount)

	var local_cluster_pos = to_local(cluster.global_position)

	var align_grid = grid_size

	var cluster_cell = (local_cluster_pos / align_grid).round()

	var local_dir = local_cluster_pos - cluster_cell*align_grid

	var global_dir = global_transform.basis_xform(local_dir)

	global_position += global_dir*self_amount
	cluster.global_position -= global_dir*cluster_amount

	for unit in cluster.destroy_cluster():
		unit.reparent(self)

	linear_velocity = (last_linear_velocity * mass + cluster.last_linear_velocity * cluster.mass) / total_mass
	angular_velocity = (last_angular_velocity * mass + cluster.last_angular_velocity * cluster.mass) / total_mass

	cluster.linear_velocity = linear_velocity
	cluster.angular_velocity = angular_velocity

	add_mass(cluster.to_global(cluster.center_of_mass), cluster.mass)

func get_aligning_angle_with(cluster: DominoCluster) -> float:
	var a = global_transform.basis_xform(Vector2.UP);

	a = a.normalized()

	var max_dot = -INF
	var target_sign = 0
	for b in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var bi = cluster.global_transform.basis_xform(b).normalized()
		var dot = a.dot(bi)
		if max_dot < dot:
			max_dot = dot
			target_sign = sign(a.cross(bi))
	
	return target_sign * acos(max_dot)

func v2mod(v: Vector2, m: float):
	return Vector2(fmod(v.x, m), fmod(v.y, m))

func add_mass(other_com, other_mass):
	var total_mass = mass + other_mass
	var weighted_sum = global_position * mass + other_com * other_mass
	center_of_mass = to_local(weighted_sum / total_mass)
	mass = total_mass

func rotate_around(obj: Node2D, point, angle):
	var tStart = point
	obj.global_translate(-tStart)
	obj.transform = obj.transform.rotated(-angle)
	obj.global_translate(tStart)

func get_gravity_simulation_units() -> Array[GravitySimualtionUnit]:
	var array: Array[GravitySimualtionUnit] = []
	for child in get_children():
		var domino = child as ClusterUnit

		if not domino:
			continue

		var unit = GravitySimualtionUnit.new()

		unit.cluster_instance_id = get_instance_id()
		unit.global_position = domino.get_global_center_of_mass()
		unit.mass = domino.mass

		array.append(unit)

	return array