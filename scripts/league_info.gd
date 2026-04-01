extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var overview_title_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewTitleLabel
@onready var overview_detail_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewDetailLabel
@onready var controlled_team_title_label: Label = $RootScroll/MarginContainer/RootVBox/ControlledTeamTitleLabel
@onready var controlled_team_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ControlledTeamDetailLabel
@onready var season_status_title_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusTitleLabel
@onready var season_status_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SeasonStatusDetailLabel
@onready var leaders_title_label: Label = $RootScroll/MarginContainer/RootVBox/LeadersTitleLabel
@onready var batting_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/BattingLeadersLabel
@onready var pitching_leaders_label: Label = $RootScroll/MarginContainer/RootVBox/PitchingLeadersLabel
@onready var event_title_label: Label = $RootScroll/MarginContainer/RootVBox/EventTitleLabel
@onready var event_detail_label: Label = $RootScroll/MarginContainer/RootVBox/EventDetailLabel
@onready var schedule_title_label: Label = $RootScroll/MarginContainer/RootVBox/ScheduleTitleLabel
@onready var schedule_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/ScheduleVBox
@onready var standings_title_label: Label = $RootScroll/MarginContainer/RootVBox/StandingsTitleLabel
@onready var standings_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/StandingsVBox
@onready var recent_games_title_label: Label = $RootScroll/MarginContainer/RootVBox/RecentGamesTitleLabel
@onready var recent_games_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RecentGamesVBox
@onready var decision_title_label: Label = $RootScroll/MarginContainer/RootVBox/DecisionTitleLabel
@onready var decision_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DecisionDetailLabel
@onready var detailed_log_title_label: Label = $RootScroll/MarginContainer/RootVBox/DetailedLogTitleLabel
@onready var detailed_log_detail_label: Label = $RootScroll/MarginContainer/RootVBox/DetailedLogDetailLabel

var selected_game_id: String = ""
var recent_game_ids: Array[String] = []

func _ready() -> void:
	title_label.text = "リーグ情報"
	back_button.text = "ホームへ戻る"
	info_label.text = "リーグ全体の流れを確認する画面です。日付ベースの年間進行に合わせて、順位表、個人成績、ニュース、日程をまとめて確認できます。"
	overview_title_label.text = "リーグ概況"
	controlled_team_title_label.text = "担当球団の立ち位置"
	season_status_title_label.text = "シーズン状況"
	leaders_title_label.text = "リーグ個人成績"
	event_title_label.text = "ストリートニュース"
	schedule_title_label.text = "担当球団の年間日程"
	standings_title_label.text = "順位表"
	recent_games_title_label.text = "直近の試合一覧"
	decision_title_label.text = "試合結果"
	detailed_log_title_label.text = "試合詳細ログ"

	back_button.pressed.connect(_on_back_button_pressed)
	_refresh_view()

func _refresh_view() -> void:
	_refresh_overview()
	_refresh_controlled_team_summary()
	_refresh_season_status()
	_refresh_league_leaders()
	_refresh_daily_events()
	_refresh_controlled_team_schedule()
	_refresh_standings()
	_refresh_recent_games()
	_refresh_decision_summary()
	_refresh_detailed_log()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)

func _refresh_overview() -> void:
	var lines: Array[String] = []
	var sorted_teams: Array = LeagueState.get_teams_sorted_by_win_pct()
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	var phase: String = LeagueState.get_season_phase()
	lines.append("日付: %s" % LeagueState.get_current_date_label())
	match phase:
		"preseason":
			lines.append("状態: 開幕前")
		"regular":
			lines.append("状態: シーズン中")
		_:
			lines.append("状態: オフシーズン")
	if controlled_team != null:
		lines.append("担当球団: %s" % controlled_team.name)
	if not sorted_teams.is_empty():
		var leader: TeamData = sorted_teams[0]
		lines.append("首位: %s  %d勝 %d敗 %d分" % [leader.name, int(leader.standings["wins"]), int(leader.standings["losses"]), int(leader.standings["draws"])])

	var games_count: int = LeagueState.get_games_for_day(LeagueState.current_day).size()
	lines.append("今日の試合数: %d" % games_count)
	var next_game_day: int = LeagueState.get_next_game_day(LeagueState.current_day, LeagueState.controlled_team_id)
	if next_game_day >= 0:
		lines.append("担当球団の次戦: %s" % LeagueState.get_date_label_for_day(next_game_day))

	overview_detail_label.text = "\n".join(lines)

