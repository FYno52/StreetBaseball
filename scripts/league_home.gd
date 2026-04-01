extends Control

const TEAM_SELECT_SCENE_PATH := "res://scenes/TeamSelect.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const LEAGUE_INFO_SCENE_PATH := "res://scenes/LeagueInfo.tscn"
const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var nav_info_label: Label = $RootScroll/MarginContainer/RootVBox/NavInfoLabel
@onready var team_management_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/TeamManagementButton
@onready var league_info_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/LeagueInfoButton
@onready var roster_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/RosterButton
@onready var sim_day_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimDayButton
@onready var sim_week_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimWeekButton
@onready var sim_auto_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimAutoButton
@onready var sim_to_next_game_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimToNextGameButton
@onready var sim_to_season_end_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimToSeasonEndButton
@onready var save_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/SaveButtonsHBox/SaveButton
@onready var load_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/SaveButtonsHBox/LoadButton
@onready var progress_status_label: Label = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressStatusLabel

@onready var season_status_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/SeasonStatusCard/SeasonStatusTitleLabel
@onready var season_status_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/SeasonStatusCard/SeasonStatusDetailLabel
@onready var focus_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/FocusTeamCard/FocusTeamTitleLabel
@onready var focus_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/FocusTeamCard/FocusTeamDetailLabel
@onready var today_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/TodayCard/TodayTitleLabel
@onready var today_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/TodayCard/TodayDetailLabel
@onready var yesterday_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/YesterdayCard/YesterdayTitleLabel
@onready var yesterday_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/YesterdayCard/YesterdayDetailLabel

@onready var digest_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/DigestTitleLabel
@onready var digest_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/DigestDetailLabel
@onready var leaders_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/LeadersTitleLabel
@onready var batting_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/BattingLeadersLabel
@onready var pitching_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/PitchingLeadersLabel
@onready var event_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/EventTitleLabel
@onready var event_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/EventDetailLabel
@onready var note_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/NoteTitleLabel
@onready var note_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightContentVBox/NoteDetailLabel

var auto_progress_active: bool = false

func _ready() -> void:
	if LeagueState.teams.is_empty() or LeagueState.schedule.is_empty():
		LeagueState.new_game()
	if LeagueState.controlled_team_id == "":
		get_tree().call_deferred("change_scene_to_file", TEAM_SELECT_SCENE_PATH)
		return

	title_label.text = "ストリート野球"
	nav_info_label.text = ""
	team_management_button.text = "チーム管理へ"
	league_info_button.text = "リーグ情報へ"
	roster_button.text = "選手一覧へ"
	sim_day_button.text = "1日進める"
	sim_week_button.text = "7日進める"
	sim_auto_button.text = "オート進行"
	sim_to_next_game_button.text = "次の試合まで"
	sim_to_season_end_button.text = "次の節目まで"
	save_button.text = "セーブ"
	load_button.text = "ロード"
	progress_status_label.text = "保存先: user://save_01.json"

	season_status_title_label.text = "シーズン状況"
	focus_team_title_label.text = "担当球団の近況"
	today_title_label.text = "今日の予定"
	yesterday_title_label.text = "昨日の結果"
	digest_title_label.text = "リーグ速報"
	leaders_title_label.text = "リーグ個人成績"
	event_title_label.text = "ストリートニュース"
	note_title_label.text = "進行メモ"

	sim_day_button.pressed.connect(_on_sim_day_button_pressed)
	sim_week_button.pressed.connect(_on_sim_week_button_pressed)
	sim_auto_button.pressed.connect(_on_sim_auto_button_pressed)
	sim_to_next_game_button.pressed.connect(_on_sim_to_next_game_button_pressed)
	sim_to_season_end_button.pressed.connect(_on_sim_to_season_end_button_pressed)
	team_management_button.pressed.connect(_on_team_management_button_pressed)
	league_info_button.pressed.connect(_on_league_info_button_pressed)
	roster_button.pressed.connect(_on_roster_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)

	_refresh_view()

