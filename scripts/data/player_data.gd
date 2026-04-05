class_name PlayerData
extends RefCounted

const POSITION_KEYS: Array[String] = ["P", "C", "1B", "2B", "3B", "SS", "LF", "CF", "RF", "DH"]

var id: String = ""
var full_name: String = ""
var nationality: String = "日本"

var age: int = 18
var bats: String = "R"
var throws: String = "R"
var is_foreign: bool = false
var registration_type: String = "registered"
var roster_status: String = "farm"

# fielder / starter / reliever / closer
var role: String = "fielder"
var primary_position: String = "CF"
var secondary_positions: Array[String] = []

var overall: int = 50
var potential: int = 60
var development_type: String = "normal"
var development_focus: String = "balanced"
var morale: int = 50
var fatigue: int = 0
var injury_risk: float = 0.03
var durability: int = 55
var condition: int = 50
var work_ethic: int = 50
var intelligence: int = 50
var leadership: int = 50
var adaptability: int = 50

var salary: int = 500
var years_pro: int = 1
var contract_years_left: int = 2
var desired_salary: int = 500
var fa_interest: int = 50

var ratings: Dictionary = {
	"contact": 50,
	"gap": 50,
	"power": 50,
	"eye": 50,
	"avoid_k": 50,
	"speed": 50,
	"arm": 50,
	"fielding": 50,
	"catching": 50,
	"velocity": 50,
	"control": 50,
	"stamina": 50,
	"break": 50,
	"movement": 50,
	"k_rate": 50,
	"vs_left": 50,
	"composure": 50
}

var position_ratings: Dictionary = {
	"P": 0,
	"C": 0,
	"1B": 0,
	"2B": 0,
	"3B": 0,
	"SS": 0,
	"LF": 0,
	"CF": 0,
	"RF": 0,
	"DH": 0
}

var pitch_types: Array[String] = []
var traits: Array[String] = []

var batting_stats: Dictionary = {}
var pitching_stats: Dictionary = {}


func _init() -> void:
	reset_season_stats()


func reset_season_stats() -> void:
	batting_stats = {
		"g": 0,
		"pa": 0,
		"ab": 0,
		"h": 0,
		"d2": 0,
		"d3": 0,
		"hr": 0,
		"rbi": 0,
		"bb": 0,
		"so": 0,
		"sb": 0,
		"runs": 0
	}

	pitching_stats = {
		"g": 0,
		"gs": 0,
		"wins": 0,
		"losses": 0,
		"saves": 0,
		"holds": 0,
		"outs": 0,
		"er": 0,
		"ha": 0,
		"hra": 0,
		"bb": 0,
		"so": 0
	}


func is_pitcher() -> bool:
	return role == "starter" or role == "reliever" or role == "closer"


func calc_overall() -> int:
	if is_pitcher():
		var velocity_value: int = int(ratings["velocity"])
		var control_value: int = int(ratings["control"])
		var stamina_value: int = int(ratings["stamina"])
		var break_value: int = int(ratings["break"])
		var strikeout_value: int = int(ratings["k_rate"])
		var composure_value: int = int(ratings["composure"])

		if role == "starter":
			return int(round(
				velocity_value * 0.22
				+ control_value * 0.22
				+ stamina_value * 0.22
				+ break_value * 0.16
				+ strikeout_value * 0.10
				+ composure_value * 0.08
			))
		return int(round(
			velocity_value * 0.27
			+ control_value * 0.23
			+ break_value * 0.20
			+ strikeout_value * 0.18
			+ composure_value * 0.12
		))

	var contact_value: int = int(ratings["contact"])
	var power_value: int = int(ratings["power"])
	var eye_value: int = int(ratings["eye"])
	var speed_value: int = int(ratings["speed"])
	var fielding_value: int = int(ratings["fielding"])
	var arm_value: int = int(ratings["arm"])
	var catching_value: int = int(ratings["catching"])

	if primary_position == "C":
		return int(round(
			contact_value * 0.18
			+ power_value * 0.16
			+ eye_value * 0.10
			+ speed_value * 0.08
			+ fielding_value * 0.18
			+ arm_value * 0.12
			+ catching_value * 0.18
		))

	return int(round(
		contact_value * 0.24
		+ power_value * 0.22
		+ eye_value * 0.14
		+ speed_value * 0.12
		+ fielding_value * 0.14
		+ arm_value * 0.08
		+ catching_value * 0.06
	))


func get_position_rating(position_key: String) -> int:
	return int(position_ratings.get(position_key, 0))


