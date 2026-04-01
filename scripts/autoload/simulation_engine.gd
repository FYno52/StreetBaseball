extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func simulate_game(game, away_team, home_team) -> Dictionary:
	return _build_game_package(game, away_team, home_team, true)


func prepare_live_game(game, away_team, home_team, command_profile: String = "neutral") -> Dictionary:
	return _build_game_package(game, away_team, home_team, false, command_profile)


func commit_prepared_live_game(game, away_team, home_team, prepared_package: Dictionary) -> Dictionary:
	if game == null or away_team == null or home_team == null:
		return {}
	if prepared_package.is_empty():
		return simulate_game(game, away_team, home_team)

	game.played = true
	game.away_score = int(prepared_package.get("away_score", 0))
	game.home_score = int(prepared_package.get("home_score", 0))
	game.winning_pitcher_id = str(prepared_package.get("winning_pitcher_id", ""))
	game.losing_pitcher_id = str(prepared_package.get("losing_pitcher_id", ""))
	game.save_pitcher_id = str(prepared_package.get("save_pitcher_id", ""))
	game.log_lines.clear()
	for line_value in prepared_package.get("log_lines", []):
		game.log_lines.append(str(line_value))
	game.play_events.clear()
	for event_value in prepared_package.get("play_events", []):
		if event_value is Dictionary:
			game.play_events.append((event_value as Dictionary).duplicate(true))

	var away_lineup_ids: Array[String] = []
	for player_id in prepared_package.get("away_lineup_ids", []):
		away_lineup_ids.append(str(player_id))
	var home_lineup_ids: Array[String] = []
	for player_id in prepared_package.get("home_lineup_ids", []):
		home_lineup_ids.append(str(player_id))

	var away_plan: Array = []
	for outing_value in prepared_package.get("away_plan", []):
		away_plan.append(outing_value)
	var home_plan: Array = []
	for outing_value in prepared_package.get("home_plan", []):
		home_plan.append(outing_value)

	_apply_team_result(away_team, home_team, int(game.away_score), int(game.home_score))
	_apply_minimal_player_stats(away_team, home_team, int(game.away_score), int(game.home_score), away_lineup_ids, home_lineup_ids, away_plan, home_plan)

	return {
		"away_team_id": away_team.id,
		"home_team_id": home_team.id,
		"away_score": game.away_score,
		"home_score": game.home_score,
		"log_lines": game.log_lines,
		"play_events": game.play_events,
	}


