class_name ContractManager
extends RefCounted


static func get_controlled_team_contract_summary(state: Node) -> Dictionary:
	var team = state.get_controlled_team()
	if team == null:
		return {}

	var expiring_players: Array = []
	var fa_watch_players: Array = []
	for player_id in team.player_ids:
		var player = state.get_player(str(player_id))
		if player == null:
			continue
		if int(player.contract_years_left) <= 1:
			expiring_players.append(player)
		if int(player.fa_interest) >= 65:
			fa_watch_players.append(player)

	expiring_players.sort_custom(func(a, b) -> bool:
		return int(a.overall) > int(b.overall)
	)
	fa_watch_players.sort_custom(func(a, b) -> bool:
		return int(a.fa_interest) > int(b.fa_interest)
	)

	return {
		"expiring_count": expiring_players.size(),
		"expiring_players": expiring_players,
		"fa_watch_players": fa_watch_players
	}


static func renew_controlled_player_contract(state: Node, player_id: String, years: int = 2) -> Dictionary:
	var team = state.get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が見つかりません。"}

	var player = state.get_player(player_id)
	if player == null or not team.player_ids.has(player_id):
		return {"ok": false, "message": "対象選手が担当球団に所属していません。"}

	var requested_salary: int = maxi(int(player.salary), int(player.desired_salary))
	var signing_bonus: int = int(round(float(requested_salary) * 0.6)) + years * 250
	if int(team.budget) < signing_bonus:
		return {"ok": false, "message": "予算が不足しています。必要額: %d" % signing_bonus}

	team.budget = int(team.budget) - signing_bonus
	player.salary = requested_salary
	player.contract_years_left = clampi(int(player.contract_years_left) + years, 1, 5)
	player.desired_salary = int(round(float(player.salary) * 1.08))
	player.fa_interest = clampi(int(player.fa_interest) - 12, 0, 100)

	var renewal_result := {
		"ok": true,
		"message": "%sと%d年契約を結びました。予算 -%d / 年俸 %d" % [
			player.full_name,
			years,
			signing_bonus,
			int(player.salary)
		]
	}
	state._mark_operation_completed("contract", "契約更改", str(renewal_result["message"]))
	return renewal_result


static func get_fa_candidate_list(state: Node) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for team_id in state.teams.keys():
		var team = state.teams[team_id]
		if team == null:
			continue
		for player_id in team.player_ids:
			var player = state.get_player(str(player_id))
			if player == null:
				continue
			var contract_left: int = int(player.contract_years_left)
			var fa_interest_value: int = int(player.fa_interest)
			if contract_left > 1 and fa_interest_value < 70:
				continue
			candidates.append({
				"player_id": str(player.id),
				"player_name": player.full_name,
				"team_id": str(team.id),
				"team_name": team.name,
				"role": player.role,
				"position": player.primary_position,
				"overall": int(player.overall),
				"age": int(player.age),
				"salary": int(player.salary),
				"desired_salary": int(player.desired_salary),
				"contract_years_left": contract_left,
				"fa_interest": fa_interest_value,
				"is_controlled_team": str(team.id) == state.controlled_team_id
			})

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority: int = 0 if int(a.get("contract_years_left", 9)) <= 1 else 1
		var b_priority: int = 0 if int(b.get("contract_years_left", 9)) <= 1 else 1
		if a_priority != b_priority:
			return a_priority < b_priority
		if int(a.get("overall", 0)) != int(b.get("overall", 0)):
			return int(a.get("overall", 0)) > int(b.get("overall", 0))
		return int(a.get("fa_interest", 0)) > int(b.get("fa_interest", 0))
	)
	return candidates


