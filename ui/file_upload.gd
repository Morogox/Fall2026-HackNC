extends Node

const GALLERY_SCENE_PATH := "res://gallery.tscn"
const WEB_POLL_TIMEOUT_SEC := 120.0

var file_dialog: FileDialog
var uploaded_textures: Array[ImageTexture] = [] # unscaled image textures
var _web_polling := false


func _ready() -> void:
	_setup_desktop_dialog()


func _setup_desktop_dialog() -> void:
	if not OS.has_feature("web"):
		file_dialog = FileDialog.new()
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
		file_dialog.files_selected.connect(_on_desktop_files_selected)
		add_child(file_dialog)


func _reset_batch() -> void:
	uploaded_textures.clear()
	ImageUtils.texture_names.clear()
	ImageUtils.texture_unixTime.clear()


func _store_file_metadata(img: Image, file_name: String, unix_time: float) -> void:
	var texture := ImageTexture.create_from_image(img)
	uploaded_textures.append(texture)
	ImageUtils.texture_names.append(file_name)
	ImageUtils.texture_unixTime.append(unix_time)
	print("Stored Metadata -> Name: %s, Time: %f" % [file_name, unix_time])


# On button click
func _onUploadButtonPress() -> void:
	print("File Upload Button Pressed")
	if OS.has_feature("web"):
		_open_web_file_popup()
	else:
		file_dialog.popup_centered_ratio(0.4)



func _on_desktop_files_selected(paths: PackedStringArray) -> void:
	_reset_batch()

	for path in paths:
		var img := Image.new()
		var error := img.load(path)

		if error == OK:
			var filename := path.get_file()
			var unix_time := FileAccess.get_modified_time(path)

			_store_file_metadata(img, filename, float(unix_time))
			print("Successfully loaded desktop image: ", filename)
		else:
			print("Failed to load desktop image: ", path.get_file(), " Error: ", error)

	_on_all_files_ready()


func _open_web_file_popup() -> void:
	if _web_polling:
		return # a previous upload is still pending

	var js_code := """
	(function() {
		let input = document.getElementById('godot-file-uploader');
		if (!input) {
			input = document.createElement('input');
			input.id = 'godot-file-uploader';
			input.type = 'file';
			input.multiple = true;
			input.accept = 'image/*';
			input.style.display = 'none';
			document.body.appendChild(input);
		}
		// Allow re-selecting the same files (onchange won't fire otherwise)
		input.value = '';
		window.webUploadComplete = false;
		window.uploadedFilesData = null;

		input.onchange = function(e) {
			let files = e.target.files;
			if (!files || files.length === 0) return;

			// Index-based results so selection order is preserved
			let results = new Array(files.length);
			let loaded = 0;

			for (let i = 0; i < files.length; i++) {
				let f = files[i];
				let reader = new FileReader();
				reader.onload = function(ev) {
					results[i] = {
						name: f.name,
						lastModified: f.lastModified, // Unix ms timestamp
						b64: ev.target.result.split(',')[1]
					};
					loaded++;
					if (loaded === files.length) {
						window.uploadedFilesData = JSON.stringify(results);
						window.webUploadComplete = true;
					}
				};
				reader.onerror = function() {
					results[i] = null;
					loaded++;
					if (loaded === files.length) {
						window.uploadedFilesData = JSON.stringify(results);
						window.webUploadComplete = true;
					}
				};
				reader.readAsDataURL(f);
			}
		};

		input.click();
	})();
	"""
	JavaScriptBridge.eval(js_code)
	_poll_web_upload()



func _poll_web_upload() -> void:
	_web_polling = true
	var elapsed := 0.0

	while not JavaScriptBridge.eval("window.webUploadComplete === true"):
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if elapsed > WEB_POLL_TIMEOUT_SEC:
			print("Web upload timed out or was cancelled.")
			_web_polling = false
			return

	_web_polling = false
	_process_web_uploaded_files()


func _process_web_uploaded_files() -> void:
	var json_str = JavaScriptBridge.eval("window.uploadedFilesData")
	JavaScriptBridge.eval("window.uploadedFilesData = null; window.webUploadComplete = false;")

	if typeof(json_str) != TYPE_STRING:
		print("No files data found from the browser upload pipeline.")
		return

	var files = JSON.parse_string(json_str)
	if typeof(files) != TYPE_ARRAY:
		print("Could not parse files data from the browser upload pipeline.")
		return

	_reset_batch()

	for i in files.size():
		var f = files[i]
		if f == null:
			print("Failed to read web file at index: ", i)
			continue

		var bytes := Marshalls.base64_to_raw(f.b64)
		var img := _image_from_buffer(bytes, f.name)

		if img:
			# Convert ms to seconds
			var unix_time := float(f.lastModified) / 1000.0
			_store_file_metadata(img, f.name, unix_time)
			print("Successfully loaded web image: ", f.name)
		else:
			print("Failed to parse web image: ", f.name)

	_on_all_files_ready()


func _image_from_buffer(bytes: PackedByteArray, file_name: String) -> Image:
	if bytes.is_empty():
		return null

	var img := Image.new()
	var err := ERR_FILE_UNRECOGNIZED

	match file_name.get_extension().to_lower():
		"png":
			err = img.load_png_from_buffer(bytes)
		"jpg", "jpeg":
			err = img.load_jpg_from_buffer(bytes)
		"webp":
			err = img.load_webp_from_buffer(bytes)

	return img if err == OK else null


# when upload finishes
func _on_all_files_ready() -> void:
	print("Total files captured: ", uploaded_textures.size())

	if uploaded_textures.is_empty():
		return

	# Post upload logic
	if ImageUtils.debug:
		_debug_display_textures()

	ImageUtils._process_textures(uploaded_textures)
	uploaded_textures.clear()

	if ImageUtils.debug:
		_swap_to_gallery_scene()


func _debug_display_textures() -> void:
	for i in uploaded_textures.size():
		print(i, ": ", ImageUtils.texture_names[i], " (",
			uploaded_textures[i].get_width(), "x", uploaded_textures[i].get_height(), ")")



func _swap_to_gallery_scene() -> void:
	if not ResourceLoader.exists(GALLERY_SCENE_PATH):
		push_error("Gallery scene not found: " + GALLERY_SCENE_PATH)
		return

	get_tree().change_scene_to_file.call_deferred(GALLERY_SCENE_PATH)
