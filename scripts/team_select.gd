extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/TeamListScroll/TeamListVBox
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SelectedTeamDetailLabel
@onready var load_button: Button = $RootScroll/MarginContainer/RootVBox/ActionButtonsHBox/LoadButton
@onready var decide_button: Button = $RootScroll/MarginContainer/RootVBox/DecideButton

var selected_team_id: String = ""

func _ready() -> void:
	if LeagueState.teams.is_empty() or LeagueState.schedule.is_empty():
		LeagueState.new_game()

	title_label.text = "担当球団選択"
	info_label.text = "まずは担当する球団を選んでください。ここで選んだ球団を中心にシーズンが進みます。"
	selected_team_title_label.text = "選択中の球団"
	load_button.text = "セーブをロード"
	decide_button.text = "この球団で始める"
	load_button.pressed.connect(_on_load_button_pressed)
	decide_button.pressed.connect(_on_decide_button_pressed)

	_refresh_team_list()
	_refresh_selected_team()

func _refresh_team_list() -> void:
	for child in team_list_vbox.get_children():
		child.queue_free()

	var summaries: Array = LeagueState.get_league_team_summaries()
	for i in range(summaries.size()):
		var summary: Dictionary = summaries[i]
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = selected_team_id == str(summary["id"])
		button.text = "%d. %s  総合:%.1f  予算:%d  人気:%d" % [
			i + 1,
			str(summary["name"]),
			float(summary["total"]),
			_get_team_budget(str(summary["id"])),
			_get_team_fan_support(str(summary["id"]))
		]
		button.pressed.connect(_on_team_button_pressed.bind(str(summary["id"])))
		team_list_vbox.add_child(button)

func _on_team_button_pressed(team_id: String) -> void:
	selected_team_id = team_id
	_refresh_team_list()
	_refresh_selected_team()

func _refresh_selected_team() -> void:
	if selected_team_id == "":
		selected_team_detail_label.text = "まだ球団が選択されていません。"
		decide_button.disabled = true
		return

	var team: TeamData = LeagueState.get_team(selected_team_id)
	if team == null:
		selected_team_detail_label.text = "球団データが見つかりません。"
		decide_button.disabled = true
		return

	decide_button.disabled = false
	var attack: float = SimulationEngine.get_team_attack_value(team)
	var pitch_value: float = SimulationEngine.get_team_pitch_value(team)
	var total: float = SimulationEngine.get_team_total_strength(team)
	selected_team_detail_label.text = "球団名: %s\nファン人気: %d\n予算: %d\n方針: %s\n打撃力: %.2f\n投手力: %.2f\n総合力: %.2f\nこの球団を中心にシーズンを進めます。" % [
		team.name,
		int(team.fan_support),
		int(team.budget),
		_get_strategy_label(str(team.strategy)),
		attack,
		pitch_value,
		total
	]

func _on_decide_button_pressed() -> void:
	if selected_team_id == "":
		return
	LeagueState.set_controlled_team(selected_team_id)
	get_tree().change_scene_to_file(HOME_SCENE_PATH)

func _on_load_button_pressed() -> void:
	var loaded: bool = LeagueState.load_from_file()
	if not loaded:
		info_label.text = "ロードに失敗しました。新しく球団を選んで始めることもできます。"
		return
	if LeagueState.controlled_team_id != "":
		get_tree().change_scene_to_file(HOME_SCENE_PATH)
		return
	info_label.text = "セーブをロードしました。担当球団を選び直してください。"
	_refresh_team_list()
	_refresh_selected_team()

func _get_team_budget(team_id: String) -> int:
	var team: TeamData = LeagueState.get_team(team_id)
	if team == null:
		return 0
	return int(team.budget)

func _get_team_fan_support(team_id: String) -> int:
	var team: TeamData = LeagueState.get_team(team_id)
	if team == null:
		return 0
	return int(team.fan_support)

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
