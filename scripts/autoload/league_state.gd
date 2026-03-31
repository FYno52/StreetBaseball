extends Node

const TEAM_DATA_SCRIPT = preload("res://scripts/data/team_data.gd")
const PLAYER_DATA_SCRIPT = preload("res://scripts/data/player_data.gd")
const GAME_DATA_SCRIPT = preload("res://scripts/data/game_data.gd")

var season_year: int = 1
var current_day: int = 1

# team_id -> TeamData
var teams: Dictionary = {}

# player_id -> PlayerData
var players: Dictionary = {}

# Array of GameData
var schedule: Array = []
var recent_events: Array[String] = []
var daily_team_bonuses: Dictionary = {}

var team_master: Array[Dictionary] = [
	{"id": "TKY", "name": "東京フェニックス"},
	{"id": "OSK", "name": "大阪ブレイバーズ"},
	{"id": "NGY", "name": "名古屋スティング"},
	{"id": "SPP", "name": "札幌ホワイトベアーズ"},
	{"id": "FKO", "name": "福岡サンダース"},
	{"id": "SDI", "name": "仙台フォックス"}
]

func reset() -> void:
	season_year = 1
	current_day = 1
	teams.clear()
	players.clear()
	schedule.clear()
	recent_events.clear()
	daily_team_bonuses.clear()

func new_game() -> void:
	reset()

	for team_info in team_master:
		var generated: Dictionary = PlayerFactory.generate_team_roster(str(team_info["id"]), str(team_info["name"]))
		var team = generated["team"]
		var roster: Array = generated["players"]

		teams[str(team.id)] = team

		for p in roster:
			players[str(p.id)] = p

	_generate_schedule()

func start_new_season() -> void:
	season_year += 1
	current_day = 1
	recent_events.clear()
	daily_team_bonuses.clear()

	for team_id in teams.keys():
		var team = teams[team_id]
		team.standings["wins"] = 0
		team.standings["losses"] = 0
		team.standings["draws"] = 0
		team.standings["runs_for"] = 0
		team.standings["runs_against"] = 0

	for player_id in players.keys():
		var player = players[player_id]
		player.reset_season_stats()

	_generate_schedule()

func _generate_schedule() -> void:
	schedule.clear()

	var ids: Array[String] = []
	for team_info in team_master:
		ids.append(str(team_info["id"]))

	var day: int = 1
	var game_index: int = 1

	# 各カード12試合（6 home / 6 away）の簡易日程
	for i in range(ids.size()):
		for j in range(i + 1, ids.size()):
			var a: String = ids[i]
			var b: String = ids[j]

			for k in range(6):
				var g1 = GAME_DATA_SCRIPT.new()
				g1.id = "G_%03d" % game_index
				g1.day = day
				g1.away_team_id = a
				g1.home_team_id = b
				schedule.append(g1)
				game_index += 1

				var g2 = GAME_DATA_SCRIPT.new()
				g2.id = "G_%03d" % game_index
				g2.day = day
				g2.away_team_id = b
				g2.home_team_id = a
				schedule.append(g2)
				game_index += 1

				day += 1

func get_team(team_id: String):
	if teams.has(team_id):
		return teams[team_id]
	return null

func get_player(player_id: String):
	if players.has(player_id):
		return players[player_id]
	return null

func get_games_for_day(day: int) -> Array:
	var result: Array = []

	for g in schedule:
		if int(g.day) == day:
			result.append(g)

	return result

func advance_day() -> void:
	current_day += 1

func all_team_ids() -> Array[String]:
	var result: Array[String] = []
	for key in teams.keys():
		result.append(str(key))
	return result

func simulate_current_day() -> Array:
	var games_today: Array = get_games_for_day(current_day)
	var event_pack: Dictionary = _generate_daily_events(current_day)
	recent_events = event_pack.get("texts", [])
	daily_team_bonuses = event_pack.get("bonuses", {})

	for game in games_today:
		var away_team = get_team(str(game.away_team_id))
		var home_team = get_team(str(game.home_team_id))
		SimulationEngine.simulate_game(game, away_team, home_team)

	return games_today

