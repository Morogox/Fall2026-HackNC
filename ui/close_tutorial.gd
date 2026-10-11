extends Button

@onready var tutorial = $"../Tutorial"

func _on_pressed() -> void:
	tutorial.modulate = Color(1,1,1,0)
	
