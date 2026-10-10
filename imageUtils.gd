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
var debug: bool = true

# Rescale textures and pass into array
func _process_textures(textures: Array[ImageTexture]) -> void:
	total_images = textures.size()
	rescaled_textures.resize(total_images)
	texture_frame_types.resize(total_images)
	
	for i in range(total_images):
		texture_frame_types[i] = _calc_frame(textures[i])
		rescaled_textures[i] = _rescale_image(textures[i], texture_frame_types[i])

func _calc_frame(texture: ImageTexture) -> Frame_Types:
	var width: float = float(texture.get_width())
	var height: float = float(texture.get_height())
	var ratio: float = height / width

	if ratio > PORTRAIT_RATIO_CUTOFF:
		return Frame_Types.PORTRAIT
	elif ratio < LANDSCAPE_RATIO_CUTOFF:
		return Frame_Types.LANDSCAPE
	
	return Frame_Types.SQUARE

func _rescale_image(texture: ImageTexture, frame_type: Frame_Types) -> ImageTexture:
	var img: Image = texture.get_image()
	var width: int = img.get_width()
	var height: int = img.get_height()
	var new_width: int = width
	var new_height: int = height

	match frame_type:
		Frame_Types.SQUARE:
			if width > height:
				new_width = MAX_DIMENSION
				new_height = int(float(height) * (float(MAX_DIMENSION) / float(width)))
			else:
				new_height = MAX_DIMENSION
				new_width = int(float(width) * (float(MAX_DIMENSION) / float(height)))
				
		Frame_Types.PORTRAIT:
			new_height = MAX_DIMENSION
			new_width = int(float(width) * (float(MAX_DIMENSION) / float(height)))
			
		Frame_Types.LANDSCAPE:
			new_width = MAX_DIMENSION
			new_height = int(float(height) * (float(MAX_DIMENSION) / float(width)))
			
	img.resize(new_width, new_height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)
