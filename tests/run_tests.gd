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
	ok(not Rules.can_enter("shards", {"shard": 2}) and Rules.can_enter("shards", {"shard": 3}) and Rules.can_enter("", {}), "숲길은 조각 셋")
	ok(Rules.can_enter("item:pearl", {"pearl": 3}) and not Rules.can_enter("item:pearl", {"shard": 3}), "장마다 물건")
	ok(Rules.can_enter("flag:boss_down", {}, {"boss_down": true}) and not Rules.can_enter("flag:boss_bear", {}, {}), "대왕을 달래야 열림")
	ok(Rules.weapon_damage("sword", 0, false, 1) == 2 and Rules.weapon_damage("bow", 1, true) == 3 and Rules.weapon_damage("club", 0) == 2, "무기별 피해")
	ok(Rules.hero("dolsoe").hp == 8 and Rules.hero("없음").name == "마루", "주인공 셋")
	ok(Rules.chapter_of("lake") == 2 and Rules.chapter_of("village") == 0 and Rules.boss_flag("bear") == "boss_bear", "장 나누기")
	ok(Rules.blocks("W", " ") and Rules.blocks(".", "T") and not Rules.blocks(".", "g") and not Rules.blocks("P", " "), "막히는 칸")
	ok(Rules.facing_row(Vector2(1, 0.2)) == 2 and Rules.facing_row(Vector2(0, -1)) == 1, "보는 방향 줄")

func _maps() -> void:
	var maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps.json"))
	ok(typeof(maps) == TYPE_DICTIONARY, "maps.json 읽힘")
	for k in ["village", "field", "grove", "ferry", "lake", "peak", "cave", "ruins", "throne"]:
		ok(maps.has(k), "지도 있음: " + k)
	var sources := {}
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
			var it := ""
			if e.type == "chest": it = e.item
			if e.type in ["shard", "pearl", "ember", "gloom"]: it = e.type
			if e.type == "camp": it = e.get("reward", "shard")
			if it != "": sources[it] = sources.get(it, 0) + 1
			if e.type == "npc":
				ok(e.id in ["granny", "smith", "kid", "ferry", "ranger", "moon"], "대사가 있는 사람: " + e.id)
	for c in Rules.CHAPTERS:
		ok(sources.get(Rules.CHAPTERS[c].item, 0) == Rules.SHARDS_NEEDED, "%d장 물건은 딱 셋" % c)
		for mk in Rules.CHAPTERS[c].maps:
			ok(maps.has(mk), "%d장 지도 %s" % [c, mk])
		var has_boss := false
		for e in maps[Rules.CHAPTERS[c].maps[1]].entities:
			if e.type == "boss" and e.kind == Rules.CHAPTERS[c].boss: has_boss = true
		ok(has_boss, "%d장 대왕" % c)
	# 들어오는 자리(출구 도착 칸·시작 칸)에서 걸어서 모든 것에 닿는지
	for k in maps:
		var m: Dictionary = maps[k]
		var starts := []
		for kk in maps:
			for e in maps[kk].entities:
				if e.type == "warp" and e.to == k: starts.append(Vector2i(e.tx, e.ty))
		for e in m.entities:
			if e.type == "player": starts.append(Vector2i(e.x, e.y))
		ok(not starts.is_empty(), k + " 들어오는 자리가 있음")
		for s in starts:
			var seen := Rules.reachable(m, s)
			for e in m.entities:
				var c := Vector2i(e.x, e.y)
				if e.type == "house": c = Vector2i(e.door[0], e.door[1] + 1)
				if e.type == "well": c = Vector2i(e.x, e.y + 1)
				if e.type in ["spring"] or (e.type == "boss" and e.kind == "serpent"): continue
				if e.type == "warp":
					var any := false
					for yy in range(e.y, e.y + e.h):
						if Rules.can_reach(seen, Vector2i(e.x, yy)): any = true
					ok(any, "%s: %s에서 출구(→%s)에 닿음" % [k, s, e.to])
				else:
					ok(Rules.can_reach(seen, c), "%s: %s에서 %s(%d,%d)에 닿음" % [k, s, e.get("id", e.type), e.x, e.y])
	ok(Rules.reachable({"w": 3, "h": 1, "ground": [".W."], "objects": ["   "], "entities": []}, Vector2i(0, 0)).size() == 1, "물은 못 건넘")
	ok(Rules.reachable({"w": 3, "h": 1, "ground": [".D."], "objects": ["   "], "entities": []}, Vector2i(0, 0)).size() == 3, "다리는 건넘")
	var rope_map := {"w": 9, "h": 1, "ground": ["...WWW..."], "objects": ["  O   O  "], "entities": []}
	ok(Rules.reachable(rope_map, Vector2i(0, 0)).has(Vector2i(8, 0)), "말뚝으로 물을 건넘")
	var far_map := {"w": 12, "h": 1, "ground": ["..WWWWWWWW.."], "objects": ["           O"], "entities": []}
	ok(not Rules.reachable(far_map, Vector2i(0, 0)).has(Vector2i(11, 0)), "밧줄이 안 닿으면 못 감")

func _assets() -> void:
	for n in ["post", "toad", "snowimp", "frostblob", "shade", "king", "bear", "serpent_head", "serpent_body", "tiles_snow", "tiles_swamp", "tiles_night", "hero_sori", "hero_dolsoe", "item_pearl", "item_ember", "item_gloom", "waystone", "npc_ferry", "npc_ranger", "npc_moon", "tiles", "hero", "mushroom", "wisp", "boar", "boss", "hearts", "coin", "moonshard", "ui_box", "hanok", "hanok_big", "well"]:
		ok(ResourceLoader.exists("res://assets/sprites/%s.png" % n), "그림 있음: " + n)
	for n in ["village", "field", "boss", "victory"]:
		ok(ResourceLoader.exists("res://assets/music/%s.wav" % n), "배경음 있음: " + n)
	var hero: Texture2D = load("res://assets/sprites/hero.png")
	ok(hero.get_width() == 16 * 8 and hero.get_height() == 22 * 3, "주인공 칸 크기 8×3")
