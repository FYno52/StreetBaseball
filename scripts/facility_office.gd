extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var detail_label: Label = $RootScroll/MarginContainer/RootVBox/DetailLabel
@onready var training_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsHBox/TrainingButton
@onready var medical_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsHBox/MedicalButton
@onready var scouting_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsHBox/ScoutingButton
@onready var marketing_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsHBox/MarketingButton
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "front_office",
		"section_label": "FACILITIES",
		"sub_tab": "facilities",
		"sub_tabs": [
			{"key": "hub", "label": "FRONT OFFICE", "scene": FRONT_OFFICE_SCENE_PATH},
			{"key": "facilities", "label": "FACILITIES", "scene": "res://scenes/FacilityOffice.tscn"},
			{"key": "staff", "label": "STAFF", "scene": "res://scenes/StaffOffice.tscn"}
		],
		"top_right": "FACILITIES"
	})
	title_label.visible = false
	back_button.text = "球団運営へ戻る"
	info_label.text = "施設投資の状況を確認し、必要な項目だけ強化します。"

	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	training_button.pressed.connect(func() -> void: _upgrade("training"))
	medical_button.pressed.connect(func() -> void: _upgrade("medical"))
	scouting_button.pressed.connect(func() -> void: _upgrade("scouting"))
	marketing_button.pressed.connect(func() -> void: _upgrade("marketing"))

	_refresh_view()


func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		detail_label.text = "-"
		return

	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	var facilities: Dictionary = snapshot.get("facilities", {})
	info_label.text = "%s の施設状況を確認します。" % team.name
	detail_label.text = "練習 Lv.%d / 医療 Lv.%d / スカウト Lv.%d / 営業 Lv.%d" % [
		int(facilities.get("training", 1)),
		int(facilities.get("medical", 1)),
		int(facilities.get("scouting", 1)),
		int(facilities.get("marketing", 1))
	]

	var id: String = str(team.id)
	training_button.text = "練習を強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "training")
	medical_button.text = "医療を強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "medical")
	scouting_button.text = "スカウトを強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "scouting")
	marketing_button.text = "営業を強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "marketing")


func _upgrade(key: String) -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return
	var result: Dictionary = LeagueState.upgrade_team_facility(str(team.id), key)
	status_label.text = str(result.get("message", ""))
	_refresh_view()
