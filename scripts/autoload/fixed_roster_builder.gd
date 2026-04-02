extends Node

const TEAM_DATA_SCRIPT = preload("res://scripts/data/team_data.gd")
const PLAYER_DATA_SCRIPT = preload("res://scripts/data/player_data.gd")
const OPENING_SUPPLEMENTS_SCRIPT = preload("res://scripts/data/opening_roster_supplements.gd")

const POSITIONS: Array[String] = ["C", "1B", "2B", "3B", "SS", "LF", "CF", "RF", "DH"]
const FILLER_LAST_NAMES: Array[String] = [
	"真壁", "朝倉", "水城", "岸田", "高槻", "榊", "冬木", "有賀",
	"神崎", "松代", "高砂", "伊吹", "相馬", "久瀬", "青柳", "新田"
]
const FILLER_FIRST_NAMES: Array[String] = [
	"蓮", "湊", "蒼", "晴斗", "悠真", "修司", "颯太", "岳",
	"迅", "隼人", "玲央", "智也", "直樹", "亮介", "海斗", "陽翔"
]

func build_opening_team(blueprint: Dictionary) -> Dictionary:
	var team = TEAM_DATA_SCRIPT.new()
	team.id = str(blueprint.get("id", ""))
	team.name = str(blueprint.get("name", ""))
	team.short_name = str(blueprint.get("short_name", team.name))
	team.strategy = _map_style_to_strategy(str(blueprint.get("style", "balanced")))
	team.budget = int(blueprint.get("budget", 100000))
	team.fan_support = int(blueprint.get("fan_support", 50))

	var created_players: Array = []
	var existing_names: Dictionary = {}
	var player_index: int = 1

	for player_def in blueprint.get("core_players", []):
		var player = _build_player_from_definition(team.id, player_index, player_def)
		player_index += 1
		created_players.append(player)
		existing_names[player.full_name] = true

	for player_def in OPENING_SUPPLEMENTS_SCRIPT.get_team_supplements(team.id):
		var player = _build_player_from_definition(team.id, player_index, player_def)
		player_index += 1
		created_players.append(player)
		existing_names[player.full_name] = true

	_fill_pitchers(team.id, created_players, existing_names, player_index, str(blueprint.get("style", "balanced")))
	player_index = created_players.size() + 1
	_fill_fielders(team.id, created_players, existing_names, player_index, str(blueprint.get("style", "balanced")))

	for player in created_players:
		team.player_ids.append(str(player.id))

	_finalize_team_depth_chart(team, created_players)
	_expand_registered_depth(team.id, created_players, existing_names, str(blueprint.get("style", "balanced")))
	_add_development_players(team.id, created_players, existing_names, str(blueprint.get("style", "balanced")))
	_refresh_team_player_ids(team, created_players)
	_mark_opening_roster_status(team, created_players)

	return {
		"team": team,
		"players": created_players
	}

func _build_player_from_definition(team_id: String, index: int, data: Dictionary):
	var player = PLAYER_DATA_SCRIPT.new()
	player.id = "%s_FIX_%03d" % [team_id, index]
	player.full_name = str(data.get("name", "選手"))
	player.role = str(data.get("role", "fielder"))
	player.primary_position = str(data.get("pos", "CF"))
	player.throws = str(data.get("throws", "R"))
	player.bats = str(data.get("bats", "R"))
	player.is_foreign = bool(data.get("foreign", false))
	player.registration_type = "registered"
	player.roster_status = "farm"
	player.age = int(data.get("age", 25))
	player.overall = int(data.get("overall", 65))
	player.potential = int(data.get("potential", player.overall + 5))
	player.salary = int(data.get("salary", 3000))
	player.years_pro = maxi(1, player.age - 18)
	player.contract_years_left = 2 if player.is_foreign else 3
	player.desired_salary = int(round(float(player.salary) * 1.05))
	player.fa_interest = 62 if player.is_foreign else 45
	player.traits.clear()
	for trait_name in data.get("traits", []):
		player.traits.append(str(trait_name))
	_assign_rating_profile(player, str(data.get("archetype", "")))
	player.overall = player.calc_overall()
	return player

