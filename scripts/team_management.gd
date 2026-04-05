extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"
const ROSTER_MANAGEMENT_SCENE_PATH := "res://scenes/RosterManagement.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var set_controlled_team_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/SetControlledTeamButton
@onready var roster_view_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/RosterViewButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll/TeamListVBox
@onready var team_list_scroll: ScrollContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/SelectedTeamCard/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/SelectedTeamCard/SelectedTeamDetailLabel
@onready var strategy_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyTitleLabel
@onready var strategy_status_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyStatusLabel
@onready var strategy_balanced_button: Button = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyButtonsHBox/StrategyBalancedButton
@onready var strategy_power_button: Button = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyButtonsHBox/StrategyPowerButton
@onready var strategy_speed_button: Button = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyButtonsHBox/StrategySpeedButton
@onready var strategy_defense_button: Button = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyButtonsHBox/StrategyDefenseButton
@onready var strategy_pitching_button: Button = $RootScroll/MarginContainer/RootVBox/SummaryGrid/StrategyCard/StrategyButtonsHBox/StrategyPitchingButton
@onready var lineup_vs_r_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupColumns/LineupRightCard/LineupVsRTitleLabel
@onready var lineup_vs_r_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/LineupColumns/LineupRightCard/LineupVsRVBox
@onready var lineup_vs_l_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupColumns/LineupLeftCard/LineupVsLTitleLabel
@onready var lineup_vs_l_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/LineupColumns/LineupLeftCard/LineupVsLVBox
@onready var edit_title_label: Label = $RootScroll/MarginContainer/RootVBox/EditTitleLabel
@onready var edit_vs_r_button: Button = $RootScroll/MarginContainer/RootVBox/EditButtonsHBox/EditVsRButton
@onready var edit_vs_l_button: Button = $RootScroll/MarginContainer/RootVBox/EditButtonsHBox/EditVsLButton
@onready var cancel_edit_button: Button = $RootScroll/MarginContainer/RootVBox/EditButtonsHBox/CancelEditButton
@onready var editor_status_label: Label = $RootScroll/MarginContainer/RootVBox/EditorStatusLabel
@onready var bench_title_label: Label = $RootScroll/MarginContainer/RootVBox/BenchTitleLabel
@onready var bench_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/BenchVBox
@onready var rotation_title_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingColumns/RotationCard/RotationTitleLabel
@onready var rotation_editor_status_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingColumns/RotationCard/RotationEditorStatusLabel
@onready var rotation_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/PitchingColumns/RotationCard/RotationVBox
@onready var bullpen_title_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenTitleLabel
@onready var bullpen_detail_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenDetailLabel
@onready var bullpen_editor_status_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenEditorStatusLabel
@onready var bullpen_auto_button: Button = get_node_or_null("RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenRoleButtonsHBox/BullpenAutoButton")
@onready var bullpen_closer_button: Button = get_node_or_null("RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenRoleButtonsHBox/BullpenCloserButton")
@onready var bullpen_setup_button: Button = get_node_or_null("RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenRoleButtonsHBox/BullpenSetupButton")
@onready var bullpen_middle_button: Button = get_node_or_null("RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenRoleButtonsHBox/BullpenMiddleButton")
@onready var bullpen_long_button: Button = get_node_or_null("RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenRoleButtonsHBox/BullpenLongButton")
@onready var bullpen_pitchers_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/PitchingColumns/BullpenCard/BullpenPitchersVBox

