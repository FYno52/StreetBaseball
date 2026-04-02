extends RefCounted
class_name NPBInspiredOpeningData

const TEAM_BLUEPRINTS: Array[Dictionary] = [
	{
		"id": "TCR",
		"name": "東京クラウンズ",
		"short_name": "東京",
		"league": "metropolitan",
		"style": "power",
		"budget": 150000,
		"fan_support": 82,
		"core_players": [
			{"name": "城崎 剛志", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 79, "potential": 83, "age": 29, "salary": 9800, "traits": ["エース"]},
			{"name": "御門 豪太", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 81, "potential": 84, "age": 28, "salary": 12000, "traits": ["主砲"]},
			{"name": "白峰 修二", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 74, "potential": 77, "age": 27, "salary": 6900, "traits": ["主将"]},
			{"name": "ラファエル・ソリア", "role": "fielder", "pos": "LF", "throws": "R", "bats": "R", "overall": 76, "potential": 78, "age": 31, "salary": 8400, "foreign": true, "traits": ["助っ人長打"]},
			{"name": "榊原 颯", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 75, "potential": 78, "age": 30, "salary": 6200, "traits": ["守護神"]},
			{"name": "矢部 敬太", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 71, "potential": 74, "age": 31, "salary": 4800, "traits": ["司令塔"]}
		]
	},
	{
		"id": "JGS",
		"name": "神宮スカイズ",
		"short_name": "神宮",
		"league": "metropolitan",
		"style": "speed",
		"budget": 116000,
		"fan_support": 71,
		"core_players": [
			{"name": "大月 晴登", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 76, "potential": 80, "age": 27, "salary": 8600, "traits": ["左の柱"]},
			{"name": "真田 亮介", "role": "fielder", "pos": "2B", "throws": "R", "bats": "L", "overall": 77, "potential": 81, "age": 26, "salary": 7600, "traits": ["切込隊長"]},
			{"name": "奥寺 陸人", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 75, "potential": 79, "age": 25, "salary": 6500, "traits": ["俊足"]},
			{"name": "パブロ・ミレイ", "role": "fielder", "pos": "1B", "throws": "R", "bats": "R", "overall": 73, "potential": 75, "age": 30, "salary": 7000, "foreign": true, "traits": ["助っ人一塁"]},
			{"name": "佐伯 惇", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 72, "potential": 75, "age": 31, "salary": 5700, "traits": ["終盤に強い"]},
			{"name": "梶谷 海斗", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 69, "potential": 73, "age": 28, "salary": 4300, "traits": ["粘り強い"]}
		]
	},
	{
		"id": "YHB",
		"name": "横浜ハーバーブルー",
		"short_name": "横浜",
		"league": "metropolitan",
		"style": "power",
		"budget": 132000,
		"fan_support": 75,
		"core_players": [
			{"name": "結城 拓海", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 78, "potential": 82, "age": 28, "salary": 9300, "traits": ["開幕投手格"]},
			{"name": "橘 鷹矢", "role": "fielder", "pos": "1B", "throws": "R", "bats": "L", "overall": 80, "potential": 83, "age": 27, "salary": 11800, "traits": ["看板打者"]},
			{"name": "志水 颯太", "role": "fielder", "pos": "RF", "throws": "R", "bats": "R", "overall": 75, "potential": 79, "age": 26, "salary": 7200, "traits": ["勝負強い"]},
			{"name": "マーカス・リー", "role": "fielder", "pos": "LF", "throws": "R", "bats": "R", "overall": 74, "potential": 76, "age": 32, "salary": 7600, "foreign": true, "traits": ["助っ人砲"]},
			{"name": "滝田 創", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 73, "potential": 76, "age": 30, "salary": 6000, "traits": ["豪腕"]},
			{"name": "松前 智也", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 71, "potential": 75, "age": 28, "salary": 5100, "traits": ["堅実守備"]}
		]
	},
	{
		"id": "NGS",
		"name": "名古屋シャドウズ",
		"short_name": "名古屋",
		"league": "metropolitan",
		"style": "pitching",
		"budget": 110000,
		"fan_support": 63,
		"core_players": [
			{"name": "葛城 龍之介", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 80, "potential": 84, "age": 29, "salary": 10200, "traits": ["大黒柱"]},
			{"name": "鏡原 蓮", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 75, "potential": 79, "age": 26, "salary": 7900, "traits": ["技巧派左腕"]},
			{"name": "石森 悠斗", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 73, "potential": 76, "age": 27, "salary": 5600, "traits": ["守備型捕手"]},
			{"name": "三船 玲央", "role": "fielder", "pos": "SS", "throws": "R", "bats": "L", "overall": 72, "potential": 76, "age": 25, "salary": 5200, "traits": ["内野の要"]},
			{"name": "ジェイ・ノックス", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 73, "potential": 75, "age": 31, "salary": 6800, "foreign": true, "traits": ["助っ人救援"]},
			{"name": "桑原 匠", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 77, "age": 31, "salary": 6100, "traits": ["締め役"]}
		]
	},
	{
		"id": "KSS",
		"name": "関西ストライプス",
		"short_name": "関西",
		"league": "metropolitan",
		"style": "defense",
		"budget": 138000,
		"fan_support": 84,
		"core_players": [
			{"name": "黒川 慎吾", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 78, "potential": 82, "age": 28, "salary": 9400, "traits": ["勝ち頭"]},
			{"name": "小田切 隼人", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 77, "potential": 80, "age": 27, "salary": 7800, "traits": ["守備職人"]},
			{"name": "畑中 宗一郎", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 76, "potential": 79, "age": 29, "salary": 8000, "traits": ["中軸"]},
			{"name": "レオナルド・バルガス", "role": "fielder", "pos": "RF", "throws": "R", "bats": "L", "overall": 74, "potential": 76, "age": 30, "salary": 7200, "foreign": true, "traits": ["助っ人外野"]},
			{"name": "香坂 湊", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 77, "age": 29, "salary": 5900, "traits": ["火消し"]},
			{"name": "速水 孝介", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 30, "salary": 4500, "traits": ["配球巧者"]}
		]
	},
	{
		"id": "HRF",
		"name": "広島フレイムズ",
		"short_name": "広島",
		"league": "metropolitan",
		"style": "speed",
		"budget": 108000,
		"fan_support": 76,
		"core_players": [
			{"name": "長谷川 陽斗", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 77, "potential": 81, "age": 27, "salary": 8500, "traits": ["開幕候補"]},
			{"name": "有馬 翔一", "role": "fielder", "pos": "2B", "throws": "R", "bats": "L", "overall": 76, "potential": 80, "age": 25, "salary": 7000, "traits": ["機動力"]},
			{"name": "寺島 迅", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 75, "potential": 81, "age": 24, "salary": 6500, "traits": ["若き中心"]},
			{"name": "ノア・ハリス", "role": "fielder", "pos": "1B", "throws": "L", "bats": "L", "overall": 72, "potential": 74, "age": 31, "salary": 6800, "foreign": true, "traits": ["助っ人一塁"]},
			{"name": "岸本 駿", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 73, "potential": 76, "age": 30, "salary": 5700, "traits": ["回またぎ可"]},
			{"name": "神谷 智宏", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 71, "potential": 76, "age": 26, "salary": 5000, "traits": ["堅実"]}
		]
	},
	{
		"id": "HKL",
		"name": "北海道ノーザンライツ",
		"short_name": "北海道",
		"league": "frontier",
		"style": "balanced",
		"budget": 117000,
		"fan_support": 70,
		"core_players": [
			{"name": "氷室 真", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 77, "potential": 82, "age": 26, "salary": 8600, "traits": ["成長株エース"]},
			{"name": "北条 岳", "role": "fielder", "pos": "CF", "throws": "R", "bats": "R", "overall": 76, "potential": 81, "age": 25, "salary": 7100, "traits": ["万能"]},
			{"name": "早瀬 旭", "role": "fielder", "pos": "1B", "throws": "L", "bats": "L", "overall": 74, "potential": 79, "age": 24, "salary": 6200, "traits": ["成長中"]},
			{"name": "エリック・ブーン", "role": "fielder", "pos": "RF", "throws": "R", "bats": "R", "overall": 73, "potential": 75, "age": 30, "salary": 6900, "foreign": true, "traits": ["長打力"]},
			{"name": "樋口 亮", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 72, "potential": 75, "age": 29, "salary": 5600, "traits": ["剛球"]},
			{"name": "南雲 和真", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 28, "salary": 4300, "traits": ["若手投手に強い"]}
		]
	},
	{
		"id": "SGF",
		"name": "仙台ゴールデンフォックス",
		"short_name": "仙台",
		"league": "frontier",
		"style": "balanced",
		"budget": 104000,
		"fan_support": 62,
		"core_players": [
			{"name": "八神 慶", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 75, "potential": 79, "age": 28, "salary": 8100, "traits": ["柱"]},
			{"name": "高瀬 竜馬", "role": "fielder", "pos": "3B", "throws": "R", "bats": "R", "overall": 76, "potential": 79, "age": 27, "salary": 7600, "traits": ["中軸"]},
			{"name": "雨宮 陽介", "role": "fielder", "pos": "RF", "throws": "R", "bats": "L", "overall": 73, "potential": 77, "age": 26, "salary": 6000, "traits": ["広角"]},
			{"name": "ヴィクター・ロペス", "role": "fielder", "pos": "DH", "throws": "R", "bats": "R", "overall": 72, "potential": 74, "age": 31, "salary": 6800, "foreign": true, "traits": ["助っ人DH"]},
			{"name": "浅川 翔", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 72, "potential": 75, "age": 31, "salary": 5500, "traits": ["抑え】"]},
			{"name": "鳴海 隆", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 27, "salary": 4500, "traits": ["守備型"]}
		]
	},
	{
		"id": "SBC",
		"name": "埼玉ブレイブキャッツ",
		"short_name": "埼玉",
		"league": "frontier",
		"style": "speed",
		"budget": 98000,
		"fan_support": 58,
		"core_players": [
			{"name": "神原 直樹", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 74, "potential": 78, "age": 26, "salary": 7800, "traits": ["左の軸"]},
			{"name": "篠宮 海", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 75, "potential": 80, "age": 24, "salary": 6700, "traits": ["快足"]},
			{"name": "日向 蒼真", "role": "fielder", "pos": "2B", "throws": "R", "bats": "R", "overall": 73, "potential": 78, "age": 25, "salary": 5800, "traits": ["走攻守"]},
			{"name": "オーウェン・グラント", "role": "reliever", "pos": "P", "throws": "R", "bats": "R", "overall": 71, "potential": 73, "age": 30, "salary": 6400, "foreign": true, "traits": ["助っ人中継ぎ"]},
			{"name": "森園 迅", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 71, "potential": 74, "age": 29, "salary": 5300, "traits": ["火消し"]},
			{"name": "大門 智久", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 68, "potential": 72, "age": 29, "salary": 3900, "traits": ["守りの要"]}
		]
	},
	{
		"id": "CHO",
		"name": "千葉オーシャンズ",
		"short_name": "千葉",
		"league": "frontier",
		"style": "pitching",
		"budget": 106000,
		"fan_support": 61,
		"core_players": [
			{"name": "黒江 匠馬", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 77, "potential": 81, "age": 28, "salary": 8700, "traits": ["本格派"]},
			{"name": "鳳 大雅", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 73, "potential": 77, "age": 25, "salary": 6500, "traits": ["若手先発"]},
			{"name": "相沢 慧", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 72, "potential": 75, "age": 28, "salary": 5200, "traits": ["捕手力"]},
			{"name": "ジャレット・ムーア", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 74, "potential": 76, "age": 31, "salary": 7200, "foreign": true, "traits": ["助っ人守護神"]},
			{"name": "小山 凌", "role": "fielder", "pos": "LF", "throws": "R", "bats": "L", "overall": 71, "potential": 75, "age": 27, "salary": 4900, "traits": ["中距離"]},
			{"name": "戸坂 圭吾", "role": "fielder", "pos": "SS", "throws": "R", "bats": "R", "overall": 70, "potential": 74, "age": 27, "salary": 4600, "traits": ["堅守"]}
		]
	},
	{
		"id": "KBY",
		"name": "神戸バイソンズ",
		"short_name": "神戸",
		"league": "frontier",
		"style": "defense",
		"budget": 125000,
		"fan_support": 64,
		"core_players": [
			{"name": "津城 健悟", "role": "starter", "pos": "P", "throws": "R", "bats": "R", "overall": 76, "potential": 80, "age": 29, "salary": 9000, "traits": ["大崩れしない"]},
			{"name": "御子柴 迅", "role": "fielder", "pos": "SS", "throws": "R", "bats": "L", "overall": 75, "potential": 79, "age": 26, "salary": 7000, "traits": ["守備の軸"]},
			{"name": "鹿取 雅人", "role": "fielder", "pos": "1B", "throws": "L", "bats": "L", "overall": 74, "potential": 77, "age": 27, "salary": 6900, "traits": ["中軸左打者"]},
			{"name": "ミゲル・クルス", "role": "fielder", "pos": "RF", "throws": "R", "bats": "R", "overall": 73, "potential": 75, "age": 30, "salary": 7100, "foreign": true, "traits": ["助っ人右翼"]},
			{"name": "白河 蒼大", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 72, "potential": 75, "age": 30, "salary": 5600, "traits": ["球威型"]},
			{"name": "結野 岳人", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 69, "potential": 73, "age": 29, "salary": 4100, "traits": ["壁性能"]}
		]
	},
	{
		"id": "FKS",
		"name": "福岡サンブレイズ",
		"short_name": "福岡",
		"league": "frontier",
		"style": "power",
		"budget": 155000,
		"fan_support": 83,
		"core_players": [
			{"name": "早良 泰星", "role": "starter", "pos": "P", "throws": "L", "bats": "L", "overall": 79, "potential": 83, "age": 28, "salary": 9900, "traits": ["エース級"]},
			{"name": "岸波 大地", "role": "fielder", "pos": "1B", "throws": "L", "bats": "L", "overall": 80, "potential": 84, "age": 27, "salary": 12200, "traits": ["主砲"]},
			{"name": "槙原 湊斗", "role": "fielder", "pos": "CF", "throws": "R", "bats": "L", "overall": 76, "potential": 80, "age": 26, "salary": 7400, "traits": ["走れる主力"]},
			{"name": "ダリオ・ロハス", "role": "fielder", "pos": "DH", "throws": "R", "bats": "R", "overall": 75, "potential": 77, "age": 31, "salary": 7900, "foreign": true, "traits": ["助っ人主砲"]},
			{"name": "鷲尾 蓮司", "role": "closer", "pos": "P", "throws": "R", "bats": "R", "overall": 75, "potential": 78, "age": 30, "salary": 6300, "traits": ["守護神"]},
			{"name": "宇佐木 涼", "role": "fielder", "pos": "C", "throws": "R", "bats": "R", "overall": 71, "potential": 75, "age": 28, "salary": 4800, "traits": ["強肩"]}
		]
	}
]

static func get_team_blueprints() -> Array[Dictionary]:
	return TEAM_BLUEPRINTS.duplicate(true)
