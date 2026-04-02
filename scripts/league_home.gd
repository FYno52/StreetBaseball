extends Control

const TEAM_SELECT_SCENE_PATH := "res://scenes/TeamSelect.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const LEAGUE_INFO_SCENE_PATH := "res://scenes/LeagueInfo.tscn"
const CALENDAR_SCENE_PATH := "res://scenes/CalendarScene.tscn"
const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"
const MATCH_SCENE_PATH := "res://scenes/MatchScene.tscn"
const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var nav_info_label: Label = $RootScroll/MarginContainer/RootVBox/NavInfoLabel
@onready var team_management_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/TeamManagementButton
@onready var league_info_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/LeagueInfoButton
@onready var calendar_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/CalendarButton
@onready var roster_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/RosterButton
@onready var front_office_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/FrontOfficeButton
@onready var sim_day_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimDayButton
@onready var sim_week_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimWeekButton
@onready var sim_auto_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimAutoButton
@onready var sim_to_next_game_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/SimToNextGameButton
@onready var live_game_button: Button = $RootScroll/MarginContainer/RootVBox/ProgressCard/ProgressButtonsHBox/LiveGameButton
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

	_setup_static_text()
	_connect_buttons()
	var pending_message: String = LeagueState.consume_pending_home_message()
	if pending_message != "":
		progress_status_label.text = pending_message
	_refresh_view()


func _exit_tree() -> void:
	auto_progress_active = false


func _connect_buttons() -> void:
	team_management_button.pressed.connect(_on_team_management_button_pressed)
	league_info_button.pressed.connect(_on_league_info_button_pressed)
	calendar_button.pressed.connect(_on_calendar_button_pressed)
	roster_button.pressed.connect(_on_roster_button_pressed)
	front_office_button.pressed.connect(_on_front_office_button_pressed)
	sim_day_button.pressed.connect(_on_sim_day_button_pressed)
	sim_week_button.pressed.connect(_on_sim_week_button_pressed)
	sim_auto_button.pressed.connect(_on_sim_auto_button_pressed)
	sim_to_next_game_button.pressed.connect(_on_sim_to_next_game_button_pressed)
	live_game_button.pressed.connect(_on_live_game_button_pressed)
	sim_to_season_end_button.pressed.connect(_on_sim_to_season_end_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)


func _setup_static_text() -> void:
	title_label.text = "ストリート野球"
	team_management_button.text = "チーム管理へ"
	league_info_button.text = "リーグ情報へ"
	calendar_button.text = "年間カレンダーへ"
	roster_button.text = "選手一覧へ"
	front_office_button.text = "球団運営へ"
	sim_day_button.text = "1日進める"
	sim_week_button.text = "7日進める"
	sim_auto_button.text = "オート進行"
	sim_to_next_game_button.text = "次の試合まで"
	live_game_button.text = "今日の試合へ"
	sim_to_season_end_button.text = "次の節目まで"
	save_button.text = "セーブ"
	load_button.text = "ロード"
	season_status_title_label.text = "シーズン状況"
	focus_team_title_label.text = "担当球団の近況"
	today_title_label.text = "今日の予定"
	yesterday_title_label.text = "昨日の結果"
	digest_title_label.text = "リーグ速報"
	leaders_title_label.text = "リーグ個人成績"
	event_title_label.text = "ストリートニュース"
	note_title_label.text = "進行メモ"


func _refresh_view() -> void:
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	var controlled_name: String = "未設定"
	if controlled_team != null:
		controlled_name = controlled_team.name

	nav_info_label.text = "日付: %s / 担当球団: %s" % [LeagueState.get_current_date_label(), controlled_name]

	_refresh_season_status()
	_refresh_focus_team_summary()
	_refresh_today_summary()
	_refresh_yesterday_summary()
	_refresh_home_digest()
	_refresh_league_leaders()
	_refresh_daily_events()
	_refresh_note_summary()
	_refresh_progress_buttons()


