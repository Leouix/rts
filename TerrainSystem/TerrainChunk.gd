
# Chunk creator script - it creates a single tile of the terrain

extends Node
class_name TerrainChunk


# Create a plane mesh and then displaces its vertices based on the chunk_manager's process_chunk_vertices() method
static func create_chunk(
	vertex_processing_function: Callable,
	chunk_size: float,
	chunk_position: Vector3,
	subdivision: int,
	should_smooth: bool
	):
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(chunk_size, chunk_size)
	plane_mesh.subdivide_depth = subdivision
	plane_mesh.subdivide_width = subdivision

	var surface_tool := SurfaceTool.new()
	surface_tool.create_from(plane_mesh, 0)

	var mesh_data_tool := MeshDataTool.new()
	mesh_data_tool.create_from_surface(surface_tool.commit(), 0)

	for i in range(mesh_data_tool.get_vertex_count()):
		var vertex := mesh_data_tool.get_vertex(i)
		vertex = vertex_processing_function.call(vertex, chunk_position) # Returns vec3
		mesh_data_tool.set_vertex(i, vertex)
		
		if vertex.y > 0:
			if vertex.y > 6:
				mesh_data_tool.set_vertex_color(i, Color.BLUE)
			else: mesh_data_tool.set_vertex_color(i, Color.RED)
		else:
			mesh_data_tool.set_vertex_color(i, Color.GREEN)
	
	var array_mesh := ArrayMesh.new()
	mesh_data_tool.commit_to_surface(array_mesh)
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	if should_smooth: surface_tool.set_smooth_group(0) # If you want smooth shading
	else: surface_tool.set_smooth_group(1) # If you want flat shading
	
	surface_tool.append_from(array_mesh, 0, Transform3D()) # MeshInstance3D transform? or world_transform? or Transform3D()?
	surface_tool.generate_normals()
	
	var output_mesh: ArrayMesh = surface_tool.commit()
	
	return output_mesh
