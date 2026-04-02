extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var today_title_label: Label = $RootScroll/MarginContainer/RootVBox/TopSummaryHBox/TodayCard/TodayTitleLabel
@onready var today_detail_label: Label = $RootScroll/MarginContainer/RootVBox/TopSummaryHBox/TodayCard/TodayDetailLabel
@onready var upcoming_title_label: Label = $RootScroll/MarginContainer/RootVBox/TopSummaryHBox/UpcomingCard/UpcomingTitleLabel
@onready var upcoming_detail_label: Label = $RootScroll/MarginContainer/RootVBox/TopSummaryHBox/UpcomingCard/UpcomingDetailLabel
@onready var month_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftVBox/MonthTitleLabel
@onready var month_buttons_grid: GridContainer = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftVBox/MonthButtonsGrid
@onready var month_summary_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftVBox/MonthSummaryLabel
@onready var monthly_events_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/MonthlyEventsTitleLabel
@onready var monthly_events_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/MonthlyEventsDetailLabel
@onready var schedule_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/ScheduleTitleLabel
@onready var schedule_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/ScheduleDetailLabel

var _selected_month: int = 1
var _month_buttons: Dictionary = {}

func _ready() -> void:
	_setup_static_text()
	_build_month_buttons()
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(HOME_SCENE_PATH))
	_selected_month = _get_current_month()
	_refresh_view()

func _setup_static_text() -> void:
	title_label.text = "年間カレンダー"
	back_button.text = "ホームへ戻る"
	info_label.text = "月ごとの年間イベントと担当球団の予定を確認できます。気になる月を選ぶと、その月だけをまとめて見られます。"
	today_title_label.text = "今日のイベント"
	upcoming_title_label.text = "次に来るイベント"
	month_title_label.text = "月を選ぶ"
	monthly_events_title_label.text = "選択月の年間イベント"
	schedule_title_label.text = "選択月の担当球団予定"

func _build_month_buttons() -> void:
	for child in month_buttons_grid.get_children():
		child.queue_free()
	_month_buttons.clear()

	for month in range(1, 13):
		var button := Button.new()
		button.text = "%d月" % month
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.pressed.connect(_on_month_button_pressed.bind(month))
		month_buttons_grid.add_child(button)
		_month_buttons[month] = button

func _on_month_button_pressed(month: int) -> void:
	_selected_month = month
	_refresh_view()

func _refresh_view() -> void:
	_refresh_top_summary()
	_refresh_month_buttons()
	_refresh_month_summary()
	_refresh_monthly_events()
	_refresh_monthly_schedule()

func _refresh_top_summary() -> void:
	today_detail_label.text = "日付: %s\n%s" % [
		LeagueState.get_current_date_label(),
		LeagueState.get_calendar_summary_text()
	]

	var upcoming_lines: Array[String] = []
	var upcoming_events: Array[Dictionary] = LeagueState.get_upcoming_calendar_events(5)
	if upcoming_events.is_empty():
		upcoming_lines.append("この先の年間イベントはありません。")
	else:
		for event_data in upcoming_events:
			upcoming_lines.append("%s  %s" % [
				str(event_data.get("date_label", "")),
				str(event_data.get("label", ""))
			])
			upcoming_lines.append("  %s" % str(event_data.get("summary", "")))
	upcoming_detail_label.text = "\n".join(upcoming_lines)

func _refresh_month_buttons() -> void:
	for month in _month_buttons.keys():
		var button: Button = _month_buttons[month]
		if button == null:
			continue
		button.button_pressed = int(month) == _selected_month

