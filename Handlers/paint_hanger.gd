extends Node3D

enum Slot { IMAGE, PROP, BLANK }

@export var gallery_builder: Node3D
@export var painting_scenes: Array[PackedScene] = []  # [0] square, [1] portrait, [2] landscape
@export var prop_scenes: Array[PackedScene] = [] # leave empty for no props
@export var min_same_prop_distance: float = 6.0
@export var order_slots_by_path: bool = true

var _prop_bag: ShuffleBag
var _placed_props: Array = []  # [{scene, position}]


func _ready() -> void:
	ImageUtils.reset_seed()
	_prop_bag = ShuffleBag.new(prop_scenes)
	hang_paintings()
	


func hang_paintings() -> void:
	if painting_scenes.is_empty():
		push_error("painting_scenes array is empty in Gallery Builder")
		return

	var markers: Array = gallery_builder.painting_slots.duplicate()
	print("markers: %d | images: %d | wanted slots: %d" % [markers.size(), ImageUtils.get_total_images(), ImageUtils.get_total_slots()])
	if markers.is_empty():
		return
	if order_slots_by_path:
		markers = _order_by_path(markers)

	var image_count: int = ImageUtils.get_total_images()
	if markers.size() < image_count:
		push_warning("Only %d slots for %d images. %d images won't be shown."
			% [markers.size(), image_count, image_count - markers.size()])

	var plan: Array = _build_plan(markers.size(), image_count)

	var image_order: Array = range(mini(image_count, markers.size()))
	for i in range(image_order.size() - 1, 0, -1):
		var j := ImageUtils.rng.randi_range(0, i)
		var temp = image_order[i]
		image_order[i] = image_order[j]
		image_order[j] = temp
		
	var next_image := 0

	for i in range(markers.size()):
		match plan[i]:
			Slot.IMAGE:
				_place_painting(markers[i], image_order[next_image])
				next_image += 1
			Slot.PROP:
				_place_prop(markers[i])
			Slot.BLANK:
				pass


# Every slot gets a role. All images are guaranteed a slot; the remaining
# slots are props/blanks, spread evenly using stratified placement.
func _build_plan(total: int, image_count: int) -> Array:
	var plan: Array = []
	plan.resize(total)
	plan.fill(Slot.IMAGE)

	var special: int = total - mini(image_count, total)
	if special <= 0:
		return plan

	var prop_target: int = 0
	if not prop_scenes.is_empty():
		prop_target = roundi(special * (1.0 - ImageUtils.get_percent_empty()))

	var kinds: Array = []
	for j in range(special):
		var before := int(j * prop_target / float(special))
		var after := int((j + 1) * prop_target / float(special))
		kinds.append(Slot.PROP if after > before else Slot.BLANK)

	
	for j in range(special):
		var lo := int(j * total / float(special))
		var hi := int((j + 1) * total / float(special)) - 1
		plan[ImageUtils.rng.randi_range(lo, maxi(lo, hi))] = kinds[j]

	return plan


func _order_by_path(markers: Array) -> Array:
	var remaining: Array = markers.duplicate()
	var ordered: Array = [remaining.pop_front()]
	while not remaining.is_empty():
		var last: Vector3 = ordered.back().global_position
		var best := 0
		var best_dist := INF
		for i in range(remaining.size()):
			var d := last.distance_squared_to(remaining[i].global_position)
			if d < best_dist:
				best_dist = d
				best = i
		ordered.append(remaining.pop_at(best))
	return ordered


func _place_painting(marker: Node3D, index: int) -> void:
	var frame_type: int = ImageUtils.get_texture_frame_type(index)

	var scene: PackedScene
	if frame_type >= 0 and frame_type < painting_scenes.size() and painting_scenes[frame_type] != null:
		scene = painting_scenes[frame_type]
	else:
		push_warning("Missing painting scene for frame type %d. Falling back to index 0." % frame_type)
		scene = painting_scenes[0]

	var frame := scene.instantiate() as Node3D
	add_child(frame)  # must happen before the setters
	frame.global_transform = marker.global_transform

	frame._set_image(ImageUtils.get_rescaled_texture(index))
	frame._set_title(ImageUtils.get_texture_name(index))
	frame._set_date(Time.get_date_string_from_unix_time(int(ImageUtils.get_texture_unix_time(index))))


func _place_prop(marker: Node3D) -> void:
	var pos := marker.global_position
	var scene: PackedScene = _prop_bag.draw(func(s): return _too_close_to_same(s, pos))
	if scene == null:
		return

	var prop := scene.instantiate() as Node3D
	add_child(prop)
	prop.global_transform = marker.global_transform
	_placed_props.append({"scene": scene, "position": pos})


func _too_close_to_same(scene: PackedScene, pos: Vector3) -> bool:
	if min_same_prop_distance <= 0.0:
		return false
	for p in _placed_props:
		if p.scene == scene and p.position.distance_to(pos) < min_same_prop_distance:
			return true
	return false
