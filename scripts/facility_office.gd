extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

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
	title_label.text = "施設"
	back_button.text = "球団運営へ戻る"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	training_button.pressed.connect(func() -> void: _upgrade("training"))
	medical_button.pressed.connect(func() -> void: _upgrade("medical"))
	scouting_button.pressed.connect(func() -> void: _upgrade("scouting"))
	marketing_button.pressed.connect(func() -> void: _upgrade("marketing"))
	_refresh_view()

func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が未設定です。"
		detail_label.text = "-"
		return
	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	var facilities: Dictionary = snapshot.get("facilities", {})
	info_label.text = "%s の施設を強化します。" % team.name
	detail_label.text = "練習施設: Lv.%d\n医療施設: Lv.%d\nスカウト施設: Lv.%d\n営業施設: Lv.%d" % [
		int(facilities.get("training", 1)),
		int(facilities.get("medical", 1)),
		int(facilities.get("scouting", 1)),
		int(facilities.get("marketing", 1))
	]
	var id: String = str(team.id)
	training_button.text = "練習施設強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "training")
	medical_button.text = "医療施設強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "medical")
	scouting_button.text = "スカウト施設強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "scouting")
	marketing_button.text = "営業施設強化 (%d)" % LeagueState.get_facility_upgrade_cost(id, "marketing")

func _upgrade(key: String) -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return
	var result: Dictionary = LeagueState.upgrade_team_facility(str(team.id), key)
	status_label.text = str(result.get("message", ""))
	_refresh_view()