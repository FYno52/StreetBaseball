extends Control

const TEAM_SELECT_SCENE_PATH := "res://scenes/TeamSelect.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const LEAGUE_INFO_SCENE_PATH := "res://scenes/LeagueInfo.tscn"
const CALENDAR_SCENE_PATH := "res://scenes/CalendarScene.tscn"
const ROSTER_VIEW_SCENE_PATH := "res://scenes/RosterView.tscn"
const MATCH_SCENE_PATH := "res://scenes/MatchScene.tscn"
const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const RECORD_ROOM_SCENE_PATH := "res://scenes/RecordRoom.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var nav_info_label: Label = $RootScroll/MarginContainer/RootVBox/NavInfoLabel
@onready var nav_buttons_hbox: HBoxContainer = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox
@onready var team_management_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/TeamManagementButton
@onready var league_info_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/LeagueInfoButton
@onready var calendar_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/CalendarButton
@onready var roster_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/RosterButton
@onready var front_office_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/FrontOfficeButton
@onready var record_room_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/RecordRoomButton
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
@onready var standings_tab_button: Button = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/LeftTabButtonsHBox/StandingsTabButton
@onready var leaders_tab_button: Button = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftContentVBox/LeftTabButtonsHBox/LeadersTabButton

var auto_progress_active: bool = false
var milestone_progress_active: bool = false
var current_left_tab: String = "standings"


func _ready() -> void:
	if LeagueState.teams.is_empty() or LeagueState.schedule.is_empty():
		LeagueState.new_game()
	if LeagueState.controlled_team_id == "":
		get_tree().call_deferred("change_scene_to_file", TEAM_SELECT_SCENE_PATH)
		return

	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "home",
		"section_label": "DASHBOARD",
		"sub_tab": "dashboard",
		"sub_tabs": [
			{"key": "dashboard", "label": "DASHBOARD", "scene": "res://scenes/LeagueHome.tscn"},
			{"key": "calendar", "label": "CALENDAR", "scene": CALENDAR_SCENE_PATH},
			{"key": "records", "label": "RECORDS", "scene": RECORD_ROOM_SCENE_PATH}
		],
		"top_right": "HOME"
	})
	_setup_static_text()
	_connect_buttons()
	var pending_message: String = LeagueState.consume_pending_home_message()
	if pending_message != "":
		progress_status_label.text = pending_message
	_refresh_view()


func _exit_tree() -> void:
	auto_progress_active = false


func _connect_buttons() -> void:
	standings_tab_button.pressed.connect(_on_left_tab_pressed.bind("standings"))
	leaders_tab_button.pressed.connect(_on_left_tab_pressed.bind("leaders"))
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
	title_label.visible = false
	nav_buttons_hbox.visible = false
	team_management_button.text = "チーム管理へ"
	league_info_button.text = "リーグ情報へ"
	calendar_button.text = "年間カレンダーへ"
	roster_button.text = "選手一覧へ"
	front_office_button.text = "球団運営へ"
	record_room_button.text = "記録室へ"
	standings_tab_button.text = "リーグ順位"
	leaders_tab_button.text = "個人成績"
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
	var today_games: Array = LeagueState.get_games_for_day(LeagueState.current_day)
	var yesterday_games: Array = []
	if LeagueState.current_day > 1:
		yesterday_games = LeagueState.get_games_for_day(LeagueState.current_day - 1)
	var today_controlled_game: GameData = _find_controlled_game_in_list(today_games)
	var latest_result_text: String = _get_latest_controlled_team_result_text()

	nav_info_label.text = "日付: %s / 担当球団: %s" % [LeagueState.get_current_date_label(), controlled_name]

	_refresh_season_status()
	_refresh_focus_team_summary(latest_result_text)
	_refresh_today_summary(today_games, today_controlled_game)
	_refresh_yesterday_summary(yesterday_games)
	_refresh_home_digest()
	_refresh_league_leaders()
	_refresh_daily_events()
	_refresh_note_summary(today_controlled_game)
	_refresh_progress_buttons(today_controlled_game)


func _refresh_season_status() -> void:
	var first_game_day: int = LeagueState.get_first_game_day()
	var final_game_day: int = LeagueState.get_final_game_day()
	var phase: String = LeagueState.get_season_phase()
	var current_date_label: String = LeagueState.get_current_date_label()
	var active_sections: Array[String] = _get_active_front_office_sections()
	var milestone: Dictionary = LeagueState.get_next_calendar_milestone()
	var lines: Array[String] = []
	lines.append("%d年" % LeagueState.season_year)
	lines.append("状態: %s" % _get_phase_label(phase))
	lines.append("今日: %s" % LeagueState.get_calendar_summary_text())
	if not milestone.is_empty():
		lines.append("次の節目: %s" % str(milestone.get("label", "年越し")))
	if phase == "preseason" and first_game_day > 0:
		lines.append("開幕予定: %s" % LeagueState.get_date_label_for_day(first_game_day))
	elif phase == "regular" and final_game_day > 0:
		lines.append("最終戦予定: %s" % LeagueState.get_date_label_for_day(final_game_day))
	if not active_sections.is_empty():
		lines.append("今が使いどき: %s" % " / ".join(active_sections))

	season_status_detail_label.text = "\n".join(lines)


