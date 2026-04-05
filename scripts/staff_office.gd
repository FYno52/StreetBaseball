extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var detail_label: Label = $RootScroll/MarginContainer/RootVBox/DetailLabel
@onready var coach_plus_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsGrid/CoachPlusButton
@onready var coach_minus_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsGrid/CoachMinusButton
@onready var scout_plus_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsGrid/ScoutPlusButton
@onready var scout_minus_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsGrid/ScoutMinusButton
@onready var trainer_plus_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsGrid/TrainerPlusButton
@onready var trainer_minus_button: Button = $RootScroll/MarginContainer/RootVBox/ButtonsGrid/TrainerMinusButton
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "front_office",
		"section_label": "STAFF",
		"sub_tab": "staff",
		"sub_tabs": [
			{"key": "hub", "label": "FRONT OFFICE", "scene": FRONT_OFFICE_SCENE_PATH},
			{"key": "staff", "label": "STAFF", "scene": "res://scenes/StaffOffice.tscn"},
			{"key": "facilities", "label": "FACILITIES", "scene": "res://scenes/FacilityOffice.tscn"}
		],
		"top_right": "STAFF"
	})
	title_label.visible = false
	back_button.text = "球団運営へ戻る"
	info_label.text = "スタッフ人数を調整します。必要な職種だけ増減させます。"
	coach_plus_button.text = "コーチ +1"
	coach_minus_button.text = "コーチ -1"
	scout_plus_button.text = "スカウト +1"
	scout_minus_button.text = "スカウト -1"
	trainer_plus_button.text = "トレーナー +1"
	trainer_minus_button.text = "トレーナー -1"

	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	coach_plus_button.pressed.connect(func() -> void: _change_staff("coaches", 1))
	coach_minus_button.pressed.connect(func() -> void: _change_staff("coaches", -1))
	scout_plus_button.pressed.connect(func() -> void: _change_staff("scouts", 1))
	scout_minus_button.pressed.connect(func() -> void: _change_staff("scouts", -1))
	trainer_plus_button.pressed.connect(func() -> void: _change_staff("trainers", 1))
	trainer_minus_button.pressed.connect(func() -> void: _change_staff("trainers", -1))

	_refresh_view()


func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		detail_label.text = "-"
		return

	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	var staff: Dictionary = snapshot.get("staff", {})
	info_label.text = "%s のスタッフ人数です。" % team.name
	detail_label.text = "コーチ %d人 / スカウト %d人 / トレーナー %d人" % [
		int(staff.get("coaches", 0)),
		int(staff.get("scouts", 0)),
		int(staff.get("trainers", 0))
	]


func _change_staff(staff_key: String, delta: int) -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return
	var result: Dictionary = LeagueState.change_team_staff(str(team.id), staff_key, delta)
	status_label.text = str(result.get("message", ""))
	_refresh_view()
