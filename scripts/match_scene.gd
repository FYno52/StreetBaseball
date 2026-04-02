extends Control

const LEAGUE_HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var auto_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/AutoButton
@onready var slow_button: Button = $RootScroll/MarginContainer/RootVBox/SpeedButtonsHBox/SlowButton
@onready var normal_button: Button = $RootScroll/MarginContainer/RootVBox/SpeedButtonsHBox/NormalButton
@onready var fast_button: Button = $RootScroll/MarginContainer/RootVBox/SpeedButtonsHBox/FastButton
@onready var pause_mode_title_label: Label = $RootScroll/MarginContainer/RootVBox/PauseModeHBox/PauseModeTitleLabel
@onready var pause_none_button: Button = $RootScroll/MarginContainer/RootVBox/PauseModeHBox/PauseNoneButton
@onready var pause_chance_button: Button = $RootScroll/MarginContainer/RootVBox/PauseModeHBox/PauseChanceButton
@onready var pause_pinch_button: Button = $RootScroll/MarginContainer/RootVBox/PauseModeHBox/PausePinchButton
@onready var pause_important_button: Button = $RootScroll/MarginContainer/RootVBox/PauseModeHBox/PauseImportantButton
@onready var step_mode_title_label: Label = $RootScroll/MarginContainer/RootVBox/StepModeHBox/StepModeTitleLabel
@onready var pitch_step_button: Button = $RootScroll/MarginContainer/RootVBox/StepModeHBox/PitchStepButton
@onready var at_bat_step_button: Button = $RootScroll/MarginContainer/RootVBox/StepModeHBox/AtBatStepButton
@onready var header_info_label: Label = $RootScroll/MarginContainer/RootVBox/HeaderInfoLabel
@onready var score_title_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/ScoreCard/ScoreTitleLabel
@onready var score_detail_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/ScoreCard/ScoreDetailLabel
@onready var progress_title_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/StatusCard/ProgressTitleLabel
@onready var progress_detail_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/StatusCard/ProgressDetailLabel
@onready var inning_title_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/StatusCard/InningTitleLabel
@onready var inning_detail_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/StatusCard/InningDetailLabel
@onready var base_title_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/StatusCard/BaseTitleLabel
@onready var base_detail_label: Label = $RootScroll/MarginContainer/RootVBox/TopColumns/StatusCard/BaseDetailLabel
@onready var previous_button: Button = $RootScroll/MarginContainer/RootVBox/ControlButtonsHBox/PreviousButton
@onready var result_button: Button = $RootScroll/MarginContainer/RootVBox/ControlButtonsHBox/ResultButton
@onready var next_button: Button = $RootScroll/MarginContainer/RootVBox/ControlButtonsHBox/NextButton
@onready var postgame_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/PostgameVBox
@onready var postgame_title_label: Label = $RootScroll/MarginContainer/RootVBox/PostgameVBox/PostgameTitleLabel
@onready var postgame_detail_label: Label = $RootScroll/MarginContainer/RootVBox/PostgameVBox/PostgameDetailLabel
@onready var command_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/CommandVBox
@onready var command_title_label: Label = $RootScroll/MarginContainer/RootVBox/CommandVBox/CommandTitleLabel
@onready var command_status_label: Label = $RootScroll/MarginContainer/RootVBox/CommandVBox/CommandStatusLabel
@onready var aggressive_button: Button = $RootScroll/MarginContainer/RootVBox/CommandVBox/CommandButtonsHBox/AggressiveButton
@onready var bunt_button: Button = $RootScroll/MarginContainer/RootVBox/CommandVBox/CommandButtonsHBox/BuntButton
@onready var advance_button: Button = $RootScroll/MarginContainer/RootVBox/CommandVBox/CommandButtonsHBox/AdvanceButton
@onready var intentional_walk_button: Button = $RootScroll/MarginContainer/RootVBox/CommandVBox/CommandButtonsHBox/IntentionalWalkButton
@onready var event_title_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/LeftVBox/EventTitleLabel
@onready var event_detail_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/LeftVBox/EventDetailLabel
@onready var log_title_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/LeftVBox/LogTitleLabel
@onready var log_detail_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/LeftVBox/LogDetailLabel
@onready var line_score_title_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/RightVBox/LineScoreTitleLabel
@onready var line_score_detail_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/RightVBox/LineScoreDetailLabel
@onready var note_title_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/RightVBox/NoteTitleLabel
@onready var note_detail_label: Label = $RootScroll/MarginContainer/RootVBox/MainColumns/RightVBox/NoteDetailLabel

