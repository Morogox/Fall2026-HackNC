extends HSlider

@onready var vol_label = $volume


func _on_value_changed(_val: float) -> void:
	vol_label.text = "Volume: " + str(value) + " db"
	if value == -30.5:
		vol_label.text = "OFF"
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)
	#music.volume_change = vol_slider.value
