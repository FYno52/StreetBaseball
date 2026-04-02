extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryLabel
@onready var prospects_title_label: Label = $RootScroll/MarginContainer/RootVBox/ProspectsTitleLabel
@onready var prospects_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ProspectsDetailLabel
@onready var note_label: Label = $RootScroll/MarginContainer/RootVBox/NoteLabel

func _ready() -> void:
	title_label.text = "スカウト・ドラフト"
	back_button.text = "球団運営へ戻る"
	prospects_title_label.text = "注目候補"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	_refresh_view()

func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		summary_label.text = "-"
		prospects_detail_label.text = "-"
		note_label.text = ""
		return

	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	var facilities: Dictionary = snapshot.get("facilities", {})
	var staff: Dictionary = snapshot.get("staff", {})
	var scouting_level: int = int(facilities.get("scouting", 1))
	var scout_count: int = int(staff.get("scouts", 0))
	var in_prep_period: bool = LeagueState.is_draft_prep_period()
	var on_draft_day: bool = LeagueState.is_draft_day()

	info_label.text = "%s のスカウト状況とドラフト候補の下見を行います。" % team.name
	summary_label.text = "スカウト施設: Lv.%d\nスカウト人数: %d人\n今日の年間イベント\n%s" % [
		scouting_level,
		scout_count,
		LeagueState.get_calendar_summary_text()
	]

	var lines: Array[String] = []
	var role_names: Array[String] = ["高校生投手", "高校生内野手", "大学生投手", "社会人外野手", "高校生捕手"]
	var grades: Array[String] = ["C", "C+", "B", "B+", "A-"]
	for i in range(5):
		var upside: int = 55 + (i + 1) * 6 + scouting_level * 2 + scout_count
		lines.append("%d. %s / 評価 %s / 将来性 %d" % [i + 1, role_names[i], grades[i], upside])
	prospects_detail_label.text = "\n".join(lines)

	if on_draft_day:
		note_label.text = "今日はドラフト会議です。今後ここから指名処理へつなげます。"
	elif in_prep_period:
		note_label.text = "今はドラフト準備期間です。候補確認と注目選手の整理を進める時期です。"
	else:
		note_label.text = "今は候補の下見段階です。ドラフト準備期間やドラフト会議日に機能を広げる前提です。"
