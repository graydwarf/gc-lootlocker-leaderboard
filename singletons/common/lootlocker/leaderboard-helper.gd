extends Node

var _leaderboardKey = ""
var _leaderboards = []

# Set these using the Set methods from your project so
# you can easily copy/paste this helper file into other projects
# without changing anything
var _uploadScoreHttpRequest
var _getPlayerHighscoreHttpRequest
var _getLeaderboardsHttpRequest
var _setPlayerNameHttpRequest

func SetLeaderboardKey(value):
	_leaderboardKey = value

func GetLeaderboard():
	return _leaderboards
	
func UploadScore(score):
	var data = { "score": str(score) }
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken()]
	_uploadScoreHttpRequest = HttpHelper.CreateHttpRequest()
	_uploadScoreHttpRequest.connect("request_completed", self, "_on_upload_score_request_completed")
	_uploadScoreHttpRequest.request("https://api.lootlocker.io/game/leaderboards/" + _leaderboardKey + "/submit", headers, true, HTTPClient.METHOD_POST, to_json(data))

func GetLeaderboards(count = 10):
	var url = "https://api.lootlocker.io/game/leaderboards/" + _leaderboardKey + "/list?count=" + str(count)
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken()]
	_getLeaderboardsHttpRequest = HttpHelper.CreateHttpRequest()
	_getLeaderboardsHttpRequest.connect("request_completed", self, "_get_leaderboards_completed")
	_getLeaderboardsHttpRequest.request(url, headers, true, HTTPClient.METHOD_GET, "")

func SetPlayerName(playerName):
	var data = "{\"name\": \"" + playerName + "\"}"
	var url = "https://api.lootlocker.io/game/player/name"
	var headers = ["Content-Type: application/json", "x-session-token:" + LootLocker.GetSessionToken(), "LL-Version: 2021-03-01"]
	_setPlayerNameHttpRequest = HttpHelper.CreateHttpRequest()
	_setPlayerNameHttpRequest.connect("request_completed", self, "_set_player_name_completed")
	_setPlayerNameHttpRequest.request(url, headers, true, HTTPClient.METHOD_PATCH, data)

func DisplayErrorMessage(errorMessage):
	print(str(errorMessage))
	
func _get_leaderboards_completed(_result, _response_code, _headers, body):
	_getLeaderboardsHttpRequest.queue_free()

	if _response_code != 200:
		DisplayErrorMessage(parse_json(body.get_string_from_ascii()))
		return

	var json = JSON.parse(body.get_string_from_utf8())
	_leaderboards.clear()	
	for n in json.result.items.size():
		var playerData = json.result.items[n]
		var lineItem = str(playerData["player"]["name"]) + ","
		lineItem += str(playerData["score"])
		_leaderboards.append(lineItem)
	
	Signals.emit_signal("GetLeaderboardsCompleted")

func _on_upload_score_request_completed(_result, _response_code, _headers, body):
	_uploadScoreHttpRequest.queue_free()
	
	if _response_code != 200:
		DisplayErrorMessage(parse_json(body.get_string_from_ascii()))
		return
		
	Signals.emit_signal("UploadingScoreCompleted")

func _set_player_name_completed(_result, _response_code, _headers, body):
	_setPlayerNameHttpRequest.queue_free()
	
	if _response_code != 200:
		DisplayErrorMessage(parse_json(body.get_string_from_ascii()))
		return
	
	Signals.emit_signal("SavePlayerNameCompleted")
