extends Control

const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var basic_title_label: Label = $RootScroll/MarginContainer/RootVBox/BasicTitleLabel
@onready var basic_detail_label: Label = $RootScroll/MarginContainer/RootVBox/BasicDetailLabel
@onready var ratings_title_label: Label = $RootScroll/MarginContainer/RootVBox/RatingsTitleLabel
@onready var ratings_detail_label: Label = $RootScroll/MarginContainer/RootVBox/RatingsDetailLabel
@onready var stats_title_label: Label = $RootScroll/MarginContainer/RootVBox/StatsTitleLabel
@onready var stats_detail_label: Label = $RootScroll/MarginContainer/RootVBox/StatsDetailLabel

func _ready() -> void:
	title_label.text = "選手詳細"
	back_button.text = "選手一覧へ戻る"
	basic_title_label.text = "基本情報"
	ratings_title_label.text = "能力"
	stats_title_label.text = "今季成績"
	back_button.pressed.connect(_on_back_button_pressed)
	_refresh_view()

func _refresh_view() -> void:
	var player: PlayerData = LeagueState.get_selected_player()
	if player == null:
		info_label.text = "選手が選ばれていません。"
		basic_detail_label.text = "選手一覧から選んでください。"
		ratings_detail_label.text = "-"
		stats_detail_label.text = "-"
		return

	var team: TeamData = _find_player_team(str(player.id))
	info_label.text = "%sの詳細データです。" % player.full_name

	var basic_lines: Array[String] = []
	basic_lines.append("所属: %s" % (team.name if team != null else "所属不明"))
	basic_lines.append("役割: %s" % _get_player_role_label(player))
	basic_lines.append("起用状況: %s" % _get_player_assignment_label(player, team))
	basic_lines.append("登録区分: %s" % _get_registration_type_label(player))
	basic_lines.append("在籍状態: %s" % _get_roster_status_label(player))
	basic_lines.append("外国人: %s" % ("はい" if bool(player.is_foreign) else "いいえ"))
	basic_lines.append("年齢: %d" % int(player.age))
	basic_lines.append("年俸: %d" % int(player.salary))
	basic_lines.append("契約残り: %d年" % int(player.contract_years_left))
	basic_lines.append("希望年俸: %d" % int(player.desired_salary))
	basic_lines.append("FA志向: %d" % int(player.fa_interest))
	basic_lines.append("投/打: %s投 / %s打" % [str(player.throws), str(player.bats)])
	basic_lines.append("総合: %d  潜在: %d" % [int(player.overall), int(player.potential)])
	basic_lines.append("成長タイプ: %s" % _get_development_label(str(player.development_type)))
	basic_lines.append("特性: %s" % _build_traits_text(player))
	basic_lines.append("コンディション: %d  疲労: %d  士気: %d" % [int(player.condition), int(player.fatigue), int(player.morale)])
	basic_detail_label.text = "\n".join(basic_lines)

	ratings_detail_label.text = _build_ratings_text(player)
	stats_detail_label.text = _build_stats_text(player)

func _build_ratings_text(player: PlayerData) -> String:
	if player.is_pitcher():
		return "\n".join([
			"球威: %d" % int(player.ratings["velocity"]),
			"制球: %d" % int(player.ratings["control"]),
			"スタミナ: %d" % int(player.ratings["stamina"]),
			"変化: %d" % int(player.ratings["break"]),
			"奪三振: %d" % int(player.ratings["k_rate"]),
			"対左: %d" % int(player.ratings["vs_left"]),
			"度胸: %d" % int(player.ratings["composure"])
		])

	return "\n".join([
		"ミート: %d" % int(player.ratings["contact"]),
		"パワー: %d" % int(player.ratings["power"]),
		"選球眼: %d" % int(player.ratings["eye"]),
		"走力: %d" % int(player.ratings["speed"]),
		"肩力: %d" % int(player.ratings["arm"]),
		"守備: %d" % int(player.ratings["fielding"]),
		"捕球: %d" % int(player.ratings["catching"]),
		"対左: %d" % int(player.ratings["vs_left"])
	])

func _build_stats_text(player: PlayerData) -> String:
	if player.is_pitcher():
		return "\n".join([
			"登板: %d" % int(player.pitching_stats["g"]),
			"先発: %d" % int(player.pitching_stats["gs"]),
			"勝敗: %d勝 %d敗" % [int(player.pitching_stats["wins"]), int(player.pitching_stats["losses"])],
			"セーブ/ホールド: %d / %d" % [int(player.pitching_stats["saves"]), int(player.pitching_stats["holds"])],
			"防御率: %.2f" % player.get_era(),
			"奪三振: %d" % int(player.pitching_stats["so"])
		])

	return "\n".join([
		"試合: %d" % int(player.batting_stats["g"]),
		"打率: %.3f" % player.get_batting_average(),
		"安打: %d" % int(player.batting_stats["h"]),
		"本塁打: %d" % int(player.batting_stats["hr"]),
		"打点: %d" % int(player.batting_stats["rbi"]),
		"四球: %d" % int(player.batting_stats["bb"]),
		"盗塁: %d" % int(player.batting_stats["sb"])
	])

func _build_traits_text(player: PlayerData) -> String:
	if player.traits.is_empty():
		return "なし"
	var labels: Array[String] = []
	for trait_name in player.traits:
		labels.append(str(trait_name))
	return ", ".join(labels)

func _find_player_team(player_id: String) -> TeamData:
	for team_id in LeagueState.all_team_ids():
		var team: TeamData = LeagueState.get_team(team_id)
		if team == null:
			continue
		if team.player_ids.has(player_id):
			return team
	return null

func _get_player_role_label(player: PlayerData) -> String:
	if player == null:
		return "-"
	match str(player.role):
		"starter":
			return "先発投手"
		"reliever":
			return "救援投手"
		"closer":
			return "抑え投手"
		_:
			return "野手 / %s" % str(player.primary_position)

func _get_player_assignment_label(player: PlayerData, team: TeamData) -> String:
	if player == null or team == null:
		return "所属不明"

	var player_id: String = str(player.id)
	if team.rotation_ids.has(player_id):
		var rotation_index: int = team.rotation_ids.find(player_id)
		return "先発ローテ%d番" % [rotation_index + 1]
	if str(team.bullpen.get("closer", "")) == player_id:
		return "抑え"
	if team.bullpen.get("setup", []).has(player_id):
		return "勝ち継投"
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
	return "二軍"

func _get_registration_type_label(player: PlayerData) -> String:
	return "育成契約" if str(player.registration_type) == "development" else "支配下"

func _get_roster_status_label(player: PlayerData) -> String:
	match str(player.roster_status):
		"active":
			return "一軍"
		"development":
			return "育成"
		_:
			return "二軍"

func _get_development_label(development_type: String) -> String:
	match development_type:
		"early":
			return "早熟"
		"late":
			return "晩成"
		_:
			return "標準"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(ROSTER_VIEW_SCENE_PATH)