func get_recent_events() -> Array[String]:
	return recent_events.duplicate()

func get_team_event_bonus(team_id: String) -> Dictionary:
	if daily_team_bonuses.has(team_id):
		return daily_team_bonuses[team_id].duplicate(true)
	return {"attack": 0.0, "pitch": 0.0}

func _generate_daily_events(day: int) -> Dictionary:
	var events: Array[String] = []
	var bonuses: Dictionary = {}
	var rng := RandomNumberGenerator.new()
	rng.seed = int(season_year * 1000 + day * 37 + teams.size())

	var chance: float = rng.randf()
	if chance < 0.35:
		var event_1: Dictionary = _build_flavor_event(rng)
		events.append(_format_event_text(event_1))
		_apply_event_bonus(bonuses, event_1)
	if chance < 0.10:
		var event_2: Dictionary = _build_flavor_event(rng)
		events.append(_format_event_text(event_2))
		_apply_event_bonus(bonuses, event_2)

	if events.is_empty():
		events.append("[平穏] 今日は大きな事件なし。いつも通りリーグ戦が進む。")

	return {
		"texts": events,
		"bonuses": bonuses
	}

func _build_flavor_event(rng: RandomNumberGenerator) -> Dictionary:
	var team_ids: Array[String] = all_team_ids()
	if team_ids.is_empty():
		return {"text": "商店街のざわつきだけが残った。"}

	var team_id: String = team_ids[rng.randi_range(0, team_ids.size() - 1)]
	var team = get_team(team_id)
	var roster: Array = []
	if team != null:
		for player_id in team.player_ids:
			var player = get_player(str(player_id))
			if player != null:
				roster.append(player)

	var player_name: String = team.name if team != null else "名無しチーム"
	if not roster.is_empty():
		var picked_player = roster[rng.randi_range(0, roster.size() - 1)]
		player_name = picked_player.full_name

	var event_defs: Array[Dictionary] = [
		{"category": "朗報", "text": "%s が試合前に商店街でファンサービス。観客がいつもより集まっている。", "attack": 1.2, "pitch": 0.0, "fan_delta": 3, "budget_delta": 1200},
		{"category": "朗報", "text": "%s がバットを持って気合いの素振り。チーム全体の空気が少し熱い。", "attack": 1.6, "pitch": 0.0, "fan_delta": 1, "budget_delta": 0},
		{"category": "街の噂", "text": "%s のベンチで謎の円陣。内容は不明だが、妙に士気が高い。", "attack": 0.8, "pitch": 0.8, "fan_delta": 0, "budget_delta": 0},
		{"category": "街の噂", "text": "%s 周辺で屋台が盛り上がり、今日はいつもより賑やかな空気。", "attack": 0.5, "pitch": 0.5, "fan_delta": 2, "budget_delta": 800},
		{"category": "朗報", "text": "%s が『今日は見せ場を作る』と宣言。周囲が少しざわつく。", "attack": 1.4, "pitch": 0.0, "fan_delta": 1, "budget_delta": 0},
		{"category": "朗報", "text": "%s のメンバーが河川敷で早朝特訓。守りの動きがやけに締まっている。", "attack": 0.0, "pitch": 1.2, "fan_delta": 1, "budget_delta": 0},
		{"category": "朗報", "text": "%s が近所の子ども相手にキャッチボール教室。街の空気が少し味方している。", "attack": 0.4, "pitch": 0.6, "fan_delta": 4, "budget_delta": 1500},
		{"category": "街の噂", "text": "%s に差し入れの焼きそばパンが大量到着。ベンチの雰囲気が妙にいい。", "attack": 0.7, "pitch": 0.3, "fan_delta": 1, "budget_delta": 0},
		{"category": "朗報", "text": "%s のエースが無言でブルペン入り。周囲が勝手に引き締まっている。", "attack": 0.0, "pitch": 1.5, "fan_delta": 0, "budget_delta": 0},
		{"category": "朗報", "text": "%s の主砲がバッティングセンターで当てまくったらしい。打席前から妙な自信がある。", "attack": 1.8, "pitch": -0.1, "fan_delta": 1, "budget_delta": 0},
		{"category": "不穏", "text": "%s が遅刻寸前で滑り込み。周囲の視線がやや厳しい。", "attack": -0.4, "pitch": -0.2, "fan_delta": -2, "budget_delta": 0},
		{"category": "不穏", "text": "%s 周辺で小さな口論。空気が少しピリついている。", "attack": -0.6, "pitch": -0.6, "fan_delta": -1, "budget_delta": 0},
		{"category": "不穏", "text": "%s の用具がひとつ足りないまま集合。試合前の準備がややバタついている。", "attack": -0.5, "pitch": -0.4, "fan_delta": -1, "budget_delta": -500},
		{"category": "不穏", "text": "%s のベンチで誰かの説教が長引いたらしい。空気が少し重い。", "attack": -0.7, "pitch": -0.3, "fan_delta": -1, "budget_delta": 0},
		{"category": "街の噂", "text": "%s に臨時の差し入れ代が発生。財布は痛いが士気は少し上がっている。", "attack": 0.5, "pitch": 0.2, "fan_delta": 0, "budget_delta": -1200},
		{"category": "街の噂", "text": "%s の応援に地元の先輩たちが大挙して登場。良くも悪くも目立っている。", "attack": 1.0, "pitch": 0.4, "fan_delta": 2, "budget_delta": 600}
	]
	var event_def: Dictionary = event_defs[rng.randi_range(0, event_defs.size() - 1)]
	return {
		"text": str(event_def["text"]) % player_name,
		"team_id": team_id,
		"attack": float(event_def.get("attack", 0.0)),
		"pitch": float(event_def.get("pitch", 0.0)),
		"fan_delta": int(event_def.get("fan_delta", 0)),
		"budget_delta": int(event_def.get("budget_delta", 0))
	}

