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
		info_label.text = "担当球団が未設定です。"
		summary_label.text = "-"
		prospects_detail_label.text = "-"
		note_label.text = ""
		return
	var snapshot: Dictionary = LeagueState.get_team_management_snapshot(str(team.id))
	var facilities: Dictionary = snapshot.get("facilities", {})
	var staff: Dictionary = snapshot.get("staff", {})
	info_label.text = "%s の将来戦力を整えるページです。まずは候補確認の受け皿として使います。" % team.name
	summary_label.text = "スカウト施設: Lv.%d\nスカウト人数: %d人\nこの数値が高いほど、補充新人や将来候補の質が少し上がります。" % [
		int(facilities.get("scouting", 1)),
		int(staff.get("scouts", 0))
	]
	var lines: Array[String] = []
	for i in range(1, 6):
		var grade: String = ["C", "C", "B", "B", "A"][i - 1]
		var role: String = ["遊撃手", "先発", "外野手", "救援", "捕手"][i - 1]
		var upside: int = 55 + i * 6 + int(facilities.get("scouting", 1)) * 2 + int(staff.get("scouts", 0))
		lines.append("%d. 注目候補 / %s / 期待値 %s / 将来性 %d" % [i, role, grade, upside])
	prospects_detail_label.text = "\n".join(lines)
	note_label.text = "今は候補の見え方だけを用意しています。後からスカウト割り振り、ドラフト指名、候補の入れ替わりに広げます。"