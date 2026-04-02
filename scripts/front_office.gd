extends Control

const LEAGUE_HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const CONTRACT_OFFICE_SCENE_PATH := "res://scenes/ContractOffice.tscn"
const SPONSOR_OFFICE_SCENE_PATH := "res://scenes/SponsorOffice.tscn"
const FACILITY_OFFICE_SCENE_PATH := "res://scenes/FacilityOffice.tscn"
const STAFF_OFFICE_SCENE_PATH := "res://scenes/StaffOffice.tscn"
const SCOUT_DRAFT_OFFICE_SCENE_PATH := "res://scenes/ScoutDraftOffice.tscn"
const TRADE_OFFICE_SCENE_PATH := "res://scenes/TradeOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryTitleLabel
@onready var summary_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryDetailLabel
@onready var contract_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/ContractButton
@onready var facility_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/FacilityButton
@onready var sponsor_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/SponsorButton
@onready var staff_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/StaffButton
@onready var scout_draft_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/ScoutDraftButton
@onready var trade_button: Button = $RootScroll/MarginContainer/RootVBox/MenuButtonsGrid/TradeButton
@onready var roadmap_title_label: Label = $RootScroll/MarginContainer/RootVBox/RoadmapTitleLabel
@onready var roadmap_detail_label: Label = $RootScroll/MarginContainer/RootVBox/RoadmapDetailLabel
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel

func _ready() -> void:
	_setup_static_text()
	_connect_buttons()
	_refresh_view()

func _setup_static_text() -> void:
	title_label.text = "球団運営"
	back_button.text = "ホームへ戻る"
	info_label.text = "球団の経営状況をここから確認します。今はハブ画面として置いてあり、後で各項目をさらに独立したページへ広げていく前提です。"
	summary_title_label.text = "運営サマリー"
	contract_button.text = "契約・FA"
	facility_button.text = "施設"
	sponsor_button.text = "スポンサー"
	staff_button.text = "スタッフ"
	scout_draft_button.text = "スカウト・ドラフト"
	trade_button.text = "トレード"
	roadmap_title_label.text = "今後の運営項目"
	roadmap_detail_label.text = "・契約更改とFA交渉\n・トレードや移籍交渉\n・スカウトとドラフト候補の管理\n・スポンサー営業の強化\n・スタッフ最適化"

func _connect_buttons() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEAGUE_HOME_SCENE_PATH))
	contract_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(CONTRACT_OFFICE_SCENE_PATH))
	facility_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FACILITY_OFFICE_SCENE_PATH))
	sponsor_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SPONSOR_OFFICE_SCENE_PATH))
	staff_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(STAFF_OFFICE_SCENE_PATH))
	scout_draft_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SCOUT_DRAFT_OFFICE_SCENE_PATH))
	trade_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(TRADE_OFFICE_SCENE_PATH))

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
	var contract_now: bool = LeagueState.is_contract_period()
	var fa_now: bool = LeagueState.is_fa_period()
	var sponsor_now: bool = LeagueState.is_sponsor_period()
	var staff_now: bool = LeagueState.is_staff_review_period()
	var draft_now: bool = LeagueState.is_draft_prep_period() or LeagueState.is_draft_day()
	var upcoming_events: Array[Dictionary] = LeagueState.get_upcoming_calendar_events(3)

	summary_detail_label.text = "%s\n予算: %d\n人気: %d\n年俸総額: %d\n日次スポンサー収入: +%d\n日次スタッフ費: -%d\n契約切れ間近: %d人\nFA注意: %d人\n\nロスター規定\n支配下: %d / %d\n一軍相当: %d / %d\n外国人保有: %d\n一軍外国人: %d / %d (投手 %d / %d, 野手 %d / %d)\n%s\n\n今日の年間イベント\n%s" % [
		team.name,
		int(snapshot.get("budget", 0)),
		int(snapshot.get("fan_support", 0)),
		total_salary,
		int(snapshot.get("daily_sponsor_income", 0)),
		int(snapshot.get("daily_staff_cost", 0)),
		expiring_count,
		fa_watch.size(),
		int(roster_rule_summary.get("registered", 0)),
		int(roster_rule_summary.get("registered_max", 70)),
		int(roster_rule_summary.get("active", 0)),
		int(roster_rule_summary.get("active_target", 29)),
		int(roster_rule_summary.get("foreign_signed", 0)),
		int(roster_rule_summary.get("foreign_active", 0)),
		int(roster_rule_summary.get("foreign_active_max", 4)),
		int(roster_rule_summary.get("foreign_active_pitchers", 0)),
		int(roster_rule_summary.get("foreign_pitcher_active_max", 3)),
		int(roster_rule_summary.get("foreign_active_fielders", 0)),
		int(roster_rule_summary.get("foreign_fielder_active_max", 3)),
		"警告なし" if roster_warning_lines.is_empty() else "警告: " + " / ".join(roster_warning_lines),
		calendar_summary
	]

	contract_button.text = "契約・FA"
	sponsor_button.text = "スポンサー"
	staff_button.text = "スタッフ"
	scout_draft_button.text = "スカウト・ドラフト"
	trade_button.text = "トレード"
	facility_button.text = "施設"

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
	if not next_lines.is_empty():
		status_label.text += "\n次のイベント: " + " / ".join(next_lines)