func _refresh_season_status() -> void:
	var first_game_day: int = LeagueState.get_first_game_day()
	var final_game_day: int = LeagueState.get_final_game_day()
	var phase: String = LeagueState.get_season_phase()
	var lines: Array[String] = []
	lines.append("現在日付: %s" % LeagueState.get_current_date_label())
	lines.append("年度: %d年" % LeagueState.season_year)
	lines.append("状態: %s" % _get_phase_label(phase))
	if first_game_day > 0:
		lines.append("開幕予定: %s" % LeagueState.get_date_label_for_day(first_game_day))
	if final_game_day > 0:
		lines.append("最終戦予定: %s" % LeagueState.get_date_label_for_day(final_game_day))
	lines.append("")
	lines.append("今日の年間イベント")
	lines.append(LeagueState.get_calendar_summary_text())
	var upcoming_events: Array[Dictionary] = LeagueState.get_upcoming_calendar_events(3)
	if not upcoming_events.is_empty():
		lines.append("")
		lines.append("次に来るイベント")
		for event_data in upcoming_events:
			lines.append("- %s  %s" % [str(event_data.get("date_label", "")), str(event_data.get("label", ""))])

	var offseason_report: Array[String] = LeagueState.get_last_offseason_report()
	if not offseason_report.is_empty() and LeagueState.current_day <= 14:
		lines.append("")
		lines.append("オフシーズン処理")
		for line in offseason_report.slice(0, mini(3, offseason_report.size())):
			lines.append("- %s" % str(line))

	var roster_log: Array[String] = LeagueState.get_last_controlled_team_roster_log()
	if not roster_log.is_empty() and LeagueState.current_day <= 14:
		lines.append("")
		for line in roster_log.slice(0, mini(4, roster_log.size())):
			lines.append(str(line))

	season_status_detail_label.text = "\n".join(lines)


func _refresh_focus_team_summary() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		focus_team_detail_label.text = "担当球団がまだ選ばれていません。"
		return

	var rotation: Array = LeagueState.get_team_rotation(str(team.id))
	var lineup_pack: Dictionary = LeagueState.get_team_lineup_and_bench(str(team.id))
	var lineup: Array = lineup_pack.get("lineup_vs_r", [])
	var ace_name: String = "未定"
	var core_batter_name: String = "未定"
	if not rotation.is_empty():
		var ace = LeagueState.get_player(str(rotation[0]))
		if ace != null:
			ace_name = ace.full_name
	if not lineup.is_empty():
		var core_batter = LeagueState.get_player(str(lineup[0]))
		if core_batter != null:
			core_batter_name = core_batter.full_name

	var lines: Array[String] = []
	lines.append(team.name)
	lines.append("戦績: %d勝 %d敗 %d分" % [int(team.standings["wins"]), int(team.standings["losses"]), int(team.standings["draws"])])
	lines.append("得失点: %d / %d" % [int(team.standings["runs_for"]), int(team.standings["runs_against"])])
	lines.append("人気: %d / 予算: %d" % [team.fan_support, team.budget])
	lines.append("方針: %s" % _get_strategy_label(str(team.strategy)))
	lines.append("予想先発: %s" % ace_name)
	lines.append("打線の中心: %s" % core_batter_name)

	var finance_log: Array[String] = LeagueState.get_recent_finance_log()
	if not finance_log.is_empty():
		lines.append("")
		lines.append("直近収支")
		lines.append(finance_log[0])

	var latest_result_text: String = _get_latest_controlled_team_result_text()
	if latest_result_text != "":
		lines.append("")
		lines.append("直近の試合")
		lines.append(latest_result_text)

	focus_team_detail_label.text = "\n".join(lines)


func _refresh_today_summary() -> void:
	var today_games: Array = LeagueState.get_games_for_day(LeagueState.current_day)
	var calendar_summary: String = LeagueState.get_calendar_summary_text()
	if today_games.is_empty():
		today_detail_label.text = "%s\n\n今日は試合予定がありません。\n休養日または移動日として進行します。" % calendar_summary
		return

	var lines: Array[String] = []
	var controlled_game: GameData = _get_today_controlled_team_game()
	if controlled_game != null:
		lines.append("担当球団カード")
		lines.append(_format_game_card(controlled_game))
		lines.append("")

	lines.append("%d試合予定" % today_games.size())
	for game_value in today_games.slice(0, mini(4, today_games.size())):
		var game: GameData = game_value
		lines.append("- %s" % _format_game_card(game))

	lines.append("")
	lines.append(calendar_summary)
	today_detail_label.text = "\n".join(lines)