var selected_team_id: String = ""
var lineup_edit_target: String = ""
var selected_lineup_index: int = -1
var selected_rotation_index: int = -1
var bullpen_edit_target: String = ""


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "organization",
		"section_label": "LINEUPS",
		"sub_tab": "lineups",
		"sub_tabs": [
			{"key": "lineups", "label": "LINEUPS", "scene": "res://scenes/TeamManagement.tscn"},
			{"key": "roster", "label": "ROSTER", "scene": ROSTER_MANAGEMENT_SCENE_PATH},
			{"key": "players", "label": "PLAYERS", "scene": ROSTER_VIEW_SCENE_PATH}
		],
		"top_right": "ORGANIZATION"
	})
	title_label.visible = false
	back_button.text = "ホームへ戻る"
	set_controlled_team_button.text = "担当球団にする"
	roster_view_button.text = "選手一覧へ"
	selected_team_title_label.text = "チーム概要"
	strategy_title_label.text = "チーム方針"
	lineup_vs_r_title_label.text = "対右スタメン"
	lineup_vs_l_title_label.text = "対左スタメン"
	edit_title_label.text = "オーダー編集"
	edit_vs_r_button.text = "対右を編集"
	edit_vs_l_button.text = "対左を編集"
	cancel_edit_button.text = "編集をやめる"
	bench_title_label.text = "控え野手"
	rotation_title_label.text = "先発6枚"
	bullpen_title_label.text = "勝ちパターン"
	if bullpen_auto_button != null:
		bullpen_auto_button.text = "自動再編"
	if bullpen_closer_button != null:
		bullpen_closer_button.text = "抑え"
	if bullpen_setup_button != null:
		bullpen_setup_button.text = "勝ちパ"
	if bullpen_middle_button != null:
		bullpen_middle_button.text = "中継ぎ"
	if bullpen_long_button != null:
		bullpen_long_button.text = "ロング"
	strategy_balanced_button.text = "バランス"
	strategy_power_button.text = "強打"
	strategy_speed_button.text = "機動力"
	strategy_defense_button.text = "守備重視"
	strategy_pitching_button.text = "投手重視"

	back_button.pressed.connect(_on_back_button_pressed)
	set_controlled_team_button.pressed.connect(_on_set_controlled_team_button_pressed)
	roster_view_button.pressed.connect(_on_roster_view_button_pressed)
	edit_vs_r_button.pressed.connect(_on_edit_mode_pressed.bind("vs_r"))
	edit_vs_l_button.pressed.connect(_on_edit_mode_pressed.bind("vs_l"))
	cancel_edit_button.pressed.connect(_on_cancel_edit_pressed)
	strategy_balanced_button.pressed.connect(_on_strategy_button_pressed.bind("balanced"))
	strategy_power_button.pressed.connect(_on_strategy_button_pressed.bind("power"))
	strategy_speed_button.pressed.connect(_on_strategy_button_pressed.bind("speed"))
	strategy_defense_button.pressed.connect(_on_strategy_button_pressed.bind("defense"))
	strategy_pitching_button.pressed.connect(_on_strategy_button_pressed.bind("pitching"))
	if bullpen_closer_button != null:
		bullpen_closer_button.pressed.connect(_on_bullpen_role_button_pressed.bind("closer"))
	if bullpen_setup_button != null:
		bullpen_setup_button.pressed.connect(_on_bullpen_role_button_pressed.bind("setup"))
	if bullpen_middle_button != null:
		bullpen_middle_button.pressed.connect(_on_bullpen_role_button_pressed.bind("middle"))
	if bullpen_long_button != null:
		bullpen_long_button.pressed.connect(_on_bullpen_role_button_pressed.bind("long"))
	if bullpen_auto_button != null:
		bullpen_auto_button.pressed.connect(_on_bullpen_auto_button_pressed)

	if LeagueState.controlled_team_id != "":
		selected_team_id = LeagueState.controlled_team_id

	_refresh_view()


func _refresh_view() -> void:
	_apply_controlled_team_mode()
	_clear_container(team_list_vbox)

	if team_list_scroll.visible:
		var summaries: Array = LeagueState.get_league_team_summaries()
		for index in range(summaries.size()):
			var summary: Dictionary = summaries[index]
			var button := Button.new()
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text = "%d. %s  %s勝%s敗%s分  勝率 %.3f" % [
				index + 1,
				str(summary.get("name", "-")),
				str(summary.get("wins", 0)),
				str(summary.get("losses", 0)),
				str(summary.get("draws", 0)),
				float(summary.get("win_pct", 0.0))
			]
			button.pressed.connect(_on_team_button_pressed.bind(str(summary.get("id", ""))))
			team_list_vbox.add_child(button)

	_refresh_selected_team_detail()
	_refresh_strategy_editor()
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()
	_refresh_selected_team_rotation()
	_refresh_selected_team_bullpen()


