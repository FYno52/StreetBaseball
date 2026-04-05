extends Control

const LEAGUE_HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const CONTRACT_OFFICE_SCENE_PATH := "res://scenes/ContractOffice.tscn"
const SPONSOR_OFFICE_SCENE_PATH := "res://scenes/SponsorOffice.tscn"
const FACILITY_OFFICE_SCENE_PATH := "res://scenes/FacilityOffice.tscn"
const STAFF_OFFICE_SCENE_PATH := "res://scenes/StaffOffice.tscn"
const SCOUT_DRAFT_OFFICE_SCENE_PATH := "res://scenes/ScoutDraftOffice.tscn"
const TRADE_OFFICE_SCENE_PATH := "res://scenes/TradeOffice.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const ROSTER_MANAGEMENT_SCENE_PATH := "res://scenes/RosterManagement.tscn"
const RECORD_ROOM_SCENE_PATH := "res://scenes/RecordRoom.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryTitleLabel
@onready var summary_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryDetailLabel
@onready var contract_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/ContractButton
@onready var team_management_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/TeamManagementButton
@onready var roster_management_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/RosterManagementButton
@onready var facility_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/FacilityButton
@onready var sponsor_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/SponsorButton
@onready var staff_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/StaffButton
@onready var scout_draft_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/ScoutDraftButton
@onready var trade_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/TradeButton
@onready var record_room_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/RecordRoomButton
@onready var roadmap_title_label: Label = $RootScroll/MarginContainer/RootVBox/RoadmapTitleLabel
@onready var roadmap_detail_label: Label = $RootScroll/MarginContainer/RootVBox/RoadmapDetailLabel
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel

func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "front_office",
		"section_label": "FRONT OFFICE",
		"sub_tab": "hub",
		"sub_tabs": [
			{"key": "hub", "label": "HUB", "scene": "res://scenes/FrontOffice.tscn"},
			{"key": "contracts", "label": "CONTRACTS", "scene": CONTRACT_OFFICE_SCENE_PATH},
			{"key": "trades", "label": "TRADES", "scene": TRADE_OFFICE_SCENE_PATH}
		],
		"top_right": "FRONT OFFICE"
	})
	_setup_static_text()
	_connect_buttons()
	_refresh_view()

func _setup_static_text() -> void:
	title_label.visible = false
	back_button.text = "ホームへ戻る"
	info_label.text = "球団運営の入口です。ここでは状況を見て、必要な管理ページへ移動します。"
	summary_title_label.text = "今日の運営状況"
	contract_button.text = "契約・FA"
	team_management_button.text = "チーム管理"
	roster_management_button.text = "ロスター管理"
	facility_button.text = "施設"
	sponsor_button.text = "スポンサー"
	staff_button.text = "スタッフ"
	scout_draft_button.text = "スカウト・ドラフト"
	trade_button.text = "トレード"
	record_room_button.text = "記録室"
	roadmap_title_label.text = "主な導線"
	roadmap_detail_label.text = "確認は チーム管理 / 選手一覧 / 記録室、操作は 契約・FA / ロスター管理 / スカウト・ドラフト / トレード / 施設 / スポンサー / スタッフ"

func _connect_buttons() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEAGUE_HOME_SCENE_PATH))
	contract_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(CONTRACT_OFFICE_SCENE_PATH))
	team_management_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TEAM_MANAGEMENT_SCENE_PATH))
	roster_management_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(ROSTER_MANAGEMENT_SCENE_PATH))
	facility_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FACILITY_OFFICE_SCENE_PATH))
	sponsor_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SPONSOR_OFFICE_SCENE_PATH))
	staff_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(STAFF_OFFICE_SCENE_PATH))
	scout_draft_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SCOUT_DRAFT_OFFICE_SCENE_PATH))
	trade_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TRADE_OFFICE_SCENE_PATH))
	record_room_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(RECORD_ROOM_SCENE_PATH))

