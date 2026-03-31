extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var season_status_title_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusTitleLabel
@onready var season_status_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusDetailLabel
@onready var leaders_title_label: Label = $RootScroll/MarginContainer/RootVBox/LeadersTitleLabel
@onready var batting_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/BattingLeadersLabel
@onready var pitching_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingLeadersLabel
@onready var event_title_label: Label = $RootScroll/MarginContainer/RootVBox/EventTitleLabel
@onready var event_detail_label: Label = $RootScroll/MarginContainer/RootVBox/EventDetailLabel
@onready var standings_title_label: Label = $RootScroll/MarginContainer/RootVBox/StandingsTitleLabel
@onready var standings_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/StandingsScroll/StandingsVBox
@onready var recent_games_title_label: Label = $RootScroll/MarginContainer/RootVBox/RecentGamesTitleLabel
@onready var recent_games_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RecentGamesVBox
@onready var decision_title_label: Label = $RootScroll/MarginContainer/RootVBox/DecisionTitleLabel
@onready var decision_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DecisionDetailLabel
@onready var detailed_log_title_label: Label = $RootScroll/MarginContainer/RootVBox/DetailedLogTitleLabel
@onready var detailed_log_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DetailedLogDetailLabel

var selected_game_id: String = ""
var recent_game_ids: Array[String] = []

func _ready() -> void:
	title_label.text = "リーグ情報"
	back_button.text = "ホームへ戻る"
	info_label.text = "順位表、個人成績、ニュース、直近の試合結果を確認できます"
	season_status_title_label.text = "シーズン状況"
	leaders_title_label.text = "リーグ個人成績"
	event_title_label.text = "ストリートニュース"
	standings_title_label.text = "順位表"
	recent_games_title_label.text = "直近の試合一覧"
	decision_title_label.text = "試合結果"
	detailed_log_title_label.text = "試合詳細ログ"

	back_button.pressed.connect(_on_back_button_pressed)
	_refresh_view()

func _refresh_view() -> void:
	_refresh_season_status()
	_refresh_league_leaders()
	_refresh_daily_events()
	_refresh_standings()
	_refresh_recent_games()
	_refresh_decision_summary()
	_refresh_detailed_log()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)

func _refresh_season_status() -> void:
	var season_finished: bool = LeagueState.current_day > LeagueState.get_last_day()
	if not season_finished:
		season_status_detail_label.text = "シーズン %d 進行中\n%d日目 / %d日" % [LeagueState.season_year, LeagueState.current_day, LeagueState.get_last_day()]
		return

	var sorted_teams: Array = LeagueState.get_teams_sorted_by_win_pct()
	if sorted_teams.is_empty():
		season_status_detail_label.text = "シーズン集計を表示できません"
		return

	var champion: TeamData = sorted_teams[0]
	var last_place: TeamData = sorted_teams[sorted_teams.size() - 1]
	var best_offense: TeamData = _find_team_by_runs_for(true)
	var best_defense: TeamData = _find_team_by_runs_against(true)
	season_status_detail_label.text = "シーズン %d 終了\n優勝: %s\n最下位: %s\n最多得点: %s (%d)\n最少失点: %s (%d)\n試合日数: %d" % [
		LeagueState.season_year,
		champion.name,
		last_place.name,
		best_offense.name if best_offense != null else "-",
		int(best_offense.standings["runs_for"]) if best_offense != null else 0,
		best_defense.name if best_defense != null else "-",
		int(best_defense.standings["runs_against"]) if best_defense != null else 0,
		LeagueState.get_last_day()
	]

func _find_team_by_runs_for(highest: bool) -> TeamData:
	var best_team: TeamData = null
	for team_id in LeagueState.all_team_ids():
		var team = LeagueState.get_team(team_id)
		if team == null:
			continue
		if best_team == null:
			best_team = team
			continue
		var team_runs: int = int(team.standings["runs_for"])
		var best_runs: int = int(best_team.standings["runs_for"])
		if highest and team_runs > best_runs:
			best_team = team
		elif not highest and team_runs < best_runs:
			best_team = team
	return best_team

func _find_team_by_runs_against(lowest: bool) -> TeamData:
	var best_team: TeamData = null
	for team_id in LeagueState.all_team_ids():
		var team = LeagueState.get_team(team_id)
		if team == null:
			continue
		if best_team == null:
			best_team = team
			continue
		var team_runs: int = int(team.standings["runs_against"])
		var best_runs: int = int(best_team.standings["runs_against"])
		if lowest and team_runs < best_runs:
			best_team = team
		elif not lowest and team_runs > best_runs:
			best_team = team
	return best_team

func _refresh_league_leaders() -> void:
	var batting: Dictionary = LeagueState.get_league_batting_leaders(5)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(5)

	var batting_lines: Array[String] = ["打率"]
	for i in range(batting.get("avg", []).size()):
		var player = batting["avg"][i]
		batting_lines.append("%d. %s  %.3f" % [i + 1, player.full_name, player.get_batting_average()])
	batting_lines.append("")
	batting_lines.append("本塁打")
	for i in range(batting.get("hr", []).size()):
		var player = batting["hr"][i]
		batting_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.batting_stats["hr"])])
	batting_lines.append("")
	batting_lines.append("打点")
	for i in range(batting.get("rbi", []).size()):
		var player = batting["rbi"][i]
		batting_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.batting_stats["rbi"])])
	batting_leaders_label.text = "\n".join(batting_lines)

	var pitching_lines: Array[String] = ["勝利"]
	for i in range(pitching.get("wins", []).size()):
		var player = pitching["wins"][i]
		pitching_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.pitching_stats["wins"])])
	pitching_lines.append("")
	pitching_lines.append("セーブ")
	for i in range(pitching.get("saves", []).size()):
		var player = pitching["saves"][i]
		pitching_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.pitching_stats["saves"])])
	pitching_lines.append("")
	pitching_lines.append("防御率")
	for i in range(pitching.get("era", []).size()):
		var player = pitching["era"][i]
		pitching_lines.append("%d. %s  %.2f" % [i + 1, player.full_name, player.get_era()])
	pitching_leaders_label.text = "\n".join(pitching_lines)