func _fill_pitchers(team_id: String, created_players: Array, existing_names: Dictionary, start_index: int, style: String) -> void:
	var index := start_index
	var starter_count := 0
	var reliever_count := 0
	var closer_count := 0

	for player in created_players:
		if str(player.role) == "starter":
			starter_count += 1
		elif str(player.role) == "reliever":
			reliever_count += 1
		elif str(player.role) == "closer":
			closer_count += 1

	while starter_count < 6:
		var player = _build_filler_pitcher(team_id, index, existing_names, "starter", style, starter_count)
		index += 1
		created_players.append(player)
		starter_count += 1

	while reliever_count < 6:
		var player = _build_filler_pitcher(team_id, index, existing_names, "reliever", style, reliever_count)
		index += 1
		created_players.append(player)
		reliever_count += 1

	while closer_count < 1:
		var player = _build_filler_pitcher(team_id, index, existing_names, "closer", style, closer_count)
		index += 1
		created_players.append(player)
		closer_count += 1

func _fill_fielders(team_id: String, created_players: Array, existing_names: Dictionary, start_index: int, style: String) -> void:
	var index := start_index
	var position_counts: Dictionary = {}
	for player in created_players:
		if str(player.role) == "fielder":
			var pos: String = str(player.primary_position)
			position_counts[pos] = int(position_counts.get(pos, 0)) + 1

	var targets := {
		"C": 2, "1B": 2, "2B": 2, "3B": 2, "SS": 2,
		"LF": 2, "CF": 2, "RF": 2, "DH": 1
	}

	for pos in POSITIONS:
		while int(position_counts.get(pos, 0)) < int(targets[pos]):
			var player = _build_filler_fielder(team_id, index, existing_names, pos, style, int(position_counts.get(pos, 0)))
			index += 1
			created_players.append(player)
			position_counts[pos] = int(position_counts.get(pos, 0)) + 1

	while created_players.size() < 25:
		var util_positions: Array[String] = ["2B", "3B", "SS", "LF", "CF", "RF"]
		var player = _build_filler_fielder(team_id, index, existing_names, util_positions[(index - 1) % util_positions.size()], style, 2)
		player.secondary_positions.clear()
		for pos in util_positions:
			player.secondary_positions.append(pos)
		index += 1
		created_players.append(player)

func _build_filler_pitcher(team_id: String, index: int, existing_names: Dictionary, role_name: String, style: String, slot_index: int):
	var player = PLAYER_DATA_SCRIPT.new()
	player.id = "%s_FIX_%03d" % [team_id, index]
	player.full_name = _roll_unique_name(team_id, index, existing_names)
	player.role = role_name
	player.primary_position = "P"
	player.throws = "L" if index % 5 == 0 else "R"
	player.bats = player.throws
	player.age = 21 + ((index + slot_index) % 11)
	player.years_pro = maxi(1, player.age - 18)
	player.contract_years_left = 3
	player.registration_type = "registered"
	player.roster_status = "farm"
	player.fa_interest = 42
	player.salary = 1400 + slot_index * 300
	player.desired_salary = int(round(float(player.salary) * 1.08))
	var base_overall := 61
	if style == "pitching":
		base_overall += 3
	elif style == "power":
		base_overall -= 1
	if role_name == "starter":
		base_overall += 2
	elif role_name == "closer":
		base_overall += 3
	player.overall = base_overall + (slot_index % 3)
	player.potential = player.overall + 6
	_assign_rating_profile(player, role_name)
	player.overall = player.calc_overall()
	return player