static func negotiate_controlled_team_fa(state: Node, player_id: String, years: int = 3) -> Dictionary:
	if not state.is_fa_period():
		return {"ok": false, "message": "FA交渉はFA期間のみ行えます。"}

	var team = state.get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が設定されていません。"}

	var player = state.get_player(player_id)
	if player == null:
		return {"ok": false, "message": "対象選手が見つかりません。"}

	var current_team = state._find_player_team(str(player.id))
	if current_team != null and str(current_team.id) == str(team.id):
		return {"ok": false, "message": "自球団選手は契約更改で対応してください。"}

	var signing_cost: int = int(player.desired_salary) + years * 400 + int(player.fa_interest) * 10
	if int(team.budget) < signing_cost:
		return {"ok": false, "message": "予算が不足しています。必要額: %d" % signing_cost}

	team.budget -= signing_cost
	if current_team != null:
		current_team.player_ids.erase(str(player.id))
		current_team.lineup_vs_r.erase(str(player.id))
		current_team.lineup_vs_l.erase(str(player.id))
		current_team.bench_ids.erase(str(player.id))
		current_team.rotation_ids.erase(str(player.id))
		if str(current_team.bullpen.get("closer", "")) == str(player.id):
			current_team.bullpen["closer"] = ""
		if str(current_team.bullpen.get("long", "")) == str(player.id):
			current_team.bullpen["long"] = ""
		for key in ["setup", "middle"]:
			var values: Array = current_team.bullpen.get(key, [])
			values.erase(str(player.id))
			current_team.bullpen[key] = values
		state._rebuild_team_competitive_structures(current_team)

	player.salary = int(player.desired_salary)
	player.contract_years_left = clampi(years, 1, 5)
	player.desired_salary = int(round(float(player.salary) * 1.1))
	player.fa_interest = clampi(int(player.fa_interest) - 25, 0, 100)
	player.morale = clampi(int(player.morale) + 12, 0, 100)

	if not team.player_ids.has(str(player.id)):
		team.player_ids.append(str(player.id))
	state._rebuild_team_competitive_structures(team)

	var fa_result := {
		"ok": true,
		"message": "%sと%d年契約を結びました。予算 -%d / 年俸 %d" % [
			player.full_name,
			years,
			signing_cost,
			int(player.salary)
		],
		"player_name": player.full_name,
		"years": years,
		"cost": signing_cost
	}
	state._mark_operation_completed("fa", "FA交渉", str(fa_result["message"]))
	return fa_result


static func get_contract_fa_cycle_summary(state: Node) -> Dictionary:
	var team = state.get_controlled_team()
	if team == null:
		return {}

	var summary: Dictionary = get_controlled_team_contract_summary(state)
	var expiring_players: Array = summary.get("expiring_players", [])
	var fa_watch_players: Array = summary.get("fa_watch_players", [])
	var fa_candidates: Array[Dictionary] = get_fa_candidate_list(state)
	var external_candidates: int = 0
	for item in fa_candidates:
		if not bool(item.get("is_controlled_team", false)):
			external_candidates += 1

	var contract_start_day: int = state._find_calendar_day(state.CONTRACT_PERIOD_START_MONTH, state.CONTRACT_PERIOD_START_DAY)
	var contract_end_day: int = state._find_calendar_day(state.CONTRACT_PERIOD_END_MONTH, state.CONTRACT_PERIOD_END_DAY)
	var fa_start_day: int = state._find_calendar_day(state.FA_PERIOD_START_MONTH, state.FA_PERIOD_START_DAY)
	var fa_end_day: int = state._find_calendar_day(state.FA_PERIOD_END_MONTH, state.FA_PERIOD_END_DAY)
	var phase_label: String = "通常期間"
	if state.is_contract_period():
		phase_label = "契約更改期間"
	elif state.is_fa_period():
		phase_label = "FA交渉期間"

	return {
		"team_name": team.name,
		"phase_label": phase_label,
		"contract_period_label": "%s 〜 %s" % [
			state.get_date_label_for_day(contract_start_day),
			state.get_date_label_for_day(contract_end_day)
		],
		"fa_period_label": "%s 〜 %s" % [
			state.get_date_label_for_day(fa_start_day),
			state.get_date_label_for_day(fa_end_day)
		],
		"expiring_count": int(summary.get("expiring_count", 0)),
		"fa_watch_count": fa_watch_players.size(),
		"external_fa_count": external_candidates,
		"contract_now": state.is_contract_period(),
		"fa_now": state.is_fa_period(),
		"expiring_players": expiring_players,
		"fa_watch_players": fa_watch_players
	}
