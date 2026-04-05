extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const WEEKDAY_NAMES: Array[String] = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
const MONTH_LABELS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

@onready var top_menu_label: Label = $RootMargin/RootVBox/TopBarPanel/TopBarMargin/TopBarHBox/TopMenuLabel
@onready var top_center_label: Label = $RootMargin/RootVBox/TopBarPanel/TopBarMargin/TopBarHBox/TopCenterLabel
@onready var top_right_label: Label = $RootMargin/RootVBox/TopBarPanel/TopBarMargin/TopBarHBox/TopRightLabel
@onready var logo_label: Label = $RootMargin/RootVBox/HeaderPanel/HeaderMargin/HeaderHBox/LogoPanel/LogoLabel
@onready var team_name_label: Label = $RootMargin/RootVBox/HeaderPanel/HeaderMargin/HeaderHBox/TeamSummaryVBox/TeamNameLabel
@onready var team_record_label: Label = $RootMargin/RootVBox/HeaderPanel/HeaderMargin/HeaderHBox/TeamSummaryVBox/TeamRecordLabel
@onready var schedule_info_label: Label = $RootMargin/RootVBox/HeaderPanel/HeaderMargin/HeaderHBox/HeaderRightVBox/ScheduleInfoLabel
@onready var continue_button: Button = $RootMargin/RootVBox/HeaderPanel/HeaderMargin/HeaderHBox/HeaderRightVBox/ContinueButton
@onready var primary_home_label: Label = $RootMargin/RootVBox/PrimaryTabsPanel/PrimaryTabsMargin/PrimaryTabsHBox/PrimaryHomeLabel
@onready var primary_organization_label: Label = $RootMargin/RootVBox/PrimaryTabsPanel/PrimaryTabsMargin/PrimaryTabsHBox/PrimaryOrganizationLabel
@onready var primary_scouting_label: Label = $RootMargin/RootVBox/PrimaryTabsPanel/PrimaryTabsMargin/PrimaryTabsHBox/PrimaryScoutingLabel
@onready var primary_info_label: Label = $RootMargin/RootVBox/PrimaryTabsPanel/PrimaryTabsMargin/PrimaryTabsHBox/PrimaryInfoLabel
@onready var back_button: Button = $RootMargin/RootVBox/SecondaryTabsPanel/SecondaryTabsMargin/SecondaryTabsHBox/BackButton
@onready var schedule_tab_title_label: Label = $RootMargin/RootVBox/SecondaryTabsPanel/SecondaryTabsMargin/SecondaryTabsHBox/ScheduleTabTitleLabel
@onready var events_tab_button: Button = $RootMargin/RootVBox/SecondaryTabsPanel/SecondaryTabsMargin/SecondaryTabsHBox/EventsTabButton
@onready var schedule_tab_button: Button = $RootMargin/RootVBox/SecondaryTabsPanel/SecondaryTabsMargin/SecondaryTabsHBox/ScheduleTabButton
@onready var calendar_title_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarHeaderHBox/CalendarTitleLabel
@onready var today_info_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarHeaderHBox/TodayInfoLabel
@onready var month_tabs_hbox: HBoxContainer = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/MonthTabsHBox
@onready var week_header_grid: GridContainer = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/CalendarMainVBox/WeekHeaderGrid
@onready var month_calendar_grid: GridContainer = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/CalendarMainVBox/MonthCalendarGrid
@onready var legend_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/CalendarMainVBox/LegendLabel
@onready var month_summary_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/MonthSummaryLabel
@onready var upcoming_title_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/UpcomingTitleLabel
@onready var upcoming_detail_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/UpcomingDetailLabel
@onready var monthly_events_title_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/MonthlyEventsTitleLabel
@onready var monthly_events_detail_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/MonthlyEventsDetailLabel
@onready var schedule_title_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/ScheduleTitleLabel
@onready var schedule_detail_label: Label = $RootMargin/RootVBox/ContentPanel/ContentMargin/ContentVBox/CalendarColumns/DetailSidebar/ScheduleDetailLabel

var _selected_month: int = 1
var _selected_day: int = -1
var _current_detail_tab: String = "events"
var _month_buttons: Dictionary = {}


func _ready() -> void:
	_setup_static_text()
	_build_week_headers()
	_build_month_tabs()
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOME_SCENE_PATH))
	continue_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOME_SCENE_PATH))
	events_tab_button.pressed.connect(func() -> void: _on_detail_tab_pressed("events"))
	schedule_tab_button.pressed.connect(func() -> void: _on_detail_tab_pressed("schedule"))
	_selected_month = _get_current_month()
	_selected_day = LeagueState.current_day
	_refresh_view()