func _build_game_package(game, away_team, home_team, commit_result: bool, command_profile: String = "neutral") -> Dictionary:
	if game == null or away_team == null or home_team == null:
		return {
			"away_team_id": "",
			"home_team_id": "",
			"away_score": 0,
			"home_score": 0,
			"log_lines": [],
			"play_events": [],
		}

	if game.played:
		return {
			"away_team_id": away_team.id,
			"home_team_id": home_team.id,
			"away_score": game.away_score,
			"home_score": game.home_score,
			"log_lines": game.log_lines,
			"play_events": game.play_events,
		}

	var away_starter = LeagueState.get_starting_pitcher_for_day(str(away_team.id), int(game.day))
	var home_starter = LeagueState.get_starting_pitcher_for_day(str(home_team.id), int(game.day))

	var away_lineup_ids: Array[String] = _get_lineup_ids_for_matchup(away_team, home_starter)
	var home_lineup_ids: Array[String] = _get_lineup_ids_for_matchup(home_team, away_starter)
	var away_event_bonus: Dictionary = LeagueState.get_team_event_bonus(str(away_team.id))
	var home_event_bonus: Dictionary = LeagueState.get_team_event_bonus(str(home_team.id))

	var away_attack: float = _calc_team_attack_value(away_team, away_lineup_ids, home_starter)
	var home_attack: float = _calc_team_attack_value(home_team, home_lineup_ids, away_starter)

	var away_pitch_def: float = _calc_pitcher_defense_value(away_starter)
	var home_pitch_def: float = _calc_pitcher_defense_value(home_starter)

	away_attack += float(away_event_bonus.get("attack", 0.0))
	home_attack += float(home_event_bonus.get("attack", 0.0))
	away_pitch_def += float(away_event_bonus.get("pitch", 0.0))
	home_pitch_def += float(home_event_bonus.get("pitch", 0.0))

	var away_command_bonus: Dictionary = _get_live_command_bonus(command_profile, away_team)
	away_attack += float(away_command_bonus.get("attack", 0.0))
	home_pitch_def += float(away_command_bonus.get("pitch_pressure", 0.0))

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
	log_lines.append("試合開始")
	log_lines.append("%s vs %s" % [away_team.name, home_team.name])
	log_lines.append("ビジター先発: %s" % (away_starter.full_name if away_starter != null else "未設定"))
	log_lines.append("ホーム先発: %s" % (home_starter.full_name if home_starter != null else "未設定"))
	log_lines.append("ビジター方針: %s" % _get_strategy_log_label(str(away_team.strategy)))
	log_lines.append("ホーム方針: %s" % _get_strategy_log_label(str(home_team.strategy)))
	if command_profile != "neutral":
		log_lines.append("ライブ指示: %s" % _get_live_command_label(command_profile))
	log_lines.append("%s %d - %d %s" % [away_team.name, away_score, home_score, home_team.name])

	if away_score > home_score:
		log_lines.append("%s の勝利" % away_team.name)
	elif home_score > away_score:
		log_lines.append("%s の勝利" % home_team.name)
	else:
		log_lines.append("引き分け")

	if winning_pitcher != null:
		log_lines.append("勝利投手: %s" % winning_pitcher.full_name)
	if losing_pitcher != null:
		log_lines.append("敗戦投手: %s" % losing_pitcher.full_name)
	if save_pitcher != null:
		log_lines.append("セーブ: %s" % save_pitcher.full_name)

	var built_events: Array[Dictionary] = _build_game_event_sequence(game, away_team, home_team, away_score, home_score, away_plan, home_plan, away_lineup_ids, home_lineup_ids, command_profile)

	if commit_result:
		game.played = true
		game.away_score = away_score
		game.home_score = home_score
		game.winning_pitcher_id = "" if winning_pitcher == null else str(winning_pitcher.id)
		game.losing_pitcher_id = "" if losing_pitcher == null else str(losing_pitcher.id)
		game.save_pitcher_id = "" if save_pitcher == null else str(save_pitcher.id)
		game.log_lines.clear()
		for line in log_lines:
			game.log_lines.append(line)
		game.play_events = built_events

		_apply_team_result(away_team, home_team, away_score, home_score)
		_apply_minimal_player_stats(away_team, home_team, away_score, home_score, away_lineup_ids, home_lineup_ids, away_plan, home_plan)

	return {
		"away_team_id": away_team.id,
		"home_team_id": home_team.id,
		"away_score": away_score,
		"home_score": home_score,
		"winning_pitcher_id": "" if winning_pitcher == null else str(winning_pitcher.id),
		"losing_pitcher_id": "" if losing_pitcher == null else str(losing_pitcher.id),
		"save_pitcher_id": "" if save_pitcher == null else str(save_pitcher.id),
		"away_lineup_ids": away_lineup_ids.duplicate(),
		"home_lineup_ids": home_lineup_ids.duplicate(),
		"away_plan": away_plan.duplicate(true),
		"home_plan": home_plan.duplicate(true),
		"log_lines": log_lines,
		"play_events": built_events,
	}


func _get_live_command_bonus(command_profile: String, offense_team) -> Dictionary:
	if offense_team == null or str(LeagueState.controlled_team_id) != str(offense_team.id):
		return {
			"attack": 0.0,
			"pitch_pressure": 0.0,
		}

	match command_profile:
		"aggressive":
			return {"attack": 0.8, "pitch_pressure": -0.2}
		"bunt":
			return {"attack": -0.6, "pitch_pressure": 0.0}
		"advance":
			return {"attack": 0.2, "pitch_pressure": 0.0}
		"intentional_walk":
			return {"attack": -0.2, "pitch_pressure": 0.2}
		_:
			return {"attack": 0.0, "pitch_pressure": 0.0}

func _get_live_command_label(command_profile: String) -> String:
	match command_profile:
		"aggressive":
			return "強攻"
		"bunt":
			return "バント"
		"advance":
			return "進塁重視"
		"intentional_walk":
			return "敬遠"
		_:
			return "通常"

