class_name CalendarManager
extends RefCounted


static func get_today_calendar_events(state: Node) -> Array[Dictionary]:
	return state.get_calendar_events_for_day(int(state.current_day))


static func get_upcoming_calendar_events(state: Node, max_count: int = 5, from_day: int = -1) -> Array[Dictionary]:
	var start_day: int = int(state.current_day) if from_day < 0 else from_day
	var upcoming: Array[Dictionary] = []
	var seen_keys: Dictionary = {}
	for day in range(start_day, state.get_last_day() + 1):
		for event_data in state.get_calendar_events_for_day(day):
			var event_type: String = str(event_data.get("type", ""))
			var dedupe_key: String = "%s_%d" % [event_type, int(event_data.get("start_day", day))]
			if seen_keys.has(dedupe_key):
				continue
			seen_keys[dedupe_key] = true
			upcoming.append(event_data)
			if upcoming.size() >= max_count:
				return upcoming
	return upcoming


static func is_contract_period(state: Node, day: int = -1) -> bool:
	return _is_day_in_range(state, day, state.CONTRACT_PERIOD_START_MONTH, state.CONTRACT_PERIOD_START_DAY, state.CONTRACT_PERIOD_END_MONTH, state.CONTRACT_PERIOD_END_DAY)


static func is_fa_period(state: Node, day: int = -1) -> bool:
	return _is_day_in_range(state, day, state.FA_PERIOD_START_MONTH, state.FA_PERIOD_START_DAY, state.FA_PERIOD_END_MONTH, state.FA_PERIOD_END_DAY)


static func is_sponsor_period(state: Node, day: int = -1) -> bool:
	return _is_day_in_range(state, day, state.SPONSOR_PERIOD_START_MONTH, state.SPONSOR_PERIOD_START_DAY, state.SPONSOR_PERIOD_END_MONTH, state.SPONSOR_PERIOD_END_DAY)


static func is_staff_review_period(state: Node, day: int = -1) -> bool:
	return _is_day_in_range(state, day, state.STAFF_REVIEW_START_MONTH, state.STAFF_REVIEW_START_DAY, state.STAFF_REVIEW_END_MONTH, state.STAFF_REVIEW_END_DAY)


static func is_draft_prep_period(state: Node, day: int = -1) -> bool:
	return _is_day_in_range(state, day, state.DRAFT_PREP_START_MONTH, state.DRAFT_PREP_START_DAY, state.DRAFT_PREP_END_MONTH, state.DRAFT_PREP_END_DAY)


static func is_draft_day(state: Node, day: int = -1) -> bool:
	var target_day: int = int(state.current_day) if day < 0 else day
	var date_info: Dictionary = state.get_date_info_for_day(target_day)
	return int(date_info.get("month", 0)) == int(state.DRAFT_DAY_MONTH) and int(date_info.get("day", 0)) == int(state.DRAFT_DAY_DAY)


static func get_calendar_summary_text(state: Node, day: int = -1) -> String:
	var target_day: int = int(state.current_day) if day < 0 else day
	var events: Array[Dictionary] = state.get_calendar_events_for_day(target_day)
	if events.is_empty():
		return "大きな年間イベントはありません。"
	var labels: Array[String] = []
	for event_data in events:
		labels.append(str(event_data.get("label", "イベント")))
	return " / ".join(labels)


