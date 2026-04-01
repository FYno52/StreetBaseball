extends Control

const LEAGUE_HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var auto_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/AutoButton
@onready var slow_button: Button = $RootScroll/MarginContainer/RootVBox/SpeedButtonsHBox/SlowButton
@onready var normal_button: Button = $RootScroll/MarginContainer/RootVBox/SpeedButtonsHBox/NormalButton
@onready var fast_button: Button = $RootScroll/MarginContainer/RootVBox/SpeedButtonsHBox/FastButton
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
@onready var next_button: Button = $RootScroll/MarginContainer/RootVBox/ControlButtonsHBox/NextButton
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
var selected_command: String = "neutral"


func _ready() -> void:
	_setup_static_text()
	back_button.pressed.connect(_on_back_button_pressed)
	auto_button.pressed.connect(_on_auto_button_pressed)
	slow_button.pressed.connect(func() -> void: _set_auto_speed("slow"))
	normal_button.pressed.connect(func() -> void: _set_auto_speed("normal"))
	fast_button.pressed.connect(func() -> void: _set_auto_speed("fast"))
	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	aggressive_button.pressed.connect(func() -> void: _set_command("aggressive"))
	bunt_button.pressed.connect(func() -> void: _set_command("bunt"))
	advance_button.pressed.connect(func() -> void: _set_command("advance"))
	intentional_walk_button.pressed.connect(func() -> void: _set_command("intentional_walk"))
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
	score_title_label.text = "スコア"
	progress_title_label.text = "進行"
	inning_title_label.text = "イニング"
	base_title_label.text = "塁状況"
	previous_button.text = "前へ"
	next_button.text = "次へ"
	command_title_label.text = "采配・指示"
	aggressive_button.text = "強攻"
	bunt_button.text = "バント"
	advance_button.text = "進塁重視"
	intentional_walk_button.text = "敬遠"
	event_title_label.text = "現在イベント"
	log_title_label.text = "イベントログ"
	line_score_title_label.text = "ラインスコア"
	note_title_label.text = "メモ"


func _load_live_game() -> void:
	current_game = LeagueState.get_selected_game()
	current_events.clear()
	current_live_package.clear()
	current_event_index = 0
	selected_command = "neutral"

	if current_game == null:
		return

	if bool(current_game.played):
		return

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

	if current_game == null:
		header_info_label.text = "今日のライブ試合がありません。"
		score_detail_label.text = "-"
		progress_detail_label.text = "-"
		inning_detail_label.text = "-"
		base_detail_label.text = "-"
		command_vbox.visible = false
		event_detail_label.text = "ホーム画面から当日の試合に入ってください。"
		log_detail_label.text = "イベントログはまだありません。"
		line_score_detail_label.text = "-"
		note_detail_label.text = "担当球団の当日試合だけ、この画面でライブ進行できます。"
		previous_button.disabled = true
		next_button.disabled = true
		auto_button.disabled = true
		auto_button.text = "オート再生"
		return

	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	header_info_label.text = "%s | %s vs %s" % [str(current_game.date_label), away_name, home_name]
	command_vbox.visible = true

	if current_events.is_empty():
		score_detail_label.text = "%s vs %s\n試合準備中" % [away_name, home_name]
		progress_detail_label.text = "イベント生成中\n速度: %s" % _get_auto_speed_label()
		inning_detail_label.text = "試合前"
		base_detail_label.text = "走者なし"
		command_status_label.text = _build_command_status_text()
		event_detail_label.text = "まだライブイベントがありません。"
		log_detail_label.text = "イベントログはまだありません。"
		line_score_detail_label.text = _build_empty_line_score_text(away_name, home_name)
		note_detail_label.text = "試合イベントを準備中です。"
		previous_button.disabled = true
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

	previous_button.disabled = current_event_index <= 0
	auto_button.disabled = false
	auto_button.text = "オート停止" if auto_play_active else "オート再生"
	if current_event_index >= current_events.size() - 1:
		next_button.disabled = false
		next_button.text = "試合確定"
	else:
		next_button.disabled = false
		next_button.text = "次へ"
	_refresh_command_buttons()


func _build_score_text(current_event: Dictionary) -> String:
	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	return "%s %d - %d %s" % [
		away_name,
		int(current_event.get("away_score", 0)),
		int(current_event.get("home_score", 0)),
		home_name,
	]


func _build_progress_text() -> String:
	var state_text: String = "オート再生中 (%s)" % _get_auto_speed_label() if auto_play_active else "手動進行中"
	return "%d / %d\n%s" % [current_event_index + 1, current_events.size(), state_text]