func _refresh_focus_team_summary(latest_result_text: String = "") -> void:
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
	lines.append("人気: %d / 予算: %d" % [team.fan_support, team.budget])
	lines.append("主力: %s / %s" % [ace_name, core_batter_name])

	if latest_result_text != "":
		lines.append("直近結果: %s" % latest_result_text)

	focus_team_detail_label.text = "\n".join(lines)


func _refresh_today_summary(today_games: Array = [], controlled_game: GameData = null) -> void:
	var calendar_summary: String = LeagueState.get_calendar_summary_text()
	var direct_hint: String = _get_home_direct_hint()
	if today_games.is_empty():
		var no_game_lines: Array[String] = ["今日は試合なし", calendar_summary]
		if direct_hint != "":
			no_game_lines.append("導線: %s" % direct_hint)
		today_detail_label.text = "\n".join(no_game_lines)
		return

	var lines: Array[String] = []
	if controlled_game != null:
		lines.append("担当球団: %s" % _format_game_card(controlled_game))
	else:
		lines.append("本日 %d試合" % today_games.size())
	lines.append(calendar_summary)
	if direct_hint != "":
		lines.append("導線: %s" % direct_hint)
	today_detail_label.text = "\n".join(lines)


func _refresh_yesterday_summary(yesterday_games: Array = []) -> void:
	var target_day: int = LeagueState.current_day - 1
	if target_day < 1:
		yesterday_detail_label.text = "まだ試合結果はありません。"
		return

	var results: Array[String] = []
	var controlled_lines: Array[String] = []
	for game_value in yesterday_games:
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
	else:
		lines.append("%s" % LeagueState.get_date_label_for_day(target_day))
		lines.append(results[0])

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
	var lines: Array[String] = []
	for i in range(mini(6, standings.size())):
		var team: TeamData = standings[i]
		var mark: String = "*" if str(team.id) == LeagueState.controlled_team_id else ""
		lines.append("%d. %s%s  %d勝 %d敗 %d分" % [
			i + 1,
			team.name,
			mark,
			int(team.standings["wins"]),
			int(team.standings["losses"]),
			int(team.standings["draws"])
		])
	digest_detail_label.text = "\n".join(lines)


func _find_team_by_runs_for(highest: bool) -> TeamData:
	var best_team: TeamData = null
	for team_id in LeagueState.all_team_ids():
		var team: TeamData = LeagueState.get_team(team_id)
		if team == null:
			continue
		if best_team == null:
			best_team = team
			continue
		var team_runs: int = int(team.standings["runs_for"])
		var best_runs: int = int(best_team.standings["runs_for"])
		if highest and team_runs > best_runs:
			best_team = team
		elif not highest and team_runs < best_runs:
			best_team = team
	return best_team


func _refresh_league_leaders() -> void:
	standings_tab_button.toggle_mode = true
	leaders_tab_button.toggle_mode = true
	standings_tab_button.button_pressed = current_left_tab == "standings"
	leaders_tab_button.button_pressed = current_left_tab == "leaders"
	var show_standings: bool = current_left_tab == "standings"
	digest_title_label.visible = true
	digest_detail_label.visible = show_standings
	leaders_title_label.visible = not show_standings
	batting_leaders_label.visible = not show_standings
	pitching_leaders_label.visible = not show_standings
	digest_title_label.text = "リーグ順位" if show_standings else ""
	leaders_title_label.text = "個人成績"
	if show_standings:
		return
	var batting: Dictionary = LeagueState.get_league_batting_leaders(3)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(3)
	var batting_lines: Array[String] = ["打者部門"]
	var avg_players: Array = batting.get("avg", [])
	var hr_players: Array = batting.get("hr", [])
	if not avg_players.is_empty():
		batting_lines.append("打率: %s %.3f" % [avg_players[0].full_name, avg_players[0].get_batting_average()])
	if not hr_players.is_empty():
		batting_lines.append("本塁打: %s %d" % [hr_players[0].full_name, int(hr_players[0].batting_stats["hr"])])
	var pitching_lines: Array[String] = ["投手部門"]
	var win_players: Array = pitching.get("wins", [])
	var save_players: Array = pitching.get("saves", [])
	var era_players: Array = pitching.get("era", [])
	if not win_players.is_empty():
		pitching_lines.append("勝利: %s %d" % [win_players[0].full_name, int(win_players[0].pitching_stats["wins"])])
	if not save_players.is_empty():
		pitching_lines.append("セーブ: %s %d" % [save_players[0].full_name, int(save_players[0].pitching_stats["saves"])])
	if not era_players.is_empty():
		pitching_lines.append("防御率: %s %.2f" % [era_players[0].full_name, era_players[0].get_era()])
	batting_leaders_label.text = "\n".join(batting_lines)
	pitching_leaders_label.text = "\n".join(pitching_lines)


