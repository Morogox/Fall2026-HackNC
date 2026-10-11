extends Node


const DEFAULT_FILENAME := "map.bin"

var _file_dialog: FileDialog
var _pending_bytes: PackedByteArray

func download_map() -> void:
	if ImageUtils._is_empty():
		return

	var bytes := encode_map()
	if bytes.is_empty():
		return

	if OS.has_feature("web"):
		_save_web(bytes)
	else:
		_save_desktop(bytes)



func encode_map() -> PackedByteArray:
	var count: int = ImageUtils.total_images
	if ImageUtils.texture_names.size() != count \
	or ImageUtils.texture_unixTime.size() != count \
	or ImageUtils.texture_frame_types.size() != count \
	or ImageUtils.rescaled_textures.size() != count:
		push_error("ImageUtils arrays are different sizes; aborting save")
		return PackedByteArray()

	var buf := StreamPeerBuffer.new()

	# Header
	buf.put_data(ImageUtils.MAGIC.to_ascii_buffer())
	buf.put_u32(ImageUtils.VERSION)
	buf.put_u32(count)
	buf.put_float(ImageUtils.prop_ratio)
	buf.put_float(ImageUtils.percent_empty)

	# Per-image records
	for i in count:
		buf.put_utf8_string(ImageUtils.texture_names[i])
		buf.put_double(ImageUtils.texture_unixTime[i])
		buf.put_u8(int(ImageUtils.texture_frame_types[i]))

		var png: PackedByteArray = ImageUtils.rescaled_textures[i].get_image().save_png_to_buffer()
		buf.put_u32(png.size())
		buf.put_data(png)

	return buf.data_array



func _save_web(bytes: PackedByteArray) -> void:
	JavaScriptBridge.download_buffer(bytes, DEFAULT_FILENAME, "application/octet-stream")



func _save_desktop(bytes: PackedByteArray) -> void:
	_pending_bytes = bytes

	if _file_dialog == null:
		_file_dialog = FileDialog.new()
		_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_file_dialog.access = FileDialog.ACCESS_FILESYSTEM  # real OS paths, not res:// or user://
		_file_dialog.use_native_dialog = true               # OS-native picker where supported
		_file_dialog.filters = PackedStringArray(["*.bin ; Map files"])
		_file_dialog.file_selected.connect(_on_save_path_selected)
		add_child(_file_dialog)

	_file_dialog.current_file = DEFAULT_FILENAME
	_file_dialog.popup_centered_ratio(0.6)


func _on_save_path_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_buffer(_pending_bytes)
	file.close()
	_pending_bytes = PackedByteArray()
