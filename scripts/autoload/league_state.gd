extends Node

const TEAM_DATA_SCRIPT = preload("res://scripts/data/team_data.gd")
const PLAYER_DATA_SCRIPT = preload("res://scripts/data/player_data.gd")
const GAME_DATA_SCRIPT = preload("res://scripts/data/game_data.gd")
const TEAM_BLUEPRINTS_SCRIPT = preload("res://scripts/data/team_blueprints.gd")
const OPENING_DATA_SCRIPT = preload("res://scripts/data/npb_inspired_opening_data.gd")
const FIXED_ROSTER_BUILDER_SCRIPT = preload("res://scripts/autoload/fixed_roster_builder.gd")
const START_SEASON_YEAR := 2026
const CALENDAR_START_MONTH := 1
const CALENDAR_START_DAY := 1
const SEASON_START_MONTH := 3
const SEASON_START_DAY := 27
const SPRING_CAMP_START_MONTH := 2
const SPRING_CAMP_START_DAY := 1
const SPRING_CAMP_END_MONTH := 2
const SPRING_CAMP_END_DAY := 28
const OPEN_GAME_START_MONTH := 3
const OPEN_GAME_START_DAY := 1
const OPEN_GAME_END_MONTH := 3
const OPEN_GAME_END_DAY := 26
const INTERLEAGUE_START_MONTH := 5
const INTERLEAGUE_START_DAY := 26
const INTERLEAGUE_END_MONTH := 6
const INTERLEAGUE_END_DAY := 14
const CLIMAX_FIRST_START_MONTH := 10
const CLIMAX_FIRST_START_DAY := 10
const CLIMAX_FIRST_END_MONTH := 10
const CLIMAX_FIRST_END_DAY := 12
const CLIMAX_FINAL_START_MONTH := 10
const CLIMAX_FINAL_START_DAY := 14
const CLIMAX_FINAL_END_MONTH := 10
const CLIMAX_FINAL_END_DAY := 19
const JAPAN_SERIES_START_MONTH := 10
const JAPAN_SERIES_START_DAY := 24
const JAPAN_SERIES_END_MONTH := 11
const JAPAN_SERIES_END_DAY := 1
const DRAFT_PREP_START_MONTH := 10
const DRAFT_PREP_START_DAY := 20
const DRAFT_PREP_END_MONTH := 10
const DRAFT_PREP_END_DAY := 26
const DRAFT_DAY_MONTH := 10
const DRAFT_DAY_DAY := 27
const CONTRACT_PERIOD_START_MONTH := 11
const CONTRACT_PERIOD_START_DAY := 1
const CONTRACT_PERIOD_END_MONTH := 11
const CONTRACT_PERIOD_END_DAY := 30
const FA_PERIOD_START_MONTH := 11
const FA_PERIOD_START_DAY := 15
const FA_PERIOD_END_MONTH := 11
const FA_PERIOD_END_DAY := 30
const SPONSOR_PERIOD_START_MONTH := 12
const SPONSOR_PERIOD_START_DAY := 1
const SPONSOR_PERIOD_END_MONTH := 12
const SPONSOR_PERIOD_END_DAY := 20
const STAFF_REVIEW_START_MONTH := 1
const STAFF_REVIEW_START_DAY := 10
const STAFF_REVIEW_END_MONTH := 1
const STAFF_REVIEW_END_DAY := 31
const REGULAR_SERIES_CYCLE_COUNT := 9
const EXTRA_SINGLE_GAME_CYCLE_COUNT := 1
const WEEKDAY_NAMES := ["日", "月", "火", "水", "木", "金", "土"]
const DESIRED_FIELDER_SLOTS: Array[String] = ["C", "C", "1B", "1B", "2B", "2B", "3B", "3B", "SS", "SS", "LF", "CF", "RF", "DH", "UT"]

var season_year: int = START_SEASON_YEAR
var current_day: int = 1
var controlled_team_id: String = ""
var selected_player_id: String = ""
var selected_game_id: String = ""
var selected_match_mode: String = "replay"
var active_live_game_id: String = ""

# team_id -> TeamData
var teams: Dictionary = {}

# player_id -> PlayerData
var players: Dictionary = {}

# Array of GameData
var schedule: Array = []
var recent_events: Array[String] = []
var daily_team_bonuses: Dictionary = {}
var last_offseason_report: Array[String] = []
var recent_finance_log: Array[String] = []
var last_controlled_team_roster_log: Array[String] = []
var latest_integrity_notes: Array[String] = []
var season_history: Array[Dictionary] = []
var annual_operation_status: Dictionary = {}
var annual_operation_log: Dictionary = {}
var prepared_day: int = 0
var finalized_finance_day: int = 0
var pending_home_message: String = ""

var team_master: Array[Dictionary] = OPENING_DATA_SCRIPT.get_team_blueprints()

func reset() -> void:
	season_year = START_SEASON_YEAR
	current_day = 1
	controlled_team_id = ""
	selected_player_id = ""
	selected_game_id = ""
	selected_match_mode = "replay"
	active_live_game_id = ""
	teams.clear()
	players.clear()
	schedule.clear()
	recent_events.clear()
	daily_team_bonuses.clear()
	last_offseason_report.clear()
	recent_finance_log.clear()
	last_controlled_team_roster_log.clear()
	latest_integrity_notes.clear()
	season_history.clear()
	annual_operation_status.clear()
	annual_operation_log.clear()
	prepared_day = 0
	finalized_finance_day = 0
	pending_home_message = ""

func new_game() -> void:
	reset()
	team_master = OPENING_DATA_SCRIPT.get_team_blueprints()
	var roster_builder = FIXED_ROSTER_BUILDER_SCRIPT.new()

	for team_info in team_master:
		var generated: Dictionary = roster_builder.build_opening_team(team_info)
		var team = generated["team"]
		var roster: Array = generated["players"]

		teams[str(team.id)] = team

		for p in roster:
			players[str(p.id)] = p

	_normalize_all_teams()
	_generate_schedule()
	_normalize_schedule_metadata()

func start_new_season() -> Array[String]:
	var previous_year: int = season_year
	_archive_current_season(previous_year)
	season_year += 1
	current_day = 1
	recent_events.clear()
	daily_team_bonuses.clear()
	last_offseason_report = _run_offseason(previous_year, season_year)
	recent_finance_log.clear()
	prepared_day = 0
	finalized_finance_day = 0
	pending_home_message = ""
	selected_game_id = ""
	selected_match_mode = "replay"
	active_live_game_id = ""

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

	_normalize_all_teams()
	_generate_schedule()
	_normalize_schedule_metadata()
	return last_offseason_report.duplicate()

func set_controlled_team(team_id: String) -> void:
	if team_id == "":
		return
	if not teams.has(team_id):
		return
	controlled_team_id = team_id

func set_selected_player(player_id: String) -> void:
	selected_player_id = player_id

func get_selected_player() -> PlayerData:
	if selected_player_id == "":
		return null
	return get_player(selected_player_id)

func set_selected_game(game_id: String) -> void:
	selected_game_id = game_id

func set_selected_match_mode(match_mode: String) -> void:
	selected_match_mode = match_mode

func get_selected_match_mode() -> String:
	return selected_match_mode

func set_active_live_game(game_id: String) -> void:
	active_live_game_id = game_id

func clear_active_live_game() -> void:
	active_live_game_id = ""

func is_active_live_game(game_id: String) -> bool:
	if game_id == "":
		return false
	return active_live_game_id == game_id

func get_selected_game():
	if selected_game_id == "":
		return null
	for game_value in schedule:
		var game: GameData = game_value
		if game != null and str(game.id) == selected_game_id:
			return game
	return null

func get_controlled_team() -> TeamData:
	if controlled_team_id == "":
		return null
	return get_team(controlled_team_id)

func get_roster_ruleset() -> Dictionary:
	return TEAM_BLUEPRINTS_SCRIPT.get_ruleset()

func get_team_registered_player_count(team_id: String) -> int:
	var team: TeamData = get_team(team_id)
	if team == null:
		return 0
	return team.player_ids.size()

func get_team_foreign_player_ids(team_id: String) -> Array[String]:
	var result: Array[String] = []
	var team: TeamData = get_team(team_id)
	if team == null:
		return result
	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player != null and bool(player.is_foreign):
			result.append(str(player.id))
	return result

func get_team_active_player_ids(team_id: String) -> Array[String]:
	var team: TeamData = get_team(team_id)
	var active_ids: Array[String] = []
	if team == null:
		return active_ids

	var seen: Dictionary = {}
	for player_id in team.lineup_vs_r:
		_append_unique_player_id(active_ids, seen, str(player_id))
	for player_id in team.lineup_vs_l:
		_append_unique_player_id(active_ids, seen, str(player_id))
	for player_id in team.bench_ids:
		_append_unique_player_id(active_ids, seen, str(player_id))
	for player_id in team.rotation_ids:
		_append_unique_player_id(active_ids, seen, str(player_id))

	_append_unique_player_id(active_ids, seen, str(team.bullpen.get("closer", "")))
	_append_unique_player_id(active_ids, seen, str(team.bullpen.get("long", "")))
	for player_id in team.bullpen.get("setup", []):
		_append_unique_player_id(active_ids, seen, str(player_id))
	for player_id in team.bullpen.get("middle", []):
		_append_unique_player_id(active_ids, seen, str(player_id))

	return active_ids

func get_team_roster_rule_summary(team_id: String) -> Dictionary:
	var rules: Dictionary = get_roster_ruleset()
	var team: TeamData = get_team(team_id)
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

	var registered_count: int = get_team_registered_player_count(team_id)
	var active_ids: Array[String] = get_team_active_player_ids(team_id)
	var foreign_signed_ids: Array[String] = get_team_foreign_player_ids(team_id)
	var foreign_active: int = 0
	var foreign_active_pitchers: int = 0
	var foreign_active_fielders: int = 0
	for player_id in active_ids:
		var player: PlayerData = get_player(str(player_id))
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

func get_controlled_team_player_management_summary() -> Dictionary:
	var team: TeamData = get_controlled_team()
	if team == null:
		return {}

	var active_count: int = 0
	var farm_count: int = 0
	var development_count: int = 0
	var foreign_active_count: int = 0
	var foreign_signed_count: int = 0

	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
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

	var roster_rule_summary: Dictionary = get_team_roster_rule_summary(str(team.id))
	return {
		"team_name": team.name,
		"active_count": active_count,
		"farm_count": farm_count,
		"development_count": development_count,
		"foreign_signed_count": foreign_signed_count,
		"foreign_active_count": foreign_active_count,
		"roster_rule_summary": roster_rule_summary
	}

func set_controlled_player_roster_status(player_id: String, target_status: String) -> Dictionary:
	var team: TeamData = get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が未設定です。"}

	var player: PlayerData = get_player(player_id)
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

	player.roster_status = normalized_status
	var status_label: String = "一軍" if normalized_status == "active" else "二軍"
	return {"ok": true, "message": "%s を%sに設定しました。" % [player.full_name, status_label]}

func promote_controlled_development_player(player_id: String) -> Dictionary:
	var team: TeamData = get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が未設定です。"}

	var player: PlayerData = get_player(player_id)
	if player == null or not team.player_ids.has(player_id):
		return {"ok": false, "message": "担当球団の選手ではありません。"}
	if str(player.registration_type) != "development":
		return {"ok": false, "message": "この選手はすでに支配下です。"}

	var rules: Dictionary = get_roster_ruleset()
	var registered_count: int = get_team_registered_player_count(str(team.id))
	var registered_max: int = int(rules.get("registered_roster_max", 70))
	if registered_count >= registered_max:
		return {"ok": false, "message": "支配下上限に達しているため昇格できません。"}

	player.registration_type = "registered"
	player.roster_status = "farm"
	return {"ok": true, "message": "%s を支配下登録しました。" % player.full_name}

func _append_unique_player_id(target: Array[String], seen: Dictionary, player_id: String) -> void:
	if player_id == "" or seen.has(player_id):
		return
	seen[player_id] = true
	target.append(player_id)

func set_pending_home_message(message: String) -> void:
	pending_home_message = message

func consume_pending_home_message() -> String:
	var message: String = pending_home_message
	pending_home_message = ""
	return message

