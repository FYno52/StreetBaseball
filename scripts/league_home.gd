extends Control

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var sim_day_button: Button = $RootScroll/MarginContainer/RootVBox/SimDayButton
@onready var save_button: Button = $RootScroll/MarginContainer/RootVBox/SaveButtonsHBox/SaveButton
@onready var load_button: Button = $RootScroll/MarginContainer/RootVBox/SaveButtonsHBox/LoadButton
@onready var new_season_button: Button = $RootScroll/MarginContainer/RootVBox/SaveButtonsHBox/NewSeasonButton
@onready var save_status_label: Label = $RootScroll/MarginContainer/RootVBox/SaveStatusLabel
@onready var season_status_title_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusTitleLabel
@onready var season_status_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusDetailLabel
@onready var leaders_title_label: Label = $RootScroll/MarginContainer/RootVBox/LeadersTitleLabel
@onready var batting_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/BattingLeadersLabel
@onready var pitching_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingLeadersLabel
@onready var event_title_label: Label = $RootScroll/MarginContainer/RootVBox/EventTitleLabel
@onready var event_detail_label: Label = $RootScroll/MarginContainer/RootVBox/EventDetailLabel
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll/TeamListVBox
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamDetailLabel
@onready var strategy_title_label: Label = $RootScroll/MarginContainer/RootVBox/StrategyTitleLabel
@onready var strategy_status_label: Label = $RootScroll/MarginContainer/RootVBox/StrategyStatusLabel
@onready var strategy_balanced_button: Button = $RootScroll/MarginContainer/RootVBox/StrategyButtonsHBox/StrategyBalancedButton
@onready var strategy_power_button: Button = $RootScroll/MarginContainer/RootVBox/StrategyButtonsHBox/StrategyPowerButton
@onready var strategy_speed_button: Button = $RootScroll/MarginContainer/RootVBox/StrategyButtonsHBox/StrategySpeedButton
@onready var strategy_defense_button: Button = $RootScroll/MarginContainer/RootVBox/StrategyButtonsHBox/StrategyDefenseButton
@onready var strategy_pitching_button: Button = $RootScroll/MarginContainer/RootVBox/StrategyButtonsHBox/StrategyPitchingButton
@onready var lineup_vs_r_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupVsRTitleLabel
@onready var lineup_vs_r_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/LineupVsRVBox
@onready var lineup_vs_l_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupVsLTitleLabel
@onready var lineup_vs_l_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/LineupVsLVBox
@onready var edit_title_label: Label = $RootScroll/MarginContainer/RootVBox/EditTitleLabel
@onready var edit_vs_r_button: Button = $RootScroll/MarginContainer/RootVBox/EditButtonsHBox/EditVsRButton
@onready var edit_vs_l_button: Button = $RootScroll/MarginContainer/RootVBox/EditButtonsHBox/EditVsLButton
@onready var cancel_edit_button: Button = $RootScroll/MarginContainer/RootVBox/EditButtonsHBox/CancelEditButton
@onready var editor_status_label: Label = $RootScroll/MarginContainer/RootVBox/EditorStatusLabel
@onready var bench_title_label: Label = $RootScroll/MarginContainer/RootVBox/BenchTitleLabel
@onready var bench_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/BenchVBox
@onready var rotation_title_label: Label = $RootScroll/MarginContainer/RootVBox/RotationTitleLabel
@onready var rotation_editor_status_label: Label = $RootScroll/MarginContainer/RootVBox/RotationEditorStatusLabel
@onready var rotation_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RotationVBox
@onready var bullpen_title_label: Label = $RootScroll/MarginContainer/RootVBox/BullpenTitleLabel
@onready var bullpen_detail_label: Label = $RootScroll/MarginContainer/RootVBox/BullpenDetailLabel
@onready var bullpen_editor_status_label: Label = $RootScroll/MarginContainer/RootVBox/BullpenEditorStatusLabel
@onready var bullpen_auto_button: Button = $RootScroll/MarginContainer/RootVBox/BullpenRoleButtonsHBox/BullpenAutoButton
@onready var bullpen_closer_button: Button = $RootScroll/MarginContainer/RootVBox/BullpenRoleButtonsHBox/BullpenCloserButton
@onready var bullpen_setup_button: Button = $RootScroll/MarginContainer/RootVBox/BullpenRoleButtonsHBox/BullpenSetupButton
@onready var bullpen_middle_button: Button = $RootScroll/MarginContainer/RootVBox/BullpenRoleButtonsHBox/BullpenMiddleButton
@onready var bullpen_long_button: Button = $RootScroll/MarginContainer/RootVBox/BullpenRoleButtonsHBox/BullpenLongButton
@onready var bullpen_pitchers_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/BullpenPitchersVBox
@onready var recent_games_title_label: Label = $RootScroll/MarginContainer/RootVBox/RecentGamesTitleLabel
@onready var recent_games_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RecentGamesVBox
@onready var decision_title_label: Label = $RootScroll/MarginContainer/RootVBox/DecisionTitleLabel
@onready var decision_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DecisionDetailLabel
@onready var detailed_log_title_label: Label = $RootScroll/MarginContainer/RootVBox/DetailedLogTitleLabel
@onready var detailed_log_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DetailedLogDetailLabel