func _apply_controlled_team_mode() -> void:
	var has_controlled_team: bool = LeagueState.controlled_team_id != ""
	if has_controlled_team:
		if selected_team_id == "":
			selected_team_id = LeagueState.controlled_team_id
		info_label.text = "担当球団の運用画面です。スタメン、先発6枚、勝ちパターンをここで固めます。"
		team_list_scroll.visible = false
		set_controlled_team_button.visible = false
	else:
		info_label.text = "チームを選ぶと、その球団のスタメン・先発・役割を確認できます。"
		team_list_scroll.visible = true
		set_controlled_team_button.visible = true


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)


func _on_roster_view_button_pressed() -> void:
	get_tree().change_scene_to_file(ROSTER_VIEW_SCENE_PATH)


func _on_set_controlled_team_button_pressed() -> void:
	if selected_team_id == "":
		info_label.text = "担当球団にしたいチームを先に選んでください。"
		return
	LeagueState.set_controlled_team(selected_team_id)
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team != null:
		info_label.text = "%s を担当球団に設定しました。" % team.name
	_refresh_view()


func _on_team_button_pressed(team_id: String) -> void:
	selected_team_id = team_id
	lineup_edit_target = ""
	selected_lineup_index = -1
	selected_rotation_index = -1
	bullpen_edit_target = ""
	var team: TeamData = LeagueState.get_team(team_id)
	if team != null:
		var suffix := ""
		if LeagueState.controlled_team_id == team_id:
			suffix = " / 担当球団"
		info_label.text = "選択中: %s%s" % [team.name, suffix]
	else:
		info_label.text = "チーム情報を取得できませんでした。"
	_refresh_selected_team_detail()
	_refresh_strategy_editor()
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()
	_refresh_selected_team_rotation()
	_refresh_selected_team_bullpen()


func _on_strategy_button_pressed(strategy: String) -> void:
	if selected_team_id == "":
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	team.strategy = strategy
	_refresh_selected_team_detail()
	_refresh_strategy_editor()


func _refresh_strategy_editor() -> void:
	_update_strategy_buttons()
	if selected_team_id == "":
		strategy_status_label.text = "チームを選ぶと方針を変更できます。"
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		strategy_status_label.text = "チーム情報を取得できませんでした。"
		return
	strategy_status_label.text = "現在の方針: %s\n打線の色と投手運用の基調をここで決めます。" % _get_strategy_label(str(team.strategy))


func _update_strategy_buttons() -> void:
	var current_strategy := ""
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team != null:
		current_strategy = str(team.strategy)
	var disabled := selected_team_id == ""
	for button in [strategy_balanced_button, strategy_power_button, strategy_speed_button, strategy_defense_button, strategy_pitching_button]:
		button.toggle_mode = true
		button.disabled = disabled
	strategy_balanced_button.button_pressed = current_strategy == "balanced"
	strategy_power_button.button_pressed = current_strategy == "power"
	strategy_speed_button.button_pressed = current_strategy == "speed"
	strategy_defense_button.button_pressed = current_strategy == "defense"
	strategy_pitching_button.button_pressed = current_strategy == "pitching"