func _format_event_text(event_data: Dictionary) -> String:
	var category: String = str(event_data.get("category", "街の噂"))
	var text: String = str(event_data.get("text", ""))
	var fan_delta: int = int(event_data.get("fan_delta", 0))
	var budget_delta: int = int(event_data.get("budget_delta", 0))
	var suffix_parts: Array[String] = []

	if fan_delta > 0:
		suffix_parts.append("人気+%d" % fan_delta)
	elif fan_delta < 0:
		suffix_parts.append("人気%d" % fan_delta)

	if budget_delta > 0:
		suffix_parts.append("予算+%d" % budget_delta)
	elif budget_delta < 0:
		suffix_parts.append("予算%d" % budget_delta)

	if suffix_parts.is_empty():
		return "[%s] %s" % [category, text]

	return "[%s] %s (%s)" % [category, text, " / ".join(suffix_parts)]

func _apply_event_bonus(bonuses: Dictionary, event_data: Dictionary) -> void:
	var team_id: String = str(event_data.get("team_id", ""))
	if team_id == "":
		return

	if not bonuses.has(team_id):
		bonuses[team_id] = {"attack": 0.0, "pitch": 0.0}

	var current_bonus: Dictionary = bonuses[team_id]
	current_bonus["attack"] = float(current_bonus.get("attack", 0.0)) + float(event_data.get("attack", 0.0))
	current_bonus["pitch"] = float(current_bonus.get("pitch", 0.0)) + float(event_data.get("pitch", 0.0))
	bonuses[team_id] = current_bonus

	var team = get_team(team_id)
	if team != null:
		team.fan_support = clampi(int(team.fan_support) + int(event_data.get("fan_delta", 0)), 0, 100)
		team.budget = maxi(0, int(team.budget) + int(event_data.get("budget_delta", 0)))

func get_teams_sorted_by_win_pct() -> Array:
	var result: Array = []

	for team_id in all_team_ids():
		result.append(get_team(team_id))

	result.sort_custom(func(a, b):
		var a_pct: float = a.win_pct()
		var b_pct: float = b.win_pct()

		if a_pct == b_pct:
			return int(a.standings["wins"]) > int(b.standings["wins"])

		return a_pct > b_pct
	)

	return result
	
