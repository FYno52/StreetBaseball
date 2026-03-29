class_name PlayerData
extends RefCounted

var id: String = ""
var full_name: String = ""

var age: int = 18
var bats: String = "R"
var throws: String = "R"

# fielder / starter / reliever / closer
var role: String = "fielder"
var primary_position: String = "CF"
var secondary_positions: Array[String] = []

var overall: int = 50
var potential: int = 60
var development_type: String = "normal"
var morale: int = 50
var fatigue: int = 0
var injury_risk: float = 0.03
var condition: int = 50

var salary: int = 500
var years_pro: int = 1

var ratings: Dictionary = {
	"contact": 50,
	"power": 50,
	"eye": 50,
	"speed": 50,
	"arm": 50,
	"fielding": 50,
	"catching": 50,
	"velocity": 50,
	"control": 50,
	"stamina": 50,
	"break": 50,
	"k_rate": 50,
	"vs_left": 50,
	"composure": 50
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
		var v: int = int(ratings["velocity"])
		var c: int = int(ratings["control"])
		var s: int = int(ratings["stamina"])
		var b: int = int(ratings["break"])
		var k: int = int(ratings["k_rate"])
		var m: int = int(ratings["composure"])

		if role == "starter":
			return int(round(v * 0.22 + c * 0.22 + s * 0.22 + b * 0.16 + k * 0.10 + m * 0.08))
		else:
			return int(round(v * 0.27 + c * 0.23 + b * 0.20 + k * 0.18 + m * 0.12))

	var con: int = int(ratings["contact"])
	var power_rating: int = int(ratings["power"])
	var eye: int = int(ratings["eye"])
	var spd: int = int(ratings["speed"])
	var fld: int = int(ratings["fielding"])
	var arm: int = int(ratings["arm"])
	var cat: int = int(ratings["catching"])

	if primary_position == "C":
		return int(round(con * 0.18 + power_rating * 0.16 + eye * 0.10 + spd * 0.08 + fld * 0.18 + arm * 0.12 + cat * 0.18))

	return int(round(con * 0.24 + power_rating * 0.22 + eye * 0.14 + spd * 0.12 + fld * 0.14 + arm * 0.08 + cat * 0.06))

func to_dict() -> Dictionary:
	return {
		"id": id,
		"full_name": full_name,
		"age": age,
		"bats": bats,
		"throws": throws,
		"role": role,
		"primary_position": primary_position,
		"secondary_positions": secondary_positions.duplicate(),
		"overall": overall,
		"potential": potential,
		"development_type": development_type,
		"morale": morale,
		"fatigue": fatigue,
		"injury_risk": injury_risk,
		"condition": condition,
		"salary": salary,
		"years_pro": years_pro,
		"ratings": ratings.duplicate(true),
		"pitch_types": pitch_types.duplicate(),
		"traits": traits.duplicate(),
		"batting_stats": batting_stats.duplicate(true),
		"pitching_stats": pitching_stats.duplicate(true)
	}

static func from_dict(d: Dictionary):
	var p = load("res://scripts/data/player_data.gd").new()

	p.id = str(d.get("id", ""))
	p.full_name = str(d.get("full_name", ""))
	p.age = int(d.get("age", 18))
	p.bats = str(d.get("bats", "R"))
	p.throws = str(d.get("throws", "R"))
	p.role = str(d.get("role", "fielder"))
	p.primary_position = str(d.get("primary_position", "CF"))
	p.overall = int(d.get("overall", 50))
	p.potential = int(d.get("potential", 60))
	p.development_type = str(d.get("development_type", "normal"))
	p.morale = int(d.get("morale", 50))
	p.fatigue = int(d.get("fatigue", 0))
	p.injury_risk = float(d.get("injury_risk", 0.03))
	p.condition = int(d.get("condition", 50))
	p.salary = int(d.get("salary", 500))
	p.years_pro = int(d.get("years_pro", 1))

	p.secondary_positions.clear()
	for value in d.get("secondary_positions", []):
		p.secondary_positions.append(str(value))

	p.pitch_types.clear()
	for value in d.get("pitch_types", []):
		p.pitch_types.append(str(value))

	p.traits.clear()
	for value in d.get("traits", []):
		p.traits.append(str(value))

	var raw_ratings: Dictionary = d.get("ratings", {})
	for key in raw_ratings.keys():
		p.ratings[str(key)] = raw_ratings[key]

	p.batting_stats = d.get("batting_stats", {}).duplicate(true)
	p.pitching_stats = d.get("pitching_stats", {}).duplicate(true)

	return p
	
func get_batting_average() -> float:
	var ab: int = int(batting_stats["ab"])
	var h: int = int(batting_stats["h"])

	if ab <= 0:
		return 0.0

	return float(h) / float(ab)

func get_era() -> float:
	var outs: int = int(pitching_stats["outs"])
	var er: int = int(pitching_stats["er"])

	if outs <= 0:
		return 0.0

	var innings: float = float(outs) / 3.0
	return float(er) * 9.0 / innings
