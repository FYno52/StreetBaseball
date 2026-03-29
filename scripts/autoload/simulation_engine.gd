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

	var away_attack: float = _calc_team_attack_value(away_team)
	var home_attack: float = _calc_team_attack_value(home_team)

	var away_pitch_def: float = _calc_pitcher_defense_value(away_starter)
	var home_pitch_def: float = _calc_pitcher_defense_value(home_starter)

	var away_score: int = _calc_score_from_matchup(away_attack, home_pitch_def)
	var home_score: int = _calc_score_from_matchup(home_attack, away_pitch_def)

	var log_lines: Array[String] = []
	log_lines.append("試合開始")
	log_lines.append("%s vs %s" % [away_team.name, home_team.name])

	if away_starter != null:
		log_lines.append("away starter: %s" % away_starter.full_name)
	else:
		log_lines.append("away starter: none")

	if home_starter != null:
		log_lines.append("home starter: %s" % home_starter.full_name)
	else:
		log_lines.append("home starter: none")

	log_lines.append("away_attack=%.2f / home_pitch_def=%.2f" % [away_attack, home_pitch_def])
	log_lines.append("home_attack=%.2f / away_pitch_def=%.2f" % [home_attack, away_pitch_def])
	log_lines.append("9回終了")
	log_lines.append("%s %d - %d %s" % [away_team.name, away_score, home_score, home_team.name])

	if away_score > home_score:
		log_lines.append("%s の勝利" % away_team.name)
	elif home_score > away_score:
		log_lines.append("%s の勝利" % home_team.name)
	else:
		log_lines.append("引き分け")

	game.played = true
	game.away_score = away_score
	game.home_score = home_score
	game.log_lines.clear()
	for line in log_lines:
		game.log_lines.append(line)

	_apply_team_result(away_team, home_team, away_score, home_score)
	_apply_minimal_player_stats(away_team, home_team, away_starter, home_starter, away_score, home_score)

	return {
		"away_team_id": away_team.id,
		"home_team_id": home_team.id,
		"away_score": away_score,
		"home_score": home_score,
		"log_lines": log_lines,
	}

func _calc_team_attack_value(team) -> float:
	var total: float = 0.0
	var count: int = 0

	for player_id in team.lineup_vs_r:
		var p = LeagueState.get_player(str(player_id))
		if p == null:
			continue

		var contact: float = float(p.ratings["contact"])
		var power_rating: float = float(p.ratings["power"])
		var eye: float = float(p.ratings["eye"])
		var speed: float = float(p.ratings["speed"])

		var hitter_value: float = contact * 0.35 + power_rating * 0.35 + eye * 0.20 + speed * 0.10
		total += hitter_value
		count += 1

	if count == 0:
		return 50.0

	return total / float(count)

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

func _apply_minimal_player_stats(away_team, home_team, away_starter, home_starter, away_score: int, home_score: int) -> void:
	_apply_minimal_batting_stats(away_team, away_score)
	_apply_minimal_batting_stats(home_team, home_score)

	_apply_minimal_pitching_stats(away_starter, home_score, away_score > home_score, away_score < home_score)
	_apply_minimal_pitching_stats(home_starter, away_score, home_score > away_score, home_score < away_score)

func _apply_minimal_batting_stats(team, team_score: int) -> void:
	var lineup_players: Array = []

	for player_id in team.lineup_vs_r:
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