func _refresh_yesterday_summary() -> void:
	var target_day: int = LeagueState.current_day - 1
	if target_day < 1:
		yesterday_detail_label.text = "まだ試合結果はありません。"
		return

	var results: Array[String] = []
	var controlled_lines: Array[String] = []
	for game_value in LeagueState.get_games_for_day(target_day):
		var game: GameData = game_value
		if not bool(game.played):
			continue
		var line: String = _format_result_line(game)
		results.append(line)
		if str(game.away_team_id) == LeagueState.controlled_team_id or str(game.home_team_id) == LeagueState.controlled_team_id:
			controlled_lines.append("担当球団の結果")
			controlled_lines.append(line)

	if results.is_empty():
		yesterday_detail_label.text = "前日の試合結果はまだありません。"
		return

	var lines: Array[String] = []
	if not controlled_lines.is_empty():
		lines.append_array(controlled_lines)
		lines.append("")
	lines.append("%s の結果" % LeagueState.get_date_label_for_day(target_day))
	for line in results.slice(0, mini(4, results.size())):
		lines.append("- %s" % line)

	yesterday_detail_label.text = "\n".join(lines)


func _refresh_home_digest() -> void:
	var standings: Array[TeamData] = []
	for team_value in LeagueState.teams.values():
		if team_value is TeamData:
			standings.append(team_value)
	standings.sort_custom(func(a: TeamData, b: TeamData) -> bool:
		if int(a.standings["wins"]) == int(b.standings["wins"]):
			var a_diff: int = int(a.standings["runs_for"]) - int(a.standings["runs_against"])
			var b_diff: int = int(b.standings["runs_for"]) - int(b.standings["runs_against"])
			return a_diff > b_diff
		return int(a.standings["wins"]) > int(b.standings["wins"])
	)
	if standings.is_empty():
		digest_detail_label.text = "リーグ情報がまだありません。"
		return
	var leader: TeamData = standings[0]
	var history_summary: Dictionary = LeagueState.get_controlled_team_history_summary()
	var lines: Array[String] = []
	lines.append("首位: %s (%d勝 %d敗)" % [leader.name, int(leader.standings["wins"]), int(leader.standings["losses"])])
	lines.append("現在日: %s" % LeagueState.get_current_date_label())
	if history_summary.get("seasons", 0) > 0:
		lines.append("")
		lines.append("担当球団通算")
		lines.append("%d年 / %d勝 %d敗 %d分" % [int(history_summary.get("seasons", 0)), int(history_summary.get("wins", 0)), int(history_summary.get("losses", 0)), int(history_summary.get("draws", 0))])
		lines.append("優勝 %d回 / 最高順位 %d位" % [int(history_summary.get("championships", 0)), int(history_summary.get("best_rank", 0))])
	digest_detail_label.text = "\n".join(lines)


func _refresh_league_leaders() -> void:
	var batting: Dictionary = LeagueState.get_league_batting_leaders(3)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(3)
	var batting_lines: Array[String] = ["打者部門"]
	for player in batting.get("avg", []):
		batting_lines.append("打率 %s %.3f" % [player.full_name, player.get_batting_average()])
	for player in batting.get("hr", []):
		batting_lines.append("本塁打 %s %d" % [player.full_name, int(player.batting_stats["hr"])])
	for player in batting.get("rbi", []):
		batting_lines.append("打点 %s %d" % [player.full_name, int(player.batting_stats["rbi"])])
	var pitching_lines: Array[String] = ["投手部門"]
	for player in pitching.get("wins", []):
		pitching_lines.append("勝利 %s %d" % [player.full_name, int(player.pitching_stats["wins"])])
	for player in pitching.get("saves", []):
		pitching_lines.append("セーブ %s %d" % [player.full_name, int(player.pitching_stats["saves"])])
	for player in pitching.get("era", []):
		pitching_lines.append("防御率 %s %.2f" % [player.full_name, player.get_era()])
	batting_leaders_label.text = "\n".join(batting_lines)
	pitching_leaders_label.text = "\n".join(pitching_lines)


func _refresh_daily_events() -> void:
	var events: Array[String] = LeagueState.get_recent_events()
	if events.is_empty():
		event_detail_label.text = "今日は大きなニュースはありません。"
		return
	event_detail_label.text = "\n".join(events.slice(0, mini(6, events.size())))


func _refresh_note_summary() -> void:
	var lines: Array[String] = []
	var today_game: GameData = _get_today_controlled_team_game()
	var phase: String = LeagueState.get_season_phase()
	lines.append("状態: %s" % _get_phase_label(phase))
	if today_game != null and not bool(today_game.played):
		lines.append("今日は担当球団の試合があります。")
		lines.append("自動進行でも消化できます。観たい時は「今日の試合へ」を使えます。")
		if LeagueState.is_active_live_game(str(today_game.id)):
			lines.append("この試合はライブ進行中です。試合確定まで再入場できません。")
	elif today_game != null and bool(today_game.played):
		lines.append("担当球団の今日の試合は消化済みです。")
	else:
		lines.append("今日は担当球団の試合はありません。")

	var latest_result_text: String = _get_latest_controlled_team_result_text()
	if latest_result_text != "":
		lines.append("")
		lines.append("直近の担当球団結果")
		lines.append(latest_result_text)

	var latest_integrity_notes: Array[String] = LeagueState.latest_integrity_notes
	if not latest_integrity_notes.is_empty():
		lines.append("")
		lines.append("内部メモ")
		for line in latest_integrity_notes.slice(0, mini(3, latest_integrity_notes.size())):
			lines.append("- %s" % str(line))
	note_detail_label.text = "\n".join(lines)