func _build_game_event_sequence(game, away_team, home_team, away_score: int, home_score: int, away_plan: Array, home_plan: Array, away_lineup_ids: Array[String], home_lineup_ids: Array[String], command_profile: String = "neutral") -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	events.append({
		"type": "game_start",
		"game_id": str(game.id),
		"date_label": str(game.date_label),
		"away_team_id": str(away_team.id),
		"away_team_name": str(away_team.name),
		"home_team_id": str(home_team.id),
		"home_team_name": str(home_team.name),
	})

	var away_by_inning: Array[int] = _distribute_runs_by_inning(away_score)
	var home_by_inning: Array[int] = _distribute_runs_by_inning(home_score)
	var away_total: int = 0
	var home_total: int = 0
	var away_batter_index: int = 0
	var home_batter_index: int = 0

	for inning in range(9):
		var away_runs: int = away_by_inning[inning]
		var home_runs: int = home_by_inning[inning]
		var away_command: String = command_profile if str(LeagueState.controlled_team_id) == str(away_team.id) else "neutral"
		var home_command: String = command_profile if str(LeagueState.controlled_team_id) == str(home_team.id) else "neutral"
		var away_sequence: Dictionary = _build_half_inning_sequence(away_team, away_lineup_ids, away_batter_index, inning + 1, "top", away_runs, away_total, home_total, home_plan, inning * 3, away_command)
		for event_value in away_sequence.get("events", []):
			events.append(event_value)
		away_batter_index = int(away_sequence.get("next_batter_index", away_batter_index))
		away_total = int(away_sequence.get("away_score", away_total))
		home_total = int(away_sequence.get("home_score", home_total))

		var home_sequence: Dictionary = _build_half_inning_sequence(home_team, home_lineup_ids, home_batter_index, inning + 1, "bottom", home_runs, away_total, home_total, away_plan, inning * 3, home_command)
		for event_value in home_sequence.get("events", []):
			events.append(event_value)
		home_batter_index = int(home_sequence.get("next_batter_index", home_batter_index))
		away_total = int(home_sequence.get("away_score", away_total))
		home_total = int(home_sequence.get("home_score", home_total))

	events.append({
		"type": "pitching_summary",
		"side": "away",
		"pitchers": _build_pitching_event_rows(away_plan),
	})
	events.append({
		"type": "pitching_summary",
		"side": "home",
		"pitchers": _build_pitching_event_rows(home_plan),
	})
	events.append({
		"type": "game_end",
		"away_score": away_score,
		"home_score": home_score,
		"winning_pitcher_id": str(game.winning_pitcher_id),
		"losing_pitcher_id": str(game.losing_pitcher_id),
		"save_pitcher_id": str(game.save_pitcher_id),
	})
	return events

