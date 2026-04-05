class_name TeamData
extends RefCounted

var id: String = ""
var name: String = ""
var short_name: String = ""

var budget: int = 100000
var fan_support: int = 50
var strategy: String = "balanced"
var sponsor_name: String = "地域商店会"
var sponsor_tier: int = 1
var draft_focus_ids: Array[String] = []
var last_draft_year: int = 0
var last_draft_result_names: Array[String] = []

var facilities: Dictionary = {
	"training": 1,
	"medical": 1,
	"scouting": 1,
	"marketing": 1
}

var staff: Dictionary = {
	"coaches": 2,
	"scouts": 1,
	"trainers": 1
}

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
		"sponsor_name": sponsor_name,
		"sponsor_tier": sponsor_tier,
		"draft_focus_ids": draft_focus_ids.duplicate(),
		"last_draft_year": last_draft_year,
		"last_draft_result_names": last_draft_result_names.duplicate(),
		"facilities": facilities.duplicate(true),
		"staff": staff.duplicate(true),
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
	t.sponsor_name = str(d.get("sponsor_name", "地域商店会"))
	t.sponsor_tier = int(d.get("sponsor_tier", 1))
	t.last_draft_year = int(d.get("last_draft_year", 0))

	t.draft_focus_ids.clear()
	for value in d.get("draft_focus_ids", []):
		t.draft_focus_ids.append(str(value))

	t.last_draft_result_names.clear()
	for value in d.get("last_draft_result_names", []):
		t.last_draft_result_names.append(str(value))

	t.facilities = d.get("facilities", {
		"training": 1,
		"medical": 1,
		"scouting": 1,
		"marketing": 1
	}).duplicate(true)
	t.staff = d.get("staff", {
		"coaches": 2,
		"scouts": 1,
		"trainers": 1
	}).duplicate(true)

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

	t.bullpen = d.get("bullpen", {
		"closer": "",
		"setup": [],
		"middle": [],
		"long": ""
	}).duplicate(true)
	t.standings = d.get("standings", {
		"wins": 0,
		"losses": 0,
		"draws": 0,
		"runs_for": 0,
		"runs_against": 0
	}).duplicate(true)

	return t
