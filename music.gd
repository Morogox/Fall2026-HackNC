extends AudioStreamPlayer

@onready var player = $"../Player"

var drink_timer = 0.0


func _process(_delta: float) -> void:
	if player.drinks > 5:
		pitch_scale = 1.0 - (0.01 * player.drinks)
		player.cam.fov = 77.5 - (0.5 * player.drinks)
		
		drink_timer += 0.1
		
		if player.drinks > 60:
			player.drinks = 60
		
		if drink_timer > 20.0:
			player.drinks -= 1
			drink_timer = 0
