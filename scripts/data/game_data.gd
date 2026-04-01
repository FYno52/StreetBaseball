class_name GameData
extends RefCounted

var id: String = ""
var day: int = 1
var season_year: int = 2026
var month: int = 1
var day_of_month: int = 1
var weekday_index: int = 0
var weekday_name: String = ""
var date_label: String = ""
var away_team_id: String = ""
var home_team_id: String = ""

var played: bool = false
var away_score: int = 0
var home_score: int = 0

var winning_pitcher_id: String = ""
var losing_pitcher_id: String = ""
var save_pitcher_id: String = ""

var log_lines: Array[String] = []
var play_events: Array[Dictionary] = []

func to_dict() -> Dictionary:
	return {
		"id": id,
		"day": day,
		"season_year": season_year,
		"month": month,
		"day_of_month": day_of_month,
		"weekday_index": weekday_index,
		"weekday_name": weekday_name,
		"date_label": date_label,
		"away_team_id": away_team_id,
		"home_team_id": home_team_id,
		"played": played,
		"away_score": away_score,
		"home_score": home_score,
		"winning_pitcher_id": winning_pitcher_id,
		"losing_pitcher_id": losing_pitcher_id,
		"save_pitcher_id": save_pitcher_id,
		"log_lines": log_lines.duplicate(),
		"play_events": play_events.duplicate(true)
	}

static func from_dict(d: Dictionary):
	var g = load("res://scripts/data/game_data.gd").new()

	g.id = str(d.get("id", ""))
	g.day = int(d.get("day", 1))
	g.season_year = int(d.get("season_year", 2026))
	g.month = int(d.get("month", 1))
	g.day_of_month = int(d.get("day_of_month", 1))
	g.weekday_index = int(d.get("weekday_index", 0))
	g.weekday_name = str(d.get("weekday_name", ""))
	g.date_label = str(d.get("date_label", ""))
	g.away_team_id = str(d.get("away_team_id", ""))
	g.home_team_id = str(d.get("home_team_id", ""))
	g.played = bool(d.get("played", false))
	g.away_score = int(d.get("away_score", 0))
	g.home_score = int(d.get("home_score", 0))
	g.winning_pitcher_id = str(d.get("winning_pitcher_id", ""))
	g.losing_pitcher_id = str(d.get("losing_pitcher_id", ""))
	g.save_pitcher_id = str(d.get("save_pitcher_id", ""))

	g.log_lines.clear()
	for value in d.get("log_lines", []):
		g.log_lines.append(str(value))

	g.play_events.clear()
	for value in d.get("play_events", []):
		if value is Dictionary:
			g.play_events.append((value as Dictionary).duplicate(true))

	return g
