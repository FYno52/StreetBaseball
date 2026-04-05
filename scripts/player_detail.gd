extends Control

const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var overview_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/OverviewTabButton
@onready var ratings_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/RatingsTabButton
@onready var defense_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/DefenseTabButton
@onready var traits_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/TraitsTabButton
@onready var development_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/DevelopmentTabButton
@onready var stats_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/StatsTabButton
@onready var history_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/HistoryTabButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var section_title_label: Label = $RootScroll/MarginContainer/RootVBox/SectionTitleLabel
@onready var section_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SectionDetailLabel

var current_tab: String = "overview"


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "organization",
		"section_label": "PLAYER PROFILE",
		"sub_tab": "players",
		"sub_tabs": [
			{"key": "lineups", "label": "LINEUPS", "scene": "res://scenes/TeamManagement.tscn"},
			{"key": "roster", "label": "ROSTER", "scene": "res://scenes/RosterManagement.tscn"},
			{"key": "players", "label": "PLAYERS", "scene": ROSTER_VIEW_SCENE_PATH}
		],
		"top_right": "PLAYER PROFILE"
	})
	title_label.visible = false
	back_button.text = "選手一覧へ戻る"
	overview_tab_button.text = "基本"
	ratings_tab_button.text = "能力"
	defense_tab_button.text = "守備"
	traits_tab_button.text = "特殊能力"
	development_tab_button.text = "育成"
	stats_tab_button.text = "成績"
	history_tab_button.text = "履歴"

	back_button.pressed.connect(_on_back_button_pressed)
	overview_tab_button.pressed.connect(func() -> void: _on_tab_pressed("overview"))
	ratings_tab_button.pressed.connect(func() -> void: _on_tab_pressed("ratings"))
	defense_tab_button.pressed.connect(func() -> void: _on_tab_pressed("defense"))
	traits_tab_button.pressed.connect(func() -> void: _on_tab_pressed("traits"))
	development_tab_button.pressed.connect(func() -> void: _on_tab_pressed("development"))
	stats_tab_button.pressed.connect(func() -> void: _on_tab_pressed("stats"))
	history_tab_button.pressed.connect(func() -> void: _on_tab_pressed("history"))

	_refresh_view()


func _refresh_view() -> void:
	var player: PlayerData = LeagueState.get_selected_player()
	if player == null:
		info_label.text = "選手が選ばれていません。"
		section_title_label.text = "選手詳細"
		section_detail_label.text = "選手一覧から確認したい選手を選んでください。"
		_refresh_tab_buttons()
		return

	var team: TeamData = _find_player_team(str(player.id))
	var team_name := team.name if team != null else "所属チーム不明"
	info_label.text = "%s / %s / %s / OVR %d / POT %d" % [player.full_name, team_name, player.primary_position, player.overall, player.potential]

	match current_tab:
		"ratings":
			section_title_label.text = "能力"
			section_detail_label.text = _build_ratings_text(player)
		"defense":
			section_title_label.text = "守備・ポジション"
			section_detail_label.text = _build_defense_text(player)
		"traits":
			section_title_label.text = "特殊能力"
			section_detail_label.text = _build_traits_text(player)
		"development":
			section_title_label.text = "育成・状態"
			section_detail_label.text = _build_development_text(player)
		"stats":
			section_title_label.text = "今季成績"
			section_detail_label.text = _build_stats_text(player)
		"history":
			section_title_label.text = "履歴"
			section_detail_label.text = _build_history_text(player)
		_:
			section_title_label.text = "基本情報"
			section_detail_label.text = _build_overview_text(player, team)

	_refresh_tab_buttons()


func _on_tab_pressed(tab_key: String) -> void:
	current_tab = tab_key
	_refresh_view()


func _refresh_tab_buttons() -> void:
	for button in [overview_tab_button, ratings_tab_button, defense_tab_button, traits_tab_button, development_tab_button, stats_tab_button, history_tab_button]:
		button.toggle_mode = true
	overview_tab_button.button_pressed = current_tab == "overview"
	ratings_tab_button.button_pressed = current_tab == "ratings"
	defense_tab_button.button_pressed = current_tab == "defense"
	traits_tab_button.button_pressed = current_tab == "traits"
	development_tab_button.button_pressed = current_tab == "development"
	stats_tab_button.button_pressed = current_tab == "stats"
	history_tab_button.button_pressed = current_tab == "history"


func _build_overview_text(player: PlayerData, team: TeamData) -> String:
	var lines: Array[String] = []
	for line in player.get_overview_lines():
		lines.append(str(line))
	lines.append("所属チーム: %s" % (team.name if team != null else "所属チーム不明"))
	lines.append("起用状況: %s" % _get_player_assignment_label(player, team))
	lines.append("二次守備: %s" % _get_secondary_positions_text(player))
	return "\n".join(lines)


