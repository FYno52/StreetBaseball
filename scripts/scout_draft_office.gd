extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryLabel
@onready var prospects_title_label: Label = $RootScroll/MarginContainer/RootVBox/ProspectsTitleLabel
@onready var prospects_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ProspectsDetailLabel
@onready var prospect_button_1: Button = $RootScroll/MarginContainer/RootVBox/ProspectButtonsVBox/Prospect1Button
@onready var prospect_button_2: Button = $RootScroll/MarginContainer/RootVBox/ProspectButtonsVBox/Prospect2Button
@onready var prospect_button_3: Button = $RootScroll/MarginContainer/RootVBox/ProspectButtonsVBox/Prospect3Button
@onready var prospect_button_4: Button = $RootScroll/MarginContainer/RootVBox/ProspectButtonsVBox/Prospect4Button
@onready var prospect_button_5: Button = $RootScroll/MarginContainer/RootVBox/ProspectButtonsVBox/Prospect5Button
@onready var draft_button: Button = $RootScroll/MarginContainer/RootVBox/DraftButton
@onready var note_label: Label = $RootScroll/MarginContainer/RootVBox/NoteLabel

var _prospect_button_ids: Array[String] = ["", "", "", "", ""]

func _ready() -> void:
	title_label.text = "スカウト・ドラフト"
	back_button.text = "球団運営へ戻る"
	prospects_title_label.text = "注目候補"
	prospect_button_1.text = "候補1"
	prospect_button_2.text = "候補2"
	prospect_button_3.text = "候補3"
	prospect_button_4.text = "候補4"
	prospect_button_5.text = "候補5"
	draft_button.text = "このまま指名する"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	prospect_button_1.pressed.connect(func() -> void: _toggle_focus_slot(0))
	prospect_button_2.pressed.connect(func() -> void: _toggle_focus_slot(1))
	prospect_button_3.pressed.connect(func() -> void: _toggle_focus_slot(2))
	prospect_button_4.pressed.connect(func() -> void: _toggle_focus_slot(3))
	prospect_button_5.pressed.connect(func() -> void: _toggle_focus_slot(4))
	draft_button.pressed.connect(_on_draft_button_pressed)
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
	var can_focus: bool = in_prep_period or on_draft_day
	var drafted_already: bool = int(team.last_draft_year) == int(LeagueState.season_year)

	info_label.text = "%s のスカウト状況とドラフト候補の下見を行います。" % team.name
	summary_label.text = "スカウト施設: Lv.%d\nスカウト人数: %d人\n今日の年間イベント\n%s" % [
		scouting_level,
		scout_count,
		LeagueState.get_calendar_summary_text()
	]

	var prospects: Array[Dictionary] = _get_prospects_for_view(team, scouting_level, scout_count)
	var lines: Array[String] = []
	_prospect_button_ids = ["", "", "", "", ""]
	for i in range(mini(5, prospects.size())):
		var prospect: Dictionary = prospects[i]
		var focus_tag: String = " [注目]" if bool(prospect.get("focused", false)) else ""
		lines.append("%d. %s / %s / 評価 %s / 将来性 %d%s" % [
			i + 1,
			str(prospect.get("name", "")),
			str(prospect.get("role", "")),
			str(prospect.get("grade", "")),
			int(prospect.get("upside", 0)),
			focus_tag
		])
		lines.append("  %s / %s" % [str(prospect.get("style", "")), str(prospect.get("note", ""))])
		_prospect_button_ids[i] = str(prospect.get("prospect_id", ""))
	prospects_detail_label.text = "\n".join(lines)

	var buttons: Array[Button] = [prospect_button_1, prospect_button_2, prospect_button_3, prospect_button_4, prospect_button_5]
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		if i < prospects.size():
			button.visible = true
			button.disabled = not can_focus
			button.text = "注目切替: %s" % str(prospects[i].get("name", "候補"))
		else:
			button.visible = false
			button.disabled = true

	draft_button.visible = true
	draft_button.disabled = not on_draft_day or drafted_already

	if on_draft_day:
		if drafted_already:
			note_label.text = "今年の指名: %s" % ", ".join(team.last_draft_result_names) if not team.last_draft_result_names.is_empty() else "今年のドラフト指名は完了済みです。"
		else:
			note_label.text = "今日はドラフト会議です。注目候補がいれば優先して指名します。"
	elif in_prep_period:
		note_label.text = "今はドラフト準備期間です。候補確認と注目選手の整理を進める時期です。注目候補は5人まで設定できます。"
	else:
		note_label.text = "今は候補の下見段階です。ドラフト準備期間やドラフト会議日に機能を広げる前提です。"

