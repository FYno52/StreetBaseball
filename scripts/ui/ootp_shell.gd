extends RefCounted

const HOME_SCENE_PATH := "res://scenes/LeagueHome.tscn"
const TEAM_MANAGEMENT_SCENE_PATH := "res://scenes/TeamManagement.tscn"
const FRONT_OFFICE_SCENE_PATH := "res://scenes/FrontOffice.tscn"
const SCOUT_DRAFT_SCENE_PATH := "res://scenes/ScoutDraftOffice.tscn"
const LEAGUE_INFO_SCENE_PATH := "res://scenes/LeagueInfo.tscn"
const RECORD_ROOM_SCENE_PATH := "res://scenes/RecordRoom.tscn"

const SIDEBAR_WIDTH := 116.0
const TOPBAR_HEIGHT := 72.0
const SUBBAR_HEIGHT := 34.0

static func install(scene: Control, config: Dictionary) -> void:
	var content_root: Control = scene.get_node_or_null("RootScroll")
	if content_root == null:
		content_root = scene.get_node_or_null("RootMargin")
	if content_root == null:
		return

	_hide_legacy_header(scene)

	var existing_sidebar := scene.get_node_or_null("FmSidebarPanel")
	if existing_sidebar != null:
		existing_sidebar.queue_free()
	var existing_top := scene.get_node_or_null("FmTopArea")
	if existing_top != null:
		existing_top.queue_free()

	content_root.offset_left = SIDEBAR_WIDTH
	content_root.offset_top = TOPBAR_HEIGHT + SUBBAR_HEIGHT
	content_root.offset_right = 0
	content_root.offset_bottom = 0

	var sidebar := PanelContainer.new()
	sidebar.name = "FmSidebarPanel"
	sidebar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	sidebar.anchor_right = 0.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = 0
	sidebar.offset_top = 0
	sidebar.offset_right = SIDEBAR_WIDTH
	sidebar.offset_bottom = 0
	sidebar.add_theme_stylebox_override("panel", _make_style(Color(0.16, 0.06, 0.28, 1.0)))
	scene.add_child(sidebar)

	var side_margin := _build_margin(10, 10, 10, 10)
	sidebar.add_child(side_margin)
	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 10)
	side_margin.add_child(side_vbox)

	var home_title := Label.new()
	home_title.text = "ホーム"
	side_vbox.add_child(home_title)

	for tab_data in _build_primary_tabs():
		side_vbox.add_child(_build_sidebar_button(scene, tab_data, str(config.get("primary_tab", ""))))

	var top_area := VBoxContainer.new()
	top_area.name = "FmTopArea"
	top_area.anchor_left = 0.0
	top_area.anchor_top = 0.0
	top_area.anchor_right = 1.0
	top_area.anchor_bottom = 0.0
	top_area.offset_left = SIDEBAR_WIDTH
	top_area.offset_top = 0
	top_area.offset_right = 0
	top_area.offset_bottom = TOPBAR_HEIGHT + SUBBAR_HEIGHT
	top_area.add_theme_constant_override("separation", 0)
	scene.add_child(top_area)

	var top_bar := PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, TOPBAR_HEIGHT)
	top_bar.add_theme_stylebox_override("panel", _make_style(Color(0.12, 0.12, 0.13, 1.0)))
	top_area.add_child(top_bar)

	var top_margin := _build_margin(18, 10, 18, 10)
	top_bar.add_child(top_margin)
	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 16)
	top_margin.add_child(top_hbox)

	var team_block := VBoxContainer.new()
	team_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_block.add_theme_constant_override("separation", 4)
	top_hbox.add_child(team_block)

	var team_name := Label.new()
	team_name.text = _build_team_name_text()
	team_block.add_child(team_name)

	var team_record := Label.new()
	team_record.text = _build_team_record_text()
	team_block.add_child(team_record)

	var page_block := VBoxContainer.new()
	page_block.custom_minimum_size = Vector2(260, 0)
	page_block.add_theme_constant_override("separation", 4)
	top_hbox.add_child(page_block)

	var section_label := Label.new()
	section_label.text = str(config.get("section_label", "OVERVIEW"))
	page_block.add_child(section_label)

	var section_hint := Label.new()
	section_hint.text = "%s  |  %s" % [LeagueState.get_current_date_label(), str(config.get("top_right", "TEAM VIEW"))]
	page_block.add_child(section_hint)

	var continue_button := Button.new()
	continue_button.custom_minimum_size = Vector2(150, 42)
	continue_button.text = str(config.get("continue_label", "次へ進む"))
	var continue_scene: String = str(config.get("continue_scene", HOME_SCENE_PATH))
	continue_button.pressed.connect(func() -> void:
		scene.get_tree().change_scene_to_file(continue_scene)
	)
	top_hbox.add_child(continue_button)

	var sub_bar := PanelContainer.new()
	sub_bar.custom_minimum_size = Vector2(0, SUBBAR_HEIGHT)
	sub_bar.add_theme_stylebox_override("panel", _make_style(Color(0.88, 0.89, 0.92, 1.0)))
	top_area.add_child(sub_bar)

	var sub_margin := _build_margin(14, 4, 14, 4)
	sub_bar.add_child(sub_margin)
	var sub_hbox := HBoxContainer.new()
	sub_hbox.add_theme_constant_override("separation", 12)
	sub_margin.add_child(sub_hbox)

	for subtab_data in config.get("sub_tabs", []):
		sub_hbox.add_child(_build_sub_button(scene, subtab_data, str(config.get("sub_tab", ""))))