func get_last_day() -> int:
	var last_day: int = 1

	for game in schedule:
		if int(game.day) > last_day:
			last_day = int(game.day)

	return last_day

func simulate_to_end_of_season() -> void:
	var last_day: int = get_last_day()

	while current_day <= last_day:
		simulate_current_day()

		if current_day < last_day:
			advance_day()
		else:
			break

func to_save_dict() -> Dictionary:
	var team_dict: Dictionary = {}
	for team_id in teams.keys():
		team_dict[str(team_id)] = teams[team_id].to_dict()

	var player_dict: Dictionary = {}
	for player_id in players.keys():
		player_dict[str(player_id)] = players[player_id].to_dict()

	var schedule_list: Array = []
	for game in schedule:
		schedule_list.append(game.to_dict())

	return {
		"save_version": 1,
		"season_year": season_year,
		"current_day": current_day,
		"recent_events": recent_events.duplicate(),
		"daily_team_bonuses": daily_team_bonuses.duplicate(true),
		"teams": team_dict,
		"players": player_dict,
		"schedule": schedule_list
	}

func load_from_dict(data: Dictionary) -> void:
	season_year = int(data.get("season_year", 1))
	current_day = int(data.get("current_day", 1))
	recent_events.clear()
	for event_text in data.get("recent_events", []):
		recent_events.append(str(event_text))
	daily_team_bonuses = data.get("daily_team_bonuses", {}).duplicate(true)

	teams.clear()
	players.clear()
	schedule.clear()

	var raw_teams: Dictionary = data.get("teams", {})
	for team_id in raw_teams.keys():
		teams[str(team_id)] = TEAM_DATA_SCRIPT.from_dict(raw_teams[team_id])

	var raw_players: Dictionary = data.get("players", {})
	for player_id in raw_players.keys():
		players[str(player_id)] = PLAYER_DATA_SCRIPT.from_dict(raw_players[player_id])

	var raw_schedule: Array = data.get("schedule", [])
	for raw_game in raw_schedule:
		schedule.append(GAME_DATA_SCRIPT.from_dict(raw_game))

func save_to_file(path: String = "user://save_01.json") -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("save failed: " + path)
		return false

	file.store_string(JSON.stringify(to_save_dict(), "\t"))
	file.close()
	return true

func load_from_file(path: String = "user://save_01.json") -> bool:
	if not FileAccess.file_exists(path):
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("json parse failed")
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("save data is not a dictionary")
		return false

	load_from_dict(json.data)
	return true

func get_team_batters_sorted_by_avg(team_id: String) -> Array:
	var team = get_team(team_id)
	var result: Array = []

	if team == null:
		return result

	for player_id in team.lineup_vs_r:
		var player = get_player(str(player_id))
		if player != null and not player.is_pitcher():
			result.append(player)

	result.sort_custom(func(a, b):
		var a_avg: float = a.get_batting_average()
		var b_avg: float = b.get_batting_average()

		if is_equal_approx(a_avg, b_avg):
			return int(a.batting_stats["h"]) > int(b.batting_stats["h"])

		return a_avg > b_avg
	)

	return result