func _setup_static_text() -> void:
	top_menu_label.text = "FILE    GAME    LEAGUE    CLUB"
	top_center_label.text = "STREET BASEBALL SEASON    %s" % LeagueState.get_current_date_label()
	top_right_label.text = "CALENDAR"
	primary_home_label.text = "HOME"
	primary_organization_label.text = "ORGANIZATION"
	primary_scouting_label.text = "SCOUTING"
	primary_info_label.text = "INFO"
	back_button.text = "HOME"
	schedule_tab_title_label.text = "SCHEDULE"
	events_tab_button.text = "EVENTS"
	schedule_tab_button.text = "GAMES"
	calendar_title_label.text = "TEAM SCHEDULE"
	upcoming_title_label.text = "UPCOMING"
	monthly_events_title_label.text = "SELECTED DAY / EVENTS"
	schedule_title_label.text = "SELECTED DAY / GAMES"
	legend_label.text = "試 = 試合日   事 = 年間イベント   今 = 今日"
	continue_button.text = "CONTINUE"


func _build_week_headers() -> void:
	for child in week_header_grid.get_children():
		child.queue_free()
	for weekday_name in WEEKDAY_NAMES:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = weekday_name
		week_header_grid.add_child(label)


func _build_month_tabs() -> void:
	for child in month_tabs_hbox.get_children():
		child.queue_free()
	_month_buttons.clear()
	for month in range(1, 13):
		var button := Button.new()
		button.text = MONTH_LABELS[month - 1]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(46, 24)
		button.pressed.connect(_on_month_button_pressed.bind(month))
		month_tabs_hbox.add_child(button)
		_month_buttons[month] = button


func _on_month_button_pressed(month: int) -> void:
	_selected_month = month
	_selected_day = _find_first_day_in_month(month)
	_refresh_view()


func _on_day_button_pressed(day: int) -> void:
	_selected_day = day
	_refresh_month_calendar()
	_refresh_detail_panel()


func _on_detail_tab_pressed(tab_key: String) -> void:
	_current_detail_tab = tab_key
	_refresh_detail_panel()


func _refresh_view() -> void:
	_refresh_header()
	_refresh_month_tabs()
	_refresh_month_summary()
	_refresh_upcoming()
	_refresh_month_calendar()
	_refresh_detail_panel()


func _refresh_header() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		logo_label.text = "--"
		team_name_label.text = "TEAM NOT SELECTED"
		team_record_label.text = "担当球団が未設定です"
		schedule_info_label.text = "TODAY   予定はありません"
		today_info_label.text = ""
		return

	logo_label.text = team.short_name.substr(0, min(team.short_name.length(), 2)).to_upper()
	team_name_label.text = team.name
	var standings: Dictionary = team.standings
	team_record_label.text = "%d-%d-%d   RF %d / RA %d   FAN %d   BUDGET %d" % [
		int(standings.get("wins", 0)),
		int(standings.get("losses", 0)),
		int(standings.get("draws", 0)),
		int(standings.get("runs_for", 0)),
		int(standings.get("runs_against", 0)),
		int(team.fan_support),
		int(team.budget)
	]

	var header_lines: Array[String] = []
	var yesterday_label: String = _build_relative_game_line(LeagueState.current_day - 1, "YESTERDAY")
	var today_label: String = _build_relative_game_line(LeagueState.current_day, "TODAY")
	var tomorrow_label: String = _build_relative_game_line(LeagueState.current_day + 1, "TOMORROW")
	if yesterday_label != "":
		header_lines.append(yesterday_label)
	if today_label != "":
		header_lines.append(today_label)
	if tomorrow_label != "":
		header_lines.append(tomorrow_label)
	if header_lines.is_empty():
		header_lines.append("TODAY   担当球団の試合予定はありません")
	schedule_info_label.text = "\n".join(header_lines)

	var phase: Dictionary = LeagueState.get_year_cycle_summary()
	today_info_label.text = "%s   |   %s" % [
		LeagueState.get_current_date_label(),
		str(phase.get("label", ""))
	]