static func _hide_legacy_header(scene: Control) -> void:
	var title_label := scene.get_node_or_null("RootScroll/MarginContainer/RootVBox/TitleLabel")
	if title_label is Control:
		title_label.visible = false

	var nav_info_label := scene.get_node_or_null("RootScroll/MarginContainer/RootVBox/NavInfoLabel")
	if nav_info_label is Control:
		nav_info_label.visible = false

	var nav_buttons_hbox := scene.get_node_or_null("RootScroll/MarginContainer/RootVBox/NavButtonsHBox")
	if nav_buttons_hbox is Control:
		nav_buttons_hbox.visible = false

	var root_margin_nav := scene.get_node_or_null("RootMargin/RootVBox/SecondaryTabsPanel/SecondaryTabsMargin/SecondaryTabsHBox/BackButton")
	if root_margin_nav is Control:
		root_margin_nav.visible = false


static func _build_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


static func _make_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style


static func _build_primary_tabs() -> Array[Dictionary]:
	return [
		{"key": "home", "label": "ホーム", "scene": HOME_SCENE_PATH},
		{"key": "organization", "label": "編成", "scene": TEAM_MANAGEMENT_SCENE_PATH},
		{"key": "front_office", "label": "運営", "scene": FRONT_OFFICE_SCENE_PATH},
		{"key": "scouting", "label": "探索", "scene": SCOUT_DRAFT_SCENE_PATH},
		{"key": "info", "label": "情報", "scene": LEAGUE_INFO_SCENE_PATH},
		{"key": "records", "label": "記録", "scene": RECORD_ROOM_SCENE_PATH}
	]


static func _build_sidebar_button(scene: Control, tab_data: Dictionary, active_key: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 40)
	button.text = str(tab_data.get("label", ""))
	var tab_key: String = str(tab_data.get("key", ""))
	var scene_path: String = str(tab_data.get("scene", ""))
	if tab_key == active_key:
		button.disabled = true
	else:
		button.pressed.connect(func() -> void:
			scene.get_tree().change_scene_to_file(scene_path)
		)
	return button


static func _build_sub_button(scene: Control, tab_data: Dictionary, active_key: String) -> Button:
	var button := Button.new()
	button.flat = true
	button.text = str(tab_data.get("label", ""))
	var tab_key: String = str(tab_data.get("key", ""))
	var scene_path: String = str(tab_data.get("scene", ""))
	if tab_key == active_key:
		button.disabled = true
	else:
		button.pressed.connect(func() -> void:
			scene.get_tree().change_scene_to_file(scene_path)
		)
	return button


static func _build_team_name_text() -> String:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return "担当球団未設定"
	return team.name


static func _build_team_record_text() -> String:
	var team: TeamData = LeagueState.get_controlled_team()
	if team == null:
		return "担当球団が未設定です"
	var standings: Dictionary = team.standings
	return "%d勝 %d敗 %d分  得点%d / 失点%d  人気%d  予算%d" % [
		int(standings.get("wins", 0)),
		int(standings.get("losses", 0)),
		int(standings.get("draws", 0)),
		int(standings.get("runs_for", 0)),
		int(standings.get("runs_against", 0)),
		int(team.fan_support),
		int(team.budget)
	]
