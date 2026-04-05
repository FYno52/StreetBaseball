extends Control

const CONTRACT_OFFICE_SCENE_PATH := "res://scenes/ContractOffice.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel
@onready var contract_detail_label: Label = $RootScroll/MarginContainer/RootVBox/ContractDetailLabel
@onready var contract_player_1_button: Button = $RootScroll/MarginContainer/RootVBox/ContractButtonsVBox/ContractPlayer1Button
@onready var contract_player_2_button: Button = $RootScroll/MarginContainer/RootVBox/ContractButtonsVBox/ContractPlayer2Button
@onready var contract_player_3_button: Button = $RootScroll/MarginContainer/RootVBox/ContractButtonsVBox/ContractPlayer3Button
@onready var status_label: Label = $RootScroll/MarginContainer/RootVBox/StatusLabel

var _contract_button_player_ids: Array[String] = ["", "", ""]


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "front_office",
		"section_label": "RENEWALS",
		"sub_tab": "renewals",
		"sub_tabs": [
			{"key": "overview", "label": "OVERVIEW", "scene": CONTRACT_OFFICE_SCENE_PATH},
			{"key": "renewals", "label": "RENEWALS", "scene": "res://scenes/ContractRenewalOffice.tscn"},
			{"key": "fa", "label": "FA MARKET", "scene": "res://scenes/FAMarket.tscn"}
		],
		"top_right": "RENEWALS"
	})
	_setup_static_text()
	_connect_buttons()
	_refresh_view()


func _setup_static_text() -> void:
	title_label.visible = false
	back_button.text = "契約・FAへ戻る"
	contract_player_1_button.text = "2年更改"
	contract_player_2_button.text = "2年更改"
	contract_player_3_button.text = "2年更改"


func _connect_buttons() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(CONTRACT_OFFICE_SCENE_PATH))
	contract_player_1_button.pressed.connect(func() -> void: _renew_contract_from_slot(0))
	contract_player_2_button.pressed.connect(func() -> void: _renew_contract_from_slot(1))
	contract_player_3_button.pressed.connect(func() -> void: _renew_contract_from_slot(2))


func _refresh_view() -> void:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		info_label.text = "担当球団が設定されていません。"
		contract_detail_label.text = "-"
		status_label.text = ""
		return

	var is_contract_period: bool = LeagueState.is_contract_period()
	var summary: Dictionary = LeagueState.get_controlled_team_contract_summary()
	var expiring_players: Array = summary.get("expiring_players", [])
	var fa_watch_players: Array = summary.get("fa_watch_players", [])
	_contract_button_player_ids = ["", "", ""]

	if is_contract_period:
		info_label.text = "%s の契約更改を進めます。まずは期限が近い主力から確認します。" % team.name
	else:
		info_label.text = "%s の契約更改候補を確認します。更改の実行は契約更改期間のみ可能です。" % team.name

	var lines: Array[String] = []
	lines.append("今日のイベント")
	lines.append(LeagueState.get_calendar_summary_text())
	lines.append("")

	if expiring_players.is_empty():
		lines.append("期限が近い選手はいません。")
	else:
		lines.append("優先して確認する選手")
		for i in range(mini(3, expiring_players.size())):
			var player: PlayerData = expiring_players[i]
			_contract_button_player_ids[i] = str(player.id)
			lines.append("%d. %s / 残り%d年 / 年俸 %d / 希望年俸 %d / FA志向 %d" % [
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
		lines.append("")
		lines.append("FA注意: " + ", ".join(fa_names))

	contract_detail_label.text = "\n".join(lines)

	var buttons: Array[Button] = [contract_player_1_button, contract_player_2_button, contract_player_3_button]
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		if _contract_button_player_ids[i] != "":
			button.visible = true
			button.disabled = not is_contract_period
			button.text = "%sを2年更改" % expiring_players[i].full_name
		else:
			button.visible = false
			button.disabled = true

	if is_contract_period:
		status_label.text = "今は契約更改期間です。候補上位3人をすぐ更改できます。"
	else:
		status_label.text = "契約更改は契約更改期間のみ実行できます。"


func _renew_contract_from_slot(slot_index: int) -> void:
	if not LeagueState.is_contract_period():
		status_label.text = "契約更改は契約更改期間のみ実行できます。"
		return
	if slot_index < 0 or slot_index >= _contract_button_player_ids.size():
		return
	var player_id: String = _contract_button_player_ids[slot_index]
	if player_id == "":
		status_label.text = "更改できる選手がいません。"
		return
	var result: Dictionary = LeagueState.renew_controlled_player_contract(player_id, 2)
	status_label.text = str(result.get("message", ""))
	_refresh_view()