func _refresh_daily_events() -> void:
	var events: Array[String] = LeagueState.get_recent_events()
	if events.is_empty():
		event_detail_label.text = "今日は特別なイベントなし"
		return

	var lines: Array[String] = []
	for event_text in events:
		lines.append("- " + str(event_text))
	event_detail_label.text = "\n".join(lines)

func _refresh_standings() -> void:
	for child in standings_vbox.get_children():
		child.queue_free()

	var summaries: Array = LeagueState.get_league_team_summaries()
	if summaries.is_empty():
		_add_message_label(standings_vbox, "順位表データがありません")
		return

	for i in range(summaries.size()):
		var summary: Dictionary = summaries[i]
		var label: Label = Label.new()
		label.custom_minimum_size = Vector2(0, 28)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%d. %s  勝:%s 敗:%s 分:%s  得:%s 失:%s  勝率:%.3f  総合:%.1f" % [
			i + 1,
			str(summary["name"]),
			str(summary["wins"]),
			str(summary["losses"]),
			str(summary["draws"]),
			str(summary["runs_for"]),
			str(summary["runs_against"]),
			float(summary["win_pct"]),
			float(summary["total"])
		]
		standings_vbox.add_child(label)

func _refresh_recent_games() -> void:
	for child in recent_games_vbox.get_children():
		child.queue_free()

	recent_game_ids.clear()
	var target_day: int = _get_recent_game_day()
	if target_day <= 0:
		_add_message_label(recent_games_vbox, "まだ試合は行われていません")
		selected_game_id = ""
		return

	var games: Array = []
	for game in LeagueState.schedule:
		if int(game.day) == target_day:
			games.append(game)
			recent_game_ids.append(str(game.id))

	if games.is_empty():
		_add_message_label(recent_games_vbox, "直近の試合データがありません")
		selected_game_id = ""
		return

	if selected_game_id == "" or not recent_game_ids.has(selected_game_id):
		selected_game_id = recent_game_ids[0]

	recent_games_title_label.text = "直近の試合一覧 (%d日目)" % target_day
	for game in games:
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = str(game.id) == selected_game_id
		var away_name: String = _get_team_name(str(game.away_team_id))
		var home_name: String = _get_team_name(str(game.home_team_id))
		button.text = "%s %d - %d %s" % [away_name, int(game.away_score), int(game.home_score), home_name]
		button.pressed.connect(_on_recent_game_pressed.bind(str(game.id)))
		recent_games_vbox.add_child(button)

func _get_recent_game_day() -> int:
	if LeagueState.schedule.is_empty():
		return 0
	if LeagueState.current_day <= 1:
		return 0
	if LeagueState.current_day > LeagueState.get_last_day():
		return LeagueState.get_last_day()
	return LeagueState.current_day - 1

func _on_recent_game_pressed(game_id: String) -> void:
	selected_game_id = game_id
	_refresh_recent_games()
	_refresh_decision_summary()
	_refresh_detailed_log()

func _refresh_decision_summary() -> void:
	if selected_game_id == "":
		decision_detail_label.text = "試合を選ぶと結果を表示します"
		return
	var game = _get_game_by_id(selected_game_id)
	if game == null:
		decision_detail_label.text = "試合データが見つかりません"
		return
	var away_name: String = _get_team_name(str(game.away_team_id))
	var home_name: String = _get_team_name(str(game.home_team_id))
	decision_detail_label.text = "試合結果: %s %d - %d %s\n勝利投手: %s\n敗戦投手: %s\nセーブ投手: %s" % [
		away_name,
		int(game.away_score),
		int(game.home_score),
		home_name,
		_get_player_name(str(game.winning_pitcher_id)),
		_get_player_name(str(game.losing_pitcher_id)),
		_get_player_name(str(game.save_pitcher_id))
	]

func _refresh_detailed_log() -> void:
	if selected_game_id == "":
		detailed_log_detail_label.text = "試合を選ぶと詳細ログを表示します"
		return
	var game = _get_game_by_id(selected_game_id)
	if game == null:
		detailed_log_detail_label.text = "試合ログが見つかりません"
		return
	if game.log_lines.is_empty():
		detailed_log_detail_label.text = "詳細ログはまだありません"
		return
	detailed_log_detail_label.text = "\n".join(game.log_lines)

func _get_game_by_id(game_id: String):
	for game in LeagueState.schedule:
		if str(game.id) == game_id:
			return game
	return null

func _get_player_name(player_id: String) -> String:
	if player_id == "":
		return "なし"
	var player = LeagueState.get_player(player_id)
	if player == null:
		return player_id
	return player.full_name

func _get_team_name(team_id: String) -> String:
	if team_id == "":
		return "不明"
	var team = LeagueState.get_team(team_id)
	if team == null:
		return team_id
	return team.name

func _add_message_label(container: VBoxContainer, message: String) -> void:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(0, 32)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	container.add_child(label)
