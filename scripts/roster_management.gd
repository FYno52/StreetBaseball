extends Control

const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"
const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var view_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/ViewButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var filter_all_button: Button = $RootScroll/MarginContainer/RootVBox/StatusButtonsHBox/FilterAllButton
@onready var filter_active_button: Button = $RootScroll/MarginContainer/RootVBox/StatusButtonsHBox/FilterActiveButton
@onready var filter_farm_button: Button = $RootScroll/MarginContainer/RootVBox/StatusButtonsHBox/FilterFarmButton
@onready var filter_development_button: Button = $RootScroll/MarginContainer/RootVBox/StatusButtonsHBox/FilterDevelopmentButton
@onready var filter_foreign_button: Button = $RootScroll/MarginContainer/RootVBox/StatusButtonsHBox/FilterForeignButton
@onready var roster_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RosterVBox

var current_filter_key: String = "all"
var last_action_message: String = ""


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "organization",
		"section_label": "ROSTER",
		"sub_tab": "roster",
		"sub_tabs": [
			{"key": "lineups", "label": "LINEUPS", "scene": TEAM_MANAGEMENT_SCENE_PATH},
			{"key": "roster", "label": "ROSTER", "scene": "res://scenes/RosterManagement.tscn"},
			{"key": "players", "label": "PLAYERS", "scene": ROSTER_VIEW_SCENE_PATH}
		],
		"top_right": "ROSTER"
	})
	title_label.visible = false
	back_button.text = "ホームへ戻る"
	view_button.text = "選手一覧へ"
	filter_all_button.text = "全員"
	filter_active_button.text = "一軍"
	filter_farm_button.text = "二軍"
	filter_development_button.text = "育成"
	filter_foreign_button.text = "外国人"

	back_button.pressed.connect(_on_back_button_pressed)
	view_button.pressed.connect(_on_view_button_pressed)
	filter_all_button.pressed.connect(_on_filter_button_pressed.bind("all"))
	filter_active_button.pressed.connect(_on_filter_button_pressed.bind("active"))
	filter_farm_button.pressed.connect(_on_filter_button_pressed.bind("farm"))
	filter_development_button.pressed.connect(_on_filter_button_pressed.bind("development"))
	filter_foreign_button.pressed.connect(_on_filter_button_pressed.bind("foreign"))

	_refresh_view()


func _refresh_view() -> void:
	for child in roster_vbox.get_children():
		child.queue_free()

	_update_filter_buttons()

	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		_add_message_label("ホームから担当球団を選んでください。")
		return

	var management_summary: Dictionary = LeagueState.get_controlled_team_player_management_summary()
	var roster_summary: Dictionary = management_summary.get("roster_rule_summary", {})
	var warnings_raw: Array = roster_summary.get("warnings", [])
	var warnings: Array[String] = []
	for item in warnings_raw:
		warnings.append(str(item))

	var active_pitchers: int = LeagueState.get_team_active_pitcher_count(str(team.id))
	var active_fielders: int = LeagueState.get_team_active_fielder_count(str(team.id))
	var foreign_signed: int = int(management_summary.get("foreign_signed_count", 0))
	var foreign_active: int = int(management_summary.get("foreign_active_count", 0))
	var foreign_active_pitchers: int = int(roster_summary.get("foreign_active_pitchers", 0))
	var foreign_active_fielders: int = int(roster_summary.get("foreign_active_fielders", 0))

	var info_lines: Array[String] = []
	info_lines.append("%s のロスター管理です。ここで一軍・二軍・育成・支配下登録を動かします。" % str(management_summary.get("team_name", team.name)))
	info_lines.append("一軍 %d人  二軍 %d人  育成 %d人" % [
		int(management_summary.get("active_count", 0)),
		int(management_summary.get("farm_count", 0)),
		int(management_summary.get("development_count", 0))
	])
	info_lines.append("支配下 %d / %d  一軍登録 %d / %d" % [
		int(roster_summary.get("registered", 0)),
		int(roster_summary.get("registered_max", 70)),
		int(roster_summary.get("active", 0)),
		int(roster_summary.get("active_target", 29))
	])
	info_lines.append("一軍内訳  投手 %d / 野手 %d" % [active_pitchers, active_fielders])
	info_lines.append("外国人  保有 %d  一軍 %d / %d  (投手 %d / 3  野手 %d / 3)" % [
		foreign_signed,
		foreign_active,
		int(roster_summary.get("foreign_active_max", 4)),
		foreign_active_pitchers,
		foreign_active_fielders
	])

	var recommendation_lines: Array[String] = _build_recommendation_lines(team, roster_summary, warnings)
	for line in recommendation_lines:
		info_lines.append(line)

	if not warnings.is_empty():
		info_lines.append("警告: " + " / ".join(warnings))
	if last_action_message != "":
		info_lines.append(last_action_message)
	info_label.text = "\n".join(info_lines)

	var roster: Array = LeagueState.get_team_full_roster(str(team.id))
	var shown_count: int = 0
	for player_value in roster:
		var player: PlayerData = player_value
		if player == null or not _matches_filter(player):
			continue
		_add_player_management_row(player)
		shown_count += 1

	if shown_count == 0:
		_add_message_label("条件に合う選手はいません。")


