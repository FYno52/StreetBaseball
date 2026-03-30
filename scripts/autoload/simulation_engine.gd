extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func simulate_game(game, away_team, home_team) -> Dictionary:
	if game.played:
		return {
			"away_team_id": away_team.id,
			"home_team_id": home_team.id,
			"away_score": game.away_score,
			"home_score": game.home_score,
			"log_lines": game.log_lines,
		}

	var away_starter = LeagueState.get_starting_pitcher_for_day(str(away_team.id), int(game.day))
	var home_starter = LeagueState.get_starting_pitcher_for_day(str(home_team.id), int(game.day))

	var away_lineup_ids: Array[String] = _get_lineup_ids_for_matchup(away_team, home_starter)
	var home_lineup_ids: Array[String] = _get_lineup_ids_for_matchup(home_team, away_starter)

	var away_attack: float = _calc_team_attack_value(away_team, away_lineup_ids, home_starter)
	var home_attack: float = _calc_team_attack_value(home_team, home_lineup_ids, away_starter)

	var away_pitch_def: float = _calc_pitcher_defense_value(away_starter)
	var home_pitch_def: float = _calc_pitcher_defense_value(home_starter)

	var away_score: int = _calc_score_from_matchup(away_attack, home_pitch_def)
	var home_score: int = _calc_score_from_matchup(home_attack, away_pitch_def)
	var run_margin: int = abs(away_score - home_score)

	var away_plan: Array = _build_pitching_plan(away_team, away_starter, home_score, away_score > home_score, run_margin)
	var home_plan: Array = _build_pitching_plan(home_team, home_starter, away_score, home_score > away_score, run_margin)

	var winning_pitcher = null
	var losing_pitcher = null
	var save_pitcher = null

	if away_score > home_score:
		winning_pitcher = _get_winning_pitcher_from_plan(away_plan)
		losing_pitcher = _get_losing_pitcher_from_plan(home_plan)
		save_pitcher = _get_save_pitcher_from_plan(away_plan, run_margin)
	elif home_score > away_score:
		winning_pitcher = _get_winning_pitcher_from_plan(home_plan)
		losing_pitcher = _get_losing_pitcher_from_plan(away_plan)
		save_pitcher = _get_save_pitcher_from_plan(home_plan, run_margin)

	var log_lines: Array[String] = []
	log_lines.append("Game Start")
	log_lines.append("%s vs %s" % [away_team.name, home_team.name])

	if away_starter != null:
		log_lines.append("away starter: %s (%s)" % [away_starter.full_name, away_starter.throws])
	else:
		log_lines.append("away starter: none")

	if home_starter != null:
		log_lines.append("home starter: %s (%s)" % [home_starter.full_name, home_starter.throws])
	else:
		log_lines.append("home starter: none")

	log_lines.append("away lineup vs %s" % _get_pitcher_hand_label(home_starter))
	log_lines.append("home lineup vs %s" % _get_pitcher_hand_label(away_starter))
	log_lines.append("away_attack=%.2f / home_pitch_def=%.2f" % [away_attack, home_pitch_def])
	log_lines.append("home_attack=%.2f / away_pitch_def=%.2f" % [home_attack, away_pitch_def])
	log_lines.append("End of 9th")
	log_lines.append("%s %d - %d %s" % [away_team.name, away_score, home_score, home_team.name])

	if away_score > home_score:
		log_lines.append("%s win" % away_team.name)
	elif home_score > away_score:
		log_lines.append("%s win" % home_team.name)
	else:
		log_lines.append("Draw")

	if winning_pitcher != null:
		log_lines.append("Winning pitcher: %s" % winning_pitcher.full_name)
	if losing_pitcher != null:
		log_lines.append("Losing pitcher: %s" % losing_pitcher.full_name)
	if save_pitcher != null:
		log_lines.append("Save: %s" % save_pitcher.full_name)

	game.played = true
	game.away_score = away_score
	game.home_score = home_score
	game.winning_pitcher_id = "" if winning_pitcher == null else str(winning_pitcher.id)
	game.losing_pitcher_id = "" if losing_pitcher == null else str(losing_pitcher.id)
	game.save_pitcher_id = "" if save_pitcher == null else str(save_pitcher.id)
	game.log_lines.clear()
	for line in log_lines:
		game.log_lines.append(line)

	_apply_team_result(away_team, home_team, away_score, home_score)
	_apply_minimal_player_stats(away_team, home_team, away_score, home_score, away_lineup_ids, home_lineup_ids, away_plan, home_plan)

	return {
		"away_team_id": away_team.id,
		"home_team_id": home_team.id,
		"away_score": away_score,
		"home_score": home_score,
		"log_lines": log_lines,
	}

