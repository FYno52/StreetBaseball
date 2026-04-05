extends Control

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var current_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/CurrentTabButton
@onready var history_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/HistoryTabButton
@onready var franchise_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/FranchiseTabButton
@onready var operation_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/OperationTabButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_grid: GridContainer = $RootScroll/MarginContainer/RootVBox/SummaryGrid
@onready var current_season_card: VBoxContainer = $RootScroll/MarginContainer/RootVBox/SummaryGrid/CurrentSeasonCard
@onready var current_season_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/CurrentSeasonCard/CurrentSeasonTitleLabel
@onready var current_season_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/CurrentSeasonCard/CurrentSeasonDetailLabel
@onready var controlled_history_card: VBoxContainer = $RootScroll/MarginContainer/RootVBox/SummaryGrid/ControlledHistoryCard
@onready var controlled_history_title_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/ControlledHistoryCard/ControlledHistoryTitleLabel
@onready var controlled_history_detail_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryGrid/ControlledHistoryCard/ControlledHistoryDetailLabel
@onready var content_columns: HBoxContainer = $RootScroll/MarginContainer/RootVBox/ContentColumns
@onready var left_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftVBox
@onready var history_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftVBox/HistoryTitleLabel
@onready var history_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/LeftVBox/HistoryDetailLabel
@onready var right_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox
@onready var record_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/RecordTitleLabel
@onready var record_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/RecordDetailLabel
@onready var operation_title_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/OperationTitleLabel
@onready var operation_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContentColumns/RightVBox/OperationDetailLabel

var current_tab: String = "current"


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "records",
		"section_label": "RECORDS",
		"sub_tab": "records",
		"sub_tabs": [
			{"key": "records", "label": "RECORDS", "scene": "res://scenes/RecordRoom.tscn"},
			{"key": "info", "label": "INFO", "scene": "res://scenes/LeagueInfo.tscn"},
			{"key": "calendar", "label": "CALENDAR", "scene": "res://scenes/CalendarScene.tscn"}
		],
		"top_right": "RECORDS"
	})
	title_label.visible = false
	back_button.text = "ホームへ戻る"
	current_tab_button.text = "今季"
	history_tab_button.text = "歴代"
	franchise_tab_button.text = "球団史"
	operation_tab_button.text = "運営ログ"
	info_label.text = "記録と履歴を確認するページです。今季の注目記録、歴代推移、担当球団の通算実績、今年の運営状況を見返せます。"
	current_season_title_label.text = "今季の主要記録"
	controlled_history_title_label.text = "担当球団の通算実績"
	history_title_label.text = "年度推移"
	record_title_label.text = "球団史ハイライト"
	operation_title_label.text = "今年の運営ログ"

	back_button.pressed.connect(_on_back_button_pressed)
	current_tab_button.pressed.connect(_on_tab_pressed.bind("current"))
	history_tab_button.pressed.connect(_on_tab_pressed.bind("history"))
	franchise_tab_button.pressed.connect(_on_tab_pressed.bind("franchise"))
	operation_tab_button.pressed.connect(_on_tab_pressed.bind("operation"))

	_refresh_view()


func _refresh_view() -> void:
	_refresh_current_season()
	_refresh_controlled_history()
	_refresh_season_history()
	_refresh_record_highlights()
	_refresh_operation_log()
	_refresh_tab_visibility()


func _refresh_current_season() -> void:
	var batting: Dictionary = LeagueState.get_league_batting_leaders(3)
	var pitching: Dictionary = LeagueState.get_league_pitching_leaders(3)
	var lines: Array[String] = []
	lines.append("日付: %s" % LeagueState.get_current_date_label())

	var avg_players: Array = batting.get("avg", [])
	if not avg_players.is_empty():
		lines.append("打率: %s  %.3f" % [avg_players[0].full_name, avg_players[0].get_batting_average()])

	var hr_players: Array = batting.get("hr", [])
	if not hr_players.is_empty():
		lines.append("本塁打: %s  %d本" % [hr_players[0].full_name, int(hr_players[0].batting_stats["hr"])])

	var win_players: Array = pitching.get("wins", [])
	if not win_players.is_empty():
		lines.append("最多勝: %s  %d勝" % [win_players[0].full_name, int(win_players[0].pitching_stats["wins"])])

	var save_players: Array = pitching.get("saves", [])
	if not save_players.is_empty():
		lines.append("最多セーブ: %s  %dS" % [save_players[0].full_name, int(save_players[0].pitching_stats["saves"])])

	current_season_detail_label.text = "\n".join(lines)


func _refresh_controlled_history() -> void:
	var summary: Dictionary = LeagueState.get_controlled_team_history_summary()
	if summary.is_empty():
		controlled_history_detail_label.text = "まだ通算実績はありません。"
		return

	var lines: Array[String] = []
	lines.append("球団: %s" % str(summary.get("team_name", "")))
	lines.append("運営年数: %d年" % int(summary.get("seasons", 0)))
	lines.append("通算成績: %d勝 %d敗 %d分" % [
		int(summary.get("total_wins", 0)),
		int(summary.get("total_losses", 0)),
		int(summary.get("total_draws", 0))
	])
	lines.append("優勝: %d回 / 最高順位: %d位" % [
		int(summary.get("championships", 0)),
		int(summary.get("best_rank", 0))
	])
	lines.append("最新の予算: %d / 人気: %d / 年俸総額: %d" % [
		int(summary.get("latest_budget", 0)),
		int(summary.get("latest_fan_support", 0)),
		int(summary.get("latest_total_salary", 0))
	])
	controlled_history_detail_label.text = "\n".join(lines)