func _refresh_progress_buttons() -> void:
	var has_calendar_days: bool = LeagueState.current_day <= LeagueState.get_last_day()
	var phase: String = LeagueState.get_season_phase()
	var today_game: GameData = _get_today_controlled_team_game()
	var live_locked: bool = today_game != null and LeagueState.is_active_live_game(str(today_game.id))
	var can_open_live: bool = today_game != null and not bool(today_game.played) and not live_locked
	sim_day_button.disabled = auto_progress_active or not has_calendar_days
	sim_week_button.disabled = auto_progress_active or not has_calendar_days
	sim_to_next_game_button.disabled = auto_progress_active or phase != "regular"
	live_game_button.disabled = auto_progress_active or not can_open_live
	sim_to_season_end_button.disabled = auto_progress_active or not has_calendar_days
	save_button.disabled = auto_progress_active
	load_button.disabled = auto_progress_active
	sim_auto_button.text = "オート停止" if auto_progress_active else "オート進行"


func _simulate_single_day() -> void:
	if LeagueState.current_day > LeagueState.get_last_day():
		progress_status_label.text = "今年度のカレンダーは最後まで進んでいます。"
		_refresh_view()
		return
	var simulated_date_label: String = LeagueState.get_current_date_label()
	var games_today: Array = LeagueState.simulate_current_day()
	var finalize_report: Dictionary = LeagueState.finalize_current_day_if_ready()
	var transition_report: Array[String] = finalize_report.get("transition_report", [])
	if games_today.is_empty():
		progress_status_label.text = "%s を進めました / 今日は試合なし" % simulated_date_label
	else:
		progress_status_label.text = "%s を進めました / 消化試合数: %d" % [simulated_date_label, games_today.size()]
	_append_latest_controlled_result_to_status(simulated_date_label)
	if not transition_report.is_empty():
		progress_status_label.text += "\n年越し: %s" % transition_report[0]
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
		progress_status_label.text = "進められる日付がありません。"
	else:
		progress_status_label.text = "%s から %s まで進行\n試合日: %d / 経過日数: %d / 消化試合数: %d" % [start_date_label, end_date_label, simulated_days, calendar_days_passed, played_games]
		_append_latest_controlled_result_to_status(end_date_label)
		if transition_count > 0:
			progress_status_label.text += "\n年越し: %d回" % transition_count
			if transition_headline != "":
				progress_status_label.text += " / %s" % transition_headline
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
		progress_status_label.text = "オート進行を停止しました。"
		_refresh_progress_buttons()
		return
	auto_progress_active = true
	progress_status_label.text = "オート進行を開始しました。"
	_refresh_progress_buttons()
	_run_auto_progress()


func _on_sim_to_next_game_button_pressed() -> void:
	if auto_progress_active:
		return
	if LeagueState.get_season_phase() != "regular":
		progress_status_label.text = "次の試合まではシーズン中のみ使えます。"
		_refresh_view()
		return
	var next_game_day: int = LeagueState.get_next_game_day(LeagueState.current_day, LeagueState.controlled_team_id)
	if next_game_day < 0:
		progress_status_label.text = "今年度の担当球団の試合日程はもうありません。"
		_refresh_view()
		return
	_simulate_multiple_days(maxi(1, next_game_day - LeagueState.current_day + 1))


func _on_live_game_button_pressed() -> void:
	if auto_progress_active:
		return
	var today_game: GameData = _get_today_controlled_team_game()
	if today_game == null:
		progress_status_label.text = "今日は担当球団の試合がありません。"
		_refresh_view()
		return
	if bool(today_game.played):
		var finalize_report: Dictionary = LeagueState.finalize_current_day_if_ready()
		var transition_report: Array[String] = finalize_report.get("transition_report", [])
		progress_status_label.text = "今日の担当球団の試合はすでに消化済みです。"
		if not transition_report.is_empty():
			progress_status_label.text += "\n年越し: %s" % transition_report[0]
		_refresh_view()
		return
	LeagueState.simulate_non_controlled_games_for_current_day()
	LeagueState.set_selected_game(str(today_game.id))
	LeagueState.set_selected_match_mode("live")
	LeagueState.set_active_live_game(str(today_game.id))
	get_tree().change_scene_to_file(MATCH_SCENE_PATH)