func _generate_schedule() -> void:
	schedule.clear()

	var ids: Array[String] = []
	for team_info in team_master:
		ids.append(str(team_info["id"]))

	var schedule_blocks: Array = _build_schedule_blocks(ids)
	var series_date_blocks: Array = _build_series_date_blocks(schedule_blocks)
	var game_index: int = 1

	for round_index in range(schedule_blocks.size()):
		var block_data: Dictionary = schedule_blocks[round_index]
		var pairings: Array = block_data.get("pairings", [])
		var date_block: Array = series_date_blocks[round_index]
		for slot in date_block:
			var calendar_day: int = _calc_calendar_day_span(
				season_year,
				CALENDAR_START_MONTH,
				CALENDAR_START_DAY,
				int(slot["year"]),
				int(slot["month"]),
				int(slot["day"])
			) + 1
			for pairing in pairings:
				var game: GameData = GAME_DATA_SCRIPT.new()
				game.id = "G_%03d" % game_index
				game.day = calendar_day
				game.season_year = int(slot["year"])
				game.month = int(slot["month"])
				game.day_of_month = int(slot["day"])
				game.weekday_index = int(slot["weekday_index"])
				game.weekday_name = str(slot["weekday_name"])
				game.date_label = str(slot["date_label"])
				game.away_team_id = str(pairing["away_team_id"])
				game.home_team_id = str(pairing["home_team_id"])
				schedule.append(game)
				game_index += 1

func _build_schedule_blocks(team_ids: Array[String]) -> Array:
	var blocks: Array = []
	if team_ids.size() < 2:
		return blocks

	var league_groups: Dictionary = {}
	for team_info in team_master:
		var league_key: String = str(team_info.get("league", ""))
		if not league_groups.has(league_key):
			league_groups[league_key] = []
		league_groups[league_key].append(str(team_info.get("id", "")))

	var league_keys: Array[String] = []
	for league_key in league_groups.keys():
		league_keys.append(str(league_key))
	league_keys.sort()

	for cycle in range(7):
		for league_key in league_keys:
			var league_team_ids: Array[String] = []
			for team_id in league_groups[league_key]:
				league_team_ids.append(str(team_id))
			var base_rounds: Array = _build_round_robin_rounds(league_team_ids)
			for base_round in base_rounds:
				var pairings: Array = []
				for matchup in base_round:
					var home_team_id: String = str(matchup["home_team_id"])
					var away_team_id: String = str(matchup["away_team_id"])
					if cycle % 2 == 1:
						var temp_id: String = home_team_id
						home_team_id = away_team_id
						away_team_id = temp_id
					pairings.append({
						"home_team_id": home_team_id,
						"away_team_id": away_team_id
					})
				blocks.append({
					"games_per_matchup": 3,
					"pairings": pairings,
					"block_type": "league"
				})

	if league_keys.size() >= 2:
		var first_league_ids: Array[String] = []
		for team_id in league_groups[league_keys[0]]:
			first_league_ids.append(str(team_id))
		var second_league_ids: Array[String] = []
		for team_id in league_groups[league_keys[1]]:
			second_league_ids.append(str(team_id))
		var interleague_rounds: Array = _build_interleague_rounds(first_league_ids, second_league_ids)
		for cycle in range(2):
			for inter_round in interleague_rounds:
				var pairings: Array = []
				for matchup in inter_round:
					var home_team_id: String = str(matchup["home_team_id"])
					var away_team_id: String = str(matchup["away_team_id"])
					if cycle % 2 == 1:
						var temp_id: String = home_team_id
						home_team_id = away_team_id
						away_team_id = temp_id
					pairings.append({
						"home_team_id": home_team_id,
						"away_team_id": away_team_id
					})
				blocks.append({
					"games_per_matchup": 3,
					"pairings": pairings,
					"block_type": "interleague"
				})

	return blocks

func _build_interleague_rounds(first_league_ids: Array[String], second_league_ids: Array[String]) -> Array:
	var rounds: Array = []
	if first_league_ids.is_empty() or second_league_ids.is_empty():
		return rounds
	var left: Array[String] = first_league_ids.duplicate()
	var right: Array[String] = second_league_ids.duplicate()
	var round_count: int = mini(left.size(), right.size())
	for _round_index in range(round_count):
		var pairings: Array = []
		for i in range(mini(left.size(), right.size())):
			pairings.append({
				"home_team_id": left[i],
				"away_team_id": right[i]
			})
		rounds.append(pairings)
		if right.size() > 1:
			right.push_front(right.pop_back())
	return rounds

func _build_round_robin_rounds(team_ids: Array[String]) -> Array:
	var rounds: Array = []
	var rotation: Array[String] = team_ids.duplicate()
	if rotation.size() % 2 == 1:
		rotation.append("BYE")

	var round_count: int = rotation.size() - 1
	var half: int = rotation.size() / 2
	for round_index in range(round_count):
		var pairings: Array = []
		for i in range(half):
			var left_id: String = rotation[i]
			var right_id: String = rotation[rotation.size() - 1 - i]
			if left_id == "BYE" or right_id == "BYE":
				continue
			var home_team_id: String = left_id
			var away_team_id: String = right_id
			if round_index % 2 == 1:
				home_team_id = right_id
				away_team_id = left_id
			pairings.append({
				"home_team_id": home_team_id,
				"away_team_id": away_team_id
			})
		rounds.append(pairings)

		var fixed_team: String = rotation[0]
		var moving: Array[String] = []
		for index in range(1, rotation.size()):
			moving.append(rotation[index])
		moving.push_front(moving.pop_back())
		rotation.clear()
		rotation.append(fixed_team)
		for team_id in moving:
			rotation.append(team_id)

	return rounds

func _build_series_date_blocks(schedule_blocks: Array) -> Array:
	var result: Array = []
	var year: int = season_year
	var month: int = SEASON_START_MONTH
	var day_of_month: int = SEASON_START_DAY

	for block_data in schedule_blocks:
		var games_per_matchup: int = int(block_data.get("games_per_matchup", 3))
		var block: Array = []

		if games_per_matchup >= 3:
			while true:
				var weekday_index: int = _get_weekday_index(year, month, day_of_month)
				if weekday_index == 2 or weekday_index == 5:
					break
				var next_regular_date: Dictionary = _advance_date(year, month, day_of_month)
				year = int(next_regular_date["year"])
				month = int(next_regular_date["month"])
				day_of_month = int(next_regular_date["day"])
		else:
			while true:
				var single_weekday_index: int = _get_weekday_index(year, month, day_of_month)
				if single_weekday_index != 1:
					break
				var next_single_date: Dictionary = _advance_date(year, month, day_of_month)
				year = int(next_single_date["year"])
				month = int(next_single_date["month"])
				day_of_month = int(next_single_date["day"])

		var block_year: int = year
		var block_month: int = month
		var block_day: int = day_of_month
		for _index in range(games_per_matchup):
			var block_weekday: int = _get_weekday_index(block_year, block_month, block_day)
			block.append({
				"year": block_year,
				"month": block_month,
				"day": block_day,
				"weekday_index": block_weekday,
				"weekday_name": WEEKDAY_NAMES[block_weekday],
				"date_label": _build_date_label(block_year, block_month, block_day, block_weekday)
			})
			var next_date: Dictionary = _advance_date(block_year, block_month, block_day)
			block_year = int(next_date["year"])
			block_month = int(next_date["month"])
			block_day = int(next_date["day"])

		result.append(block)
		year = block_year
		month = block_month
		day_of_month = block_day

	return result

func _build_date_label(year: int, month: int, day_of_month: int, weekday_index: int) -> String:
	return "%04d-%02d-%02d(%s)" % [year, month, day_of_month, WEEKDAY_NAMES[weekday_index]]

func _advance_date(year: int, month: int, day_of_month: int) -> Dictionary:
	var next_year: int = year
	var next_month: int = month
	var next_day: int = day_of_month + 1
	if next_day > _get_days_in_month(next_year, next_month):
		next_day = 1
		next_month += 1
		if next_month > 12:
			next_month = 1
			next_year += 1
	return {
		"year": next_year,
		"month": next_month,
		"day": next_day
	}

func _get_days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if _is_leap_year(year) else 28
		_:
			return 30

func _is_leap_year(year: int) -> bool:
	if year % 400 == 0:
		return true
	if year % 100 == 0:
		return false
	return year % 4 == 0

func _get_weekday_index(year: int, month: int, day_of_month: int) -> int:
	var month_offsets: Array[int] = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
	var y: int = year
	if month < 3:
		y -= 1
	return int((y + y / 4 - y / 100 + y / 400 + month_offsets[month - 1] + day_of_month) % 7)

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

func get_next_game_day(from_day: int, team_id: String = "") -> int:
	var start_day: int = maxi(1, from_day)
	for day in range(start_day, get_last_day() + 1):
		var games: Array = get_games_for_day(day)
		if games.is_empty():
			continue
		if team_id == "":
			return day
		for game in games:
			if str(game.away_team_id) == team_id or str(game.home_team_id) == team_id:
				return day
	return -1

func get_date_label_for_day(day: int) -> String:
	return str(get_date_info_for_day(day).get("date_label", ""))

func get_date_info_for_day(day: int) -> Dictionary:
	var target_day: int = maxi(1, day)
	var year: int = season_year
	var month: int = CALENDAR_START_MONTH
	var day_of_month: int = CALENDAR_START_DAY

	for _index in range(target_day - 1):
		var next_date: Dictionary = _advance_date(year, month, day_of_month)
		year = int(next_date["year"])
		month = int(next_date["month"])
		day_of_month = int(next_date["day"])

	var weekday_index: int = _get_weekday_index(year, month, day_of_month)
	return {
		"year": year,
		"month": month,
		"day": day_of_month,
		"weekday_index": weekday_index,
		"weekday_name": WEEKDAY_NAMES[weekday_index],
		"date_label": _build_date_label(year, month, day_of_month, weekday_index)
	}

func _normalize_schedule_metadata() -> void:
	for game_value in schedule:
		var game: GameData = game_value
		if game == null:
			continue
		var date_info: Dictionary = get_date_info_for_day(int(game.day))
		game.season_year = int(date_info.get("year", season_year))
		game.month = int(date_info.get("month", CALENDAR_START_MONTH))
		game.day_of_month = int(date_info.get("day", CALENDAR_START_DAY))
		game.weekday_index = int(date_info.get("weekday_index", 0))
		game.weekday_name = str(date_info.get("weekday_name", ""))
		game.date_label = str(date_info.get("date_label", ""))

func get_current_date_label() -> String:
	return get_date_label_for_day(current_day)

