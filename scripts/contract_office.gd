extends Control

const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const FA_MARKET_SCENE_PATH := "res://scenes/FAMarket.tscn"
const CONTRACT_RENEWAL_SCENE_PATH := "res://scenes/ContractRenewalOffice.tscn"
const OOTP_SHELL_SCRIPT = preload("res://scripts/ui/ootp_shell.gd")

@onready var title_label: Label = $RootScroll/MarginContainer/RootVBox/TitleLabel
@onready var back_button: Button = $RootScroll/MarginContainer/RootVBox/NavButtonsHBox/BackButton
@onready var overview_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/OverviewTabButton
@onready var renewal_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/RenewalTabButton
@onready var fa_tab_button: Button = $RootScroll/MarginContainer/RootVBox/TabButtonsHBox/FATabButton
@onready var info_label: Label = $RootScroll/MarginContainer/RootVBox/InfoLabel

@onready var overview_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/OverviewVBox
@onready var summary_grid: GridContainer = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryGrid
@onready var contract_title_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryGrid/ContractCard/ContractTitleLabel
@onready var contract_detail_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryGrid/ContractCard/ContractDetailLabel
@onready var fa_title_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryGrid/FACard/FATitleLabel
@onready var fa_detail_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/SummaryGrid/FACard/FADetailLabel
@onready var overview_status_label: Label = $RootScroll/MarginContainer/RootVBox/OverviewVBox/StatusLabel

@onready var renewal_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/RenewalVBox
@onready var renewal_title_label: Label = $RootScroll/MarginContainer/RootVBox/RenewalVBox/RenewalTitleLabel
@onready var renewal_detail_label: Label = $RootScroll/MarginContainer/RootVBox/RenewalVBox/RenewalDetailLabel
@onready var renewal_button: Button = $RootScroll/MarginContainer/RootVBox/RenewalVBox/RenewalButton
@onready var renewal_note_label: Label = $RootScroll/MarginContainer/RootVBox/RenewalVBox/RenewalNoteLabel

@onready var fa_vbox: VBoxContainer = $RootScroll/MarginContainer/RootVBox/FAVBox
@onready var market_title_label: Label = $RootScroll/MarginContainer/RootVBox/FAVBox/MarketTitleLabel
@onready var market_detail_label: Label = $RootScroll/MarginContainer/RootVBox/FAVBox/MarketDetailLabel
@onready var fa_market_button: Button = $RootScroll/MarginContainer/RootVBox/FAVBox/FAMarketButton
@onready var fa_note_label: Label = $RootScroll/MarginContainer/RootVBox/FAVBox/FANoteLabel

var _current_tab: String = "overview"


func _ready() -> void:
	OOTP_SHELL_SCRIPT.install(self, {
		"primary_tab": "front_office",
		"section_label": "CONTRACTS",
		"sub_tab": "overview",
		"sub_tabs": [
			{"key": "overview", "label": "OVERVIEW", "scene": "res://scenes/ContractOffice.tscn"},
			{"key": "renewals", "label": "RENEWALS", "scene": CONTRACT_RENEWAL_SCENE_PATH},
			{"key": "fa", "label": "FA MARKET", "scene": FA_MARKET_SCENE_PATH}
		],
		"top_right": "CONTRACTS"
	})
	_setup_static_text()
	_connect_buttons()
	_refresh_view()


func _setup_static_text() -> void:
	title_label.visible = false
	back_button.text = "球団運営へ戻る"
	overview_tab_button.text = "概況"
	renewal_tab_button.text = "更改"
	fa_tab_button.text = "FA市場"
	info_label.text = "契約更改と FA の時期を確認するトップです。締切と注意選手を見て、必要な実行ページへ進みます。"
	contract_title_label.text = "契約更改"
	fa_title_label.text = "FA市場"
	renewal_title_label.text = "更改候補"
	market_title_label.text = "FA候補"
	renewal_button.text = "契約更改へ"
	fa_market_button.text = "FA市場へ"


func _connect_buttons() -> void:
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FRONT_OFFICE_SCENE_PATH))
	overview_tab_button.pressed.connect(func() -> void: _on_tab_pressed("overview"))
	renewal_tab_button.pressed.connect(func() -> void: _on_tab_pressed("renewal"))
	fa_tab_button.pressed.connect(func() -> void: _on_tab_pressed("fa"))
	renewal_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(CONTRACT_RENEWAL_SCENE_PATH))
	fa_market_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(FA_MARKET_SCENE_PATH))


