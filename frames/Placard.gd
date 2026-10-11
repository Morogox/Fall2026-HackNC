extends Node

@onready var title_label: Label3D = get_child(0) as Label3D
@onready var date_label: Label3D = get_child(1) as Label3D

func _set_title(title: String) -> void:
	title_label.text = title

func _set_date(date: String) -> void:
	date_label.text = date
