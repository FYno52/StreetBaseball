extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const PLAYER_DETAIL_SCENE_PATH := "res://scenes/PlayerDetail.tscn"
const ROSTER_MANAGEMENT_SCENE_PATH := "res://scenes/RosterManagement.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var manage_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/ManageButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var sort_overall_button: Button = $RootScroll/MarginContainer/RootVBox/SortButtonsHBox/SortOverallButton
@onready var sort_age_button: Button = $RootScroll/MarginContainer/RootVBox/SortButtonsHBox/SortAgeButton
@onready var sort_salary_button: Button = $RootScroll/MarginContainer/RootVBox/SortButtonsHBox/SortSalaryButton
@onready var sort_name_button: Button = $RootScroll/MarginContainer/RootVBox/SortButtonsHBox/SortNameButton
@onready var filter_all_button: Button = $RootScroll/MarginContainer/RootVBox/FilterButtonsHBox/FilterAllButton
@onready var filter_fielders_button: Button = $RootScroll/MarginContainer/RootVBox/FilterButtonsHBox/FilterFieldersButton
@onready var filter_pitchers_button: Button = $RootScroll/MarginContainer/RootVBox/FilterButtonsHBox/FilterPitchersButton
@onready var filter_active_button: Button = $RootScroll/MarginContainer/RootVBox/FilterButtonsHBox/FilterStartersButton
@onready var filter_reserve_button: Button = $RootScroll/MarginContainer/RootVBox/FilterButtonsHBox/FilterBenchButton
@onready var roster_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RosterVBox

var current_sort_key: String = "overall"
var current_filter_key: String = "all"


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "organization",
		"section_label": "PLAYERS",
		"sub_tab": "players",
		"sub_tabs": [
			{"key": "lineups", "label": "LINEUPS", "scene": TEAM_MANAGEMENT_SCENE_PATH},
			{"key": "roster", "label": "ROSTER", "scene": ROSTER_MANAGEMENT_SCENE_PATH},
			{"key": "players", "label": "PLAYERS", "scene": "res://scenes/RosterView.tscn"}
		],
		"top_right": "PLAYERS"
	})
	title_label.visible = false
	back_button.text = "ホームへ戻る"
	manage_button.text = "ロスター管理へ"
	sort_overall_button.text = "総合順"
	sort_age_button.text = "年齢順"
	sort_salary_button.text = "年俸順"
	sort_name_button.text = "名前順"
	filter_all_button.text = "全員"
	filter_fielders_button.text = "野手"
	filter_pitchers_button.text = "投手"
	filter_active_button.text = "一軍"
	filter_reserve_button.text = "二軍・育成"

	back_button.pressed.connect(_on_back_button_pressed)
	manage_button.pressed.connect(_on_manage_button_pressed)
	sort_overall_button.pressed.connect(_on_sort_button_pressed.bind("overall"))
	sort_age_button.pressed.connect(_on_sort_button_pressed.bind("age"))
	sort_salary_button.pressed.connect(_on_sort_button_pressed.bind("salary"))
	sort_name_button.pressed.connect(_on_sort_button_pressed.bind("name"))
	filter_all_button.pressed.connect(_on_filter_button_pressed.bind("all"))
	filter_fielders_button.pressed.connect(_on_filter_button_pressed.bind("fielders"))
	filter_pitchers_button.pressed.connect(_on_filter_button_pressed.bind("pitchers"))
	filter_active_button.pressed.connect(_on_filter_button_pressed.bind("active"))
	filter_reserve_button.pressed.connect(_on_filter_button_pressed.bind("reserve"))

	_refresh_view()


func _refresh_view() -> void:
	for child in roster_vbox.get_children():
		child.queue_free()

	_update_sort_buttons()
	_update_filter_buttons()

	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		_add_message_label("ホームから担当球団を選んでください。")
		return

	var roster_summary: Dictionary = LeagueState.get_team_roster_rule_summary(str(team.id))
	info_label.text = "%s の選手一覧です。ここは確認用で、昇降格や支配下登録はロスター管理で行います。\n支配下 %d/%d  一軍 %d/%d  外国人 %d人" % [
		team.name,
		int(roster_summary.get("registered", 0)),
		int(roster_summary.get("registered_max", 70)),
		int(roster_summary.get("active", 0)),
		int(roster_summary.get("active_target", 29)),
		int(roster_summary.get("foreign_signed", 0))
	]

	var grouped_players: Dictionary = _build_filtered_groups(team)
	_add_group("野手", grouped_players.get("fielders", []), team)
	_add_group("先発投手", grouped_players.get("starters", []), team)
	_add_group("救援投手", grouped_players.get("relievers", []), team)


func _build_filtered_groups(team: TeamData) -> Dictionary:
	var roster_groups: Dictionary = LeagueState.get_team_roster_groups(str(team.id))
	var result: Dictionary = {
		"fielders": [],
		"starters": [],
		"relievers": []
	}

	for player_value in roster_groups.get("fielders", []):
		var player: PlayerData = player_value
		if _matches_filter(player):
			result["fielders"].append(player)
	for player_value in roster_groups.get("starters", []):
		var player: PlayerData = player_value
		if _matches_filter(player):
			result["starters"].append(player)
	for player_value in roster_groups.get("relievers", []):
		var player: PlayerData = player_value
		if _matches_filter(player):
			result["relievers"].append(player)

	return result


