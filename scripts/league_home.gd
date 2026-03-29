extends Control

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var sim_day_button: Button = $RootScroll/MarginContainer/RootVBox/SimDayButton
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll/TeamListVBox
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamDetailLabel
@onready var lineup_vs_r_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupVsRTitleLabel
@onready var lineup_vs_r_detail_label: Label = $RootScroll/MarginContainer/RootVBox/LineupVsRDetailLabel
@onready var lineup_vs_l_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupVsLTitleLabel
@onready var lineup_vs_l_detail_label: Label = $RootScroll/MarginContainer/RootVBox/LineupVsLDetailLabel
@onready var rotation_title_label: Label = $RootScroll/MarginContainer/RootVBox/RotationTitleLabel
@onready var rotation_detail_label: Label = $RootScroll/MarginContainer/RootVBox/RotationDetailLabel
@onready var game_log_title_label: Label = $RootScroll/MarginContainer/RootVBox/GameLogTitleLabel
@onready var game_log_detail_label: Label = $RootScroll/MarginContainer/RootVBox/GameLogDetailLabel

var selected_team_id: String = ""
var last_simulated_day: int = 0
var last_game_log_text: String = "まだ試合は行われていません"

func _ready() -> void:
	LeagueState.new_game()

	title_label.text = "League Home"
	selected_team_title_label.text = "選択球団詳細"
	selected_team_detail_label.text = "まだ球団が選択されていません"
	lineup_vs_r_title_label.text = "対右投手スタメン"
	lineup_vs_r_detail_label.text = "球団を選択すると対右打線が表示されます"
	lineup_vs_l_title_label.text = "対左投手スタメン"
	lineup_vs_l_detail_label.text = "球団を選択すると対左打線が表示されます"
	rotation_title_label.text = "先発ローテ"
	rotation_detail_label.text = "球団を選択すると先発ローテが表示されます"
	game_log_title_label.text = "直近の試合結果"
	game_log_detail_label.text = last_game_log_text

	sim_day_button.pressed.connect(_on_sim_day_button_pressed)

	_refresh_view()

func _refresh_view() -> void:
	info_label.text = "現在日: %d" % LeagueState.current_day

	for child in team_list_vbox.get_children():
		child.queue_free()

	var summaries: Array = LeagueState.get_league_team_summaries()
	for i in range(summaries.size()):
		var s: Dictionary = summaries[i]
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%d. %s  W:%s L:%s D:%s  RF:%s RA:%s  PCT:%.3f  TOT:%.1f" % [
			i + 1,
			str(s["name"]),
			str(s["wins"]),
			str(s["losses"]),
			str(s["draws"]),
			str(s["runs_for"]),
			str(s["runs_against"]),
			float(s["win_pct"]),
			float(s["total"])
		]
		button.pressed.connect(_on_team_button_pressed.bind(str(s["id"])))
		team_list_vbox.add_child(button)

	_refresh_selected_team_detail()
	_refresh_selected_team_lineups()
	_refresh_selected_team_rotation()
	_refresh_sim_day_button()

func _on_sim_day_button_pressed() -> void:
	if LeagueState.current_day > LeagueState.get_last_day():
		_refresh_sim_day_button()
		return

	var simulated_day: int = LeagueState.current_day
	var games_today: Array = LeagueState.simulate_current_day()
	_store_game_logs(simulated_day, games_today)

	if LeagueState.current_day < LeagueState.get_last_day():
		LeagueState.advance_day()
	else:
		LeagueState.current_day = LeagueState.get_last_day() + 1

	_refresh_view()

func _on_team_button_pressed(team_id: String) -> void:
	selected_team_id = team_id

	var team = LeagueState.get_team(team_id)
	if team != null:
		info_label.text = "現在日: %d / 選択球団: %s" % [LeagueState.current_day, team.name]

	_refresh_selected_team_detail()
	_refresh_selected_team_lineups()
	_refresh_selected_team_rotation()