func _get_lineup_ids_for_matchup(team, opposing_pitcher) -> Array[String]:
	if team == null:
		return []

	if opposing_pitcher != null and str(opposing_pitcher.throws) == "L" and not team.lineup_vs_l.is_empty():
		return team.lineup_vs_l

	if not team.lineup_vs_r.is_empty():
		return team.lineup_vs_r

	return team.lineup_vs_l

func _calc_team_attack_value(team, lineup_ids: Array[String] = [], opposing_pitcher = null) -> float:
	var total: float = 0.0
	var count: int = 0
	var resolved_lineup_ids: Array[String] = lineup_ids

	if resolved_lineup_ids.is_empty():
		resolved_lineup_ids = _get_lineup_ids_for_matchup(team, opposing_pitcher)

	for player_id in resolved_lineup_ids:
		var p = LeagueState.get_player(str(player_id))
		if p == null:
			continue

		var contact: float = float(p.ratings["contact"])
		var power_rating: float = float(p.ratings["power"])
		var eye: float = float(p.ratings["eye"])
		var speed: float = float(p.ratings["speed"])
		var handedness_bonus: float = _calc_handedness_bonus(p, opposing_pitcher)

		var hitter_value: float = contact * 0.35 + power_rating * 0.35 + eye * 0.20 + speed * 0.10 + handedness_bonus
		total += hitter_value
		count += 1

	if count == 0:
		return 50.0

	return total / float(count)

func _calc_handedness_bonus(batter, opposing_pitcher) -> float:
	if batter == null or opposing_pitcher == null:
		return 0.0

	var split_rating: float = float(batter.ratings.get("vs_left", 50))
	if str(opposing_pitcher.throws) == "L":
		return (split_rating - 50.0) * 0.08

	return 0.0

func _get_pitcher_hand_label(pitcher) -> String:
	if pitcher == null:
		return "RHP"

	if str(pitcher.throws) == "L":
		return "LHP"

	return "RHP"

func _calc_pitcher_defense_value(pitcher) -> float:
	if pitcher == null:
		return 50.0

	var velocity: float = float(pitcher.ratings["velocity"])
	var control: float = float(pitcher.ratings["control"])
	var stamina: float = float(pitcher.ratings["stamina"])
	var break_value: float = float(pitcher.ratings["break"])
	var k_rate: float = float(pitcher.ratings["k_rate"])
	var composure: float = float(pitcher.ratings["composure"])

	return velocity * 0.20 + control * 0.22 + stamina * 0.18 + break_value * 0.18 + k_rate * 0.12 + composure * 0.10

func _calc_score_from_matchup(attack_value: float, pitch_def_value: float) -> int:
	var base_score: float = 4.0
	var diff: float = (attack_value - pitch_def_value) / 12.0
	var random_bonus: float = rng.randf_range(-2.0, 2.0)

	var raw_score: float = base_score + diff + random_bonus
	var final_score: int = int(round(raw_score))

	return maxi(0, final_score)