static func get_year_cycle_summary(state: Node) -> Dictionary:
	var date_info: Dictionary = state.get_date_info_for_day(int(state.current_day))
	var month: int = int(date_info.get("month", 1))
	var day_of_month: int = int(date_info.get("day", 1))

	if _is_date_in_range(month, day_of_month, state.SPRING_CAMP_START_MONTH, state.SPRING_CAMP_START_DAY, state.SPRING_CAMP_END_MONTH, state.SPRING_CAMP_END_DAY):
		return {"phase": "spring_camp", "label": "春季キャンプ", "focus": ["コンディション調整", "若手確認", "開幕構想づくり"]}
	if _is_date_in_range(month, day_of_month, state.OPEN_GAME_START_MONTH, state.OPEN_GAME_START_DAY, state.OPEN_GAME_END_MONTH, state.OPEN_GAME_END_DAY):
		return {"phase": "open_games", "label": "オープン戦", "focus": ["開幕一軍の確認", "先発と打順の見直し", "新戦力の試用"]}
	if _is_date_in_range(month, day_of_month, state.INTERLEAGUE_START_MONTH, state.INTERLEAGUE_START_DAY, state.INTERLEAGUE_END_MONTH, state.INTERLEAGUE_END_DAY):
		return {"phase": "interleague", "label": "交流戦", "focus": ["短期の順位変動", "注目度アップ", "戦力の見極め"]}
	if _is_date_in_range(month, day_of_month, state.CLIMAX_FIRST_START_MONTH, state.CLIMAX_FIRST_START_DAY, state.CLIMAX_FINAL_END_MONTH, state.CLIMAX_FINAL_END_DAY):
		return {"phase": "climax_series", "label": "クライマックスシリーズ", "focus": ["短期決戦の編成", "勝ちパターン固定", "主力運用"]}
	if _is_date_in_range(month, day_of_month, state.JAPAN_SERIES_START_MONTH, state.JAPAN_SERIES_START_DAY, state.JAPAN_SERIES_END_MONTH, state.JAPAN_SERIES_END_DAY):
		return {"phase": "japan_series", "label": "日本シリーズ", "focus": ["頂上決戦", "主力集中運用", "シリーズ制覇"]}
	if is_draft_prep_period(state):
		return {"phase": "draft_prep", "label": "ドラフト準備", "focus": ["候補整理", "注目候補確認", "補強方針決定"]}
	if is_draft_day(state):
		return {"phase": "draft_day", "label": "ドラフト会議", "focus": ["指名実行", "将来戦力確保", "補強結果確認"]}
	if is_contract_period(state):
		return {"phase": "contract", "label": "契約更改", "focus": ["年俸調整", "残留交渉", "主力流出防止"]}
	if is_fa_period(state):
		return {"phase": "fa", "label": "FA交渉", "focus": ["FA流出対策", "補強交渉", "戦力補充"]}
	if is_sponsor_period(state):
		return {"phase": "sponsor", "label": "スポンサー更改", "focus": ["収益改善", "契約更新", "予算確保"]}
	if is_staff_review_period(state):
		return {"phase": "staff", "label": "スタッフ見直し", "focus": ["コーチ整理", "スカウト体制調整", "来季準備"]}
	if int(state.current_day) < int(state.get_first_game_day()):
		return {"phase": "preseason", "label": "開幕準備", "focus": ["開幕一軍整理", "起用法確認", "編成最終調整"]}
	if int(state.current_day) <= int(state.get_final_game_day()):
		return {"phase": "regular", "label": "レギュラーシーズン", "focus": ["試合消化", "昇降格", "疲労管理"]}
	return {"phase": "offseason", "label": "オフシーズン", "focus": ["来季構想", "球団運営", "編成整理"]}