func _build_filler_fielder(team_id: String, index: int, existing_names: Dictionary, pos: String, style: String, slot_index: int):
	var player = PLAYER_DATA_SCRIPT.new()
	player.id = "%s_FIX_%03d" % [team_id, index]
	player.full_name = _roll_unique_name(team_id, index, existing_names)
	player.role = "fielder"
	player.primary_position = pos
	player.throws = "R"
	player.bats = "L" if index % 4 == 0 else "R"
	player.age = 20 + ((index + slot_index) % 13)
	player.years_pro = maxi(1, player.age - 18)
	player.contract_years_left = 3
	player.registration_type = "registered"
	player.roster_status = "farm"
	player.fa_interest = 44
	player.salary = 1200 + slot_index * 220
	player.desired_salary = int(round(float(player.salary) * 1.08))
	var base_overall := 60
	if style == "power" and (pos == "1B" or pos == "LF" or pos == "RF" or pos == "DH"):
		base_overall += 3
	elif style == "speed" and (pos == "2B" or pos == "CF" or pos == "SS"):
		base_overall += 3
	elif style == "defense" and (pos == "C" or pos == "SS" or pos == "CF"):
		base_overall += 2
	player.overall = base_overall + (slot_index % 4)
	player.potential = player.overall + 7
	_assign_rating_profile(player, pos)
	player.overall = player.calc_overall()
	return player

func _assign_rating_profile(player, archetype: String) -> void:
	if player.is_pitcher():
		player.ratings["velocity"] = 55 + (player.overall - 55) + (_bonus_if(archetype in ["starter", "closer"], 2))
		player.ratings["control"] = 50 + int((player.overall - 55) * 0.8)
		player.ratings["stamina"] = 68 if str(player.role) == "starter" else 42
		player.ratings["break"] = 50 + int((player.overall - 55) * 0.9)
		player.ratings["k_rate"] = 52 + int((player.overall - 55) * 0.9)
		player.ratings["composure"] = 50 + int((player.overall - 55) * 0.7)
		player.pitch_types.clear()
		player.pitch_types.append("4SFB")
		player.pitch_types.append("SL")
		player.pitch_types.append("CH")
		if str(player.role) == "closer":
			player.pitch_types.clear()
			player.pitch_types.append("4SFB")
			player.pitch_types.append("CUT")
			player.pitch_types.append("SFF")
		return

	player.ratings["contact"] = 48 + int((player.overall - 55) * 0.9)
	player.ratings["power"] = 45 + int((player.overall - 55) * 0.8)
	player.ratings["eye"] = 46 + int((player.overall - 55) * 0.7)
	player.ratings["speed"] = 44 + int((player.overall - 55) * 0.7)
	player.ratings["fielding"] = 48 + int((player.overall - 55) * 0.8)
	player.ratings["arm"] = 46 + int((player.overall - 55) * 0.6)
	player.ratings["catching"] = 35 + int((player.overall - 55) * 0.6)
	if archetype == "C":
		player.ratings["catching"] += 18
		player.ratings["fielding"] += 8
	elif archetype == "SS" or archetype == "CF":
		player.ratings["fielding"] += 10
		player.ratings["speed"] += 6
	elif archetype == "1B" or archetype == "DH":
		player.ratings["power"] += 10