func get_league_batting_leaders(limit: int = 5) -> Dictionary:
	var batters: Array = []
	for player_id in players.keys():
		var player = players[player_id]
		if player == null or player.is_pitcher():
			continue
		batters.append(player)

	var avg_leaders: Array = batters.duplicate()
	avg_leaders.sort_custom(func(a, b):
		var a_avg: float = a.get_batting_average()
		var b_avg: float = b.get_batting_average()
		if is_equal_approx(a_avg, b_avg):
			return int(a.batting_stats["h"]) > int(b.batting_stats["h"])
		return a_avg > b_avg
	)

	var hr_leaders: Array = batters.duplicate()
	hr_leaders.sort_custom(func(a, b):
		if int(a.batting_stats["hr"]) == int(b.batting_stats["hr"]):
			return float(a.get_batting_average()) > float(b.get_batting_average())
		return int(a.batting_stats["hr"]) > int(b.batting_stats["hr"])
	)

	var rbi_leaders: Array = batters.duplicate()
	rbi_leaders.sort_custom(func(a, b):
		if int(a.batting_stats["rbi"]) == int(b.batting_stats["rbi"]):
			return int(a.batting_stats["h"]) > int(b.batting_stats["h"])
		return int(a.batting_stats["rbi"]) > int(b.batting_stats["rbi"])
	)

	return {
		"avg": avg_leaders.slice(0, mini(limit, avg_leaders.size())),
		"hr": hr_leaders.slice(0, mini(limit, hr_leaders.size())),
		"rbi": rbi_leaders.slice(0, mini(limit, rbi_leaders.size()))
	}

func get_league_pitching_leaders(limit: int = 5) -> Dictionary:
	var pitchers: Array = []
	for player_id in players.keys():
		var player = players[player_id]
		if player == null or not player.is_pitcher():
			continue
		pitchers.append(player)

	var win_leaders: Array = pitchers.duplicate()
	win_leaders.sort_custom(func(a, b):
		if int(a.pitching_stats["wins"]) == int(b.pitching_stats["wins"]):
			return int(a.pitching_stats["so"]) > int(b.pitching_stats["so"])
		return int(a.pitching_stats["wins"]) > int(b.pitching_stats["wins"])
	)

	var save_leaders: Array = pitchers.duplicate()
	save_leaders.sort_custom(func(a, b):
		if int(a.pitching_stats["saves"]) == int(b.pitching_stats["saves"]):
			return int(a.pitching_stats["holds"]) > int(b.pitching_stats["holds"])
		return int(a.pitching_stats["saves"]) > int(b.pitching_stats["saves"])
	)

	var era_candidates: Array = []
	for pitcher in pitchers:
		if int(pitcher.pitching_stats["outs"]) >= 9:
			era_candidates.append(pitcher)
	if era_candidates.is_empty():
		era_candidates = pitchers.duplicate()

	era_candidates.sort_custom(func(a, b):
		var a_era: float = a.get_era()
		var b_era: float = b.get_era()
		if is_equal_approx(a_era, b_era):
			return int(a.pitching_stats["outs"]) > int(b.pitching_stats["outs"])
		return a_era < b_era
	)

	return {
		"wins": win_leaders.slice(0, mini(limit, win_leaders.size())),
		"saves": save_leaders.slice(0, mini(limit, save_leaders.size())),
		"era": era_candidates.slice(0, mini(limit, era_candidates.size()))
	}
	
func get_team_pitchers_sorted_by_era(team_id: String) -> Array:
	var team = get_team(team_id)
	var result: Array = []

	if team == null:
		return result

	for player_id in team.rotation_ids:
		var player = get_player(str(player_id))
		if player != null and player.is_pitcher():
			result.append(player)

	result.sort_custom(func(a, b):
		var a_era: float = a.get_era()
		var b_era: float = b.get_era()

		if is_equal_approx(a_era, b_era):
			return int(a.pitching_stats["so"]) > int(b.pitching_stats["so"])

		return a_era < b_era
	)

	return result

func _ready() -> void:
	pass

func get_team_report(team_id: String) -> Dictionary:
	return {
		"team": get_team(team_id),
		"batters": get_team_batters_sorted_by_avg(team_id),
		"pitchers": get_team_pitchers_sorted_by_era(team_id)
	}

func get_league_team_summaries() -> Array:
	var result: Array = []
	var sorted_teams: Array = get_teams_sorted_by_win_pct()

	for team in sorted_teams:
		result.append({
			"id": team.id,
			"name": team.name,
			"wins": team.standings["wins"],
			"losses": team.standings["losses"],
			"draws": team.standings["draws"],
			"runs_for": team.standings["runs_for"],
			"runs_against": team.standings["runs_against"],
			"win_pct": team.win_pct(),
			"attack": SimulationEngine.get_team_attack_value(team),
			"pitch": SimulationEngine.get_team_pitch_value(team),
			"total": SimulationEngine.get_team_total_strength(team)
		})

	return result

