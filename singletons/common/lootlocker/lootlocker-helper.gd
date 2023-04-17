extends Node

# Set by LootLocker
var _sessionToken = ""
var _playerIdentifier = ""

# Set these using the Set methods from your project so
# you can easily copy/paste this helper file into other projects
# without changing anything
var _gameApiKey = ""
var _developmentMode = true
var _playerId = ""
var _gameVersion = "0.0.0.1"

func _ready():
	Signals.connect("SessionCreated", self, "SessionCreated")

func GetSessionToken():
	return _sessionToken
	
func GetPlayerId():
	return _playerId
	
func SessionCreated(sessionToken):
	_sessionToken = sessionToken

func SetGameVersion(value : String):
	_gameVersion = value
	
func SetGameApiKey(value : String):
	_gameApiKey = value

func SetDevelopmentMode(value : bool):
	_developmentMode = value

func LoadLocalPlayerData():
	var file : File = File.new()
	var playerData = []
	if file.file_exists("user://LootLocker.data"):
		file.open("user://LootLocker.data", File.READ)
		var playerDataText = file.get_as_text()
		playerData = playerDataText.split(",", false)
		if playerData.size() > 0:
			_playerId = playerData[0]
			_playerIdentifier = playerData[1]
		file.close()
	return playerData
			
# If the user doesn't have a unique player identifier, LootLocker
# will create one and return it in the response. 
func Login():
	LoadLocalPlayerData()
	var data = ""

	if(_playerId == ""):
		# Player data doesn't exist so we'll create a new one
		data = { "game_key": _gameApiKey, "game_version": _gameVersion, "development_mode": _developmentMode }
	else:
		# Player identifier exists. Use it.
		data = { "game_key": _gameApiKey, "player_identifier":_playerIdentifier, "game_version": _gameVersion, "development_mode": _developmentMode }

	var url = "https://api.lootlocker.io/game/v2/session/guest"
	var method = HTTPClient.METHOD_POST
	var headers = ["Content-Type: application/json"]

	var httpRequest = HttpHelper.CreateHttpRequest()
	httpRequest.connect("request_completed", self, "_on_auth_request_completed")
	httpRequest.request(url, headers, true, method, to_json(data))

func _on_auth_request_completed(_result, _response_code, _headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if _response_code != 200:
		var debugDetails = parse_json(body.get_string_from_ascii())
		print("_on_auth_request_completed debugDetails: " + str(debugDetails))
		return
	
	# Save player_identifier to file
	var file = File.new()
	file.open("user://LootLocker.data", File.WRITE)
	file.store_string(str(json.result.player_id) + "," + str(json.result.player_identifier))
	file.close()
	
	# Store session_token 
	SessionCreated(json.result.session_token)
	
	Signals.emit_signal("AuthenticationWithLootLockerSucceeded")