func _on_left_tab_pressed(tab_key: String) -> void:
	current_left_tab = tab_key
	_refresh_home_digest()
	_refresh_league_leaders()


func _refresh_daily_events() -> void:
	var events: Array[String] = LeagueState.get_recent_events()
	if events.is_empty():
		event_detail_label.text = "今日は大きなニュースはありません。"
		return
	event_detail_label.text = "\n".join(events.slice(0, mini(3, events.size())))


func _refresh_note_summary(today_game: GameData = null) -> void:
	var lines: Array[String] = []
	var phase: String = LeagueState.get_season_phase()
	var direct_hint: String = _get_home_direct_hint()
	lines.append("状態: %s" % _get_phase_label(phase))
	if today_game != null and not bool(today_game.played):
		lines.append("今日は担当球団の試合があります。")
		if LeagueState.is_active_live_game(str(today_game.id)):
			lines.append("この試合はライブ進行中です。試合確定まで再入場できません。")
	elif today_game != null and bool(today_game.played):
		lines.append("担当球団の今日の試合は消化済みです。")
	else:
		lines.append("今日は担当球団の試合はありません。")

	if direct_hint != "":
		lines.append("おすすめ導線: %s" % direct_hint)
	note_detail_label.text = "\n".join(lines)


func _refresh_progress_buttons(today_game: GameData = null) -> void:
	var has_calendar_days: bool = LeagueState.current_day <= LeagueState.get_last_day()
	var phase: String = LeagueState.get_season_phase()
	var live_locked: bool = today_game != null and LeagueState.is_active_live_game(str(today_game.id))
	var can_open_live: bool = phase == "regular" and today_game != null and not bool(today_game.played) and not live_locked
	var progress_locked: bool = auto_progress_active or milestone_progress_active
	sim_day_button.disabled = progress_locked or not has_calendar_days
	sim_week_button.disabled = progress_locked or not has_calendar_days
	sim_to_next_game_button.disabled = progress_locked or phase != "regular"
	live_game_button.disabled = progress_locked or not can_open_live
	sim_to_season_end_button.disabled = progress_locked or not has_calendar_days
	save_button.disabled = progress_locked
	load_button.disabled = progress_locked
	sim_auto_button.text = "オート停止" if auto_progress_active else "オート進行"
	front_office_button.text = _get_front_office_button_text()
	var milestone: Dictionary = LeagueState.get_next_calendar_milestone()
	var button_label: String = str(milestone.get("button_label", "次の節目まで"))
	sim_to_season_end_button.text = button_label


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
	if LeagueState.get_season_phase() != "regular":
		progress_status_label.text = "ライブ試合はレギュラーシーズン中のみ入れます。"
		_refresh_view()
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
	if auto_progress_active or milestone_progress_active:
		return
	var milestone: Dictionary = LeagueState.get_next_calendar_milestone()
	var milestone_label: String = str(milestone.get("progress_label", str(milestone.get("label", "節目"))))
	var target_day: int = int(milestone.get("target_day", LeagueState.current_day))
	var inclusive_target: bool = milestone_label == "年越し"
	var remaining_days: int = maxi(0, target_day - LeagueState.current_day + (1 if inclusive_target else 0))
	if remaining_days <= 0:
		progress_status_label.text = "今日は %s の節目です。" % milestone_label
		_refresh_progress_buttons()
		return
	milestone_progress_active = true
	_refresh_progress_buttons()
	progress_status_label.text = "%s まで進行中..." % milestone_label
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_simulate_multiple_days(remaining_days)
	progress_status_label.text = "%s まで到達しました。\n%s" % [milestone_label, progress_status_label.text]
	milestone_progress_active = false
	_refresh_progress_buttons()


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


func _on_record_room_button_pressed() -> void:
	auto_progress_active = false
	get_tree().change_scene_to_file(RECORD_ROOM_SCENE_PATH)


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


func _find_controlled_game_in_list(games: Array) -> GameData:
	if LeagueState.controlled_team_id == "":
		return null
	for game_value in games:
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

func _get_active_front_office_sections() -> Array[String]:
	var active_sections: Array[String] = []
	if LeagueState.is_contract_period():
		active_sections.append("契約更改")
	if LeagueState.is_fa_period():
		active_sections.append("FA交渉")
	if LeagueState.is_draft_prep_period() or LeagueState.is_draft_day():
		active_sections.append("スカウト・ドラフト")
	if LeagueState.is_sponsor_period():
		active_sections.append("スポンサー営業")
	if LeagueState.is_staff_review_period():
		active_sections.append("スタッフ整理")
	return active_sections

func _get_front_office_button_text() -> String:
	var active_sections: Array[String] = _get_active_front_office_sections()
	if active_sections.is_empty():
		return "球団運営へ"
	return "球団運営へ [%s]" % active_sections[0]

func _get_home_direct_hint() -> String:
	var active_sections: Array[String] = _get_active_front_office_sections()
	if active_sections.is_empty():
		return "年間カレンダーや球団運営で次のイベントに備えられます。"
	return "今は「球団運営へ」から %s を進めるのがおすすめです。" % " / ".join(active_sections)