func _on_tab_pressed(tab_key: String) -> void:
	_current_tab = tab_key
	_refresh_tab_visibility()


func _refresh_tab_visibility() -> void:
	overview_tab_button.disabled = _current_tab == "overview"
	renewal_tab_button.disabled = _current_tab == "renewal"
	fa_tab_button.disabled = _current_tab == "fa"

	overview_vbox.visible = _current_tab == "overview"
	renewal_vbox.visible = _current_tab == "renewal"
	fa_vbox.visible = _current_tab == "fa"


func _refresh_view() -> void:
	var cycle: Dictionary = LeagueState.get_contract_fa_cycle_summary()
	if cycle.is_empty():
		contract_detail_label.text = "担当球団が未設定です。"
		fa_detail_label.text = "-"
		overview_status_label.text = ""
		renewal_detail_label.text = "-"
		renewal_note_label.text = ""
		market_detail_label.text = "-"
		fa_note_label.text = ""
		_refresh_tab_visibility()
		return

	var expiring_players: Array = cycle.get("expiring_players", [])
	var fa_watch_players: Array = cycle.get("fa_watch_players", [])
	var contract_now: bool = bool(cycle.get("contract_now", false))
	var fa_now: bool = bool(cycle.get("fa_now", false))

	contract_detail_label.text = _build_expiring_text(expiring_players, 3)
	fa_detail_label.text = _build_fa_watch_text(fa_watch_players, int(cycle.get("external_fa_count", 0)), 3)
	overview_status_label.text = _build_status_text(cycle)

	renewal_detail_label.text = _build_expiring_text(expiring_players, 5)
	renewal_button.disabled = not contract_now
	if contract_now:
		renewal_note_label.text = "今は契約更改期間です。残り年数が少ない主力から順に更改していくのが安全です。"
	else:
		renewal_note_label.text = "契約更改は更改期間のみ実行できます。まずは締切と対象選手を確認します。"

	market_detail_label.text = _build_fa_watch_text(fa_watch_players, int(cycle.get("external_fa_count", 0)), 5)
	fa_market_button.disabled = not fa_now
	if fa_now:
		fa_note_label.text = "今は FA 交渉期間です。流出警戒と補強候補の両方を見ながら判断します。"
	else:
		fa_note_label.text = "FA 市場は FA 交渉期間のみ実行できます。今は候補と注意選手を確認する段階です。"

	_refresh_tab_visibility()


func _build_expiring_text(expiring_players: Array, max_count: int) -> String:
	var lines: Array[String] = []
	lines.append("残り年数が少ない選手")
	if expiring_players.is_empty():
		lines.append("今すぐ更改が必要な選手はいません。")
		return "\n".join(lines)

	for i in range(mini(max_count, expiring_players.size())):
		var player: PlayerData = expiring_players[i]
		lines.append("- %s / 残り%d年 / 年俸 %d / 希望 %d / FA志向 %d" % [
			player.full_name,
			int(player.contract_years_left),
			int(player.salary),
			int(player.desired_salary),
			int(player.fa_interest)
		])
	return "\n".join(lines)


func _build_fa_watch_text(fa_watch_players: Array, external_count: int, max_count: int) -> String:
	var lines: Array[String] = []
	lines.append("自球団の FA 注意選手 %d人" % fa_watch_players.size())
	lines.append("市場に出そうな他球団候補 %d人" % external_count)
	if fa_watch_players.is_empty():
		lines.append("今のところ強い流出警戒はありません。")
		return "\n".join(lines)

	for i in range(mini(max_count, fa_watch_players.size())):
		var player: PlayerData = fa_watch_players[i]
		lines.append("- %s / FA志向 %d / 希望 %d" % [
			player.full_name,
			int(player.fa_interest),
			int(player.desired_salary)
		])
	return "\n".join(lines)


func _build_status_text(cycle: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("現在フェーズ: %s" % str(cycle.get("phase_label", "通常期間")))
	lines.append("契約更改: %s" % str(cycle.get("contract_period_label", "-")))
	lines.append("FA交渉: %s" % str(cycle.get("fa_period_label", "-")))
	if bool(cycle.get("contract_now", false)):
		lines.append("今やるなら: 契約更改を優先")
	elif bool(cycle.get("fa_now", false)):
		lines.append("今やるなら: FA交渉を確認")
	else:
		lines.append("今は締切前の確認期間です。")
	return "\n".join(lines)
