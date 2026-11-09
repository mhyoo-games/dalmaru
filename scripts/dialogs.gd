class_name Dialogs
extends RefCounted
## 사람들 대사. 진행 상황(Game.flags, 모은 물건 수)에 따라 달라진다.

static func me() -> String:
	return Rules.hero(Game.hero).name

static func weapon_name(level: int) -> String:
	var w: String = Rules.hero(Game.hero).weapon
	var names := {"sword": ["목검", "단단한 목검", "박달 목검"], "bow": ["활", "단단한 활", "박달 활"],
		"club": ["방망이", "단단한 방망이", "박달 방망이"]}
	return names[w][mini(level, 2)]

static func has_news(id: String) -> bool:
	match id:
		"granny":
			return not Game.flag("talked_granny") or (Game.shards >= Rules.SHARDS_NEEDED and not Game.flag("told_ready")) \
				or (Game.flag("boss_down") and not Game.flag("thanked"))
		"smith":
			return Game.flag("talked_granny") and not Game.flag("met_smith")
		"ferry":
			return not Game.flag("met_ferry")
		"ranger":
			return not Game.flag("met_ranger")
		"moon":
			return not Game.flag("met_moon") or (Game.flag("boss_king") and not Game.flag("moon_thanks"))
	return false

static func talk(tree: SceneTree, id: String, who: String) -> void:
	match id:
		"granny": _granny(tree, who)
		"smith": _smith(tree, who)
		"kid": _kid(tree, who)
		"ferry": _ferry(tree, who)
		"ranger": _ranger(tree, who)
		"moon": _moon(tree, who)

static func _say(tree: SceneTree, lines: Array, cb := Callable(), choices: Array = []) -> void:
	tree.call_group("main", "dialog", lines, cb, choices)

static func _hints(item: String, spots: Array) -> String:
	var left := []
	for s in spots:
		if not Game.flag(s[0]): left.append(s[1])
	return ", ".join(left)

