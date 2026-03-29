extends Node

func _ready() -> void:
	LeagueState.new_game()

	var sample_team_id: String = LeagueState.all_team_ids()[0]
	var sample_team = LeagueState.get_team(sample_team_id)
	var lineup_and_bench: Dictionary = LeagueState.get_team_lineup_and_bench(sample_team_id)

	var lineup: Array = lineup_and_bench["lineup"]
	var bench: Array = lineup_and_bench["bench"]

	print("=== BEFORE GAME ===")
	print("team: ", sample_team.name)

	print("--- LINEUP BEFORE ---")
	for i in range(lineup.size()):
		var p = lineup[i]
		print(
			str(i + 1), ". ",
			p.full_name,
			"  G:", p.batting_stats["g"],
			" PA:", p.batting_stats["pa"],
			" AB:", p.batting_stats["ab"]
		)

	print("--- BENCH BEFORE ---")
	for i in range(bench.size()):
		var p = bench[i]
		print(
			str(i + 1), ". ",
			p.full_name,
			"  G:", p.batting_stats["g"],
			" PA:", p.batting_stats["pa"],
			" AB:", p.batting_stats["ab"]
		)

	LeagueState.simulate_current_day()

	print("=== AFTER GAME ===")

	print("--- LINEUP AFTER ---")
	for i in range(lineup.size()):
		var p = lineup[i]
		print(
			str(i + 1), ". ",
			p.full_name,
			"  G:", p.batting_stats["g"],
			" PA:", p.batting_stats["pa"],
			" AB:", p.batting_stats["ab"]
		)

	print("--- BENCH AFTER ---")
	for i in range(bench.size()):
		var p = bench[i]
		print(
			str(i + 1), ". ",
			p.full_name,
			"  G:", p.batting_stats["g"],
			" PA:", p.batting_stats["pa"],
			" AB:", p.batting_stats["ab"]
		)