func _exit_tree() -> void:
	auto_progress_active = false

func _refresh_view() -> void:
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	var controlled_name: String = "未設定"
	if controlled_team != null:
		controlled_name = controlled_team.name
	nav_info_label.text = "日付: %s  /  担当球団: %s" % [LeagueState.get_current_date_label(), controlled_name]

	_refresh_season_status()
	_refresh_focus_team_summary()
	_refresh_today_summary()
	_refresh_yesterday_summary()
	_refresh_home_digest()
	_refresh_league_leaders()
	_refresh_daily_events()
	_refresh_note_summary()
	_refresh_progress_buttons()

func _simulate_single_day() -> void:
	if LeagueState.current_day > LeagueState.get_last_day():
		_refresh_progress_buttons()
		return

	var simulated_date_label: String = LeagueState.get_current_date_label()
	var games_today: Array = LeagueState.simulate_current_day()
	var transition_report: Array[String] = LeagueState.complete_day_transition()

	if games_today.is_empty():
		progress_status_label.text = "%s を消化しました / 今日は試合なし" % simulated_date_label
	else:
		progress_status_label.text = "%s を消化しました / 試合数: %d" % [simulated_date_label, games_today.size()]
	if not transition_report.is_empty():
		progress_status_label.text += "\n年越し: " + str(transition_report[0])

	_refresh_view()

func _simulate_multiple_days(day_count: int) -> void:
	if day_count <= 0 or LeagueState.current_day > LeagueState.get_last_day():
		_refresh_progress_buttons()
		return

	var summary: Dictionary = LeagueState.simulate_days(day_count)
	var simulated_days: int = int(summary.get("simulated_days", 0))
	var played_games: int = int(summary.get("played_games", 0))
	var start_date_label: String = str(summary.get("start_date_label", ""))
	var end_date_label: String = str(summary.get("end_date_label", ""))
	var calendar_days_passed: int = int(summary.get("calendar_days_passed", 0))
	var transition_count: int = int(summary.get("transition_count", 0))
	var transition_headline: String = str(summary.get("transition_headline", ""))

	if simulated_days <= 0:
		progress_status_label.text = "これ以上進められる日程がありません"
	else:
		progress_status_label.text = "%s から %s まで進行 / 試合日: %d日 / 経過日数: %d日 / 消化試合数: %d" % [
			start_date_label,
			end_date_label,
			simulated_days,
			calendar_days_passed,
			played_games
		]
		if transition_count > 0:
			progress_status_label.text += "\n年越し: %d回" % transition_count
			if transition_headline != "":
				progress_status_label.text += " / " + transition_headline

	_refresh_view()

func _run_auto_progress() -> void:
	while auto_progress_active and is_inside_tree():
		_simulate_single_day()
		if not auto_progress_active:
			break
		await get_tree().create_timer(0.35).timeout

func _on_sim_day_button_pressed() -> void:
	if auto_progress_active:
		return
	_simulate_single_day()

func _on_sim_week_button_pressed() -> void:
	if auto_progress_active:
		return
	_simulate_multiple_days(7)

func _on_sim_auto_button_pressed() -> void:
	if auto_progress_active:
		auto_progress_active = false
		progress_status_label.text = "オート進行を停止しました"
		_refresh_progress_buttons()
		return
	auto_progress_active = true
	progress_status_label.text = "オート進行を開始しました"
	_refresh_progress_buttons()
	_run_auto_progress()

func _on_sim_to_next_game_button_pressed() -> void:
	if auto_progress_active:
		return
	if LeagueState.get_season_phase() != "regular":
		progress_status_label.text = "次の試合まで はシーズン中だけ使えます\n開幕前やオフは 次の節目まで を使ってください"
		_refresh_view()
		return

	var next_game_day: int = LeagueState.get_next_game_day(LeagueState.current_day, LeagueState.controlled_team_id)
	if next_game_day < 0:
		progress_status_label.text = "今年度の担当球団の試合日程はもうありません"
		_refresh_view()
		return

	_simulate_multiple_days(maxi(1, next_game_day - LeagueState.current_day + 1))