func _build_recommendation_lines(team: TeamData, roster_summary: Dictionary, warnings: Array[String]) -> Array[String]:
	var lines: Array[String] = []
	var active_count: int = int(roster_summary.get("active", 0))
	var active_target: int = int(roster_summary.get("active_target", 29))
	var development_count: int = 0
	for player_id in team.player_ids:
		var player: PlayerData = LeagueState.get_player(str(player_id))
		if player == null:
			continue
		if str(player.registration_type) == "development":
			development_count += 1

	if active_count < active_target:
		lines.append("今やるなら: 一軍枠にあと %d 人登録できます。" % (active_target - active_count))
	elif active_count == active_target:
		lines.append("今やるなら: 一軍登録は上限いっぱいです。入れ替え中心で管理します。")

	if development_count > 0 and int(roster_summary.get("registered", 0)) < int(roster_summary.get("registered_max", 70)):
		lines.append("育成選手が %d 人います。必要なら支配下登録を検討できます。" % development_count)

	if warnings.is_empty():
		lines.append("ロスター規定は現在クリアしています。")

	return lines


func _matches_filter(player: PlayerData) -> bool:
	match current_filter_key:
		"active":
			return str(player.roster_status) == "active"
		"farm":
			return str(player.roster_status) == "farm"
		"development":
			return str(player.roster_status) == "development"
		"foreign":
			return bool(player.is_foreign)
		_:
			return true


func _add_player_management_row(player: PlayerData) -> void:
	var row_hbox := HBoxContainer.new()
	row_hbox.add_theme_constant_override("separation", 8)
	roster_vbox.add_child(row_hbox)

	var summary_label := Label.new()
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.text = _build_player_summary_text(player)
	row_hbox.add_child(summary_label)

	var actions_hbox := HBoxContainer.new()
	actions_hbox.custom_minimum_size = Vector2(360, 0)
	actions_hbox.add_theme_constant_override("separation", 6)
	row_hbox.add_child(actions_hbox)

	var roster_option := OptionButton.new()
	roster_option.custom_minimum_size = Vector2(140, 0)
	_build_roster_option(roster_option, player)
	roster_option.item_selected.connect(_on_roster_option_selected.bind(str(player.id), roster_option))
	actions_hbox.add_child(roster_option)

	var focus_option := OptionButton.new()
	focus_option.custom_minimum_size = Vector2(180, 0)
	_build_focus_option(focus_option, player)
	focus_option.item_selected.connect(_on_focus_option_selected.bind(str(player.id), focus_option))
	actions_hbox.add_child(focus_option)


func _build_player_summary_text(player: PlayerData) -> String:
	var foreign_text: String = " / 外国人" if bool(player.is_foreign) else ""
	var role_text: String = "投手" if player.is_pitcher() else str(player.primary_position)
	return "%s  %s  年齢:%d  総合:%d  %s / %s / 育成:%s%s" % [
		player.full_name,
		role_text,
		int(player.age),
		int(player.overall),
		_get_registration_label(player),
		_get_status_label(player),
		player.get_development_focus_label(),
		foreign_text
	]


func _get_registration_label(player: PlayerData) -> String:
	return "育成契約" if str(player.registration_type) == "development" else "支配下"


func _get_status_label(player: PlayerData) -> String:
	match str(player.roster_status):
		"active":
			return "一軍"
		"development":
			return "育成"
		_:
			return "二軍"


func _update_filter_buttons() -> void:
	for button in [filter_all_button, filter_active_button, filter_farm_button, filter_development_button, filter_foreign_button]:
		button.toggle_mode = true
	filter_all_button.button_pressed = current_filter_key == "all"
	filter_active_button.button_pressed = current_filter_key == "active"
	filter_farm_button.button_pressed = current_filter_key == "farm"
	filter_development_button.button_pressed = current_filter_key == "development"
	filter_foreign_button.button_pressed = current_filter_key == "foreign"


