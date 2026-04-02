extends RefCounted
class_name OpeningRosterSupplements

const SUPPLEMENTS := {
	"TCR": [
		{"name": "白峰 恒一", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 78, "age": 26, "salary": 6200, "traits": ["ローテ柱"]},
		{"name": "久住 大雅", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 71, "potential": 74, "age": 28, "salary": 4200, "traits": ["勝ち継投"]},
		{"name": "梶谷 龍之介", "role": "fielder", "pos": "RF", "throws": "R", "bats": "R", "overall": 74, "potential": 77, "age": 27, "salary": 5900, "traits": ["長打力"]},
		{"name": "結城 颯真", "role": "fielder", "pos": "2B", "throws": "R", "bats": "L", "overall": 70, "potential": 75, "age": 24, "salary": 3600, "traits": ["機動力"]}
	],
	"JGS": [
		{"name": "立花 玲央", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 73, "potential": 77, "age": 25, "salary": 5600, "traits": ["左の先発"]},
		{"name": "榊原 一成", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 70, "potential": 73, "age": 27, "salary": 3900, "traits": ["火消し"]},
		{"name": "成瀬 海里", "role": "fielder", "pos": "LF", "throws": "R", "bats": "L", "overall": 73, "potential": 77, "age": 24, "salary": 4800, "traits": ["出塁型"]},
		{"name": "桐山 陸", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 71, "potential": 76, "age": 23, "salary": 3400, "traits": ["守備職人"]}
	],
	"YHB": [
		{"name": "相沢 煌", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 78, "age": 27, "salary": 6100, "traits": ["本格派"]},
		{"name": "瀬川 仁", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 71, "potential": 74, "age": 29, "salary": 4300, "traits": ["セットアッパー"]},
		{"name": "神崎 直哉", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 75, "potential": 78, "age": 28, "salary": 6400, "traits": ["中軸"]},
		{"name": "室井 蒼空", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 70, "potential": 74, "age": 24, "salary": 3500, "traits": ["俊足"]}
	],
	"NGS": [
		{"name": "黒瀬 大河", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 75, "potential": 79, "age": 27, "salary": 6500, "traits": ["エース格"]},
		{"name": "御園 生真", "role": "reliever", "pos": "P", "throws": "L", "bats": "L", "overall": 71, "potential": 75, "age": 28, "salary": 4100, "traits": ["左殺し"]},
		{"name": "安東 匠", "role": "fielder", "pos": "2B", "throws": "R", "bats": "R", "overall": 72, "potential": 76, "age": 26, "salary": 4700, "traits": ["堅守"]},
		{"name": "水元 悠司", "role": "fielder", "pos": "LF", "throws": "R", "bats": "L", "overall": 69, "potential": 73, "age": 25, "salary": 3200, "traits": ["つなぎ役"]}
	],
	"KSS": [
		{"name": "西島 悠斗", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 78, "age": 28, "salary": 6000, "traits": ["試合作り"]},
		{"name": "八代 拓海", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 70, "potential": 73, "age": 27, "salary": 4000, "traits": ["便利屋"]},
		{"name": "岸本 啓吾", "role": "fielder", "pos": "1B", "throws": "L", "bats": "L", "overall": 74, "potential": 77, "age": 29, "salary": 6200, "traits": ["勝負強い"]},
		{"name": "松波 隼", "role": "fielder", "pos": "2B", "throws": "R", "bats": "L", "overall": 71, "potential": 75, "age": 25, "salary": 3800, "traits": ["守備範囲"]}
	],
	"HRF": [
		{"name": "高峰 奏斗", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 73, "potential": 78, "age": 24, "salary": 5200, "traits": ["若手先発"]},
		{"name": "槙野 旭", "role": "reliever", "pos": "P", "throws": "L", "bats": "L", "overall": 69, "potential": 74, "age": 26, "salary": 3300, "traits": ["左中継ぎ"]},
		{"name": "御堂 光希", "role": "fielder", "pos": "RF", "throws": "R", "bats": "L", "overall": 73, "potential": 78, "age": 24, "salary": 4500, "traits": ["脚力"]},
		{"name": "三枝 透真", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 70, "potential": 75, "age": 25, "salary": 3600, "traits": ["粘り強い"]}
	],
	"HKL": [
		{"name": "冴木 岳人", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 79, "age": 25, "salary": 5900, "traits": ["若き柱"]},
		{"name": "春川 壮馬", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 28, "salary": 3900, "traits": ["回またぎ"]},
		{"name": "朝比奈 蓮", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 72, "potential": 77, "age": 24, "salary": 4300, "traits": ["スター候補"]},
		{"name": "尾崎 晴樹", "role": "fielder", "pos": "LF", "throws": "R", "bats": "L", "overall": 71, "potential": 75, "age": 26, "salary": 4100, "traits": ["中距離打者"]}
	],
	"SGF": [
		{"name": "鴻上 聖也", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 73, "potential": 77, "age": 27, "salary": 5600, "traits": ["安定感"]},
		{"name": "鷲尾 凛太朗", "role": "reliever", "pos": "P", "throws": "L", "bats": "L", "overall": 69, "potential": 73, "age": 28, "salary": 3500, "traits": ["左の切り札"]},
		{"name": "深山 陽生", "role": "fielder", "pos": "2B", "throws": "R", "bats": "L", "overall": 72, "potential": 76, "age": 25, "salary": 4200, "traits": ["俊足巧打"]},
		{"name": "北沢 悠真", "role": "fielder", "pos": "1B", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 26, "salary": 4000, "traits": ["長打候補"]}
	],
	"SBC": [
		{"name": "綾瀬 拓翔", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 72, "potential": 77, "age": 24, "salary": 5000, "traits": ["伸び盛り"]},
		{"name": "常盤 理久", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 69, "potential": 72, "age": 27, "salary": 3200, "traits": ["タフネス"]},
		{"name": "風間 玲央", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 71, "potential": 76, "age": 24, "salary": 3900, "traits": ["守備型"]},
		{"name": "篠崎 大智", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 72, "potential": 77, "age": 23, "salary": 4100, "traits": ["走塁型"]}
	],
	"CHO": [
		{"name": "雨宮 遼", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 78, "age": 26, "salary": 6000, "traits": ["技巧派"]},
		{"name": "大津 玄希", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 29, "salary": 3800, "traits": ["勝ち継投"]},
		{"name": "月岡 修司", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 72, "potential": 76, "age": 27, "salary": 4600, "traits": ["中軸候補"]},
		{"name": "比嘉 蒼汰", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 70, "potential": 74, "age": 25, "salary": 3500, "traits": ["守備職人"]}
	],
	"KBY": [
		{"name": "伊吹 和真", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 78, "age": 27, "salary": 6100, "traits": ["ローテ中核"]},
		{"name": "桐生 晴斗", "role": "reliever", "pos": "P", "throws": "L", "bats": "L", "overall": 70, "potential": 73, "age": 28, "salary": 3700, "traits": ["変則左腕"]},
		{"name": "相良 直樹", "role": "fielder", "pos": "2B", "throws": "R", "bats": "R", "overall": 72, "potential": 75, "age": 27, "salary": 4500, "traits": ["堅実"]},
		{"name": "椿原 勝也", "role": "fielder", "pos": "LF", "throws": "R", "bats": "L", "overall": 71, "potential": 75, "age": 25, "salary": 3900, "traits": ["勝負強い"]}
	],
	"FKS": [
		{"name": "御影 巧", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 75, "potential": 79, "age": 27, "salary": 6500, "traits": ["ローテ上位"]},
		{"name": "皆川 駿", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 71, "potential": 75, "age": 28, "salary": 4100, "traits": ["剛腕中継ぎ"]},
		{"name": "芹沢 颯人", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 74, "potential": 78, "age": 26, "salary": 5600, "traits": ["中軸"]},
		{"name": "園部 悠雅", "role": "fielder", "pos": "RF", "throws": "R", "bats": "L", "overall": 72, "potential": 76, "age": 25, "salary": 4300, "traits": ["長打力"]}
	]
}

static func get_team_supplements(team_id: String) -> Array[Dictionary]:
	if not SUPPLEMENTS.has(team_id):
		var empty_result: Array[Dictionary] = []
		return empty_result
	var result: Array[Dictionary] = []
	for player_def in SUPPLEMENTS[team_id]:
		result.append(Dictionary(player_def))
	return result