func get_calendar_events_for_day(day: int) -> Array[Dictionary]:
	var date_info: Dictionary = get_date_info_for_day(day)
	var month: int = int(date_info.get("month", 1))
	var day_of_month: int = int(date_info.get("day", 1))
	var events: Array[Dictionary] = []

	if _is_date_in_range(month, day_of_month, SPRING_CAMP_START_MONTH, SPRING_CAMP_START_DAY, SPRING_CAMP_END_MONTH, SPRING_CAMP_END_DAY):
		events.append({
			"type": "spring_camp",
			"label": "春季キャンプ",
			"summary": "若手育成と調整を進める時期です。施設とスタッフ効果が出やすくなります。"
		})
	if _is_date_in_range(month, day_of_month, OPEN_GAME_START_MONTH, OPEN_GAME_START_DAY, OPEN_GAME_END_MONTH, OPEN_GAME_END_DAY):
		events.append({
			"type": "open_games",
			"label": "オープン戦期間",
			"summary": "開幕前の調整期間です。打線やローテの確認に向いています。"
		})
	if month == SEASON_START_MONTH and day_of_month == SEASON_START_DAY:
		events.append({
			"type": "opening_day",
			"label": "開幕日",
			"summary": "公式戦が開幕します。ここからシーズン本番です。"
		})
	if _is_date_in_range(month, day_of_month, INTERLEAGUE_START_MONTH, INTERLEAGUE_START_DAY, INTERLEAGUE_END_MONTH, INTERLEAGUE_END_DAY):
		events.append({
			"type": "interleague_period",
			"label": "交流戦",
			"summary": "他リーグとの交流戦期間です。普段と違う相手との連戦が続きます。"
		})
	if _is_date_in_range(month, day_of_month, CLIMAX_FIRST_START_MONTH, CLIMAX_FIRST_START_DAY, CLIMAX_FIRST_END_MONTH, CLIMAX_FIRST_END_DAY):
		events.append({
			"type": "climax_first_stage",
			"label": "クライマックス・ファースト",
			"summary": "各リーグ2位と3位が戦う短期決戦の期間です。"
		})
	if _is_date_in_range(month, day_of_month, CLIMAX_FINAL_START_MONTH, CLIMAX_FINAL_START_DAY, CLIMAX_FINAL_END_MONTH, CLIMAX_FINAL_END_DAY):
		events.append({
			"type": "climax_final_stage",
			"label": "クライマックス・ファイナル",
			"summary": "各リーグ1位が待つ最終ステージです。日本シリーズ進出を争います。"
		})
	if _is_date_in_range(month, day_of_month, JAPAN_SERIES_START_MONTH, JAPAN_SERIES_START_DAY, JAPAN_SERIES_END_MONTH, JAPAN_SERIES_END_DAY):
		events.append({
			"type": "japan_series",
			"label": "日本シリーズ",
			"summary": "両リーグ優勝代表が日本一を争う決戦期間です。"
		})
	if _is_date_in_range(month, day_of_month, DRAFT_PREP_START_MONTH, DRAFT_PREP_START_DAY, DRAFT_PREP_END_MONTH, DRAFT_PREP_END_DAY):
		events.append({
			"type": "draft_prep",
			"label": "ドラフト準備期間",
			"summary": "スカウト候補を整理して、注目選手を絞り込む時期です。"
		})
	if month == DRAFT_DAY_MONTH and day_of_month == DRAFT_DAY_DAY:
		events.append({
			"type": "draft_day",
			"label": "ドラフト会議",
			"summary": "新人指名を行う日です。スカウト成果を反映する本番です。"
		})
	if _is_date_in_range(month, day_of_month, CONTRACT_PERIOD_START_MONTH, CONTRACT_PERIOD_START_DAY, CONTRACT_PERIOD_END_MONTH, CONTRACT_PERIOD_END_DAY):
		events.append({
			"type": "contract_period",
			"label": "契約更改期間",
			"summary": "契約更改を進められる期間です。年俸や残留を整理します。"
		})
	if _is_date_in_range(month, day_of_month, FA_PERIOD_START_MONTH, FA_PERIOD_START_DAY, FA_PERIOD_END_MONTH, FA_PERIOD_END_DAY):
		events.append({
			"type": "fa_period",
			"label": "FA交渉期間",
			"summary": "FA候補との交渉が本格化する期間です。"
		})
	if _is_date_in_range(month, day_of_month, SPONSOR_PERIOD_START_MONTH, SPONSOR_PERIOD_START_DAY, SPONSOR_PERIOD_END_MONTH, SPONSOR_PERIOD_END_DAY):
		events.append({
			"type": "sponsor_period",
			"label": "スポンサー更改期間",
			"summary": "スポンサー営業や契約更新を進めやすい時期です。"
		})
	if _is_date_in_range(month, day_of_month, STAFF_REVIEW_START_MONTH, STAFF_REVIEW_START_DAY, STAFF_REVIEW_END_MONTH, STAFF_REVIEW_END_DAY):
		events.append({
			"type": "staff_review",
			"label": "スタッフ見直し期間",
			"summary": "スタッフ体制の見直しや補強を行いやすい時期です。"
		})

	return events

func get_today_calendar_events() -> Array[Dictionary]:
	return get_calendar_events_for_day(current_day)

func get_upcoming_calendar_events(max_count: int = 5, from_day: int = -1) -> Array[Dictionary]:
	var target_day: int = current_day if from_day <= 0 else from_day
	var result: Array[Dictionary] = []
	var seen_signatures: Dictionary = {}
	for day in range(target_day + 1, get_last_day() + 1):
		for event_data in get_calendar_events_for_day(day):
			var event_type: String = str(event_data.get("type", ""))
			var signature: String = event_type
			if seen_signatures.has(signature):
				continue
			seen_signatures[signature] = true
			result.append({
				"day": day,
				"date_label": get_date_label_for_day(day),
				"type": event_type,
				"label": str(event_data.get("label", "")),
				"summary": str(event_data.get("summary", ""))
			})
			if result.size() >= max_count:
				return result
	return result

func is_contract_period(day: int = -1) -> bool:
	var target_day: int = current_day if day <= 0 else day
	return _calendar_event_exists(target_day, "contract_period")

func is_fa_period(day: int = -1) -> bool:
	var target_day: int = current_day if day <= 0 else day
	return _calendar_event_exists(target_day, "fa_period")

func is_sponsor_period(day: int = -1) -> bool:
	var target_day: int = current_day if day <= 0 else day
	return _calendar_event_exists(target_day, "sponsor_period")

func is_staff_review_period(day: int = -1) -> bool:
	var target_day: int = current_day if day <= 0 else day
	return _calendar_event_exists(target_day, "staff_review")

func is_draft_prep_period(day: int = -1) -> bool:
	var target_day: int = current_day if day <= 0 else day
	return _calendar_event_exists(target_day, "draft_prep")

func is_draft_day(day: int = -1) -> bool:
	var target_day: int = current_day if day <= 0 else day
	return _calendar_event_exists(target_day, "draft_day")

func get_calendar_summary_text(day: int = -1) -> String:
	var target_day: int = current_day if day <= 0 else day
	var events: Array[Dictionary] = get_calendar_events_for_day(target_day)
	if events.is_empty():
		return "今日は大きな年間イベントはありません。"
	var lines: Array[String] = []
	for event_data in events:
		lines.append("%s: %s" % [str(event_data.get("label", "")), str(event_data.get("summary", ""))])
	return "\n".join(lines)

func _calendar_event_exists(day: int, event_type: String) -> bool:
	for event_data in get_calendar_events_for_day(day):
		if str(event_data.get("type", "")) == event_type:
			return true
	return false

func _is_date_in_range(month: int, day_of_month: int, start_month: int, start_day: int, end_month: int, end_day: int) -> bool:
	var current_value: int = month * 100 + day_of_month
	var start_value: int = start_month * 100 + start_day
	var end_value: int = end_month * 100 + end_day
	return current_value >= start_value and current_value <= end_value

func advance_day() -> void:
	current_day += 1

func complete_day_transition() -> Array[String]:
	if current_day < get_last_day():
		advance_day()
		prepared_day = 0
		finalized_finance_day = 0
		return []
	prepared_day = 0
	finalized_finance_day = 0
	return start_new_season()

func all_team_ids() -> Array[String]:
	var result: Array[String] = []
	for key in teams.keys():
		result.append(str(key))
	return result

func simulate_current_day() -> Array:
	_sanitize_match_selection_state()
	_normalize_all_teams()
	_prepare_current_day_context()
	var games_today: Array = get_games_for_day(current_day)

	for game in games_today:
		if bool(game.played):
			continue
		var away_team = get_team(str(game.away_team_id))
		var home_team = get_team(str(game.home_team_id))
		SimulationEngine.simulate_game(game, away_team, home_team)

	_apply_daily_finances_if_ready(current_day, games_today)

	return games_today


func simulate_non_controlled_games_for_current_day() -> Array:
	_sanitize_match_selection_state()
	_normalize_all_teams()
	_prepare_current_day_context()
	var games_today: Array = get_games_for_day(current_day)
	var simulated_games: Array = []

	for game in games_today:
		if bool(game.played):
			continue
		var involves_controlled: bool = controlled_team_id != "" and (
			str(game.away_team_id) == controlled_team_id or str(game.home_team_id) == controlled_team_id
		)
		if involves_controlled:
			continue
		var away_team = get_team(str(game.away_team_id))
		var home_team = get_team(str(game.home_team_id))
		SimulationEngine.simulate_game(game, away_team, home_team)
		simulated_games.append(game)

	_apply_daily_finances_if_ready(current_day, games_today)
	return simulated_games


func finalize_current_day_if_ready() -> Dictionary:
	_sanitize_match_selection_state()
	var games_today: Array = get_games_for_day(current_day)
	for game in games_today:
		if not bool(game.played):
			return {
				"day_completed": false,
				"transition_report": [],
				"finance_applied": false
			}

	_apply_daily_finances_if_ready(current_day, games_today)
	var transition_report: Array[String] = complete_day_transition()
	selected_game_id = ""
	selected_match_mode = "replay"
	active_live_game_id = ""
	return {
		"day_completed": true,
		"transition_report": transition_report,
		"finance_applied": true
	}


func _prepare_current_day_context() -> void:
	_sanitize_match_selection_state()
	if prepared_day == current_day:
		return
	var event_pack: Dictionary = _generate_daily_events(current_day)
	recent_events = event_pack.get("texts", [])
	daily_team_bonuses = event_pack.get("bonuses", {})
	prepared_day = current_day


func _apply_daily_finances_if_ready(day: int, games_today: Array) -> void:
	if finalized_finance_day == day:
		return
	for game in games_today:
		if not bool(game.played):
			return
	_apply_daily_finances(day, games_today)
	finalized_finance_day = day

func _sanitize_match_selection_state() -> void:
	if selected_game_id != "":
		var selected_game = get_selected_game()
		if selected_game == null:
			selected_game_id = ""
			selected_match_mode = "replay"
		elif int(selected_game.day) != current_day or bool(selected_game.played):
			selected_game_id = ""
			selected_match_mode = "replay"

	if active_live_game_id != "":
		var active_game = get_selected_game() if selected_game_id == active_live_game_id else null
		if active_game == null:
			for game_value in schedule:
				var schedule_game: GameData = game_value
				if schedule_game != null and str(schedule_game.id) == active_live_game_id:
					active_game = schedule_game
					break
		if active_game == null or int(active_game.day) != current_day or bool(active_game.played):
			active_live_game_id = ""

func _normalize_all_teams() -> void:
	latest_integrity_notes.clear()
	for team_id in teams.keys():
		var team: TeamData = teams[team_id]
		_normalize_team_structures(team)

func _normalize_team_structures(team: TeamData) -> void:
	if team == null:
		return

	var valid_player_ids: Array[String] = []
	var removed_missing_players: int = 0
	for player_id in team.player_ids:
		var resolved_id: String = str(player_id)
		if players.has(resolved_id):
			valid_player_ids.append(resolved_id)
		else:
			removed_missing_players += 1
	team.player_ids = valid_player_ids

	var has_pitcher: bool = false
	var has_fielder: bool = false
	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player == null:
			continue
		if player.is_pitcher():
			has_pitcher = true
		else:
			has_fielder = true

	if not has_pitcher or not has_fielder:
		_replenish_team_roster(team, [])
		latest_integrity_notes.append("%s roster was missing a pitcher or fielder, so fallback players were added." % team.name)

	var needs_rebuild: bool = false
	for player_id in team.rotation_ids:
		var pitcher: PlayerData = get_player(str(player_id))
		if pitcher == null or not pitcher.is_pitcher():
			needs_rebuild = true
			break

	if not needs_rebuild:
		for player_id in team.lineup_vs_r:
			var batter_r: PlayerData = get_player(str(player_id))
			if batter_r == null or batter_r.is_pitcher():
				needs_rebuild = true
				break

	if not needs_rebuild:
		for player_id in team.lineup_vs_l:
			var batter_l: PlayerData = get_player(str(player_id))
			if batter_l == null or batter_l.is_pitcher():
				needs_rebuild = true
				break

	if needs_rebuild or team.rotation_ids.is_empty() or team.lineup_vs_r.is_empty() or team.lineup_vs_l.is_empty():
		_rebuild_team_competitive_structures(team)
		latest_integrity_notes.append("%s lineup or rotation was broken, so it was rebuilt." % team.name)
		return

	var original_bench_size: int = team.bench_ids.size()
	var cleaned_bench_ids: Array[String] = []
	for player_id in team.bench_ids:
		var bench_player: PlayerData = get_player(str(player_id))
		if bench_player != null and not bench_player.is_pitcher():
			if not cleaned_bench_ids.has(str(bench_player.id)):
				cleaned_bench_ids.append(str(bench_player.id))
	team.bench_ids = cleaned_bench_ids

	normalize_team_bullpen(team)
	if removed_missing_players > 0:
		latest_integrity_notes.append("%s removed %d invalid player ids." % [team.name, removed_missing_players])
	if cleaned_bench_ids.size() != original_bench_size:
		latest_integrity_notes.append("%s bench structure was cleaned up." % team.name)

func get_latest_integrity_notes() -> Array[String]:
	return latest_integrity_notes.duplicate()

func get_integrity_audit() -> Array[String]:
	var issues: Array[String] = []
	if schedule.is_empty():
		issues.append("Schedule data is empty.")
	if current_day < 1:
		issues.append("Current day is below 1.")
	if current_day > get_last_day() + 1:
		issues.append("Current day exceeds schedule range.")
	if controlled_team_id != "" and not teams.has(controlled_team_id):
		issues.append("Controlled team id is invalid.")

	for team_id in teams.keys():
		var team: TeamData = teams[team_id]
		if team == null:
			issues.append("team_id=%s has null team data." % str(team_id))
			continue

		if team.player_ids.is_empty():
			issues.append("%s has no registered players." % team.name)
		if team.rotation_ids.is_empty():
			issues.append("%s has empty rotation." % team.name)
		if team.lineup_vs_r.size() < 9:
			issues.append("%s has fewer than 9 players in lineup_vs_r." % team.name)
		if team.lineup_vs_l.size() < 9:
			issues.append("%s has fewer than 9 players in lineup_vs_l." % team.name)

		var missing_players: int = 0
		for player_id in team.player_ids:
			if get_player(str(player_id)) == null:
				missing_players += 1
		if missing_players > 0:
			issues.append("%s has %d invalid player ids." % [team.name, missing_players])

	if issues.is_empty():
		issues.append("Audit OK")
	return issues