func _on_sim_to_season_end_button_pressed() -> void:
	if auto_progress_active:
		return
	var phase: String = LeagueState.get_season_phase()
	var remaining_days: int = 1
	if phase == "preseason":
		remaining_days = maxi(1, LeagueState.get_first_game_day() - LeagueState.current_day)
	elif phase == "regular":
		remaining_days = maxi(1, LeagueState.get_final_game_day() - LeagueState.current_day + 1)
	else:
		remaining_days = maxi(1, LeagueState.get_last_day() - LeagueState.current_day + 1)
	_simulate_multiple_days(remaining_days)

func _on_team_management_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(TEAM_MANAGEMENT_SCENE_PATH)

func _on_league_info_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(LEAGUE_INFO_SCENE_PATH)

func _on_roster_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(ROSTER_VIEW_SCENE_PATH)

func _on_save_button_pressed() -> void:
	var saved: bool = LeagueState.save_to_file()
	progress_status_label.text = "保存しました: user://save_01.json" if saved else "保存に失敗しました"
	_refresh_view()

func _on_load_button_pressed() -> void:
	var loaded: bool = LeagueState.load_from_file()
	if not loaded:
		progress_status_label.text = "ロードに失敗しました"
		return
	progress_status_label.text = "ロードしました: user://save_01.json"
	if LeagueState.controlled_team_id == "":
		get_tree().call_deferred("change_scene_to_file", TEAM_SELECT_SCENE_PATH)
		return
	_refresh_view()

func _refresh_progress_buttons() -> void:
	var can_progress: bool = LeagueState.current_day <= LeagueState.get_last_day()
	sim_day_button.disabled = auto_progress_active or not can_progress
	sim_week_button.disabled = auto_progress_active or not can_progress
	sim_to_season_end_button.disabled = auto_progress_active or not can_progress
	sim_to_next_game_button.disabled = auto_progress_active or LeagueState.get_season_phase() != "regular" or not can_progress
	save_button.disabled = auto_progress_active
	load_button.disabled = auto_progress_active
	team_management_button.disabled = auto_progress_active
	league_info_button.disabled = auto_progress_active
	roster_button.disabled = auto_progress_active
	sim_auto_button.text = "オート停止" if auto_progress_active else "オート進行"

func _refresh_season_status() -> void:
	var phase: String = LeagueState.get_season_phase()
	var lines: Array[String] = []
	lines.append("%d年" % LeagueState.season_year)
	lines.append("現在の日付: %s" % LeagueState.get_current_date_label())
	match phase:
		"preseason":
			lines.append("状態: 開幕前")
			lines.append("開幕予定: %s" % LeagueState.get_date_label_for_day(LeagueState.get_first_game_day()))
		"regular":
			lines.append("状態: シーズン中")
			lines.append("最終戦予定: %s" % LeagueState.get_date_label_for_day(LeagueState.get_final_game_day()))
		_:
			lines.append("状態: オフシーズン")
			lines.append("年末まで進行すると次年度へ移ります。")
	lines.append("年間進行: 365日 / 公式戦はNPB準拠ベース")

	if LeagueState.current_day == 1:
		var offseason_report: Array[String] = LeagueState.get_last_offseason_report()
		if not offseason_report.is_empty():
			lines.append("")
			lines.append("オフシーズン処理完了")
			lines.append(offseason_report[0])
		var roster_log: Array[String] = LeagueState.get_last_controlled_team_roster_log()
		if not roster_log.is_empty():
			lines.append("")
			for roster_line in roster_log:
				lines.append(roster_line)

	season_status_detail_label.text = "\n".join(lines)