func _refresh_selected_team_detail() -> void:
	if selected_team_id == "":
		selected_team_detail_label.text = "まだチームが選ばれていません。"
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		selected_team_detail_label.text = "チーム情報を取得できませんでした。"
		return

	var attack: float = SimulationEngine.get_team_attack_value(team)
	var pitch_value: float = SimulationEngine.get_team_pitch_value(team)
	var total: float = SimulationEngine.get_team_total_strength(team)
	var roster_rule_summary: Dictionary = LeagueState.get_team_roster_rule_summary(selected_team_id)
	var warning_lines: Array[String] = roster_rule_summary.get("warnings", [])
	var warning_text := "問題なし"
	if not warning_lines.is_empty():
		warning_text = " / ".join(warning_lines)

	var starter = LeagueState.get_starting_pitcher_for_day(selected_team_id, LeagueState.current_day)
	var starter_name := "未定"
	if starter != null:
		starter_name = starter.full_name

	var main_catcher := _find_player_name(team.lineup_vs_r, 1)
	var cleanup := _find_cleanup_name(team.lineup_vs_r)

	var team_name := team.name
	if LeagueState.controlled_team_id == selected_team_id:
		team_name += " (担当球団)"

	selected_team_detail_label.text = (
		"%s\n"
		+ "%s勝%s敗%s分  人気 %d / 予算 %d\n"
		+ "方針: %s  打撃 %.2f / 投手 %.2f / 総合 %.2f\n"
		+ "予想先発: %s\n"
		+ "主軸: %s  正捕手: %s\n"
		+ "支配下 %d/%d  一軍 %d/%d  外国人 %d人\n"
		+ "編成メモ: %s"
	) % [
		team_name,
		str(team.standings.get("wins", 0)),
		str(team.standings.get("losses", 0)),
		str(team.standings.get("draws", 0)),
		int(team.fan_support),
		int(team.budget),
		_get_strategy_label(str(team.strategy)),
		attack,
		pitch_value,
		total,
		starter_name,
		cleanup,
		main_catcher,
		int(roster_rule_summary.get("registered", 0)),
		int(roster_rule_summary.get("registered_max", 0)),
		int(roster_rule_summary.get("active", 0)),
		int(roster_rule_summary.get("active_target", 0)),
		int(roster_rule_summary.get("foreign_signed", 0)),
		warning_text
	]


func _refresh_selected_team_lineups() -> void:
	_clear_container(lineup_vs_r_vbox)
	_clear_container(lineup_vs_l_vbox)
	if selected_team_id == "":
		_add_message_label(lineup_vs_r_vbox, "チームを選ぶと対右オーダーが表示されます。")
		_add_message_label(lineup_vs_l_vbox, "チームを選ぶと対左オーダーが表示されます。")
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	_populate_lineup_buttons(lineup_vs_r_vbox, team.lineup_vs_r, "vs_r")
	_populate_lineup_buttons(lineup_vs_l_vbox, team.lineup_vs_l, "vs_l")


func _populate_lineup_buttons(container: VBoxContainer, lineup_ids: Array[String], mode: String) -> void:
	for index in range(lineup_ids.size()):
		var player: PlayerData = LeagueState.get_player(str(lineup_ids[index]))
		if player == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = lineup_edit_target == mode and selected_lineup_index == index
		button.text = "%d. %s  %s  打率 %.3f  本 %s  点 %s" % [
			index + 1,
			player.full_name,
			player.primary_position,
			player.get_batting_average(),
			str(player.batting_stats.get("hr", 0)),
			str(player.batting_stats.get("rbi", 0))
		]
		button.pressed.connect(_on_lineup_slot_pressed.bind(mode, index))
		container.add_child(button)


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


func _refresh_lineup_editor() -> void:
	_clear_container(bench_vbox)
	if selected_team_id == "":
		editor_status_label.text = "チームを選ぶとオーダー編集が使えます。"
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		editor_status_label.text = "チーム情報を取得できませんでした。"
		return

	_rebuild_team_bench(team)
	if lineup_edit_target == "":
		editor_status_label.text = "対右または対左を選ぶと、ベンチから差し替えできます。"
		return
	if selected_lineup_index < 0:
		editor_status_label.text = "入れ替えたい打順を先に選んでください。"
	else:
		editor_status_label.text = "ベンチ候補を選ぶと、その打順と入れ替わります。"

	for player_id in team.bench_ids:
		var player: PlayerData = LeagueState.get_player(str(player_id))
		if player == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = selected_lineup_index < 0
		button.text = "%s  %s  打率 %.3f" % [player.full_name, player.primary_position, player.get_batting_average()]
		button.pressed.connect(_on_bench_player_pressed.bind(str(player_id)))
		bench_vbox.add_child(button)