func _on_sim_to_season_end_button_pressed() -> void:
	if auto_progress_active:
		return
	var phase: String = LeagueState.get_season_phase()
	var remaining_days: int = 1
	match phase:
		"preseason":
			remaining_days = maxi(1, LeagueState.get_first_game_day() - LeagueState.current_day)
		"regular":
			remaining_days = maxi(1, LeagueState.get_final_game_day() - LeagueState.current_day + 1)
		_:
			remaining_days = maxi(1, LeagueState.get_last_day() - LeagueState.current_day + 1)
	_simulate_multiple_days(remaining_days)


func _on_team_management_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(TEAM_MANAGEMENT_SCENE_PATH)


func _on_league_info_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(LEAGUE_INFO_SCENE_PATH)

func _on_calendar_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(CALENDAR_SCENE_PATH)


func _on_roster_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(ROSTER_VIEW_SCENE_PATH)


func _on_front_office_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH)


func _on_save_button_pressed() -> void:
	if LeagueState.save_to_file():
		progress_status_label.text = "セーブしました: user://save_01.json"
	else:
		progress_status_label.text = "セーブに失敗しました。"
	_refresh_view()


func _on_load_button_pressed() -> void:
	if LeagueState.load_from_file():
		progress_status_label.text = "ロードしました: user://save_01.json"
		if LeagueState.controlled_team_id == "":
			get_tree().call_deferred("change_scene_to_file", TEAM_SELECT_SCENE_PATH)
			return
	else:
		progress_status_label.text = "ロードに失敗しました。"
	_refresh_view()


func _get_today_controlled_team_game() -> GameData:
	if LeagueState.controlled_team_id == "":
		return null
	for game_value in LeagueState.get_games_for_day(LeagueState.current_day):
		var game: GameData = game_value
		if str(game.away_team_id) == LeagueState.controlled_team_id or str(game.home_team_id) == LeagueState.controlled_team_id:
			return game
	return null


func _get_latest_controlled_team_result_text() -> String:
	if LeagueState.controlled_team_id == "":
		return ""
	for target_day in range(LeagueState.current_day - 1, 0, -1):
		for game_value in LeagueState.get_games_for_day(target_day):
			var game: GameData = game_value
			if not bool(game.played):
				continue
			var involves_controlled: bool = str(game.away_team_id) == LeagueState.controlled_team_id or str(game.home_team_id) == LeagueState.controlled_team_id
			if not involves_controlled:
				continue
			var controlled_is_home: bool = str(game.home_team_id) == LeagueState.controlled_team_id
			var controlled_score: int = int(game.home_score) if controlled_is_home else int(game.away_score)
			var opponent_score: int = int(game.away_score) if controlled_is_home else int(game.home_score)
			var result_label: String = "引き分け"
			if controlled_score > opponent_score:
				result_label = "勝利"
			elif controlled_score < opponent_score:
				result_label = "敗戦"
			return "%s\n%s\n結果: %s" % [LeagueState.get_date_label_for_day(target_day), _format_result_line(game), result_label]
	return ""


func _append_latest_controlled_result_to_status(reference_date_label: String) -> void:
	var latest_result_text: String = _get_latest_controlled_team_result_text()
	if latest_result_text == "":
		return
	if reference_date_label == "" or latest_result_text.find(reference_date_label) >= 0:
		progress_status_label.text += "\n\n担当球団結果\n%s" % latest_result_text


func _get_team_name(team_id: String) -> String:
	var team: TeamData = LeagueState.get_team(team_id)
	return team.name if team != null else team_id


func _format_game_card(game: GameData) -> String:
	return "%s vs %s" % [_get_team_name(str(game.away_team_id)), _get_team_name(str(game.home_team_id))]


func _format_result_line(game: GameData) -> String:
	return "%s %d - %d %s" % [_get_team_name(str(game.away_team_id)), int(game.away_score), int(game.home_score), _get_team_name(str(game.home_team_id))]


func _get_phase_label(phase: String) -> String:
	match phase:
		"preseason":
			return "開幕前"
		"regular":
			return "シーズン中"
		"offseason":
			return "オフシーズン"
		_:
			return phase


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
