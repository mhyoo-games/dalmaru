extends SceneTree
## godot --headless -s tests/run_tests.gd  (규칙·지도·대사가 서로 맞는지 확인)

var fails := 0
var passes := 0

func ok(cond: bool, what: String) -> void:
	if cond:
		passes += 1
	else:
		fails += 1
		printerr("실패: ", what)

func _init() -> void:
	_rules()
	_maps()
	_assets()
	print("통과 %d, 실패 %d" % [passes, fails])
	quit(1 if fails > 0 else 0)

func _rules() -> void:
	var rows := ["..P", ".PP", "..."]
	ok(Rules.dual_mask(rows, 0, 0, "P") == 0, "빈 모서리는 0")
	ok(Rules.dual_mask(rows, 2, 1, "P") == 0b0101 | 0b0010, "모서리 네 칸 섞기")
	ok(Rules.dual_mask(rows, 3, 1, "P") == 15, "지도 밖은 가장자리를 늘린다")
	ok(Rules.cell(rows, -5, 0) == ".", "왼쪽 밖")
	ok(Rules.hearts(5, 6) == [2, 2, 1], "하트 반 칸")
	ok(Rules.hearts(0, 6) == [0, 0, 0], "빈 하트")
	ok(Rules.take(1, 3) == 0, "체력은 0 아래로 안 감")
	ok(Rules.heal(5, 6, 4) == 6, "최대 체력까지만 회복")
	ok(Rules.sword_damage(0) == 1 and Rules.sword_damage(2) == 3, "목검 공격력")
	ok(Rules.sword_cost(0) == 30 and Rules.sword_cost(2) == -1, "목검 값")
	ok(Rules.death_coins(9) == 5 and Rules.death_coins(0) == 0, "쓰러지면 절반 잃음")
	ok(Rules.drop_for("mushroom", 0.0) == "heart" and Rules.drop_for("mushroom", 0.99) == "", "떨어뜨리는 것")
	ok(Rules.drop_for("boar", 0.5) == "coin" and Rules.coin_value("boar") == 3, "멧돼지는 엽전을 잘 줌")
	ok(not Rules.can_enter("shards", 2) and Rules.can_enter("shards", 3) and Rules.can_enter("", 0), "숲길은 조각 셋")
	ok(Rules.blocks("W", " ") and Rules.blocks(".", "T") and not Rules.blocks(".", "g") and not Rules.blocks("P", " "), "막히는 칸")
	ok(Rules.facing_row(Vector2(1, 0.2)) == 2 and Rules.facing_row(Vector2(0, -1)) == 1, "보는 방향 줄")

func _maps() -> void:
	var maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps.json"))
	ok(typeof(maps) == TYPE_DICTIONARY, "maps.json 읽힘")
	for k in ["village", "field", "grove"]:
		ok(maps.has(k), "지도 있음: " + k)
	var shard_sources := 0
	for k in maps:
		var m: Dictionary = maps[k]
		ok(m.ground.size() == m.h and m.objects.size() == m.h, k + " 줄 수")
		for r in m.ground + m.objects:
			ok(r.length() == m.w, k + " 줄 길이")
		for e in m.entities:
			ok(e.x >= 0 and e.x < m.w and e.y >= 0 and e.y < m.h, "%s %s 위치가 지도 안" % [k, e.type])
			if e.type == "warp":
				ok(maps.has(e.to), "%s 출구가 있는 지도로" % k)
				var t: Dictionary = maps[e.to]
				ok(not Rules.blocks(Rules.cell(t.ground, e.tx, e.ty), Rules.cell(t.objects, e.tx, e.ty)), "%s→%s 도착 칸이 비어 있음" % [k, e.to])
			if e.type in ["npc", "sign", "chest", "player"]:
				ok(not Rules.blocks(Rules.cell(m.ground, e.x, e.y), Rules.cell(m.objects, e.x, e.y)), "%s %s 자리가 막히지 않음" % [k, e.type])
			if e.type == "chest" and e.item == "shard": shard_sources += 1
			if e.type == "shard": shard_sources += 1
			if e.type == "camp" and e.reward == "shard": shard_sources += 1
			if e.type == "npc":
				ok(e.id in ["granny", "smith", "kid"], "대사가 있는 사람: " + e.id)
	ok(shard_sources == Rules.SHARDS_NEEDED, "달빛 조각은 딱 셋")

func _assets() -> void:
	for n in ["tiles", "hero", "mushroom", "wisp", "boar", "boss", "hearts", "coin", "moonshard", "ui_box", "hanok", "hanok_big", "well"]:
		ok(ResourceLoader.exists("res://assets/sprites/%s.png" % n), "그림 있음: " + n)
	for n in ["village", "field", "boss", "victory"]:
		ok(ResourceLoader.exists("res://assets/music/%s.wav" % n), "배경음 있음: " + n)
	var hero: Texture2D = load("res://assets/sprites/hero.png")
	ok(hero.get_width() == 16 * 8 and hero.get_height() == 22 * 3, "주인공 칸 크기 8×3")
