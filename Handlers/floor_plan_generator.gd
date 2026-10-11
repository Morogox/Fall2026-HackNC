extends Node

#@export var square: PackedScene
#@export var rectangle: PackedScene
#@export var large: PackedScene

#@onready var camera = $Camera2D

@export var paintings = 100# number of images
var available_slots = 0


var direction = 0 # left, right, up, down
var turn = 0
var last_turn = 0 # only -1 or 1
var num_turns = 0 # can't exceed 2

var cur := Vector2(0,0)

var grid = Array()
var grid_size := 1


func _ready() -> void:
	paintings = ImageUtils.get_total_slots()
	generate(paintings)

func generate(painting_count: int) -> void:
	paintings = painting_count
	grid.clear()
	cur = Vector2(0, 0)
	available_slots = 0

	_generate_starting_grid()
	direction = randi_range(0, 3)

	#match direction:
		#0:
			#cur = Vector2(-2, 0)
		#1:
			#cur = Vector2(2, 0)
		#2:
			#cur = Vector2(0, -2)
		#3:
			#cur = Vector2(0, 2)
	#if available_slots < paintings:
		#grid.append(cur)
		#check_walls(cur)
	direction = randi_range(0, 3)
	cur = Vector2(0, 0)
	check_walls(cur)

	var i = 0
	while (available_slots < paintings):
		turn = randi_range(-1,1) # left, forward, right
		
		# No easy way to turn into itself
		if turn != 0:
			if turn == last_turn:
				if num_turns >= 2:
					turn = 0
				else:
					num_turns += 1
			else:
				num_turns = 1
			
		if turn != 0:
			last_turn = turn
		
		# handle turn
		direction = (direction + turn + 4) % 4
		
		# if normal
		if not advance_cur(1):
			i += 1
			continue
		check_walls(cur)
		
		i += 1
	print("Cells generated: ", grid.size())
	print("Painting slots: ", available_slots)

func _generate_starting_grid() -> void:
	var starting_size = 1

	#if paintings > 8:
		#starting_size = 2
	#if paintings > 16:
		#starting_size = 3

	var start := int(floor(starting_size / 2.0))

	for x in range(-start, starting_size - start):
		for y in range(-start, starting_size - start):
			grid.append(Vector2(x, y))

func advance_cur(dist: int) -> bool:
	for step in range(dist):
		var next := cur

		match direction:
			0:
				next.y -= 1
			1:
				next.x += 1
			2:
				next.y += 1
			3:
				next.x -= 1

		if grid.has(next):
			return false

		cur = next
		grid.append(cur)
	return true


func check_walls(pos: Vector2):
	var check = pos
	#print("available_slots before: " + str(available_slots))
	available_slots += 8
	for x in range(-1,2): # Checks pos.x - 1 and pos.x + 1
		if x != 0:
			check = pos
			check.x += x
			if grid.has(check):
				#print(check)
				available_slots -= 4
	for y in range(-1,2): # Checks pos.y - 1 and pos.y + 1
		if y != 0:
			check = pos
			check.y += y
			if grid.has(check):
				#print(check)
				available_slots -= 4
	#print("available_slots after: " + str(available_slots))
