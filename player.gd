
extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sensitivity := 0.002

@onready var head: Node3D = $Head
@onready var wine: Node3D = $Head/Wine
@onready var wine_drink: Node3D = $Head/wineDrink
@onready var drink_audio: AudioStreamPlayer = $Head/DrinkAudio

@export var drinking_sounds: Array[AudioStream]

var gravity: float = 9.8

var drinking := false
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not drinking:
		drink_wine()
	
func drink_wine() -> void:
	drinking = true
	var tween = create_tween()
	var wine_start := wine.position
	var drink_start := wine_drink.position
	#lower wine and raise wineDrink
	tween.tween_property(wine, "position", wine_start + Vector3(0, -0.5, 0), 0.3)
	tween.parallel().tween_property(wine_drink, "position", drink_start + Vector3(0, 0.5, 0), 0.3)

	#drinking pose.
	tween.tween_interval(1.0)

	#return both to their starting positions.
	tween.tween_property(wine, "position", wine_start, 0.3)
	tween.parallel().tween_property(wine_drink, "position", drink_start, 0.3)

	tween.finished.connect(func():
		drinking = false
	)

func play_drink_sound() -> void:
	if drinking_sounds.is_empty():
		return

	var sound = drinking_sounds.pick_random()
	drink_audio.stream = sound
	drink_audio.play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	#if not is_on_floor():
		#velocity.y -= gravity * delta

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y )).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