var current_game: GameData = null
var current_events: Array[Dictionary] = []
var current_live_package: Dictionary = {}
var current_event_index: int = 0
var auto_play_active: bool = false
var auto_play_speed: String = "normal"
var auto_pause_mode: String = "important"
var selected_command: String = "neutral"
var step_mode: String = "pitch"


func _ready() -> void:
	_setup_static_text()
	_connect_buttons()
	_load_live_game()
	_refresh_view()


func _exit_tree() -> void:
	auto_play_active = false


func _setup_static_text() -> void:
	title_label.text = "ライブ試合"
	back_button.text = "ホームへ戻る"
	auto_button.text = "オート再生"
	slow_button.text = "低速"
	normal_button.text = "標準"
	fast_button.text = "高速"
	pause_mode_title_label.text = "停止場面"
	pause_none_button.text = "停止なし"
	pause_chance_button.text = "チャンス"
	pause_pinch_button.text = "ピンチ"
	pause_important_button.text = "重要場面"
	step_mode_title_label.text = "進行単位"
	pitch_step_button.text = "一球ごと"
	at_bat_step_button.text = "一打席ごと"
	score_title_label.text = "スコア"
	progress_title_label.text = "進行"
	inning_title_label.text = "イニング"
	base_title_label.text = "塁状況"
	previous_button.text = "前へ"
	result_button.text = "結果を見る"
	next_button.text = "次へ"
	postgame_title_label.text = "試合後サマリー"
	command_title_label.text = "采配・指示"
	aggressive_button.text = "強攻"
	bunt_button.text = "バント"
	advance_button.text = "進塁重視"
	intentional_walk_button.text = "敬遠"
	event_title_label.text = "現在イベント"
	log_title_label.text = "イベントログ"
	line_score_title_label.text = "ラインスコア"
	note_title_label.text = "メモ"