func _refresh_month_summary() -> void:
	var year: int = LeagueState.season_year
	var event_count: int = 0
	var game_count: int = 0
	var next_marker: String = ""
	var controlled_team: TeamData = LeagueState.get_controlled_team()

	for day in range(1, LeagueState.get_last_day() + 1):
		var date_info: Dictionary = LeagueState.get_date_info_for_day(day)
		if int(date_info.get("month", 0)) != _selected_month:
			continue
		event_count += LeagueState.get_calendar_events_for_day(day).size()
		if controlled_team != null:
			var games: Array = LeagueState.get_games_for_day(day)
			for game_value in games:
				var game: GameData = game_value
				if game == null:
					continue
				if str(game.away_team_id) == str(controlled_team.id) or str(game.home_team_id) == str(controlled_team.id):
					game_count += 1
					if next_marker == "" and day >= LeagueState.current_day:
						next_marker = str(game.date_label)

	var lines: Array[String] = []
	lines.append("%04d年%d月を表示中" % [year, _selected_month])
	lines.append("年間イベント: %d件" % event_count)
	lines.append("担当球団の試合: %d試合" % game_count)
	if next_marker != "":
		lines.append("この月の次の試合: %s" % next_marker)
	month_summary_label.text = "\n".join(lines)

func _refresh_monthly_events() -> void:
	var lines: Array[String] = []
	for day in range(1, LeagueState.get_last_day() + 1):
		var date_info: Dictionary = LeagueState.get_date_info_for_day(day)
		if int(date_info.get("month", 0)) != _selected_month:
			continue
		var events: Array[Dictionary] = LeagueState.get_calendar_events_for_day(day)
		if events.is_empty():
			continue
		for event_data in events:
			lines.append("%s  %s" % [
				LeagueState.get_date_label_for_day(day),
				str(event_data.get("label", ""))
			])
			lines.append("  %s" % str(event_data.get("summary", "")))
			lines.append("")

	if lines.is_empty():
		monthly_events_detail_label.text = "この月に大きな年間イベントはありません。"
	else:
		monthly_events_detail_label.text = "\n".join(lines)

func _refresh_monthly_schedule() -> void:
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	if controlled_team == null:
		schedule_detail_label.text = "担当球団が設定されていません。"
		return

	var lines: Array[String] = []
	for game_value in LeagueState.schedule:
		var game: GameData = game_value
		if game == null:
			continue
		if int(game.month) != _selected_month:
			continue
		if str(game.away_team_id) != str(controlled_team.id) and str(game.home_team_id) != str(controlled_team.id):
			continue

		var home_away: String = "vs"
		var opponent_name: String = ""
		if str(game.home_team_id) == str(controlled_team.id):
			var away_team: TeamData = LeagueState.get_team(str(game.away_team_id))
			opponent_name = away_team.name if away_team != null else str(game.away_team_id)
		else:
			home_away = "@"
			var home_team: TeamData = LeagueState.get_team(str(game.home_team_id))
			opponent_name = home_team.name if home_team != null else str(game.home_team_id)

		var result_text: String = "未消化"
		if bool(game.played):
			if int(game.away_score) == int(game.home_score):
				result_text = "△ %d-%d" % [int(game.away_score), int(game.home_score)]
			elif str(game.home_team_id) == str(controlled_team.id):
				result_text = "○ %d-%d" % [int(game.home_score), int(game.away_score)] if int(game.home_score) > int(game.away_score) else "● %d-%d" % [int(game.home_score), int(game.away_score)]
			else:
				result_text = "○ %d-%d" % [int(game.away_score), int(game.home_score)] if int(game.away_score) > int(game.home_score) else "● %d-%d" % [int(game.away_score), int(game.home_score)]

		var marker: String = ""
		if int(game.day) == LeagueState.current_day:
			marker = "  <- 今日"
		elif int(game.day) == maxi(1, LeagueState.current_day - 1):
			marker = "  <- 昨日"

		lines.append("%s  %s %s  %s%s" % [
			str(game.date_label),
			home_away,
			opponent_name,
			result_text,
			marker
		])

	if lines.is_empty():
		schedule_detail_label.text = "この月に担当球団の試合はありません。"
	else:
		schedule_detail_label.text = "\n".join(lines)

func _get_current_month() -> int:
	var date_info: Dictionary = LeagueState.get_date_info_for_day(LeagueState.current_day)
	return int(date_info.get("month", 1))
