#[compute]
#version 450

struct Unit {
	int cluster_index;
	float mass;
	vec2 position;
};

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

// This buffer holds all our units
layout(set = 0, binding = 0, std430) buffer UnitBuffer {
	Unit units[];
} data;

layout(set = 0, binding = 1, std430) buffer ForceBuffer {
	vec2 forces[];
} result;

void main() {
	uint i = gl_GlobalInvocationID.x;
	uint j = gl_GlobalInvocationID.y;

	uint n = data.units.length();

	if (j >= i) return;

	if (i >= n) return;

	Unit unit_a = data.units[i];
	Unit unit_b = data.units[j];

	if (unit_a.cluster_index == unit_b.cluster_index) return;

	vec2 r = unit_b.position - unit_a.position;

	float G = 6.674 * 1000000; // Gravitational constant (adjust as needed for your scale)

	float force = G * unit_a.mass * unit_b.mass / dot(r, r);

	vec2 direction = normalize(r);

	result.forces[i*n+j] = force * direction;
	result.forces[j*n+i] = -force * direction;
}
