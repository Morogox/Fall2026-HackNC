extends Node3D
@export var floor_plan_generator: Node
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var doorway_wall_scene: PackedScene
@export var cell_size: float = 14.0

func _ready() -> void:
	build_floor()
	build_walls()
	
func build_floor() -> void:
	for cell in floor_plan_generator.grid:
		var tile = floor_scene.instantiate() as Node3D
		add_child(tile)
		
		tile.position = Vector3(cell.x * cell_size, 0.0, cell.y * cell_size)


func build_walls() -> void:
	var directions = [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0)
	]
	
	for cell in floor_plan_generator.grid:
		for direction in directions:
			var neighbor = Vector2i(cell) + direction
			
			if floor_plan_generator.grid.has(Vector2(neighbor)):
				continue
				
			var wall = wall_scene.instantiate() as Node3D
			add_child(wall)
			
			var offset = Vector3(direction.x * cell_size / 2.0, 5.0, direction.y * cell_size / 2.0)
			
			wall.position = Vector3(cell.x * cell_size, 0.0, cell.y * cell_size) + offset
			
			if direction.x != 0:
				wall.rotation.y = PI / 2.0
