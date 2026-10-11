extends Node3D
@export var floor_plan_generator: Node
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var doorway_wall_scene: PackedScene
@export var cell_size: float = 14.0

var rooms: Array[Array] = []
var interior_boundaries: Array[Dictionary] = []
var doorway_boundaries: Array[Dictionary] = []

var painting_slots: Array[Marker3D] = []

func _ready() -> void:
	painting_slots.clear()
	generate_rooms()
	build_floor()
	build_interior_walls()
	choose_doorways()
	place_interior_walls()
	build_walls()
	
	print("Appended markers: ", painting_slots.size())
	
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
			
			for marker in wall.find_children("*", "Marker3D", true, false):
				painting_slots.append(marker)
			
			var offset = Vector3(direction.x * cell_size / 2.0, 5.0, direction.y * cell_size / 2.0)
			
			wall.position = Vector3(cell.x * cell_size, 0.0, cell.y * cell_size) + offset
			
			match direction:
				Vector2i(0, -1): # North
					wall.rotation.y = 0.0
				Vector2i(1, 0): # East
					wall.rotation.y = -PI / 2.0
				Vector2i(0, 1): # South
					wall.rotation.y = PI
				Vector2i(-1, 0): # West
					wall.rotation.y = PI / 2.0


func generate_rooms() -> void:
	rooms.clear()
	var unassigned = floor_plan_generator.grid.duplicate()

	while not unassigned.is_empty():
		var room: Array = []
		var total_cells = floor_plan_generator.grid.size()
		var max_room_size = clampi(int(total_cells / 3), 3, 7)
		var target_size = randi_range(1, max_room_size)

		var start = unassigned.pick_random()
		unassigned.erase(start)
		room.append(start)

		while room.size() < target_size:
			var candidates: Array = []

			for cell in room:
				for direction in [Vector2(0, -1),Vector2(1, 0),Vector2(0, 1),Vector2(-1, 0)]:
					var neighbor = cell + direction
					if unassigned.has(neighbor) and not candidates.has(neighbor):
						candidates.append(neighbor)
						
			
			if candidates.is_empty():
				break
				
			var next_cell = candidates.pick_random()
			unassigned.erase(next_cell)
			room.append(next_cell)
			
		rooms.append(room)
		
	print("Rooms generated: ", rooms.size())
	for i in range(rooms.size()):
		print("Room ", i, ": ", rooms[i].size(), " cells")

func get_room_id(cell: Vector2) -> int:
	for i in range(rooms.size()):
		if rooms[i].has(cell):
			return i

	return -1

func build_interior_walls() -> void:
	interior_boundaries.clear()

	var directions = [Vector2i(1, 0), Vector2i(0, 1)]

	for cell in floor_plan_generator.grid:
		for direction in directions:
			var neighbor = Vector2(cell) + Vector2(direction)
			
			if not floor_plan_generator.grid.has(neighbor):
				continue

			var room_a = get_room_id(cell)
			var room_b = get_room_id(neighbor)
			
			if room_a == room_b:
				continue
			
			interior_boundaries.append({"cell": cell, "neighbor": neighbor, "room_a": room_a, "room_b": room_b, "direction": direction})
	print("Interior boundaries: ", interior_boundaries.size())

func choose_doorways() -> void:
	doorway_boundaries.clear()

	var room_connections: Array = []

	for i in range(rooms.size()):
		room_connections.append(i)

	var shuffled_boundaries = interior_boundaries.duplicate()
	shuffled_boundaries.shuffle()

	for boundary in shuffled_boundaries:
		var room_a: int = boundary["room_a"]
		var room_b: int = boundary["room_b"]

		if room_connections[room_a] == room_connections[room_b]:
			continue

		doorway_boundaries.append(boundary)

		var old_group = room_connections[room_b]
		var new_group = room_connections[room_a]

		for i in range(room_connections.size()):
			if room_connections[i] == old_group:
				room_connections[i] = new_group

	print("Doorway boundaries: ", doorway_boundaries.size())
	
	var connected_groups: Dictionary = {}

	for group_id in room_connections:
		connected_groups[group_id] = true

	print("Connected groups: ", connected_groups.size())


func place_interior_walls() -> void:
	for boundary in interior_boundaries:
		var cell: Vector2 = boundary["cell"]
		var direction: Vector2i = boundary["direction"]

		var is_doorway = doorway_boundaries.has(boundary)
		var scene: PackedScene = doorway_wall_scene if is_doorway else wall_scene

		var wall = scene.instantiate() as Node3D
		add_child(wall)
		
		for marker in wall.find_children("*", "Marker3D", true, false):
			painting_slots.append(marker)

		wall.position = Vector3(cell.x * cell_size, 5.0, cell.y * cell_size) + Vector3(direction.x * cell_size / 2.0,
			0.0, direction.y * cell_size / 2.0
		)

		if direction.x != 0:
			wall.rotation.y = PI / 2.0
