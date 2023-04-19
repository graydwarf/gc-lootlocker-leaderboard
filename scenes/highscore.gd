extends ColorRect
# Custom Project Settings: (I change these on all my projects)
# - Project -> Project Settings -> Debug -> GDScript -> Unused Signal = false
# - Project -> Project Settings -> Debug -> GDScript -> Return Value Discarded = false
#
# Notes:
# - This project was converted from the Godot Companion example so it's possible
# that I've missed something while grooming the project for standalone.
#
# - See LootLocker for more details on how to make your leaderboards more secure. 
# In short, you'll need to have a server sitting in the middle. If you aren't overly
# concerned about people posting fake highscores, this implementation should meet 
# your testing/early access needs.

# https://ref.lootlocker.com/game-api/#leaderboards

onready var _loadingAnimationPlayer = $LoadingAnimationPlayer
onready var _loadingAnimationSprite = $LoadingAnimationSprite
onready var _leaderboardContainer = $ScrollContainer/LeaderboardVBoxContainer
onready var _initialsLineEdit = $InitialsLineEdit
onready var _errorLabel = $ErrorLabel

# Change these values to match yours
var _gameApiKey = "YOUR-GAME-API-KEY-GOES-HERE" # Example: dev_b745dc17379vae8as6e1ddfe2dcs6faasf8
var _leaderboardKey = "YOU-LEADERBOARD-KEY-GOES-HERE"  # Example: my-highscore-board
var _isDebugging = true # See LootLocker for more info on prod vs staging environments

func _ready():
	randomize()
	InitSignals()
	StartLoadingAnimation()
	LootLocker.SetGameApiKey(_gameApiKey)
	LootLocker.SetDevelopmentMode(_isDebugging)
	LootLocker.Login()

func InitSignals():
	Signals.connect("AuthenticationWithLootLockerSucceeded", self, "AuthenticationWithLootLockerSucceeded")
	Signals.connect("DoneGettingPlayersVisitedCount", self, "DoneGettingPlayersVisitedCount")
	Signals.connect("GetPlayerDataCompleted", self, "GetPlayerDataCompleted")
	Signals.connect("SavePlayerDataCompleted", self, "SavePlayerDataCompleted")
	Signals.connect("GetLeaderboardsCompleted", self, "GetLeaderboardsCompleted")
	Signals.connect("UploadingScoreCompleted", self, "UploadingScoreCompleted")
	Signals.connect("SavePlayerNameCompleted", self, "SavePlayerNameCompleted")

# Detect app closing via X or alt+f4
func _notification(notificationType):
	if notificationType == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		LootLocker.EndSession()
		get_tree().quit()
		
func AuthenticationWithLootLockerSucceeded():
	Leaderboard.SetLeaderboardKey(_leaderboardKey)
	Leaderboard.GetLeaderboards(10)
	
func StartLoadingAnimation():
	_loadingAnimationPlayer.play("Spin")
	_loadingAnimationSprite.visible = true

func StopLoadingAnimation():
	_loadingAnimationPlayer.stop()
	_loadingAnimationSprite.visible = false
	
# Name was saved.
# Now save the score.
func SavePlayerNameCompleted():
	# Callback goes to UploadingScoreCompleted()
	var score = Common.Rand(1, 100000)
	Leaderboard.UploadScore(score)
	
func ClearScores():
	for child in _leaderboardContainer.get_children():
		child.queue_free()
		
func UploadingScoreCompleted():
	ClearScores()
	
	# Callback goes to GetLeaderboardsCompleted()
	Leaderboard.GetLeaderboards(10)

func GetLeaderboardsCompleted():
	# Add headers 
	var line = HBoxContainer.new()
	_leaderboardContainer.add_child(line)
	line.size_flags_horizontal = SIZE_EXPAND_FILL
	line.alignment = BoxContainer.ALIGN_CENTER
		
	var lineEdit = LineEdit.new()
	lineEdit.text = "Player Name:"
	line.add_child(lineEdit)
	lineEdit.size_flags_horizontal = SIZE_EXPAND_FILL

	lineEdit = LineEdit.new()
	lineEdit.text = "Score:"
	line.add_child(lineEdit)
	lineEdit.size_flags_horizontal = SIZE_EXPAND_FILL
	
	# Add player name and score
	for leader in Leaderboard.GetLeaderboard():
		var playerName = leader.split(",")[0]
		var playerScore = leader.split(",")[1]
			
		line = HBoxContainer.new()
		_leaderboardContainer.add_child(line)
		line.size_flags_horizontal = SIZE_EXPAND_FILL
		line.alignment = BoxContainer.ALIGN_CENTER
		
		lineEdit = LineEdit.new()
		lineEdit.text = " " + playerName
		line.add_child(lineEdit)
		lineEdit.size_flags_horizontal = SIZE_EXPAND_FILL
		lineEdit.editable = false
		lineEdit.theme = load("res://assets/themes/toolbox-lootlocker-highscore-lineitem_theme.tres")

		lineEdit = LineEdit.new()
		lineEdit.text = " " + playerScore
		line.add_child(lineEdit)
		lineEdit.size_flags_horizontal = SIZE_EXPAND_FILL
		lineEdit.editable = false
		lineEdit.theme = load("res://assets/themes/toolbox-lootlocker-highscore-lineitem_theme.tres")
	
	StopLoadingAnimation()
	
func DisplayErrorMessage(message):
	_errorLabel.text = message
	
func InitialsValid():
	var badWords = BadWords.new().GetBadWords()
	var initials = _initialsLineEdit.text
	if initials.length() < 3:
		DisplayErrorMessage("Needs to be 3 characters")
		return false
	
	for badWord in badWords:
		if badWord == initials.to_lower():
			DisplayErrorMessage("Please change your initials and try again.")
			return false
	
	return true

func ClearErrorLabel():
	_errorLabel.text = ""
	
func _on_SubmitHighscoreButton_pressed():
	ClearErrorLabel()
	
	if !InitialsValid():
		return
	
	StartLoadingAnimation()
	
	# Callback goes to SavePlayerNameCompleted()
	Leaderboard.SetPlayerName(_initialsLineEdit.text)
