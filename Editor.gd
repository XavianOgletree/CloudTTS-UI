extends Control
signal save_dailog_closed(result)


# Add you API's here
var api_list = {}

# Important UI Elements
onready var TtsTextEdit := $PanelContainer/MarginContainer/HBoxContainer/TtsTextEdit
onready var ApiOptionButton := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/ApiOptionButton
onready var ApiKeyLineEdit := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/GridContainer/ApiKeyLineEdit
onready var SurviceUrlLineEdit := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/GridContainer/SurviceUrlLineEdit
onready var GetVoicesButton := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/GridContainer/GetVoicesButton
onready var VoiceOptionButton := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/GridContainer/VoiceOptionButton
onready var OneFilePerLineBox := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/OneFilePerLineBox
onready var FilePrefixContainer := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/FilePrefixContainer
onready var FilePrefixLineEdit := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/FilePrefixContainer/FilePrefixLineEdit
onready var SaveAudioButton := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/SaveAudioButton
onready var SaveProgressLabel := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/SaveProgressLabel
onready var SaveProgressBar := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/SaveProgressBar

onready var SaveDialog := $DailogLayer/SaveDialog
onready var WarningMessageDialog := $WarningMessageDialog
onready var OverwriteDialog := $DailogLayer/OverwriteDialog
onready var AboutDialog := $AboutDialog

onready var AboutButton := $PanelContainer/MarginContainer/HBoxContainer/Panel/VBoxContainer/AboutButton

# Called when theis node enters the scene tree
func _ready() -> void:
	
	var dir = Directory.new()
	dir.open("res://scripts/apis")
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != '':
		if file_name.begins_with('TextToSpeechApi') or file_name.ends_with('.remap'):
			file_name = dir.get_next()
		else:
			var api = load('res://scripts/apis/%s' % file_name).new()
			api_list[api.get_name()] = api
			file_name = dir.get_next()
	dir.list_dir_end()
	
	for api_name in api_list:
		ApiOptionButton.add_item(api_name)
		api_list[api_name].connect("error_occured", self, "show_message")
	
	var api_name : String = ApiOptionButton.get_item_text(
		ApiOptionButton.selected
	)
	var api = api_list[api_name]
	SurviceUrlLineEdit.visible =  api.needs_url
	
	OneFilePerLineBox.connect("toggled", self, "_on_one_file_per_line_toggled")
	GetVoicesButton.connect("pressed", self, "_on_get_voices_button_pressed")
	SaveAudioButton.connect("pressed", self, "_on_save_audio_button_pressed")
	SaveDialog.connect("dir_selected", self, "_on_dir_selected")
	SaveDialog.connect("file_selected", self, "_on_file_selected")
	SaveDialog.connect("popup_hide", self, "_on_popup_hide")
	
	OverwriteDialog.get_ok().hide()
	OverwriteDialog.add_button("Overwrite", true, "overwrite")
	OverwriteDialog.add_button("Overwrite All", true, "overwrite-all")
	OverwriteDialog.add_button("Skip", true, "skip")
	
	ApiOptionButton.connect('item_selected', self, '_on_item_selected')
	
	AboutButton.connect("pressed", AboutDialog, "popup_centered")


func _on_item_selected(index: int) -> void:
	ApiKeyLineEdit.clear()
	var api_name : String = ApiOptionButton.get_item_text(
		ApiOptionButton.selected
	)
	var api = api_list[api_name]
	SurviceUrlLineEdit.clear()
	SurviceUrlLineEdit.visible = api.needs_url
		
	VoiceOptionButton.clear()
	

func _on_dir_selected(dir: String) -> void:
	emit_signal("save_dailog_closed", dir)


func _on_file_selected(path: String) -> void:
	emit_signal("save_dailog_closed", path)


func _on_popup_hide() -> void:
	emit_signal("save_dailog_closed", "")


func _on_one_file_per_line_toggled(button_pressed: bool) -> void:
	FilePrefixContainer.visible = button_pressed


func _on_get_voices_button_pressed() -> void:
	var api_key : String = ApiKeyLineEdit.text
	var survice_url : String = SurviceUrlLineEdit.text
	var api_name : String = ApiOptionButton.get_item_text(
		ApiOptionButton.selected
	)
	var api = api_list[api_name]
	var voices = api.get_voices($HTTPRequest, api_key, survice_url)
	if voices is GDScriptFunctionState:
		voices = yield(voices, "completed")
	
	VoiceOptionButton.clear()
	if voices.empty():
		return
		
	for i in range(len(voices)):
		var voice = voices[i]
		VoiceOptionButton.add_item(voice.name)
		VoiceOptionButton.set_item_metadata(i, voice.metadata)
	
	VoiceOptionButton.selected = 0