func _on_filter_button_pressed(filter_key: String) -> void:
	current_filter_key = filter_key
	_refresh_view()


func _on_set_status_button_pressed(player_id: String, target_status: String) -> void:
	var result: Dictionary = LeagueState.set_controlled_player_roster_status(player_id, target_status)
	last_action_message = str(result.get("message", "ロスター状態を更新しました。"))
	_refresh_view()


func _on_promote_button_pressed(player_id: String) -> void:
	var result: Dictionary = LeagueState.promote_controlled_development_player(player_id)
	last_action_message = str(result.get("message", "支配下登録を更新しました。"))
	_refresh_view()


func _on_cycle_focus_button_pressed(player_id: String) -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		last_action_message = "担当球団が未設定です。"
		_refresh_view()
		return

	var player: PlayerData = LeagueState.get_player(player_id)
	if player == null or not team.player_ids.has(player_id):
		last_action_message = "担当球団の選手ではありません。"
		_refresh_view()
		return

	var focus_keys: Array[String] = player.get_available_development_focuses()
	var current_index: int = focus_keys.find(str(player.development_focus))
	if current_index < 0:
		current_index = 0
	var next_focus: String = focus_keys[(current_index + 1) % focus_keys.size()]
	var result: Dictionary = LeagueState.set_controlled_player_development_focus(player_id, next_focus)
	last_action_message = str(result.get("message", "育成方針を更新しました。"))
	_refresh_view()


func _build_roster_option(option: OptionButton, player: PlayerData) -> void:
	option.clear()
	if str(player.registration_type) == "development":
		option.add_item("育成", 0)
		option.add_item("支配下登録", 1)
		option.select(0)
		return

	if str(player.roster_status) == "active":
		option.add_item("一軍", 0)
		option.add_item("二軍", 1)
		option.select(0)
	else:
		option.add_item("一軍", 0)
		option.add_item("二軍", 1)
		option.select(1)


func _build_focus_option(option: OptionButton, player: PlayerData) -> void:
	option.clear()
	var focus_keys: Array[String] = player.get_available_development_focuses()
	var selected_index: int = 0
	for i in range(focus_keys.size()):
		var focus_key: String = focus_keys[i]
		var focus_label: String = _get_focus_label(player, focus_key)
		var option_label: String = "育成: %s" % focus_label if focus_key == str(player.development_focus) else focus_label
		option.add_item(option_label, i)
		if focus_key == str(player.development_focus):
			selected_index = i
	option.select(selected_index)


func _on_roster_option_selected(index: int, player_id: String, option: OptionButton) -> void:
	var player: PlayerData = LeagueState.get_player(player_id)
	if player == null:
		return

	var item_text: String = option.get_item_text(index)
	if str(player.registration_type) == "development":
		if item_text == "支配下登録":
			_on_promote_button_pressed(player_id)
		return

	var target_status: String = "active" if item_text == "一軍" else "farm"
	if str(player.roster_status) == target_status:
		return
	_on_set_status_button_pressed(player_id, target_status)


func _on_focus_option_selected(index: int, player_id: String, option: OptionButton) -> void:
	var player: PlayerData = LeagueState.get_player(player_id)
	if player == null:
		return
	var focus_keys: Array[String] = player.get_available_development_focuses()
	if index < 0 or index >= focus_keys.size():
		return
	var focus_key: String = focus_keys[index]
	var result: Dictionary = LeagueState.set_controlled_player_development_focus(player_id, focus_key)
	last_action_message = str(result.get("message", "育成方針を更新しました。"))
	_refresh_view()


func _get_focus_label(player: PlayerData, focus_key: String) -> String:
	if player.is_pitcher():
		match focus_key:
			"velocity":
				return "球威強化"
			"control":
				return "制球強化"
			"break":
				return "変化球強化"
			"stamina":
				return "スタミナ強化"
			_:
				return "バランス"
	match focus_key:
		"contact":
			return "ミート強化"
		"power":
			return "パワー強化"
		"eye":
			return "選球眼強化"
		"speed":
			return "走力強化"
		"fielding":
			return "守備強化"
		_:
			return "バランス"


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)


func _on_view_button_pressed() -> void:
	get_tree().change_scene_to_file(ROSTER_VIEW_SCENE_PATH)


func _add_message_label(message: String) -> void:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0, 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	roster_vbox.add_child(label)