func get_position_rating_label(position_key: String) -> String:
	var value: int = get_position_rating(position_key)
	if value >= 85:
		return "S"
	if value >= 75:
		return "A"
	if value >= 65:
		return "B"
	if value >= 50:
		return "C"
	if value >= 35:
		return "D"
	return "E"


func get_available_development_focuses() -> Array[String]:
	if is_pitcher():
		return ["balanced", "velocity", "control", "breaking", "stamina"]
	return ["balanced", "contact", "power", "discipline", "speed", "defense"]


func get_development_focus_label() -> String:
	match str(development_focus):
		"velocity":
			return "球威強化"
		"control":
			return "制球強化"
		"breaking":
			return "変化球強化"
		"stamina":
			return "スタミナ強化"
		"contact":
			return "ミート強化"
		"power":
			return "パワー強化"
		"discipline":
			return "選球眼強化"
		"speed":
			return "走力強化"
		"defense":
			return "守備強化"
		_:
			return "バランス"


func get_key_ratings_for_display() -> Array[Dictionary]:
	if is_pitcher():
		return [
			{"label": "Stuff", "value": int(ratings["velocity"])},
			{"label": "Movement", "value": int(ratings["movement"])},
			{"label": "制球", "value": int(ratings["control"])},
			{"label": "スタミナ", "value": int(ratings["stamina"])},
			{"label": "変化球", "value": int(ratings["break"])},
			{"label": "奪三振", "value": int(ratings["k_rate"])},
			{"label": "対左", "value": int(ratings["vs_left"])}
		]

	return [
		{"label": "Contact", "value": int(ratings["contact"])},
		{"label": "Gap", "value": int(ratings["gap"])},
		{"label": "Power", "value": int(ratings["power"])},
		{"label": "選球眼", "value": int(ratings["eye"])},
		{"label": "Avoid K", "value": int(ratings["avoid_k"])},
		{"label": "走力", "value": int(ratings["speed"])},
		{"label": "肩力", "value": int(ratings["arm"])},
		{"label": "守備", "value": int(ratings["fielding"])},
		{"label": "捕球", "value": int(ratings["catching"])}
	]


func get_overview_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("国籍: %s" % nationality)
	lines.append("年齢: %d  %s投 / %s打" % [age, throws, bats])
	lines.append("総合: %d  将来性: %d" % [overall, potential])
	lines.append("役割: %s  主位置: %s" % [_get_role_label(), primary_position])
	lines.append("登録: %s / %s" % [_get_registration_label(), _get_roster_status_label()])
	lines.append("契約: %d年  年俸 %d  希望 %d" % [contract_years_left, salary, desired_salary])
	lines.append("FA志向: %d  在籍年数: %d年" % [fa_interest, years_pro])
	return lines


func get_development_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("成長タイプ: %s" % _get_development_type_label())
	lines.append("育成方針: %s" % get_development_focus_label())
	lines.append("コンディション: %d  疲労: %d" % [condition, fatigue])
	lines.append("耐久力: %d  故障しやすさ: %d" % [durability, get_injury_proneness_score()])
	lines.append("士気: %d  勤勉さ: %d  頭脳: %d" % [morale, work_ethic, intelligence])
	lines.append("統率力: %d  環境適応: %d" % [leadership, adaptability])
	return lines


func get_history_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("プロ年数: %d年" % years_pro)
	lines.append("契約残り: %d年" % contract_years_left)
	lines.append("登録区分: %s" % _get_registration_label())
	lines.append("在籍状態: %s" % _get_roster_status_label())
	lines.append("外国人: %s" % ("はい" if is_foreign else "いいえ"))
	return lines


func get_traits_by_category() -> Dictionary:
	var categories := {
		"打撃": [],
		"守備": [],
		"投手": [],
		"メンタル": []
	}
	for trait_name in traits:
		var resolved: String = str(trait_name)
		var target := "打撃"
		if ["守備職人", "強肩", "レンジ広い", "司令塔"].has(resolved):
			target = "守備"
		elif ["速球派", "制球重視", "変化球中心", "奪三振", "対ピンチ", "イニングイーター", "守護神気質", "対左打者○"].has(resolved):
			target = "投手"
		elif ["勝負強さ", "キャプテン気質", "ムードメーカー"].has(resolved):
			target = "メンタル"
		categories[target].append(resolved)
	return categories


func get_injury_proneness_score() -> int:
	return clampi(int(round(injury_risk * 1000.0)), 1, 99)


func _get_role_label() -> String:
	match role:
		"starter":
			return "先発投手"
		"reliever":
			return "中継ぎ投手"
		"closer":
			return "抑え投手"
		_:
			return "野手"


func _get_registration_label() -> String:
	return "育成契約" if registration_type == "development" else "支配下"