func _refresh_home_digest() -> void:
	var sorted_teams: Array = LeagueState.get_teams_sorted_by_win_pct()
	if sorted_teams.is_empty():
		digest_detail_label.text = "リーグ速報を表示できません。"
		return

	var leader: TeamData = sorted_teams[0]
	var batting: Dictionary = LeagueState.get_league_batting_leaders(1)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(1)
	var lines: Array[String] = []
	lines.append("首位: %s  %d勝 %d敗 %d分  勝率 %.3f" % [leader.name, int(leader.standings["wins"]), int(leader.standings["losses"]), int(leader.standings["draws"]), leader.win_pct()])

	var avg_leaders: Array = batting.get("avg", [])
	if not avg_leaders.is_empty():
		var avg_player: PlayerData = avg_leaders[0]
		lines.append("打率首位: %s  %.3f" % [avg_player.full_name, avg_player.get_batting_average()])
	var hr_leaders: Array = batting.get("hr", [])
	if not hr_leaders.is_empty():
		var hr_player: PlayerData = hr_leaders[0]
		lines.append("本塁打首位: %s  %d本" % [hr_player.full_name, int(hr_player.batting_stats["hr"])])
	var win_leaders: Array = pitching.get("wins", [])
	if not win_leaders.is_empty():
		var win_player: PlayerData = win_leaders[0]
		lines.append("勝利数首位: %s  %d勝" % [win_player.full_name, int(win_player.pitching_stats["wins"])])
	var save_leaders: Array = pitching.get("saves", [])
	if not save_leaders.is_empty():
		var save_player: PlayerData = save_leaders[0]
		lines.append("セーブ首位: %s  %dS" % [save_player.full_name, int(save_player.pitching_stats["saves"])])
	digest_detail_label.text = "\n".join(lines)

func _refresh_league_leaders() -> void:
	var batting: Dictionary = LeagueState.get_league_batting_leaders(5)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(5)

	var batting_lines: Array[String] = ["打者部門"]
	batting_lines.append("打率")
	for i in range(batting.get("avg", []).size()):
		var avg_player: PlayerData = batting["avg"][i]
		batting_lines.append("%d. %s  %.3f" % [i + 1, avg_player.full_name, avg_player.get_batting_average()])
	batting_lines.append("")
	batting_lines.append("本塁打")
	for i in range(batting.get("hr", []).size()):
		var hr_player: PlayerData = batting["hr"][i]
		batting_lines.append("%d. %s  %d" % [i + 1, hr_player.full_name, int(hr_player.batting_stats["hr"])])
	batting_lines.append("")
	batting_lines.append("打点")
	for i in range(batting.get("rbi", []).size()):
		var rbi_player: PlayerData = batting["rbi"][i]
		batting_lines.append("%d. %s  %d" % [i + 1, rbi_player.full_name, int(rbi_player.batting_stats["rbi"])])
	batting_leaders_label.text = "\n".join(batting_lines)

	var pitching_lines: Array[String] = ["投手部門"]
	pitching_lines.append("勝利")
	for i in range(pitching.get("wins", []).size()):
		var win_player: PlayerData = pitching["wins"][i]
		pitching_lines.append("%d. %s  %d" % [i + 1, win_player.full_name, int(win_player.pitching_stats["wins"])])
	pitching_lines.append("")
	pitching_lines.append("セーブ")
	for i in range(pitching.get("saves", []).size()):
		var save_player: PlayerData = pitching["saves"][i]
		pitching_lines.append("%d. %s  %d" % [i + 1, save_player.full_name, int(save_player.pitching_stats["saves"])])
	pitching_lines.append("")
	pitching_lines.append("防御率")
	for i in range(pitching.get("era", []).size()):
		var era_player: PlayerData = pitching["era"][i]
		pitching_lines.append("%d. %s  %.2f" % [i + 1, era_player.full_name, era_player.get_era()])
	pitching_leaders_label.text = "\n".join(pitching_lines)