func _refresh_selected_team_detail() -> void:
	if selected_team_id == "":
		selected_team_detail_label.text = "まだ球団が選択されていません"
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		selected_team_detail_label.text = "球団データが見つかりません"
		return

	var attack: float = SimulationEngine.get_team_attack_value(team)
	var pitch_value: float = SimulationEngine.get_team_pitch_value(team)
	var total: float = SimulationEngine.get_team_total_strength(team)

	selected_team_detail_label.text = "球団名: %s\n戦績: %s勝 %s敗 %s分\n得点: %s\n失点: %s\n攻撃力: %.2f\n投手力: %.2f\n総合力: %.2f\n選手数: %d" % [
		team.name,
		str(team.standings["wins"]),
		str(team.standings["losses"]),
		str(team.standings["draws"]),
		str(team.standings["runs_for"]),
		str(team.standings["runs_against"]),
		attack,
		pitch_value,
		total,
		team.player_ids.size()
	]

func _refresh_selected_team_lineups() -> void:
	if selected_team_id == "":
		lineup_vs_r_detail_label.text = "球団を選択すると対右打線が表示されます"
		lineup_vs_l_detail_label.text = "球団を選択すると対左打線が表示されます"
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		lineup_vs_r_detail_label.text = "球団データが見つかりません"
		lineup_vs_l_detail_label.text = "球団データが見つかりません"
		return

	lineup_vs_r_detail_label.text = _build_lineup_text(team.lineup_vs_r)
	lineup_vs_l_detail_label.text = _build_lineup_text(team.lineup_vs_l)

func _build_lineup_text(lineup_ids: Array[String]) -> String:
	if lineup_ids.is_empty():
		return "スタメンがありません"

	var lines: Array[String] = []
	for i in range(lineup_ids.size()):
		var p = LeagueState.get_player(str(lineup_ids[i]))
		if p == null:
			continue
		lines.append("%d. %s  %s  %s  AVG:%.3f  H:%s HR:%s RBI:%s" % [
			i + 1,
			p.full_name,
			p.primary_position,
			p.bats,
			p.get_batting_average(),
			str(p.batting_stats["h"]),
			str(p.batting_stats["hr"]),
			str(p.batting_stats["rbi"])
		])

	if lines.is_empty():
		return "スタメンがありません"

	return "\n".join(lines)

func _refresh_selected_team_rotation() -> void:
	if selected_team_id == "":
		rotation_detail_label.text = "球団を選択すると先発ローテが表示されます"
		return

	var rotation_players: Array = LeagueState.get_team_rotation(selected_team_id)
	if rotation_players.is_empty():
		rotation_detail_label.text = "先発ローテがありません"
		return

	var lines: Array[String] = []
	for i in range(rotation_players.size()):
		var p = rotation_players[i]
		lines.append("%d. %s  %s投げ  ERA:%.2f  W:%s L:%s SO:%s" % [
			i + 1,
			p.full_name,
			p.throws,
			p.get_era(),
			str(p.pitching_stats["wins"]),
			str(p.pitching_stats["losses"]),
			str(p.pitching_stats["so"])
		])

	rotation_detail_label.text = "\n".join(lines)

func _refresh_sim_day_button() -> void:
	var season_finished: bool = LeagueState.current_day > LeagueState.get_last_day()
	sim_day_button.disabled = season_finished
	sim_day_button.text = "シーズン終了" if season_finished else "1日消化"

func _store_game_logs(simulated_day: int, games_today: Array) -> void:
	last_simulated_day = simulated_day

	if games_today.is_empty():
		last_game_log_text = "Day %d\n試合はありません" % simulated_day
		game_log_detail_label.text = last_game_log_text
		return

	var lines: Array[String] = ["Day %d" % simulated_day]
	for game in games_today:
		var away_team = LeagueState.get_team(str(game.away_team_id))
		var home_team = LeagueState.get_team(str(game.home_team_id))
		var away_name: String = away_team.name if away_team != null else str(game.away_team_id)
		var home_name: String = home_team.name if home_team != null else str(game.home_team_id)
		lines.append("%s %d - %d %s" % [away_name, int(game.away_score), int(game.home_score), home_name])

	last_game_log_text = "\n".join(lines)
	game_log_detail_label.text = last_game_log_text