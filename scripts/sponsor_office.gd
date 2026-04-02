extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var detail_label: Label = $RootScroll/MarginContainer/RootVBox/DetailLabel
@onready var sponsor_button: Button = $RootScroll/MarginContainer/RootVBox/SponsorButton
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel

func _ready() -> void:
	title_label.text = "スポンサー"
	back_button.text = "球団運営へ戻る"
	sponsor_button.text = "営業する"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	sponsor_button.pressed.connect(_on_sponsor_button_pressed)
	_refresh_view()

func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が未設定です。"
		detail_label.text = "-"
		return
	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	info_label.text = "%s のスポンサー状況を確認し、営業します。" % team.name
	detail_label.text = "現在契約: %s\n契約ランク: %d\n日次スポンサー収入: +%d\n営業施設が高いほど営業に有利です。" % [
		str(snapshot.get("sponsor_name", "未契約")),
		int(snapshot.get("sponsor_tier", 1)),
		int(snapshot.get("daily_sponsor_income", 0))
	]

func _on_sponsor_button_pressed() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return
	var result: Dictionary = LeagueState.pitch_team_sponsor(str(team.id))
	status_label.text = str(result.get("message", ""))
	_refresh_view()