func _refresh_daily_events() -> void:
	var events: Array[String] = LeagueState.get_recent_events()
	if events.is_empty():
		event_detail_label.text = "今日は特別なイベントなし"
		return
	var lines: Array[String] = []
	for event_text in events:
		lines.append("- " + str(event_text))
	event_detail_label.text = "\n".join(lines)

func _refresh_focus_team_summary() -> void:
	var focus_team: TeamData = LeagueState.get_controlled_team()
	if focus_team == null:
		focus_team_detail_label.text = "担当球団情報を表示できません。"
		return

	var lines: Array[String] = []
	lines.append("チーム: %s" % focus_team.name)
	lines.append("戦績: %d勝 %d敗 %d分" % [int(focus_team.standings["wins"]), int(focus_team.standings["losses"]), int(focus_team.standings["draws"])])
	lines.append("得失点: %d / %d" % [int(focus_team.standings["runs_for"]), int(focus_team.standings["runs_against"])])
	lines.append("ファン人気: %d  予算: %d" % [int(focus_team.fan_support), int(focus_team.budget)])
	lines.append("方針: %s" % _get_strategy_label(str(focus_team.strategy)))
	lines.append("年俸総額: %d" % LeagueState.get_team_total_salary(str(focus_team.id)))

	var finance_log: Array[String] = LeagueState.get_recent_finance_log()
	if not finance_log.is_empty():
		lines.append("直近収支: %s" % finance_log[0])

	var next_starter_name: String = "未定"
	if not focus_team.rotation_ids.is_empty():
		var starter_index: int = max(0, (LeagueState.current_day - 1) % focus_team.rotation_ids.size())
		var starter: PlayerData = LeagueState.get_player(str(focus_team.rotation_ids[starter_index]))
		if starter != null:
			next_starter_name = "%s (%s投)" % [starter.full_name, starter.throws]
	lines.append("予想先発: %s" % next_starter_name)

	var top_batter: PlayerData = _find_top_batter_for_team(focus_team)
	if top_batter != null:
		lines.append("打線の中心: %s  打率 %.3f / %d本" % [top_batter.full_name, top_batter.get_batting_average(), int(top_batter.batting_stats["hr"])])

	focus_team_detail_label.text = "\n".join(lines)

func _find_top_batter_for_team(team: TeamData) -> PlayerData:
	var best_player: PlayerData = null
	var best_value: float = -9999.0
	for player_id in team.player_ids:
		var player: PlayerData = LeagueState.get_player(str(player_id))
		if player == null or player.is_pitcher():
			continue
		var value: float = float(player.batting_stats["hr"]) * 4.0 + float(player.batting_stats["rbi"]) * 1.5 + player.get_batting_average() * 100.0
		if value > best_value:
			best_value = value
			best_player = player
	return best_player