func _refresh_controlled_team_summary() -> void:
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	if controlled_team == null:
		controlled_team_detail_label.text = "担当球団はまだ設定されていません。"
		return

	var sorted_teams: Array = LeagueState.get_teams_sorted_by_win_pct()
	var rank: int = 0
	for i in range(sorted_teams.size()):
		var team: TeamData = sorted_teams[i]
		if team != null and str(team.id) == str(controlled_team.id):
			rank = i + 1
			break

	var lines: Array[String] = []
	lines.append("球団: %s" % controlled_team.name)
	if rank > 0:
		lines.append("順位: %d位" % rank)
	else:
		lines.append("順位: 集計中")
	lines.append("戦績: %d勝 %d敗 %d分" % [int(controlled_team.standings["wins"]), int(controlled_team.standings["losses"]), int(controlled_team.standings["draws"])])
	lines.append("得失点: %d / %d" % [int(controlled_team.standings["runs_for"]), int(controlled_team.standings["runs_against"])])
	lines.append("人気: %d  予算: %d" % [int(controlled_team.fan_support), int(controlled_team.budget)])
	if not sorted_teams.is_empty():
		var leader: TeamData = sorted_teams[0]
		if leader != null and str(leader.id) != str(controlled_team.id):
			var win_gap: int = int(leader.standings["wins"]) - int(controlled_team.standings["wins"])
			lines.append("首位との差: %d勝差" % win_gap)

	controlled_team_detail_label.text = "\n".join(lines)

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
			lines.append("年末を越えると自動で次年度へ移行します。")
	var latest_summary: Dictionary = LeagueState.get_latest_completed_season_summary()
	if not latest_summary.is_empty():
		lines.append("")
		lines.append("直近のシーズン記録")
		lines.append("%d年 優勝: %s / 最下位: %s" % [
			int(latest_summary.get("year", 0)),
			str(latest_summary.get("champion_name", "-")),
			str(latest_summary.get("last_place_name", "-"))
		])
		if str(latest_summary.get("controlled_team_name", "")) != "":
			lines.append("担当球団: %s  %d勝 %d敗 %d分" % [
				str(latest_summary.get("controlled_team_name", "")),
				int(latest_summary.get("controlled_wins", 0)),
				int(latest_summary.get("controlled_losses", 0)),
				int(latest_summary.get("controlled_draws", 0))
			])
		lines.append("打率王: %s  %.3f" % [
			str(latest_summary.get("avg_leader_name", "-")),
			float(latest_summary.get("avg_leader_value", 0.0))
		])
		lines.append("本塁打王: %s  %d本" % [
			str(latest_summary.get("hr_leader_name", "-")),
			int(latest_summary.get("hr_leader_value", 0))
		])
		lines.append("最多勝: %s  %d勝" % [
			str(latest_summary.get("win_leader_name", "-")),
			int(latest_summary.get("win_leader_value", 0))
		])
		lines.append("最多セーブ: %s  %dS" % [
			str(latest_summary.get("save_leader_name", "-")),
			int(latest_summary.get("save_leader_value", 0))
		])
	season_status_detail_label.text = "\n".join(lines)

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

func _find_team_by_runs_against(lowest: bool) -> TeamData:
	var best_team: TeamData = null
	for team_id in LeagueState.all_team_ids():
		var team: TeamData = LeagueState.get_team(team_id)
		if team == null:
			continue
		if best_team == null:
			best_team = team
			continue
		var team_runs: int = int(team.standings["runs_against"])
		var best_runs: int = int(best_team.standings["runs_against"])
		if lowest and team_runs < best_runs:
			best_team = team
		elif not lowest and team_runs > best_runs:
			best_team = team
	return best_team

