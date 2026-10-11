
extends Node3D

const LETTERBOX_SHADER := preload("res://letterbox.gdshader")

@export var child_mesh: MeshInstance3D
@export var placard_path: NodePath
@export var canvas_surface: int = 1

@export var canvas_aspect_override: float = 0.0


func _set_image(img_texture: ImageTexture) -> void:
	if child_mesh == null or img_texture == null:
		push_error("frame.gd: missing child_mesh or texture on " + name)
		return

	var mesh_aspect := _get_surface_aspect()
	var img_aspect := float(img_texture.get_width()) / float(img_texture.get_height())

	var content_scale := Vector2.ONE
	var content_offset := Vector2.ZERO

	if img_aspect > mesh_aspect:
		content_scale.y = mesh_aspect / img_aspect
		content_offset.y = (1.0 - content_scale.y) * 0.5
	else:
		content_scale.x = img_aspect / mesh_aspect
		content_offset.x = (1.0 - content_scale.x) * 0.5

	var mat := ShaderMaterial.new()
	mat.shader = LETTERBOX_SHADER
	mat.set_shader_parameter("albedo_tex", img_texture)
	mat.set_shader_parameter("content_scale", content_scale)
	mat.set_shader_parameter("content_offset", content_offset)

	child_mesh.set_surface_override_material(canvas_surface, mat)


func _get_surface_aspect() -> float:
	if canvas_aspect_override > 0.0:
		return canvas_aspect_override

	if child_mesh == null or child_mesh.mesh == null:
		return 1.0

	if child_mesh.mesh is QuadMesh:
		var quad := child_mesh.mesh as QuadMesh
		if quad.size.y > 0.0001:
			return quad.size.x / quad.size.y

	push_warning("Expected a QuadMesh for the image surface on " + name)
	return 1.0


func _set_title(title: String) -> void:
	var placard_node = get_node_or_null(placard_path)
	if placard_node and placard_node.has_method("_set_title"):
		placard_node._set_title(title)


func _set_date(date: String) -> void:
	var placard_node = get_node_or_null(placard_path)
	if placard_node and placard_node.has_method("_set_date"):
		placard_node._set_date(date)