func get_recent_events() -> Array[String]:
	return recent_events.duplicate()

func get_last_offseason_report() -> Array[String]:
	return last_offseason_report.duplicate()

func get_recent_finance_log() -> Array[String]:
	return recent_finance_log.duplicate()

func get_last_controlled_team_roster_log() -> Array[String]:
	return last_controlled_team_roster_log.duplicate()

func get_season_history() -> Array[Dictionary]:
	return season_history.duplicate(true)

func get_latest_completed_season_summary() -> Dictionary:
	if season_history.is_empty():
		return {}
	return season_history[season_history.size() - 1].duplicate(true)

func get_current_operation_progress() -> Dictionary:
	_ensure_operation_year_state(season_year)
	return Dictionary(annual_operation_status.get(str(season_year), {})).duplicate(true)

func get_current_operation_log() -> Array[Dictionary]:
	_ensure_operation_year_state(season_year)
	var result: Array[Dictionary] = []
	for entry in annual_operation_log.get(str(season_year), []):
		result.append(Dictionary(entry))
	return result

func _ensure_operation_year_state(year: int) -> void:
	var year_key: String = str(year)
	if not annual_operation_status.has(year_key):
		annual_operation_status[year_key] = {
			"draft": false,
			"contract": false,
			"fa": false,
			"sponsor": false,
			"staff": false,
			"trade": false
		}
	if not annual_operation_log.has(year_key):
		annual_operation_log[year_key] = []

func _mark_operation_completed(operation_key: String, title: String, detail: String) -> void:
	_ensure_operation_year_state(season_year)
	var year_key: String = str(season_year)
	var status: Dictionary = Dictionary(annual_operation_status.get(year_key, {}))
	status[operation_key] = true
	annual_operation_status[year_key] = status
	var log_entries: Array = annual_operation_log.get(year_key, [])
	log_entries.append({
		"date_label": get_current_date_label(),
		"operation": operation_key,
		"title": title,
		"detail": detail
	})
	annual_operation_log[year_key] = log_entries

func get_controlled_team_history_summary() -> Dictionary:
	if controlled_team_id == "":
		return {}

	var seasons: int = 0
	var championships: int = 0
	var total_wins: int = 0
	var total_losses: int = 0
	var total_draws: int = 0
	var best_rank: int = 0
	var latest_budget: int = 0
	var latest_fan_support: int = 0
	var latest_total_salary: int = 0

	for entry in season_history:
		if str(entry.get("controlled_team_id", "")) != controlled_team_id:
			continue
		seasons += 1
		if str(entry.get("champion_team_id", "")) == controlled_team_id:
			championships += 1
		total_wins += int(entry.get("controlled_wins", 0))
		total_losses += int(entry.get("controlled_losses", 0))
		total_draws += int(entry.get("controlled_draws", 0))
		var rank: int = int(entry.get("controlled_rank", 0))
		if rank > 0 and (best_rank == 0 or rank < best_rank):
			best_rank = rank
		latest_budget = int(entry.get("controlled_budget", latest_budget))
		latest_fan_support = int(entry.get("controlled_fan_support", latest_fan_support))
		latest_total_salary = int(entry.get("controlled_total_salary", latest_total_salary))

	var controlled_team: TeamData = get_controlled_team()
	return {
		"team_id": controlled_team_id,
		"team_name": controlled_team.name if controlled_team != null else "",
		"seasons": seasons,
		"championships": championships,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"total_draws": total_draws,
		"best_rank": best_rank,
		"latest_budget": latest_budget,
		"latest_fan_support": latest_fan_support,
		"latest_total_salary": latest_total_salary
	}

func _archive_current_season(year: int) -> void:
	if teams.is_empty():
		return
	var sorted_teams: Array = get_teams_sorted_by_win_pct()
	if sorted_teams.is_empty():
		return

	var champion: TeamData = sorted_teams[0]
	var last_place: TeamData = sorted_teams[sorted_teams.size() - 1]
	var controlled_team: TeamData = get_controlled_team()
	var batting: Dictionary = get_league_batting_leaders(1)
	var pitching: Dictionary = get_league_pitching_leaders(1)
	var controlled_rank: int = 0
	if controlled_team != null:
		for i in range(sorted_teams.size()):
			var ranked_team: TeamData = sorted_teams[i]
			if ranked_team != null and str(ranked_team.id) == str(controlled_team.id):
				controlled_rank = i + 1
				break

	var summary: Dictionary = {
		"year": year,
		"champion_team_id": str(champion.id),
		"champion_name": champion.name,
		"last_place_team_id": str(last_place.id),
		"last_place_name": last_place.name,
		"controlled_team_id": controlled_team_id,
		"controlled_team_name": controlled_team.name if controlled_team != null else "",
		"controlled_rank": controlled_rank,
		"controlled_wins": int(controlled_team.standings["wins"]) if controlled_team != null else 0,
		"controlled_losses": int(controlled_team.standings["losses"]) if controlled_team != null else 0,
		"controlled_draws": int(controlled_team.standings["draws"]) if controlled_team != null else 0,
		"controlled_budget": int(controlled_team.budget) if controlled_team != null else 0,
		"controlled_total_salary": _calc_team_total_salary(controlled_team) if controlled_team != null else 0,
		"controlled_fan_support": int(controlled_team.fan_support) if controlled_team != null else 0,
		"controlled_runs_for": int(controlled_team.standings["runs_for"]) if controlled_team != null else 0,
		"controlled_runs_against": int(controlled_team.standings["runs_against"]) if controlled_team != null else 0,
		"avg_leader_name": "",
		"avg_leader_value": 0.0,
		"hr_leader_name": "",
		"hr_leader_value": 0,
		"win_leader_name": "",
		"win_leader_value": 0,
		"save_leader_name": "",
		"save_leader_value": 0
	}

	var avg_list: Array = batting.get("avg", [])
	if not avg_list.is_empty():
		var avg_player: PlayerData = avg_list[0]
		summary["avg_leader_name"] = avg_player.full_name
		summary["avg_leader_value"] = avg_player.get_batting_average()

	var hr_list: Array = batting.get("hr", [])
	if not hr_list.is_empty():
		var hr_player: PlayerData = hr_list[0]
		summary["hr_leader_name"] = hr_player.full_name
		summary["hr_leader_value"] = int(hr_player.batting_stats["hr"])

	var win_list: Array = pitching.get("wins", [])
	if not win_list.is_empty():
		var win_player: PlayerData = win_list[0]
		summary["win_leader_name"] = win_player.full_name
		summary["win_leader_value"] = int(win_player.pitching_stats["wins"])

	var save_list: Array = pitching.get("saves", [])
	if not save_list.is_empty():
		var save_player: PlayerData = save_list[0]
		summary["save_leader_name"] = save_player.full_name
		summary["save_leader_value"] = int(save_player.pitching_stats["saves"])

	season_history.append(summary)

func _apply_daily_finances(day: int, games_today: Array) -> void:
	recent_finance_log.clear()
	var processed_team_ids: Array[String] = []

	for game in games_today:
		var away_team: TeamData = get_team(str(game.away_team_id))
		var home_team: TeamData = get_team(str(game.home_team_id))
		if home_team != null and not processed_team_ids.has(str(home_team.id)):
			processed_team_ids.append(str(home_team.id))
			_apply_team_game_day_finance(home_team, true, day)
		if away_team != null and not processed_team_ids.has(str(away_team.id)):
			processed_team_ids.append(str(away_team.id))
			_apply_team_game_day_finance(away_team, false, day)

func _apply_team_game_day_finance(team: TeamData, is_home_game: bool, day: int) -> void:
	var payroll_cost: int = _calc_daily_payroll_cost(team)
	var sponsor_income: int = _calc_daily_sponsor_income(team)
	var staff_cost: int = _calc_daily_staff_cost(team)
	var base_income: int = 800 + int(team.fan_support) * 18
	var venue_bonus: int = 900 if is_home_game else 250
	venue_bonus += int(team.facilities.get("marketing", 1)) * 90
	var performance_bonus: int = int(team.standings["wins"]) * 15
	var game_income: int = base_income + venue_bonus + performance_bonus + sponsor_income
	var travel_cost: int = 120 if is_home_game else 420
	var net_change: int = game_income - payroll_cost - travel_cost - staff_cost

	team.budget = maxi(0, int(team.budget) + net_change)

	if str(team.id) == controlled_team_id:
		var home_away_text: String = "ホーム開催" if is_home_game else "ビジター遠征"
		var line: String = "%s  収支 %s%d  入場+%d  スポンサー+%d  人件費-%d  スタッフ費-%d  %s-%d" % [
			get_date_label_for_day(day),
			"+" if net_change >= 0 else "",
			net_change,
			game_income - sponsor_income,
			sponsor_income,
			payroll_cost,
			staff_cost,
			home_away_text,
			travel_cost
		]
		recent_finance_log.append(line)

func _calc_daily_payroll_cost(team: TeamData) -> int:
	var payroll_sum: int = 0
	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player == null:
			continue
		payroll_sum += int(player.salary)
	return maxi(150, int(round(float(payroll_sum) / 80.0)))

func _calc_daily_sponsor_income(team: TeamData) -> int:
	if team == null:
		return 0
	var sponsor_tier: int = int(team.sponsor_tier)
	var marketing_level: int = int(team.facilities.get("marketing", 1))
	return 160 + sponsor_tier * 180 + marketing_level * 70

func _calc_daily_staff_cost(team: TeamData) -> int:
	if team == null:
		return 0
	var coaches: int = int(team.staff.get("coaches", 0))
	var scouts: int = int(team.staff.get("scouts", 0))
	var trainers: int = int(team.staff.get("trainers", 0))
	return coaches * 22 + scouts * 28 + trainers * 24

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
		events.append("[平穏] 今日は大きなニュースはありません。")

	return {
		"texts": events,
		"bonuses": bonuses
	}