func _connect_buttons() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	auto_button.pressed.connect(_on_auto_button_pressed)
	slow_button.pressed.connect(func() -> void: _set_auto_speed("slow"))
	normal_button.pressed.connect(func() -> void: _set_auto_speed("normal"))
	fast_button.pressed.connect(func() -> void: _set_auto_speed("fast"))
	pause_none_button.pressed.connect(func() -> void: _set_auto_pause_mode("none"))
	pause_chance_button.pressed.connect(func() -> void: _set_auto_pause_mode("chance"))
	pause_pinch_button.pressed.connect(func() -> void: _set_auto_pause_mode("pinch"))
	pause_important_button.pressed.connect(func() -> void: _set_auto_pause_mode("important"))
	pitch_step_button.pressed.connect(func() -> void: _set_step_mode("pitch"))
	at_bat_step_button.pressed.connect(func() -> void: _set_step_mode("at_bat"))
	previous_button.pressed.connect(_on_previous_button_pressed)
	result_button.pressed.connect(_on_result_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	aggressive_button.pressed.connect(func() -> void: _set_command("aggressive"))
	bunt_button.pressed.connect(func() -> void: _set_command("bunt"))
	advance_button.pressed.connect(func() -> void: _set_command("advance"))
	intentional_walk_button.pressed.connect(func() -> void: _set_command("intentional_walk"))


func _load_live_game() -> void:
	current_game = LeagueState.get_selected_game()
	current_events.clear()
	current_live_package.clear()
	current_event_index = 0
	selected_command = "neutral"

	if current_game == null:
		LeagueState.clear_active_live_game()
		return
	if bool(current_game.played):
		LeagueState.clear_active_live_game()
		return

	LeagueState.set_active_live_game(str(current_game.id))

	_regenerate_live_preview()


func _regenerate_live_preview() -> void:
	if current_game == null or bool(current_game.played):
		return

	var away_team = LeagueState.get_team(str(current_game.away_team_id))
	var home_team = LeagueState.get_team(str(current_game.home_team_id))
	if away_team == null or home_team == null:
		current_events.clear()
		current_live_package.clear()
		return

	var previous_index: int = current_event_index
	current_live_package = SimulationEngine.prepare_live_game(current_game, away_team, home_team, selected_command)
	current_events.clear()
	for event_value in current_live_package.get("play_events", []):
		if event_value is Dictionary:
			current_events.append((event_value as Dictionary).duplicate(true))

	if current_events.is_empty():
		current_event_index = 0
	else:
		current_event_index = clampi(previous_index, 0, current_events.size() - 1)


func _refresh_view() -> void:
	_refresh_speed_buttons()
	_refresh_pause_mode_buttons()
	_refresh_step_mode_buttons()

	if current_game == null:
		_refresh_empty_view()
		return

	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	header_info_label.text = "%s | %s vs %s" % [str(current_game.date_label), away_name, home_name]
	postgame_vbox.visible = bool(current_game.played)
	postgame_detail_label.text = _build_postgame_summary_text() if bool(current_game.played) else ""
	command_vbox.visible = not bool(current_game.played)
	previous_button.visible = false
	previous_button.disabled = true
	result_button.visible = not bool(current_game.played)
	back_button.disabled = not bool(current_game.played)
	back_button.text = "ホームへ戻る" if bool(current_game.played) else "試合中"

	if current_events.is_empty():
		score_detail_label.text = "%s vs %s\n試合準備中" % [away_name, home_name]
		progress_detail_label.text = "イベント生成中\n速度: %s\n停止: %s\n単位: %s" % [_get_auto_speed_label(), _get_auto_pause_mode_label(), _get_step_mode_label()]
		inning_detail_label.text = "試合前"
		base_detail_label.text = "走者なし"
		command_status_label.text = _build_command_status_text()
		event_detail_label.text = "まだライブイベントがありません。"
		log_detail_label.text = "イベントログはまだありません。"
		line_score_detail_label.text = _build_empty_line_score_text(away_name, home_name)
		note_detail_label.text = "試合イベントを準備中です。"
		result_button.disabled = true
		next_button.disabled = true
		auto_button.disabled = true
		auto_button.text = "オート再生"
		_refresh_command_buttons()
		return

	current_event_index = clampi(current_event_index, 0, current_events.size() - 1)
	var current_event: Dictionary = current_events[current_event_index]
	score_detail_label.text = _build_score_text(current_event)
	progress_detail_label.text = _build_progress_text()
	inning_detail_label.text = _build_inning_text(current_event)
	base_detail_label.text = _build_base_state_text(current_event)
	command_status_label.text = _build_command_status_text()
	event_detail_label.text = _build_event_text(current_event)
	log_detail_label.text = _build_log_text()
	line_score_detail_label.text = _build_line_score_text_from_events(current_events)
	note_detail_label.text = _build_note_text(current_event)

	auto_button.disabled = false
	auto_button.text = "オート停止" if auto_play_active else "オート再生"
	if bool(current_game.played):
		result_button.disabled = true
		next_button.disabled = true
		next_button.text = "試合確定済み"
	elif current_event_index >= current_events.size() - 1:
		result_button.disabled = false
		next_button.disabled = false
		next_button.text = "試合確定"
	else:
		result_button.disabled = false
		next_button.disabled = false
		next_button.text = "次へ"
	_refresh_command_buttons()


func _refresh_empty_view() -> void:
	header_info_label.text = "今日のライブ試合がありません。"
	score_detail_label.text = "-"
	progress_detail_label.text = "-"
	inning_detail_label.text = "-"
	base_detail_label.text = "-"
	postgame_vbox.visible = false
	command_vbox.visible = false
	event_detail_label.text = "ホーム画面から当日の試合へ入ってください。"
	log_detail_label.text = "イベントログはまだありません。"
	line_score_detail_label.text = "-"
	note_detail_label.text = "担当球団の当日試合だけ、この画面でライブ進行できます。"
	previous_button.visible = false
	previous_button.disabled = true
	result_button.visible = false
	result_button.disabled = true
	back_button.disabled = false
	back_button.text = "ホームへ戻る"
	next_button.disabled = true
	auto_button.disabled = true
	auto_button.text = "オート再生"


func _build_score_text(current_event: Dictionary) -> String:
	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	return "%s %d - %d %s" % [away_name, int(current_event.get("away_score", 0)), int(current_event.get("home_score", 0)), home_name]


func _build_progress_text() -> String:
	var state_text: String = "オート再生中 (%s)" % _get_auto_speed_label() if auto_play_active else "手動進行中"
	return "%d / %d\n%s\n停止: %s\n単位: %s" % [current_event_index + 1, current_events.size(), state_text, _get_auto_pause_mode_label(), _get_step_mode_label()]


func _build_inning_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	if event_type == "game_start":
		return "試合開始\n先攻: %s" % _get_team_name(str(current_game.away_team_id))
	if event_type in ["half_inning_start", "pitch", "at_bat", "half_inning"]:
		var lines: Array[String] = []
		lines.append(_format_half_inning_label(int(current_event.get("inning", 0)), str(current_event.get("side", ""))))
		if current_event.has("batter_name"):
			lines.append("打者: %s" % str(current_event.get("batter_name", "")))
		if current_event.has("pitcher_name"):
			lines.append("投手: %s" % str(current_event.get("pitcher_name", "")))
		if current_event.has("outs"):
			lines.append("アウト: %d" % int(current_event.get("outs", 0)))
		return "\n".join(lines)
	if event_type == "game_end":
		return "試合終了"
	return "-"


func _build_base_state_text(current_event: Dictionary) -> String:
	if str(current_event.get("type", "")) in ["half_inning_start", "pitch", "at_bat", "half_inning"]:
		return _format_base_state(current_event.get("bases", [false, false, false]))
	return "走者なし"


func _build_event_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	match event_type:
		"game_start":
			return "試合を開始します。"
		"half_inning_start":
			return "%sの攻撃開始\n投手: %s" % [str(current_event.get("offense_team_name", "")), str(current_event.get("pitcher_name", ""))]
		"pitch":
			return "%s vs %s\n%d球目: %s\n球種: %s / コース: %s\nカウント %d-%d" % [
				str(current_event.get("batter_name", "")),
				str(current_event.get("pitcher_name", "")),
				int(current_event.get("pitch_number", 0)),
				str(current_event.get("pitch_result_label", "")),
				str(current_event.get("pitch_type_label", "")),
				str(current_event.get("pitch_zone_label", "")),
				int(current_event.get("balls_after", 0)),
				int(current_event.get("strikes_after", 0))
			]
		"at_bat":
			var lines: Array[String] = []
			lines.append("%s vs %s" % [str(current_event.get("batter_name", "")), str(current_event.get("pitcher_name", ""))])
			lines.append(str(current_event.get("result_label", "")))
			lines.append("カウント %d-%d / %d球" % [int(current_event.get("balls", 0)), int(current_event.get("strikes", 0)), int(current_event.get("pitch_count", 0))])
			var command_name: String = _get_command_display_name(str(current_event.get("command_profile", "neutral")))
			if command_name != "通常":
				lines.append("指示: %s" % command_name)
			var batted_ball_text: String = _build_batted_ball_text(current_event)
			if batted_ball_text != "":
				lines.append(batted_ball_text)
			var pitch_summary: String = str(current_event.get("pitch_result_summary", ""))
			if pitch_summary != "":
				lines.append(pitch_summary)
			var play_note: String = str(current_event.get("play_note", ""))
			if play_note != "":
				lines.append(play_note)
			if int(current_event.get("runs_scored", 0)) > 0:
				lines.append("この打席で %d得点" % int(current_event.get("runs_scored", 0)))
			return "\n".join(lines)
		"half_inning":
			return "%sの攻撃終了\nこの回の得点: %d" % [str(current_event.get("offense_team_name", "")), int(current_event.get("runs_scored", 0))]
		"pitching_summary":
			return _build_pitching_summary_text(current_event)
		"game_end":
			return _build_postgame_summary_text()
		_:
			return "イベント情報はありません。"


func _build_pitching_summary_text(current_event: Dictionary) -> String:
	var lines: Array[String] = []
	for pitcher_value in current_event.get("pitchers", []):
		if not (pitcher_value is Dictionary):
			continue
		var pitcher_row: Dictionary = pitcher_value
		var tags: Array[String] = []
		if bool(pitcher_row.get("is_starter", false)):
			tags.append("先発")
		var decision: String = str(pitcher_row.get("decision", "none"))
		if decision == "win":
			tags.append("勝")
		elif decision == "loss":
			tags.append("敗")
		if bool(pitcher_row.get("save", false)):
			tags.append("S")
		if bool(pitcher_row.get("hold", false)):
			tags.append("H")
		lines.append("%s  %dアウト  自責%d  %s" % [str(pitcher_row.get("pitcher_name", "")), int(pitcher_row.get("outs", 0)), int(pitcher_row.get("earned_runs", 0)), " / ".join(tags)])
	if lines.is_empty():
		return "投手リレーはありません。"
	return "\n".join(lines)


func _build_line_score_text_from_events(event_source: Array) -> String:
	if current_game == null:
		return "-"
	var away_runs_by_inning: Array[int] = []
	var home_runs_by_inning: Array[int] = []
	for _i in range(9):
		away_runs_by_inning.append(0)
		home_runs_by_inning.append(0)
	for event_value in event_source:
		if not (event_value is Dictionary):
			continue
		var event_data: Dictionary = event_value
		if str(event_data.get("type", "")) != "half_inning":
			continue
		var inning_index: int = int(event_data.get("inning", 1)) - 1
		if inning_index < 0 or inning_index >= 9:
			continue
		if str(event_data.get("side", "")) == "top":
			away_runs_by_inning[inning_index] = int(event_data.get("runs_scored", 0))
		else:
			home_runs_by_inning[inning_index] = int(event_data.get("runs_scored", 0))
	var header: Array[String] = []
	var away_row: Array[String] = []
	var home_row: Array[String] = []
	for inning in range(9):
		header.append(str(inning + 1))
		away_row.append(str(away_runs_by_inning[inning]))
		home_row.append(str(home_runs_by_inning[inning]))
	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	return "回: %s\n%s: %s | %d\n%s: %s | %d" % [" ".join(header), away_name, " ".join(away_row), _get_current_score_value("away_score"), home_name, " ".join(home_row), _get_current_score_value("home_score")]


func _build_empty_line_score_text(away_name: String, home_name: String) -> String:
	return "回: 1 2 3 4 5 6 7 8 9\n%s: - - - - - - - - -\n%s: - - - - - - - - -" % [away_name, home_name]


func _build_note_text(current_event: Dictionary) -> String:
	var lines: Array[String] = []
	if current_event.has("command_profile"):
		lines.append("現在の指示: %s" % _get_command_display_name(str(current_event.get("command_profile", "neutral"))))
	if current_event.has("outs_before"):
		lines.append("打席前アウト: %d" % int(current_event.get("outs_before", 0)))
	if current_event.has("outs"):
		lines.append("打席後アウト: %d" % int(current_event.get("outs", 0)))
	if current_event.has("pitch_count"):
		lines.append("球数: %d球" % int(current_event.get("pitch_count", 0)))
	if current_event.has("pitch_result_summary"):
		var summary: String = str(current_event.get("pitch_result_summary", ""))
		if summary != "":
			lines.append(summary)
	if current_event.has("play_note"):
		var play_note: String = str(current_event.get("play_note", ""))
		if play_note != "":
			lines.append(play_note)
	if lines.is_empty():
		return "試合の流れを確認できます。"
	return "\n".join(lines)


func _build_log_text() -> String:
	if current_events.is_empty():
		return "イベントログはまだありません。"
	var lines: Array[String] = []
	var start_index: int = maxi(0, current_event_index - 10)
	for index in range(start_index, current_event_index + 1):
		var event_data: Dictionary = current_events[index]
		var line: String = _build_log_line(event_data)
		if line != "":
			lines.append(line)
	if lines.is_empty():
		return "イベントログはまだありません。"
	return "\n".join(lines)


func _build_log_line(event_data: Dictionary) -> String:
	var event_type: String = str(event_data.get("type", ""))
	match event_type:
		"pitch":
			return "%d球目 %s vs %s  %s" % [int(event_data.get("pitch_number", 0)), str(event_data.get("batter_name", "")), str(event_data.get("pitcher_name", "")), str(event_data.get("pitch_result_label", ""))]
		"at_bat":
			return "%s vs %s  %s" % [str(event_data.get("batter_name", "")), str(event_data.get("pitcher_name", "")), str(event_data.get("result_label", ""))]
		"half_inning_start":
			return "%s 攻撃開始" % str(event_data.get("offense_team_name", ""))
		"half_inning":
			return "%s 攻撃終了 (%d得点)" % [str(event_data.get("offense_team_name", "")), int(event_data.get("runs_scored", 0))]
		"game_end":
			return "試合終了"
		_:
			return ""


func _build_postgame_summary_text() -> String:
	if current_game == null:
		return "試合結果はありません。"
	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	var lines: Array[String] = []
	lines.append("%s %d - %d %s" % [away_name, int(current_game.away_score), int(current_game.home_score), home_name])
	if int(current_game.away_score) == int(current_game.home_score):
		lines.append("結果: 引き分け")
	else:
		var winner_name: String = away_name if int(current_game.away_score) > int(current_game.home_score) else home_name
		lines.append("勝利チーム: %s" % winner_name)
	lines.append("勝利投手: %s" % _get_player_name(str(current_game.winning_pitcher_id)))
	lines.append("敗戦投手: %s" % _get_player_name(str(current_game.losing_pitcher_id)))
	lines.append("セーブ: %s" % _get_player_name(str(current_game.save_pitcher_id)))
	var controlled_id: String = LeagueState.controlled_team_id
	if controlled_id != "" and (str(current_game.home_team_id) == controlled_id or str(current_game.away_team_id) == controlled_id):
		var controlled_is_home: bool = str(current_game.home_team_id) == controlled_id
		var controlled_score: int = int(current_game.home_score) if controlled_is_home else int(current_game.away_score)
		var opponent_score: int = int(current_game.away_score) if controlled_is_home else int(current_game.home_score)
		if controlled_score > opponent_score:
			lines.append("担当球団メモ: 勝利しました。")
		elif controlled_score < opponent_score:
			lines.append("担当球団メモ: 敗戦しました。")
		else:
			lines.append("担当球団メモ: 引き分けでした。")
	return "\n".join(lines)


func _format_half_inning_label(inning: int, side: String) -> String:
	var side_label: String = "表" if side == "top" else "裏"
	return "%d回%s" % [inning, side_label]


func _format_base_state(bases_value) -> String:
	var base_array: Array = [false, false, false]
	if bases_value is Array and (bases_value as Array).size() >= 3:
		base_array = bases_value
	return "一塁:%s  二塁:%s  三塁:%s" % ["●" if bool(base_array[0]) else "○", "●" if bool(base_array[1]) else "○", "●" if bool(base_array[2]) else "○"]


func _build_batted_ball_text(current_event: Dictionary) -> String:
	var ball_type: String = str(current_event.get("batted_ball_type_label", ""))
	var direction: String = str(current_event.get("batted_ball_direction_label", ""))
	if ball_type == "" and direction == "":
		return ""
	if direction == "":
		return ball_type
	if ball_type == "":
		return direction
	return "%s / %s" % [ball_type, direction]


func _get_auto_speed_label() -> String:
	match auto_play_speed:
		"slow":
			return "低速"
		"fast":
			return "高速"
		_:
			return "標準"


func _get_auto_pause_mode_label() -> String:
	match auto_pause_mode:
		"none":
			return "停止なし"
		"chance":
			return "チャンス"
		"pinch":
			return "ピンチ"
		_:
			return "重要場面"


func _get_step_mode_label() -> String:
	return "一球ごと" if step_mode == "pitch" else "一打席ごと"


func _build_command_status_text() -> String:
	return "現在の指示: %s" % _get_command_display_name(selected_command)


func _get_command_display_name(command_name: String) -> String:
	match command_name:
		"aggressive":
			return "強攻"
		"bunt":
			return "バント"
		"advance":
			return "進塁重視"
		"intentional_walk":
			return "敬遠"
		_:
			return "通常"


func _refresh_speed_buttons() -> void:
	slow_button.disabled = auto_play_speed == "slow"
	normal_button.disabled = auto_play_speed == "normal"
	fast_button.disabled = auto_play_speed == "fast"


func _refresh_pause_mode_buttons() -> void:
	pause_none_button.disabled = auto_pause_mode == "none"
	pause_chance_button.disabled = auto_pause_mode == "chance"
	pause_pinch_button.disabled = auto_pause_mode == "pinch"
	pause_important_button.disabled = auto_pause_mode == "important"


func _refresh_step_mode_buttons() -> void:
	pitch_step_button.disabled = step_mode == "pitch"
	at_bat_step_button.disabled = step_mode == "at_bat"


func _refresh_command_buttons() -> void:
	var disable_commands: bool = current_game == null or bool(current_game.played)
	aggressive_button.disabled = disable_commands or selected_command == "aggressive"
	bunt_button.disabled = disable_commands or selected_command == "bunt"
	advance_button.disabled = disable_commands or selected_command == "advance"
	intentional_walk_button.disabled = disable_commands or selected_command == "intentional_walk"


func _set_auto_speed(speed_name: String) -> void:
	auto_play_speed = speed_name
	_refresh_view()


func _set_auto_pause_mode(mode_name: String) -> void:
	auto_pause_mode = mode_name
	_refresh_view()


func _set_step_mode(mode_name: String) -> void:
	step_mode = mode_name
	_refresh_view()


func _set_command(command_name: String) -> void:
	if current_game == null or bool(current_game.played):
		return
	selected_command = command_name
	_regenerate_live_preview()
	_refresh_view()


func _run_auto_play() -> void:
	while auto_play_active and is_inside_tree():
		if current_game == null:
			auto_play_active = false
			break
		if not bool(current_game.played) and current_event_index >= current_events.size() - 1:
			_finalize_live_game()
			break
		if current_event_index < current_events.size() - 1:
			current_event_index = _find_next_index(current_event_index)
			_refresh_view()
			if _should_pause_on_current_event():
				auto_play_active = false
				_refresh_view()
				break
		else:
			auto_play_active = false
			_refresh_view()
			break
		await get_tree().create_timer(_get_auto_wait_time()).timeout


func _get_auto_wait_time() -> float:
	match auto_play_speed:
		"slow":
			return 0.75
		"fast":
			return 0.12
		_:
			return 0.35


func _should_pause_on_current_event() -> bool:
	if auto_pause_mode == "none":
		return false
	if current_events.is_empty():
		return false
	var event_data: Dictionary = current_events[current_event_index]
	var bases = event_data.get("bases", [false, false, false])
	var inning: int = int(event_data.get("inning", 0))
	var away_score: int = int(event_data.get("away_score", 0))
	var home_score: int = int(event_data.get("home_score", 0))
	var is_chance: bool = false
	var is_pinch: bool = false
	var is_important: bool = false

	if bases is Array and (bases as Array).size() >= 3:
		is_chance = bool(bases[1]) or bool(bases[2])
		is_pinch = inning >= 8 and away_score == home_score and str(event_data.get("side", "")) == "top" and (bool(bases[1]) or bool(bases[2]))
		if str(event_data.get("side", "")) == "bottom":
			is_pinch = inning >= 8 and away_score == home_score and (bool(bases[1]) or bool(bases[2]))
		if bool(bases[0]) and bool(bases[1]) and bool(bases[2]):
			is_important = true

	if int(event_data.get("runs_scored", 0)) > 0:
		is_important = true
	if inning >= 8 and away_score == home_score:
		is_important = true
	if inning >= 8 and is_chance:
		is_important = true

	match auto_pause_mode:
		"chance":
			return is_chance
		"pinch":
			return is_pinch
		"important":
			return is_important
	return false


func _find_next_index(from_index: int) -> int:
	if step_mode == "pitch":
		return mini(current_events.size() - 1, from_index + 1)
	for index in range(from_index + 1, current_events.size()):
		if str(current_events[index].get("type", "")) != "pitch":
			return index
	return current_events.size() - 1


func _find_previous_index(from_index: int) -> int:
	if step_mode == "pitch":
		return maxi(0, from_index - 1)
	for index in range(from_index - 1, -1, -1):
		if str(current_events[index].get("type", "")) != "pitch":
			return index
	return 0


func _finalize_live_game() -> void:
	if current_game == null or bool(current_game.played):
		return
	var away_team = LeagueState.get_team(str(current_game.away_team_id))
	var home_team = LeagueState.get_team(str(current_game.home_team_id))
	if away_team == null or home_team == null:
		return
	var committed_package: Dictionary = SimulationEngine.commit_prepared_live_game(current_game, away_team, home_team, current_live_package)
	current_events.clear()
	for event_value in committed_package.get("play_events", []):
		if event_value is Dictionary:
			current_events.append((event_value as Dictionary).duplicate(true))
	current_event_index = maxi(0, current_events.size() - 1)
	var finalize_report: Dictionary = LeagueState.finalize_current_day_if_ready()
	auto_play_active = false
	LeagueState.clear_active_live_game()
	var home_message_lines: Array[String] = []
	home_message_lines.append("今日のまとめ")
	home_message_lines.append("%s のライブ試合を終了しました。" % str(current_game.date_label))
	home_message_lines.append(_build_postgame_summary_text())
	var controlled_team: TeamData = LeagueState.get_controlled_team()
	if controlled_team != null:
		home_message_lines.append("%s: %d勝 %d敗 %d分" % [
			controlled_team.name,
			int(controlled_team.standings["wins"]),
			int(controlled_team.standings["losses"]),
			int(controlled_team.standings["draws"])
		])
	if bool(finalize_report.get("day_completed", false)):
		home_message_lines.append("この日の進行は完了しています。")
		var transition_report: Array[String] = finalize_report.get("transition_report", [])
		if not transition_report.is_empty():
			home_message_lines.append("年越し: %s" % transition_report[0])
	LeagueState.set_pending_home_message("\n".join(home_message_lines))
	_refresh_view()
	if bool(finalize_report.get("day_completed", false)):
		var transition_report: Array[String] = finalize_report.get("transition_report", [])
		if transition_report.is_empty():
			note_detail_label.text += "\nこの日の進行が完了しました。"
		else:
			note_detail_label.text += "\nこの日の進行が完了しました。\n年越し: %s" % transition_report[0]


func _get_current_score_value(score_key: String) -> int:
	if current_events.is_empty():
		return 0
	return int(current_events[clampi(current_event_index, 0, current_events.size() - 1)].get(score_key, 0))


func _get_team_name(team_id: String) -> String:
	var team = LeagueState.get_team(team_id)
	return team.name if team != null else team_id


func _get_player_name(player_id: String) -> String:
	if player_id == "":
		return "なし"
	var player = LeagueState.get_player(player_id)
	return player.full_name if player != null else player_id


func _on_back_button_pressed() -> void:
	if current_game != null and not bool(current_game.played):
		note_detail_label.text = "ライブ試合は一発勝負です。\n試合確定まではホームへ戻れません。"
		return
	auto_play_active = false
	get_tree().change_scene_to_file(LEAGUE_HOME_SCENE_PATH)


func _on_auto_button_pressed() -> void:
	if current_game == null or current_events.is_empty():
		return
	auto_play_active = not auto_play_active
	_refresh_view()
	if auto_play_active:
		_run_auto_play()


func _on_previous_button_pressed() -> void:
	return


func _on_next_button_pressed() -> void:
	auto_play_active = false
	if current_game != null and not bool(current_game.played) and current_event_index >= current_events.size() - 1:
		_finalize_live_game()
		return
	if current_event_index < current_events.size() - 1:
		current_event_index = _find_next_index(current_event_index)
	_refresh_view()


func _on_result_button_pressed() -> void:
	auto_play_active = false
	if current_game == null or bool(current_game.played):
		return
	current_event_index = maxi(0, current_events.size() - 1)
	_finalize_live_game()