static func _granny(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_king"):
		_say(tree, [[who, "달이 저렇게 둥근 걸 보니, 네가 해냈구나. 장하다, %s야." % me()],
			[who, "이정표로 어디든 다시 다녀올 수 있으니, 가끔 들판 구경도 하고 오렴."]])
		return
	if Game.flag("boss_down"):
		if not Game.flag("thanked"):
			Game.set_flag("thanked")
			_say(tree, [[who, "우물에 물이 다시 차오르는구나. 고맙다, %s야." % me()],
				[who, "그런데 달샘 물이 동쪽 나루에서 자꾸 흐려진다는구나. 물안개가 걷히질 않는대."],
				[who, "숲지기의 빈터 동쪽으로 가면 물안개 나루다. 뱃사공 노인을 찾아보렴."],
				[me(), "맡겨 주세요! 마당 이정표로 금방 다녀올게요."]])
		else:
			var next := "물안개 나루"
			if Game.flag("boss_serpent"): next = "서리봉 고개"
			if Game.flag("boss_bear"): next = "달그림자 성터"
			_say(tree, [[who, "다음은 %s(이)구나. 마당의 달빛 이정표를 쓰면 열린 곳까지 바로 간단다." % next]])
		return
	if not Game.flag("talked_granny"):
		Game.set_flag("talked_granny")
		_say(tree, [[who, me() + "야, 마침 잘 왔다. 요 며칠 마을 우물이 바싹 말라 버렸단다."],
			[who, "우물물은 숲 안쪽 달샘에서 흘러오지. 그런데 숲지기가 달샘을 막고 사납게 날뛴다는구나."],
			[me(), "숲지기라면… 그 커다란 멧돼지 말이에요?"],
			[who, "그래. 원래는 순한 녀석인데, 달빛 조각을 잃어버리고부터 저 모양이야. 도깨비불들이 물어 갔다더구나."],
			[who, "들판 어딘가에 조각 셋이 흩어져 있을 게다. 셋을 모아 숲지기를 달래 주렴."],
			[who, "Z로 공격, X로 구르기. 그리고 이 갈고리 밧줄을 가져가렴. C로 던지면 말뚝까지 휙 날아간단다."],
			["", "갈고리 밧줄을 받았다! 말뚝에 걸면 날아가고, 작은 적은 끌어와 어지럽게 만든다."]])
		return
	if Game.shards >= Rules.SHARDS_NEEDED:
		Game.set_flag("told_ready")
		_say(tree, [[who, "셋 다 모았구나! 들판 동쪽 끝 숲길이 열렸을 게다."],
			[who, "숲지기는 몸집이 커서 돌진하다 나무에 부딪히면 한동안 휘청인단다. 그때를 노리렴."]])
		return
	_say(tree, [[who, "조각은 %d개 모았구나." % Game.shards],
		[who, "아직 안 가 본 곳이라면… %s 쪽을 살펴보렴." % _hints("shard", [["chest_n_shard", "들판 북쪽 언덕 위 상자"],
			["shard_island", "연못 가운데 작은 섬(동쪽 나무다리로)"], ["camp_wisp_shard", "동남쪽 도깨비불 무리"]])]])

static func _ferry(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_serpent"):
		_say(tree, [[who, "물안개가 걷히니 강 건너 산까지 훤하구먼. 북쪽 서리봉 길은 나루 동쪽 끝이여."]])
		return
	if not Game.flag("met_ferry"):
		Game.set_flag("met_ferry")
		_say(tree, [[who, "허허, 이 안개 속에 손님이라니. 배는 못 띄운다네. 이무기가 깨어나 소에서 날뛰거든."],
			[who, "강 곳곳에 옛 말뚝이 박혀 있지. 밧줄 쓸 줄 알면 건너다닐 만할 게야."],
			[who, "물방울 구슬 셋을 이무기 소에 바치면 녀석도 잠잠해질 텐데… 하나는 강 건너 갈대밭, 하나는 북쪽 바위섬, 하나는 두꺼비들이 품고 있다더군."],
			[who, "이무기는 물 위로 고개를 내밀 때 밧줄로 걸어 끌어내야 칼이 닿는다네. 명심하게."]])
		return
	_say(tree, [[who, "구슬은 %d개로구먼. 남은 곳은… %s." % [Game.count("pearl"), _hints("pearl", [["pearl_reeds", "강 건너 갈대밭"],
		["pearl_rock", "북쪽 바위섬"], ["camp_toad_pearl", "두꺼비 무리"]])]]])

static func _ranger(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_bear"):
		_say(tree, [[who, "얼음굴이 녹으니 봄 냄새가 나는구먼. 굴 동쪽 길이 성터로 이어지네. 그곳은… 밤이 끝나지 않는다더군."]])
		return
	if not Game.flag("met_ranger"):
		Game.set_flag("met_ranger")
		_say(tree, [[who, "이 추위에 맨몸으로 왔나? 산 꼭대기 서리곰이 불씨를 몽땅 꺼 버려서 봄이 오질 않아."],
			[who, "불씨 돌 셋이 이 고개 어딘가에 남아 있을 게야. 얼음 낭떠러지 건너편, 눈도깨비 굴, 그리고 장승 뒤편 상자."],
			[who, "서리곰은 몸을 일으켰다 내리칠 때 눈덩이를 부채처럼 뿌리지. 일어서는 걸 보면 바로 굴러!"]])
		return
	_say(tree, [[who, "불씨 돌은 %d개로군. 남은 곳은… %s." % [Game.count("ember"), _hints("ember", [["ember_cliff", "얼음 낭떠러지 건너편"],
		["camp_imp_ember", "눈도깨비 무리"], ["chest_jang_ember", "장승 뒤편 상자"]])]]])

static func _moon(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_king"):
		Game.set_flag("moon_thanks")
		_say(tree, [[who, "보세요, 달이 둥글어요. 이 빛은 달마루 우물까지 닿을 거예요."], [who, "언제든 놀러 와요. 저는 늘 여기 있을게요."]])
		return
	if not Game.flag("met_moon"):
		Game.set_flag("met_moon")
		_say(tree, [[who, "…여기까지 오다니. 저는 달님의 그림자를 지키던 아이예요."],
			[who, "도깨비왕이 달그림자를 조각내 삼키려 해요. 그래서 달이 자꾸 이지러지는 거예요."],
			[who, "조각 셋이 성터에 흩어져 있어요. 무너진 다리 건너편, 그림자 도깨비들 사이, 그리고 장승이 지키는 상자 안에."],
			[who, "도깨비왕은 순식간에 사라졌다 나타나요. 사라질 때 연기가 피어오르면 몸을 피하세요."]])
		return
	_say(tree, [[who, "조각은 %d개예요. 남은 곳은… %s." % [Game.count("gloom"), _hints("gloom", [["gloom_bridge", "무너진 다리 건너편"],
		["camp_shade_gloom", "그림자 도깨비 무리"], ["chest_ruin_gloom", "장승이 지키는 상자"]])]]])

static func _smith(tree: SceneTree, who: String) -> void:
	var first := not Game.flag("met_smith")
	Game.set_flag("met_smith")
	var lines := []
	if first:
		lines.append([who, "오, %s 왔냐! 할머니 심부름 간다며? 그 %s으론 어림없지." % [me(), weapon_name(0)]])
	var cost := Rules.sword_cost(Game.sword)
	var opts := []
	if cost > 0:
		opts.append("%s 다듬기 (엽전 %d)" % [weapon_name(Game.sword), cost])
	opts.append("약초 사기 (엽전 8)")
	opts.append("그냥 구경")
	lines.append([who, "엽전만 넉넉하면 뭐든 해 주마. 뭐가 필요하냐? (가진 엽전 %d)" % Game.coins])
	_say(tree, lines, func(i: int): _smith_pick(tree, who, opts[i], cost), opts)

static func _smith_pick(tree: SceneTree, who: String, pick: String, cost: int) -> void:
	if pick.contains("다듬기"):
		if Game.coins < cost:
			_say(tree, [[who, "엽전이 모자라구먼. 덤불이나 항아리를 베 보면 꽤 나온다."]])
			return
		Game.coins -= cost
		Game.sword += 1
		Game.changed.emit()
		Sound.play("chest", 0.0)
		_say(tree, [[who, "자, %s이다! 한 번 휘둘러 봐. 바람 소리부터 다르지?" % weapon_name(Game.sword)],
			["", "무기가 세졌다! (공격력 +1)"]])
	elif pick.begins_with("약초"):
		if Game.coins < 8:
			_say(tree, [[who, "엽전 여덟 닢은 있어야 한다."]])
		elif Game.herbs >= 5:
			_say(tree, [[who, "주머니가 꽉 찼구먼. 다섯 개면 충분해."]])
		else:
			Game.coins -= 8
			Game.herbs += 1
			Game.changed.emit()
			Sound.play("coin", 0.0)
			_say(tree, [[who, "다치면 V를 눌러 씹어 먹어라. 쓰지만 금방 낫는다."]])
	else:
		_say(tree, [[who, "언제든 와라. 숯불은 꺼지지 않으니까."]])

static func _kid(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_king"):
		_say(tree, [[who, "형아(누나) 최고! 달이 저렇게 큰 거 처음 봐!"]])
		return
	var tips := ["도깨비불은 불씨를 쏘기 전에 하얗게 번쩍여! 그때 굴러!",
		"멧돼지는 돌진하다 벽에 박으면 한동안 어질어질해. 그때 때리면 더 아파!",
		"덤불을 베면 가끔 엽전이 나와. 우리 엄마한텐 비밀이야.",
		"갈고리 밧줄로 작은 적을 끌어오면 빙글빙글 어지러워해. 그때 두들겨!",
		"마당 이정표를 만지면 가 봤던 곳으로 휙 갈 수 있대!"]
	var i := int(Game.flags.get("kid_i", 0))
	Game.flags["kid_i"] = (i + 1) % tips.size()
	_say(tree, [[who, tips[i]]])

## 달빛 이정표: 열린 곳으로 데려다준다
static func travel(tree: SceneTree) -> void:
	var dests := [["달마루 마을", "village", Vector2i(23, 18)]]
	dests.append(["솔바람 들판", "field", Vector2i(3, 21)])
	if Game.flag("boss_down"): dests.append(["물안개 나루", "ferry", Vector2i(3, 18)])
	if Game.flag("boss_serpent"): dests.append(["서리봉 고개", "peak", Vector2i(3, 30)])
	if Game.flag("boss_bear"): dests.append(["달그림자 성터", "ruins", Vector2i(3, 20)])
	var opts := []
	for d in dests:
		opts.append(d[0] + (" (여기)" if d[1] == Game.map_key else ""))
	opts.append("그만두기")
	_say(tree, [["달빛 이정표", "돌에 손을 대자 은은한 빛이 감돈다. 어디로 갈까?"]], func(i: int):
		if i < dests.size() and dests[i][1] != Game.map_key:
			tree.call_group("main", "go_map", dests[i][1], dests[i][2]), opts)