func _on_bench_player_pressed(player_id: String) -> void:
	if selected_team_id == "" or lineup_edit_target == "" or selected_lineup_index < 0:
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	var target_lineup: Array[String] = team.lineup_vs_r if lineup_edit_target == "vs_r" else team.lineup_vs_l
	if selected_lineup_index >= target_lineup.size():
		return
	target_lineup[selected_lineup_index] = player_id
	if lineup_edit_target == "vs_r":
		team.lineup_vs_r = target_lineup
	else:
		team.lineup_vs_l = target_lineup
	_rebuild_team_bench(team)
	selected_lineup_index = -1
	_refresh_selected_team_lineups()
	_refresh_lineup_editor()


func _rebuild_team_bench(team: TeamData) -> void:
	var used_ids: Array[String] = []
	for player_id in team.lineup_vs_r:
		if not used_ids.has(str(player_id)):
			used_ids.append(str(player_id))
	for player_id in team.lineup_vs_l:
		if not used_ids.has(str(player_id)):
			used_ids.append(str(player_id))

	team.bench_ids.clear()
	for player_id in team.player_ids:
		var player: PlayerData = LeagueState.get_player(str(player_id))
		if player == null or player.is_pitcher():
			continue
		if not used_ids.has(str(player.id)):
			team.bench_ids.append(str(player.id))


func _refresh_selected_team_rotation() -> void:
	_clear_container(rotation_vbox)
	if selected_team_id == "":
		rotation_editor_status_label.text = "チームを選ぶと先発ローテが表示されます。"
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		rotation_editor_status_label.text = "チーム情報を取得できませんでした。"
		return

	rotation_editor_status_label.text = "2人選ぶと順番を入れ替えます。1番手が今日の予想先発です。"
	for index in range(team.rotation_ids.size()):
		var player: PlayerData = LeagueState.get_player(str(team.rotation_ids[index]))
		if player == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = selected_rotation_index == index
		button.text = "%d. %s  防御率 %.2f  %s勝%s敗  奪三振 %s" % [
			index + 1,
			player.full_name,
			player.get_era(),
			str(player.pitching_stats.get("wins", 0)),
			str(player.pitching_stats.get("losses", 0)),
			str(player.pitching_stats.get("so", 0))
		]
		button.pressed.connect(_on_rotation_slot_pressed.bind(index))
		rotation_vbox.add_child(button)


func _on_rotation_slot_pressed(index: int) -> void:
	if selected_team_id == "":
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null or index < 0 or index >= team.rotation_ids.size():
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


func _refresh_selected_team_bullpen() -> void:
	_clear_container(bullpen_pitchers_vbox)
	_update_bullpen_role_buttons()
	if selected_team_id == "":
		bullpen_detail_label.text = "チームを選ぶと勝ちパターンが表示されます。"
		bullpen_editor_status_label.text = "役割を選んでから投手を選んでください。"
		return
	var bullpen: Dictionary = LeagueState.get_team_bullpen(selected_team_id)
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		bullpen_detail_label.text = "チーム情報を取得できませんでした。"
		bullpen_editor_status_label.text = "チーム情報を取得できませんでした。"
		return

	var lines: Array[String] = []
	var closer: PlayerData = bullpen.get("closer", null)
	if closer != null:
		lines.append("抑え  %s" % closer.full_name)
	for player_value in bullpen.get("setup", []):
		var setup_player: PlayerData = player_value
		lines.append("勝ちパ  %s" % setup_player.full_name)
	for player_value in bullpen.get("middle", []):
		var middle_player: PlayerData = player_value
		lines.append("中継ぎ  %s" % middle_player.full_name)
	var long_reliever: PlayerData = bullpen.get("long", null)
	if long_reliever != null:
		lines.append("ロング  %s" % long_reliever.full_name)

	bullpen_detail_label.text = "勝ちパターン未設定" if lines.is_empty() else "\n".join(lines)
	bullpen_editor_status_label.text = "役割を選んでから投手を選んでください。" if bullpen_edit_target == "" else "編集中の役割: %s" % _get_bullpen_role_label(bullpen_edit_target)

	for pitcher_value in _get_relief_pitchers_for_team(team):
		var pitcher: PlayerData = pitcher_value
		var role_label: String = _get_pitcher_bullpen_role(team, str(pitcher.id))
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = bullpen_edit_target == ""
		button.text = "%s  %s  防御率 %.2f  奪三振 %s" % [
			pitcher.full_name,
			role_label,
			pitcher.get_era(),
			str(pitcher.pitching_stats.get("so", 0))
		]
		button.pressed.connect(_on_bullpen_pitcher_pressed.bind(str(pitcher.id)))
		bullpen_pitchers_vbox.add_child(button)


