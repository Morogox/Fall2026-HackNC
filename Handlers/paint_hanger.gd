extends Node3D
@export var gallery_builder: Node3D
@export var painting_scenes: Array[PackedScene] = []


func _ready() -> void:
	hang_paintings()
func hang_paintings() -> void:
	var shuffled_markers = gallery_builder.painting_slots.duplicate()
	shuffled_markers.shuffle()
	
	#Replace this for loop with a standard for loop of i = 0; i < paint_amount once 
	#it is avaliable from the javascript pipeline
	for marker in shuffled_markers:
		var painting_frame = randi_range(0, painting_scenes.size() - 1)
		var scene: PackedScene = painting_scenes[painting_frame]
		var frame = scene.instantiate() as Node3D
		add_child(frame)
		
		frame.global_transform = marker.global_transform
