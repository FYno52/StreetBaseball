extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var overview_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/OverviewTabButton
@onready var prospects_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/ProspectsTabButton
@onready var draft_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/DraftTabButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel

@onready var overview_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/OverviewVBox
@onready var summary_title_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryTitleLabel
@onready var summary_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryLabel
@onready var note_title_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/NoteTitleLabel
@onready var note_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/NoteLabel

@onready var prospects_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/ProspectsVBox
@onready var prospects_title_label: Label = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectsTitleLabel
@onready var prospects_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectsDetailLabel
@onready var prospect_button_1: Button = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectButtonsVBox/Prospect1Button
@onready var prospect_button_2: Button = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectButtonsVBox/Prospect2Button
@onready var prospect_button_3: Button = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectButtonsVBox/Prospect3Button
@onready var prospect_button_4: Button = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectButtonsVBox/Prospect4Button
@onready var prospect_button_5: Button = $RootScroll/MarginContainer/RootVBox/ProspectsVBox/ProspectButtonsVBox/Prospect5Button

@onready var draft_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/DraftVBox
@onready var draft_title_label: Label = $RootScroll/MarginContainer/RootVBox/DraftVBox/DraftTitleLabel
@onready var draft_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DraftVBox/DraftDetailLabel
@onready var draft_button: Button = $RootScroll/MarginContainer/RootVBox/DraftVBox/DraftButton
@onready var draft_note_label: Label = $RootScroll/MarginContainer/RootVBox/DraftVBox/DraftNoteLabel

var _current_tab: String = "overview"
var _prospect_button_ids: Array[String] = ["", "", "", "", ""]


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "scouting",
		"section_label": "SCOUTING",
		"sub_tab": "draft",
		"sub_tabs": [
			{"key": "draft", "label": "DRAFT", "scene": "res://scenes/ScoutDraftOffice.tscn"},
			{"key": "contracts", "label": "CONTRACTS", "scene": "res://scenes/ContractOffice.tscn"},
			{"key": "front", "label": "FRONT OFFICE", "scene": FRONT_OFFICE_SCENE_PATH}
		],
		"top_right": "SCOUTING"
	})
	_setup_static_text()
	_connect_signals()
	_refresh_view()


func _setup_static_text() -> void:
	title_label.visible = false
	back_button.text = "球団運営へ戻る"
	overview_tab_button.text = "概況"
	prospects_tab_button.text = "候補"
	draft_tab_button.text = "指名"
	info_label.text = "スカウト状況とドラフト準備を確認します。上のタブで候補整理と当日指名を切り替えられます。"
	summary_title_label.text = "スカウト状況"
	note_title_label.text = "今の時期"
	prospects_title_label.text = "注目候補"
	prospect_button_1.text = "注目切替"
	prospect_button_2.text = "注目切替"
	prospect_button_3.text = "注目切替"
	prospect_button_4.text = "注目切替"
	prospect_button_5.text = "注目切替"
	draft_title_label.text = "ドラフト会議"
	draft_button.text = "このまま指名する"


func _connect_signals() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	overview_tab_button.pressed.connect(func() -> void: _on_tab_pressed("overview"))
	prospects_tab_button.pressed.connect(func() -> void: _on_tab_pressed("prospects"))
	draft_tab_button.pressed.connect(func() -> void: _on_tab_pressed("draft"))
	prospect_button_1.pressed.connect(func() -> void: _toggle_focus_slot(0))
	prospect_button_2.pressed.connect(func() -> void: _toggle_focus_slot(1))
	prospect_button_3.pressed.connect(func() -> void: _toggle_focus_slot(2))
	prospect_button_4.pressed.connect(func() -> void: _toggle_focus_slot(3))
	prospect_button_5.pressed.connect(func() -> void: _toggle_focus_slot(4))
	draft_button.pressed.connect(_on_draft_button_pressed)