func _build_inning_text(current_event: Dictionary) -> String:
	match str(current_event.get("type", "")):
		"game_start":
			return "試合開始\n先攻: %s" % _get_team_name(str(current_game.away_team_id))
		"half_inning_start":
			return "%s\n攻撃: %s\n投手: %s" % [
				_format_half_inning_label(int(current_event.get("inning", 0)), str(current_event.get("side", ""))),
				str(current_event.get("offense_team_name", "")),
				str(current_event.get("pitcher_name", "")),
			]
		"pitch":
			return "%s\n打者: %s\n投手: %s\n%d球目" % [
				_format_half_inning_label(int(current_event.get("inning", 0)), str(current_event.get("side", ""))),
				str(current_event.get("batter_name", "")),
				str(current_event.get("pitcher_name", "")),
				int(current_event.get("pitch_number", 0)),
			]
		"at_bat":
			return "%s\n打者: %s\n投手: %s\nアウト: %d" % [
				_format_half_inning_label(int(current_event.get("inning", 0)), str(current_event.get("side", ""))),
				str(current_event.get("batter_name", "")),
				str(current_event.get("pitcher_name", "")),
				int(current_event.get("outs", 0)),
			]
		"half_inning":
			return "%s 終了\n攻撃: %s\nこの回: %d点" % [
				_format_half_inning_label(int(current_event.get("inning", 0)), str(current_event.get("side", ""))),
				str(current_event.get("offense_team_name", "")),
				int(current_event.get("runs_scored", 0)),
			]
		"pitching_summary":
			return "投手リレー"
		"game_end":
			return "試合終了"
		_:
			return "-"


func _build_base_state_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	if event_type in ["half_inning_start", "pitch", "at_bat", "half_inning"]:
		return _format_base_state(current_event.get("bases", [false, false, false]))
	if event_type == "game_start":
		return "走者なし"
	return "次のイベントで表示"


func _build_event_text(current_event: Dictionary) -> String:
	match str(current_event.get("type", "")):
		"game_start":
			return "試合を開始します。"
		"half_inning_start":
			return "%sの攻撃開始\n登板中: %s" % [
				str(current_event.get("offense_team_name", "")),
				str(current_event.get("pitcher_name", "")),
			]
		"pitch":
			return "%s vs %s\n%d球目: %s\n球種: %s / コース: %s\nカウント %d-%d" % [
				str(current_event.get("batter_name", "")),
				str(current_event.get("pitcher_name", "")),
				int(current_event.get("pitch_number", 0)),
				str(current_event.get("pitch_result_label", "")),
				str(current_event.get("pitch_type_label", "")),
				str(current_event.get("pitch_zone_label", "")),
				int(current_event.get("balls_after", 0)),
				int(current_event.get("strikes_after", 0)),
			]
		"at_bat":
			var lines: Array[String] = []
			lines.append("%s vs %s" % [str(current_event.get("batter_name", "")), str(current_event.get("pitcher_name", ""))])
			lines.append(str(current_event.get("result_label", "")))
			lines.append("カウント %d-%d / %d球" % [
				int(current_event.get("balls", 0)),
				int(current_event.get("strikes", 0)),
				int(current_event.get("pitch_count", 0)),
			])
			var command_name: String = _get_command_display_name(str(current_event.get("command_profile", "neutral")))
			if command_name != "通常":
				lines.append("指示: %s" % command_name)
			var batted_ball_text: String = _build_batted_ball_text(current_event)
			if batted_ball_text != "":
				lines.append(batted_ball_text)
			var pitch_result_summary: String = str(current_event.get("pitch_result_summary", ""))
			if pitch_result_summary != "":
				lines.append(pitch_result_summary)
			var play_note: String = str(current_event.get("play_note", ""))
			if play_note != "":
				lines.append(play_note)
			var runs_scored: int = int(current_event.get("runs_scored", 0))
			if runs_scored > 0:
				lines.append("この打席で %d 点" % runs_scored)
			return "\n".join(lines)
		"half_inning":
			return "%s 攻撃終了\nこの回の得点: %d" % [
				str(current_event.get("offense_team_name", "")),
				int(current_event.get("runs_scored", 0)),
			]
		"pitching_summary":
			return _build_pitching_summary_text(current_event)
		"game_end":
			return "勝利投手: %s\n敗戦投手: %s\nセーブ: %s" % [
				_get_player_name(str(current_event.get("winning_pitcher_id", ""))),
				_get_player_name(str(current_event.get("losing_pitcher_id", ""))),
				_get_player_name(str(current_event.get("save_pitcher_id", ""))),
			]
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
		lines.append("%s  %dアウト  自責%d  %s" % [
			str(pitcher_row.get("pitcher_name", "")),
			int(pitcher_row.get("outs", 0)),
			int(pitcher_row.get("earned_runs", 0)),
			" / ".join(tags),
		])
	if lines.is_empty():
		return "投手リレーはありません。"
	return "\n".join(lines)