func _build_half_inning_sequence(team, lineup_ids: Array[String], batter_index: int, inning: int, side: String, target_runs: int, away_score_before: int, home_score_before: int, defensive_plan: Array, defensive_outs_before: int, command_profile: String = "neutral") -> Dictionary:
	var events: Array[Dictionary] = []
	var outs: int = 0
	var runs_scored: int = 0
	var away_score: int = away_score_before
	var home_score: int = home_score_before
	var bases: Array[bool] = [false, false, false]
	var lineup_size: int = maxi(1, lineup_ids.size())
	var next_batter_index: int = batter_index

	events.append({
		"type": "half_inning_start",
		"inning": inning,
		"side": side,
		"outs": outs,
		"bases": bases.duplicate(),
		"away_score": away_score,
		"home_score": home_score,
		"offense_team_id": str(team.id),
		"offense_team_name": str(team.name),
		"pitcher_id": str(_get_pitcher_from_plan_for_outs(defensive_plan, defensive_outs_before).get("id", "")),
		"pitcher_name": str(_get_pitcher_from_plan_for_outs(defensive_plan, defensive_outs_before).get("name", "")),
	})

	var safety_count: int = 0
	while outs < 3 and safety_count < 20:
		safety_count += 1
		var active_pitcher: Dictionary = _get_pitcher_from_plan_for_outs(defensive_plan, defensive_outs_before + outs)
		var batter_info: Dictionary = _get_lineup_batter_info(lineup_ids, next_batter_index)
		next_batter_index = int(batter_info.get("next_index", 0))
		var result: String = _choose_at_bat_result(target_runs - runs_scored, outs, bases, command_profile)
		var batted_ball: Dictionary = _build_batted_ball_info(result)
		var pitch_count_info: Dictionary = _build_pitch_count_info(result, command_profile)
		var bases_before: Array[bool] = bases.duplicate()
		var outs_before: int = outs
		for pitch_event in _build_pitch_events(inning, side, batter_info, active_pitcher, team, away_score, home_score, bases_before, pitch_count_info):
			events.append(pitch_event)
		var play_result: Dictionary = _apply_at_bat_result(result, bases, outs)
		bases = play_result.get("bases", [false, false, false])
		outs = int(play_result.get("outs", outs))
		var play_runs: int = int(play_result.get("runs_scored", 0))
		runs_scored += play_runs
		if side == "top":
			away_score += play_runs
		else:
			home_score += play_runs

		events.append({
			"type": "at_bat",
			"inning": inning,
			"side": side,
			"batter_id": str(batter_info.get("player_id", "")),
			"batter_name": str(batter_info.get("player_name", "")),
			"pitcher_id": str(active_pitcher.get("id", "")),
			"pitcher_name": str(active_pitcher.get("name", "")),
			"result": result,
			"result_label": _get_at_bat_result_label(result),
			"batted_ball_type": str(batted_ball.get("type", "")),
			"batted_ball_label": str(batted_ball.get("type_label", "")),
			"batted_ball_direction": str(batted_ball.get("direction", "")),
			"batted_ball_direction_label": str(batted_ball.get("direction_label", "")),
			"balls": int(pitch_count_info.get("balls", 0)),
			"strikes": int(pitch_count_info.get("strikes", 0)),
			"pitch_count": int(pitch_count_info.get("pitch_count", 0)),
			"pitch_result_summary": str(pitch_count_info.get("summary", "")),
			"outs_before": outs_before,
			"outs_on_play": int(play_result.get("outs_on_play", outs - outs_before)),
			"bases_before": bases_before,
			"outs": outs,
			"bases": bases.duplicate(),
			"runs_scored": play_runs,
			"play_note": str(play_result.get("play_note", "")),
			"command_profile": command_profile,
			"away_score": away_score,
			"home_score": home_score,
			"offense_team_id": str(team.id),
			"offense_team_name": str(team.name),
		})
		if runs_scored >= target_runs and outs >= 3:
			break

	if runs_scored < target_runs:
		while runs_scored < target_runs:
			var active_pitcher_force: Dictionary = _get_pitcher_from_plan_for_outs(defensive_plan, defensive_outs_before + outs)
			var batter_info_force: Dictionary = _get_lineup_batter_info(lineup_ids, next_batter_index)
			next_batter_index = int(batter_info_force.get("next_index", 0))
			var forced_result: String = "bunt_success" if command_profile == "bunt" and outs <= 1 and (bases[0] or bases[1]) else "home_run"
			var forced_batted_ball: Dictionary = _build_batted_ball_info(forced_result)
			var forced_pitch_count_info: Dictionary = _build_pitch_count_info(forced_result, command_profile)
			var bases_before_force: Array[bool] = bases.duplicate()
			var outs_before_force: int = outs
			for pitch_event in _build_pitch_events(inning, side, batter_info_force, active_pitcher_force, team, away_score, home_score, bases_before_force, forced_pitch_count_info):
				events.append(pitch_event)
			var forced_play: Dictionary = _apply_at_bat_result(forced_result, bases, outs)
			bases = forced_play.get("bases", [false, false, false])
			var forced_runs: int = mini(target_runs - runs_scored, int(forced_play.get("runs_scored", 0)))
			runs_scored += forced_runs
			if side == "top":
				away_score += forced_runs
			else:
				home_score += forced_runs
			events.append({
				"type": "at_bat",
				"inning": inning,
				"side": side,
				"batter_id": str(batter_info_force.get("player_id", "")),
				"batter_name": str(batter_info_force.get("player_name", "")),
				"pitcher_id": str(active_pitcher_force.get("id", "")),
				"pitcher_name": str(active_pitcher_force.get("name", "")),
				"result": forced_result,
				"result_label": _get_at_bat_result_label(forced_result),
				"batted_ball_type": str(forced_batted_ball.get("type", "")),
				"batted_ball_label": str(forced_batted_ball.get("type_label", "")),
				"batted_ball_direction": str(forced_batted_ball.get("direction", "")),
				"batted_ball_direction_label": str(forced_batted_ball.get("direction_label", "")),
				"balls": int(forced_pitch_count_info.get("balls", 0)),
				"strikes": int(forced_pitch_count_info.get("strikes", 0)),
				"pitch_count": int(forced_pitch_count_info.get("pitch_count", 0)),
				"pitch_result_summary": str(forced_pitch_count_info.get("summary", "")),
				"outs_before": outs_before_force,
				"outs_on_play": int(forced_play.get("outs_on_play", 0)),
				"bases_before": bases_before_force,
				"outs": outs,
				"bases": bases.duplicate(),
				"runs_scored": forced_runs,
				"play_note": str(forced_play.get("play_note", "")),
				"command_profile": command_profile,
				"away_score": away_score,
				"home_score": home_score,
				"offense_team_id": str(team.id),
				"offense_team_name": str(team.name),
			})

	if outs < 3:
		while outs < 3:
			var active_pitcher_out: Dictionary = _get_pitcher_from_plan_for_outs(defensive_plan, defensive_outs_before + outs)
			var batter_info_out: Dictionary = _get_lineup_batter_info(lineup_ids, next_batter_index)
			next_batter_index = int(batter_info_out.get("next_index", 0))
			var out_result: String = "out"
			var out_batted_ball: Dictionary = _build_batted_ball_info(out_result)
			var out_pitch_count_info: Dictionary = _build_pitch_count_info(out_result, command_profile)
			var bases_before_out: Array[bool] = bases.duplicate()
			var outs_before_out: int = outs
			for pitch_event in _build_pitch_events(inning, side, batter_info_out, active_pitcher_out, team, away_score, home_score, bases_before_out, out_pitch_count_info):
				events.append(pitch_event)
			var out_play: Dictionary = _apply_at_bat_result(out_result, bases, outs)
			bases = out_play.get("bases", [false, false, false])
			outs = int(out_play.get("outs", outs))
			events.append({
				"type": "at_bat",
				"inning": inning,
				"side": side,
				"batter_id": str(batter_info_out.get("player_id", "")),
				"batter_name": str(batter_info_out.get("player_name", "")),
				"pitcher_id": str(active_pitcher_out.get("id", "")),
				"pitcher_name": str(active_pitcher_out.get("name", "")),
				"result": out_result,
				"result_label": _get_at_bat_result_label(out_result),
				"batted_ball_type": str(out_batted_ball.get("type", "")),
				"batted_ball_label": str(out_batted_ball.get("type_label", "")),
				"batted_ball_direction": str(out_batted_ball.get("direction", "")),
				"batted_ball_direction_label": str(out_batted_ball.get("direction_label", "")),
				"balls": int(out_pitch_count_info.get("balls", 0)),
				"strikes": int(out_pitch_count_info.get("strikes", 0)),
				"pitch_count": int(out_pitch_count_info.get("pitch_count", 0)),
				"pitch_result_summary": str(out_pitch_count_info.get("summary", "")),
				"outs_before": outs_before_out,
				"outs_on_play": int(out_play.get("outs_on_play", outs - outs_before_out)),
				"bases_before": bases_before_out,
				"outs": outs,
				"bases": bases.duplicate(),
				"runs_scored": 0,
				"play_note": str(out_play.get("play_note", "")),
				"command_profile": command_profile,
				"away_score": away_score,
				"home_score": home_score,
				"offense_team_id": str(team.id),
				"offense_team_name": str(team.name),
			})

	events.append({
		"type": "half_inning",
		"inning": inning,
		"side": side,
		"runs_scored": target_runs,
		"away_score": away_score,
		"home_score": home_score,
		"outs": 3,
		"bases": [false, false, false],
		"offense_team_id": str(team.id),
		"offense_team_name": str(team.name),
	})

	return {
		"events": events,
		"next_batter_index": next_batter_index % lineup_size,
		"away_score": away_score,
		"home_score": home_score,
	}