func _refresh_league_leaders() -> void:
	var batting: Dictionary = LeagueState.get_league_batting_leaders(5)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(5)

	var batting_lines: Array[String] = ["打者部門", "", "打率"]
	for i in range(batting.get("avg", []).size()):
		var player = batting["avg"][i]
		batting_lines.append("%d. %s  %.3f" % [i + 1, player.full_name, player.get_batting_average()])
	batting_lines.append("")
	batting_lines.append("本塁打")
	for i in range(batting.get("hr", []).size()):
		var player = batting["hr"][i]
		batting_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.batting_stats["hr"])])
	batting_lines.append("")
	batting_lines.append("打点")
	for i in range(batting.get("rbi", []).size()):
		var player = batting["rbi"][i]
		batting_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.batting_stats["rbi"])])
	batting_leaders_label.text = "\n".join(batting_lines)

	var pitching_lines: Array[String] = ["投手部門", "", "勝利"]
	for i in range(pitching.get("wins", []).size()):
		var player = pitching["wins"][i]
		pitching_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.pitching_stats["wins"])])
	pitching_lines.append("")
	pitching_lines.append("セーブ")
	for i in range(pitching.get("saves", []).size()):
		var player = pitching["saves"][i]
		pitching_lines.append("%d. %s  %d" % [i + 1, player.full_name, int(player.pitching_stats["saves"])])
	pitching_lines.append("")
	pitching_lines.append("防御率")
	for i in range(pitching.get("era", []).size()):
		var player = pitching["era"][i]
		pitching_lines.append("%d. %s  %.2f" % [i + 1, player.full_name, player.get_era()])
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

func _refresh_controlled_team_schedule() -> void:
	for child in schedule_vbox.get_children():
		child.queue_free()

	var controlled_team: TeamData = LeagueState.get_controlled_team()
	if controlled_team == null:
		_add_message_label(schedule_vbox, "担当球団が未設定のため、年間日程を表示できません。")
		return

	_add_message_label(schedule_vbox, "%s の年間日程" % controlled_team.name)

	var month_headers: Dictionary = {}
	var month_stats: Dictionary = {}
	var team_games: Array = []
	for game in LeagueState.schedule:
		var is_team_game: bool = str(game.away_team_id) == str(controlled_team.id) or str(game.home_team_id) == str(controlled_team.id)
		if not is_team_game:
			continue
		team_games.append(game)

	if team_games.is_empty():
		_add_message_label(schedule_vbox, "担当球団の年間日程データがありません。")
		return

	var previous_year: int = -1
	var previous_month: int = -1
	var previous_day_of_month: int = -1
	for game in team_games:
		if previous_year != -1:
			var rest_cursor: Dictionary = _advance_local_date(previous_year, previous_month, previous_day_of_month)
			while not _is_same_date(rest_cursor, int(game.season_year), int(game.month), int(game.day_of_month)):
				var rest_year: int = int(rest_cursor["year"])
				var rest_month: int = int(rest_cursor["month"])
				var rest_day: int = int(rest_cursor["day"])
				var rest_weekday: int = LeagueState._get_weekday_index(rest_year, rest_month, rest_day)
				var rest_month_key: String = "%04d-%02d" % [rest_year, rest_month]
				_ensure_schedule_month(month_headers, month_stats, rest_month_key)
				month_headers[rest_month_key].append({
					"type": "rest",
					"text": "%s  休養日" % LeagueState._build_date_label(rest_year, rest_month, rest_day, rest_weekday)
				})
				rest_cursor = _advance_local_date(rest_year, rest_month, rest_day)

		var month_key: String = "%04d-%02d" % [int(game.season_year), int(game.month)]
		_ensure_schedule_month(month_headers, month_stats, month_key)

		var venue_label: String = "vs"
		var opponent_name: String = ""
		if str(game.home_team_id) == str(controlled_team.id):
			venue_label = "vs"
			opponent_name = _get_team_name(str(game.away_team_id))
		else:
			venue_label = "@"
			opponent_name = _get_team_name(str(game.home_team_id))

		var result_label: String = "未消化"
		if bool(game.played):
			var team_score: int = int(game.home_score) if str(game.home_team_id) == str(controlled_team.id) else int(game.away_score)
			var opp_score: int = int(game.away_score) if str(game.home_team_id) == str(controlled_team.id) else int(game.home_score)
			if team_score > opp_score:
				result_label = "○ %d-%d" % [team_score, opp_score]
				month_stats[month_key]["wins"] = int(month_stats[month_key]["wins"]) + 1
			elif team_score < opp_score:
				result_label = "● %d-%d" % [team_score, opp_score]
				month_stats[month_key]["losses"] = int(month_stats[month_key]["losses"]) + 1
			else:
				result_label = "△ %d-%d" % [team_score, opp_score]
				month_stats[month_key]["draws"] = int(month_stats[month_key]["draws"]) + 1
			month_stats[month_key]["games"] = int(month_stats[month_key]["games"]) + 1

		var current_marker: String = ""
		if int(game.day) == LeagueState.current_day:
			current_marker = " <- 今日"
		elif int(game.day) == LeagueState.current_day - 1:
			current_marker = " <- 昨日"

		month_headers[month_key].append({
			"type": "game",
			"game_id": str(game.id),
			"text": "%s  %s %s  %s%s" % [
				str(game.date_label),
				venue_label,
				opponent_name,
				result_label,
				current_marker
			]
		})
		previous_year = int(game.season_year)
		previous_month = int(game.month)
		previous_day_of_month = int(game.day_of_month)

	var ordered_months: Array[String] = []
	for month_key_variant in month_headers.keys():
		ordered_months.append(str(month_key_variant))
	ordered_months.sort()
	for month_key in ordered_months:
		var display_month: String = month_key.replace("-", "年") + "月"
		var stats: Dictionary = month_stats[month_key]
		_add_section_label(schedule_vbox, display_month)
		_add_message_label(schedule_vbox, "月間成績: %d勝 %d敗 %d分  消化:%d" % [
			int(stats["wins"]),
			int(stats["losses"]),
			int(stats["draws"]),
			int(stats["games"])
		])
		for entry in month_headers[month_key]:
			if str(entry.get("type", "")) == "game":
				_add_schedule_game_button(str(entry.get("text", "")), str(entry.get("game_id", "")))
			else:
				_add_schedule_note(str(entry.get("text", "")))
		_add_schedule_note("")

