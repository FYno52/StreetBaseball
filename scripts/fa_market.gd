extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryTitleLabel
@onready var summary_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryDetailLabel
@onready var list_title_label: Label = $RootScroll/MarginContainer/RootVBox/ListTitleLabel
@onready var list_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ListDetailLabel
@onready var note_title_label: Label = $RootScroll/MarginContainer/RootVBox/NoteTitleLabel
@onready var note_detail_label: Label = $RootScroll/MarginContainer/RootVBox/NoteDetailLabel

func _ready() -> void:
	_setup_static_text()
	back_button.pressed.connect(_on_back_button_pressed)
	_refresh_view()

func _setup_static_text() -> void:
	title_label.text = "FA候補一覧"
	back_button.text = "球団運営へ戻る"
	summary_title_label.text = "市場サマリー"
	list_title_label.text = "候補選手"
	note_title_label.text = "メモ"
	note_detail_label.text = "現段階では閲覧のみです。\n後から交渉、FA宣言、獲得競合、移籍交渉へ広げる予定です。"

func _refresh_view() -> void:
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	if controlled_team == null:
		info_label.text = "担当球団が未設定です。"
		summary_detail_label.text = "-"
		list_detail_label.text = "-"
		return

	info_label.text = "%s から見た、契約切れ間近やFA志向が高い選手の一覧です。" % controlled_team.name
	var candidates: Array[Dictionary] = LeagueState.get_fa_candidate_list()
	var controlled_count: int = 0
	var other_count: int = 0
	for item in candidates:
		if bool(item.get("is_controlled_team", false)):
			controlled_count += 1
		else:
			other_count += 1
	summary_detail_label.text = "候補総数: %d\n自球団候補: %d\n他球団候補: %d" % [
		candidates.size(),
		controlled_count,
		other_count
	]

	if candidates.is_empty():
		list_detail_label.text = "現在、目立ったFA候補はいません。"
		return

	var lines: Array[String] = []
	for i in range(mini(12, candidates.size())):
		var item: Dictionary = candidates[i]
		var tag: String = "自球団" if bool(item.get("is_controlled_team", false)) else "他球団"
		lines.append("%d. [%s] %s / %s / %s / 総合%d / %d歳 / 残り%d年 / 希望年俸%d / FA志向%d" % [
			i + 1,
			tag,
			str(item.get("player_name", "")),
			str(item.get("team_name", "")),
			_get_role_label(str(item.get("role", "")), str(item.get("position", ""))),
			int(item.get("overall", 0)),
			int(item.get("age", 0)),
			int(item.get("contract_years_left", 0)),
			int(item.get("desired_salary", 0)),
			int(item.get("fa_interest", 0))
		])
	list_detail_label.text = "\n".join(lines)

func _get_role_label(role: String, position: String) -> String:
	match role:
		"starter":
			return "先発"
		"reliever":
			return "救援"
		"closer":
			return "抑え"
		_:
			return position

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH)