func _matches_filter(player: PlayerData) -> bool:
	if player == null:
		return false

	match current_filter_key:
		"fielders":
			return not player.is_pitcher()
		"pitchers":
			return player.is_pitcher()
		"active":
			return str(player.roster_status) == "active"
		"reserve":
			return str(player.roster_status) == "farm" or str(player.roster_status) == "development"
		_:
			return true


func _add_group(title: String, players_in_group: Array, team: TeamData) -> void:
	var header_label := Label.new()
	header_label.custom_minimum_size = Vector2(0, 28)
	header_label.text = title
	roster_vbox.add_child(header_label)

	if players_in_group.is_empty():
		_add_message_label("条件に合う選手はいません。")
		return

	var sorted_players: Array = players_in_group.duplicate()
	sorted_players.sort_custom(_sort_players)

	for player_value in sorted_players:
		var player: PlayerData = player_value
		if player == null:
			continue
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = _build_player_row_text(player, team)
		button.pressed.connect(_on_player_button_pressed.bind(str(player.id)))
		roster_vbox.add_child(button)


func _sort_players(a: Variant, b: Variant) -> bool:
	var player_a: PlayerData = a
	var player_b: PlayerData = b
	match current_sort_key:
		"age":
			if int(player_a.age) == int(player_b.age):
				return str(player_a.full_name) < str(player_b.full_name)
			return int(player_a.age) < int(player_b.age)
		"salary":
			if int(player_a.salary) == int(player_b.salary):
				return str(player_a.full_name) < str(player_b.full_name)
			return int(player_a.salary) > int(player_b.salary)
		"name":
			return str(player_a.full_name) < str(player_b.full_name)
		_:
			if int(player_a.overall) == int(player_b.overall):
				return str(player_a.full_name) < str(player_b.full_name)
			return int(player_a.overall) > int(player_b.overall)


func _build_player_row_text(player: PlayerData, team: TeamData) -> String:
	var foreign_suffix := " / 外国人" if bool(player.is_foreign) else ""
	return "%s  %s  年齢:%d  年俸:%d  OVR:%d  %s  %s%s" % [
		player.full_name,
		_get_player_role_label(player),
		int(player.age),
		int(player.salary),
		int(player.overall),
		_get_player_assignment_label(player, team),
		_get_roster_status_label(player),
		foreign_suffix
	]


func _get_player_role_label(player: PlayerData) -> String:
	if player == null:
		return "-"
	if player.is_pitcher():
		match str(player.role):
			"starter":
				return "先発"
			"closer":
				return "抑え"
			_:
				return "救援"
	return str(player.primary_position)


func _get_player_assignment_label(player: PlayerData, team: TeamData) -> String:
	if player == null or team == null:
		return "未設定"

	var player_id: String = str(player.id)
	if team.rotation_ids.has(player_id):
		return "ローテ%d番" % [team.rotation_ids.find(player_id) + 1]
	if str(team.bullpen.get("closer", "")) == player_id:
		return "抑え"
	if team.bullpen.get("setup", []).has(player_id):
		return "セットアッパー"
	if team.bullpen.get("middle", []).has(player_id):
		return "中継ぎ"
	if str(team.bullpen.get("long", "")) == player_id:
		return "ロング"
	if team.lineup_vs_r.has(player_id) and team.lineup_vs_l.has(player_id):
		return "一軍スタメン"
	if team.lineup_vs_r.has(player_id):
		return "対右スタメン"
	if team.lineup_vs_l.has(player_id):
		return "対左スタメン"
	if team.bench_ids.has(player_id):
		return "一軍ベンチ"
	return "二軍・控え"


func _get_roster_status_label(player: PlayerData) -> String:
	match str(player.roster_status):
		"active":
			return "一軍"
		"development":
			return "育成"
		_:
			return "二軍"


func _update_sort_buttons() -> void:
	sort_overall_button.toggle_mode = true
	sort_age_button.toggle_mode = true
	sort_salary_button.toggle_mode = true
	sort_name_button.toggle_mode = true
	sort_overall_button.button_pressed = current_sort_key == "overall"
	sort_age_button.button_pressed = current_sort_key == "age"
	sort_salary_button.button_pressed = current_sort_key == "salary"
	sort_name_button.button_pressed = current_sort_key == "name"


func _update_filter_buttons() -> void:
	filter_all_button.toggle_mode = true
	filter_fielders_button.toggle_mode = true
	filter_pitchers_button.toggle_mode = true
	filter_active_button.toggle_mode = true
	filter_reserve_button.toggle_mode = true
	filter_all_button.button_pressed = current_filter_key == "all"
	filter_fielders_button.button_pressed = current_filter_key == "fielders"
	filter_pitchers_button.button_pressed = current_filter_key == "pitchers"
	filter_active_button.button_pressed = current_filter_key == "active"
	filter_reserve_button.button_pressed = current_filter_key == "reserve"


func _on_sort_button_pressed(sort_key: String) -> void:
	current_sort_key = sort_key
	_refresh_view()


func _on_filter_button_pressed(filter_key: String) -> void:
	current_filter_key = filter_key
	_refresh_view()


func _on_player_button_pressed(player_id: String) -> void:
	LeagueState.set_selected_player(player_id)
	get_tree().change_scene_to_file(PLAYER_DETAIL_SCENE_PATH)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)


func _on_manage_button_pressed() -> void:
	get_tree().change_scene_to_file(ROSTER_MANAGEMENT_SCENE_PATH)


func _add_message_label(message: String) -> void:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0, 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	roster_vbox.add_child(label)
