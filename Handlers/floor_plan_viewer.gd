extends Node2D

@export var cell_size: float = 40.0
@onready var generator = $FloorPlanGenerator

var grid: Array[Vector2] = []

func _ready() -> void:
	ImageUtils.reset_seed()
	generator.generate(100)
	display_grid(generator.grid)
	
func _draw() -> void:
	if grid.is_empty():
		return

	var min_x: float = grid[0].x
	var max_x: float = grid[0].x
	var min_y: float = grid[0].y
	var max_y: float = grid[0].y

	for cell in grid:
		min_x = minf(min_x, cell.x)
		max_x = maxf(max_x, cell.x)
		min_y = minf(min_y, cell.y)
		max_y = maxf(max_y, cell.y)

	var offset := Vector2(min_x, min_y)
	var size := Vector2(max_x - min_x + 1, max_y - min_y + 1) * cell_size
	var origin := (get_viewport_rect().size - size) / 2.0

	for cell in grid:
		var position := (cell - offset) * cell_size + origin
		var rect := Rect2(position, Vector2(cell_size, cell_size))
		draw_rect(rect, Color.WHITE, true)
		draw_rect(rect, Color.BLACK, false, 2.0)

func display_grid(cells: Array) -> void:
	grid.clear()

	for cell in cells:
		grid.append(cell)

	queue_redraw()
