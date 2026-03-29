extends Node

const PLAYER_DATA_SCRIPT = preload("res://scripts/data/player_data.gd")
const TEAM_DATA_SCRIPT = preload("res://scripts/data/team_data.gd")

const POS_C := "C"
const POS_1B := "1B"
const POS_2B := "2B"
const POS_3B := "3B"
const POS_SS := "SS"
const POS_LF := "LF"
const POS_CF := "CF"
const POS_RF := "RF"
const POS_DH := "DH"

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var last_names: Array[String] = [
	"佐藤", "鈴木", "高橋", "田中", "伊藤", "渡辺", "山本", "中村",
	"小林", "加藤", "吉田", "山田", "斎藤", "松本", "井上", "木村"
]

var first_names: Array[String] = [
	"大輔", "悠人", "拓海", "蓮", "健太", "颯太", "翔", "陸",
	"隼人", "陽介", "直樹", "優斗", "和真", "雄太", "海斗", "凌"
]

func _ready() -> void:
	rng.randomize()

func test_random_name() -> String:
	return generate_name()

func generate_name() -> String:
	var last_name: String = last_names[rng.randi_range(0, last_names.size() - 1)]
	var first_name: String = first_names[rng.randi_range(0, first_names.size() - 1)]
	return "%s %s" % [last_name, first_name]

func rand_rating(min_v: int, max_v: int) -> int:
	return clampi(rng.randi_range(min_v, max_v), 1, 99)

func build_fielder(player_id: String, pos: String, archetype: String):
	var p = PLAYER_DATA_SCRIPT.new()

	p.id = player_id
	p.full_name = generate_name()
	p.age = rng.randi_range(18, 35)
	p.bats = ["R", "L", "S"][rng.randi_range(0, 2)]
	p.throws = ["R", "L"][rng.randi_range(0, 1)]
	p.role = "fielder"
	p.primary_position = pos
	p.development_type = ["early", "normal", "late"][rng.randi_range(0, 2)]
	p.potential = rng.randi_range(45, 90)
	p.salary = rng.randi_range(300, 3000)
	p.years_pro = maxi(1, p.age - 17)

	match archetype:
		"contact":
			p.ratings["contact"] = rand_rating(60, 85)
			p.ratings["power"] = rand_rating(30, 60)
			p.ratings["eye"] = rand_rating(55, 80)
			p.ratings["speed"] = rand_rating(45, 75)
		"slugger":
			p.ratings["contact"] = rand_rating(40, 65)
			p.ratings["power"] = rand_rating(65, 90)
			p.ratings["eye"] = rand_rating(35, 60)
			p.ratings["speed"] = rand_rating(25, 50)
		"speed":
			p.ratings["contact"] = rand_rating(45, 70)
			p.ratings["power"] = rand_rating(20, 45)
			p.ratings["eye"] = rand_rating(40, 65)
			p.ratings["speed"] = rand_rating(70, 95)
		"defense":
			p.ratings["contact"] = rand_rating(35, 60)
			p.ratings["power"] = rand_rating(20, 50)
			p.ratings["eye"] = rand_rating(35, 60)
			p.ratings["speed"] = rand_rating(50, 80)
		_:
			p.ratings["contact"] = rand_rating(40, 75)
			p.ratings["power"] = rand_rating(35, 75)
			p.ratings["eye"] = rand_rating(35, 75)
			p.ratings["speed"] = rand_rating(35, 75)

	match pos:
		POS_C:
			p.ratings["arm"] = rand_rating(45, 85)
			p.ratings["fielding"] = rand_rating(45, 85)
			p.ratings["catching"] = rand_rating(55, 95)
		POS_SS, POS_2B, POS_CF:
			p.ratings["arm"] = rand_rating(45, 85)
			p.ratings["fielding"] = rand_rating(60, 95)
			p.ratings["catching"] = rand_rating(35, 70)
		_:
			p.ratings["arm"] = rand_rating(35, 80)
			p.ratings["fielding"] = rand_rating(40, 85)
			p.ratings["catching"] = rand_rating(25, 60)

	p.overall = p.calc_overall()
	return p