func get_team_full_roster(team_id: String) -> Array:
	var team = get_team(team_id)
	var result: Array = []

	if team == null:
		return result

	for player_id in team.player_ids:
		var player = get_player(str(player_id))
		if player != null:
			result.append(player)

	result.sort_custom(func(a, b):
		if a.is_pitcher() != b.is_pitcher():
			return a.is_pitcher()

		if a.is_pitcher():
			if str(a.role) != str(b.role):
				var pitcher_order := {"starter": 0, "closer": 1, "reliever": 2}
				return int(pitcher_order.get(str(a.role), 99)) < int(pitcher_order.get(str(b.role), 99))

		if int(a.overall) == int(b.overall):
			return str(a.full_name) < str(b.full_name)

		return int(a.overall) > int(b.overall)
	)

	return result

func get_team_roster_groups(team_id: String) -> Dictionary:
	var team = get_team(team_id)

	var starters: Array = []
	var relievers: Array = []
	var fielders: Array = []

	if team == null:
		return {
			"starters": starters,
			"relievers": relievers,
			"fielders": fielders
		}

	for player_id in team.player_ids:
		var player = get_player(str(player_id))
		if player == null:
			continue

		if player.role == "starter":
			starters.append(player)
		elif player.is_pitcher():
			relievers.append(player)
		else:
			fielders.append(player)

	starters.sort_custom(func(a, b):
		if int(a.overall) == int(b.overall):
			return str(a.full_name) < str(b.full_name)
		return int(a.overall) > int(b.overall)
	)

	relievers.sort_custom(func(a, b):
		if int(a.overall) == int(b.overall):
			return str(a.full_name) < str(b.full_name)
		return int(a.overall) > int(b.overall)
	)

	fielders.sort_custom(func(a, b):
		if int(a.overall) == int(b.overall):
			return str(a.full_name) < str(b.full_name)
		return int(a.overall) > int(b.overall)
	)

	return {
		"starters": starters,
		"relievers": relievers,
		"fielders": fielders
	}

func get_team_lineup_and_bench(team_id: String) -> Dictionary:
	var team = get_team(team_id)

	var lineup: Array = []
	var bench: Array = []

	if team == null:
		return {
			"lineup": lineup,
			"bench": bench
		}

	for player_id in team.lineup_vs_r:
		var player = get_player(str(player_id))
		if player != null:
			lineup.append(player)

	for player_id in team.bench_ids:
		var player = get_player(str(player_id))
		if player != null:
			bench.append(player)

	bench.sort_custom(func(a, b):
		if int(a.overall) == int(b.overall):
			return str(a.full_name) < str(b.full_name)
		return int(a.overall) > int(b.overall)
	)

	return {
		"lineup": lineup,
		"bench": bench
	}

func get_team_rotation(team_id: String) -> Array:
	var team = get_team(team_id)
	var result: Array = []

	if team == null:
		return result

	for player_id in team.rotation_ids:
		var player = get_player(str(player_id))
		if player != null:
			result.append(player)

	return result

func get_team_bullpen(team_id: String) -> Dictionary:
	var team = get_team(team_id)

	var closer = null
	var setup: Array = []
	var middle: Array = []
	var long_reliever = null

	if team == null:
		return {
			"closer": closer,
			"setup": setup,
			"middle": middle,
			"long": long_reliever
		}

	if str(team.bullpen["closer"]) != "":
		closer = get_player(str(team.bullpen["closer"]))

	for player_id in team.bullpen["setup"]:
		var player = get_player(str(player_id))
		if player != null:
			setup.append(player)

	for player_id in team.bullpen["middle"]:
		var player = get_player(str(player_id))
		if player != null:
			middle.append(player)

	if str(team.bullpen["long"]) != "":
		long_reliever = get_player(str(team.bullpen["long"]))

	return {
		"closer": closer,
		"setup": setup,
		"middle": middle,
		"long": long_reliever
	}