func _on_tab_pressed(tab_key: String) -> void:
	_current_tab = tab_key
	_refresh_tab_visibility()


func _refresh_tab_visibility() -> void:
	overview_tab_button.disabled = _current_tab == "overview"
	prospects_tab_button.disabled = _current_tab == "prospects"
	draft_tab_button.disabled = _current_tab == "draft"

	overview_vbox.visible = _current_tab == "overview"
	prospects_vbox.visible = _current_tab == "prospects"
	draft_vbox.visible = _current_tab == "draft"


func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		summary_label.text = "-"
		note_label.text = ""
		prospects_detail_label.text = "-"
		draft_detail_label.text = "-"
		draft_note_label.text = ""
		_refresh_tab_visibility()
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
	var prospects: Array[Dictionary] = _get_prospects_for_view(team)
	var focused_count: int = team.draft_focus_ids.size()

	summary_label.text = "スカウト施設 Lv.%d\nスカウト人数 %d人\n候補数 %d人 / 注目 %d人\n今日のイベント: %s" % [
		scouting_level,
		scout_count,
		prospects.size(),
		focused_count,
		LeagueState.get_calendar_summary_text()
	]
	note_label.text = _build_period_note(in_prep_period, on_draft_day, drafted_already)

	_refresh_prospect_section(prospects, can_focus)
	_refresh_draft_section(team, prospects, on_draft_day, drafted_already)
	_refresh_tab_visibility()


func _refresh_prospect_section(prospects: Array[Dictionary], can_focus: bool) -> void:
	var lines: Array[String] = []
	_prospect_button_ids = ["", "", "", "", ""]
	for i in range(mini(5, prospects.size())):
		var prospect: Dictionary = prospects[i]
		var focus_tag: String = " [注目]" if bool(prospect.get("focused", false)) else ""
		lines.append("%d. %s / %s / 評価 %s%s\n   %s" % [
			i + 1,
			str(prospect.get("name", "")),
			str(prospect.get("role", "")),
			str(prospect.get("grade", "")),
			focus_tag,
			str(prospect.get("note", ""))
		])
		_prospect_button_ids[i] = str(prospect.get("prospect_id", ""))
	if lines.is_empty():
		lines.append("候補データはまだありません。")
	prospects_detail_label.text = "\n".join(lines)

	var buttons: Array[Button] = [prospect_button_1, prospect_button_2, prospect_button_3, prospect_button_4, prospect_button_5]
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		if i < prospects.size():
			button.visible = true
			button.disabled = not can_focus
			var is_focused: bool = bool(prospects[i].get("focused", false))
			button.text = "注目%s: %s" % [
				"解除" if is_focused else "登録",
				str(prospects[i].get("name", "候補"))
			]
		else:
			button.visible = false
			button.disabled = true


func _refresh_draft_section(team: TeamData, prospects: Array[Dictionary], on_draft_day: bool, drafted_already: bool) -> void:
	var lines: Array[String] = []
	lines.append("開催日: %s" % _get_draft_day_label())
	if drafted_already:
		lines.append("今年のドラフト指名は完了しています。")
	elif on_draft_day:
		lines.append("今日はドラフト会議当日です。")
	else:
		lines.append("今日はドラフト会議日ではありません。")

	if not team.last_draft_result_names.is_empty():
		lines.append("")
		lines.append("直近の指名:")
		for name in team.last_draft_result_names:
			lines.append("- %s" % str(name))

	if on_draft_day and not prospects.is_empty():
		var preview: Dictionary = _pick_draft_choice_preview(prospects)
		lines.append("")
		lines.append("今回の指名候補: %s / %s / 評価 %s" % [
			str(preview.get("name", "")),
			str(preview.get("role", "")),
			str(preview.get("grade", ""))
		])

	draft_detail_label.text = "\n".join(lines)
	draft_button.disabled = not on_draft_day or drafted_already

	if drafted_already:
		draft_note_label.text = "同じ年に複数回の指名はできません。"
	elif on_draft_day:
		draft_note_label.text = "注目候補がいれば優先し、いなければ評価上位を指名します。"
	else:
		draft_note_label.text = "今は下見の時期です。候補を確認して注目登録しておきましょう。"


