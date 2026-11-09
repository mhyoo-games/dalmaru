class_name Dialogs
extends RefCounted
## 마을 사람 대사. 진행 상황(Game.flags, 조각 수)에 따라 달라진다.

static func has_news(id: String) -> bool:
	match id:
		"granny":
			return not Game.flag("talked_granny") or (Game.shards >= Rules.SHARDS_NEEDED and not Game.flag("told_ready")) \
				or (Game.flag("boss_down") and not Game.flag("thanked"))
		"smith":
			return Game.flag("talked_granny") and not Game.flag("met_smith")
	return false

static func talk(tree: SceneTree, id: String, who: String) -> void:
	match id:
		"granny": _granny(tree, who)
		"smith": _smith(tree, who)
		"kid": _kid(tree, who)

static func _say(tree: SceneTree, lines: Array, cb := Callable(), choices: Array = []) -> void:
	tree.call_group("main", "dialog", lines, cb, choices)

static func _granny(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_down"):
		Game.set_flag("thanked")
		_say(tree, [[who, "우물에 물이 다시 차오르는구나. 고맙다, 마루야."],
			[who, "숲지기도 이제 편히 잠들었겠지. 오늘 밤엔 달이 유난히 밝겠어."],
			["마루", "헤헤. 다음엔 무슨 일이 생겨도 제가 갈게요!"],
			[who, "녀석, 듬직하기는. (달마루 모험기 1장 끝 — 계속 만들고 있어요)"]])
		return
	if not Game.flag("talked_granny"):
		Game.set_flag("talked_granny")
		_say(tree, [[who, "마루야, 마침 잘 왔다. 요 며칠 마을 우물이 바싹 말라 버렸단다."],
			[who, "우물물은 숲 안쪽 달샘에서 흘러오지. 그런데 숲지기가 달샘을 막고 사납게 날뛴다는구나."],
			["마루", "숲지기라면… 그 커다란 멧돼지 말이에요?"],
			[who, "그래. 원래는 순한 녀석인데, 달빛 조각을 잃어버리고부터 저 모양이야. 도깨비불들이 물어 갔다더구나."],
			[who, "들판 어딘가에 조각 셋이 흩어져 있을 게다. 셋을 모아 숲지기를 달래 주렴."],
			[who, "Z로 목검을 휘두르고, X로 구르면 웬만한 건 피할 수 있단다. 대장간 쇠돌이한테도 들러 보고."]])
		return
	if Game.shards >= Rules.SHARDS_NEEDED:
		Game.set_flag("told_ready")
		_say(tree, [[who, "셋 다 모았구나! 들판 동쪽 끝 숲길이 열렸을 게다."],
			[who, "숲지기는 몸집이 커서 돌진하다 나무에 부딪히면 한동안 휘청인단다. 그때를 노리렴."]])
		return
	var hints := []
	if not Game.flag("chest_n"): hints.append("들판 북쪽 언덕 위 상자")
	if not Game.flag("shard_island"): hints.append("연못 가운데 작은 섬")
	if not Game.flag("camp_wisp"): hints.append("동남쪽 도깨비불 무리")
	_say(tree, [[who, "조각은 %d개 모았구나." % Game.shards],
		[who, "아직 안 가 본 곳이라면… %s 쪽을 살펴보렴." % ", ".join(hints)]])

static func _smith(tree: SceneTree, who: String) -> void:
	var first := not Game.flag("met_smith")
	Game.set_flag("met_smith")
	var lines := []
	if first:
		lines.append([who, "오, 마루 왔냐! 할머니 심부름 간다며? 그 목검으론 어림없지."])
	var cost := Rules.sword_cost(Game.sword)
	var opts := []
	if cost > 0:
		opts.append("목검 다듬기 (엽전 %d)" % cost)
	opts.append("약초 사기 (엽전 8)")
	opts.append("그냥 구경")
	lines.append([who, "엽전만 넉넉하면 뭐든 해 주마. 뭐가 필요하냐? (가진 엽전 %d)" % Game.coins])
	_say(tree, lines, func(i: int): _smith_pick(tree, who, opts[i], cost), opts)

static func _smith_pick(tree: SceneTree, who: String, pick: String, cost: int) -> void:
	if pick.begins_with("목검"):
		if Game.coins < cost:
			_say(tree, [[who, "엽전이 모자라구먼. 덤불이나 항아리를 베 보면 꽤 나온다."]])
			return
		Game.coins -= cost
		Game.sword += 1
		Game.changed.emit()
		Sound.play("chest", 0.0)
		var nm: String = ["", "단단한 목검", "박달 목검"][Game.sword]
		_say(tree, [[who, "자, %s이다! 한 번 휘둘러 봐. 바람 소리부터 다르지?" % nm], ["", "목검이 세졌다! (공격력 %d)" % Rules.sword_damage(Game.sword)]])
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
			_say(tree, [[who, "다치면 C를 눌러 씹어 먹어라. 쓰지만 금방 낫는다."]])
	else:
		_say(tree, [[who, "언제든 와라. 숯불은 꺼지지 않으니까."]])

static func _kid(tree: SceneTree, who: String) -> void:
	if Game.flag("boss_down"):
		_say(tree, [[who, "형 최고! 나도 크면 박달 목검 살 거야!"]])
		return
	var tips := ["형, 도깨비불은 불씨를 쏘기 전에 하얗게 번쩍여! 그때 굴러!",
		"멧돼지는 돌진하다 벽에 박으면 한동안 어질어질해. 그때 때리면 더 아파!",
		"덤불을 베면 가끔 엽전이 나와. 우리 엄마한텐 비밀이야.",
		"Z를 빨리 두 번 누르면 두 번 휘둘러. 두 번째가 더 세!"]
	var i := int(Game.flags.get("kid_i", 0))
	Game.flags["kid_i"] = (i + 1) % tips.size()
	_say(tree, [[who, tips[i]]])