func _on_save_audio_button_pressed() -> void:
	if SaveDialog.visible:
		return
		
	if VoiceOptionButton.selected == -1:
		show_message(Warnings.NO_VOICE_SELECTED)
		return
	
	if TtsTextEdit.text.empty():
		show_message(Warnings.EMPTY_TTS_TEXT)
		return
	
	if ApiKeyLineEdit.text.empty():
		show_message(Warnings.EMPTY_TTS_TEXT)
		return
		
	
	
	var api_key = ApiKeyLineEdit.text
	var survice_url = SurviceUrlLineEdit.text
	var tts_text = TtsTextEdit.text
	var voice_metadata = VoiceOptionButton.get_item_metadata(
		VoiceOptionButton.selected
	)
	var api_name = ApiOptionButton.get_item_text(
		ApiOptionButton.selected
	)
	var api = api_list[api_name]
	
	if SurviceUrlLineEdit.text.empty() and api.needs_url:
		show_message(Warnings.EMPTY_SURVICE_URL)
		return
	
	if OneFilePerLineBox.pressed:
		SaveDialog.mode = FileDialog.MODE_OPEN_DIR
		SaveDialog.popup_exclusive = true
		SaveDialog.popup_centered(get_viewport_rect().size * 0.75)
		
		var file_prefix = FilePrefixLineEdit.text
		if file_prefix.empty():
			emit_signal(Warnings.EMPTY_PREFIX)
			return
		
		var dir = yield(self, "save_dailog_closed")
		if dir.empty():
			show_message(Warnings.NO_DIRECTORY_SELECTED)
			return
		
		var lines = tts_text.split("\n")
		var overwrite_all = false
		var file = File.new()
		
		SaveProgressBar.max_value = len(lines)
		SaveProgressLabel.text = "Saving 0/%d" % len(lines)
		for i in range(len(lines)):
			var file_path = dir + "/" + file_prefix + "%02d.mp3" % i
			
			if not overwrite_all and file.file_exists(file_path):
				OverwriteDialog.popup_centered()
				OverwriteDialog.dialog_text = "File %s exist. Do you want to overwrite it?" % file_path
				
				var choice = yield(OverwriteDialog, "custom_action")
				match choice:
					"overwrite-all":
						overwrite_all = true
					"skip":
						continue
				
				OverwriteDialog.hide()
			
			var result = save_single_audio_file(
				api, 
				api_key, 
				survice_url, 
				lines[i], 
				voice_metadata, 
				file_path
			)
			
			if result is GDScriptFunctionState:
				yield(result, "completed")
			
			set_progress(i + 1, len(lines))
		
		set_progress(len(lines), len(lines))
		show_message("All files saved!")
		
	else:
		SaveDialog.mode = FileDialog.MODE_SAVE_FILE
		SaveDialog.popup_exclusive = true
		SaveDialog.popup_centered_clamped(get_viewport_rect().size - Vector2(100, 100) * 0.75)
		
		var file_path : String = yield(self, "save_dailog_closed")
		if file_path.empty() or file_path.ends_with("/.mp3"):
			show_message(Warnings.NO_FILE_SELECTED)
			return 
		
		save_single_audio_file(
			api, 
			api_key, 
			survice_url, 
			tts_text, 
			voice_metadata, 
			file_path
		)
		
		show_message("Audio successfully saved!")


func save_single_audio_file(
		api,
		api_key : String,
		survice_url : String,
		tts_text : String,
		voice_metadata,
		file_path : String) -> void:
	
	var audio_data = api.get_audio(
		$HTTPRequest, 
		api_key, 
		survice_url,
		tts_text,
		voice_metadata
	)
	if audio_data is GDScriptFunctionState:
		audio_data = yield(audio_data, "completed")
	
	if audio_data.empty():
		show_message("No audio recieved.")
		return
	
	
	var file := File.new()
	file.open(file_path, File.WRITE)
	file.store_buffer(audio_data)
	file.close()


func show_message(text: String) -> void:
		WarningMessageDialog.dialog_text = text
		WarningMessageDialog.popup_centered()


func set_progress(current: int, count: int) -> void:
	SaveProgressBar.value = current
	SaveProgressLabel.text = "Saving %d/%d" % [current, count]
	