func build_pitcher(player_id: String, role_name: String, archetype: String):
	var p = PLAYER_DATA_SCRIPT.new()

	p.id = player_id
	p.full_name = generate_name()
	p.age = rng.randi_range(18, 36)
	p.bats = ["R", "L"][rng.randi_range(0, 1)]
	p.throws = ["R", "L"][rng.randi_range(0, 1)]
	p.role = role_name
	p.primary_position = "P"
	p.development_type = ["early", "normal", "late"][rng.randi_range(0, 2)]
	p.potential = rng.randi_range(45, 92)
	p.salary = rng.randi_range(400, 3500)
	p.years_pro = maxi(1, p.age - 17)

	match archetype:
		"power":
			p.ratings["velocity"] = rand_rating(70, 95)
			p.ratings["control"] = rand_rating(35, 65)
			p.ratings["break"] = rand_rating(45, 75)
			p.ratings["k_rate"] = rand_rating(65, 95)
		"control":
			p.ratings["velocity"] = rand_rating(45, 75)
			p.ratings["control"] = rand_rating(65, 95)
			p.ratings["break"] = rand_rating(45, 75)
			p.ratings["k_rate"] = rand_rating(40, 70)
		"breaking":
			p.ratings["velocity"] = rand_rating(50, 80)
			p.ratings["control"] = rand_rating(45, 75)
			p.ratings["break"] = rand_rating(65, 95)
			p.ratings["k_rate"] = rand_rating(50, 85)
		_:
			p.ratings["velocity"] = rand_rating(45, 85)
			p.ratings["control"] = rand_rating(40, 80)
			p.ratings["break"] = rand_rating(40, 80)
			p.ratings["k_rate"] = rand_rating(45, 85)

	p.ratings["vs_left"] = rand_rating(35, 85)
	p.ratings["composure"] = rand_rating(35, 90)

	if role_name == "starter":
		p.ratings["stamina"] = rand_rating(60, 95)
	else:
		p.ratings["stamina"] = rand_rating(20, 60)

	var pitch_pool: Array[String] = ["4SFB", "2SFB", "SL", "CB", "CH", "SPL", "CUT", "SFF"]
	
	p.pitch_types.clear()
	p.pitch_types.append("4SFB")

	var target_pitch_count: int = rng.randi_range(2, 4)
	while p.pitch_types.size() < target_pitch_count:
		var pt: String = pitch_pool[rng.randi_range(0, pitch_pool.size() - 1)]
		if not p.pitch_types.has(pt):
			p.pitch_types.append(pt)

	p.overall = p.calc_overall()
	return p

func _pick_fielder_archetype(pos: String) -> String:
	if pos == POS_SS or pos == POS_2B or pos == POS_CF:
		return ["contact", "speed", "defense"][rng.randi_range(0, 2)]
	if pos == POS_1B:
		return ["slugger", "contact"][rng.randi_range(0, 1)]
	if pos == POS_C:
		return ["defense", "contact", "slugger"][rng.randi_range(0, 2)]
	return ["contact", "slugger", "speed", "defense"][rng.randi_range(0, 3)]

func _pick_pitcher_archetype(role_name: String) -> String:
	if role_name == "closer":
		return ["power", "breaking"][rng.randi_range(0, 1)]
	return ["power", "control", "breaking"][rng.randi_range(0, 2)]

func _sort_by_overall_desc(a, b) -> bool:
	return int(a.overall) > int(b.overall)

func _sort_fielder_attack_desc(a, b) -> bool:
	var av: int = int(a.ratings["contact"]) + int(a.ratings["power"]) + int(a.ratings["eye"]) + int(a.ratings["speed"])
	var bv: int = int(b.ratings["contact"]) + int(b.ratings["power"]) + int(b.ratings["eye"]) + int(b.ratings["speed"])
	return av > bv