func _build_relative_game_line(day: int, prefix: String) -> String:
	if day <= 0 or day > LeagueState.get_last_day():
		return ""
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return ""
	for game_value in LeagueState.get_games_for_day(day):
		var game: GameData = game_value
		if game == null:
			continue
		if str(game.away_team_id) != str(team.id) and str(game.home_team_id) != str(team.id):
			continue
		var opponent_name := ""
		if str(game.home_team_id) == str(team.id):
			var away_team: TeamData = LeagueState.get_team(str(game.away_team_id))
			opponent_name = "vs %s" % (away_team.name if away_team != null else str(game.away_team_id))
		else:
			var home_team: TeamData = LeagueState.get_team(str(game.home_team_id))
			opponent_name = "@ %s" % (home_team.name if home_team != null else str(game.home_team_id))
		var result_text := "未消化"
		if bool(game.played):
			var my_score: int = int(game.home_score) if str(game.home_team_id) == str(team.id) else int(game.away_score)
			var opp_score: int = int(game.away_score) if str(game.home_team_id) == str(team.id) else int(game.home_score)
			result_text = "%d-%d" % [my_score, opp_score]
		return "%s   %s   %s" % [prefix, opponent_name, result_text]
	return ""


func _refresh_month_tabs() -> void:
	for month_key in _month_buttons.keys():
		var button: Button = _month_buttons[month_key]
		if button != null:
			button.button_pressed = int(month_key) == _selected_month


func _refresh_month_summary() -> void:
	var event_days: int = 0
	var game_count: int = 0
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	for day in range(1, LeagueState.get_last_day() + 1):
		var info: Dictionary = LeagueState.get_date_info_for_day(day)
		if int(info.get("month", 0)) != _selected_month:
			continue
		if not LeagueState.get_calendar_events_for_day(day).is_empty():
			event_days += 1
		if _day_has_controlled_team_game(day, controlled_team):
			game_count += 1

	month_summary_label.text = "%d %s\nイベント日: %d\n試合数: %d\n選択日: %s" % [
		LeagueState.season_year,
		MONTH_LABELS[_selected_month - 1],
		event_days,
		game_count,
		LeagueState.get_date_label_for_day(_selected_day) if _selected_day > 0 else "-"
	]


func _refresh_upcoming() -> void:
	var upcoming_lines: Array[String] = []
	var upcoming_events: Array[Dictionary] = LeagueState.get_upcoming_calendar_events(4)
	if upcoming_events.is_empty():
		upcoming_lines.append("次の年間イベントはありません")
	else:
		for event_data in upcoming_events:
			upcoming_lines.append("%s  %s" % [
				str(event_data.get("date_label", "")),
				str(event_data.get("label", ""))
			])
	upcoming_detail_label.text = "\n".join(upcoming_lines)


func _refresh_month_calendar() -> void:
	for child in month_calendar_grid.get_children():
		child.queue_free()

	var first_day_in_month: int = -1
	var last_day_in_month: int = -1
	for day in range(1, LeagueState.get_last_day() + 1):
		var info: Dictionary = LeagueState.get_date_info_for_day(day)
		if int(info.get("month", 0)) != _selected_month:
			continue
		if first_day_in_month < 0:
			first_day_in_month = day
		last_day_in_month = day
	if first_day_in_month < 0:
		return

	var first_info: Dictionary = LeagueState.get_date_info_for_day(first_day_in_month)
	var first_weekday: int = int(first_info.get("weekday", 0))
	for _index in range(first_weekday):
		var spacer := Label.new()
		spacer.text = ""
		month_calendar_grid.add_child(spacer)

	var controlled_team: TeamData = LeagueState.get_controlled_team()
	for day in range(first_day_in_month, last_day_in_month + 1):
		var info: Dictionary = LeagueState.get_date_info_for_day(day)
		var day_button := Button.new()
		day_button.custom_minimum_size = Vector2(96, 74)
		day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_button.toggle_mode = true
		day_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		day_button.clip_text = true

		var markers: Array[String] = []
		if _day_has_controlled_team_game(day, controlled_team):
			markers.append("試")
		if not LeagueState.get_calendar_events_for_day(day).is_empty():
			markers.append("事")
		if day == LeagueState.current_day:
			markers.append("今")

		var body_lines: Array[String] = [str(int(info.get("day", 0)))]
		if not markers.is_empty():
			body_lines.append(" ".join(markers))
		var short_game: String = _build_short_game_line(day, controlled_team)
		if short_game != "":
			body_lines.append(short_game)
		day_button.text = "\n".join(body_lines)
		day_button.button_pressed = day == _selected_day
		day_button.pressed.connect(_on_day_button_pressed.bind(day))
		month_calendar_grid.add_child(day_button)


