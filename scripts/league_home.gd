extends Control

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var sim_day_button: Button = $RootScroll/MarginContainer/RootVBox/SimDayButton
@onready var save_buttons_hbox: HBoxContainer = $RootScroll/MarginContainer/RootVBox/SaveButtonsHBox
@onready var save_button: Button = $RootScroll/MarginContainer/RootVBox/SaveButtonsHBox/SaveButton
@onready var load_button: Button = $RootScroll/MarginContainer/RootVBox/SaveButtonsHBox/LoadButton
@onready var save_status_label: Label = $RootScroll/MarginContainer/RootVBox/SaveStatusLabel
@onready var season_status_title_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusTitleLabel
@onready var season_status_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusDetailLabel
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll/TeamListVBox
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamDetailLabel
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

func _ready() -> void:
	LeagueState.new_game()

	title_label.text = "ストリート野球"
	save_button.text = "セーブ"
	load_button.text = "ロード"
	save_status_label.text = "保存データは user://save_01.json を使います"
	season_status_title_label.text = "シーズン状況"
	season_status_detail_label.text = "シーズン進行中です"
	selected_team_title_label.text = "チーム詳細"
	selected_team_detail_label.text = "まだチームが選択されていません"
	lineup_vs_r_title_label.text = "対右投手スタメン"
	lineup_vs_l_title_label.text = "対左投手スタメン"
	edit_title_label.text = "打線編集"
	edit_vs_r_button.text = "対右を編集"
	edit_vs_l_button.text = "対左を編集"
	cancel_edit_button.text = "編集をやめる"
	bench_title_label.text = "ベンチ"
	rotation_title_label.text = "先発ローテ"
	rotation_editor_status_label.text = "チームを選ぶと先発ローテが表示されます"
	bullpen_title_label.text = "ブルペン"
	bullpen_detail_label.text = "チームを選ぶとブルペンが表示されます"
	recent_games_title_label.text = "直近の試合一覧"
	decision_title_label.text = "試合結果"
	decision_detail_label.text = "まだ試合が選択されていません"
	detailed_log_title_label.text = "試合詳細ログ"
	detailed_log_detail_label.text = "まだ試合が選択されていません"

	sim_day_button.pressed.connect(_on_sim_day_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	edit_vs_r_button.pressed.connect(_on_edit_mode_pressed.bind("vs_r"))
	edit_vs_l_button.pressed.connect(_on_edit_mode_pressed.bind("vs_l"))
	cancel_edit_button.pressed.connect(_on_cancel_edit_pressed)

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

	_refresh_season_status()
	_refresh_selected_team_detail()
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
	if saved:
		save_status_label.text = "セーブしました: user://save_01.json"
	else:
		save_status_label.text = "セーブに失敗しました"

func _on_load_button_pressed() -> void:
	var loaded: bool = LeagueState.load_from_file()
	if not loaded:
		save_status_label.text = "ロードできませんでした。先にセーブを作成してください"
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
	save_status_label.text = "ロードしました: user://save_01.json"
	_refresh_view()

func _refresh_season_status() -> void:
	var season_finished: bool = LeagueState.current_day > LeagueState.get_last_day()
	if not season_finished:
		season_status_detail_label.text = "シーズン進行中: Day %d / %d\n1日消化でリーグが進みます" % [
			LeagueState.current_day,
			LeagueState.get_last_day()
		]
		return

	var sorted_teams: Array = LeagueState.get_teams_sorted_by_win_pct()
	if sorted_teams.is_empty():
		season_status_detail_label.text = "シーズン結果を表示できません"
		return

	var champion = sorted_teams[0]
	var last_place = sorted_teams[sorted_teams.size() - 1]
	var best_offense = _find_team_by_runs_for(true)
	var best_defense = _find_team_by_runs_against(true)

	season_status_detail_label.text = "シーズン終了\n優勝: %s\n最下位: %s\n最多得点: %s (%d)\n最少失点: %s (%d)\n総試合日数: %d" % [
		champion.name,
		last_place.name,
		best_offense.name if best_offense != null else "-",
		int(best_offense.standings["runs_for"]) if best_offense != null else 0,
		best_defense.name if best_defense != null else "-",
		int(best_defense.standings["runs_against"]) if best_defense != null else 0,
		LeagueState.get_last_day()
	]

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

func _on_team_button_pressed(team_id: String) -> void:
	selected_team_id = team_id
	selected_lineup_index = -1
	selected_rotation_index = -1

	var team = LeagueState.get_team(team_id)
	if team != null:
		info_label.text = "現在日: %d / 選択チーム: %s" % [LeagueState.current_day, team.name]

	_refresh_selected_team_detail()
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()
	_refresh_selected_team_rotation()
	_refresh_selected_team_bullpen()

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

	selected_team_detail_label.text = "チーム名: %s\n戦績: %s勝 %s敗 %s分\n得点: %s\n失点: %s\n打撃力: %.2f\n投手力: %.2f\n総合力: %.2f\n登録人数: %d" % [
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
	for child in lineup_vs_r_vbox.get_children():
		child.queue_free()
	for child in lineup_vs_l_vbox.get_children():
		child.queue_free()

	if selected_team_id == "":
		_add_message_label(lineup_vs_r_vbox, "チームを選ぶと対右スタメンが表示されます")
		_add_message_label(lineup_vs_l_vbox, "チームを選ぶと対左スタメンが表示されます")
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
		_add_message_label(container, "スタメンがまだ設定されていません")
		return

	for i in range(lineup_ids.size()):
		var p = LeagueState.get_player(str(lineup_ids[i]))
		if p == null:
			continue

		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = lineup_edit_target == mode and selected_lineup_index == i
		button.text = "%d. %s  %s  %s  AVG:%.3f  H:%s HR:%s RBI:%s" % [
			i + 1,
			p.full_name,
			p.primary_position,
			p.bats,
			p.get_batting_average(),
			str(p.batting_stats["h"]),
			str(p.batting_stats["hr"]),
			str(p.batting_stats["rbi"])
		]
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
		_add_message_label(bench_vbox, "ベンチが表示できません")
		return

	_rebuild_team_bench(team)

	if lineup_edit_target == "":
		editor_status_label.text = "編集したい打線を選ぶと、ベンチの選手と入れ替えできます"
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
		_add_message_label(bench_vbox, "ベンチに入れ替え可能な野手がいません")
		return

	for player_id in team.bench_ids:
		var p = LeagueState.get_player(str(player_id))
		if p == null:
			continue

		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = selected_lineup_index < 0
		button.text = "%s  %s  %s  AVG:%.3f  H:%s HR:%s RBI:%s" % [
			p.full_name,
			p.primary_position,
			p.bats,
			p.get_batting_average(),
			str(p.batting_stats["h"]),
			str(p.batting_stats["hr"]),
			str(p.batting_stats["rbi"])
		]
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
		rotation_editor_status_label.text = "先発ローテがありません"
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
		button.text = "%d. %s  %s投げ  ERA:%.2f  W:%s L:%s SO:%s" % [
			i + 1,
			p.full_name,
			p.throws,
			p.get_era(),
			str(p.pitching_stats["wins"]),
			str(p.pitching_stats["losses"]),
			str(p.pitching_stats["so"])
		]
		button.pressed.connect(_on_rotation_slot_pressed.bind(i))
		rotation_vbox.add_child(button)

func _refresh_selected_team_bullpen() -> void:
	if selected_team_id == "":
		bullpen_detail_label.text = "チームを選ぶとブルペンが表示されます"
		return

	var bullpen: Dictionary = LeagueState.get_team_bullpen(selected_team_id)
	var lines: Array[String] = []

	var closer = bullpen.get("closer", null)
	if closer != null:
		lines.append("CL  %s  ERA:%.2f  SV:%s  HLD:%s  SO:%s" % [
			closer.full_name,
			closer.get_era(),
			str(closer.pitching_stats["saves"]),
			str(closer.pitching_stats["holds"]),
			str(closer.pitching_stats["so"])
		])

	for p in bullpen.get("setup", []):
		lines.append("SU  %s  ERA:%.2f  SV:%s  HLD:%s  SO:%s" % [
			p.full_name,
			p.get_era(),
			str(p.pitching_stats["saves"]),
			str(p.pitching_stats["holds"]),
			str(p.pitching_stats["so"])
		])

	for p in bullpen.get("middle", []):
		lines.append("MR  %s  ERA:%.2f  SV:%s  HLD:%s  SO:%s" % [
			p.full_name,
			p.get_era(),
			str(p.pitching_stats["saves"]),
			str(p.pitching_stats["holds"]),
			str(p.pitching_stats["so"])
		])

	var long_reliever = bullpen.get("long", null)
	if long_reliever != null:
		lines.append("LR  %s  ERA:%.2f  SV:%s  HLD:%s  SO:%s" % [
			long_reliever.full_name,
			long_reliever.get_era(),
			str(long_reliever.pitching_stats["saves"]),
			str(long_reliever.pitching_stats["holds"]),
			str(long_reliever.pitching_stats["so"])
		])

	if lines.is_empty():
		bullpen_detail_label.text = "ブルペンがありません"
	else:
		bullpen_detail_label.text = "\n".join(lines)

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
		button.text = "Day %d  %s %d - %d %s" % [int(game.day), away_name, int(game.away_score), int(game.home_score), home_name]
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

	decision_detail_label.text = "勝利投手: %s\n敗戦投手: %s\nセーブ投手: %s" % [
		_get_player_name(game.winning_pitcher_id),
		_get_player_name(game.losing_pitcher_id),
		_get_player_name(game.save_pitcher_id)
	]

func _refresh_detailed_log() -> void:
	if selected_game_id == "":
		detailed_log_detail_label.text = "まだ試合が選択されていません"
		return

	var game = _get_game_by_id(selected_game_id)
	if game == null:
		detailed_log_detail_label.text = "試合データが見つかりません"
		return

	if game.log_lines.is_empty():
		detailed_log_detail_label.text = "この試合には詳細ログがありません"
		return

	var lines: Array[String] = []
	for line in game.log_lines:
		lines.append(str(line))

	detailed_log_detail_label.text = "\n".join(lines)

func _refresh_sim_day_button() -> void:
	var season_finished: bool = LeagueState.current_day > LeagueState.get_last_day()
	sim_day_button.disabled = season_finished
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

func _add_message_label(container: VBoxContainer, message: String) -> void:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0, 32)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	container.add_child(label)
