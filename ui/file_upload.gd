extends Node

var file_dialog: FileDialog
var uploaded_textures: Array[ImageTexture] = [] # unscaled image texture


func _ready():
	_setup_desktop_dialog()

func _setup_desktop_dialog():
	if not OS.has_feature("web"):
		file_dialog = FileDialog.new()
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg ; Images"])
		file_dialog.files_selected.connect(_on_desktop_files_selected)
		add_child(file_dialog)

# Central helper function to extract and manage metadata
func _store_file_metadata(img: Image, file_name: String, unix_time: float) -> void:
	var texture = ImageTexture.create_from_image(img)
	uploaded_textures.append(texture)
	ImageUtils.texture_names.append(file_name)
	ImageUtils.texture_unixTime.append(unix_time)
	print("Stored Metadata -> Name: %s, Time: %f" % [file_name, unix_time])

# On button click
func _onUploadButtonPress() -> void:
	print("File Upload Button Pressed")
	# Reset previous batch across all metadata arrays
	uploaded_textures.clear()
	ImageUtils.texture_names.clear()
	ImageUtils.texture_unixTime.clear()
	
	if OS.has_feature("web"):
		_open_web_file_popup()
	else:
		file_dialog.popup_centered_ratio(0.4)

# Desktop version
func _on_desktop_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		var img = Image.new()
		var error = img.load(path)
		
		if error == OK:
			var filename = path.get_file()
			# Fetch local desktop filesystem last modification time
			var unix_time = FileAccess.get_modified_time(path)
			
			_store_file_metadata(img, filename, float(unix_time))
			print("Successfully loaded desktop image: ", filename)
		else:
			print("Failed to load desktop image: ", path.get_file(), " Error: ", error)
			
	_on_all_files_ready()

# Web version
func _open_web_file_popup() -> void:
	var js_code = """
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
		
		input.onchange = function(e) {
			let files = e.target.files;
			if (!files || files.length === 0) return;
			
			window.uploadedFilesData = [];
			window.webUploadComplete = false;
			let loadedCount = 0;
			
			for(let i = 0; i < files.length; i++) {
				let reader = new FileReader();
				let currentFile = files[i];
				
				reader.onload = function(event) {
					let bytes = new Uint8Array(event.target.result);
					
					// Package file data alongside metadata objects
					window.uploadedFilesData.push({
						name: currentFile.name,
						lastModified: currentFile.lastModified, // Unix ms timestamp
						bytes: bytes
					});
					
					loadedCount++;
					if (loadedCount === files.length) {
						window.webUploadComplete = true;
					}
				};
				reader.readAsArrayBuffer(currentFile);
			}
		};
		
		input.click();
	})();
	"""
	JavaScriptBridge.eval(js_code)
	_poll_web_upload()

# Repeatedly check if JS finished loading all selected files asynchronously
func _poll_web_upload() -> void:
	var is_complete = JavaScriptBridge.eval("window.webUploadComplete")
	if is_complete:
		_process_web_uploaded_files()
	else:
		await get_tree().process_frame
		_poll_web_upload()

func _process_web_uploaded_files() -> void:
	var files_array = JavaScriptBridge.eval("window.uploadedFilesData")
	
	if files_array:
		for i in range(files_array.length):
			var file_obj = files_array[i]
			var file_data: PackedByteArray = file_obj.bytes
			
			if file_data and file_data.size() > 0:
				var img = Image.new()
				var error = img.load_from_buffer(file_data)
				
				if error == OK:
					var filename = file_obj.name
					# Convert to seconds
					var unix_time = float(file_obj.lastModified) / 1000.0 
					
					_store_file_metadata(img, filename, unix_time)
					print("Successfully loaded web image index: ", i)
				else:
					print("Failed to parse web image index: ", i, " Error: ", error)
					
		# Clean up JavaScript context window
		JavaScriptBridge.eval("window.uploadedFilesData = null; window.webUploadComplete = false;")
		_on_all_files_ready()
	else:
		print("No files data found from the browser upload pipeline.")

func _on_all_files_ready() -> void:
	print("Total files captured: ", uploaded_textures.size())
	# Post uplaod logic
	if(ImageUtils.debug): _debug_display_textures();
	ImageUtils._process_textures(uploaded_textures);
	
func _debug_display_textures() -> void:
	for i in uploaded_textures.size():
		print(i);
	pass
