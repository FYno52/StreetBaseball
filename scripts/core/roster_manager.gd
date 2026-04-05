class_name RosterManager
extends RefCounted


static func get_team_registered_player_count(state: Node, team_id: String) -> int:
	var team = state.get_team(team_id)
	if team == null:
		return 0
	return team.player_ids.size()


static func get_team_foreign_player_ids(state: Node, team_id: String) -> Array[String]:
	var result: Array[String] = []
	var team = state.get_team(team_id)
	if team == null:
		return result
	for player_id in team.player_ids:
		var player = state.get_player(str(player_id))
		if player != null and bool(player.is_foreign):
			result.append(str(player.id))
	return result


static func get_team_active_player_ids(state: Node, team_id: String) -> Array[String]:
	var active_ids: Array[String] = []
	var team = state.get_team(team_id)
	if team == null:
		return active_ids

	for player_id in team.player_ids:
		var player = state.get_player(str(player_id))
		if player == null:
			continue
		if str(player.registration_type) != "registered":
			continue
		if str(player.roster_status) == "active":
			active_ids.append(str(player.id))

	return active_ids


static func get_team_roster_rule_summary(state: Node, team_id: String) -> Dictionary:
	var rules: Dictionary = state.get_roster_ruleset()
	var team = state.get_team(team_id)
	if team == null:
		return {
			"ok": false,
			"registered": 0,
			"active": 0,
			"foreign_signed": 0,
			"foreign_active": 0,
			"foreign_active_pitchers": 0,
			"foreign_active_fielders": 0,
			"warnings": ["チームデータが見つかりません。"]
		}

	var registered_count: int = get_team_registered_player_count(state, team_id)
	var active_ids: Array[String] = get_team_active_player_ids(state, team_id)
	var foreign_signed_ids: Array[String] = get_team_foreign_player_ids(state, team_id)
	var foreign_active: int = 0
	var foreign_active_pitchers: int = 0
	var foreign_active_fielders: int = 0
	for player_id in active_ids:
		var player = state.get_player(str(player_id))
		if player == null or not bool(player.is_foreign):
			continue
		foreign_active += 1
		if player.is_pitcher():
			foreign_active_pitchers += 1
		else:
			foreign_active_fielders += 1

	var warnings: Array[String] = []
	if registered_count > int(rules.get("registered_roster_max", 70)):
		warnings.append("支配下人数が上限を超えています。")
	if active_ids.size() > int(rules.get("active_roster_target", 29)):
		warnings.append("一軍登録人数が上限を超えています。")
	if foreign_active > int(rules.get("foreign_active_max", 4)):
		warnings.append("一軍外国人枠を超えています。")
	if foreign_active_pitchers > int(rules.get("foreign_pitcher_active_max", 3)):
		warnings.append("一軍外国人投手枠を超えています。")
	if foreign_active_fielders > int(rules.get("foreign_fielder_active_max", 3)):
		warnings.append("一軍外国人野手枠を超えています。")

	return {
		"ok": warnings.is_empty(),
		"registered": registered_count,
		"registered_target": int(rules.get("registered_roster_target", 68)),
		"registered_max": int(rules.get("registered_roster_max", 70)),
		"active": active_ids.size(),
		"active_target": int(rules.get("active_roster_target", 29)),
		"foreign_signed": foreign_signed_ids.size(),
		"foreign_active": foreign_active,
		"foreign_active_max": int(rules.get("foreign_active_max", 4)),
		"foreign_active_pitchers": foreign_active_pitchers,
		"foreign_pitcher_active_max": int(rules.get("foreign_pitcher_active_max", 3)),
		"foreign_active_fielders": foreign_active_fielders,
		"foreign_fielder_active_max": int(rules.get("foreign_fielder_active_max", 3)),
		"warnings": warnings
	}


