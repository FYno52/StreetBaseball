extends Control

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var sim_day_button: Button = $RootScroll/MarginContainer/RootVBox/SimDayButton
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll/TeamListVBox
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamDetailLabel
@onready var lineup_title_label: Label = $RootScroll/MarginContainer/RootVBox/LineupTitleLabel
@onready var lineup_detail_label: Label = $RootScroll/MarginContainer/RootVBox/LineupDetailLabel
@onready var rotation_title_label: Label = $RootScroll/MarginContainer/RootVBox/RotationTitleLabel
@onready var rotation_detail_label: Label = $RootScroll/MarginContainer/RootVBox/RotationDetailLabel

var selected_team_id: String = ""

func _ready() -> void:
	LeagueState.new_game()

	title_label.text = "League Home"
	selected_team_title_label.text = "選択球団詳細"
	selected_team_detail_label.text = "まだ球団が選択されていません"
	lineup_title_label.text = "スタメン"
	lineup_detail_label.text = "球団を選択するとスタメンが表示されます"
	rotation_title_label.text = "先発ローテ"
	rotation_detail_label.text = "球団を選択すると先発ローテが表示されます"

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
	_refresh_selected_team_lineup()
	_refresh_selected_team_rotation()

func _on_sim_day_button_pressed() -> void:
	LeagueState.simulate_current_day()
	LeagueState.advance_day()
	_refresh_view()

func _on_team_button_pressed(team_id: String) -> void:
	selected_team_id = team_id

	var team = LeagueState.get_team(team_id)
	if team != null:
		info_label.text = "現在日: %d / 選択球団: %s" % [LeagueState.current_day, team.name]

	_refresh_selected_team_detail()
	_refresh_selected_team_lineup()
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

func _refresh_selected_team_lineup() -> void:
	if selected_team_id == "":
		lineup_detail_label.text = "球団を選択するとスタメンが表示されます"
		return

	var data: Dictionary = LeagueState.get_team_lineup_and_bench(selected_team_id)
	var lineup: Array = data["lineup"]

	if lineup.is_empty():
		lineup_detail_label.text = "スタメンがありません"
		return

	var lines: Array[String] = []

	for i in range(lineup.size()):
		var p = lineup[i]
		lines.append("%d. %s  %s  OVR:%d" % [
			i + 1,
			p.full_name,
			p.primary_position,
			p.overall
		])

	lineup_detail_label.text = "\n".join(lines)

func _refresh_selected_team_rotation() -> void:
	if selected_team_id == "":
		rotation_detail_label.text = "球団を選択すると先発ローテが表示されます"
		return

	var rotation: Array = LeagueState.get_team_rotation(selected_team_id)

	if rotation.is_empty():
		rotation_detail_label.text = "先発ローテがありません"
		return

	var lines: Array[String] = []

	for i in range(rotation.size()):
		var p = rotation[i]
		lines.append("%d. %s  OVR:%d  VEL:%s CON:%s STA:%s" % [
			i + 1,
			p.full_name,
			p.overall,
			str(p.ratings["velocity"]),
			str(p.ratings["control"]),
			str(p.ratings["stamina"])
		])

	rotation_detail_label.text = "\n".join(lines)
