extends Control
# Some precoded messages
const API_WARNING := "There is no API key provided. Please provide API key."
const TTS_EMPTY_WARNING := "There is no text to make into speech. Please provide Text."
const SURVICE_URL_WARNING := "There is no survice URL. Please provide service URL"
const PREFIX_EMPTY_WARNING := "There is no file prefix. Please provide a file prefix"

# Important UI Elements
onready var TtsTextEdit := $PanelContainer/MarginContainer/HBoxContainer/TtsTextEdit
onready var ApiOptionButton := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/ApiOptionButton
onready var ApiKeyLineEdit := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/ApiKeyLineEdit
onready var SurviceUrlLineEdit := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/SurviceUrlLineEdit
onready var GetVoicesButton := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/GetVoicesButton
onready var VoiceOptionButton := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/GridContainer/VoiceOptionButton
onready var OneFilePerLineBox := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/OneFilePerLineBox
onready var FilePrefixContainer := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/FilePrefixContainer
onready var FilePrefixLineEdit := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/FilePrefixContainer/FilePrefixLineEdit
onready var SaveAudioButton := $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/SaveAudioButton
onready var SaveDailog := $PanelContainer/SaveDailog
onready var WarningMessageDailog := $PanelContainer/WarningMessageDailog

# Called when theis node enters the scene tree
func _ready():
	ApiOptionButton.add_item("Google")
	ApiOptionButton.add_item("IBM")
	
	GetVoicesButton.connect("pressed", self, "_on_get_voices_button_pressed")
	SaveAudioButton.connect("pressed", self, "_on_save_audio_button_pressed")
	

func _on_get_voices_button_pressed() -> void:
	if ApiKeyLineEdit.text.empty():
		show_message(API_WARNING)
		return
	
	var api_key : String = ApiKeyLineEdit.text
	var survice_url : String = SurviceUrlLineEdit.text
	var voices : Array
	match ApiOptionButton.get_item_text(ApiOptionButton.selected):
		"Google":
			voices = yield(get_voices_google(api_key, survice_url), "completed")
			
		"IBM":
			pass
	
	VoiceOptionButton.clear()
	for i in range(len(voices)):
		var voice = voices[i]
		VoiceOptionButton.add_item(voice.name)
		VoiceOptionButton.set_item_metadata(i, voice.metadata)
				
func _on_save_audio_button_pressed() -> void:
	if SaveDailog.visible:
		return
		
	if ApiKeyLineEdit.text.empty():
		show_message(API_WARNING)
		return
	
	if SurviceUrlLineEdit.text.empty():
		show_message(SURVICE_URL_WARNING)
		return
	
	if TtsTextEdit.text.empty():
		show_message(TTS_EMPTY_WARNING)
		return
	
	else:
		var tts_text = TtsTextEdit.text
		
		if OneFilePerLineBox.pressed:
			if FilePrefixLineEdit.text.empty():
				show_message(PREFIX_EMPTY_WARNING)
				return
			
			SaveDailog.mode = FileDialog.MODE_OPEN_DIR
			SaveDailog.popup_exclusive = true
			SaveDailog.popup_centered()
			var file_dir : String = yield(SaveDailog, "dir_selected")
			var file_prefix : String = FilePrefixLineEdit.text
			
			
			
		else:
			SaveDailog.mode = FileDialog.MODE_OPEN_FILE
			SaveDailog.popup_exclusive = true
			SaveDailog.popup_centered()
			var file_path : String = yield(SaveDailog, "file_selected")
			save_single_audio_file(tts_text, file_path)
			

func save_multiple_audio_file(tts_text: String, file_dir: String, file_prefix: String) -> void:
	var lines = tts_text.split("\n")
	for i in range(len(lines)):
		pass
		#save_single_audio_file(file_dir + "/" + file_prefix)

func save_single_audio_file(tts_text: String, file_path: String) -> void:
	var api_key : String = ApiKeyLineEdit.text
	var survice_url : String = SurviceUrlLineEdit.text
	var audio_data : PoolByteArray
	match ApiOptionButton.get_item_text(ApiOptionButton.selected):
		"Google":
			audio_data = yield(get_audio_google(api_key, survice_url, tts_text), "completed")
			
		"IBM":
			pass
	
	if not audio_data:
		return

func get_voices_google(api_key: String, api_url: String) -> Array:
	var url = "https://texttospeech.googleapis.com/v1/voices?key=%s&languageCode=en-US" % api_key
	$HTTPRequest.request(url)
	
	var response = yield($HTTPRequest, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var headers: PoolStringArray = response[2]
	var body: PoolByteArray = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS:
		var json = JSON.parse(body.get_string_from_utf8()).result
		var voices : Array = []
		for voice in json.voices:
			if voice.languageCodes[0] == "en-US":
				voices.append({name = "%s %s" % [voice.name, voice.ssmlGender], metadata = voice})
		
		return voices
		
	else:
		show_message("%d\n%s" % [code, body.get_string_from_utf8()])
		return []
	
	

func get_voices_ibm(api_key: String, api_url: String) -> Array:
	if SurviceUrlLineEdit.text.empty():
		show_message(SURVICE_URL_WARNING) 
	
	return []


func get_audio_google(api_key: String, api_url: String, text: String) -> PoolByteArray:
	var url = "%s?key=%s" % [api_url, api_key]
	var selected_voice_index = VoiceOptionButton.selected
	var voice_metadata = VoiceOptionButton.get_item_metadata(selected_voice_index)
	
	var json := to_json({
		input = {text = text},
		voice = {
			languageCode = voice_metadata.languageCodes[0],
			name = voice_metadata.name,
			ssmlGender = voice_metadata.ssmlGender,
		},
		audioConfig = {audioEncoding = 'MP3'}
	})
	var request_headers := ["Content-Type: application/json"]
	
	$HTTPRequest.request(url, request_headers, true, HTTPClient.METHOD_POST, json)
	var response = yield($HTTPRequest, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var response_headers: PoolStringArray = response[2]
	var body: PoolByteArray = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var audio_data = JSON.parse(body.get_string_from_utf8()).result.audioContent
		return Marshalls.base64_to_raw(audio_data)
		
	else:
		show_message("%d\n%s" % [code, body.get_string_from_utf8()])
		return null

func get_audio_ibm():
	pass

func show_message(text: String) -> void:
		WarningMessageDailog.dialog_text = text
		WarningMessageDailog.popup_centered()
