class_name GravitySimualtion extends Node

# TODO rewrite to c++ type mappings are very expensive

var rd: RenderingDevice
var shader: RID
var pipeline: RID

const SHADER_UNIT_SIZE = 16

func _ready():
	# 1. Initialize Rendering Device
	rd = RenderingServer.create_local_rendering_device()
	
	# 2. Load Shader
	var shader_file = load("res://shaders/gravity_simulation.glsl")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	pipeline = rd.compute_pipeline_create(shader)

func runGPU(data: Array[GravitySimualtionUnit]) -> Array[Vector2]:
	if data.is_empty(): return []

	var units_data = _units_to_byte_array(data)

	# Create Storage Buffer
	var buffer = rd.storage_buffer_create(units_data.size(), units_data)
	var output_buffer = rd.storage_buffer_create(data.size()*data.size()*8)
	
	# Create Uniform Set
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0
	uniform.add_id(buffer)

	var out_uniform = RDUniform.new()
	out_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	out_uniform.binding = 1
	out_uniform.add_id(output_buffer)
	var uniform_set = rd.uniform_set_create([uniform, out_uniform], shader, 0)
	
	# Start Compute List
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	# Dispatch (groups of 32x32 as defined in shader)
	var groups = ceil(units_data.size() / float(SHADER_UNIT_SIZE) / 32.0)
	print("group size ", groups, "x", groups)
	rd.compute_list_dispatch(compute_list, groups, groups, 1)
	rd.compute_list_end()
	
	# Submit and Wait
	rd.submit()
	rd.sync()
	
	# Retrieve Data
	var output_bytes = rd.buffer_get_data(output_buffer)
	return _byte_array_to_forces(output_bytes)

func _units_to_byte_array(units: Array[GravitySimualtionUnit]) -> PackedByteArray:
	var unit_count = units.size()
	var bytes = PackedByteArray()
	
	# Pre-allocate memory: 24 bytes per unit
	# [int32: 4] + [float: 4] + [vec2: 8] = 16
	bytes.resize(unit_count * SHADER_UNIT_SIZE)
	
	for i in range(unit_count):
		var offset = i * SHADER_UNIT_SIZE
		var unit: GravitySimualtionUnit = units[i]
		
		# 1. cluster_index (int32 - 4 bytes)
		bytes.encode_s32(offset, unit.cluster_instance_id)
		
		# 2. mass (float32 - 4 bytes)
		bytes.encode_float(offset + 4, unit.mass)
		
		# 3. position (Vector2 - 8 bytes)
		bytes.encode_float(offset + 8, unit.global_position.x)
		bytes.encode_float(offset + 12, unit.global_position.y)
		
	return bytes

func _byte_array_to_forces(data: PackedByteArray) -> Array[Vector2]:
	var unit_count = floori(sqrt(data.size() / 8.0))
	var forces: Array[Vector2] = []
	
	for i in range(unit_count):
		var force = Vector2.ZERO
		for j in range(unit_count):
			var offset = (i*unit_count + j) * 8
			# Force starts at byte 16 of each 24-byte block
			var fx = data.decode_float(offset)
			var fy = data.decode_float(offset + 4)
			force += Vector2(fx, fy)
		forces.append(force)
		
	return forces

func runCPU(data: Array[GravitySimualtionUnit]) -> Array[Vector2]:
	const G = 6.67 * 2000000

	var result_array: Array[Vector2] = []
	var forces_array: Array[Vector2] = []
	var n = data.size()

	result_array.resize(n)
	forces_array.resize(n*n)

	for i in range(n):
		for j in range(0, i):
			var a: GravitySimualtionUnit = data[i]
			var b: GravitySimualtionUnit = data[j]

			if a.cluster_instance_id == b.cluster_instance_id: 
				continue;

			var r = b.global_position - a.global_position

			var r2 = r.length_squared()
			var force = G * a.mass * b.mass / r2

			var direction = r.normalized()

			forces_array[i*n+j] = force * direction
			forces_array[j*n+i] = -force * direction
	
	for i in range(n):
		var force = Vector2.ZERO
		for j in range(n):
			var index = i*n + j
			force += forces_array[index]
		result_array[i] = force

	return result_array