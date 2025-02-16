@tool

extends Node3D

const CHUNK_SIZE := 256 # Per axis
const CHUNK_AMOUNT := 4 # Per axis
const CHUNK_SUBDIVISION := 8 # Per axis
const SHOULD_SMOOTH := true # Should terrain be smooth?

@export var player: Node3D
var loaded_chunks : Dictionary = {} # dict to hold loaded chunks

@export var terrain_material: Material # Assign the material in inspector

var noise : FastNoiseLite # Noise will later be used

# In _ready(), initialize the noise. You can set any values,
# but following valuesworked for me.
func _ready():
	noise = FastNoiseLite.new()
	noise.seed = 101325
	noise.fractal_octaves = 6
	noise.frequency = 0.001
	

func generate_terrain(player_position: Vector3, vertex_processing_function: Callable):
	# Calculate player chunk position (which chunk player lies in)
	var player_chunk_x = int(player_position.x / CHUNK_SIZE)
	var player_chunk_z = int(player_position.z / CHUNK_SIZE)
	
	# Load and unload chunks based on player position
	for x in range(player_chunk_x - CHUNK_AMOUNT, player_chunk_x + CHUNK_AMOUNT + 1):
		for z in range(player_chunk_z - CHUNK_AMOUNT, player_chunk_z + CHUNK_AMOUNT + 1):
			var chunk_key = str(x) + "," + str(z)
			if not loaded_chunks.has(chunk_key):
				load_chunk(x, z, vertex_processing_function)
	
	# Unload chunks that are out of render distance
	for key in loaded_chunks.keys():
		var coords = key.split(",")
		var chunk_x = int(coords[0])
		var chunk_z = int(coords[1])
		if abs(chunk_x - player_chunk_x) > CHUNK_AMOUNT or abs(chunk_z - player_chunk_z) > CHUNK_AMOUNT:
			unload_chunk(chunk_x, chunk_z)
			


func load_chunk(x, z, vertex_processing_function: Callable):
	var chunk_mesh = TerrainChunk.create_chunk(vertex_processing_function, CHUNK_SIZE, Vector3(x, 0, z), CHUNK_SUBDIVISION, SHOULD_SMOOTH)
	var chunk_instance = MeshInstance3D.new()
	chunk_instance.mesh = chunk_mesh
	chunk_instance.position.x = x * CHUNK_SIZE
	chunk_instance.position.z = z * CHUNK_SIZE
	chunk_instance.material_override = terrain_material
	self.add_child(chunk_instance)
	loaded_chunks[str(x) + "," + str(z)] = chunk_instance
	
	# Add collision static body to terrain chunks
	chunk_instance.create_trimesh_collision()


func unload_chunk(x, z):
	var chunk_key = str(x) + "," + str(z)
	if loaded_chunks.has(chunk_key):
		var chunk_instance = loaded_chunks[chunk_key]
		chunk_instance.queue_free()
		loaded_chunks.erase(chunk_key)
		
func _process(delta):
	var player_position: Vector3 = player.global_transform.origin
	
	generate_terrain(player_position, _process_chunk_vertices)

# Defining vertex_processing_function:

# Logic to displace vertices of chunks (called by TerrainChunk.create_chunk())
func _process_chunk_vertices(vertex: Vector3, chunk_position: Vector3) -> Vector3:
	var noise_value := noise.get_noise_3d(vertex.x + chunk_position.x * CHUNK_SIZE, 0, vertex.z + chunk_position.z * CHUNK_SIZE)
	var vertex_global_position = vertex + chunk_position * CHUNK_SIZE

	# Apply combined falloff to noise
	return Vector3(
		vertex.x,
		(noise_value * noise_value if noise_value >= 0 else -noise_value * noise_value) * 128,
		vertex.z
	)
	