func _refresh_today_summary() -> void:
	if LeagueState.current_day > LeagueState.get_last_day():
		today_detail_label.text = "今季の日程はすべて終了しています。"
		return

	var games_today: Array = []
	for game in LeagueState.schedule:
		if int(game.day) == LeagueState.current_day:
			games_today.append(game)

	if games_today.is_empty():
		today_detail_label.text = "%s は試合予定がありません。\n休養日または移動日として進行します。" % LeagueState.get_current_date_label()
		return

	var lines: Array[String] = []
	lines.append("%s の予定: %d試合" % [LeagueState.get_current_date_label(), games_today.size()])
	var controlled_game: GameData = null
	var focus_game: GameData = null
	var focus_value: float = -1.0

	for game in games_today:
		lines.append("- %s vs %s" % [_get_team_name(str(game.away_team_id)), _get_team_name(str(game.home_team_id))])
		if LeagueState.controlled_team_id != "" and (str(game.away_team_id) == LeagueState.controlled_team_id or str(game.home_team_id) == LeagueState.controlled_team_id):
			controlled_game = game
		var away_team: TeamData = LeagueState.get_team(str(game.away_team_id))
		var home_team: TeamData = LeagueState.get_team(str(game.home_team_id))
		if away_team != null and home_team != null:
			var matchup_value: float = SimulationEngine.get_team_total_strength(away_team) + SimulationEngine.get_team_total_strength(home_team)
			if matchup_value > focus_value:
				focus_value = matchup_value
				focus_game = game

	if controlled_game != null:
		lines.append("")
		lines.append("担当球団カード: %s vs %s" % [_get_team_name(str(controlled_game.away_team_id)), _get_team_name(str(controlled_game.home_team_id))])
	if focus_game != null:
		lines.append("")
		lines.append("注目カード: %s vs %s" % [_get_team_name(str(focus_game.away_team_id)), _get_team_name(str(focus_game.home_team_id))])

	today_detail_label.text = "\n".join(lines)

func _refresh_yesterday_summary() -> void:
	var target_day: int = LeagueState.current_day - 1
	if LeagueState.current_day > LeagueState.get_last_day():
		target_day = LeagueState.get_last_day()
	if target_day <= 0:
		yesterday_detail_label.text = "まだ試合結果はありません。"
		return

	var games_yesterday: Array = []
	for game in LeagueState.schedule:
		if int(game.day) == target_day and bool(game.played):
			games_yesterday.append(game)
	if games_yesterday.is_empty():
		yesterday_detail_label.text = "前日の試合結果はまだありません。"
		return

	var lines: Array[String] = []
	lines.append("%s の結果" % LeagueState.get_date_label_for_day(target_day))
	var controlled_game: GameData = null
	var closest_game: GameData = null
	var closest_margin: int = 999
	for game in games_yesterday:
		lines.append("- %s %d - %d %s" % [_get_team_name(str(game.away_team_id)), int(game.away_score), int(game.home_score), _get_team_name(str(game.home_team_id))])
		if LeagueState.controlled_team_id != "" and (str(game.away_team_id) == LeagueState.controlled_team_id or str(game.home_team_id) == LeagueState.controlled_team_id):
			controlled_game = game
		var margin: int = abs(int(game.away_score) - int(game.home_score))
		if margin < closest_margin:
			closest_margin = margin
			closest_game = game

	if controlled_game != null:
		lines.append("")
		lines.append("担当球団の結果: %s %d - %d %s" % [_get_team_name(str(controlled_game.away_team_id)), int(controlled_game.away_score), int(controlled_game.home_score), _get_team_name(str(controlled_game.home_team_id))])
	if closest_game != null:
		lines.append("")
		lines.append("接戦: %s %d - %d %s" % [_get_team_name(str(closest_game.away_team_id)), int(closest_game.away_score), int(closest_game.home_score), _get_team_name(str(closest_game.home_team_id))])

	yesterday_detail_label.text = "\n".join(lines)

func _refresh_note_summary() -> void:
	var lines: Array[String] = []
	lines.append("進行操作")
	lines.append("1日進める: 毎日進行")
	lines.append("7日進める: まとめて進行")
	lines.append("次の試合まで: シーズン中のみ")
	lines.append("次の節目まで: 開幕 / 最終戦 / 年末まで")
	if auto_progress_active:
		lines.append("")
		lines.append("現在オート進行中です。")
	note_detail_label.text = "\n".join(lines)

func _get_team_name(team_id: String) -> String:
	var team: TeamData = LeagueState.get_team(team_id)
	if team == null:
		return team_id
	return team.name

func _get_strategy_label(strategy: String) -> String:
	match strategy:
		"power":
			return "強打"
		"speed":
			return "機動力"
		"defense":
			return "守備重視"
		"pitching":
			return "投手重視"
		_:
			return "標準"