func _build_flavor_event(rng: RandomNumberGenerator) -> Dictionary:
	var team_ids: Array[String] = all_team_ids()
	if team_ids.is_empty():
		return {
			"category": "平穏",
			"text": "今日は特に大きな出来事はありません。",
			"team_id": "",
			"attack": 0.0,
			"pitch": 0.0,
			"fan_delta": 0,
			"budget_delta": 0
		}

	var team_id: String = team_ids[rng.randi_range(0, team_ids.size() - 1)]
	var team = get_team(team_id)
	var roster: Array = []
	if team != null:
		for player_id in team.player_ids:
			var player = get_player(str(player_id))
			if player != null:
				roster.append(player)

	var player_name: String = team.name if team != null else "注目選手"
	if not roster.is_empty():
		var picked_player = roster[rng.randi_range(0, roster.size() - 1)]
		player_name = picked_player.full_name

	var event_defs: Array[Dictionary] = [
		{"category": "朗報", "text": "%s が商店街イベントで大人気。遠征先でも声援が増えている。", "attack": 1.2, "pitch": 0.0, "fan_delta": 3, "budget_delta": 1200},
		{"category": "朗報", "text": "%s が地元球場で子ども向け教室を開き、球団の空気が良くなっている。", "attack": 1.0, "pitch": 0.2, "fan_delta": 1, "budget_delta": 0},
		{"category": "街の噂", "text": "%s の選手たちが河川敷で自主練を続けていると話題。現場の熱気が高まる。", "attack": 0.6, "pitch": 0.4, "fan_delta": 2, "budget_delta": 400},
		{"category": "街の噂", "text": "%s の差し入れ話でベンチの雰囲気が少し上向いている。", "attack": 0.4, "pitch": 0.4, "fan_delta": 1, "budget_delta": -300},
		{"category": "不穏", "text": "%s 周辺で用具トラブルの噂。試合前の空気がやや重い。", "attack": -0.5, "pitch": -0.3, "fan_delta": -1, "budget_delta": -500},
		{"category": "不穏", "text": "%s のベンチで説教が長引いている。立ち上がりに不安。", "attack": -0.3, "pitch": -0.5, "fan_delta": -1, "budget_delta": 0},
		{"category": "朗報", "text": "%s の闘志が注目され、今日は思い切った打席が増えそうだ。", "attack": 1.4, "pitch": 0.0, "fan_delta": 1, "budget_delta": 0},
		{"category": "朗報", "text": "%s の投球練習が好調。周りから期待の声が集まっている。", "attack": 0.0, "pitch": 1.3, "fan_delta": 1, "budget_delta": 0}
	]
	var event_def: Dictionary = event_defs[rng.randi_range(0, event_defs.size() - 1)]
	return {
		"category": str(event_def["category"]),
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

	var team = get_team(team_id)
	if team != null:
		current_bonus = _apply_strategy_event_synergy(team, current_bonus, event_data)
		team.fan_support = clampi(int(team.fan_support) + int(event_data.get("fan_delta", 0)), 0, 100)
		team.budget = maxi(0, int(team.budget) + int(event_data.get("budget_delta", 0)))

	bonuses[team_id] = current_bonus

func _apply_strategy_event_synergy(team, current_bonus: Dictionary, event_data: Dictionary) -> Dictionary:
	if team == null:
		return current_bonus

	var strategy: String = str(team.strategy)
	var category: String = str(event_data.get("category", ""))
	var attack_delta: float = float(event_data.get("attack", 0.0))
	var pitch_delta: float = float(event_data.get("pitch", 0.0))

	match strategy:
		"power":
			if attack_delta > 0.0:
				current_bonus["attack"] = float(current_bonus.get("attack", 0.0)) + 0.35
			elif attack_delta < 0.0:
				current_bonus["attack"] = float(current_bonus.get("attack", 0.0)) - 0.15
		"speed":
			if category == "街の噂":
				current_bonus["attack"] = float(current_bonus.get("attack", 0.0)) + 0.20
			if int(event_data.get("fan_delta", 0)) > 0:
				current_bonus["attack"] = float(current_bonus.get("attack", 0.0)) + 0.15
		"defense":
			if pitch_delta > 0.0:
				current_bonus["pitch"] = float(current_bonus.get("pitch", 0.0)) + 0.40
			elif attack_delta < 0.0 and pitch_delta < 0.0:
				current_bonus["pitch"] = float(current_bonus.get("pitch", 0.0)) - 0.10
		"pitching":
			if pitch_delta > 0.0:
				current_bonus["pitch"] = float(current_bonus.get("pitch", 0.0)) + 0.55
			elif pitch_delta < 0.0:
				current_bonus["pitch"] = float(current_bonus.get("pitch", 0.0)) - 0.20
		_:
			if category == "不穏":
				current_bonus["attack"] = float(current_bonus.get("attack", 0.0)) + 0.15
				current_bonus["pitch"] = float(current_bonus.get("pitch", 0.0)) + 0.15

	return current_bonus

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
	return 366 if _is_leap_year(season_year) else 365

func get_first_game_day() -> int:
	if schedule.is_empty():
		return 1
	var first_day: int = get_last_day()
	for game in schedule:
		first_day = mini(first_day, int(game.day))
	return first_day

func get_final_game_day() -> int:
	if schedule.is_empty():
		return 1
	var final_day: int = 1
	for game in schedule:
		final_day = maxi(final_day, int(game.day))
	return final_day

func get_first_interleague_day() -> int:
	var first_day: int = -1
	for game in schedule:
		if not _is_interleague_game(game):
			continue
		var game_day: int = int(game.day)
		if first_day < 0 or game_day < first_day:
			first_day = game_day
	return first_day

func get_last_interleague_day() -> int:
	var last_day: int = -1
	for game in schedule:
		if not _is_interleague_game(game):
			continue
		last_day = maxi(last_day, int(game.day))
	return last_day

func _find_calendar_day(month: int, day_of_month: int) -> int:
	for day in range(1, get_last_day() + 1):
		var date_info: Dictionary = get_date_info_for_day(day)
		if int(date_info.get("month", 0)) == month and int(date_info.get("day", 0)) == day_of_month:
			return day
	return -1

func _append_milestone(milestones: Array[Dictionary], label: String, button_label: String, progress_label: String, target_day: int) -> void:
	if target_day <= 0:
		return
	milestones.append({
		"label": label,
		"button_label": button_label,
		"progress_label": progress_label,
		"target_day": target_day
	})

func get_next_calendar_milestone() -> Dictionary:
	var opening_day: int = get_first_game_day()
	var first_interleague_day: int = _find_calendar_day(INTERLEAGUE_START_MONTH, INTERLEAGUE_START_DAY)
	var last_interleague_day: int = _find_calendar_day(INTERLEAGUE_END_MONTH, INTERLEAGUE_END_DAY)
	var spring_camp_start_day: int = _find_calendar_day(SPRING_CAMP_START_MONTH, SPRING_CAMP_START_DAY)
	var spring_camp_end_day: int = _find_calendar_day(SPRING_CAMP_END_MONTH, SPRING_CAMP_END_DAY)
	var open_game_start_day: int = _find_calendar_day(OPEN_GAME_START_MONTH, OPEN_GAME_START_DAY)
	var open_game_end_day: int = _find_calendar_day(OPEN_GAME_END_MONTH, OPEN_GAME_END_DAY)
	var climax_first_start_day: int = _find_calendar_day(CLIMAX_FIRST_START_MONTH, CLIMAX_FIRST_START_DAY)
	var climax_first_end_day: int = _find_calendar_day(CLIMAX_FIRST_END_MONTH, CLIMAX_FIRST_END_DAY)
	var climax_final_start_day: int = _find_calendar_day(CLIMAX_FINAL_START_MONTH, CLIMAX_FINAL_START_DAY)
	var climax_final_end_day: int = _find_calendar_day(CLIMAX_FINAL_END_MONTH, CLIMAX_FINAL_END_DAY)
	var japan_series_start_day: int = _find_calendar_day(JAPAN_SERIES_START_MONTH, JAPAN_SERIES_START_DAY)
	var japan_series_end_day: int = _find_calendar_day(JAPAN_SERIES_END_MONTH, JAPAN_SERIES_END_DAY)
	var draft_prep_start_day: int = _find_calendar_day(DRAFT_PREP_START_MONTH, DRAFT_PREP_START_DAY)
	var draft_day: int = _find_calendar_day(DRAFT_DAY_MONTH, DRAFT_DAY_DAY)
	var contract_start_day: int = _find_calendar_day(CONTRACT_PERIOD_START_MONTH, CONTRACT_PERIOD_START_DAY)
	var contract_end_day: int = _find_calendar_day(CONTRACT_PERIOD_END_MONTH, CONTRACT_PERIOD_END_DAY)
	var fa_start_day: int = _find_calendar_day(FA_PERIOD_START_MONTH, FA_PERIOD_START_DAY)
	var fa_end_day: int = _find_calendar_day(FA_PERIOD_END_MONTH, FA_PERIOD_END_DAY)
	var sponsor_start_day: int = _find_calendar_day(SPONSOR_PERIOD_START_MONTH, SPONSOR_PERIOD_START_DAY)
	var sponsor_end_day: int = _find_calendar_day(SPONSOR_PERIOD_END_MONTH, SPONSOR_PERIOD_END_DAY)
	var staff_review_start_day: int = _find_calendar_day(STAFF_REVIEW_START_MONTH, STAFF_REVIEW_START_DAY)
	var staff_review_end_day: int = _find_calendar_day(STAFF_REVIEW_END_MONTH, STAFF_REVIEW_END_DAY)

	var milestones: Array[Dictionary] = []
	_append_milestone(milestones, "春季キャンプ", "キャンプまで", "春季キャンプ開始", spring_camp_start_day)
	_append_milestone(milestones, "キャンプ終了", "キャンプ終了まで", "春季キャンプ終了", spring_camp_end_day)
	_append_milestone(milestones, "オープン戦", "オープン戦まで", "オープン戦開始", open_game_start_day)
	_append_milestone(milestones, "オープン戦終了", "オープン戦終了まで", "オープン戦終了", open_game_end_day)
	_append_milestone(milestones, "開幕", "開幕まで", "開幕", opening_day)
	_append_milestone(milestones, "交流戦", "交流戦まで", "交流戦開始", first_interleague_day)
	_append_milestone(milestones, "交流戦終了", "交流戦明けまで", "交流戦終了", last_interleague_day)
	_append_milestone(milestones, "クライマックス開始", "CS開始まで", "クライマックス開始", climax_first_start_day)
	_append_milestone(milestones, "クライマックス1st終了", "CS1st終了まで", "クライマックス1st終了", climax_first_end_day)
	_append_milestone(milestones, "クライマックスFinal", "CS Finalまで", "クライマックスFinal開始", climax_final_start_day)
	_append_milestone(milestones, "クライマックスFinal終了", "CS終了まで", "クライマックスFinal終了", climax_final_end_day)
	_append_milestone(milestones, "日本シリーズ", "日本Sまで", "日本シリーズ開始", japan_series_start_day)
	_append_milestone(milestones, "日本シリーズ終了", "日本S終了まで", "日本シリーズ終了", japan_series_end_day)
	_append_milestone(milestones, "ドラフト準備", "ドラフト準備まで", "ドラフト準備開始", draft_prep_start_day)
	_append_milestone(milestones, "ドラフト会議", "ドラフト会議まで", "ドラフト会議", draft_day)
	_append_milestone(milestones, "契約更改", "契約更改まで", "契約更改開始", contract_start_day)
	_append_milestone(milestones, "契約更改終了", "更改終了まで", "契約更改終了", contract_end_day)
	_append_milestone(milestones, "FA交渉", "FA期間まで", "FA交渉開始", fa_start_day)
	_append_milestone(milestones, "FA終了", "FA終了まで", "FA交渉終了", fa_end_day)
	_append_milestone(milestones, "スポンサー更改", "スポンサー期まで", "スポンサー更改開始", sponsor_start_day)
	_append_milestone(milestones, "スポンサー終了", "スポンサー終了まで", "スポンサー更改終了", sponsor_end_day)
	_append_milestone(milestones, "スタッフ見直し", "スタッフ期まで", "スタッフ見直し開始", staff_review_start_day)
	_append_milestone(milestones, "スタッフ見直し終了", "スタッフ期終了まで", "スタッフ見直し終了", staff_review_end_day)

	for milestone in milestones:
		var milestone_day: int = int(milestone.get("target_day", -1))
		if milestone_day > current_day:
			return milestone

	return {"label": "年越し", "button_label": "年越しまで", "progress_label": "年越し", "target_day": get_last_day()}

func _is_interleague_game(game: GameData) -> bool:
	var away_league: String = _get_team_league_key(str(game.away_team_id))
	var home_league: String = _get_team_league_key(str(game.home_team_id))
	return away_league != "" and home_league != "" and away_league != home_league

func get_season_phase() -> String:
	var first_game_day: int = get_first_game_day()
	var final_game_day: int = get_final_game_day()
	if current_day < first_game_day:
		return "preseason"
	if current_day <= final_game_day:
		return "regular"
	return "offseason"

func _run_offseason(previous_year: int, next_year: int) -> Array[String]:
	var lines: Array[String] = []
	lines.append("%d年シーズンのオフ処理を開始しました。" % previous_year)
	lines.append("%d年シーズンに向けて状態と選手を調整します。" % next_year)

	var sorted_teams: Array = get_teams_sorted_by_win_pct()
	var champion_id: String = ""
	if not sorted_teams.is_empty():
		var champion: TeamData = sorted_teams[0]
		if champion != null:
			champion_id = str(champion.id)

	for team_id in all_team_ids():
		var team: TeamData = get_team(team_id)
		if team == null:
			continue
		var wins: int = int(team.standings["wins"])
		var losses: int = int(team.standings["losses"])
		var draw_bonus: int = int(team.standings["draws"]) * 120
		var run_diff: int = int(team.standings["runs_for"]) - int(team.standings["runs_against"])
		var budget_change: int = 6000 + wins * 220 - losses * 80 + draw_bonus + run_diff * 10
		if str(team.id) == champion_id:
			budget_change += 5000
		team.budget = maxi(5000, int(team.budget) + budget_change)

		var fan_change: int = int(round(float(run_diff) / 20.0))
		fan_change += int(round(float(wins - losses) / 4.0))
		if str(team.id) == champion_id:
			fan_change += 5
		team.fan_support = clampi(int(team.fan_support) + fan_change, 0, 100)

	for player_id in players.keys():
		var player: PlayerData = players[player_id]
		if player == null:
			continue
		_apply_player_offseason(player)

	var salary_review_report: Array[String] = _apply_salary_reviews()
	for report_line in salary_review_report:
		lines.append(report_line)

	var roster_report: Array[String] = _process_retirements_and_replacements()
	for report_line in roster_report:
		lines.append(report_line)

	if champion_id != "":
		var champion_team: TeamData = get_team(champion_id)
		if champion_team != null:
			lines.append("前年度の優勝: %s" % champion_team.name)

	var controlled_team: TeamData = get_controlled_team()
	if controlled_team != null:
		lines.append("担当球団: %s / 人気 %d / 予算 %d" % [controlled_team.name, int(controlled_team.fan_support), int(controlled_team.budget)])

	lines.append("オフシーズン処理が完了しました。")
	return lines

func _apply_salary_reviews() -> Array[String]:
	var lines: Array[String] = []
	var controlled_team: TeamData = get_controlled_team()
	var controlled_before: int = _calc_team_total_salary(controlled_team) if controlled_team != null else 0

	for player_id in players.keys():
		var player: PlayerData = players[player_id]
		if player == null:
			continue
		_apply_salary_review(player)

	var payroll_adjustment_report: Array[String] = _rebalance_team_payrolls()
	for report_line in payroll_adjustment_report:
		lines.append(report_line)

	var controlled_after: int = _calc_team_total_salary(controlled_team) if controlled_team != null else 0
	if controlled_team != null:
		lines.append("担当球団年俸更改: %d -> %d (%+d)" % [
			controlled_before,
			controlled_after,
			controlled_after - controlled_before
		])
	return lines

func _apply_salary_review(player: PlayerData) -> void:
	var base_salary: int = int(player.salary)
	var target_salary: int = base_salary

	if player.is_pitcher():
		var outs: int = int(player.pitching_stats["outs"])
		var wins: int = int(player.pitching_stats["wins"])
		var saves: int = int(player.pitching_stats["saves"])
		var holds: int = int(player.pitching_stats["holds"])
		var era: float = player.get_era()
		target_salary += int(round(float(player.overall - 50) * 12.0))
		target_salary += wins * 70 + saves * 45 + holds * 20
		target_salary += int(round(float(outs) / 9.0 * 6.0))
		if outs >= 27 and era <= 3.20:
			target_salary += 250
		elif outs >= 18 and era >= 5.20:
			target_salary -= 120
	else:
		var avg: float = player.get_batting_average()
		var hr: int = int(player.batting_stats["hr"])
		var rbi: int = int(player.batting_stats["rbi"])
		var pa: int = int(player.batting_stats["pa"])
		target_salary += int(round(float(player.overall - 50) * 11.0))
		target_salary += hr * 35 + rbi * 8
		target_salary += int(round(float(pa) * 0.8))
		if pa >= 80 and avg >= 0.300:
			target_salary += 220
		elif pa >= 40 and avg <= 0.210:
			target_salary -= 120

	if player.age <= 24 and int(player.potential) > int(player.overall):
		target_salary += 80
	elif player.age >= 34:
		target_salary -= 60

	var eased_salary: int = int(round(float(base_salary) * 0.55 + float(target_salary) * 0.45))
	player.salary = clampi(eased_salary, 180, 12000)
	player.desired_salary = int(round(float(player.salary) * (1.00 + float(player.fa_interest) / 220.0)))

func _rebalance_team_payrolls() -> Array[String]:
	var lines: Array[String] = []
	for team_id in all_team_ids():
		var team: TeamData = get_team(team_id)
		if team == null:
			continue

		var total_salary: int = _calc_team_total_salary(team)
		var soft_cap: int = maxi(3000, int(team.budget) + 2500)
		if total_salary <= soft_cap:
			continue

		var scale: float = float(soft_cap) / float(maxi(total_salary, 1))
		for player_id in team.player_ids:
			var player: PlayerData = get_player(str(player_id))
			if player == null:
				continue
			player.salary = clampi(int(round(float(player.salary) * scale)), 180, 12000)
			player.desired_salary = int(round(float(player.salary) * (1.00 + float(player.fa_interest) / 220.0)))

		var adjusted_total: int = _calc_team_total_salary(team)
		if controlled_team_id != "" and str(team.id) == str(controlled_team_id):
			lines.append("担当球団年俸調整: %d -> %d" % [total_salary, adjusted_total])
	return lines

func _calc_team_total_salary(team: TeamData) -> int:
	if team == null:
		return 0
	var total_salary: int = 0
	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player == null:
			continue
		total_salary += int(player.salary)
	return total_salary

func get_team_total_salary(team_id: String) -> int:
	return _calc_team_total_salary(get_team(team_id))

func get_team_management_snapshot(team_id: String) -> Dictionary:
	var team: TeamData = get_team(team_id)
	if team == null:
		return {}
	return {
		"team_name": team.name,
		"budget": int(team.budget),
		"fan_support": int(team.fan_support),
		"total_salary": _calc_team_total_salary(team),
		"sponsor_name": str(team.sponsor_name),
		"sponsor_tier": int(team.sponsor_tier),
		"daily_sponsor_income": _calc_daily_sponsor_income(team),
		"daily_staff_cost": _calc_daily_staff_cost(team),
		"facilities": team.facilities.duplicate(true),
		"staff": team.staff.duplicate(true)
	}

func get_facility_upgrade_cost(team_id: String, facility_key: String) -> int:
	var team: TeamData = get_team(team_id)
	if team == null:
		return -1
	var current_level: int = int(team.facilities.get(facility_key, 1))
	return 4000 + current_level * 2500

func _roll_sponsor_name(team: TeamData) -> String:
	var team_name: String = team.name if team != null else "球団"
	var base_names: Array[String] = [
		"街角グループ",
		"地元建設",
		"青空フーズ",
		"港町メディカル",
		"ナイター商店街",
		"ストリート工業",
		"商店会連合",
		"未来モータース"
	]
	var picked: String = base_names[abs(hash(team_name + str(team.sponsor_tier))) % base_names.size()]
	return "%s %s" % [team_name.substr(0, mini(2, team_name.length())), picked]

func _get_facility_label(facility_key: String) -> String:
	match facility_key:
		"training":
			return "練習施設"
		"medical":
			return "医療施設"
		"scouting":
			return "スカウト施設"
		"marketing":
			return "営業施設"
		_:
			return facility_key

func _get_staff_label(staff_key: String) -> String:
	match staff_key:
		"coaches":
			return "コーチ"
		"scouts":
			return "スカウト"
		"trainers":
			return "トレーナー"
		_:
			return staff_key

func upgrade_team_facility(team_id: String, facility_key: String) -> Dictionary:
	var team: TeamData = get_team(team_id)
	if team == null:
		return {"ok": false, "message": "球団データが見つかりません。"}
	if not team.facilities.has(facility_key):
		return {"ok": false, "message": "対象外の施設です。"}
	var current_level: int = int(team.facilities.get(facility_key, 1))
	if current_level >= 5:
		return {"ok": false, "message": "これ以上は強化できません。"}
	var cost: int = get_facility_upgrade_cost(team_id, facility_key)
	if int(team.budget) < cost:
		return {"ok": false, "message": "予算が不足しています。必要額: %d" % cost}
	team.budget = int(team.budget) - cost
	team.facilities[facility_key] = current_level + 1
	var result := {
		"ok": true,
		"message": "%sをLv.%dに強化しました。予算 -%d" % [_get_facility_label(facility_key), current_level + 1, cost]
	}
	_mark_operation_completed("staff", "施設強化", str(result["message"]))
	return result

func change_team_staff(team_id: String, staff_key: String, delta: int) -> Dictionary:
	var team: TeamData = get_team(team_id)
	if team == null:
		return {"ok": false, "message": "球団データが見つかりません。"}
	if not team.staff.has(staff_key):
		return {"ok": false, "message": "対象外のスタッフ種別です。"}
	if delta == 0:
		return {"ok": false, "message": "変更人数が0です。"}
	var current_count: int = int(team.staff.get(staff_key, 0))
	if delta < 0:
		var min_count: int = 1
		if current_count <= min_count:
			return {"ok": false, "message": "%sはこれ以上減らせません。" % _get_staff_label(staff_key)}
		team.staff[staff_key] = current_count - 1
		var reduce_result := {"ok": true, "message": "%sを1人減らしました。" % _get_staff_label(staff_key)}
		_mark_operation_completed("staff", "スタッフ見直し", str(reduce_result["message"]))
		return reduce_result
	var hire_cost: int = 1800 + current_count * 1200
	if int(team.budget) < hire_cost:
		return {"ok": false, "message": "予算が不足しています。必要額: %d" % hire_cost}
	team.budget = int(team.budget) - hire_cost
	team.staff[staff_key] = current_count + 1
	var hire_result := {"ok": true, "message": "%sを1人増やしました。予算 -%d" % [_get_staff_label(staff_key), hire_cost]}
	_mark_operation_completed("staff", "スタッフ見直し", str(hire_result["message"]))
	return hire_result

func pitch_team_sponsor(team_id: String) -> Dictionary:
	var team: TeamData = get_team(team_id)
	if team == null:
		return {"ok": false, "message": "球団データが見つかりません。"}
	var marketing_level: int = int(team.facilities.get("marketing", 1))
	var scout_count: int = int(team.staff.get("scouts", 1))
	var growth_roll: int = (marketing_level * 12) + (scout_count * 8) + int(team.fan_support / 4)
	if growth_roll >= 55 and int(team.sponsor_tier) < 5:
		team.sponsor_tier = int(team.sponsor_tier) + 1
		team.sponsor_name = _roll_sponsor_name(team)
		var rankup_result := {"ok": true, "message": "スポンサーがランクアップしました: %s / Tier %d" % [team.sponsor_name, int(team.sponsor_tier)]}
		_mark_operation_completed("sponsor", "スポンサー更改", str(rankup_result["message"]))
		return rankup_result
	var bonus_budget: int = 1200 + marketing_level * 300
	team.budget = int(team.budget) + bonus_budget
	var sponsor_result := {"ok": true, "message": "スポンサー営業が成功しました。予算 +%d" % bonus_budget}
	_mark_operation_completed("sponsor", "スポンサー更改", str(sponsor_result["message"]))
	return sponsor_result

func get_controlled_team_contract_summary() -> Dictionary:
	var team: TeamData = get_controlled_team()
	if team == null:
		return {}
	var expiring_players: Array[PlayerData] = []
	var fa_watch_players: Array[PlayerData] = []
	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player == null:
			continue
		if int(player.contract_years_left) <= 1:
			expiring_players.append(player)
		if int(player.fa_interest) >= 65:
			fa_watch_players.append(player)
	expiring_players.sort_custom(func(a: PlayerData, b: PlayerData) -> bool:
		return int(a.overall) > int(b.overall)
	)
	fa_watch_players.sort_custom(func(a: PlayerData, b: PlayerData) -> bool:
		return int(a.fa_interest) > int(b.fa_interest)
	)
	return {
		"expiring_count": expiring_players.size(),
		"expiring_players": expiring_players,
		"fa_watch_players": fa_watch_players
	}

func renew_controlled_player_contract(player_id: String, years: int = 2) -> Dictionary:
	var team: TeamData = get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が見つかりません。"}
	var player: PlayerData = get_player(player_id)
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
		"message": "%sと%d年契約を結びました。予算 -%d / 年俸 %d" % [player.full_name, years, signing_bonus, int(player.salary)]
	}
	_mark_operation_completed("contract", "契約更改", str(renewal_result["message"]))
	return renewal_result