func _build_line_score_text_from_events(event_source: Array) -> String:
	if current_game == null:
		return "-"

	var away_runs_by_inning: Array[int] = []
	var home_runs_by_inning: Array[int] = []
	for _inning in range(9):
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

	var inning_header: Array[String] = []
	var away_line: Array[String] = []
	var home_line: Array[String] = []
	for inning in range(9):
		inning_header.append(str(inning + 1))
		away_line.append(str(away_runs_by_inning[inning]))
		home_line.append(str(home_runs_by_inning[inning]))

	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	var away_total: int = _get_current_score_value("away_score")
	var home_total: int = _get_current_score_value("home_score")
	return "回  %s\n%s: %s | %d\n%s: %s | %d" % [
		" ".join(inning_header),
		away_name,
		" ".join(away_line),
		away_total,
		home_name,
		" ".join(home_line),
		home_total,
	]


func _build_empty_line_score_text(away_name: String, home_name: String) -> String:
	return "回  1 2 3 4 5 6 7 8 9\n%s: - - - - - - - - -\n%s: - - - - - - - - -" % [away_name, home_name]


func _build_note_text(current_event: Dictionary) -> String:
	match str(current_event.get("type", "")):
		"game_start":
			return "ここから試合を順番に進めていきます。"
		"half_inning_start":
			return "このイニングの攻撃が始まります。"
		"pitch":
			return "球種: %s\nコース: %s\n一球ごとの結果とカウントを表示します。" % [
				str(current_event.get("pitch_type_label", "")),
				str(current_event.get("pitch_zone_label", "")),
			]
		"at_bat":
			return "打席前アウト: %d\n打席後アウト: %d\n球数: %d球 (%d-%d)\nこの打席の指示: %s" % [
				int(current_event.get("outs_before", 0)),
				int(current_event.get("outs", 0)),
				int(current_event.get("pitch_count", 0)),
				int(current_event.get("balls", 0)),
				int(current_event.get("strikes", 0)),
				_get_command_display_name(str(current_event.get("command_profile", "neutral"))),
			]
		"half_inning":
			return "この回の攻撃はここで終了です。"
		"pitching_summary":
			return "投手起用の結果をまとめています。"
		"game_end":
			return "ライブ試合の最終結果です。ホームへ戻ると反映を確認できます。"
		_:
			return "試合進行に合わせて関連情報を表示します。"


func _build_log_text() -> String:
	var lines: Array[String] = []
	for event_index in range(current_event_index + 1):
		var event_data: Dictionary = current_events[event_index]
		match str(event_data.get("type", "")):
			"game_start":
				lines.append("試合開始")
			"half_inning_start":
				lines.append("%s 開始 (%s)" % [
					_format_half_inning_label(int(event_data.get("inning", 0)), str(event_data.get("side", ""))),
					str(event_data.get("pitcher_name", "")),
				])
			"pitch":
				lines.append("%s vs %s  %d球目 %s (%s / %s)" % [
					str(event_data.get("batter_name", "")),
					str(event_data.get("pitcher_name", "")),
					int(event_data.get("pitch_number", 0)),
					str(event_data.get("pitch_result_label", "")),
					str(event_data.get("pitch_type_label", "")),
					str(event_data.get("pitch_zone_label", "")),
				])
			"at_bat":
				var line: String = "%s vs %s  %s" % [
					str(event_data.get("batter_name", "")),
					str(event_data.get("pitcher_name", "")),
					str(event_data.get("result_label", "")),
				]
				var batted_ball_text: String = _build_batted_ball_text(event_data)
				if batted_ball_text != "":
					line += " (%s)" % batted_ball_text
				var play_note: String = str(event_data.get("play_note", ""))
				if play_note != "":
					line += " [%s]" % play_note
				lines.append(line)
			"half_inning":
				lines.append("%s  %d点" % [
					_format_half_inning_label(int(event_data.get("inning", 0)), str(event_data.get("side", ""))),
					int(event_data.get("runs_scored", 0)),
				])
			"pitching_summary":
				lines.append("%s投手リレー" % ("ビジター" if str(event_data.get("side", "")) == "away" else "ホーム"))
			"game_end":
				lines.append("試合終了")
	if lines.is_empty():
		return "イベントログはまだありません。"
	return "\n".join(lines)


