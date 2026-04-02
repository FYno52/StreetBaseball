extends RefCounted
class_name TeamBlueprints

const NPB_INSPIRED_RULESET := {
	"team_count": 12,
	"leagues": 2,
	"teams_per_league": 6,
	"registered_roster_target": 68,
	"registered_roster_max": 70,
	"active_roster_target": 29,
	"active_pitchers_target": 14,
	"active_fielders_target": 15,
	"rotation_size": 6,
	"bullpen_active_target": 8,
	"bench_active_target": 7,
	"foreign_signed_target": 4,
	"foreign_active_max": 4,
	"foreign_pitcher_active_max": 3,
	"foreign_fielder_active_max": 3
}

const INITIAL_ROSTER_DISTRIBUTION := {
	"pitchers": 30,
	"catchers": 4,
	"infielders": 17,
	"outfielders": 13,
	"foreigners_signed": 4
}

const NPB_INSPIRED_TEAMS: Array[Dictionary] = [
	{
		"id": "TCR",
		"name": "東京クラウンズ",
		"short_name": "東京",
		"league": "metropolitan",
		"region": "東京",
		"style": "power",
		"budget_tier": 5,
		"fan_tier": 5,
		"notes": "資金力が高く、強打者を集めやすい看板球団。"
	},
	{
		"id": "JGS",
		"name": "神宮スカイズ",
		"short_name": "神宮",
		"league": "metropolitan",
		"region": "東京",
		"style": "speed",
		"budget_tier": 3,
		"fan_tier": 4,
		"notes": "機動力と野手育成に強い、都心型の技巧派球団。"
	},
	{
		"id": "YHB",
		"name": "横浜ハーバーブルー",
		"short_name": "横浜",
		"league": "metropolitan",
		"region": "神奈川",
		"style": "power",
		"budget_tier": 4,
		"fan_tier": 4,
		"notes": "打ち勝つカラーが強く、助っ人野手を当てやすい。"
	},
	{
		"id": "NGS",
		"name": "名古屋シャドウズ",
		"short_name": "名古屋",
		"league": "metropolitan",
		"region": "愛知",
		"style": "pitching",
		"budget_tier": 3,
		"fan_tier": 3,
		"notes": "守り勝つ思想が強く、投手層が厚くなりやすい。"
	},
	{
		"id": "KSS",
		"name": "関西ストライプス",
		"short_name": "関西",
		"league": "metropolitan",
		"region": "兵庫",
		"style": "defense",
		"budget_tier": 4,
		"fan_tier": 5,
		"notes": "人気が高く、守備と執念で勝ち切るタイプ。"
	},
	{
		"id": "HRF",
		"name": "広島フレイムズ",
		"short_name": "広島",
		"league": "metropolitan",
		"region": "広島",
		"style": "speed",
		"budget_tier": 3,
		"fan_tier": 4,
		"notes": "若手育成と機動力を軸にする地方熱狂型。"
	},
	{
		"id": "HKL",
		"name": "北海道ノーザンライツ",
		"short_name": "北海道",
		"league": "frontier",
		"region": "北海道",
		"style": "balanced",
		"budget_tier": 3,
		"fan_tier": 4,
		"notes": "総合型で若手起用も多く、伸び盛りが出やすい。"
	},
	{
		"id": "SGF",
		"name": "仙台ゴールデンフォックス",
		"short_name": "仙台",
		"league": "frontier",
		"region": "宮城",
		"style": "balanced",
		"budget_tier": 3,
		"fan_tier": 3,
		"notes": "中長期で底上げしやすい地方密着型球団。"
	},
	{
		"id": "SBC",
		"name": "埼玉ブレイブキャッツ",
		"short_name": "埼玉",
		"league": "frontier",
		"region": "埼玉",
		"style": "speed",
		"budget_tier": 2,
		"fan_tier": 3,
		"notes": "足と若手を軸にした再建向きの球団カラー。"
	},
	{
		"id": "CHO",
		"name": "千葉オーシャンズ",
		"short_name": "千葉",
		"league": "frontier",
		"region": "千葉",
		"style": "pitching",
		"budget_tier": 3,
		"fan_tier": 3,
		"notes": "投手運用と終盤の継投が強みになりやすい。"
	},
	{
		"id": "KBY",
		"name": "神戸バイソンズ",
		"short_name": "神戸",
		"league": "frontier",
		"region": "大阪・兵庫",
		"style": "defense",
		"budget_tier": 4,
		"fan_tier": 3,
		"notes": "地力は高いが波もある、西日本の総合戦力型。"
	},
	{
		"id": "FKS",
		"name": "福岡サンブレイズ",
		"short_name": "福岡",
		"league": "frontier",
		"region": "福岡",
		"style": "power",
		"budget_tier": 5,
		"fan_tier": 5,
		"notes": "資金力が高く、助っ人補強や層の厚さが売り。"
	}
]

static func get_team_blueprints() -> Array[Dictionary]:
	return NPB_INSPIRED_TEAMS.duplicate(true)

static func get_ruleset() -> Dictionary:
	return NPB_INSPIRED_RULESET.duplicate(true)

static func get_initial_distribution() -> Dictionary:
	return INITIAL_ROSTER_DISTRIBUTION.duplicate(true)
