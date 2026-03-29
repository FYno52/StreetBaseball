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

	for game in games_today:
		var away_team = get_team(str(game.away_team_id))
		var home_team = get_team(str(game.home_team_id))
		SimulationEngine.simulate_game(game, away_team, home_team)

	return games_today

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
		"teams": team_dict,
		"players": player_dict,
		"schedule": schedule_list
	}

func load_from_dict(data: Dictionary) -> void:
	season_year = int(data.get("season_year", 1))
	current_day = int(data.get("current_day", 1))

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

func get_starting_pitcher_for_day(team_id: String, day: int):
	var team = get_team(team_id)

	if team == null:
		return null

	if team.rotation_ids.is_empty():
		return null

	var rotation_index: int = (day - 1) % team.rotation_ids.size()
	var pitcher_id: String = str(team.rotation_ids[rotation_index])

	return get_player(pitcher_id)