func _build_batted_ball_text(event_data: Dictionary) -> String:
	var ball_label: String = str(event_data.get("batted_ball_label", ""))
	var direction_label: String = str(event_data.get("batted_ball_direction_label", ""))
	if ball_label == "" or ball_label in ["ボール判定", "該当なし"]:
		return ""
	if direction_label == "" or direction_label == "方向なし":
		return ball_label
	return "%s / %s" % [ball_label, direction_label]


func _format_base_state(base_value) -> String:
	var bases: Array = [false, false, false]
	if base_value is Array and (base_value as Array).size() >= 3:
		bases = (base_value as Array).duplicate()
	return "一塁 %s\n二塁 %s\n三塁 %s" % [
		"●" if bool(bases[0]) else "○",
		"●" if bool(bases[1]) else "○",
		"●" if bool(bases[2]) else "○",
	]


func _format_half_inning_label(inning: int, side: String) -> String:
	return "%d回%s" % [inning, "表" if side == "top" else "裏"]


func _build_command_status_text() -> String:
	return "現在の指示: %s" % _get_command_display_name(selected_command)


func _refresh_command_buttons() -> void:
	var command_disabled: bool = current_game == null or bool(current_game.played)
	aggressive_button.disabled = command_disabled or selected_command == "aggressive"
	bunt_button.disabled = command_disabled or selected_command == "bunt"
	advance_button.disabled = command_disabled or selected_command == "advance"
	intentional_walk_button.disabled = command_disabled or selected_command == "intentional_walk"


func _refresh_speed_buttons() -> void:
	slow_button.disabled = auto_play_speed == "slow"
	normal_button.disabled = auto_play_speed == "normal"
	fast_button.disabled = auto_play_speed == "fast"


func _set_command(command_id: String) -> void:
	if current_game == null or bool(current_game.played):
		return
	selected_command = command_id
	_regenerate_live_preview()
	_refresh_view()


func _set_auto_speed(speed_id: String) -> void:
	auto_play_speed = speed_id
	_refresh_view()


func _get_command_display_name(command_id: String) -> String:
	match command_id:
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


func _get_auto_speed_label() -> String:
	match auto_play_speed:
		"slow":
			return "低速"
		"fast":
			return "高速"
		_:
			return "標準"


func _get_auto_play_interval() -> float:
	match auto_play_speed:
		"slow":
			return 0.8
		"fast":
			return 0.18
		_:
			return 0.45


func _run_auto_play() -> void:
	while auto_play_active and is_inside_tree():
		if current_events.is_empty():
			auto_play_active = false
			break
		if current_event_index >= current_events.size() - 1:
			auto_play_active = false
			if current_game != null and not bool(current_game.played):
				_finalize_live_game()
			_refresh_view()
			break
		current_event_index += 1
		_refresh_view()
		if _should_pause_auto_play(current_events[current_event_index]):
			auto_play_active = false
			_refresh_view()
			break
		await get_tree().create_timer(_get_auto_play_interval()).timeout


func _should_pause_auto_play(event_data: Dictionary) -> bool:
	if str(event_data.get("type", "")) == "pitch":
		return false
	if str(event_data.get("type", "")) != "at_bat":
		return false
	if int(event_data.get("runs_scored", 0)) > 0:
		return true
	var bases = event_data.get("bases", [false, false, false])
	if bases is Array and (bases as Array).size() >= 3 and bool(bases[0]) and bool(bases[1]) and bool(bases[2]):
		return true
	var inning: int = int(event_data.get("inning", 0))
	var away_score: int = int(event_data.get("away_score", 0))
	var home_score: int = int(event_data.get("home_score", 0))
	if inning >= 8 and away_score == home_score:
		return true
	if inning >= 8 and bases is Array and (bases as Array).size() >= 3 and (bool(bases[1]) or bool(bases[2])):
		return true
	return false


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
	auto_play_active = false
	_refresh_view()


func _get_current_score_value(score_key: String) -> int:
	if current_events.is_empty():
		return 0
	var current_event: Dictionary = current_events[clampi(current_event_index, 0, current_events.size() - 1)]
	return int(current_event.get(score_key, 0))


func _get_team_name(team_id: String) -> String:
	var team = LeagueState.get_team(team_id)
	return team.name if team != null else team_id


func _get_player_name(player_id: String) -> String:
	if player_id == "":
		return "なし"
	var player = LeagueState.get_player(player_id)
	return player.full_name if player != null else player_id


func _on_back_button_pressed() -> void:
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
	auto_play_active = false
	if current_event_index > 0:
		current_event_index -= 1
	_refresh_view()


func _on_next_button_pressed() -> void:
	auto_play_active = false
	if current_game != null and not bool(current_game.played) and current_event_index >= current_events.size() - 1:
		_finalize_live_game()
		return
	if current_event_index < current_events.size() - 1:
		current_event_index += 1
	_refresh_view()