func get_fa_candidate_list() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for team_id in teams.keys():
		var team: TeamData = teams[team_id]
		if team == null:
			continue
		for player_id in team.player_ids:
			var player: PlayerData = get_player(str(player_id))
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
				"is_controlled_team": str(team.id) == controlled_team_id
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

func negotiate_controlled_team_fa(player_id: String, years: int = 3) -> Dictionary:
	if not is_fa_period():
		return {"ok": false, "message": "FA交渉はFA期間のみ行えます。"}
	var team: TeamData = get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が設定されていません。"}
	var player: PlayerData = get_player(player_id)
	if player == null:
		return {"ok": false, "message": "対象選手が見つかりません。"}

	var current_team: TeamData = _find_player_team(str(player.id))
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
		_rebuild_team_competitive_structures(current_team)

	player.salary = int(player.desired_salary)
	player.contract_years_left = clampi(years, 1, 5)
	player.desired_salary = int(round(float(player.salary) * 1.1))
	player.fa_interest = clampi(int(player.fa_interest) - 25, 0, 100)
	player.morale = clampi(int(player.morale) + 12, 0, 100)

	if not team.player_ids.has(str(player.id)):
		team.player_ids.append(str(player.id))
	_rebuild_team_competitive_structures(team)

	var fa_result := {
		"ok": true,
		"message": "%sと%d年契約を結びました。予算 -%d / 年俸 %d" % [player.full_name, years, signing_cost, int(player.salary)],
		"player_name": player.full_name,
		"years": years,
		"cost": signing_cost
	}
	_mark_operation_completed("fa", "FA交渉", str(fa_result["message"]))
	return fa_result

