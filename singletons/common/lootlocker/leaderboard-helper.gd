extends Node

var _leaderboardKey = ""
var _leaderboards = []

func SetLeaderboardKey(value):
	_leaderboardKey = value

func GetLeaderboard():
	return _leaderboards
	
func UploadScore(score):
	var data = { "score": str(score) }
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken()]
	var httpRequest = HttpHelper.CreateHttpRequest()
	httpRequest.connect("request_completed", self, "_on_upload_score_request_completed")
	httpRequest.request("https://api.lootlocker.io/game/leaderboards/" + _leaderboardKey + "/submit", headers, true, HTTPClient.METHOD_POST, to_json(data))
	
func GetPlayerHighScore():
	var url = "https://api.lootlocker.io/game/leaderboards/" + _leaderboardKey + "/member/" + LootLocker.GetPlayerId()
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken()]
	var httpRequest = HttpHelper.CreateHttpRequest()
	httpRequest.connect("request_completed", self, "_get_player_highscore_completed")
	httpRequest.request(url, headers, true, HTTPClient.METHOD_GET, "")
		
func GetLeaderboards(count = 10):
	var url = "https://api.lootlocker.io/game/leaderboards/" + _leaderboardKey + "/list?count=" + str(count)
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken()]
	var httpRequest = HttpHelper.CreateHttpRequest()
	httpRequest.connect("request_completed", self, "_get_leaderboards_completed")
	httpRequest.request(url, headers, true, HTTPClient.METHOD_GET, "")

func SetPlayerName(playerName):
	var data = "{\"name\": \"" + playerName + "\"}"
	var url = "https://api.lootlocker.io/game/player/name"
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken(), "LL-Version: 2021-03-01"]
	var httpRequest = HttpHelper.CreateHttpRequest()
	httpRequest.connect("request_completed", self, "_save_player_name_completed")
	httpRequest.request(url, headers, true, HTTPClient.METHOD_PATCH, data)

func DisplayErrorMessage(errorMessage):
	print(str(errorMessage))
	
func _get_leaderboards_completed(_result, _response_code, _headers, body):
	var json = JSON.parse(body.get_string_from_utf8())

	if _response_code != 200:
		DisplayErrorMessage(parse_json(body.get_string_from_ascii()))
		return

	_leaderboards.clear()	
	for n in json.result.items.size():
		var playerData = json.result.items[n]
		var lineItem = str(playerData["player"]["name"]) + ","
		lineItem += str(playerData["score"])
		_leaderboards.append(lineItem)
	
	Signals.emit_signal("GetLeaderboardsCompleted")

func _on_upload_score_request_completed(_result, _response_code, _headers, body):
	if _response_code != 200:
		DisplayErrorMessage(parse_json(body.get_string_from_ascii()))
		return
		
	Signals.emit_signal("UploadingScoreCompleted")

func _save_player_name_completed(_result, _response_code, _headers, body):
	if _response_code != 200:
		DisplayErrorMessage(parse_json(body.get_string_from_ascii()))
		return
	
	Signals.emit_signal("SavePlayerNameCompleted")
