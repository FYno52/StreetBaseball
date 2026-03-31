extends Node

const TEAM_DATA_SCRIPT = preload("res://scripts/data/team_data.gd")
const PLAYER_DATA_SCRIPT = preload("res://scripts/data/player_data.gd")
const GAME_DATA_SCRIPT = preload("res://scripts/data/game_data.gd")
const START_SEASON_YEAR := 2026
const SEASON_START_MONTH := 3
const SEASON_START_DAY := 27
const WEEKDAY_NAMES := ["日", "月", "火", "水", "木", "金", "土"]
const DESIRED_FIELDER_SLOTS: Array[String] = ["C", "C", "1B", "1B", "2B", "2B", "3B", "3B", "SS", "SS", "LF", "CF", "RF", "DH", "UT"]

var season_year: int = START_SEASON_YEAR
var current_day: int = 1
var controlled_team_id: String = ""
var selected_player_id: String = ""

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

var team_master: Array[Dictionary] = [
	{"id": "TKY", "name": "東京フェニックス"},
	{"id": "OSK", "name": "大阪ブレイバーズ"},
	{"id": "NGY", "name": "名古屋スティング"},
	{"id": "SPP", "name": "札幌ホワイトベアーズ"},
	{"id": "FKO", "name": "福岡サンダース"},
	{"id": "SDI", "name": "仙台フォックス"}
]

func reset() -> void:
	season_year = START_SEASON_YEAR
	current_day = 1
	controlled_team_id = ""
	selected_player_id = ""
	teams.clear()
	players.clear()
	schedule.clear()
	recent_events.clear()
	daily_team_bonuses.clear()
	last_offseason_report.clear()
	recent_finance_log.clear()
	last_controlled_team_roster_log.clear()
	latest_integrity_notes.clear()

func new_game() -> void:
	reset()

	for team_info in team_master:
		var generated: Dictionary = PlayerFactory.generate_team_roster(str(team_info["id"]), str(team_info["name"]))
		var team = generated["team"]
		var roster: Array = generated["players"]

		teams[str(team.id)] = team

		for p in roster:
			players[str(p.id)] = p

	_normalize_all_teams()
	_generate_schedule()

func start_new_season() -> Array[String]:
	var previous_year: int = season_year
	season_year += 1
	current_day = 1
	recent_events.clear()
	daily_team_bonuses.clear()
	last_offseason_report = _run_offseason(previous_year, season_year)
	recent_finance_log.clear()
	last_controlled_team_roster_log.clear()

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

func get_controlled_team() -> TeamData:
	if controlled_team_id == "":
		return null
	return get_team(controlled_team_id)

func _generate_schedule() -> void:
	schedule.clear()

	var ids: Array[String] = []
	for team_info in team_master:
		ids.append(str(team_info["id"]))

	var series_rounds: Array = _build_series_rounds(ids)
	var series_date_blocks: Array = _build_series_date_blocks(series_rounds.size())
	var day: int = 1
	var game_index: int = 1

	for round_index in range(series_rounds.size()):
		var pairings: Array = series_rounds[round_index]
		var date_block: Array = series_date_blocks[round_index]
		for slot in date_block:
			for pairing in pairings:
				var game: GameData = GAME_DATA_SCRIPT.new()
				game.id = "G_%03d" % game_index
				game.day = day
				game.season_year = season_year
				game.month = int(slot["month"])
				game.day_of_month = int(slot["day"])
				game.weekday_index = int(slot["weekday_index"])
				game.weekday_name = str(slot["weekday_name"])
				game.date_label = str(slot["date_label"])
				game.away_team_id = str(pairing["away_team_id"])
				game.home_team_id = str(pairing["home_team_id"])
				schedule.append(game)
				game_index += 1
			day += 1

func _build_series_rounds(team_ids: Array[String]) -> Array:
	var rounds: Array = []
	if team_ids.size() < 2:
		return rounds

	var base_rounds: Array = _build_round_robin_rounds(team_ids)
	for cycle in range(4):
		for round_index in range(base_rounds.size()):
			var pairings: Array = []
			var base_round: Array = base_rounds[round_index]
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
			rounds.append(pairings)
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

