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

	game.played = true
	game.away_score = away_score
	game.home_score = home_score
	game.log_lines.clear()
	for line in log_lines:
		game.log_lines.append(line)

	_apply_team_result(away_team, home_team, away_score, home_score)
	_apply_minimal_player_stats(away_team, home_team, away_starter, home_starter, away_score, home_score, away_lineup_ids, home_lineup_ids)

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

func _apply_minimal_player_stats(_away_team, _home_team, away_starter, home_starter, away_score: int, home_score: int, away_lineup_ids: Array[String], home_lineup_ids: Array[String]) -> void:
	_apply_minimal_batting_stats(away_lineup_ids, away_score)
	_apply_minimal_batting_stats(home_lineup_ids, home_score)

	_apply_minimal_pitching_stats(away_starter, home_score, away_score > home_score, away_score < home_score)
	_apply_minimal_pitching_stats(home_starter, away_score, home_score > away_score, home_score < away_score)

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

func _apply_minimal_pitching_stats(pitcher, runs_allowed: int, got_win: bool, got_loss: bool) -> void:
	if pitcher == null:
		return

	pitcher.pitching_stats["g"] = int(pitcher.pitching_stats["g"]) + 1
	pitcher.pitching_stats["gs"] = int(pitcher.pitching_stats["gs"]) + 1
	pitcher.pitching_stats["outs"] = int(pitcher.pitching_stats["outs"]) + 27
	pitcher.pitching_stats["er"] = int(pitcher.pitching_stats["er"]) + runs_allowed
	pitcher.pitching_stats["ha"] = int(pitcher.pitching_stats["ha"]) + maxi(runs_allowed, rng.randi_range(4, 10))
	pitcher.pitching_stats["hra"] = int(pitcher.pitching_stats["hra"]) + mini(runs_allowed, rng.randi_range(0, 2))
	pitcher.pitching_stats["bb"] = int(pitcher.pitching_stats["bb"]) + rng.randi_range(1, 5)
	pitcher.pitching_stats["so"] = int(pitcher.pitching_stats["so"]) + rng.randi_range(3, 10)

	if got_win:
		pitcher.pitching_stats["wins"] = int(pitcher.pitching_stats["wins"]) + 1
	elif got_loss:
		pitcher.pitching_stats["losses"] = int(pitcher.pitching_stats["losses"]) + 1

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