func _build_pitching_plan(team, starter, runs_allowed: int, team_won: bool, run_margin: int) -> Array:
	var plan: Array = []
	var starter_outs: int = _calc_starter_outs(starter)
	var remaining_outs: int = maxi(0, 27 - starter_outs)

	if starter != null:
		plan.append({
			"pitcher": starter,
			"outs": starter_outs,
			"gs": true,
			"decision": "none",
			"save": false,
			"hold": false,
		})

	if remaining_outs <= 0:
		_assign_runs_to_plan(plan, runs_allowed)
		return plan

	var bullpen = LeagueState.get_team_bullpen(str(team.id))
	var closer = bullpen.get("closer", null)
	var setup_list: Array = bullpen.get("setup", [])
	var middle_list: Array = bullpen.get("middle", [])
	var long_reliever = bullpen.get("long", null)

	var reliever_queue: Array = []
	if team_won and run_margin <= 3 and closer != null:
		if remaining_outs > 3 and setup_list.size() > 0:
			reliever_queue.append(setup_list[0])
		if remaining_outs > 6 and setup_list.size() > 1:
			reliever_queue.append(setup_list[1])
		if remaining_outs > 3 and reliever_queue.is_empty() and middle_list.size() > 0:
			reliever_queue.append(middle_list[0])
		if remaining_outs > 3 and reliever_queue.is_empty() and long_reliever != null:
			reliever_queue.append(long_reliever)
		reliever_queue.append(closer)
	else:
		if long_reliever != null:
			reliever_queue.append(long_reliever)
		for pitcher in middle_list:
			if not reliever_queue.has(pitcher):
				reliever_queue.append(pitcher)
		for pitcher in setup_list:
			if not reliever_queue.has(pitcher):
				reliever_queue.append(pitcher)
		if closer != null and not reliever_queue.has(closer):
			reliever_queue.append(closer)

	if reliever_queue.is_empty() and starter != null:
		reliever_queue.append(starter)

	while remaining_outs > 0 and not reliever_queue.is_empty():
		var pitcher = reliever_queue.pop_front()
		if pitcher == null:
			continue

		var outing_outs: int = min(remaining_outs, _calc_reliever_outs(pitcher, remaining_outs))
		plan.append({
			"pitcher": pitcher,
			"outs": outing_outs,
			"gs": false,
			"decision": "none",
			"save": false,
			"hold": false,
		})
		remaining_outs -= outing_outs

	if remaining_outs > 0 and starter != null:
		plan.append({
			"pitcher": starter,
			"outs": remaining_outs,
			"gs": false,
			"decision": "none",
			"save": false,
			"hold": false,
		})

	_assign_runs_to_plan(plan, runs_allowed)
	_mark_bullpen_results(plan, team_won, run_margin)
	return plan

func _calc_starter_outs(starter) -> int:
	if starter == null:
		return 15

	var stamina: int = int(starter.ratings.get("stamina", 50))
	var target_innings: int = clampi(int(round(5.0 + (float(stamina) - 50.0) / 18.0 + rng.randf_range(-1.0, 1.0))), 4, 9)
	return target_innings * 3

func _calc_reliever_outs(pitcher, remaining_outs: int) -> int:
	if pitcher == null:
		return remaining_outs

	var role: String = str(pitcher.role)
	if role == "closer":
		return min(3, remaining_outs)
	if role == "reliever":
		return min(6, remaining_outs)
	return min(remaining_outs, 9)

