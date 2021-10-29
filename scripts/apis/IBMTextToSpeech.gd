extends "res://scripts/apis/TextToSpeechApi.gd"
const SortingUtils = preload("res://scripts/utils/SortingUtils.gd")

func get_needs_url() -> bool:
	return true

func get_name() -> String:
	return "IBM"

func get_voices(
		http: HTTPRequest,
		api_key: String = "", 
		api_url: String = "") -> Array:
	
	if api_key.empty():
		emit_signal("error_occured", Warnings.EMPTY_API)
		return []
	
	if api_url.empty():
		emit_signal("error_occured", Warnings.EMPTY_SURVICE_URL)
		return []
	
	var url = "%s/v1/voices" % api_url
	var request_headers = [
		"Authorization: Basic %s" % Marshalls.utf8_to_base64('apikey:%s' % api_key)
	]
	
	var err = http.request(url, request_headers)
	if err != OK:
		emit_signal("error_occured", Warnings.INVALID_URL)
		return []
	
	
	var response = yield(http, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var headers: PoolStringArray = response[2]
	var body: PoolByteArray = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var json = JSON.parse(body.get_string_from_utf8()).result
		var voices : Array = []
		for voice in json.voices:
			if voice.language == "en-US":
				voices.append({name = "%s %s" % [voice.name.replace('en-US_',''), voice.gender], metadata = voice})
		
		voices.sort_custom(SortingUtils, "sort_decending_by_name")
		return voices
		
	elif code == 404:
		emit_signal("error_occured", Warnings.INVALID_URL_REQUEST)
		return []
		
	elif code == 401:
		emit_signal("error_occured", Warnings.INVALID_API_KEY)
		return []
		
	elif result == HTTPRequest.RESULT_SUCCESS:
		emit_signal("error_occured", "%d\n%s" % [code, parse_json(body.get_string_from_utf8()).error.message])
		return []
	
	else:
		emit_signal("error_occured", Warnings.UNKNOWN_ERROR)
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
	
	if api_url.empty():
		emit_signal("error_occured", Warnings.EMPTY_TTS_TEXT)
		return PoolByteArray([])
	
	var url = "%s/v1/synthesize?voice=%s" % [api_url, voice_metadata.name]
	
	var json := to_json({
		text = text,
	})
	
	var request_headers := [
		"Content-Type: application/json",
		"Accept: audio/mp3",
		"Authorization: Basic %s" % Marshalls.utf8_to_base64('apikey:%s' % api_key)	
	]
	
	http.request(url, request_headers, true, HTTPClient.METHOD_POST, json)
	var response = yield(http, "request_completed")
	var result: int = response[0]
	var code: int = response[1]
	var response_headers: PoolStringArray = response[2]
	var body: PoolByteArray = response[3]
	
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		return body
		
	else:
		emit_signal("error_occured", "Status Code %d\n%s" % [code, body.get_string_from_utf8()])
		return PoolByteArray([])
