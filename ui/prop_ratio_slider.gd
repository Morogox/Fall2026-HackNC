extends HSlider


@onready var label = $Value

func _on_value_changed(_val: float) -> void:
	ImageUtils.prop_ratio = value
	label.text = "Props per Image: " + str(value)
