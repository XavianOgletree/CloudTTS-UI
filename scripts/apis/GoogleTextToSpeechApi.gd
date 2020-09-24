extends "res://scripts/apis/TextToSpeechAPI.gd"

func get_voices(
		http: HTTPRequest,
		api_key: String = "", 
		api_url: String = "") -> Array:
	
	if api_key.empty():
		emit_signal("error_occured", "There is no API key provided. Please provide API key.")
		return []
	
	var url = "https://texttospeech.googleapis.com/v1/voices?key=%s&languageCode=en-US" % api_key
	http.request(url)
	
	var response = yield(http, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var headers: PoolStringArray = response[2]
	var body: PoolByteArray = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json = JSON.parse(body.get_string_from_utf8()).result
		var voices : Array = []
		for voice in json.voices:
			if voice.languageCodes[0] == "en-US":
				voices.append({name = "%s %s" % [voice.name, voice.ssmlGender], metadata = voice})
		
		return voices
		
	else:
		emit_signal("%d\n%s" % [code, body.get_string_from_utf8()])
		return []
		
	

func get_audio(
		http: HTTPRequest,
		api_key: String, 
		api_url: String, 
		text: String, 
		voice_metadata) -> PoolByteArray:
	
	if api_key.empty():
		emit_signal("error_occured", Warnings.EMPTY_API)
		return PoolByteArray([])
	
	var url = "https://texttospeech.googleapis.com/v1/text:synthesize?key=%s" % [api_key]
	
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
	
	http.request(url, request_headers, true, HTTPClient.METHOD_POST, json)
	var response = yield(http, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var response_headers: PoolStringArray = response[2]
	var body: PoolByteArray = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var audio_data = JSON.parse(body.get_string_from_utf8()).result.audioContent
		return Marshalls.base64_to_raw(audio_data)
		
	else:
		emit_signal("error_occured", "Status Code %d\n%s" % [code, body.get_string_from_utf8()])
		return PoolByteArray([])