func _build_pitch_events(inning: int, side: String, batter_info: Dictionary, pitcher_info: Dictionary, team, away_score: int, home_score: int, bases_before: Array[bool], pitch_count_info: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var balls_target: int = int(pitch_count_info.get("balls", 0))
	var strikes_target: int = int(pitch_count_info.get("strikes", 0))
	var pitch_total: int = maxi(1, int(pitch_count_info.get("pitch_count", 1)))
	var balls_now: int = 0
	var strikes_now: int = 0

	for pitch_number in range(1, pitch_total + 1):
		var is_last_pitch: bool = pitch_number == pitch_total
		var result_label: String = "投球"
		var pitch_type_label: String = _get_random_pitch_type_label()
		var pitch_zone_label: String = _get_random_pitch_zone_label()
		if not is_last_pitch:
			if balls_now < balls_target and strikes_now < strikes_target:
				if rng.randf() < 0.5:
					balls_now += 1
					result_label = "ボール"
				else:
					strikes_now += 1
					result_label = "ストライク"
			elif balls_now < balls_target:
				balls_now += 1
				result_label = "ボール"
			elif strikes_now < strikes_target:
				strikes_now += 1
				result_label = "ファウル" if strikes_now >= 2 and rng.randf() < 0.45 else "ストライク"
			else:
				result_label = "ファウル"
		else:
			balls_now = balls_target
			strikes_now = strikes_target
			result_label = str(pitch_count_info.get("summary", "打席結果"))

		events.append({
			"type": "pitch",
			"inning": inning,
			"side": side,
			"pitch_number": pitch_number,
			"batter_id": str(batter_info.get("player_id", "")),
			"batter_name": str(batter_info.get("player_name", "")),
			"pitcher_id": str(pitcher_info.get("id", "")),
			"pitcher_name": str(pitcher_info.get("name", "")),
			"pitch_result_label": result_label,
			"pitch_type_label": pitch_type_label,
			"pitch_zone_label": pitch_zone_label,
			"balls_after": balls_now,
			"strikes_after": strikes_now,
			"bases": bases_before.duplicate(),
			"away_score": away_score,
			"home_score": home_score,
			"offense_team_id": str(team.id),
			"offense_team_name": str(team.name),
		})

	return events


func _get_random_pitch_type_label() -> String:
	var pitch_types: Array[String] = ["ストレート", "スライダー", "カーブ", "フォーク", "ツーシーム", "カット"]
	return pitch_types[rng.randi_range(0, pitch_types.size() - 1)]


func _get_random_pitch_zone_label() -> String:
	var pitch_zones: Array[String] = ["外角高め", "外角低め", "内角高め", "内角低め", "真ん中高め", "真ん中低め"]
	return pitch_zones[rng.randi_range(0, pitch_zones.size() - 1)]


func _build_pitch_count_info(result: String, command_profile: String = "neutral") -> Dictionary:
	var balls: int = 0
	var strikes: int = 0
	var pitch_count: int = 0
	var summary: String = ""

	match result:
		"walk":
			balls = 4
			strikes = rng.randi_range(0, 2)
			pitch_count = balls + strikes
			summary = "%d-%d縺九ｉ蝗帷帥" % [balls, strikes]
		"strikeout":
			strikes = 3
			balls = rng.randi_range(0, 3)
			pitch_count = balls + strikes
			summary = "%d-%d縺九ｉ荳画険" % [balls, strikes]
		"bunt_success":
			balls = rng.randi_range(0, 1)
			strikes = rng.randi_range(0, 2)
			pitch_count = maxi(1, balls + strikes + rng.randi_range(0, 1))
			summary = "繝舌Φ繝医〒蜍晁ｲ"
		"home_run", "double", "triple", "single":
			balls = rng.randi_range(0, 3)
			strikes = rng.randi_range(0, 2)
			pitch_count = maxi(1, balls + strikes + 1)
			summary = "%d球目を打った" % pitch_count
		_:
			balls = rng.randi_range(0, 3)
			strikes = rng.randi_range(0, 2)
			pitch_count = maxi(1, balls + strikes + 1)
			summary = "%d球で打席終了" % pitch_count

	if command_profile == "aggressive":
		pitch_count = maxi(1, pitch_count - 1)
	elif command_profile == "advance":
		pitch_count += 1

	return {
		"balls": balls,
		"strikes": strikes,
		"pitch_count": pitch_count,
		"summary": summary,
	}

func _get_pitcher_from_plan_for_outs(plan: Array, target_outs: int) -> Dictionary:
	var covered_outs: int = 0
	for outing_value in plan:
		var outing: Dictionary = outing_value
		var pitcher = outing.get("pitcher", null)
		var outing_outs: int = int(outing.get("outs", 0))
		if pitcher == null:
			continue
		if target_outs < covered_outs + outing_outs:
			return {
				"id": str(pitcher.id),
				"name": str(pitcher.full_name),
			}
		covered_outs += outing_outs
	if not plan.is_empty():
		var last_outing: Dictionary = plan[plan.size() - 1]
		var last_pitcher = last_outing.get("pitcher", null)
		if last_pitcher != null:
			return {
				"id": str(last_pitcher.id),
				"name": str(last_pitcher.full_name),
			}
	return {
		"id": "",
		"name": "投手",
	}

func _build_batted_ball_info(result: String) -> Dictionary:
	match result:
		"walk":
			return {
				"type": "none",
				"type_label": "ボール判定",
				"direction": "none",
				"direction_label": "打球なし",
			}
		"strikeout":
			return {
				"type": "none",
				"type_label": "空振り",
				"direction": "none",
				"direction_label": "打球なし",
			}
		"fly_out":
			return _build_contact_event("fly", _get_random_direction(["LF", "CF", "RF"]))
		"ground_out":
			return _build_contact_event("ground", _get_random_direction(["1B", "2B", "3B", "SS"]))
		"double_play":
			return _build_contact_event("ground", _get_random_direction(["2B", "SS"]))
		"single":
			return _build_contact_event("line", _get_random_direction(["LF", "CF", "RF"]))
		"double":
			return _build_contact_event("gap", _get_random_direction(["LCF", "RCF", "LF", "RF"]))
		"triple":
			return _build_contact_event("gap", _get_random_direction(["LCF", "RCF"]))
		"home_run":
			return _build_contact_event("home_run", _get_random_direction(["LF", "CF", "RF"]))
		_:
			return _build_contact_event("ground", _get_random_direction(["P", "1B", "2B", "3B", "SS"]))

func _build_contact_event(ball_type: String, direction: String) -> Dictionary:
	return {
		"type": ball_type,
		"type_label": _get_batted_ball_type_label(ball_type),
		"direction": direction,
		"direction_label": _get_batted_ball_direction_label(direction),
	}

func _get_random_direction(candidates: Array[String]) -> String:
	if candidates.is_empty():
		return "none"
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _get_batted_ball_type_label(ball_type: String) -> String:
	match ball_type:
		"fly":
			return "外野フライ"
		"ground":
			return "ゴロ"
		"line":
			return "ライナー"
		"gap":
			return "長打性の打球"
		"home_run":
			return "ホームラン性の打球"
		_:
			return "打球"

func _get_batted_ball_direction_label(direction: String) -> String:
	match direction:
		"LF":
			return "レフト"
		"CF":
			return "センター"
		"RF":
			return "ライト"
		"LCF":
			return "左中間"
		"RCF":
			return "右中間"
		"1B":
			return "一塁線"
		"2B":
			return "二塁付近"
		"3B":
			return "三塁線"
		"SS":
			return "三遊間"
		"P":
			return "投手前"
		_:
			return "方向なし"
func _get_lineup_batter_info(lineup_ids: Array[String], batter_index: int) -> Dictionary:
	if lineup_ids.is_empty():
		return {
			"player_id": "",
			"player_name": "選手",
			"next_index": 0,
		}
	var lineup_size: int = lineup_ids.size()
	var resolved_index: int = posmod(batter_index, lineup_size)
	var player_id: String = str(lineup_ids[resolved_index])
	var player = LeagueState.get_player(player_id)
	return {
		"player_id": player_id,
		"player_name": player.full_name if player != null else "選手",
		"next_index": (resolved_index + 1) % lineup_size,
	}

func _choose_at_bat_result(remaining_runs: int, outs: int, bases: Array[bool], command_profile: String = "neutral") -> String:
	if command_profile == "bunt" and outs <= 1 and (bases[0] or bases[1]):
		var bunt_roll: float = rng.randf()
		if bunt_roll < 0.55:
			return "bunt_success"
		if bunt_roll < 0.80:
			return "ground_out"
		return "double_play"

	if command_profile == "aggressive":
		var aggressive_roll: float = rng.randf()
		if aggressive_roll < 0.18:
			return "home_run"
		if aggressive_roll < 0.36:
			return "double"
		if aggressive_roll < 0.52:
			return "single"
		if aggressive_roll < 0.72:
			return "strikeout"
		if aggressive_roll < 0.86:
			return "fly_out"
		return "ground_out"

	if command_profile == "advance" and (bases[0] or bases[1] or bases[2]):
		var advance_roll: float = rng.randf()
		if advance_roll < 0.25:
			return "single"
		if advance_roll < 0.45:
			return "ground_out"
		if advance_roll < 0.65:
			return "fly_out"
		if advance_roll < 0.80:
			return "walk"
		return "double"

	if command_profile == "intentional_walk" and bases[1] and rng.randf() < 0.35:
		return "walk"

	if remaining_runs <= 0:
		var no_run_roll: float = rng.randf()
		if no_run_roll < 0.35:
			return "strikeout"
		if no_run_roll < 0.65:
			return "ground_out"
		if no_run_roll < 0.80:
			return "fly_out"
		if no_run_roll < 0.88:
			return "walk"
		return "single"

	if outs >= 2 and remaining_runs > 0 and not bases[0] and not bases[1] and not bases[2]:
		return "home_run"

	if not bases[0] and not bases[1] and not bases[2]:
		var empty_roll: float = rng.randf()
		if empty_roll < 0.38:
			return "single"
		if empty_roll < 0.62:
			return "double"
		if empty_roll < 0.72:
			return "triple"
		if empty_roll < 0.86:
			return "home_run"
		return "strikeout"

	if bases[2] or bases[1]:
		var scoring_roll: float = rng.randf()
		if scoring_roll < 0.32:
			return "single"
		if scoring_roll < 0.56:
			return "double"
		if scoring_roll < 0.68:
			return "walk"
		if scoring_roll < 0.82:
			return "fly_out"
		return "home_run"

	if bases[0] and remaining_runs >= 2 and rng.randf() < 0.35:
		return "home_run"

	var runner_roll: float = rng.randf()
	if runner_roll < 0.22:
		return "walk"
	if runner_roll < 0.48:
		return "single"
	if runner_roll < 0.64:
		return "double"
	if runner_roll < 0.78 and outs <= 1:
		return "double_play"
	if runner_roll < 0.89:
		return "ground_out"
	return "strikeout"

func _apply_at_bat_result(result: String, current_bases: Array[bool], current_outs: int) -> Dictionary:
	var bases: Array[bool] = current_bases.duplicate()
	var outs: int = current_outs
	var runs_scored: int = 0
	var play_note: String = ""
	match result:
		"bunt_success":
			outs = mini(3, outs + 1)
			play_note = "送りバント成功"
			if bases[2] and outs < 3:
				runs_scored += 1
				bases[2] = false
				play_note = "スクイズ成功"
			var new_third_bunt: bool = bases[1]
			var new_second_bunt: bool = bases[0]
			bases = [false, new_second_bunt, new_third_bunt]
		"out", "strikeout":
			outs = mini(3, outs + 1)
			if result == "strikeout":
				play_note = "空振り三振"
		"fly_out":
			outs = mini(3, outs + 1)
			if outs < 3 and bases[2] and rng.randf() < 0.45:
				runs_scored += 1
				bases[2] = false
				play_note = "犠牲フライ"
		"ground_out":
			outs = mini(3, outs + 1)
			if outs < 3 and bases[2] and rng.randf() < 0.18:
				runs_scored += 1
				bases[2] = false
				play_note = "内野ゴロの間に生還"
			if outs < 3 and bases[0]:
				var runner_from_first_to_third: bool = bool(bases[1]) or rng.randf() < 0.35
				bases = [false, bases[1], runner_from_first_to_third]
		"double_play":
			if bases[0] and outs <= 1:
				outs = mini(3, outs + 2)
				bases[0] = false
				play_note = "併殺成立"
			else:
				outs = mini(3, outs + 1)
		"walk":
			if bases[0] and bases[1] and bases[2]:
				runs_scored += 1
				play_note = "押し出し"
			var new_third_walk: bool = bases[2]
			if bases[1] and bases[0]:
				new_third_walk = true
			var new_second_walk: bool = bases[1] or bases[0]
			bases = [true, new_second_walk, new_third_walk]
		"single":
			if bases[2]:
				runs_scored += 1
			if bases[1] and rng.randf() < 0.55:
				runs_scored += 1
				bases[1] = false
			var new_second: bool = false
			var new_third: bool = false
			if bases[1]:
				new_third = true
			if bases[0]:
				if rng.randf() < 0.55:
					new_third = true
				else:
					new_second = true
			bases = [true, new_second, new_third]
		"double":
			if bases[2]:
				runs_scored += 1
			if bases[1]:
				runs_scored += 1
			var runner_scores_from_first: bool = bases[0] and rng.randf() < 0.45
			if runner_scores_from_first:
				runs_scored += 1
			var runner_to_third: bool = bases[0] and not runner_scores_from_first
			bases = [false, true, runner_to_third]
		"triple":
			for occupied in bases:
				if bool(occupied):
					runs_scored += 1
			bases = [false, false, true]
		"home_run":
			for occupied in bases:
				if bool(occupied):
					runs_scored += 1
			runs_scored += 1
			bases = [false, false, false]
		_:
			outs = mini(3, outs + 1)

	return {
		"bases": bases,
		"outs": outs,
		"runs_scored": runs_scored,
		"outs_on_play": maxi(0, outs - current_outs),
		"play_note": play_note,
	}

func _get_at_bat_result_label(result: String) -> String:
	match result:
		"bunt_success":
			return "送りバント"
		"walk":
			return "四球"
		"single":
			return "単打"
		"double":
			return "二塁打"
		"triple":
			return "三塁打"
		"home_run":
			return "本塁打"
		"strikeout":
			return "三振"
		"fly_out":
			return "外野フライ"
		"ground_out":
			return "内野ゴロ"
		"double_play":
			return "併殺打"
		_:
			return "凡打"

func _distribute_runs_by_inning(total_runs: int) -> Array[int]:
	var innings: Array[int] = []
	for _inning in range(9):
		innings.append(0)

	var remaining_runs: int = total_runs
	while remaining_runs > 0:
		var target_inning: int = rng.randi_range(0, 8)
		innings[target_inning] += 1
		remaining_runs -= 1

	return innings

func _build_pitching_event_rows(plan: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for outing_value in plan:
		var outing: Dictionary = outing_value
		var pitcher = outing.get("pitcher", null)
		if pitcher == null:
			continue
		rows.append({
			"pitcher_id": str(pitcher.id),
			"pitcher_name": str(pitcher.full_name),
			"outs": int(outing.get("outs", 0)),
			"earned_runs": int(outing.get("er", 0)),
			"is_starter": bool(outing.get("gs", false)),
			"decision": str(outing.get("decision", "none")),
			"save": bool(outing.get("save", false)),
			"hold": bool(outing.get("hold", false)),
		})
	return rows

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

	return total / float(count) + _get_strategy_attack_bonus(team)

func _calc_handedness_bonus(batter, opposing_pitcher) -> float:
	if batter == null or opposing_pitcher == null:
		return 0.0

	var split_rating: float = float(batter.ratings.get("vs_left", 50))
	if str(opposing_pitcher.throws) == "L":
		return (split_rating - 50.0) * 0.08

	return 0.0

func _get_pitcher_hand_label(pitcher) -> String:
	if pitcher == null:
		return "陷ｿ・ｳ隰壼｢鍋・"

	if str(pitcher.throws) == "L":
		return "陝ｾ・ｦ隰壼｢鍋・"

	return "陷ｿ・ｳ隰壼｢鍋・"

func _get_strategy_log_label(strategy: String) -> String:
	match strategy:
		"power":
			return "強打"
		"speed":
			return "機動力"
		"defense":
			return "守備重視"
		"pitching":
			return "投手重視"
		_:
			return "標準"

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

func _get_strategy_attack_bonus(team) -> float:
	if team == null:
		return 0.0

	match str(team.strategy):
		"power":
			return 1.2
		"speed":
			return 0.8
		"defense":
			return -0.4
		"pitching":
			return -0.6
		_:
			return 0.0

func _get_strategy_pitch_bonus(team) -> float:
	if team == null:
		return 0.0

	match str(team.strategy):
		"defense":
			return 0.8
		"pitching":
			return 1.4
		"speed":
			return 0.2
		"power":
			return -0.2
		_:
			return 0.0

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
	return _calc_pitcher_defense_value(starter) + _get_strategy_pitch_bonus(team)

func get_team_total_strength(team) -> float:
	var attack_value: float = get_team_attack_value(team)
	var pitch_value: float = get_team_pitch_value(team)
	return attack_value * 0.55 + pitch_value * 0.45
