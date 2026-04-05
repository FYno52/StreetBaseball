class_name DraftManager
extends RefCounted


static func get_controlled_team_draft_prospects(state: Node) -> Array[Dictionary]:
	var team = state.get_controlled_team()
	if team == null:
		return []
	return _build_draft_prospect_list(state, team)


static func toggle_controlled_draft_focus(state: Node, prospect_id: String) -> Dictionary:
	if not state.is_draft_prep_period() and not state.is_draft_day():
		return {"ok": false, "message": "注目候補の整理はドラフト準備期間とドラフト会議日に行えます。"}

	var team = state.get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が設定されていません。"}
	if prospect_id == "":
		return {"ok": false, "message": "候補IDが不正です。"}

	if team.draft_focus_ids.has(prospect_id):
		team.draft_focus_ids.erase(prospect_id)
		return {"ok": true, "message": "注目候補から外しました。"}
	if team.draft_focus_ids.size() >= 5:
		return {"ok": false, "message": "注目候補は5人までです。"}
	team.draft_focus_ids.append(prospect_id)
	return {"ok": true, "message": "注目候補に追加しました。"}


static func run_controlled_team_draft(state: Node) -> Dictionary:
	if not state.is_draft_day():
		return {"ok": false, "message": "ドラフト指名はドラフト会議当日のみ行えます。"}

	var team = state.get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が設定されていません。"}
	if int(team.last_draft_year) == int(state.season_year):
		return {"ok": false, "message": "今年のドラフト指名はすでに完了しています。"}

	var prospects: Array[Dictionary] = _build_draft_prospect_list(state, team)
	if prospects.is_empty():
		return {"ok": false, "message": "指名できる候補がいません。"}

	var chosen: Dictionary = {}
	for prospect in prospects:
		if bool(prospect.get("focused", false)):
			chosen = prospect
			break
	if chosen.is_empty():
		chosen = prospects[0]

	var role_text: String = str(chosen.get("role", "高校生内野手"))
	var player
	if role_text.find("投手") >= 0:
		player = state._build_replacement_pitcher(team.id, "starter")
	elif role_text.find("捕手") >= 0:
		player = state._build_replacement_fielder(team.id, "C")
	elif role_text.find("外野手") >= 0:
		player = state._build_replacement_fielder(team.id, "CF")
	else:
		player = state._build_replacement_fielder(team.id, "SS")

	player.full_name = str(chosen.get("name", player.full_name))
	player.age = 18 if role_text.find("高校生") >= 0 else 22 if role_text.find("大学生") >= 0 else 24
	player.years_pro = 1
	player.contract_years_left = 3
	player.salary = clampi(450 + int(chosen.get("upside", 60)) * 4, 450, 2200)
	player.desired_salary = player.salary
	player.fa_interest = 35
	player.potential = clampi(int(chosen.get("upside", 60)) + 8, 50, 95)
	player.morale = 65
	player.condition = 60
	player.overall = clampi(maxi(int(player.overall), int(chosen.get("upside", 60)) - 8), 35, 90)
	player.traits.clear()
	player.traits.append(str(chosen.get("style", "")))

	state._register_new_player(team, player)
	state._rebuild_team_competitive_structures(team)
	team.last_draft_year = state.season_year
	team.last_draft_result_names = [player.full_name]
	team.draft_focus_ids.clear()

	var draft_result := {
		"ok": true,
		"message": "ドラフトで %s を指名しました。" % player.full_name,
		"player_name": player.full_name,
		"role": role_text,
		"overall": int(player.overall),
		"potential": int(player.potential)
	}
	state._mark_operation_completed("draft", "ドラフト会議", str(draft_result["message"]))
	return draft_result


static func _build_draft_prospect_list(state: Node, team) -> Array[Dictionary]:
	var scouting_level: int = int(team.facilities.get("scouting", 1))
	var scout_count: int = int(team.staff.get("scouts", 0))
	var quality_bonus: int = scouting_level * 3 + scout_count * 2
	var grade_labels: Array[String] = ["C", "C+", "B", "B+", "A-", "A"]
	var family_names: Array[String] = ["佐藤", "鈴木", "高橋", "田中", "伊藤", "渡辺", "山本", "中村"]
	var given_names: Array[String] = ["一樹", "健太", "隼人", "悠斗", "大雅", "直樹", "優真", "蓮"]
	var role_pool: Array[String] = ["高校生投手", "大学生投手", "社会人投手", "高校生内野手", "大学生外野手", "社会人捕手", "高校生外野手", "大学生内野手"]
	var style_pool: Array[String] = ["速球派", "変化球型", "守備型", "長打型", "巧打型", "万能型", "強肩型", "粘り強い"]
	var prospects: Array[Dictionary] = []

	for i in range(8):
		var prospect_id: String = "%d_draft_%02d" % [state.season_year, i + 1]
		var upside: int = 54 + i * 4 + quality_bonus
		var grade_index: int = mini(grade_labels.size() - 1, int(floor(float(upside - 50) / 8.0)))
		prospects.append({
			"prospect_id": prospect_id,
			"name": "%s %s" % [family_names[i % family_names.size()], given_names[i % given_names.size()]],
			"role": role_pool[i % role_pool.size()],
			"grade": grade_labels[grade_index],
			"upside": upside,
			"style": style_pool[(i + scouting_level + scout_count) % style_pool.size()],
			"note": "将来性 %d / スカウト評価 %s" % [upside, grade_labels[grade_index]],
			"focused": team.draft_focus_ids.has(prospect_id)
		})
	return prospects
