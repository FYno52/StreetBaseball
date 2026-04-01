extends Control

const GAME_DETAIL_SCENE_PATH := "res://scenes/GameDetail.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var auto_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/AutoButton
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
var current_event_index: int = 0
var auto_play_active: bool = false

func _ready() -> void:
	title_label.text = "試合再生"
	back_button.text = "試合詳細へ戻る"
	auto_button.text = "オート再生"
	header_info_label.text = ""
	score_title_label.text = "スコア"
	progress_title_label.text = "進行"
	inning_title_label.text = "イニング"
	base_title_label.text = "塁状況"
	previous_button.text = "前へ"
	next_button.text = "次へ"
	event_title_label.text = "現在イベント"
	log_title_label.text = "イベントログ"
	line_score_title_label.text = "ラインスコア"
	note_title_label.text = "メモ"

	back_button.pressed.connect(_on_back_button_pressed)
	auto_button.pressed.connect(_on_auto_button_pressed)
	previous_button.pressed.connect(_on_previous_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)

	_load_selected_game()
	_refresh_view()

func _exit_tree() -> void:
	auto_play_active = false

func _load_selected_game() -> void:
	current_game = LeagueState.get_selected_game()
	current_events.clear()
	current_event_index = 0

	if current_game == null or not bool(current_game.played):
		return

	for event_value in current_game.play_events:
		if event_value is Dictionary:
			current_events.append((event_value as Dictionary).duplicate(true))

func _refresh_view() -> void:
	if current_game == null:
		header_info_label.text = "試合が選択されていません。"
		score_detail_label.text = "-"
		progress_detail_label.text = "-"
		inning_detail_label.text = "-"
		base_detail_label.text = "-"
		event_detail_label.text = "試合詳細から開き直してください。"
		log_detail_label.text = "イベントログはありません。"
		line_score_detail_label.text = "-"
		note_detail_label.text = "まだ表示できる情報がありません。"
		previous_button.disabled = true
		next_button.disabled = true
		auto_button.disabled = true
		return

	var away_name: String = _get_team_name(str(current_game.away_team_id))
	var home_name: String = _get_team_name(str(current_game.home_team_id))
	header_info_label.text = "%s  |  %s vs %s" % [str(current_game.date_label), away_name, home_name]
	score_detail_label.text = "%s %d - %d %s" % [
		away_name,
		int(current_game.away_score),
		int(current_game.home_score),
		home_name
	]

	if current_events.is_empty():
		progress_detail_label.text = "0 / 0"
		inning_detail_label.text = "イベント未作成"
		base_detail_label.text = "打席単位実装後に反映します。"
		event_detail_label.text = "play_events が空です。"
		log_detail_label.text = "\n".join(current_game.log_lines) if not current_game.log_lines.is_empty() else "詳細ログはまだありません。"
		line_score_detail_label.text = _build_line_score_text()
		note_detail_label.text = "まずはイベント列を持つ試合から再生します。"
		previous_button.disabled = true
		next_button.disabled = true
		auto_button.disabled = true
		return

	current_event_index = clampi(current_event_index, 0, current_events.size() - 1)
	var current_event: Dictionary = current_events[current_event_index]
	progress_detail_label.text = "%d / %d  %s" % [
		current_event_index + 1,
		current_events.size(),
		"再生中" if auto_play_active else "停止中"
	]
	inning_detail_label.text = _build_inning_text(current_event)
	base_detail_label.text = _build_base_state_text(current_event)
	event_detail_label.text = _build_event_text(current_event)
	log_detail_label.text = _build_log_text()
	line_score_detail_label.text = _build_line_score_text()
	note_detail_label.text = _build_note_text(current_event)

	previous_button.disabled = current_event_index <= 0
	next_button.disabled = current_event_index >= current_events.size() - 1
	auto_button.disabled = false
	auto_button.text = "オート停止" if auto_play_active else "オート再生"

func _build_inning_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	if event_type == "half_inning":
		var side_label: String = "表" if str(current_event.get("side", "")) == "top" else "裏"
		return "%d回%s\n攻撃: %s\nアウト: %d" % [
			int(current_event.get("inning", 0)),
			side_label,
			str(current_event.get("offense_team_name", "")),
			int(current_event.get("outs", 0))
		]
	if event_type == "game_start":
		return "試合開始前\n初回表から再生します。"
	if event_type == "pitching_summary":
		return "投手リレー確認"
	if event_type == "game_end":
		return "試合終了"
	return "-"

func _build_base_state_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	if event_type == "half_inning":
		return "走者なし\n打席単位実装後に反映します。"
	if event_type == "game_start":
		return "開始時点: 走者なし"
	if event_type == "game_end":
		return "試合終了時点"
	return "塁状況は後で細かくします。"

