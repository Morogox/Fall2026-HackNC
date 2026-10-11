extends Node3D

@export var gallery_builder: Node3D
@export var painting_scenes: Array[PackedScene] = []
# Stored in order: [0] = square, [1] = portrait, [2] = landscape


func _ready() -> void:
	hang_paintings()
	
	
func hang_paintings() -> void:
	if painting_scenes.is_empty():
		push_error("painting_scenes array is empty in Gallery Builder!")
		return

	var shuffled_markers = gallery_builder.painting_slots.duplicate()
	shuffled_markers.shuffle()

	var paint_amount: int = min(shuffled_markers.size(), ImageUtils.get_total_images())

	for index in range(paint_amount):
		var marker = shuffled_markers[index]
		
		# Fetch the specific frame type for this image (SQUARE, PORTRAIT, or LANDSCAPE)
		var frame_type = ImageUtils.get_texture_frame_type(index)
		
		# Ensure the index exists in your array to prevent out-of-bounds errors
		var scene: PackedScene
		if frame_type >= 0 and frame_type < painting_scenes.size() and painting_scenes[frame_type] != null:
			scene = painting_scenes[frame_type]
		else:
			push_warning("Missing painting scene for frame type index %d. Falling back to index 0." % frame_type)
			scene = painting_scenes[0]

		var frame = scene.instantiate() as Node3D

		add_child(frame)  # Must happen first so @onready / node tree resolves
		frame.global_transform = marker.global_transform

		frame._set_image(ImageUtils.get_rescaled_texture(index))
		frame._set_title(ImageUtils.get_texture_name(index))
		frame._set_date(Time.get_date_string_from_unix_time(int(ImageUtils.get_texture_unix_time(index))))