static func get_next_calendar_milestone(state: Node) -> Dictionary:
	var milestones: Array[Dictionary] = []
	_append_milestone(milestones, "春季キャンプ", "キャンプまで", "春季キャンプ開始", state._find_calendar_day(state.SPRING_CAMP_START_MONTH, state.SPRING_CAMP_START_DAY))
	_append_milestone(milestones, "キャンプ終了", "キャンプ終了まで", "春季キャンプ終了", state._find_calendar_day(state.SPRING_CAMP_END_MONTH, state.SPRING_CAMP_END_DAY))
	_append_milestone(milestones, "オープン戦", "オープン戦まで", "オープン戦開始", state._find_calendar_day(state.OPEN_GAME_START_MONTH, state.OPEN_GAME_START_DAY))
	_append_milestone(milestones, "オープン戦終了", "オープン戦終了まで", "オープン戦終了", state._find_calendar_day(state.OPEN_GAME_END_MONTH, state.OPEN_GAME_END_DAY))
	_append_milestone(milestones, "開幕", "開幕まで", "開幕", state.get_first_game_day())
	_append_milestone(milestones, "交流戦", "交流戦まで", "交流戦開始", state._find_calendar_day(state.INTERLEAGUE_START_MONTH, state.INTERLEAGUE_START_DAY))
	_append_milestone(milestones, "交流戦終了", "交流戦明けまで", "交流戦終了", state._find_calendar_day(state.INTERLEAGUE_END_MONTH, state.INTERLEAGUE_END_DAY))
	_append_milestone(milestones, "クライマックス開始", "CS開始まで", "クライマックス開始", state._find_calendar_day(state.CLIMAX_FIRST_START_MONTH, state.CLIMAX_FIRST_START_DAY))
	_append_milestone(milestones, "クライマックス1st終了", "CS1st終了まで", "クライマックス1st終了", state._find_calendar_day(state.CLIMAX_FIRST_END_MONTH, state.CLIMAX_FIRST_END_DAY))
	_append_milestone(milestones, "クライマックスFinal", "CS Finalまで", "クライマックスFinal開始", state._find_calendar_day(state.CLIMAX_FINAL_START_MONTH, state.CLIMAX_FINAL_START_DAY))
	_append_milestone(milestones, "クライマックスFinal終了", "CS終了まで", "クライマックスFinal終了", state._find_calendar_day(state.CLIMAX_FINAL_END_MONTH, state.CLIMAX_FINAL_END_DAY))
	_append_milestone(milestones, "日本シリーズ", "日本Sまで", "日本シリーズ開始", state._find_calendar_day(state.JAPAN_SERIES_START_MONTH, state.JAPAN_SERIES_START_DAY))
	_append_milestone(milestones, "日本シリーズ終了", "日本S終了まで", "日本シリーズ終了", state._find_calendar_day(state.JAPAN_SERIES_END_MONTH, state.JAPAN_SERIES_END_DAY))
	_append_milestone(milestones, "ドラフト準備", "ドラフト準備まで", "ドラフト準備開始", state._find_calendar_day(state.DRAFT_PREP_START_MONTH, state.DRAFT_PREP_START_DAY))
	_append_milestone(milestones, "ドラフト会議", "ドラフト会議まで", "ドラフト会議", state._find_calendar_day(state.DRAFT_DAY_MONTH, state.DRAFT_DAY_DAY))
	_append_milestone(milestones, "契約更改", "契約更改まで", "契約更改開始", state._find_calendar_day(state.CONTRACT_PERIOD_START_MONTH, state.CONTRACT_PERIOD_START_DAY))
	_append_milestone(milestones, "契約更改終了", "更改終了まで", "契約更改終了", state._find_calendar_day(state.CONTRACT_PERIOD_END_MONTH, state.CONTRACT_PERIOD_END_DAY))
	_append_milestone(milestones, "FA交渉", "FA期間まで", "FA交渉開始", state._find_calendar_day(state.FA_PERIOD_START_MONTH, state.FA_PERIOD_START_DAY))
	_append_milestone(milestones, "FA終了", "FA終了まで", "FA交渉終了", state._find_calendar_day(state.FA_PERIOD_END_MONTH, state.FA_PERIOD_END_DAY))
	_append_milestone(milestones, "スポンサー更改", "スポンサー期まで", "スポンサー更改開始", state._find_calendar_day(state.SPONSOR_PERIOD_START_MONTH, state.SPONSOR_PERIOD_START_DAY))
	_append_milestone(milestones, "スポンサー終了", "スポンサー終了まで", "スポンサー更改終了", state._find_calendar_day(state.SPONSOR_PERIOD_END_MONTH, state.SPONSOR_PERIOD_END_DAY))
	_append_milestone(milestones, "スタッフ見直し", "スタッフ期まで", "スタッフ見直し開始", state._find_calendar_day(state.STAFF_REVIEW_START_MONTH, state.STAFF_REVIEW_START_DAY))
	_append_milestone(milestones, "スタッフ見直し終了", "スタッフ期終了まで", "スタッフ見直し終了", state._find_calendar_day(state.STAFF_REVIEW_END_MONTH, state.STAFF_REVIEW_END_DAY))

	for milestone in milestones:
		if int(milestone.get("target_day", -1)) > int(state.current_day):
			return milestone
	return {"label": "年越し", "button_label": "年越しまで", "progress_label": "年越し", "target_day": state.get_last_day()}


static func _append_milestone(milestones: Array[Dictionary], label: String, button_label: String, progress_label: String, target_day: int) -> void:
	if target_day <= 0:
		return
	milestones.append({
		"label": label,
		"button_label": button_label,
		"progress_label": progress_label,
		"target_day": target_day
	})


static func _is_day_in_range(state: Node, day: int, start_month: int, start_day: int, end_month: int, end_day: int) -> bool:
	var target_day: int = int(state.current_day) if day < 0 else day
	var date_info: Dictionary = state.get_date_info_for_day(target_day)
	return _is_date_in_range(
		int(date_info.get("month", 0)),
		int(date_info.get("day", 0)),
		start_month,
		start_day,
		end_month,
		end_day
	)


static func _is_date_in_range(month: int, day_of_month: int, start_month: int, start_day: int, end_month: int, end_day: int) -> bool:
	if month < start_month or month > end_month:
		return false
	if month == start_month and day_of_month < start_day:
		return false
	if month == end_month and day_of_month > end_day:
		return false
	return true