func _assign_runs_to_plan(plan: Array, runs_allowed: int) -> void:
	if plan.is_empty():
		return

	var total_weight: int = 0
	for outing in plan:
		var outs: int = int(outing["outs"])
		var weight: int = maxi(1, outs)
		if bool(outing["gs"]):
			weight += 2
		outing["weight"] = weight
		outing["er"] = 0
		total_weight += weight

	var remaining_runs: int = runs_allowed
	for i in range(plan.size()):
		var outing = plan[i]
		var assigned_runs: int = 0
		if i == plan.size() - 1:
			assigned_runs = remaining_runs
		elif total_weight > 0 and remaining_runs > 0:
			assigned_runs = mini(remaining_runs, int(round(float(runs_allowed) * float(outing["weight"]) / float(total_weight))))
		outing["er"] = assigned_runs
		remaining_runs -= assigned_runs
		total_weight -= int(outing["weight"])
		plan[i] = outing

	var index: int = 0
	while remaining_runs > 0 and plan.size() > 0:
		var outing = plan[index % plan.size()]
		outing["er"] = int(outing["er"]) + 1
		plan[index % plan.size()] = outing
		remaining_runs -= 1
		index += 1

func _mark_bullpen_results(plan: Array, team_won: bool, run_margin: int) -> void:
	if plan.is_empty():
		return

	if team_won:
		for i in range(plan.size()):
			var outing = plan[i]
			if i == 0 or plan.size() == 1:
				outing["decision"] = "win"
			elif i == plan.size() - 1 and run_margin <= 3 and str(outing["pitcher"].role) == "closer":
				outing["save"] = true
			elif i < plan.size() - 1 and run_margin <= 3:
				outing["hold"] = true
			plan[i] = outing
	else:
		var losing_outing = plan[0]
		losing_outing["decision"] = "loss"
		plan[0] = losing_outing

func _get_winning_pitcher_from_plan(plan: Array):
	for outing in plan:
		if str(outing["decision"]) == "win":
			return outing["pitcher"]
	if plan.is_empty():
		return null
	return plan[0]["pitcher"]

func _get_losing_pitcher_from_plan(plan: Array):
	for outing in plan:
		if str(outing["decision"]) == "loss":
			return outing["pitcher"]
	if plan.is_empty():
		return null
	return plan[0]["pitcher"]

func _get_save_pitcher_from_plan(plan: Array, run_margin: int):
	if run_margin > 3:
		return null
	for outing in plan:
		if bool(outing["save"]):
			return outing["pitcher"]
	return null

func _apply_team_result(away_team, home_team, away_score: int, home_score: int) -> void:
	away_team.standings["runs_for"] = int(away_team.standings["runs_for"]) + away_score
	away_team.standings["runs_against"] = int(away_team.standings["runs_against"]) + home_score

	home_team.standings["runs_for"] = int(home_team.standings["runs_for"]) + home_score
	home_team.standings["runs_against"] = int(home_team.standings["runs_against"]) + away_score

	if away_score > home_score:
		away_team.standings["wins"] = int(away_team.standings["wins"]) + 1
		home_team.standings["losses"] = int(home_team.standings["losses"]) + 1
	elif home_score > away_score:
		home_team.standings["wins"] = int(home_team.standings["wins"]) + 1
		away_team.standings["losses"] = int(away_team.standings["losses"]) + 1
	else:
		away_team.standings["draws"] = int(away_team.standings["draws"]) + 1
		home_team.standings["draws"] = int(home_team.standings["draws"]) + 1

func _apply_minimal_player_stats(_away_team, _home_team, away_score: int, home_score: int, away_lineup_ids: Array[String], home_lineup_ids: Array[String], away_plan: Array, home_plan: Array) -> void:
	_apply_minimal_batting_stats(away_lineup_ids, away_score)
	_apply_minimal_batting_stats(home_lineup_ids, home_score)
	_apply_pitching_plan_stats(away_plan)
	_apply_pitching_plan_stats(home_plan)

