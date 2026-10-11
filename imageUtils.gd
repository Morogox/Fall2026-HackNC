extends Node

enum Frame_Types { SQUARE, PORTRAIT, LANDSCAPE }

const PORTRAIT_RATIO_CUTOFF: float = 1.38888888889   
const LANDSCAPE_RATIO_CUTOFF: float = 0.78125  
const MAX_DIMENSION: int = 1080    

var texture_names: Array[String] = [] 
var texture_unixTime: Array[float] = [] 
var texture_frame_types: Array[Frame_Types] = [] 
var rescaled_textures: Array[ImageTexture] = [] 
var total_images: int = 0
var total_props: int = 0
var prop_ratio: float = 1.2 # extra prop slots per image (0.25 = 1 prop per 4 images)
var percent_empty: float = 0.5; # percent chance that prop location is left blank (currently 100% until props are implemented)
var debug: bool = true

#encoder decoder consensus
const MAGIC := "MAP1"
const VERSION := 1


const GALLERY_SCENE_PATH := "res://gallery.tscn"

func swap_to_gallery_scene() -> void:
	if not ResourceLoader.exists(GALLERY_SCENE_PATH):
		push_error("Gallery scene not found: " + GALLERY_SCENE_PATH)
		return
	get_tree().change_scene_to_file.call_deferred(GALLERY_SCENE_PATH)

# Rescale textures and pass into array
func _process_textures(textures: Array[ImageTexture]) -> void:
	total_images = textures.size()
	rescaled_textures.resize(total_images)
	texture_frame_types.resize(total_images)
	
	for i in range(total_images):
		texture_frame_types[i] = _calc_frame(textures[i])
		rescaled_textures[i] = _rescale_image(textures[i], texture_frame_types[i])
		
	calc_total_slots(prop_ratio)

func _calc_frame(texture: ImageTexture) -> Frame_Types:
	var width: float = float(texture.get_width())
	var height: float = float(texture.get_height())
	var ratio: float = height / width

	if ratio > PORTRAIT_RATIO_CUTOFF:
		return Frame_Types.PORTRAIT
	elif ratio < LANDSCAPE_RATIO_CUTOFF:
		return Frame_Types.LANDSCAPE
	
	return Frame_Types.SQUARE

func _rescale_image(texture: ImageTexture, _frame_type: Frame_Types) -> ImageTexture:
	var img: Image = texture.get_image()
	var longest := maxi(img.get_width(), img.get_height())

	if longest > MAX_DIMENSION:
		var s := float(MAX_DIMENSION) / float(longest)
		img.resize(maxi(1, roundi(img.get_width() * s)),maxi(1, roundi(img.get_height() * s)),Image.INTERPOLATE_NEAREST)

	img.generate_mipmaps() 
	return ImageTexture.create_from_image(img)

func _is_empty()-> bool:
	return rescaled_textures.size()==0

func _is_valid_index(index: int) -> bool:
	if index < 0 or index >= total_images:
		if debug:
			push_warning("Index %d out of range (total images: %d)" % [index, total_images])
		return false
	return true


func get_total_images() -> int:
	return total_images

func get_texture_name(index: int) -> String:
	if not _is_valid_index(index):
		return ""
	return texture_names[index]

func get_texture_unix_time(index: int) -> float:
	if not _is_valid_index(index):
		return 0.0
	return texture_unixTime[index]

func get_texture_frame_type(index: int) -> Frame_Types:
	if not _is_valid_index(index):
		return Frame_Types.SQUARE
	return texture_frame_types[index]

func get_rescaled_texture(index: int) -> ImageTexture:
	if not _is_valid_index(index):
		return null
	return rescaled_textures[index]

func calc_total_slots(percent: float) -> void:
	total_props = ceili(total_images * percent)
	
func get_total_props() -> int:
	return total_props
	
func get_total_slots() -> int:
	return total_props + total_images
	
func get_percent_empty() -> float:
	return percent_empty
