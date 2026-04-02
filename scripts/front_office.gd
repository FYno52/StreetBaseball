extends Control

const LEAGUE_HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const CONTRACT_OFFICE_SCENE_PATH := "res://scenes/ContractOffice.tscn"
const SPONSOR_OFFICE_SCENE_PATH := "res://scenes/SponsorOffice.tscn"
const FACILITY_OFFICE_SCENE_PATH := "res://scenes/FacilityOffice.tscn"
const STAFF_OFFICE_SCENE_PATH := "res://scenes/StaffOffice.tscn"
const SCOUT_DRAFT_OFFICE_SCENE_PATH := "res://scenes/ScoutDraftOffice.tscn"

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
	info_label.text = "経営関連の機能をここから選びます。後から各ページをさらに細かく分割できる前提で進めます。"
	summary_title_label.text = "運営サマリー"
	contract_button.text = "契約・FA"
	facility_button.text = "施設"
	sponsor_button.text = "スポンサー"
	staff_button.text = "スタッフ"
	scout_draft_button.text = "スカウト・ドラフト"
	roadmap_title_label.text = "今後の経営要素"
	roadmap_detail_label.text = "・FA交渉 / 移籍交渉 / トレード\n・スカウト / ドラフト候補の強化\n・スポンサー契約拡張\n・スタッフ最適化\n・経営判断イベント"

func _connect_buttons() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(LEAGUE_HOME_SCENE_PATH))
	contract_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(CONTRACT_OFFICE_SCENE_PATH))
	facility_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FACILITY_OFFICE_SCENE_PATH))
	sponsor_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SPONSOR_OFFICE_SCENE_PATH))
	staff_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(STAFF_OFFICE_SCENE_PATH))
	scout_draft_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(SCOUT_DRAFT_OFFICE_SCENE_PATH))

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
	summary_detail_label.text = "%s\n予算: %d\n人気: %d\n年俸総額: %d\n日次スポンサー収入: +%d\n日次スタッフ費: -%d\n契約切れ間近: %d人\nFA注意: %d人" % [
		team.name,
		int(snapshot.get("budget", 0)),
		int(snapshot.get("fan_support", 0)),
		int(snapshot.get("total_salary", 0)),
		int(snapshot.get("daily_sponsor_income", 0)),
		int(snapshot.get("daily_staff_cost", 0)),
		expiring_count,
		fa_watch.size()
	]
	status_label.text = "各項目を選ぶと専用ページへ移動します。"