func _ensure_schedule_month(month_headers: Dictionary, month_stats: Dictionary, month_key: String) -> void:
	if month_headers.has(month_key):
		return
	month_headers[month_key] = []
	month_stats[month_key] = {
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"games": 0
	}

func _advance_local_date(year: int, month: int, day_of_month: int) -> Dictionary:
	var next_year: int = year
	var next_month: int = month
	var next_day: int = day_of_month + 1
	var days_in_month: int = _get_days_in_month_local(next_year, next_month)
	if next_day > days_in_month:
		next_day = 1
		next_month += 1
		if next_month > 12:
			next_month = 1
			next_year += 1
	return {
		"year": next_year,
		"month": next_month,
		"day": next_day
	}

func _get_days_in_month_local(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			if _is_leap_year_local(year):
				return 29
			return 28
		_:
			return 30

func _is_leap_year_local(year: int) -> bool:
	if year % 400 == 0:
		return true
	if year % 100 == 0:
		return false
	return year % 4 == 0

func _is_same_date(date_dict: Dictionary, year: int, month: int, day_of_month: int) -> bool:
	return int(date_dict["year"]) == year and int(date_dict["month"]) == month and int(date_dict["day"]) == day_of_month

func _refresh_standings() -> void:
	for child in standings_vbox.get_children():
		child.queue_free()

	var summaries: Array = LeagueState.get_league_team_summaries()
	if summaries.is_empty():
		_add_message_label(standings_vbox, "順位表データがありません")
		return

	if LeagueState.controlled_team_id != "":
		var legend_label: Label = Label.new()
		legend_label.custom_minimum_size = Vector2(0, 28)
		legend_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		legend_label.text = "* は担当球団"
		standings_vbox.add_child(legend_label)

	var header_label: Label = Label.new()
	header_label.custom_minimum_size = Vector2(0, 28)
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_label.text = "順位  球団名  勝  敗  分  得  失  勝率  総合"
	standings_vbox.add_child(header_label)

	for i in range(summaries.size()):
		var summary: Dictionary = summaries[i]
		var label: Label = Label.new()
		label.custom_minimum_size = Vector2(0, 28)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var team_id: String = str(summary["id"])
		var prefix: String = "%d." % [i + 1]
		if team_id == LeagueState.controlled_team_id:
			prefix = "%d.*" % [i + 1]
		label.text = "%s %-10s  %2s  %2s  %2s  %3s  %3s  %.3f  %.1f" % [
			prefix,
			str(summary["name"]),
			str(summary["wins"]),
			str(summary["losses"]),
			str(summary["draws"]),
			str(summary["runs_for"]),
			str(summary["runs_against"]),
			float(summary["win_pct"]),
			float(summary["total"])
		]
		standings_vbox.add_child(label)

func _refresh_recent_games() -> void:
	for child in recent_games_vbox.get_children():
		child.queue_free()

	recent_game_ids.clear()
	var target_day: int = _get_recent_game_day()
	if target_day <= 0:
		_add_message_label(recent_games_vbox, "まだ試合は行われていません")
		selected_game_id = ""
		return

	var games: Array = []
	for game in LeagueState.schedule:
		if int(game.day) == target_day:
			games.append(game)
			recent_game_ids.append(str(game.id))

	if games.is_empty():
		_add_message_label(recent_games_vbox, "直近の試合データがありません")
		selected_game_id = ""
		return

	if selected_game_id == "" or not recent_game_ids.has(selected_game_id):
		selected_game_id = recent_game_ids[0]

	recent_games_title_label.text = "直近の試合一覧 (%s)" % LeagueState.get_date_label_for_day(target_day)
	if LeagueState.controlled_team_id != "":
		var controlled_header: Label = Label.new()
		controlled_header.custom_minimum_size = Vector2(0, 28)
		controlled_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		controlled_header.text = "担当球団の試合を含む日を表示中"
		recent_games_vbox.add_child(controlled_header)
	for game in games:
		var button: Button = Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = str(game.id) == selected_game_id
		var away_name: String = _get_team_name(str(game.away_team_id))
		var home_name: String = _get_team_name(str(game.home_team_id))
		button.text = "%s %d - %d %s" % [away_name, int(game.away_score), int(game.home_score), home_name]
		button.pressed.connect(_on_recent_game_pressed.bind(str(game.id)))
		recent_games_vbox.add_child(button)

func _get_recent_game_day() -> int:
	if LeagueState.schedule.is_empty():
		return 0
	var search_day: int = mini(LeagueState.current_day - 1, LeagueState.get_last_day())
	while search_day >= 1:
		var games: Array = LeagueState.get_games_for_day(search_day)
		for game in games:
			if bool(game.played):
				return search_day
		search_day -= 1
	return 0

func _on_recent_game_pressed(game_id: String) -> void:
	selected_game_id = game_id
	_refresh_recent_games()
	_refresh_controlled_team_schedule()
	_refresh_decision_summary()
	_refresh_detailed_log()

func _refresh_decision_summary() -> void:
	if selected_game_id == "":
		decision_detail_label.text = "試合を選ぶと結果を表示します"
		return
	var game = _get_game_by_id(selected_game_id)
	if game == null:
		decision_detail_label.text = "試合データが見つかりません"
		return
	if not bool(game.played):
		var away_future_name: String = _get_team_name(str(game.away_team_id))
		var home_future_name: String = _get_team_name(str(game.home_team_id))
		decision_detail_label.text = "試合結果: %s vs %s\nこの試合はまだ未消化です" % [away_future_name, home_future_name]
		return
	var away_name: String = _get_team_name(str(game.away_team_id))
	var home_name: String = _get_team_name(str(game.home_team_id))
	decision_detail_label.text = "試合結果: %s %d - %d %s\n勝利投手: %s\n敗戦投手: %s\nセーブ投手: %s" % [away_name, int(game.away_score), int(game.home_score), home_name, _get_player_name(str(game.winning_pitcher_id)), _get_player_name(str(game.losing_pitcher_id)), _get_player_name(str(game.save_pitcher_id))]

func _refresh_detailed_log() -> void:
	if selected_game_id == "":
		detailed_log_detail_label.text = "試合を選ぶと詳細ログを表示します"
		return
	var game = _get_game_by_id(selected_game_id)
	if game == null:
		detailed_log_detail_label.text = "試合ログが見つかりません"
		return
	if not bool(game.played):
		detailed_log_detail_label.text = "この試合はまだ未消化です"
		return
	if game.log_lines.is_empty():
		detailed_log_detail_label.text = "詳細ログはまだありません"
		return
	detailed_log_detail_label.text = "\n".join(game.log_lines)

func _add_section_label(container: VBoxContainer, message: String) -> void:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(0, 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	container.add_child(label)

func _add_schedule_note(message: String) -> void:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(0, 28)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	schedule_vbox.add_child(label)

func _add_schedule_game_button(message: String, game_id: String) -> void:
	var button: Button = Button.new()
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.button_pressed = game_id == selected_game_id
	button.text = message
	button.pressed.connect(_on_recent_game_pressed.bind(game_id))
	schedule_vbox.add_child(button)

func _get_game_by_id(game_id: String):
	for game in LeagueState.schedule:
		if str(game.id) == game_id:
			return game
	return null

func _get_player_name(player_id: String) -> String:
	if player_id == "":
		return "なし"
	var player = LeagueState.get_player(player_id)
	if player == null:
		return player_id
	return player.full_name

func _get_team_name(team_id: String) -> String:
	if team_id == "":
		return "不明"
	var team = LeagueState.get_team(team_id)
	if team == null:
		return team_id
	return team.name

func _add_message_label(container: VBoxContainer, message: String) -> void:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(0, 32)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = message
	container.add_child(label)