func _build_series_date_blocks(block_count: int) -> Array:
	var result: Array = []
	var year: int = season_year
	var month: int = SEASON_START_MONTH
	var day_of_month: int = SEASON_START_DAY

	while result.size() < block_count:
		var weekday_index: int = _get_weekday_index(year, month, day_of_month)
		if weekday_index == 2 or weekday_index == 5:
			var block: Array = []
			var block_year: int = year
			var block_month: int = month
			var block_day: int = day_of_month
			for _index in range(3):
				var block_weekday: int = _get_weekday_index(block_year, block_month, block_day)
				block.append({
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
			continue

		var next_regular_date: Dictionary = _advance_date(year, month, day_of_month)
		year = int(next_regular_date["year"])
		month = int(next_regular_date["month"])
		day_of_month = int(next_regular_date["day"])

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

func get_date_label_for_day(day: int) -> String:
	for game in schedule:
		if int(game.day) == day:
			return str(game.date_label)
	return "%04d-%02d-%02d" % [season_year, SEASON_START_MONTH, SEASON_START_DAY]

func get_date_info_for_day(day: int) -> Dictionary:
	for game in schedule:
		if int(game.day) == day:
			return {
				"year": int(game.season_year),
				"month": int(game.month),
				"day": int(game.day_of_month),
				"weekday_index": int(game.weekday_index),
				"weekday_name": str(game.weekday_name),
				"date_label": str(game.date_label)
			}
	return {
		"year": season_year,
		"month": SEASON_START_MONTH,
		"day": SEASON_START_DAY,
		"weekday_index": _get_weekday_index(season_year, SEASON_START_MONTH, SEASON_START_DAY),
		"weekday_name": WEEKDAY_NAMES[_get_weekday_index(season_year, SEASON_START_MONTH, SEASON_START_DAY)],
		"date_label": "%04d-%02d-%02d(%s)" % [season_year, SEASON_START_MONTH, SEASON_START_DAY, WEEKDAY_NAMES[_get_weekday_index(season_year, SEASON_START_MONTH, SEASON_START_DAY)]]
	}

func get_current_date_label() -> String:
	var target_day: int = current_day
	if current_day > get_last_day():
		target_day = get_last_day()
	if target_day <= 0:
		target_day = 1
	return get_date_label_for_day(target_day)

func advance_day() -> void:
	current_day += 1

func all_team_ids() -> Array[String]:
	var result: Array[String] = []
	for key in teams.keys():
		result.append(str(key))
	return result

func simulate_current_day() -> Array:
	_normalize_all_teams()
	var games_today: Array = get_games_for_day(current_day)
	var event_pack: Dictionary = _generate_daily_events(current_day)
	recent_events = event_pack.get("texts", [])
	daily_team_bonuses = event_pack.get("bonuses", {})

	for game in games_today:
		var away_team = get_team(str(game.away_team_id))
		var home_team = get_team(str(game.home_team_id))
		SimulationEngine.simulate_game(game, away_team, home_team)

	_apply_daily_finances(current_day, games_today)

	return games_today

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
		latest_integrity_notes.append("%s の人数不足を補充しました" % team.name)

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
		latest_integrity_notes.append("%s の起用データを再構築しました" % team.name)
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
		latest_integrity_notes.append("%s の無効な選手IDを %d 件整理しました" % [team.name, removed_missing_players])
	if cleaned_bench_ids.size() != original_bench_size:
		latest_integrity_notes.append("%s のベンチ構成を整理しました" % team.name)

func get_latest_integrity_notes() -> Array[String]:
	return latest_integrity_notes.duplicate()

func get_integrity_audit() -> Array[String]:
	var issues: Array[String] = []
	if schedule.is_empty():
		issues.append("日程が空です")
	if current_day < 1:
		issues.append("現在日が不正です")
	if current_day > get_last_day() + 1:
		issues.append("現在日が最終日を超えすぎています")
	if controlled_team_id != "" and not teams.has(controlled_team_id):
		issues.append("担当球団IDが無効です")

	for team_id in teams.keys():
		var team: TeamData = teams[team_id]
		if team == null:
			issues.append("チームデータが null です: %s" % str(team_id))
			continue

		if team.player_ids.is_empty():
			issues.append("%s の登録選手がいません" % team.name)
		if team.rotation_ids.is_empty():
			issues.append("%s の先発ローテが空です" % team.name)
		if team.lineup_vs_r.size() < 9:
			issues.append("%s の対右打線が不足しています" % team.name)
		if team.lineup_vs_l.size() < 9:
			issues.append("%s の対左打線が不足しています" % team.name)

		var missing_players: int = 0
		for player_id in team.player_ids:
			if get_player(str(player_id)) == null:
				missing_players += 1
		if missing_players > 0:
			issues.append("%s に無効な選手IDが %d 件あります" % [team.name, missing_players])

	if issues.is_empty():
		issues.append("監査OK")
	return issues

func get_recent_events() -> Array[String]:
	return recent_events.duplicate()

func get_last_offseason_report() -> Array[String]:
	return last_offseason_report.duplicate()

func get_recent_finance_log() -> Array[String]:
	return recent_finance_log.duplicate()

func get_last_controlled_team_roster_log() -> Array[String]:
	return last_controlled_team_roster_log.duplicate()

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
	var base_income: int = 800 + int(team.fan_support) * 18
	var venue_bonus: int = 900 if is_home_game else 250
	var performance_bonus: int = int(team.standings["wins"]) * 15
	var game_income: int = base_income + venue_bonus + performance_bonus
	var travel_cost: int = 120 if is_home_game else 420
	var net_change: int = game_income - payroll_cost - travel_cost

	team.budget = maxi(0, int(team.budget) + net_change)

	if str(team.id) == controlled_team_id:
		var line: String = "%s  収支 %s%d  入場+%d  人件費-%d  %s-%d" % [
			get_date_label_for_day(day),
			"+" if net_change >= 0 else "",
			net_change,
			game_income,
			payroll_cost,
			"運営費" if is_home_game else "遠征費",
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
	var last_day: int = 1

	for game in schedule:
		if int(game.day) > last_day:
			last_day = int(game.day)

	return last_day

func _run_offseason(previous_year: int, next_year: int) -> Array[String]:
	var lines: Array[String] = []
	lines.append("%d年シーズン終了後のオフを処理しました。" % previous_year)
	lines.append("%d年シーズンへ移行します。" % next_year)

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

	var roster_report: Array[String] = _process_retirements_and_replacements()
	for report_line in roster_report:
		lines.append(report_line)

	if champion_id != "":
		var champion_team: TeamData = get_team(champion_id)
		if champion_team != null:
			lines.append("前年優勝: %s" % champion_team.name)

	var controlled_team: TeamData = get_controlled_team()
	if controlled_team != null:
		lines.append("担当球団オフ結果: %s / 人気 %d / 予算 %d" % [controlled_team.name, int(controlled_team.fan_support), int(controlled_team.budget)])

	lines.append("選手の年齢・プロ年数・コンディションを更新しました。")
	return lines

func _apply_player_offseason(player: PlayerData) -> void:
	player.age += 1
	player.years_pro += 1
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
				last_controlled_team_roster_log.append("主な入れ替えはありません。")
			else:
				for retired_name in retired_names:
					last_controlled_team_roster_log.append("引退: %s" % retired_name)
				for added_name in added_names:
					last_controlled_team_roster_log.append("加入: %s" % added_name)

	if lines.is_empty():
		lines.append("オフの引退・補充はありませんでした。")
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
	var next_player_id: String = _allocate_next_player_id(team_id)
	var archetype: String = PlayerFactory._pick_pitcher_archetype(role_name)
	var pitcher: PlayerData = PlayerFactory.build_pitcher(next_player_id, role_name, archetype)
	pitcher.age = 18 + (abs(hash(next_player_id)) % 5)
	pitcher.years_pro = 1
	pitcher.salary = clampi(int(pitcher.salary) / 2, 250, 1800)
	pitcher.morale = 55
	pitcher.condition = 60
	pitcher.fatigue = 0
	pitcher.overall = pitcher.calc_overall()
	return pitcher

func _build_replacement_fielder(team_id: String, slot: String) -> PlayerData:
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
	fielder.overall = fielder.calc_overall()
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
	var last_day: int = get_last_day()

	while current_day <= last_day:
		simulate_current_day()

		if current_day < last_day:
			advance_day()
		else:
			break

func simulate_days(day_count: int) -> Dictionary:
	var simulated_days: int = 0
	var played_games: int = 0
	var last_simulated_day: int = -1
	var start_day: int = current_day
	var start_date_label: String = ""
	var end_date_label: String = ""
	var calendar_days_passed: int = 0

	if day_count <= 0:
		return {
			"simulated_days": simulated_days,
			"played_games": played_games,
			"last_simulated_day": last_simulated_day,
			"start_date_label": start_date_label,
			"end_date_label": end_date_label,
			"calendar_days_passed": calendar_days_passed,
			"season_finished": current_day > get_last_day()
		}

	start_date_label = get_date_label_for_day(start_day)

	while simulated_days < day_count and current_day <= get_last_day():
		last_simulated_day = current_day
		var games_today: Array = simulate_current_day()
		played_games += games_today.size()
		simulated_days += 1

		if current_day < get_last_day():
			advance_day()
		else:
			current_day = get_last_day() + 1
			break

	if last_simulated_day > 0:
		end_date_label = get_date_label_for_day(last_simulated_day)
		var start_info: Dictionary = get_date_info_for_day(start_day)
		var end_info: Dictionary = get_date_info_for_day(last_simulated_day)
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
		"season_finished": current_day > get_last_day()
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
		"recent_events": recent_events.duplicate(),
		"last_offseason_report": last_offseason_report.duplicate(),
		"recent_finance_log": recent_finance_log.duplicate(),
		"last_controlled_team_roster_log": last_controlled_team_roster_log.duplicate(),
		"daily_team_bonuses": daily_team_bonuses.duplicate(true),
		"teams": team_dict,
		"players": player_dict,
		"schedule": schedule_list
	}

func load_from_dict(data: Dictionary) -> void:
	season_year = int(data.get("season_year", 1))
	current_day = int(data.get("current_day", 1))
	controlled_team_id = str(data.get("controlled_team_id", ""))
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

	_normalize_all_teams()

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