func _update_bullpen_role_buttons() -> void:
	var disabled := selected_team_id == ""
	for button in [bullpen_closer_button, bullpen_setup_button, bullpen_middle_button, bullpen_long_button]:
		if button == null:
			continue
		button.toggle_mode = true
		button.disabled = disabled
	if bullpen_auto_button != null:
		bullpen_auto_button.disabled = disabled
	if bullpen_closer_button != null:
		bullpen_closer_button.button_pressed = bullpen_edit_target == "closer"
	if bullpen_setup_button != null:
		bullpen_setup_button.button_pressed = bullpen_edit_target == "setup"
	if bullpen_middle_button != null:
		bullpen_middle_button.button_pressed = bullpen_edit_target == "middle"
	if bullpen_long_button != null:
		bullpen_long_button.button_pressed = bullpen_edit_target == "long"


func _on_bullpen_role_button_pressed(role: String) -> void:
	if selected_team_id == "":
		return
	bullpen_edit_target = "" if bullpen_edit_target == role else role
	_refresh_selected_team_bullpen()


func _get_relief_pitchers_for_team(team: TeamData) -> Array:
	var result: Array = []
	for player_id in team.player_ids:
		var player: PlayerData = LeagueState.get_player(str(player_id))
		if player != null and (str(player.role) == "reliever" or str(player.role) == "closer"):
			result.append(player)
	return result


func _get_pitcher_bullpen_role(team: TeamData, player_id: String) -> String:
	if str(team.bullpen.get("closer", "")) == player_id:
		return "抑え"
	if str(team.bullpen.get("long", "")) == player_id:
		return "ロング"
	if team.bullpen.get("setup", []).has(player_id):
		return "勝ちパ"
	if team.bullpen.get("middle", []).has(player_id):
		return "中継ぎ"
	return "-"


func _get_bullpen_role_label(role: String) -> String:
	match role:
		"closer":
			return "抑え"
		"setup":
			return "勝ちパ"
		"middle":
			return "中継ぎ"
		"long":
			return "ロング"
		_:
			return role


func _on_bullpen_pitcher_pressed(player_id: String) -> void:
	if selected_team_id == "" or bullpen_edit_target == "":
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	_assign_bullpen_role(team, player_id, bullpen_edit_target)
	_refresh_selected_team_bullpen()


func _on_bullpen_auto_button_pressed() -> void:
	if selected_team_id == "":
		return
	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		return
	LeagueState.auto_assign_team_bullpen(team)
	bullpen_edit_target = ""
	_refresh_selected_team_bullpen()


func _assign_bullpen_role(team: TeamData, player_id: String, role: String) -> void:
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
			return "バランス"


func _add_message_label(container: VBoxContainer, message: String) -> void:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0, 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	container.add_child(label)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()


func _find_player_name(lineup_ids: Array, lineup_index: int) -> String:
	if lineup_index < 0 or lineup_index >= lineup_ids.size():
		return "未設定"
	var player: PlayerData = LeagueState.get_player(str(lineup_ids[lineup_index]))
	if player == null:
		return "未設定"
	return player.full_name


func _find_cleanup_name(lineup_ids: Array) -> String:
	var candidates := [3, 4]
	for index in candidates:
		if index < lineup_ids.size():
			var player: PlayerData = LeagueState.get_player(str(lineup_ids[index]))
			if player != null:
				return player.full_name
	return "未設定"