func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		summary_detail_label.text = "担当球団が未設定です。"
		status_label.text = ""
		return

	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	var contract_summary: Dictionary = LeagueState.get_controlled_team_contract_summary()
	var expiring_count: int = int(contract_summary.get("expiring_count", 0))
	var fa_watch: Array = contract_summary.get("fa_watch_players", [])
	var total_salary: int = int(snapshot.get("total_salary", 0))
	var roster_rule_summary: Dictionary = LeagueState.get_team_roster_rule_summary(str(team.id))
	var roster_warning_lines: Array[String] = roster_rule_summary.get("warnings", [])
	var calendar_summary: String = LeagueState.get_calendar_summary_text()
	var year_cycle_summary: Dictionary = LeagueState.get_year_cycle_summary()
	var operation_overview: Dictionary = LeagueState.get_current_operation_overview()
	var contract_now: bool = LeagueState.is_contract_period()
	var fa_now: bool = LeagueState.is_fa_period()
	var sponsor_now: bool = LeagueState.is_sponsor_period()
	var staff_now: bool = LeagueState.is_staff_review_period()
	var draft_now: bool = LeagueState.is_draft_prep_period() or LeagueState.is_draft_day()
	var upcoming_events: Array[Dictionary] = LeagueState.get_upcoming_calendar_events(3)

	summary_detail_label.text = "%s\n予算 %d / 人気 %d / 年俸総額 %d\n契約切れ間近 %d人 / FA注意 %d人\n支配下 %d / %d  一軍 %d / %d\n外国人 %d保有 / 一軍 %d / %d\n%s\n今日のイベント: %s" % [
		team.name,
		int(snapshot.get("budget", 0)),
		int(snapshot.get("fan_support", 0)),
		total_salary,
		expiring_count,
		fa_watch.size(),
		int(roster_rule_summary.get("registered", 0)),
		int(roster_rule_summary.get("registered_max", 70)),
		int(roster_rule_summary.get("active", 0)),
		int(roster_rule_summary.get("active_target", 29)),
		int(roster_rule_summary.get("foreign_signed", 0)),
		int(roster_rule_summary.get("foreign_active", 0)),
		int(roster_rule_summary.get("foreign_active_max", 4)),
		"警告なし" if roster_warning_lines.is_empty() else "警告: " + " / ".join(roster_warning_lines),
		calendar_summary
	]
	summary_detail_label.text += "\n運営進行: %d / %d 完了" % [
		int(operation_overview.get("completed_count", 0)),
		int(operation_overview.get("total_count", 0))
	]
	summary_detail_label.text += "\n年間フェーズ: %s" % str(year_cycle_summary.get("label", ""))

	contract_button.text = "契約・FA"
	team_management_button.text = "チーム管理"
	roster_management_button.text = "ロスター管理"
	sponsor_button.text = "スポンサー"
	staff_button.text = "スタッフ"
	scout_draft_button.text = "スカウト・ドラフト"
	trade_button.text = "トレード"
	facility_button.text = "施設"
	record_room_button.text = "記録室"

	var active_sections: Array[String] = []
	if contract_now:
		contract_button.text += " [更改期]"
		active_sections.append("契約更改")
	if fa_now:
		contract_button.text += " [FA期]"
		active_sections.append("FA交渉")
	if sponsor_now:
		sponsor_button.text += " [更改期]"
		active_sections.append("スポンサー営業")
	if staff_now:
		staff_button.text += " [見直し期]"
		active_sections.append("スタッフ整理")
	if draft_now:
		scout_draft_button.text += " [ドラフト期]"
		active_sections.append("スカウト・ドラフト")

	var next_lines: Array[String] = []
	for event_data in upcoming_events:
		next_lines.append("%s %s" % [str(event_data.get("date_label", "")), str(event_data.get("label", ""))])

	if active_sections.is_empty():
		status_label.text = "今は常設項目を中心に確認する時期です。"
	else:
		status_label.text = "今が使いどき: %s" % " / ".join(active_sections)
	var recommended_now: Array[String] = []
	for item in operation_overview.get("recommended_now", []):
		recommended_now.append(str(item))
	if not recommended_now.is_empty():
		status_label.text += "\n今やるなら: " + " / ".join(recommended_now)
	var phase_focus: Array[String] = []
	for item in year_cycle_summary.get("focus", []):
		phase_focus.append(str(item))
	if not phase_focus.is_empty():
		status_label.text += "\n今のテーマ: " + " / ".join(phase_focus)
	var pending_labels: Array[String] = []
	for item in operation_overview.get("pending_labels", []):
		pending_labels.append(str(item))
	if not pending_labels.is_empty():
		status_label.text += "\n今年の未完了: " + " / ".join(pending_labels)
	if not next_lines.is_empty():
		status_label.text += "\n次のイベント: " + " / ".join(next_lines)