func _get_roster_status_label() -> String:
	match roster_status:
		"active":
			return "一軍"
		"development":
			return "育成"
		_:
			return "二軍"


func _get_development_type_label() -> String:
	match development_type:
		"early":
			return "早熟"
		"late":
			return "晩成"
		_:
			return "標準"


func to_dict() -> Dictionary:
	return {
		"id": id,
		"full_name": full_name,
		"nationality": nationality,
		"age": age,
		"bats": bats,
		"throws": throws,
		"is_foreign": is_foreign,
		"registration_type": registration_type,
		"roster_status": roster_status,
		"role": role,
		"primary_position": primary_position,
		"secondary_positions": secondary_positions.duplicate(),
		"overall": overall,
		"potential": potential,
		"development_type": development_type,
		"development_focus": development_focus,
		"morale": morale,
		"fatigue": fatigue,
		"injury_risk": injury_risk,
		"durability": durability,
		"condition": condition,
		"work_ethic": work_ethic,
		"intelligence": intelligence,
		"leadership": leadership,
		"adaptability": adaptability,
		"salary": salary,
		"years_pro": years_pro,
		"contract_years_left": contract_years_left,
		"desired_salary": desired_salary,
		"fa_interest": fa_interest,
		"ratings": ratings.duplicate(true),
		"position_ratings": position_ratings.duplicate(true),
		"pitch_types": pitch_types.duplicate(),
		"traits": traits.duplicate(),
		"batting_stats": batting_stats.duplicate(true),
		"pitching_stats": pitching_stats.duplicate(true)
	}


static func from_dict(d: Dictionary):
	var player: PlayerData = load("res://scripts/data/player_data.gd").new()

	player.id = str(d.get("id", ""))
	player.full_name = str(d.get("full_name", ""))
	player.nationality = str(d.get("nationality", "日本"))
	player.age = int(d.get("age", 18))
	player.bats = str(d.get("bats", "R"))
	player.throws = str(d.get("throws", "R"))
	player.is_foreign = bool(d.get("is_foreign", false))
	player.registration_type = str(d.get("registration_type", "registered"))
	player.roster_status = str(d.get("roster_status", "farm"))
	player.role = str(d.get("role", "fielder"))
	player.primary_position = str(d.get("primary_position", "CF"))
	player.overall = int(d.get("overall", 50))
	player.potential = int(d.get("potential", 60))
	player.development_type = str(d.get("development_type", "normal"))
	player.development_focus = str(d.get("development_focus", "balanced"))
	player.morale = int(d.get("morale", 50))
	player.fatigue = int(d.get("fatigue", 0))
	player.injury_risk = float(d.get("injury_risk", 0.03))
	player.durability = int(d.get("durability", 55))
	player.condition = int(d.get("condition", 50))
	player.work_ethic = int(d.get("work_ethic", 50))
	player.intelligence = int(d.get("intelligence", 50))
	player.leadership = int(d.get("leadership", 50))
	player.adaptability = int(d.get("adaptability", 50))
	player.salary = int(d.get("salary", 500))
	player.years_pro = int(d.get("years_pro", 1))
	player.contract_years_left = int(d.get("contract_years_left", 2))
	player.desired_salary = int(d.get("desired_salary", player.salary))
	player.fa_interest = int(d.get("fa_interest", 50))

	player.secondary_positions.clear()
	for value in d.get("secondary_positions", []):
		player.secondary_positions.append(str(value))

	player.pitch_types.clear()
	for value in d.get("pitch_types", []):
		player.pitch_types.append(str(value))

	player.traits.clear()
	for value in d.get("traits", []):
		player.traits.append(str(value))

	var raw_ratings: Dictionary = d.get("ratings", {})
	for key in raw_ratings.keys():
		player.ratings[str(key)] = raw_ratings[key]

	var raw_position_ratings: Dictionary = d.get("position_ratings", {})
	for key in raw_position_ratings.keys():
		player.position_ratings[str(key)] = raw_position_ratings[key]

	player.batting_stats = d.get("batting_stats", {}).duplicate(true)
	player.pitching_stats = d.get("pitching_stats", {}).duplicate(true)
	return player


func get_batting_average() -> float:
	var at_bats: int = int(batting_stats["ab"])
	var hits: int = int(batting_stats["h"])
	if at_bats <= 0:
		return 0.0
	return float(hits) / float(at_bats)


func get_era() -> float:
	var outs: int = int(pitching_stats["outs"])
	var earned_runs: int = int(pitching_stats["er"])
	if outs <= 0:
		return 0.0
	var innings: float = float(outs) / 3.0
	return float(earned_runs) * 9.0 / innings