func _refresh_season_history() -> void:
	var history: Array[Dictionary] = LeagueState.get_season_history()
	if history.is_empty():
		history_detail_label.text = "まだ年度履歴はありません。"
		return

	var lines: Array[String] = []
	for i in range(history.size() - 1, max(-1, history.size() - 4), -1):
		var entry: Dictionary = history[i]
		lines.append("%d年  優勝: %s / 最下位: %s" % [
			int(entry.get("year", 0)),
			str(entry.get("champion_name", "-")),
			str(entry.get("last_place_name", "-"))
		])
		if str(entry.get("controlled_team_name", "")) != "":
			lines.append("担当球団: %s  %d位  %d勝 %d敗 %d分" % [
				str(entry.get("controlled_team_name", "")),
				int(entry.get("controlled_rank", 0)),
				int(entry.get("controlled_wins", 0)),
				int(entry.get("controlled_losses", 0)),
				int(entry.get("controlled_draws", 0))
			])
		if i > max(-1, history.size() - 4):
			lines.append("")
	history_detail_label.text = "\n".join(lines)


func _refresh_record_highlights() -> void:
	var history: Array[Dictionary] = LeagueState.get_season_history()
	if history.is_empty():
		record_detail_label.text = "球団史ハイライトはまだありません。"
		return

	var best_avg: float = 0.0
	var best_avg_name: String = "-"
	var best_avg_year: int = 0
	var best_hr: int = -1
	var best_hr_name: String = "-"
	var best_hr_year: int = 0

	for entry in history:
		var avg_value: float = float(entry.get("avg_leader_value", 0.0))
		if avg_value > best_avg:
			best_avg = avg_value
			best_avg_name = str(entry.get("avg_leader_name", "-"))
			best_avg_year = int(entry.get("year", 0))

		var hr_value: int = int(entry.get("hr_leader_value", 0))
		if hr_value > best_hr:
			best_hr = hr_value
			best_hr_name = str(entry.get("hr_leader_name", "-"))
			best_hr_year = int(entry.get("year", 0))

	var lines: Array[String] = []
	lines.append("歴代最高打率")
	lines.append("%d年  %s  %.3f" % [best_avg_year, best_avg_name, best_avg])
	lines.append("")
	lines.append("歴代最多本塁打")
	lines.append("%d年  %s  %d本" % [best_hr_year, best_hr_name, best_hr])
	record_detail_label.text = "\n".join(lines)


func _refresh_operation_log() -> void:
	var progress: Dictionary = LeagueState.get_current_operation_progress()
	var overview: Dictionary = LeagueState.get_current_operation_overview()
	var log_entries: Array[Dictionary] = LeagueState.get_current_operation_log()
	var lines: Array[String] = []
	lines.append("進行状況: %d / %d 完了" % [
		int(overview.get("completed_count", 0)),
		int(overview.get("total_count", 0))
	])
	var pending_labels: Array[String] = []
	for item in overview.get("pending_labels", []):
		pending_labels.append(str(item))
	if pending_labels.is_empty():
		lines.append("未完了: なし")
	else:
		lines.append("未完了: %s" % " / ".join(pending_labels))

	var recommended_now: Array[String] = []
	for item in overview.get("recommended_now", []):
		recommended_now.append(str(item))
	if not recommended_now.is_empty():
		lines.append("今やるなら: %s" % " / ".join(recommended_now))
	lines.append("")
	lines.append("完了状況")
	lines.append("ドラフト: %s / 契約更改: %s / FA: %s" % [
		_format_done(progress.get("draft", false)),
		_format_done(progress.get("contract", false)),
		_format_done(progress.get("fa", false))
	])
	lines.append("スポンサー: %s / スタッフ: %s / トレード: %s" % [
		_format_done(progress.get("sponsor", false)),
		_format_done(progress.get("staff", false)),
		_format_done(progress.get("trade", false))
	])
	lines.append("")
	lines.append("最近のログ")
	if log_entries.is_empty():
		lines.append("- まだ運営ログはありません。")
	else:
		for i in range(max(0, log_entries.size() - 5), log_entries.size()):
			var entry: Dictionary = log_entries[i]
			var detail_text: String = str(entry.get("detail", ""))
			lines.append("- %s  %s" % [str(entry.get("date_label", "")), str(entry.get("title", ""))])
			if detail_text != "":
				lines.append("  %s" % detail_text)
	operation_detail_label.text = "\n".join(lines)


func _refresh_tab_visibility() -> void:
	for button in [current_tab_button, history_tab_button, franchise_tab_button, operation_tab_button]:
		button.toggle_mode = true
	current_tab_button.button_pressed = current_tab == "current"
	history_tab_button.button_pressed = current_tab == "history"
	franchise_tab_button.button_pressed = current_tab == "franchise"
	operation_tab_button.button_pressed = current_tab == "operation"

	summary_grid.visible = current_tab == "current" or current_tab == "franchise"
	current_season_card.visible = current_tab == "current"
	controlled_history_card.visible = current_tab == "franchise"
	content_columns.visible = current_tab == "history" or current_tab == "franchise" or current_tab == "operation"

	left_vbox.visible = current_tab == "history"
	history_title_label.visible = current_tab == "history"
	history_detail_label.visible = current_tab == "history"

	right_vbox.visible = current_tab == "franchise" or current_tab == "operation"
	record_title_label.visible = current_tab == "franchise"
	record_detail_label.visible = current_tab == "franchise"
	operation_title_label.visible = current_tab == "operation"
	operation_detail_label.visible = current_tab == "operation"


func _on_tab_pressed(tab_key: String) -> void:
	current_tab = tab_key
	_refresh_tab_visibility()


func _format_done(value: Variant) -> String:
	return "完了" if bool(value) else "未完了"


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)