func _finalize_team_depth_chart(team, created_players: Array) -> void:
	var starters: Array = []
	var relievers: Array = []
	var closers: Array = []
	var fielders: Array = []
	for player in created_players:
		if str(player.role) == "starter":
			starters.append(player)
		elif str(player.role) == "reliever":
			relievers.append(player)
		elif str(player.role) == "closer":
			closers.append(player)
		else:
			fielders.append(player)

	starters.sort_custom(func(a, b): return int(a.overall) > int(b.overall))
	relievers.sort_custom(func(a, b): return int(a.overall) > int(b.overall))
	fielders.sort_custom(func(a, b): return int(a.overall) > int(b.overall))

	team.rotation_ids.clear()
	for starter in starters:
		team.rotation_ids.append(str(starter.id))

	team.bullpen["closer"] = str(closers[0].id) if closers.size() > 0 else ""
	team.bullpen["setup"] = []
	team.bullpen["middle"] = []
	team.bullpen["long"] = ""
	if relievers.size() > 0:
		team.bullpen["long"] = str(relievers[relievers.size() - 1].id)
	for i in range(mini(2, relievers.size())):
		team.bullpen["setup"].append(str(relievers[i].id))
	for i in range(2, relievers.size()):
		team.bullpen["middle"].append(str(relievers[i].id))

	team.lineup_vs_r.clear()
	for player_id in _build_lineup(fielders, false):
		team.lineup_vs_r.append(player_id)
	team.lineup_vs_l.clear()
	for player_id in _build_lineup(fielders, true):
		team.lineup_vs_l.append(player_id)

	team.bench_ids.clear()
	var used_ids: Dictionary = {}
	for player_id in team.lineup_vs_r:
		used_ids[str(player_id)] = true
	for player_id in team.lineup_vs_l:
		used_ids[str(player_id)] = true
	for fielder in fielders:
		if not used_ids.has(str(fielder.id)):
			team.bench_ids.append(str(fielder.id))

func _expand_registered_depth(team_id: String, created_players: Array, existing_names: Dictionary, style: String) -> void:
	var index: int = created_players.size() + 1
	var pitcher_target: int = 28
	var catcher_target: int = 4
	var infielder_target: int = 18
	var outfielder_target: int = 16

	while _count_registered_pitchers(created_players) < pitcher_target:
		var role_name: String = "reliever"
		if _count_registered_starters(created_players) < 10:
			role_name = "starter"
		var player = _build_filler_pitcher(team_id, index, existing_names, role_name, style, _count_registered_pitchers(created_players))
		index += 1
		created_players.append(player)

	while _count_registered_catchers(created_players) < catcher_target:
		var catcher = _build_filler_fielder(team_id, index, existing_names, "C", style, _count_registered_catchers(created_players))
		index += 1
		created_players.append(catcher)

	while _count_registered_infielders(created_players) < infielder_target:
		var infield_positions: Array[String] = ["1B", "2B", "3B", "SS"]
		var fielder = _build_filler_fielder(team_id, index, existing_names, infield_positions[(index - 1) % infield_positions.size()], style, _count_registered_infielders(created_players))
		index += 1
		created_players.append(fielder)

	while _count_registered_outfielders(created_players) < outfielder_target:
		var outfield_positions: Array[String] = ["LF", "CF", "RF"]
		var outfielder = _build_filler_fielder(team_id, index, existing_names, outfield_positions[(index - 1) % outfield_positions.size()], style, _count_registered_outfielders(created_players))
		index += 1
		created_players.append(outfielder)

func _add_development_players(team_id: String, created_players: Array, existing_names: Dictionary, style: String) -> void:
	var index: int = created_players.size() + 1
	while _count_development_players(created_players) < 6:
		var player
		if _count_development_pitchers(created_players) < 3:
			player = _build_filler_pitcher(team_id, index, existing_names, "reliever", style, _count_development_players(created_players))
		else:
			var dev_positions: Array[String] = ["C", "SS", "CF", "1B", "3B", "RF"]
			player = _build_filler_fielder(team_id, index, existing_names, dev_positions[(index - 1) % dev_positions.size()], style, _count_development_players(created_players))
		player.age = 18 + (index % 3)
		player.years_pro = 1
		player.salary = 320
		player.desired_salary = 380
		player.registration_type = "development"
		player.roster_status = "development"
		player.potential += 4
		index += 1
		created_players.append(player)

func _refresh_team_player_ids(team, created_players: Array) -> void:
	team.player_ids.clear()
	for player in created_players:
		team.player_ids.append(str(player.id))

