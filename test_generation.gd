extends Node2D

@export var square: PackedScene
#@export var rectangle: PackedScene
#@export var large: PackedScene

@onready var camera = $Camera2D

@export var paintings = 100 # number of images
var available_slots = 0


var direction = 0 # left, right, up, down
var turn = 0
var last_turn = 0 # only -1 or 1
var num_turns = 0 # can't exceed 2

var cur = Vector2(0,0)

var grid = Array()

func _ready() -> void:
	#var main = large.instantiate()
	#add_child(main)
	
	for x in range(-1,2):
		for y in range(-1,2):
			grid.append(Vector2(x,y))
			var room = square.instantiate()
			add_child(room)
			room.position = Vector2(x,y)
	direction = randi_range(0,4)
	advance_cur(2)
	
	var i = 0
	
	available_slots += 24
	while (available_slots < paintings):
		turn = randi_range(-1,1) # left, forward, right
		var room = square.instantiate()
		add_child(room)
		
		# No easy way to turn into itself
		if turn == last_turn and turn != 0:
			if num_turns == 2:
				turn = 0
			else:
				num_turns += 1
		elif turn != last_turn and turn != 0:
			num_turns = 0
		
		# handle turn
		direction += turn
		if direction < 0:
			direction = 3
		elif direction > 3:
			direction = 0
		
		# if normal
		if i != 0:
			advance_cur(1)
		room.position = cur
		room.name = str("room"+str(int(room.position.x))+str(int(room.position.y)))
		#print(room.name)
		#room.position.x = i + 2
		check_walls(cur)
		var funni_color_float = float(available_slots - 8)/float(paintings)
		room.modulate = Color(0 + funni_color_float, 1 - funni_color_float, 1 - funni_color_float)
		
		i += 1
	#print("available_slots" + str(available_slots))
	#print("slots " + str(paintings))

func advance_cur(dist: int):
	while (grid.has(cur)):
		if direction == 0:
			cur.x -= dist
		elif direction == 1:
			cur.x += dist
		elif direction == 2:
			cur.y -= dist
		else:
			cur.y += dist
		#if (!grid.has(cur)):
			#print("overlap at " + str(cur))
	grid.append(cur)
	#print("added at " + str(cur))


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

func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("down"):
		camera.position.y += 1
	if Input.is_action_pressed("up"):
		camera.position.y -= 1
	if Input.is_action_pressed("left"):
		camera.position.x -= 1
	if Input.is_action_pressed("right"):
		camera.position.x += 1
	
	if Input.is_action_pressed("q"):
		camera.zoom.x -= 0.1
		camera.zoom.y -= 0.1
	if Input.is_action_pressed("e"):
		camera.zoom.x += 0.1
		camera.zoom.y += 0.1
	
	if Input.is_action_just_pressed("reload"):
		get_tree().reload_current_scene()