func _build_ratings_text(player: PlayerData) -> String:
	var lines: Array[String] = []
	for item in player.get_key_ratings_for_display():
		lines.append("%s: %d" % [str(item.get("label", "")), int(item.get("value", 0))])
	if player.is_pitcher():
		lines.append("")
		lines.append("球種")
		lines.append(_build_pitch_types_text(player))
	return "\n".join(lines)


func _build_defense_text(player: PlayerData) -> String:
	var lines: Array[String] = []
	lines.append("主位置: %s" % player.primary_position)
	lines.append("二次守備: %s" % _get_secondary_positions_text(player))
	lines.append("")
	lines.append("ポジション適性")
	for position_key in PlayerData.POSITION_KEYS:
		var raw_value: int = player.get_position_rating(position_key)
		if raw_value <= 0 and position_key != player.primary_position:
			continue
		lines.append("%s  %s (%d)" % [position_key, player.get_position_rating_label(position_key), raw_value])
	return "\n".join(lines)


func _build_traits_text(player: PlayerData) -> String:
	var lines: Array[String] = []
	var categorized: Dictionary = player.get_traits_by_category()
	for key in ["打撃", "守備", "投手", "メンタル"]:
		var values = categorized.get(key, [])
		if values.size() == 0:
			continue
		lines.append("%s" % key)
		lines.append(", ".join(values))
		lines.append("")
	if lines.is_empty():
		return "特殊能力はありません。"
	return "\n".join(lines).strip_edges()


func _build_development_text(player: PlayerData) -> String:
	return "\n".join(player.get_development_lines())


func _build_stats_text(player: PlayerData) -> String:
	if player.is_pitcher():
		return "\n".join([
			"登板: %d  先発: %d" % [int(player.pitching_stats["g"]), int(player.pitching_stats["gs"])],
			"勝敗: %d勝 %d敗" % [int(player.pitching_stats["wins"]), int(player.pitching_stats["losses"])],
			"セーブ / ホールド: %d / %d" % [int(player.pitching_stats["saves"]), int(player.pitching_stats["holds"])],
			"防御率: %.2f" % player.get_era(),
			"被安打: %d  被本塁打: %d" % [int(player.pitching_stats["ha"]), int(player.pitching_stats["hra"])],
			"与四球: %d  奪三振: %d" % [int(player.pitching_stats["bb"]), int(player.pitching_stats["so"])]
		])

	return "\n".join([
		"試合: %d  打席: %d  打数: %d" % [int(player.batting_stats["g"]), int(player.batting_stats["pa"]), int(player.batting_stats["ab"])],
		"打率: %.3f  安打: %d" % [player.get_batting_average(), int(player.batting_stats["h"])],
		"二塁打: %d  三塁打: %d  本塁打: %d" % [int(player.batting_stats["d2"]), int(player.batting_stats["d3"]), int(player.batting_stats["hr"])],
		"打点: %d  得点: %d" % [int(player.batting_stats["rbi"]), int(player.batting_stats["runs"])],
		"四球: %d  三振: %d  盗塁: %d" % [int(player.batting_stats["bb"]), int(player.batting_stats["so"]), int(player.batting_stats["sb"])]
	])


func _build_history_text(player: PlayerData) -> String:
	var lines: Array[String] = []
	for line in player.get_history_lines():
		lines.append(str(line))
	lines.append("ドラフト / FA / トレード履歴: 今後追加")
	lines.append("受賞歴: 今後追加")
	return "\n".join(lines)


func _build_pitch_types_text(player: PlayerData) -> String:
	if player.pitch_types.is_empty():
		return "未設定"
	return ", ".join(player.pitch_types)


func _get_secondary_positions_text(player: PlayerData) -> String:
	if player.secondary_positions.is_empty():
		return "なし"
	return ", ".join(player.secondary_positions)


func _find_player_team(player_id: String) -> TeamData:
	for team_id in LeagueState.all_team_ids():
		var team: TeamData = LeagueState.get_team(team_id)
		if team != null and team.player_ids.has(player_id):
			return team
	return null


func _get_player_assignment_label(player: PlayerData, team: TeamData) -> String:
	if player == null or team == null:
		return "所属チーム不明"

	var player_id: String = str(player.id)
	if team.rotation_ids.has(player_id):
		return "先発ローテ %d番" % [team.rotation_ids.find(player_id) + 1]
	if str(team.bullpen.get("closer", "")) == player_id:
		return "抑え"
	if team.bullpen.get("setup", []).has(player_id):
		return "セットアッパー"
	if team.bullpen.get("middle", []).has(player_id):
		return "中継ぎ"
	if str(team.bullpen.get("long", "")) == player_id:
		return "ロング"
	if team.lineup_vs_r.has(player_id) and team.lineup_vs_l.has(player_id):
		return "一軍スタメン"
	if team.lineup_vs_r.has(player_id):
		return "対右スタメン"
	if team.lineup_vs_l.has(player_id):
		return "対左スタメン"
	if team.bench_ids.has(player_id):
		return "一軍ベンチ"
	return "二軍・控え"


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(ROSTER_VIEW_SCENE_PATH)