static func get_controlled_team_player_management_summary(state: Node) -> Dictionary:
	var team = state.get_controlled_team()
	if team == null:
		return {}

	var active_count: int = 0
	var farm_count: int = 0
	var development_count: int = 0
	var foreign_active_count: int = 0
	var foreign_signed_count: int = 0

	for player_id in team.player_ids:
		var player = state.get_player(str(player_id))
		if player == null:
			continue
		match str(player.roster_status):
			"active":
				active_count += 1
			"development":
				development_count += 1
			_:
				farm_count += 1
		if bool(player.is_foreign):
			foreign_signed_count += 1
			if str(player.roster_status) == "active":
				foreign_active_count += 1

	return {
		"team_name": team.name,
		"active_count": active_count,
		"farm_count": farm_count,
		"development_count": development_count,
		"foreign_signed_count": foreign_signed_count,
		"foreign_active_count": foreign_active_count,
		"roster_rule_summary": get_team_roster_rule_summary(state, str(team.id))
	}


static func set_controlled_player_roster_status(state: Node, player_id: String, target_status: String) -> Dictionary:
	var team = state.get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が未設定です。"}

	var player = state.get_player(player_id)
	if player == null or not team.player_ids.has(player_id):
		return {"ok": false, "message": "担当球団の選手ではありません。"}

	var normalized_status: String = str(target_status)
	if normalized_status not in ["active", "farm", "development"]:
		return {"ok": false, "message": "変更先の在籍状態が不正です。"}

	if normalized_status == "development":
		if str(player.registration_type) != "development":
			return {"ok": false, "message": "支配下選手はそのまま育成契約に戻せません。"}
		player.roster_status = "development"
		return {"ok": true, "message": "%s を育成枠に設定しました。" % player.full_name}

	if str(player.registration_type) == "development":
		return {"ok": false, "message": "育成選手は先に支配下登録が必要です。"}

	if normalized_status == "active":
		var rules: Dictionary = state.get_roster_ruleset()
		var active_ids: Array[String] = get_team_active_player_ids(state, str(team.id))
		var active_limit: int = int(rules.get("active_roster_target", 29))
		if str(player.roster_status) != "active" and active_ids.size() >= active_limit:
			return {"ok": false, "message": "一軍登録上限に達しているため登録できません。"}

		if bool(player.is_foreign) and str(player.roster_status) != "active":
			var foreign_active_total: int = 0
			var foreign_active_pitchers: int = 0
			var foreign_active_fielders: int = 0
			for active_player_id in active_ids:
				var active_player = state.get_player(str(active_player_id))
				if active_player == null or not bool(active_player.is_foreign):
					continue
				foreign_active_total += 1
				if active_player.is_pitcher():
					foreign_active_pitchers += 1
				else:
					foreign_active_fielders += 1

			if foreign_active_total >= int(rules.get("foreign_active_max", 4)):
				return {"ok": false, "message": "一軍外国人枠に空きがありません。"}
			if player.is_pitcher() and foreign_active_pitchers >= int(rules.get("foreign_pitcher_active_max", 3)):
				return {"ok": false, "message": "一軍外国人投手枠に空きがありません。"}
			if not player.is_pitcher() and foreign_active_fielders >= int(rules.get("foreign_fielder_active_max", 3)):
				return {"ok": false, "message": "一軍外国人野手枠に空きがありません。"}

	player.roster_status = normalized_status
	var status_label: String = "一軍" if normalized_status == "active" else "二軍"
	return {"ok": true, "message": "%s を%sに設定しました。" % [player.full_name, status_label]}


static func promote_controlled_development_player(state: Node, player_id: String) -> Dictionary:
	var team = state.get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が未設定です。"}

	var player = state.get_player(player_id)
	if player == null or not team.player_ids.has(player_id):
		return {"ok": false, "message": "担当球団の選手ではありません。"}
	if str(player.registration_type) != "development":
		return {"ok": false, "message": "この選手はすでに支配下です。"}

	var rules: Dictionary = state.get_roster_ruleset()
	var registered_count: int = get_team_registered_player_count(state, str(team.id))
	var registered_max: int = int(rules.get("registered_roster_max", 70))
	if registered_count >= registered_max:
		return {"ok": false, "message": "支配下上限に達しているため昇格できません。"}

	player.registration_type = "registered"
	player.roster_status = "farm"
	return {"ok": true, "message": "%s を支配下登録しました。" % player.full_name}