func _build_event_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	match event_type:
		"game_start":
			return "ここから試合イベントを順に再生します。"
		"half_inning":
			var side_label: String = "表" if str(current_event.get("side", "")) == "top" else "裏"
			return "%d回%sの攻撃で %d点\nスコア: %d - %d" % [
				int(current_event.get("inning", 0)),
				side_label,
				int(current_event.get("runs_scored", 0)),
				int(current_event.get("away_score", 0)),
				int(current_event.get("home_score", 0))
			]
		"pitching_summary":
			return _build_pitching_summary_text(current_event)
		"game_end":
			return "勝利投手: %s\n敗戦投手: %s\nセーブ投手: %s" % [
				_get_player_name(str(current_event.get("winning_pitcher_id", ""))),
				_get_player_name(str(current_event.get("losing_pitcher_id", ""))),
				_get_player_name(str(current_event.get("save_pitcher_id", "")))
			]
		_:
			return "イベント情報はありません。"

func _build_pitching_summary_text(current_event: Dictionary) -> String:
	var lines: Array[String] = []
	var pitchers: Array = current_event.get("pitchers", [])
	for pitcher_value in pitchers:
		if not (pitcher_value is Dictionary):
			continue
		var pitcher_row: Dictionary = pitcher_value
		var tags: Array[String] = []
		if bool(pitcher_row.get("is_starter", false)):
			tags.append("先発")
		if str(pitcher_row.get("decision", "none")) == "win":
			tags.append("勝")
		elif str(pitcher_row.get("decision", "none")) == "loss":
			tags.append("敗")
		if bool(pitcher_row.get("save", false)):
			tags.append("S")
		if bool(pitcher_row.get("hold", false)):
			tags.append("H")
		lines.append("%s  %dアウト  失点%d  %s" % [
			str(pitcher_row.get("pitcher_name", "")),
			int(pitcher_row.get("outs", 0)),
			int(pitcher_row.get("earned_runs", 0)),
			" / ".join(tags)
		])
	if lines.is_empty():
		return "投手リレー情報はありません。"
	return "\n".join(lines)

func _build_line_score_text() -> String:
	if current_game == null:
		return "-"

	var away_runs_by_inning: Array[int] = []
	var home_runs_by_inning: Array[int] = []
	for _inning in range(9):
		away_runs_by_inning.append(0)
		home_runs_by_inning.append(0)

	for event_value in current_events:
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
	return "回:  %s\n%s: %s | %d\n%s: %s | %d" % [
		" ".join(inning_header),
		away_name,
		" ".join(away_line),
		int(current_game.away_score),
		home_name,
		" ".join(home_line),
		int(current_game.home_score)
	]

func _build_note_text(current_event: Dictionary) -> String:
	var event_type: String = str(current_event.get("type", ""))
	match event_type:
		"game_start":
			return "まずはイニング単位の流れを確認する段階です。"
		"half_inning":
			return "次はこの部分を打席単位へ細かくしていきます。"
		"pitching_summary":
			return "継投イベントは将来の采配判断に直結します。"
		"game_end":
			return "ここから先はダイジェストやライブ観戦へ発展させます。"
		_:
			return "試合画面は段階的に拡張していきます。"

func _build_log_text() -> String:
	var lines: Array[String] = []
	for event_index in range(current_event_index + 1):
		var event_data: Dictionary = current_events[event_index]
		var event_type: String = str(event_data.get("type", ""))
		match event_type:
			"game_start":
				lines.append("試合開始")
			"half_inning":
				var side_label: String = "表" if str(event_data.get("side", "")) == "top" else "裏"
				lines.append("%d回%s  %d点" % [
					int(event_data.get("inning", 0)),
					side_label,
					int(event_data.get("runs_scored", 0))
				])
			"pitching_summary":
				lines.append("%s投手リレー" % ("ビジター" if str(event_data.get("side", "")) == "away" else "ホーム"))
			"game_end":
				lines.append("試合終了")
	if lines.is_empty():
		return "イベントログはまだありません。"
	return "\n".join(lines)

func _run_auto_play() -> void:
	while auto_play_active and is_inside_tree():
		if current_events.is_empty():
			auto_play_active = false
			break
		if current_event_index >= current_events.size() - 1:
			auto_play_active = false
			_refresh_view()
			break
		current_event_index += 1
		_refresh_view()
		await get_tree().create_timer(0.45).timeout

func _on_back_button_pressed() -> void:
	auto_play_active = false
	get_tree().change_scene_to_file(GAME_DETAIL_SCENE_PATH)

func _on_auto_button_pressed() -> void:
	if current_events.is_empty():
		return
	if auto_play_active:
		auto_play_active = false
		_refresh_view()
		return
	auto_play_active = true
	_refresh_view()
	_run_auto_play()

func _on_previous_button_pressed() -> void:
	if auto_play_active or current_events.is_empty():
		return
	current_event_index = maxi(0, current_event_index - 1)
	_refresh_view()

func _on_next_button_pressed() -> void:
	if auto_play_active or current_events.is_empty():
		return
	current_event_index = mini(current_events.size() - 1, current_event_index + 1)
	_refresh_view()

func _get_team_name(team_id: String) -> String:
	var team = LeagueState.get_team(team_id)
	if team == null:
		return team_id
	return str(team.name)

func _get_player_name(player_id: String) -> String:
	if player_id == "":
		return "なし"
	var player = LeagueState.get_player(player_id)
	if player == null:
		return player_id
	return str(player.full_name)