func get_controlled_team_trade_proposals() -> Array[Dictionary]:
	var team: TeamData = get_controlled_team()
	if team == null:
		return []

	var own_players: Array[PlayerData] = []
	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player != null:
			own_players.append(player)
	own_players.sort_custom(func(a: PlayerData, b: PlayerData) -> bool:
		return int(a.overall) < int(b.overall)
	)

	var proposals: Array[Dictionary] = []
	for other_team_id in all_team_ids():
		if other_team_id == str(team.id):
			continue
		var other_team: TeamData = get_team(other_team_id)
		if other_team == null:
			continue

		var other_players: Array[PlayerData] = []
		for player_id in other_team.player_ids:
			var player: PlayerData = get_player(str(player_id))
			if player != null:
				other_players.append(player)
		other_players.sort_custom(func(a: PlayerData, b: PlayerData) -> bool:
			return int(a.overall) > int(b.overall)
		)

		if own_players.is_empty() or other_players.is_empty():
			continue

		var give_player: PlayerData = own_players[min(proposals.size(), own_players.size() - 1)]
		var take_player: PlayerData = other_players[0]
		proposals.append({
			"other_team_id": str(other_team.id),
			"other_team_name": other_team.name,
			"give_player_id": str(give_player.id),
			"give_player_name": give_player.full_name,
			"give_player_overall": int(give_player.overall),
			"take_player_id": str(take_player.id),
			"take_player_name": take_player.full_name,
			"take_player_overall": int(take_player.overall),
			"summary": "%s ⇄ %s" % [give_player.full_name, take_player.full_name]
		})
		if proposals.size() >= 3:
			break

	return proposals

func execute_controlled_team_trade(give_player_id: String, take_player_id: String) -> Dictionary:
	var team: TeamData = get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が設定されていません。"}
	if give_player_id == "" or take_player_id == "":
		return {"ok": false, "message": "トレード対象が不正です。"}

	var give_player: PlayerData = get_player(give_player_id)
	var take_player: PlayerData = get_player(take_player_id)
	if give_player == null or take_player == null:
		return {"ok": false, "message": "対象選手が見つかりません。"}
	if not team.player_ids.has(give_player_id):
		return {"ok": false, "message": "放出選手が担当球団に所属していません。"}

	var other_team: TeamData = _find_player_team(take_player_id)
	if other_team == null or str(other_team.id) == str(team.id):
		return {"ok": false, "message": "交換相手の所属先が不正です。"}

	team.player_ids.erase(give_player_id)
	other_team.player_ids.erase(take_player_id)
	team.player_ids.append(take_player_id)
	other_team.player_ids.append(give_player_id)

	_rebuild_team_competitive_structures(team)
	_rebuild_team_competitive_structures(other_team)

	var trade_result := {
		"ok": true,
		"message": "%sとのトレード成立: %s ⇄ %s" % [other_team.name, give_player.full_name, take_player.full_name]
	}
	_mark_operation_completed("trade", "トレード成立", str(trade_result["message"]))
	return trade_result

func get_controlled_team_draft_prospects() -> Array[Dictionary]:
	var team: TeamData = get_controlled_team()
	if team == null:
		return []
	return _build_draft_prospect_list(team)

func toggle_controlled_draft_focus(prospect_id: String) -> Dictionary:
	if not is_draft_prep_period() and not is_draft_day():
		return {"ok": false, "message": "注目候補の整理はドラフト準備期間とドラフト会議日に行えます。"}
	var team: TeamData = get_controlled_team()
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

func _build_draft_prospect_list(team: TeamData) -> Array[Dictionary]:
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
		var prospect_id: String = "%d_draft_%02d" % [season_year, i + 1]
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

func run_controlled_team_draft() -> Dictionary:
	if not is_draft_day():
		return {"ok": false, "message": "ドラフト指名はドラフト会議当日のみ行えます。"}
	var team: TeamData = get_controlled_team()
	if team == null:
		return {"ok": false, "message": "担当球団が設定されていません。"}
	if int(team.last_draft_year) == int(season_year):
		return {"ok": false, "message": "今年のドラフト指名はすでに完了しています。"}

	var prospects: Array[Dictionary] = _build_draft_prospect_list(team)
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
	var player: PlayerData
	if role_text.find("投手") >= 0:
		player = _build_replacement_pitcher(team.id, "starter")
	elif role_text.find("捕手") >= 0:
		player = _build_replacement_fielder(team.id, "C")
	elif role_text.find("外野手") >= 0:
		player = _build_replacement_fielder(team.id, "CF")
	else:
		player = _build_replacement_fielder(team.id, "SS")

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
	player.traits = [str(chosen.get("style", ""))]

	_register_new_player(team, player)
	_rebuild_team_competitive_structures(team)
	team.last_draft_year = season_year
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
	_mark_operation_completed("draft", "ドラフト会議", str(draft_result["message"]))
	return draft_result


func _apply_player_offseason(player: PlayerData) -> void:
	var team: TeamData = _find_player_team(str(player.id))
	player.age += 1
	player.years_pro += 1
	player.contract_years_left = maxi(0, int(player.contract_years_left) - 1)
	player.fatigue = 0
	player.condition = clampi(55 + int(player.morale / 2), 40, 100)
	player.morale = clampi(int(player.morale) + 3, 0, 100)

	var growth_budget: int = 0
	if player.age <= 24:
		growth_budget = 2
	elif player.age <= 28:
		growth_budget = 1
	elif player.age >= 33:
		growth_budget = -1

	if player.overall < player.potential:
		growth_budget += 1
	elif player.overall > player.potential + 5:
		growth_budget -= 1

	if team != null:
		growth_budget += maxi(0, int(team.facilities.get("training", 1)) - 1)
		growth_budget += maxi(0, int(team.staff.get("coaches", 2)) - 2)
		if int(team.facilities.get("medical", 1)) >= 3:
			player.injury_risk = maxf(0.01, float(player.injury_risk) - 0.002)
		if int(team.staff.get("trainers", 1)) >= 2:
			player.condition = clampi(int(player.condition) + 3, 0, 100)
		if int(team.fan_support) >= 65:
			player.fa_interest = clampi(int(player.fa_interest) - 3, 0, 100)
		elif int(team.fan_support) <= 35:
			player.fa_interest = clampi(int(player.fa_interest) + 4, 0, 100)

	if player.is_pitcher():
		_apply_rating_delta(player, "velocity", growth_budget)
		_apply_rating_delta(player, "control", growth_budget)
		_apply_rating_delta(player, "stamina", 1 if player.role == "starter" and growth_budget > 0 else 0)
		_apply_rating_delta(player, "break", growth_budget)
		_apply_rating_delta(player, "k_rate", growth_budget)
		_apply_rating_delta(player, "composure", 1 if player.age >= 27 else 0)
	else:
		_apply_rating_delta(player, "contact", growth_budget)
		_apply_rating_delta(player, "power", growth_budget)
		_apply_rating_delta(player, "eye", growth_budget)
		_apply_rating_delta(player, "speed", -1 if player.age >= 31 else growth_budget)
		_apply_rating_delta(player, "fielding", 1 if player.age <= 30 and growth_budget >= 0 else 0)
		_apply_rating_delta(player, "arm", 0)
		_apply_rating_delta(player, "catching", 0)

	player.overall = clampi(player.calc_overall(), 1, 99)

func _apply_rating_delta(player: PlayerData, rating_key: String, delta: int) -> void:
	var current_value: int = int(player.ratings.get(rating_key, 50))
	player.ratings[rating_key] = clampi(current_value + delta, 1, 99)

func _process_retirements_and_replacements() -> Array[String]:
	var lines: Array[String] = []
	var total_retired: int = 0
	var total_added: int = 0

	for team_id in all_team_ids():
		var team: TeamData = get_team(team_id)
		if team == null:
			continue

		var retired_ids: Array[String] = []
		var retired_names: Array[String] = []
		for player_id in team.player_ids:
			var player: PlayerData = get_player(str(player_id))
			if player == null:
				continue
			if _should_player_retire(player):
				retired_ids.append(str(player.id))
				retired_names.append(str(player.full_name))

		for retired_id in retired_ids:
			_remove_player_from_team(team, retired_id)
			players.erase(retired_id)

		var added_names: Array[String] = []
		var added_count: int = _replenish_team_roster(team, added_names)
		total_retired += retired_ids.size()
		total_added += added_count

		if not retired_ids.is_empty() or added_count > 0:
			lines.append("%s: 引退 %d人 / 新人補充 %d人" % [team.name, retired_ids.size(), added_count])
		if str(team.id) == controlled_team_id:
			last_controlled_team_roster_log.clear()
			last_controlled_team_roster_log.append("%s のオフ動向" % team.name)
			if retired_names.is_empty() and added_names.is_empty():
				last_controlled_team_roster_log.append("引退・加入はありませんでした。")
			else:
				for retired_name in retired_names:
					last_controlled_team_roster_log.append("引退: %s" % retired_name)
				for added_name in added_names:
					last_controlled_team_roster_log.append("加入: %s" % added_name)

	if lines.is_empty():
		lines.append("引退・新人補充はありませんでした。")
	else:
		lines.insert(0, "引退 %d人 / 新人補充 %d人" % [total_retired, total_added])

	return lines

func _should_player_retire(player: PlayerData) -> bool:
	if player == null:
		return false
	if player.age >= 40:
		return true

	var retire_chance: float = 0.0
	if player.age >= 38:
		retire_chance = 0.70
	elif player.age >= 36:
		retire_chance = 0.35
	elif player.age >= 34:
		retire_chance = 0.12

	if int(player.overall) <= 45:
		retire_chance += 0.15
	elif int(player.overall) <= 55:
		retire_chance += 0.05

	if int(player.fatigue) >= 70:
		retire_chance += 0.05

	if retire_chance <= 0.0:
		return false

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(season_year * 100000 + abs(hash(player.id)))
	return rng.randf() < minf(retire_chance, 0.98)

func _remove_player_from_team(team: TeamData, player_id: String) -> void:
	team.player_ids.erase(player_id)
	team.lineup_vs_r.erase(player_id)
	team.lineup_vs_l.erase(player_id)
	team.bench_ids.erase(player_id)
	team.rotation_ids.erase(player_id)
	team.bullpen["setup"].erase(player_id)
	team.bullpen["middle"].erase(player_id)
	if str(team.bullpen.get("closer", "")) == player_id:
		team.bullpen["closer"] = ""
	if str(team.bullpen.get("long", "")) == player_id:
		team.bullpen["long"] = ""

func _find_player_team(player_id: String) -> TeamData:
	for team_id in all_team_ids():
		var team: TeamData = get_team(team_id)
		if team != null and team.player_ids.has(player_id):
			return team
	return null

func _replenish_team_roster(team: TeamData, added_names: Array[String]) -> int:
	var added_players: Array = []
	var existing_players: Array = []
	for player_id in team.player_ids:
		var existing_player: PlayerData = get_player(str(player_id))
		if existing_player != null:
			existing_players.append(existing_player)

	var starter_count: int = 0
	var reliever_count: int = 0
	var closer_count: int = 0
	var fielder_count: int = 0
	var position_counts: Dictionary = {}
	for player in existing_players:
		if player == null:
			continue
		match str(player.role):
			"starter":
				starter_count += 1
			"reliever":
				reliever_count += 1
			"closer":
				closer_count += 1
			_:
				fielder_count += 1
				var primary_position: String = str(player.primary_position)
				position_counts[primary_position] = int(position_counts.get(primary_position, 0)) + 1

	while starter_count < 5:
		var starter: PlayerData = _build_replacement_pitcher(team.id, "starter")
		_register_new_player(team, starter)
		added_players.append(starter)
		added_names.append(str(starter.full_name))
		starter_count += 1

	while closer_count < 1:
		var closer: PlayerData = _build_replacement_pitcher(team.id, "closer")
		_register_new_player(team, closer)
		added_players.append(closer)
		added_names.append(str(closer.full_name))
		closer_count += 1

	while reliever_count < 4:
		var reliever: PlayerData = _build_replacement_pitcher(team.id, "reliever")
		_register_new_player(team, reliever)
		added_players.append(reliever)
		added_names.append(str(reliever.full_name))
		reliever_count += 1

	var desired_counts: Dictionary = {}
	for slot in DESIRED_FIELDER_SLOTS:
		if str(slot) == "UT":
			continue
		desired_counts[str(slot)] = int(desired_counts.get(str(slot), 0)) + 1

	for position_key in desired_counts.keys():
		var desired_count: int = int(desired_counts[position_key])
		var current_count: int = int(position_counts.get(position_key, 0))
		while current_count < desired_count:
			var fielder: PlayerData = _build_replacement_fielder(team.id, str(position_key))
			_register_new_player(team, fielder)
			added_players.append(fielder)
			added_names.append(str(fielder.full_name))
			fielder_count += 1
			current_count += 1
			position_counts[position_key] = current_count

	while fielder_count < DESIRED_FIELDER_SLOTS.size():
		var utility_fielder: PlayerData = _build_replacement_fielder(team.id, "UT")
		_register_new_player(team, utility_fielder)
		added_players.append(utility_fielder)
		added_names.append(str(utility_fielder.full_name))
		fielder_count += 1

	_rebuild_team_competitive_structures(team)
	return added_players.size()

