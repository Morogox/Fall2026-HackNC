extends CanvasLayer

var paused = false

func _ready() -> void:
	visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		paused = !paused
		
		if paused:
			_open_settings()
		else:
			_close_settings()
		

func _open_settings():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#if not I_am_title:
		#get_tree().paused = true
	visible = true
	get_tree().paused = true

func _close_settings():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	get_tree().paused = false