func _build_period_note(in_prep_period: bool, on_draft_day: bool, drafted_already: bool) -> String:
	if on_draft_day:
		if drafted_already:
			return "今年のドラフト会議は完了しています。結果確認だけできます。"
		return "今日はドラフト会議当日です。候補確認のあと、指名へ進めます。"
	if in_prep_period:
		return "ドラフト準備期間です。注目候補は最大5人まで登録できます。"
	return "今は下見の時期です。スカウト施設とスカウト人数が候補評価に影響します。"


func _toggle_focus_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _prospect_button_ids.size():
		return
	var prospect_id: String = _prospect_button_ids[slot_index]
	if prospect_id == "":
		return
	var result: Dictionary
	if LeagueState.has_method("toggle_controlled_draft_focus"):
		result = LeagueState.toggle_controlled_draft_focus(prospect_id)
	else:
		result = {"ok": false, "message": "注目候補の操作はまだ使えません。"}
	note_label.text = str(result.get("message", ""))
	_refresh_view()
	_current_tab = "prospects"
	_refresh_tab_visibility()


func _get_prospects_for_view(team: TeamData) -> Array[Dictionary]:
	if LeagueState.has_method("get_controlled_team_draft_prospects"):
		return LeagueState.get_controlled_team_draft_prospects()
	return _build_local_fallback_prospects(team)


func _build_local_fallback_prospects(team: TeamData) -> Array[Dictionary]:
	var scouting_level: int = int(team.facilities.get("scouting", 1))
	var scout_count: int = int(team.staff.get("scouts", 0))
	var quality_bonus: int = scouting_level * 3 + scout_count * 2
	var grade_labels: Array[String] = ["C", "C+", "B", "B+", "A-", "A"]
	var family_names: Array[String] = ["佐藤", "鈴木", "高橋", "田中", "伊藤", "渡辺", "山本", "中村"]
	var given_names: Array[String] = ["一樹", "健太", "隼人", "悠斗", "大雅", "直樹", "優真", "蓮"]
	var role_pool: Array[String] = ["高校生投手", "大学生投手", "社会人投手", "高校生内野手", "大学生外野手", "社会人捕手", "高校生外野手", "大学生内野手"]
	var style_pool: Array[String] = ["速球派", "変化球型", "守備型", "長打型", "巧打型", "万能型", "強肩型", "粘り強い"]
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


func _pick_draft_choice_preview(prospects: Array[Dictionary]) -> Dictionary:
	for prospect in prospects:
		if bool(prospect.get("focused", false)):
			return prospect
	if prospects.is_empty():
		return {}
	return prospects[0]


func _get_draft_day_label() -> String:
	var draft_day: int = 0
	for day in range(1, LeagueState.get_last_day() + 1):
		var events: Array[Dictionary] = LeagueState.get_calendar_events_for_day(day)
		for event_data in events:
			if str(event_data.get("type", "")) == "draft_day":
				draft_day = day
				break
		if draft_day > 0:
			break
	if draft_day <= 0:
		return "未設定"
	var info: Dictionary = LeagueState.get_date_info_for_day(draft_day)
	return "%d/%d(%s)" % [int(info.get("month", 1)), int(info.get("day", 1)), str(info.get("weekday", ""))]


func _on_draft_button_pressed() -> void:
	if not LeagueState.has_method("run_controlled_team_draft"):
		draft_note_label.text = "ドラフト指名機能はまだ利用できません。"
		return
	var result: Dictionary = LeagueState.run_controlled_team_draft()
	draft_note_label.text = str(result.get("message", ""))
	_refresh_view()
	_current_tab = "draft"
	_refresh_tab_visibility()