func _toggle_focus_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _prospect_button_ids.size():
		return
	var prospect_id: String = _prospect_button_ids[slot_index]
	if prospect_id == "":
		return
	if LeagueState.has_method("toggle_controlled_draft_focus"):
		var result: Dictionary = LeagueState.toggle_controlled_draft_focus(prospect_id)
		note_label.text = str(result.get("message", ""))
	else:
		var team: TeamData = LeagueState.get_controlled_team()
		if team == null:
			note_label.text = "担当球団が設定されていません。"
			return
		if team.draft_focus_ids.has(prospect_id):
			team.draft_focus_ids.erase(prospect_id)
			note_label.text = "注目候補から外しました。"
		elif team.draft_focus_ids.size() >= 5:
			note_label.text = "注目候補は5人までです。"
		else:
			team.draft_focus_ids.append(prospect_id)
			note_label.text = "注目候補に追加しました。"
	_refresh_view()

func _get_prospects_for_view(team: TeamData, scouting_level: int, scout_count: int) -> Array[Dictionary]:
	if LeagueState.has_method("get_controlled_team_draft_prospects"):
		return LeagueState.get_controlled_team_draft_prospects()

	var grade_labels: Array[String] = ["C", "C+", "B", "B+", "A-", "A"]
	var family_names: Array[String] = ["佐藤", "鈴木", "高橋", "田中", "伊藤", "渡辺", "山本", "中村"]
	var given_names: Array[String] = ["一樹", "健太", "隼人", "悠斗", "大雅", "直樹", "優真", "蓮"]
	var role_pool: Array[String] = ["高校生投手", "大学生投手", "社会人投手", "高校生内野手", "大学生外野手", "社会人捕手", "高校生外野手", "大学生内野手"]
	var style_pool: Array[String] = ["速球派", "変化球型", "守備型", "長打型", "巧打型", "万能型", "強肩型", "粘り強い"]
	var quality_bonus: int = scouting_level * 3 + scout_count * 2
	var prospects: Array[Dictionary] = []

	for i in range(8):
		var prospect_id: String = "%d_draft_%02d" % [LeagueState.season_year, i + 1]
		var upside: int = 54 + i * 4 + quality_bonus
		var grade_index: int = mini(grade_labels.size() - 1, int(floor(float(upside - 50) / 8.0)))
		prospects.append({
			"prospect_id": prospect_id,
			"name": "%s %s" % [family_names[i % family_names.size()], given_names[i % given_names.size()]],
			"role": role_pool[i % role_pool.size()],
			"grade": grade_labels[grade_index],
			"upside": upside,
			"style": style_pool[(i + scouting_level + scout_count) % style_pool.size()],
			"note": "将来性 %d / スカウト評価 %s" % [upside, grade_labels[grade_index]],
			"focused": team.draft_focus_ids.has(prospect_id)
		})
	return prospects

func _on_draft_button_pressed() -> void:
	if not LeagueState.has_method("run_controlled_team_draft"):
		note_label.text = "ドラフト指名処理をまだ利用できません。"
		return
	var result: Dictionary = LeagueState.run_controlled_team_draft()
	note_label.text = str(result.get("message", ""))
	_refresh_view()
