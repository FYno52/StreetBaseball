extends Control

const LEAGUE_INFO_SCENE_PATH := "res://scenes/LeagueInfo.tscn"
const MATCH_SCENE_PATH := "res://scenes/MatchScene.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var replay_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/ReplayButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryTitleLabel
@onready var summary_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryDetailLabel
@onready var pitching_title_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingTitleLabel
@onready var pitching_detail_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingDetailLabel
@onready var log_title_label: Label = $RootScroll/MarginContainer/RootVBox/LogTitleLabel
@onready var log_detail_label: Label = $RootScroll/MarginContainer/RootVBox/LogDetailLabel

func _ready() -> void:
	title_label.text = "試合詳細"
	back_button.text = "リーグ情報へ戻る"
	replay_button.text = "試合再生へ"
	info_label.text = "ここでは選択した試合のスコア、投手結果、詳細ログを確認できます。試合再生はこの画面から入る形にしています。"
	summary_title_label.text = "試合結果"
	pitching_title_label.text = "投手結果"
	log_title_label.text = "試合詳細ログ"

	back_button.pressed.connect(_on_back_button_pressed)
	replay_button.pressed.connect(_on_replay_button_pressed)
	_refresh_view()

func _refresh_view() -> void:
	var game: GameData = LeagueState.get_selected_game()
	if game == null:
		summary_detail_label.text = "試合データが見つかりません。"
		pitching_detail_label.text = "リーグ情報から試合を選んでください。"
		log_detail_label.text = "詳細ログはありません。"
		replay_button.disabled = true
		return

	var away_name: String = _get_team_name(str(game.away_team_id))
	var home_name: String = _get_team_name(str(game.home_team_id))

	if not bool(game.played):
		summary_detail_label.text = "%s\n%s vs %s\nこの試合はまだ未消化です。" % [
			str(game.date_label),
			away_name,
			home_name
		]
		pitching_detail_label.text = "投手結果はまだありません。"
		log_detail_label.text = "試合ログはまだありません。"
		replay_button.disabled = true
		return

	summary_detail_label.text = "%s\n%s %d - %d %s" % [
		str(game.date_label),
		away_name,
		int(game.away_score),
		int(game.home_score),
		home_name
	]
	pitching_detail_label.text = "勝利投手: %s\n敗戦投手: %s\nセーブ投手: %s" % [
		_get_player_name(str(game.winning_pitcher_id)),
		_get_player_name(str(game.losing_pitcher_id)),
		_get_player_name(str(game.save_pitcher_id))
	]
	log_detail_label.text = "詳細ログはまだありません。"
	if not game.log_lines.is_empty():
		log_detail_label.text = "\n".join(game.log_lines)
	replay_button.disabled = false

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(LEAGUE_INFO_SCENE_PATH)

func _on_replay_button_pressed() -> void:
	var game: GameData = LeagueState.get_selected_game()
	if game == null or not bool(game.played):
		return
	get_tree().change_scene_to_file(MATCH_SCENE_PATH)

func _get_team_name(team_id: String) -> String:
	var team = LeagueState.get_team(team_id)
	if team == null:
		return team_id
	return str(team.name)

func _get_player_name(player_id: String) -> String:
	if player_id == "":
		return "なし"
	var player = LeagueState.get_player(player_id)
	if player == null:
		return player_id
	return str(player.full_name)
