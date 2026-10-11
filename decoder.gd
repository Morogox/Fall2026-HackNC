extends Node

var _open_dialog: FileDialog
var _js_callback: JavaScriptObject



func load_map() -> void:
	if OS.has_feature("web"):
		_load_web()
	else:
		_load_desktop()



func decode_map(bytes: PackedByteArray) -> bool:
	var buf := StreamPeerBuffer.new()
	buf.data_array = bytes

	var magic_res := buf.get_data(ImageUtils.MAGIC.length())
	if magic_res[0] != OK or (magic_res[1] as PackedByteArray).get_string_from_ascii() != ImageUtils.MAGIC:
		push_error("Not a valid map file (bad header)")
		return false

	var version := buf.get_u32()
	if version != ImageUtils.VERSION:
		push_error("Unsupported map version %d (expected %d)" % [version, ImageUtils.VERSION])
		return false

	var count := buf.get_u32()
	var prop_ratio := buf.get_float()
	var percent_empty := buf.get_float()

	var names: Array[String] = []
	var times: Array[float] = []
	var types: Array[ImageUtils.Frame_Types] = []
	var textures: Array[ImageTexture] = []

	for i in count:
		if buf.get_available_bytes() < 4:
			push_error("Map file truncated at image %d" % i)
			return false

		var tex_name := buf.get_utf8_string()
		if buf.get_available_bytes() < 8 + 1 + 4:
			push_error("Map file truncated at image %d" % i)
			return false

		var unix_time := buf.get_double()
		var frame_type := buf.get_u8()
		if frame_type > ImageUtils.Frame_Types.LANDSCAPE:
			push_error("Invalid frame type %d at image %d" % [frame_type, i])
			return false

		var png_size := buf.get_u32()
		if png_size == 0 or png_size > buf.get_available_bytes():
			push_error("Invalid PNG size at image %d" % i)
			return false

		var png_res := buf.get_data(png_size)
		if png_res[0] != OK:
			push_error("Failed to read PNG data at image %d" % i)
			return false

		var img := Image.new()
		if img.load_png_from_buffer(png_res[1]) != OK:
			push_error("Failed to decode PNG at image %d" % i)
			return false

		img.generate_mipmaps()

		names.append(tex_name)
		times.append(unix_time)
		types.append(frame_type as ImageUtils.Frame_Types)
		textures.append(ImageTexture.create_from_image(img))

	
	ImageUtils.texture_names = names
	ImageUtils.texture_unixTime = times
	ImageUtils.texture_frame_types = types
	ImageUtils.rescaled_textures = textures
	ImageUtils.total_images = count
	ImageUtils.prop_ratio = prop_ratio
	ImageUtils.percent_empty = percent_empty
	ImageUtils.calc_total_slots(prop_ratio)

	return true



func _load_desktop() -> void:
	if _open_dialog == null:
		_open_dialog = FileDialog.new()
		_open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_open_dialog.use_native_dialog = true
		_open_dialog.filters = PackedStringArray(["*.bin ; Map files"])
		_open_dialog.file_selected.connect(_on_open_path_selected)
		add_child(_open_dialog)

	_open_dialog.popup_centered_ratio(0.6)


func _on_open_path_selected(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found: %s" % path)
		return
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_error("Could not read %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	if decode_map(bytes):
		ImageUtils.swap_to_gallery_scene()




func _load_web() -> void:
	if _js_callback == null:
		_js_callback = JavaScriptBridge.create_callback(_on_web_file_loaded)

	var window := JavaScriptBridge.get_interface("window")
	window.godotMapCallback = _js_callback

	JavaScriptBridge.eval("""
		(function () {
			var input = document.createElement('input');
			input.type = 'file';
			input.accept = '.bin';
			input.onchange = function (e) {
				var file = e.target.files[0];
				if (!file) return;
				var reader = new FileReader();
				reader.onload = function () {
					var bytes = new Uint8Array(reader.result);
					var bin = '';
					for (var i = 0; i < bytes.length; i += 0x8000) {
						bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
					}
					window.godotMapCallback(btoa(bin));
				};
				reader.readAsArrayBuffer(file);
			};
			input.click();
		})();
	""", true)


func _on_web_file_loaded(args: Array) -> void:
	var bytes := Marshalls.base64_to_raw(str(args[0]))
	if bytes.is_empty():
		push_error("Received empty file from browser")
		return
	if decode_map(bytes):
		ImageUtils.swap_to_gallery_scene()