func _build_short_game_line(day: int, controlled_team: TeamData) -> String:
	if controlled_team == null:
		return ""
	for game_value in LeagueState.get_games_for_day(day):
		var game: GameData = game_value
		if game == null:
			continue
		if str(game.away_team_id) != str(controlled_team.id) and str(game.home_team_id) != str(controlled_team.id):
			continue
		var opponent_name := ""
		if str(game.home_team_id) == str(controlled_team.id):
			var away_team: TeamData = LeagueState.get_team(str(game.away_team_id))
			opponent_name = away_team.short_name if away_team != null else "OPP"
			return "vs %s" % opponent_name
		var home_team: TeamData = LeagueState.get_team(str(game.home_team_id))
		opponent_name = home_team.short_name if home_team != null else "OPP"
		return "@ %s" % opponent_name
	return ""


func _refresh_detail_panel() -> void:
	events_tab_button.toggle_mode = true
	schedule_tab_button.toggle_mode = true
	events_tab_button.button_pressed = _current_detail_tab == "events"
	schedule_tab_button.button_pressed = _current_detail_tab == "schedule"

	monthly_events_title_label.visible = _current_detail_tab == "events"
	monthly_events_detail_label.visible = _current_detail_tab == "events"
	schedule_title_label.visible = _current_detail_tab == "schedule"
	schedule_detail_label.visible = _current_detail_tab == "schedule"

	if not _is_selected_day_in_current_month():
		monthly_events_detail_label.text = "日付を選ぶとその日のイベントが表示されます。"
		schedule_detail_label.text = "日付を選ぶとその日の試合予定が表示されます。"
		return

	var selected_events: Array[Dictionary] = LeagueState.get_calendar_events_for_day(_selected_day)
	var event_lines: Array[String] = [LeagueState.get_date_label_for_day(_selected_day)]
	if selected_events.is_empty():
		event_lines.append("この日に大きな年間イベントはありません。")
	else:
		for event_data in selected_events:
			event_lines.append("- %s" % str(event_data.get("label", "")))
			var summary_text: String = str(event_data.get("summary", ""))
			if summary_text != "":
				event_lines.append("  %s" % summary_text)
	monthly_events_detail_label.text = "\n".join(event_lines)

	var team: TeamData = LeagueState.get_controlled_team()
	var schedule_lines: Array[String] = [LeagueState.get_date_label_for_day(_selected_day)]
	var found_game: bool = false
	if team != null:
		for game_value in LeagueState.get_games_for_day(_selected_day):
			var game: GameData = game_value
			if game == null:
				continue
			if str(game.away_team_id) != str(team.id) and str(game.home_team_id) != str(team.id):
				continue
			found_game = true
			var prefix := "vs"
			var opponent_name := ""
			if str(game.home_team_id) == str(team.id):
				var away_team: TeamData = LeagueState.get_team(str(game.away_team_id))
				opponent_name = away_team.name if away_team != null else str(game.away_team_id)
			else:
				prefix = "@"
				var home_team: TeamData = LeagueState.get_team(str(game.home_team_id))
				opponent_name = home_team.name if home_team != null else str(game.home_team_id)
			var result_text := "未消化"
			if bool(game.played):
				var my_score: int = int(game.home_score) if str(game.home_team_id) == str(team.id) else int(game.away_score)
				var opp_score: int = int(game.away_score) if str(game.home_team_id) == str(team.id) else int(game.home_score)
				result_text = "%d-%d" % [my_score, opp_score]
			schedule_lines.append("- %s %s  %s" % [prefix, opponent_name, result_text])
	if not found_game:
		schedule_lines.append("この日に担当球団の試合はありません。")
	schedule_detail_label.text = "\n".join(schedule_lines)


func _get_current_month() -> int:
	var info: Dictionary = LeagueState.get_date_info_for_day(LeagueState.current_day)
	return int(info.get("month", 1))


func _find_first_day_in_month(month: int) -> int:
	for day in range(1, LeagueState.get_last_day() + 1):
		var info: Dictionary = LeagueState.get_date_info_for_day(day)
		if int(info.get("month", 0)) == month:
			return day
	return LeagueState.current_day


func _is_selected_day_in_current_month() -> bool:
	if _selected_day <= 0:
		return false
	var info: Dictionary = LeagueState.get_date_info_for_day(_selected_day)
	return int(info.get("month", 0)) == _selected_month


func _day_has_controlled_team_game(day: int, controlled_team: TeamData) -> bool:
	if controlled_team == null:
		return false
	for game_value in LeagueState.get_games_for_day(day):
		var game: GameData = game_value
		if game == null:
			continue
		if str(game.away_team_id) == str(controlled_team.id) or str(game.home_team_id) == str(controlled_team.id):
			return true
	return false