func normalize_team_bullpen(team) -> void:
	if team == null:
		return

	var relief_ids: Array[String] = []
	for player_id in team.player_ids:
		var player = get_player(str(player_id))
		if player == null:
			continue
		if str(player.role) == "reliever" or str(player.role) == "closer":
			if not relief_ids.has(str(player.id)):
				relief_ids.append(str(player.id))

	var closer_id: String = str(team.bullpen.get("closer", ""))
	if closer_id != "" and not relief_ids.has(closer_id):
		closer_id = ""

	var long_id: String = str(team.bullpen.get("long", ""))
	if long_id != "" and (not relief_ids.has(long_id) or long_id == closer_id):
		long_id = ""

	var setup_ids: Array[String] = []
	for player_id in team.bullpen.get("setup", []):
		var resolved_id: String = str(player_id)
		if resolved_id == "" or resolved_id == closer_id or resolved_id == long_id:
			continue
		if not relief_ids.has(resolved_id):
			continue
		if setup_ids.has(resolved_id):
			continue
		if setup_ids.size() < 2:
			setup_ids.append(resolved_id)

	var middle_ids: Array[String] = []
	for player_id in team.bullpen.get("middle", []):
		var resolved_id: String = str(player_id)
		if resolved_id == "" or resolved_id == closer_id or resolved_id == long_id:
			continue
		if setup_ids.has(resolved_id):
			continue
		if not relief_ids.has(resolved_id):
			continue
		if middle_ids.has(resolved_id):
			continue
		middle_ids.append(resolved_id)

	for relief_id in relief_ids:
		if relief_id == closer_id or relief_id == long_id:
			continue
		if setup_ids.has(relief_id) or middle_ids.has(relief_id):
			continue
		middle_ids.append(relief_id)

	team.bullpen["closer"] = closer_id
	team.bullpen["long"] = long_id
	team.bullpen["setup"] = setup_ids
	team.bullpen["middle"] = middle_ids

func auto_assign_team_bullpen(team) -> void:
	if team == null:
		return

	var closers: Array = []
	var relievers: Array = []
	for player_id in team.player_ids:
		var player = get_player(str(player_id))
		if player == null:
			continue
		if str(player.role) == "closer":
			closers.append(player)
		elif str(player.role) == "reliever":
			relievers.append(player)

	closers.sort_custom(func(a, b):
		return int(a.overall) > int(b.overall)
	)
	relievers.sort_custom(func(a, b):
		return int(a.overall) > int(b.overall)
	)

	team.bullpen["closer"] = ""
	team.bullpen["setup"] = []
	team.bullpen["middle"] = []
	team.bullpen["long"] = ""

	if not closers.is_empty():
		team.bullpen["closer"] = str(closers[0].id)
	elif not relievers.is_empty():
		team.bullpen["closer"] = str(relievers[0].id)

	var remaining_ids: Array[String] = []
	for pitcher in relievers:
		var pitcher_id: String = str(pitcher.id)
		if pitcher_id != str(team.bullpen["closer"]):
			remaining_ids.append(pitcher_id)

	for i in range(mini(2, remaining_ids.size())):
		team.bullpen["setup"].append(remaining_ids[i])

	for i in range(2, remaining_ids.size()):
		team.bullpen["middle"].append(remaining_ids[i])

	if not team.bullpen["middle"].is_empty():
		team.bullpen["long"] = str(team.bullpen["middle"][team.bullpen["middle"].size() - 1])

	normalize_team_bullpen(team)

func get_starting_pitcher_for_day(team_id: String, day: int):
	var team = get_team(team_id)

	if team == null:
		return null

	if team.rotation_ids.is_empty():
		return null

	var rotation_index: int = (day - 1) % team.rotation_ids.size()
	var pitcher_id: String = str(team.rotation_ids[rotation_index])

	return get_player(pitcher_id)
