class_name TeamData
extends RefCounted

var id: String = ""
var name: String = ""
var short_name: String = ""

var budget: int = 100000
var fan_support: int = 50
var strategy: String = "balanced" # balanced / power / speed / defense / pitching

var player_ids: Array[String] = []

var lineup_vs_r: Array[String] = []
var lineup_vs_l: Array[String] = []
var bench_ids: Array[String] = []
var rotation_ids: Array[String] = []

var bullpen: Dictionary = {
	"closer": "",
	"setup": [],
	"middle": [],
	"long": ""
}

var standings: Dictionary = {
	"wins": 0,
	"losses": 0,
	"draws": 0,
	"runs_for": 0,
	"runs_against": 0
}

func win_pct() -> float:
	var games: int = int(standings["wins"]) + int(standings["losses"])
	if games <= 0:
		return 0.0
	return float(standings["wins"]) / float(games)

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"short_name": short_name,
		"budget": budget,
		"fan_support": fan_support,
		"strategy": strategy,
		"player_ids": player_ids.duplicate(),
		"lineup_vs_r": lineup_vs_r.duplicate(),
		"lineup_vs_l": lineup_vs_l.duplicate(),
		"bench_ids": bench_ids.duplicate(),
		"rotation_ids": rotation_ids.duplicate(),
		"bullpen": bullpen.duplicate(true),
		"standings": standings.duplicate(true)
	}

static func from_dict(d: Dictionary):
	var t = load("res://scripts/data/team_data.gd").new()

	t.id = str(d.get("id", ""))
	t.name = str(d.get("name", ""))
	t.short_name = str(d.get("short_name", ""))
	t.budget = int(d.get("budget", 100000))
	t.fan_support = int(d.get("fan_support", 50))
	t.strategy = str(d.get("strategy", "balanced"))

	t.player_ids.clear()
	for value in d.get("player_ids", []):
		t.player_ids.append(str(value))

	t.lineup_vs_r.clear()
	for value in d.get("lineup_vs_r", []):
		t.lineup_vs_r.append(str(value))

	t.lineup_vs_l.clear()
	for value in d.get("lineup_vs_l", []):
		t.lineup_vs_l.append(str(value))

	t.bench_ids.clear()
	for value in d.get("bench_ids", []):
		t.bench_ids.append(str(value))

	t.rotation_ids.clear()
	for value in d.get("rotation_ids", []):
		t.rotation_ids.append(str(value))

	t.bullpen = d.get("bullpen", {}).duplicate(true)
	t.standings = d.get("standings", {}).duplicate(true)

	return t