func _apply_minimal_batting_stats(lineup_ids: Array[String], team_score: int) -> void:
	var lineup_players: Array = []

	for player_id in lineup_ids:
		var p = LeagueState.get_player(str(player_id))
		if p != null:
			lineup_players.append(p)

	if lineup_players.is_empty():
		return

	var total_hits: int = maxi(team_score, rng.randi_range(4, 12))
	var total_home_runs: int = mini(team_score, rng.randi_range(0, 2))
	var total_runs: int = team_score
	var total_rbi: int = team_score
	var total_so: int = rng.randi_range(4, 12)

	for p in lineup_players:
		p.batting_stats["g"] = int(p.batting_stats["g"]) + 1
		p.batting_stats["pa"] = int(p.batting_stats["pa"]) + 4
		p.batting_stats["ab"] = int(p.batting_stats["ab"]) + 4

	for i in range(total_hits):
		var batter = lineup_players[rng.randi_range(0, lineup_players.size() - 1)]
		batter.batting_stats["h"] = int(batter.batting_stats["h"]) + 1

	for i in range(total_home_runs):
		var batter = lineup_players[rng.randi_range(0, lineup_players.size() - 1)]
		batter.batting_stats["hr"] = int(batter.batting_stats["hr"]) + 1

	for i in range(total_runs):
		var batter = lineup_players[rng.randi_range(0, lineup_players.size() - 1)]
		batter.batting_stats["runs"] = int(batter.batting_stats["runs"]) + 1

	for i in range(total_rbi):
		var batter = lineup_players[rng.randi_range(0, lineup_players.size() - 1)]
		batter.batting_stats["rbi"] = int(batter.batting_stats["rbi"]) + 1

	for i in range(total_so):
		var batter = lineup_players[rng.randi_range(0, lineup_players.size() - 1)]
		batter.batting_stats["so"] = int(batter.batting_stats["so"]) + 1

func _apply_pitching_plan_stats(plan: Array) -> void:
	for outing in plan:
		var pitcher = outing.get("pitcher", null)
		if pitcher == null:
			continue

		pitcher.pitching_stats["g"] = int(pitcher.pitching_stats["g"]) + 1
		if bool(outing.get("gs", false)):
			pitcher.pitching_stats["gs"] = int(pitcher.pitching_stats["gs"]) + 1

		var outs: int = int(outing.get("outs", 0))
		var er: int = int(outing.get("er", 0))
		pitcher.pitching_stats["outs"] = int(pitcher.pitching_stats["outs"]) + outs
		pitcher.pitching_stats["er"] = int(pitcher.pitching_stats["er"]) + er
		pitcher.pitching_stats["ha"] = int(pitcher.pitching_stats["ha"]) + maxi(er, rng.randi_range(1, maxi(2, outs / 3 + 1)))
		pitcher.pitching_stats["hra"] = int(pitcher.pitching_stats["hra"]) + mini(er, rng.randi_range(0, 1))
		pitcher.pitching_stats["bb"] = int(pitcher.pitching_stats["bb"]) + rng.randi_range(0, maxi(1, outs / 6))
		pitcher.pitching_stats["so"] = int(pitcher.pitching_stats["so"]) + rng.randi_range(0, maxi(1, outs / 2))

		match str(outing.get("decision", "none")):
			"win":
				pitcher.pitching_stats["wins"] = int(pitcher.pitching_stats["wins"]) + 1
			"loss":
				pitcher.pitching_stats["losses"] = int(pitcher.pitching_stats["losses"]) + 1

		if bool(outing.get("save", false)):
			pitcher.pitching_stats["saves"] = int(pitcher.pitching_stats["saves"]) + 1
		if bool(outing.get("hold", false)):
			pitcher.pitching_stats["holds"] = int(pitcher.pitching_stats["holds"]) + 1

func get_team_attack_value(team) -> float:
	return _calc_team_attack_value(team)

func get_team_pitch_value(team) -> float:
	if team == null:
		return 50.0

	if team.rotation_ids.size() == 0:
		return 50.0

	var starter = LeagueState.get_player(str(team.rotation_ids[0]))
	return _calc_pitcher_defense_value(starter)

func get_team_total_strength(team) -> float:
	var attack_value: float = get_team_attack_value(team)
	var pitch_value: float = get_team_pitch_value(team)
	return attack_value * 0.55 + pitch_value * 0.45