func _mark_opening_roster_status(team, created_players: Array) -> void:
	var active_ids: Dictionary = {}
	for player_id in team.lineup_vs_r:
		active_ids[str(player_id)] = true
	for player_id in team.lineup_vs_l:
		active_ids[str(player_id)] = true
	for player_id in team.bench_ids:
		active_ids[str(player_id)] = true
	for player_id in team.rotation_ids:
		active_ids[str(player_id)] = true
	active_ids[str(team.bullpen.get("closer", ""))] = true
	active_ids[str(team.bullpen.get("long", ""))] = true
	for player_id in team.bullpen.get("setup", []):
		active_ids[str(player_id)] = true
	for player_id in team.bullpen.get("middle", []):
		active_ids[str(player_id)] = true

	for player in created_players:
		if str(player.registration_type) == "development":
			player.roster_status = "development"
		elif active_ids.has(str(player.id)):
			player.roster_status = "active"
		else:
			player.roster_status = "farm"

func _count_registered_pitchers(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) == "registered" and player.is_pitcher():
			count += 1
	return count

func _count_registered_starters(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) == "registered" and str(player.role) == "starter":
			count += 1
	return count

func _count_registered_catchers(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) == "registered" and not player.is_pitcher() and str(player.primary_position) == "C":
			count += 1
	return count

func _count_registered_infielders(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) != "registered" or player.is_pitcher():
			continue
		if ["1B", "2B", "3B", "SS"].has(str(player.primary_position)):
			count += 1
	return count

func _count_registered_outfielders(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) != "registered" or player.is_pitcher():
			continue
		if ["LF", "CF", "RF", "DH"].has(str(player.primary_position)):
			count += 1
	return count

func _count_development_players(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) == "development":
			count += 1
	return count

func _count_development_pitchers(created_players: Array) -> int:
	var count := 0
	for player in created_players:
		if str(player.registration_type) == "development" and player.is_pitcher():
			count += 1
	return count

func _build_lineup(fielders: Array, versus_left: bool) -> Array[String]:
	var defense_order: Array[String] = ["C", "1B", "2B", "3B", "SS", "LF", "CF", "RF", "DH"]
	var used_ids: Dictionary = {}
	var lineup: Array[String] = []
	for target_pos in defense_order:
		var candidates: Array = []
		for player in fielders:
			if used_ids.has(str(player.id)):
				continue
			if str(player.primary_position) == target_pos or target_pos in player.secondary_positions:
				candidates.append(player)
		if candidates.is_empty():
			for player in fielders:
				if not used_ids.has(str(player.id)):
					candidates.append(player)
		candidates.sort_custom(func(a, b): return _attack_score(a, versus_left) > _attack_score(b, versus_left))
		if candidates.is_empty():
			continue
		var picked = candidates[0]
		lineup.append(str(picked.id))
		used_ids[str(picked.id)] = true
	return lineup

func _attack_score(player, versus_left: bool) -> float:
	var split_bonus := 0.0
	if versus_left:
		split_bonus += (float(player.ratings.get("vs_left", 50)) - 50.0) * 0.6
	return float(player.ratings["contact"]) * 0.33 + float(player.ratings["power"]) * 0.30 + float(player.ratings["eye"]) * 0.17 + float(player.ratings["speed"]) * 0.10 + split_bonus

func _roll_unique_name(team_id: String, index: int, existing_names: Dictionary) -> String:
	var last_name: String = FILLER_LAST_NAMES[(index + team_id.length()) % FILLER_LAST_NAMES.size()]
	var first_name: String = FILLER_FIRST_NAMES[(index * 3 + team_id.unicode_at(0)) % FILLER_FIRST_NAMES.size()]
	var full_name := "%s %s" % [last_name, first_name]
	var suffix := 1
	while existing_names.has(full_name):
		full_name = "%s %s%d" % [last_name, first_name, suffix]
		suffix += 1
	existing_names[full_name] = true
	return full_name

func _map_style_to_strategy(style: String) -> String:
	match style:
		"power":
			return "power"
		"speed":
			return "speed"
		"defense":
			return "defense"
		"pitching":
			return "pitching"
		_:
			return "balanced"

func _bonus_if(condition: bool, amount: int) -> int:
	return amount if condition else 0