var selected_team_id: String = ""
var selected_game_id: String = ""
var last_game_ids: Array[String] = []
var lineup_edit_target: String = ""
var selected_lineup_index: int = -1
var selected_rotation_index: int = -1
var bullpen_edit_target: String = ""

func _ready() -> void:
	LeagueState.new_game()

	title_label.text = "ストリート野球"
	save_button.text = "セーブ"
	load_button.text = "ロード"
	new_season_button.text = "新シーズン開始"
	save_status_label.text = "保存先: user://save_01.json"
	season_status_title_label.text = "シーズン状況"
	leaders_title_label.text = "リーグ個人成績"
	event_title_label.text = "ストリートニュース"
	selected_team_title_label.text = "チーム詳細"
	strategy_title_label.text = "チーム方針"
	lineup_vs_r_title_label.text = "対右投手スタメン"
	lineup_vs_l_title_label.text = "対左投手スタメン"
	edit_title_label.text = "打線編集"
	edit_vs_r_button.text = "対右を編集"
	edit_vs_l_button.text = "対左を編集"
	cancel_edit_button.text = "編集をやめる"
	bench_title_label.text = "ベンチ"
	rotation_title_label.text = "先発ローテ"
	bullpen_title_label.text = "ブルペン"
	bullpen_auto_button.text = "自動"
	recent_games_title_label.text = "直近の試合一覧"
	decision_title_label.text = "試合結果"
	detailed_log_title_label.text = "試合詳細ログ"
	strategy_balanced_button.text = "標準"
	strategy_power_button.text = "強打"
	strategy_speed_button.text = "機動力"
	strategy_defense_button.text = "守備重視"
	strategy_pitching_button.text = "投手重視"
	bullpen_closer_button.text = "抑え"
	bullpen_setup_button.text = "勝ち継投"
	bullpen_middle_button.text = "中継ぎ"
	bullpen_long_button.text = "ロング"

	sim_day_button.pressed.connect(_on_sim_day_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	new_season_button.pressed.connect(_on_new_season_button_pressed)
	edit_vs_r_button.pressed.connect(_on_edit_mode_pressed.bind("vs_r"))
	edit_vs_l_button.pressed.connect(_on_edit_mode_pressed.bind("vs_l"))
	cancel_edit_button.pressed.connect(_on_cancel_edit_pressed)
	strategy_balanced_button.pressed.connect(_on_strategy_button_pressed.bind("balanced"))
	strategy_power_button.pressed.connect(_on_strategy_button_pressed.bind("power"))
	strategy_speed_button.pressed.connect(_on_strategy_button_pressed.bind("speed"))
	strategy_defense_button.pressed.connect(_on_strategy_button_pressed.bind("defense"))
	strategy_pitching_button.pressed.connect(_on_strategy_button_pressed.bind("pitching"))
	bullpen_closer_button.pressed.connect(_on_bullpen_role_button_pressed.bind("closer"))
	bullpen_setup_button.pressed.connect(_on_bullpen_role_button_pressed.bind("setup"))
	bullpen_middle_button.pressed.connect(_on_bullpen_role_button_pressed.bind("middle"))
	bullpen_long_button.pressed.connect(_on_bullpen_role_button_pressed.bind("long"))
	bullpen_auto_button.pressed.connect(_on_bullpen_auto_button_pressed)

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
		button.text = "%d. %s  勝:%s 敗:%s 分:%s  得:%s 失:%s  勝率:%.3f  総合:%.1f" % [i + 1, str(s["name"]), str(s["wins"]), str(s["losses"]), str(s["draws"]), str(s["runs_for"]), str(s["runs_against"]), float(s["win_pct"]), float(s["total"])]
		button.pressed.connect(_on_team_button_pressed.bind(str(s["id"])))
		team_list_vbox.add_child(button)

	_refresh_season_status()
	_refresh_league_leaders()
	_refresh_daily_events()
	_refresh_selected_team_detail()
	_refresh_strategy_editor()
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()
	_refresh_selected_team_rotation()
	_refresh_selected_team_bullpen()
	_refresh_recent_games_list()
	_refresh_decision_summary()
	_refresh_detailed_log()
	_refresh_sim_day_button()

func _on_sim_day_button_pressed() -> void:
	if LeagueState.current_day > LeagueState.get_last_day():
		_refresh_sim_day_button()
		return

	var simulated_day: int = LeagueState.current_day
	var games_today: Array = LeagueState.simulate_current_day()
	_store_recent_games(simulated_day, games_today)

	if LeagueState.current_day < LeagueState.get_last_day():
		LeagueState.advance_day()
	else:
		LeagueState.current_day = LeagueState.get_last_day() + 1

	_refresh_view()

func _on_save_button_pressed() -> void:
	var saved: bool = LeagueState.save_to_file()
	save_status_label.text = "保存しました: user://save_01.json" if saved else "保存に失敗しました"

func _on_load_button_pressed() -> void:
	var loaded: bool = LeagueState.load_from_file()
	if not loaded:
		save_status_label.text = "ロードに失敗しました"
		return

	if selected_team_id != "" and LeagueState.get_team(selected_team_id) == null:
		selected_team_id = ""
	if selected_game_id != "" and _get_game_by_id(selected_game_id) == null:
		selected_game_id = ""
	if selected_game_id == "" and not last_game_ids.is_empty():
		selected_game_id = last_game_ids[0]

	lineup_edit_target = ""
	selected_lineup_index = -1
	selected_rotation_index = -1
	bullpen_edit_target = ""
	save_status_label.text = "ロードしました: user://save_01.json"
	_refresh_view()

func _on_new_season_button_pressed() -> void:
	if LeagueState.current_day <= LeagueState.get_last_day():
		save_status_label.text = "今のシーズンを最後まで進めてください"
		return

	LeagueState.start_new_season()
	last_game_ids.clear()
	selected_game_id = ""
	lineup_edit_target = ""
	selected_lineup_index = -1
	selected_rotation_index = -1
	bullpen_edit_target = ""
	save_status_label.text = "新シーズンを開始しました"
	_refresh_view()

func _refresh_season_status() -> void:
	var season_finished: bool = LeagueState.current_day > LeagueState.get_last_day()
	if not season_finished:
		season_status_detail_label.text = "シーズン %d 進行中\n%d日目 / %d日" % [LeagueState.season_year, LeagueState.current_day, LeagueState.get_last_day()]
		return

	var sorted_teams: Array = LeagueState.get_teams_sorted_by_win_pct()
	if sorted_teams.is_empty():
		season_status_detail_label.text = "シーズン集計を表示できません"
		return

	var champion = sorted_teams[0]
	var last_place = sorted_teams[sorted_teams.size() - 1]
	var best_offense = _find_team_by_runs_for(true)
	var best_defense = _find_team_by_runs_against(true)
	season_status_detail_label.text = "シーズン %d 終了\n優勝: %s\n最下位: %s\n最多得点: %s (%d)\n最少失点: %s (%d)\n試合日数: %d" % [LeagueState.season_year, champion.name, last_place.name, best_offense.name if best_offense != null else "-", int(best_offense.standings["runs_for"]) if best_offense != null else 0, best_defense.name if best_defense != null else "-", int(best_defense.standings["runs_against"]) if best_defense != null else 0, LeagueState.get_last_day()]

func _find_team_by_runs_for(highest: bool):
	var best_team = null
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

func _find_team_by_runs_against(lowest: bool):
	var best_team = null
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

func _on_team_button_pressed(team_id: String) -> void:
	selected_team_id = team_id
	selected_lineup_index = -1
	selected_rotation_index = -1
	bullpen_edit_target = ""

	var team = LeagueState.get_team(team_id)
	if team != null:
			info_label.text = "現在日: %d / 選択チーム: %s" % [LeagueState.current_day, team.name]

	_refresh_selected_team_detail()
	_refresh_strategy_editor()
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()
	_refresh_selected_team_rotation()
	_refresh_selected_team_bullpen()

func _on_strategy_button_pressed(strategy: String) -> void:
	if selected_team_id == "":
		return
	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	team.strategy = strategy
	_refresh_selected_team_detail()
	_refresh_strategy_editor()

func _refresh_strategy_editor() -> void:
	_update_strategy_buttons()
	if selected_team_id == "":
		strategy_status_label.text = "チームを選ぶと方針を変更できます"
		return
	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		strategy_status_label.text = "チームデータが見つかりません"
		return
	strategy_status_label.text = "現在の方針: %s\n標準はバランス型、強打は打撃寄り、機動力は走力寄り、守備重視は失点抑制寄り、投手重視は投手力寄りです。" % _get_strategy_label(team.strategy)

func _update_strategy_buttons() -> void:
	var current_strategy: String = ""
	var team = LeagueState.get_team(selected_team_id)
	if team != null:
		current_strategy = str(team.strategy)
	strategy_balanced_button.toggle_mode = true
	strategy_power_button.toggle_mode = true
	strategy_speed_button.toggle_mode = true
	strategy_defense_button.toggle_mode = true
	strategy_pitching_button.toggle_mode = true
	strategy_balanced_button.button_pressed = current_strategy == "balanced"
	strategy_power_button.button_pressed = current_strategy == "power"
	strategy_speed_button.button_pressed = current_strategy == "speed"
	strategy_defense_button.button_pressed = current_strategy == "defense"
	strategy_pitching_button.button_pressed = current_strategy == "pitching"
	strategy_balanced_button.disabled = selected_team_id == ""
	strategy_power_button.disabled = selected_team_id == ""
	strategy_speed_button.disabled = selected_team_id == ""
	strategy_defense_button.disabled = selected_team_id == ""
	strategy_pitching_button.disabled = selected_team_id == ""

func _on_edit_mode_pressed(mode: String) -> void:
	lineup_edit_target = mode
	selected_lineup_index = -1
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()

func _on_cancel_edit_pressed() -> void:
	lineup_edit_target = ""
	selected_lineup_index = -1
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()

func _on_lineup_slot_pressed(mode: String, index: int) -> void:
	lineup_edit_target = mode
	selected_lineup_index = index
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()

func _on_bench_player_pressed(player_id: String) -> void:
	if selected_team_id == "" or lineup_edit_target == "" or selected_lineup_index < 0:
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		return

	var target_lineup: Array[String] = team.lineup_vs_r
	if lineup_edit_target == "vs_l":
		target_lineup = team.lineup_vs_l
	if selected_lineup_index >= target_lineup.size():
		return

	target_lineup[selected_lineup_index] = player_id
	if lineup_edit_target == "vs_l":
		team.lineup_vs_l = target_lineup
	else:
		team.lineup_vs_r = target_lineup

	_rebuild_team_bench(team)
	selected_lineup_index = -1
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()

func _on_recent_game_pressed(game_id: String) -> void:
	selected_game_id = game_id
	_refresh_recent_games_list()
	_refresh_decision_summary()
	_refresh_detailed_log()

func _on_rotation_slot_pressed(index: int) -> void:
	if selected_team_id == "":
		return
	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	if index < 0 or index >= team.rotation_ids.size():
		return

	if selected_rotation_index == -1:
		selected_rotation_index = index
	elif selected_rotation_index == index:
		selected_rotation_index = -1
	else:
		var first_id: String = str(team.rotation_ids[selected_rotation_index])
		var second_id: String = str(team.rotation_ids[index])
		team.rotation_ids[selected_rotation_index] = second_id
		team.rotation_ids[index] = first_id
		selected_rotation_index = -1

	_refresh_selected_team_rotation()

func _on_bullpen_role_button_pressed(role: String) -> void:
	if bullpen_edit_target == role:
		bullpen_edit_target = ""
	else:
		bullpen_edit_target = role
	_refresh_selected_team_bullpen()

func _on_bullpen_pitcher_pressed(player_id: String) -> void:
	if selected_team_id == "" or bullpen_edit_target == "":
		return
	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	_assign_bullpen_role(team, player_id, bullpen_edit_target)
	_refresh_selected_team_bullpen()

func _on_bullpen_auto_button_pressed() -> void:
	if selected_team_id == "":
		return
	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	LeagueState.auto_assign_team_bullpen(team)
	bullpen_edit_target = ""
	_refresh_selected_team_bullpen()

func _refresh_selected_team_detail() -> void:
	if selected_team_id == "":
		selected_team_detail_label.text = "まだチームが選択されていません"
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		selected_team_detail_label.text = "チームデータが見つかりません"
		return

	var attack: float = SimulationEngine.get_team_attack_value(team)
	var pitch_value: float = SimulationEngine.get_team_pitch_value(team)
	var total: float = SimulationEngine.get_team_total_strength(team)
	selected_team_detail_label.text = "チーム名: %s\n戦績: %s勝 %s敗 %s分\n得点: %s\n失点: %s\nファン人気: %d\n予算: %d\n方針: %s\n打撃力: %.2f\n投手力: %.2f\n総合力: %.2f\n登録人数: %d" % [team.name, str(team.standings["wins"]), str(team.standings["losses"]), str(team.standings["draws"]), str(team.standings["runs_for"]), str(team.standings["runs_against"]), int(team.fan_support), int(team.budget), _get_strategy_label(team.strategy), attack, pitch_value, total, team.player_ids.size()]

func _refresh_selected_team_lineups() -> void:
	for child in lineup_vs_r_vbox.get_children():
		child.queue_free()
	for child in lineup_vs_l_vbox.get_children():
		child.queue_free()

	if selected_team_id == "":
		_add_message_label(lineup_vs_r_vbox, "チームを選ぶと対右投手スタメンが表示されます")
		_add_message_label(lineup_vs_l_vbox, "チームを選ぶと対左投手スタメンが表示されます")
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		_add_message_label(lineup_vs_r_vbox, "チームデータが見つかりません")
		_add_message_label(lineup_vs_l_vbox, "チームデータが見つかりません")
		return

	_populate_lineup_buttons(lineup_vs_r_vbox, team.lineup_vs_r, "vs_r")
	_populate_lineup_buttons(lineup_vs_l_vbox, team.lineup_vs_l, "vs_l")

func _populate_lineup_buttons(container: VBoxContainer, lineup_ids: Array[String], mode: String) -> void:
	if lineup_ids.is_empty():
		_add_message_label(container, "打線データがありません")
		return

	for i in range(lineup_ids.size()):
		var p = LeagueState.get_player(str(lineup_ids[i]))
		if p == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = lineup_edit_target == mode and selected_lineup_index == i
		button.text = "%d. %s  %s  %s  打率:%.3f  安打:%s  本:%s  点:%s" % [i + 1, p.full_name, p.primary_position, p.bats, p.get_batting_average(), str(p.batting_stats["h"]), str(p.batting_stats["hr"]), str(p.batting_stats["rbi"])]
		button.pressed.connect(_on_lineup_slot_pressed.bind(mode, i))
		container.add_child(button)

func _refresh_lineup_editor() -> void:
	for child in bench_vbox.get_children():
		child.queue_free()

	if selected_team_id == "":
		editor_status_label.text = "チームを選ぶと打線編集が使えます"
		_add_message_label(bench_vbox, "ベンチはまだ表示されていません")
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		editor_status_label.text = "チームデータが見つかりません"
		_add_message_label(bench_vbox, "ベンチを表示できません")
		return

	_rebuild_team_bench(team)
	if lineup_edit_target == "":
		editor_status_label.text = "編集したい打線を先に選んでください"
		_add_message_label(bench_vbox, "「対右を編集」または「対左を編集」を押してください")
		return

	var target_label: String = "対右"
	if lineup_edit_target == "vs_l":
		target_label = "対左"
	if selected_lineup_index < 0:
		editor_status_label.text = "%s打線の入れ替え先を選んでください" % target_label
	else:
		editor_status_label.text = "%s打線の %d 番を選択中です。ベンチから入れ替える選手を選んでください" % [target_label, selected_lineup_index + 1]

	if team.bench_ids.is_empty():
		_add_message_label(bench_vbox, "ベンチ選手がいません")
		return

	for player_id in team.bench_ids:
		var p = LeagueState.get_player(str(player_id))
		if p == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = selected_lineup_index < 0
		button.text = "%s  %s  %s  打率:%.3f  安打:%s  本:%s  点:%s" % [p.full_name, p.primary_position, p.bats, p.get_batting_average(), str(p.batting_stats["h"]), str(p.batting_stats["hr"]), str(p.batting_stats["rbi"])]
		button.pressed.connect(_on_bench_player_pressed.bind(str(player_id)))
		bench_vbox.add_child(button)

func _rebuild_team_bench(team) -> void:
	var used_ids: Array[String] = []
	for player_id in team.lineup_vs_r:
		if not used_ids.has(str(player_id)):
			used_ids.append(str(player_id))
	for player_id in team.lineup_vs_l:
		if not used_ids.has(str(player_id)):
			used_ids.append(str(player_id))

	team.bench_ids.clear()
	for player_id in team.player_ids:
		var player = LeagueState.get_player(str(player_id))
		if player == null or player.is_pitcher():
			continue
		if not used_ids.has(str(player.id)):
			team.bench_ids.append(str(player.id))

func _refresh_selected_team_rotation() -> void:
	for child in rotation_vbox.get_children():
		child.queue_free()

	if selected_team_id == "":
		rotation_editor_status_label.text = "チームを選ぶと先発ローテが表示されます"
		return

	var team = LeagueState.get_team(selected_team_id)
	if team == null:
		rotation_editor_status_label.text = "チームデータが見つかりません"
		return
	if team.rotation_ids.is_empty():
		rotation_editor_status_label.text = "先発ローテが設定されていません"
		return

	rotation_editor_status_label.text = "入れ替えたい先発を1人選んでから、交換先を押すと順番が入れ替わります"
	if selected_rotation_index >= 0:
		rotation_editor_status_label.text = "ローテの %d 番を選択中です。入れ替えたい先発をもう1人押してください" % [selected_rotation_index + 1]

	for i in range(team.rotation_ids.size()):
		var p = LeagueState.get_player(str(team.rotation_ids[i]))
		if p == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = selected_rotation_index == i
		button.text = "%d. %s  %s投  防御率:%.2f  勝:%s 敗:%s 奪三振:%s" % [i + 1, p.full_name, p.throws, p.get_era(), str(p.pitching_stats["wins"]), str(p.pitching_stats["losses"]), str(p.pitching_stats["so"])]
		button.pressed.connect(_on_rotation_slot_pressed.bind(i))
		rotation_vbox.add_child(button)

func _refresh_selected_team_bullpen() -> void:
	for child in bullpen_pitchers_vbox.get_children():
		child.queue_free()
	_update_bullpen_role_buttons()

	if selected_team_id == "":
		bullpen_detail_label.text = "チームを選ぶとブルペンが表示されます"
		bullpen_editor_status_label.text = "チームを選ぶとブルペン役割を編集できます"
		return

	var bullpen: Dictionary = LeagueState.get_team_bullpen(selected_team_id)
	var team = LeagueState.get_team(selected_team_id)
	var lines: Array[String] = []
	var closer = bullpen.get("closer", null)
	if closer != null:
		lines.append("抑え  %s  防御率:%.2f  セーブ:%s  ホールド:%s  奪三振:%s" % [closer.full_name, closer.get_era(), str(closer.pitching_stats["saves"]), str(closer.pitching_stats["holds"]), str(closer.pitching_stats["so"])])
	for p in bullpen.get("setup", []):
		lines.append("勝ち継投  %s  防御率:%.2f  セーブ:%s  ホールド:%s  奪三振:%s" % [p.full_name, p.get_era(), str(p.pitching_stats["saves"]), str(p.pitching_stats["holds"]), str(p.pitching_stats["so"])])
	for p in bullpen.get("middle", []):
		lines.append("中継ぎ  %s  防御率:%.2f  セーブ:%s  ホールド:%s  奪三振:%s" % [p.full_name, p.get_era(), str(p.pitching_stats["saves"]), str(p.pitching_stats["holds"]), str(p.pitching_stats["so"])])
	var long_reliever = bullpen.get("long", null)
	if long_reliever != null:
		lines.append("ロング  %s  防御率:%.2f  セーブ:%s  ホールド:%s  奪三振:%s" % [long_reliever.full_name, long_reliever.get_era(), str(long_reliever.pitching_stats["saves"]), str(long_reliever.pitching_stats["holds"]), str(long_reliever.pitching_stats["so"])])
		bullpen_detail_label.text = "ブルペンデータがありません" if lines.is_empty() else "\n".join(lines)

	if team == null:
		bullpen_editor_status_label.text = "チームデータが見つかりません"
		return
	if bullpen_edit_target == "":
		bullpen_editor_status_label.text = "役割を選んでから救援投手を選んでください"
	else:
		bullpen_editor_status_label.text = "設定中の役割: %s" % _get_bullpen_role_label(bullpen_edit_target)

	var relief_pitchers: Array = _get_relief_pitchers_for_team(team)
	if relief_pitchers.is_empty():
		_add_message_label(bullpen_pitchers_vbox, "救援投手がいません")
		return

	for pitcher in relief_pitchers:
		var role_label: String = _get_pitcher_bullpen_role(team, str(pitcher.id))
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = bullpen_edit_target == ""
		button.text = "%s  %s  防御率:%.2f  セーブ:%s  ホールド:%s" % [pitcher.full_name, role_label, pitcher.get_era(), str(pitcher.pitching_stats["saves"]), str(pitcher.pitching_stats["holds"])]
		button.pressed.connect(_on_bullpen_pitcher_pressed.bind(str(pitcher.id)))
		bullpen_pitchers_vbox.add_child(button)

func _update_bullpen_role_buttons() -> void:
	bullpen_closer_button.toggle_mode = true
	bullpen_setup_button.toggle_mode = true
	bullpen_middle_button.toggle_mode = true
	bullpen_long_button.toggle_mode = true
	bullpen_closer_button.button_pressed = bullpen_edit_target == "closer"
	bullpen_setup_button.button_pressed = bullpen_edit_target == "setup"
	bullpen_middle_button.button_pressed = bullpen_edit_target == "middle"
	bullpen_long_button.button_pressed = bullpen_edit_target == "long"

func _get_relief_pitchers_for_team(team) -> Array:
	var result: Array = []
	for player_id in team.player_ids:
		var player = LeagueState.get_player(str(player_id))
		if player == null:
			continue
		if str(player.role) == "reliever" or str(player.role) == "closer":
			result.append(player)
	return result

func _get_pitcher_bullpen_role(team, player_id: String) -> String:
	if str(team.bullpen.get("closer", "")) == player_id:
		return "抑え"
	if str(team.bullpen.get("long", "")) == player_id:
		return "ロング"
	if team.bullpen.get("setup", []).has(player_id):
		return "勝ち継投"
	if team.bullpen.get("middle", []).has(player_id):
		return "中継ぎ"
	return "-"

func _get_bullpen_role_label(role: String) -> String:
	match role:
		"closer":
			return "クローザー"
		"setup":
			return "セットアッパー"
		"middle":
			return "中継ぎ"
		"long":
			return "ロング"
	return role

func _assign_bullpen_role(team, player_id: String, role: String) -> void:
	team.bullpen["closer"] = "" if str(team.bullpen.get("closer", "")) == player_id else str(team.bullpen.get("closer", ""))
	team.bullpen["long"] = "" if str(team.bullpen.get("long", "")) == player_id else str(team.bullpen.get("long", ""))
	var setup_ids: Array[String] = []
	for existing_id in team.bullpen.get("setup", []):
		if str(existing_id) != player_id:
			setup_ids.append(str(existing_id))
	var middle_ids: Array[String] = []
	for existing_id in team.bullpen.get("middle", []):
		if str(existing_id) != player_id:
			middle_ids.append(str(existing_id))
	match role:
		"closer":
			team.bullpen["closer"] = player_id
		"long":
			team.bullpen["long"] = player_id
		"setup":
			setup_ids.append(player_id)
		"middle":
			middle_ids.append(player_id)
	team.bullpen["setup"] = setup_ids
	team.bullpen["middle"] = middle_ids
	LeagueState.normalize_team_bullpen(team)

func _refresh_recent_games_list() -> void:
	for child in recent_games_vbox.get_children():
		child.queue_free()
	if last_game_ids.is_empty():
		_add_message_label(recent_games_vbox, "まだ試合は行われていません")
		return
	for game_id in last_game_ids:
		var game = _get_game_by_id(game_id)
		if game == null:
			continue
		var away_team = LeagueState.get_team(str(game.away_team_id))
		var home_team = LeagueState.get_team(str(game.home_team_id))
		var away_name: String = away_team.name if away_team != null else str(game.away_team_id)
		var home_name: String = home_team.name if home_team != null else str(game.home_team_id)
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = selected_game_id == game_id
		button.text = "%d日目  %s %d - %d %s" % [int(game.day), away_name, int(game.away_score), int(game.home_score), home_name]
		button.pressed.connect(_on_recent_game_pressed.bind(game_id))
		recent_games_vbox.add_child(button)

func _refresh_decision_summary() -> void:
	if selected_game_id == "":
		decision_detail_label.text = "まだ試合が選択されていません"
		return
	var game = _get_game_by_id(selected_game_id)
	if game == null:
		decision_detail_label.text = "試合データが見つかりません"
		return
	decision_detail_label.text = "勝利投手: %s\n敗戦投手: %s\nセーブ投手: %s" % [_get_player_name(game.winning_pitcher_id), _get_player_name(game.losing_pitcher_id), _get_player_name(game.save_pitcher_id)]

func _refresh_detailed_log() -> void:
	if selected_game_id == "":
		detailed_log_detail_label.text = "まだ試合が選択されていません"
		return
	var game = _get_game_by_id(selected_game_id)
	if game == null:
		detailed_log_detail_label.text = "試合データが見つかりません"
		return
	if game.log_lines.is_empty():
		detailed_log_detail_label.text = "詳細ログがありません"
		return
	var lines: Array[String] = []
	for line in game.log_lines:
		lines.append(str(line))
	detailed_log_detail_label.text = "\n".join(lines)

func _refresh_sim_day_button() -> void:
	var season_finished: bool = LeagueState.current_day > LeagueState.get_last_day()
	sim_day_button.disabled = season_finished
	new_season_button.disabled = not season_finished
	if season_finished:
		sim_day_button.text = "シーズン終了"
	else:
		sim_day_button.text = "1日消化"

func _store_recent_games(_simulated_day: int, games_today: Array) -> void:
	last_game_ids.clear()
	for game in games_today:
		last_game_ids.append(str(game.id))
	if last_game_ids.is_empty():
		selected_game_id = ""
	elif selected_game_id == "" or not last_game_ids.has(selected_game_id):
		selected_game_id = last_game_ids[0]

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

func _get_strategy_label(strategy: String) -> String:
	match strategy:
		"power":
			return "強打"
		"speed":
			return "機動力"
		"defense":
			return "守備重視"
		"pitching":
			return "投手重視"
		_:
			return "標準"

func _add_message_label(container: VBoxContainer, message: String) -> void:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0, 32)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	container.add_child(label)
