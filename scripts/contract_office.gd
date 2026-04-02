extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const FA_MARKET_SCENE_PATH := "res://scenes/FAMarket.tscn"

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var fa_market_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/FAMarketButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var contract_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContractDetailLabel
@onready var contract_player_1_button: Button = $RootScroll/MarginContainer/RootVBox/ContractButtonsVBox/ContractPlayer1Button
@onready var contract_player_2_button: Button = $RootScroll/MarginContainer/RootVBox/ContractButtonsVBox/ContractPlayer2Button
@onready var contract_player_3_button: Button = $RootScroll/MarginContainer/RootVBox/ContractButtonsVBox/ContractPlayer3Button
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel

var _contract_button_player_ids: Array[String] = ["", "", ""]

func _ready() -> void:
	title_label.text = "契約・FA"
	back_button.text = "球団運営へ戻る"
	fa_market_button.text = "FA候補一覧へ"
	contract_player_1_button.text = "契約候補1"
	contract_player_2_button.text = "契約候補2"
	contract_player_3_button.text = "契約候補3"
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	fa_market_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FA_MARKET_SCENE_PATH))
	contract_player_1_button.pressed.connect(func() -> void: _renew_contract_from_slot(0))
	contract_player_2_button.pressed.connect(func() -> void: _renew_contract_from_slot(1))
	contract_player_3_button.pressed.connect(func() -> void: _renew_contract_from_slot(2))
	_refresh_view()

func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が未設定です。"
		contract_detail_label.text = "-"
		return
	var summary: Dictionary = LeagueState.get_controlled_team_contract_summary()
	var expiring_players: Array = summary.get("expiring_players", [])
	var fa_watch_players: Array = summary.get("fa_watch_players", [])
	info_label.text = "%s の契約切れ間近選手を確認し、必要ならその場で更改します。" % team.name
	_contract_button_player_ids = ["", "", ""]
	var lines: Array[String] = []
	if expiring_players.is_empty():
		lines.append("契約切れ間近の選手はいません。")
	else:
		lines.append("残り1年以下の選手:")
		for i in range(mini(3, expiring_players.size())):
			var player: PlayerData = expiring_players[i]
			_contract_button_player_ids[i] = str(player.id)
			lines.append("%d. %s / 残り%d年 / 年俸%d / 希望年俸%d / FA志向%d" % [
				i + 1,
				player.full_name,
				int(player.contract_years_left),
				int(player.salary),
				int(player.desired_salary),
				int(player.fa_interest)
			])
	if not fa_watch_players.is_empty():
		var fa_names: Array[String] = []
		for i in range(mini(5, fa_watch_players.size())):
			var fa_player: PlayerData = fa_watch_players[i]
			fa_names.append("%s(FA志向%d)" % [fa_player.full_name, int(fa_player.fa_interest)])
		lines.append("FA注意: " + ", ".join(fa_names))
	contract_detail_label.text = "\n".join(lines)
	var buttons: Array[Button] = [contract_player_1_button, contract_player_2_button, contract_player_3_button]
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		if _contract_button_player_ids[i] != "":
			button.visible = true
			button.disabled = false
			button.text = "%s を2年更改" % expiring_players[i].full_name
		else:
			button.visible = false
			button.disabled = true

func _renew_contract_from_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _contract_button_player_ids.size():
		return
	var player_id: String = _contract_button_player_ids[slot_index]
	if player_id == "":
		status_label.text = "更改できる選手がいません。"
		return
	var result: Dictionary = LeagueState.renew_controlled_player_contract(player_id, 2)
	status_label.text = str(result.get("message", ""))
	_refresh_view()