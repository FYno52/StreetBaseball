extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var summary_label: Label = $RootScroll/MarginContainer/RootVBox/SummaryLabel
@onready var proposal_title_label: Label = $RootScroll/MarginContainer/RootVBox/ProposalTitleLabel
@onready var proposal_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ProposalDetailLabel
@onready var trade_button_1: Button = $RootScroll/MarginContainer/RootVBox/TradeButtonsVBox/Trade1Button
@onready var trade_button_2: Button = $RootScroll/MarginContainer/RootVBox/TradeButtonsVBox/Trade2Button
@onready var trade_button_3: Button = $RootScroll/MarginContainer/RootVBox/TradeButtonsVBox/Trade3Button
@onready var note_label: Label = $RootScroll/MarginContainer/RootVBox/NoteLabel

var _proposal_give_ids: Array[String] = ["", "", ""]
var _proposal_take_ids: Array[String] = ["", "", ""]

func _ready() -> void:
	title_label.text = "トレード"
	back_button.text = "球団運営へ戻る"
	proposal_title_label.text = "おすすめ交換案"
	trade_button_1.text = "交換案1を実行"
	trade_button_2.text = "交換案2を実行"
	trade_button_3.text = "交換案3を実行"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	trade_button_1.pressed.connect(func() -> void: _run_trade_slot(0))
	trade_button_2.pressed.connect(func() -> void: _run_trade_slot(1))
	trade_button_3.pressed.connect(func() -> void: _run_trade_slot(2))
	_refresh_view()

func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		summary_label.text = "-"
		proposal_detail_label.text = "-"
		note_label.text = ""
		return

	info_label.text = "%s の戦力整理用に、簡易トレード案を表示します。" % team.name
	summary_label.text = "今日の年間イベント\n%s\n\n今は1対1の簡易トレードのみです。" % LeagueState.get_calendar_summary_text()

	var proposals: Array[Dictionary] = []
	if LeagueState.has_method("get_controlled_team_trade_proposals"):
		proposals = LeagueState.get_controlled_team_trade_proposals()
	_proposal_give_ids = ["", "", ""]
	_proposal_take_ids = ["", "", ""]

	if proposals.is_empty():
		proposal_detail_label.text = "現在出せるおすすめトレード案はありません。"
	else:
		var lines: Array[String] = []
		for i in range(mini(3, proposals.size())):
			var proposal: Dictionary = proposals[i]
			lines.append("%d. 相手球団: %s" % [i + 1, str(proposal.get("other_team_name", ""))])
			lines.append("  放出: %s (総合%d)" % [str(proposal.get("give_player_name", "")), int(proposal.get("give_player_overall", 0))])
			lines.append("  獲得: %s (総合%d)" % [str(proposal.get("take_player_name", "")), int(proposal.get("take_player_overall", 0))])
			lines.append("")
			_proposal_give_ids[i] = str(proposal.get("give_player_id", ""))
			_proposal_take_ids[i] = str(proposal.get("take_player_id", ""))
		proposal_detail_label.text = "\n".join(lines)

	var buttons: Array[Button] = [trade_button_1, trade_button_2, trade_button_3]
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		if i < proposals.size():
			button.visible = true
			button.disabled = false
			button.text = "実行: %s" % str(proposals[i].get("summary", "交換案"))
		else:
			button.visible = false
			button.disabled = true

	if note_label.text == "":
		note_label.text = "後で交渉難度や複数人トレードを足せるよう、今は最小の交換案だけにしています。"

func _run_trade_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _proposal_give_ids.size():
		return
	var give_id: String = _proposal_give_ids[slot_index]
	var take_id: String = _proposal_take_ids[slot_index]
	if give_id == "" or take_id == "":
		return
	if not LeagueState.has_method("execute_controlled_team_trade"):
		note_label.text = "トレード処理をまだ利用できません。"
		return
	var result: Dictionary = LeagueState.execute_controlled_team_trade(give_id, take_id)
	note_label.text = str(result.get("message", ""))
	_refresh_view()