func _build_replacement_pitcher(team_id: String, role_name: String) -> PlayerData:
	var team: TeamData = get_team(team_id)
	var next_player_id: String = _allocate_next_player_id(team_id)
	var archetype: String = PlayerFactory._pick_pitcher_archetype(role_name)
	var pitcher: PlayerData = PlayerFactory.build_pitcher(next_player_id, role_name, archetype)
	pitcher.age = 18 + (abs(hash(next_player_id)) % 5)
	pitcher.years_pro = 1
	pitcher.salary = clampi(int(pitcher.salary) / 2, 250, 1800)
	pitcher.morale = 55
	pitcher.condition = 60
	pitcher.fatigue = 0
	var scouting_boost: int = 0
	if team != null:
		scouting_boost = maxi(0, int(team.facilities.get("scouting", 1)) - 1) + maxi(0, int(team.staff.get("scouts", 1)) - 1)
		pitcher.potential = clampi(int(pitcher.potential) + scouting_boost * 2, 40, 99)
	pitcher.overall = clampi(pitcher.calc_overall() + scouting_boost, 1, 99)
	return pitcher

func _build_replacement_fielder(team_id: String, slot: String) -> PlayerData:
	var team: TeamData = get_team(team_id)
	var next_player_id: String = _allocate_next_player_id(team_id)
	var base_position: String = slot
	if slot == "UT":
		var util_positions: Array[String] = ["2B", "3B", "SS", "LF", "CF", "RF"]
		base_position = util_positions[abs(hash(next_player_id)) % util_positions.size()]
	var archetype: String = PlayerFactory._pick_fielder_archetype(base_position)
	var fielder: PlayerData = PlayerFactory.build_fielder(next_player_id, base_position, archetype)
	fielder.age = 18 + (abs(hash(next_player_id)) % 4)
	fielder.years_pro = 1
	fielder.salary = clampi(int(fielder.salary) / 2, 200, 1500)
	fielder.morale = 55
	fielder.condition = 60
	fielder.fatigue = 0
	if slot == "UT":
		fielder.secondary_positions.clear()
		for util_position in ["2B", "3B", "SS", "LF", "CF", "RF"]:
			fielder.secondary_positions.append(str(util_position))
	var scouting_boost: int = 0
	if team != null:
		scouting_boost = maxi(0, int(team.facilities.get("scouting", 1)) - 1) + maxi(0, int(team.staff.get("scouts", 1)) - 1)
		fielder.potential = clampi(int(fielder.potential) + scouting_boost * 2, 40, 99)
	fielder.overall = clampi(fielder.calc_overall() + scouting_boost, 1, 99)
	return fielder

func _register_new_player(team: TeamData, player: PlayerData) -> void:
	players[str(player.id)] = player
	team.player_ids.append(str(player.id))

func _allocate_next_player_id(team_id: String) -> String:
	var next_index: int = 1
	for existing_player_id in players.keys():
		var resolved_id: String = str(existing_player_id)
		if not resolved_id.begins_with(team_id + "_"):
			continue
		var suffix: String = resolved_id.trim_prefix(team_id + "_")
		if suffix.is_valid_int():
			next_index = maxi(next_index, int(suffix) + 1)
	return "%s_%03d" % [team_id, next_index]

func _rebuild_team_competitive_structures(team: TeamData) -> void:
	var starters: Array = []
	var closers: Array = []
	var relievers: Array = []
	var fielders: Array = []

	for player_id in team.player_ids:
		var player: PlayerData = get_player(str(player_id))
		if player == null:
			continue
		match str(player.role):
			"starter":
				starters.append(player)
			"closer":
				closers.append(player)
			"reliever":
				relievers.append(player)
			_:
				fielders.append(player)

	starters.sort_custom(func(a, b):
		return int(a.overall) > int(b.overall)
	)
	closers.sort_custom(func(a, b):
		return int(a.overall) > int(b.overall)
	)
	relievers.sort_custom(func(a, b):
		return int(a.overall) > int(b.overall)
	)

	team.rotation_ids.clear()
	for starter in starters:
		team.rotation_ids.append(str(starter.id))

	team.bullpen["closer"] = ""
	team.bullpen["setup"] = []
	team.bullpen["middle"] = []
	team.bullpen["long"] = ""

	var bullpen_pool: Array = relievers.duplicate()
	if not closers.is_empty():
		team.bullpen["closer"] = str(closers[0].id)
	else:
		if not bullpen_pool.is_empty():
			team.bullpen["closer"] = str(bullpen_pool[0].id)
			bullpen_pool.remove_at(0)

	for reliever_index in range(bullpen_pool.size()):
		var reliever_player: PlayerData = bullpen_pool[reliever_index]
		if reliever_index < 2:
			team.bullpen["setup"].append(str(reliever_player.id))
		else:
			team.bullpen["middle"].append(str(reliever_player.id))

	if not team.bullpen["middle"].is_empty():
		team.bullpen["long"] = str(team.bullpen["middle"][team.bullpen["middle"].size() - 1])

	team.lineup_vs_r = PlayerFactory._build_lineup(fielders, false)
	team.lineup_vs_l = PlayerFactory._build_lineup(fielders, true)

	var used_ids: Array[String] = []
	for lineup_player_id in team.lineup_vs_r:
		if not used_ids.has(str(lineup_player_id)):
			used_ids.append(str(lineup_player_id))
	for lineup_player_id in team.lineup_vs_l:
		if not used_ids.has(str(lineup_player_id)):
			used_ids.append(str(lineup_player_id))

	team.bench_ids.clear()
	for fielder in fielders:
		if not used_ids.has(str(fielder.id)):
			team.bench_ids.append(str(fielder.id))

	normalize_team_bullpen(team)

func simulate_to_end_of_season() -> void:
	var final_game_day: int = get_final_game_day()

	while current_day <= final_game_day:
		simulate_current_day()
		if current_day < final_game_day:
			advance_day()
		else:
			break

func simulate_days(day_count: int) -> Dictionary:
	var simulated_days: int = 0
	var played_games: int = 0
	var last_simulated_day: int = -1
	var start_date_label: String = ""
	var end_date_label: String = ""
	var calendar_days_passed: int = 0
	var end_info: Dictionary = {}
	var transition_count: int = 0
	var last_transition_headline: String = ""

	if day_count <= 0:
		return {
			"simulated_days": simulated_days,
			"played_games": played_games,
			"last_simulated_day": last_simulated_day,
			"start_date_label": start_date_label,
			"end_date_label": end_date_label,
			"calendar_days_passed": calendar_days_passed,
			"transition_count": transition_count,
			"transition_headline": last_transition_headline,
			"season_finished": current_day > get_last_day()
		}

	start_date_label = get_current_date_label()
	var start_info: Dictionary = get_date_info_for_day(current_day)

	while simulated_days < day_count:
		last_simulated_day = current_day
		end_info = get_date_info_for_day(current_day)
		end_date_label = str(end_info.get("date_label", ""))
		var games_today: Array = simulate_current_day()
		played_games += games_today.size()
		simulated_days += 1

		var transition_report: Array[String] = complete_day_transition()
		if not transition_report.is_empty():
			transition_count += 1
			last_transition_headline = str(transition_report[0])

	if last_simulated_day > 0 and not end_info.is_empty():
		calendar_days_passed = _calc_calendar_day_span(
			int(start_info["year"]),
			int(start_info["month"]),
			int(start_info["day"]),
			int(end_info["year"]),
			int(end_info["month"]),
			int(end_info["day"])
		) + 1

	return {
		"simulated_days": simulated_days,
		"played_games": played_games,
		"last_simulated_day": last_simulated_day,
		"start_date_label": start_date_label,
		"end_date_label": end_date_label,
		"calendar_days_passed": calendar_days_passed,
		"transition_count": transition_count,
		"transition_headline": last_transition_headline,
		"season_finished": false
	}

func _calc_calendar_day_span(start_year: int, start_month: int, start_day_of_month: int, end_year: int, end_month: int, end_day_of_month: int) -> int:
	var days: int = 0
	var current_year: int = start_year
	var current_month: int = start_month
	var current_day_of_month: int = start_day_of_month

	while current_year != end_year or current_month != end_month or current_day_of_month != end_day_of_month:
		var next_date: Dictionary = _advance_date(current_year, current_month, current_day_of_month)
		current_year = int(next_date["year"])
		current_month = int(next_date["month"])
		current_day_of_month = int(next_date["day"])
		days += 1

	return days

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
		"controlled_team_id": controlled_team_id,
		"selected_game_id": selected_game_id,
		"selected_match_mode": selected_match_mode,
		"active_live_game_id": active_live_game_id,
		"prepared_day": prepared_day,
		"finalized_finance_day": finalized_finance_day,
		"pending_home_message": pending_home_message,
		"recent_events": recent_events.duplicate(),
		"last_offseason_report": last_offseason_report.duplicate(),
		"recent_finance_log": recent_finance_log.duplicate(),
		"last_controlled_team_roster_log": last_controlled_team_roster_log.duplicate(),
		"season_history": season_history.duplicate(true),
		"annual_operation_status": annual_operation_status.duplicate(true),
		"annual_operation_log": annual_operation_log.duplicate(true),
		"daily_team_bonuses": daily_team_bonuses.duplicate(true),
		"teams": team_dict,
		"players": player_dict,
		"schedule": schedule_list
	}

func load_from_dict(data: Dictionary) -> void:
	season_year = int(data.get("season_year", 1))
	current_day = int(data.get("current_day", 1))
	controlled_team_id = str(data.get("controlled_team_id", ""))
	selected_game_id = str(data.get("selected_game_id", ""))
	selected_match_mode = str(data.get("selected_match_mode", "replay"))
	active_live_game_id = str(data.get("active_live_game_id", ""))
	prepared_day = int(data.get("prepared_day", 0))
	finalized_finance_day = int(data.get("finalized_finance_day", 0))
	pending_home_message = str(data.get("pending_home_message", ""))
	recent_events.clear()
	for event_text in data.get("recent_events", []):
		recent_events.append(str(event_text))
	last_offseason_report.clear()
	for report_line in data.get("last_offseason_report", []):
		last_offseason_report.append(str(report_line))
	recent_finance_log.clear()
	for finance_line in data.get("recent_finance_log", []):
		recent_finance_log.append(str(finance_line))
	last_controlled_team_roster_log.clear()
	for roster_line in data.get("last_controlled_team_roster_log", []):
		last_controlled_team_roster_log.append(str(roster_line))
	season_history.clear()
	for history_entry in data.get("season_history", []):
		if history_entry is Dictionary:
			season_history.append((history_entry as Dictionary).duplicate(true))
	annual_operation_status = data.get("annual_operation_status", {}).duplicate(true)
	annual_operation_log = data.get("annual_operation_log", {}).duplicate(true)
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

	if schedule.is_empty():
		_generate_schedule()

	_normalize_schedule_metadata()

	current_day = clampi(current_day, 1, get_last_day())

	_normalize_all_teams()
	_sanitize_match_selection_state()

	if controlled_team_id != "" and not teams.has(controlled_team_id):
		controlled_team_id = ""

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
		var league_key: String = _get_team_league_key(str(team.id))
		result.append({
			"id": team.id,
			"name": team.name,
			"league": league_key,
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

func _get_team_league_key(team_id: String) -> String:
	for team_info in team_master:
		if str(team_info.get("id", "")) == team_id:
			return str(team_info.get("league", ""))
	return ""

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