func generate_team_roster(team_id: String, team_name: String) -> Dictionary:
	var team = TEAM_DATA_SCRIPT.new()
	team.id = team_id
	team.name = team_name
	team.short_name = team_name.substr(0, mini(2, team_name.length()))
	team.budget = rng.randi_range(80000, 150000)
	team.fan_support = rng.randi_range(35, 70)
	team.strategy = ["balanced", "power", "speed", "defense", "pitching"][rng.randi_range(0, 4)]

	var created_players: Array = []
	var player_index: int = 1

	for i in range(5):
		var p_starter = build_pitcher("%s_%03d" % [team_id, player_index], "starter", _pick_pitcher_archetype("starter"))
		player_index += 1
		created_players.append(p_starter)

	for i in range(4):
		var p_reliever = build_pitcher("%s_%03d" % [team_id, player_index], "reliever", _pick_pitcher_archetype("reliever"))
		player_index += 1
		created_players.append(p_reliever)

	var p_closer = build_pitcher("%s_%03d" % [team_id, player_index], "closer", _pick_pitcher_archetype("closer"))
	player_index += 1
	created_players.append(p_closer)

	var positions: Array[String] = [
		POS_C, POS_C,
		POS_1B, POS_1B,
		POS_2B, POS_2B,
		POS_3B, POS_3B,
		POS_SS, POS_SS,
		POS_LF,
		POS_CF,
		POS_RF,
		POS_DH,
		"UT"
	]

	for pos in positions:
		var base_pos: String
		if pos == "UT":
			var util_pool: Array[String] = [POS_2B, POS_3B, POS_SS, POS_LF, POS_CF, POS_RF]
			base_pos = util_pool[rng.randi_range(0, util_pool.size() - 1)]
		else:
			base_pos = pos

		var p_fielder = build_fielder("%s_%03d" % [team_id, player_index], base_pos, _pick_fielder_archetype(base_pos))
		player_index += 1

		if pos == "UT":
			p_fielder.secondary_positions.clear()
			p_fielder.secondary_positions.append(POS_2B)
			p_fielder.secondary_positions.append(POS_3B)
			p_fielder.secondary_positions.append(POS_SS)
			p_fielder.secondary_positions.append(POS_LF)
			p_fielder.secondary_positions.append(POS_CF)
			p_fielder.secondary_positions.append(POS_RF)
			
		created_players.append(p_fielder)

	for p in created_players:
		team.player_ids.append(str(p.id))

	var starters: Array = []
	var relievers: Array = []
	var closers: Array = []
	var fielders: Array = []

	for p in created_players:
		if p.role == "starter":
			starters.append(p)
		elif p.role == "reliever":
			relievers.append(p)
		elif p.role == "closer":
			closers.append(p)
		else:
			fielders.append(p)

	starters.sort_custom(_sort_by_overall_desc)
	relievers.sort_custom(_sort_by_overall_desc)
	closers.sort_custom(_sort_by_overall_desc)

	for p in starters:
		team.rotation_ids.append(str(p.id))

	if closers.size() > 0:
		team.bullpen["closer"] = str(closers[0].id)

	var setup_count: int = mini(2, relievers.size())
	for i in range(setup_count):
		team.bullpen["setup"].append(str(relievers[i].id))

	for i in range(setup_count, relievers.size()):
		team.bullpen["middle"].append(str(relievers[i].id))

	if relievers.size() > 0:
		team.bullpen["long"] = str(relievers[relievers.size() - 1].id)

	var defense_order: Array[String] = [POS_C, POS_1B, POS_2B, POS_3B, POS_SS, POS_LF, POS_CF, POS_RF, POS_DH]
	var used_ids: Array[String] = []

	for target_pos in defense_order:
		var candidates: Array = []

		for f in fielders:
			if str(f.id) in used_ids:
				continue
			if str(f.primary_position) == target_pos:
				candidates.append(f)

		if candidates.is_empty():
			for f in fielders:
				if not (str(f.id) in used_ids):
					candidates.append(f)

		candidates.sort_custom(_sort_fielder_attack_desc)

		if candidates.size() > 0:
			var picked = candidates[0]
			team.lineup_vs_r.append(str(picked.id))
			team.lineup_vs_l.append(str(picked.id))
			used_ids.append(str(picked.id))

	for f in fielders:
		if not (str(f.id) in used_ids):
			team.bench_ids.append(str(f.id))

	return {
		"team": team,
		"players": created_players
	}
