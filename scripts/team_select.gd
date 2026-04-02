extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var team_list_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/TeamListScroll/TeamListVBox
@onready var selected_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/SelectedTeamTitleLabel
@onready var selected_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/SelectedTeamDetailLabel
@onready var start_note_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/StartNoteLabel
@onready var load_button: Button = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/ActionButtonsHBox/LoadButton
@onready var decide_button: Button = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/ActionButtonsHBox/DecideButton

var selected_team_id: String = ""


func _ready() -> void:
	if LeagueState.teams.is_empty() or LeagueState.schedule.is_empty():
		LeagueState.new_game()

	title_label.text = "担当球団選択"
	info_label.text = "まずは担当する球団を選びます。固定開幕ロスターと球団カラーを見て、今季のスタート地点を決めましょう。"
	selected_team_title_label.text = "選択中の球団"
	start_note_label.text = "最初に選んだ球団を中心に、ホーム、チーム管理、リーグ情報、球団運営が進行します。"
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
		var team_id: String = str(summary["id"])
		var team: TeamData = LeagueState.get_team(team_id)
		var style_label: String = _get_style_label(team)
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = selected_team_id == team_id
		button.text = "%d. %s  %s  総合 %.1f  予算 %d  人気 %d" % [
			i + 1,
			str(summary["name"]),
			style_label,
			float(summary["total"]),
			_get_team_budget(team_id),
			_get_team_fan_support(team_id)
		]
		button.pressed.connect(_on_team_button_pressed.bind(team_id))
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
	var roster_rule_summary: Dictionary = LeagueState.get_team_roster_rule_summary(selected_team_id)
	var style_label: String = _get_style_label(team)
	var league_label: String = _get_league_label(selected_team_id)
	var star_text: String = _get_star_player_text(selected_team_id)
	selected_team_detail_label.text = "球団名: %s\nリーグ: %s\n球団カラー: %s\nファン人気: %d\n予算: %d\n方針: %s\n打撃力: %.2f\n投手力: %.2f\n総合力: %.2f\n\n開幕編成\n支配下: %d / %d\n一軍相当: %d / %d\n外国人保有: %d\n一軍外国人: %d / %d" % [
		team.name,
		league_label,
		style_label,
		int(team.fan_support),
		int(team.budget),
		_get_strategy_label(str(team.strategy)),
		attack,
		pitch_value,
		total,
		int(roster_rule_summary.get("registered", 0)),
		int(roster_rule_summary.get("registered_max", 0)),
		int(roster_rule_summary.get("active", 0)),
		int(roster_rule_summary.get("active_target", 0)),
		int(roster_rule_summary.get("foreign_signed", 0)),
		int(roster_rule_summary.get("foreign_active", 0)),
		int(roster_rule_summary.get("foreign_active_max", 0))
	]
	if star_text != "":
		selected_team_detail_label.text += "\n\n主な戦力\n%s" % star_text
	selected_team_detail_label.text += "\n\nこの球団を中心にシーズンを進めます。"


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


func _get_style_label(team: TeamData) -> String:
	if team == null:
		return "標準型"
	var style_key: String = ""
	for blueprint in LeagueState.team_master:
		if str(blueprint.get("id", "")) == str(team.id):
			style_key = str(blueprint.get("style", ""))
			break
	match style_key:
		"power":
			return "強打型"
		"speed":
			return "機動力型"
		"defense":
			return "守備型"
		"pitching":
			return "投手型"
		_:
			return "均衡型"


func _get_league_label(team_id: String) -> String:
	for blueprint in LeagueState.team_master:
		if str(blueprint.get("id", "")) != team_id:
			continue
		var league_key: String = str(blueprint.get("league", ""))
		match league_key:
			"metropolitan":
				return "メトロポリタン"
			"frontier":
				return "フロンティア"
			_:
				return "リーグ未設定"
	return "リーグ未設定"


func _get_star_player_text(team_id: String) -> String:
	for blueprint in LeagueState.team_master:
		if str(blueprint.get("id", "")) != team_id:
			continue
		var lines: Array[String] = []
		var core_players: Array = blueprint.get("core_players", [])
		for i in range(mini(4, core_players.size())):
			var player_def: Dictionary = core_players[i]
			lines.append("%s (%s)" % [str(player_def.get("name", "")), str(player_def.get("pos", ""))])
		return "\n".join(lines)
	return ""
