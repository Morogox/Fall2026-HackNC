extends Button

@onready var credits = $"../Credits"

func _on_pressed() -> void:
	credits.modulate = Color(1,1,1,0)
	
