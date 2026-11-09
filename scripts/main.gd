extends Node
## 화면 전환을 맡는다: 처음 화면 ↔ 지도, 지도 사이 이동, 쓰러짐, 대왕 연출.

var world: Node2D
var hud: CanvasLayer
var title: Control
var fade: ColorRect
var moving := false

func _ready() -> void:
	add_to_group("main")
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	var fl := CanvasLayer.new()
	fl.layer = 20
	add_child(fl)
	fade = ColorRect.new()
	fade.color = Color(0.08, 0.05, 0.12)
	fade.size = Vector2(384, 216)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.add_child(fade)
	show_title()
	_fade_to(0.0, 0.6)

func _fade_to(a: float, sec := 0.35) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", a, sec)
	await tw.finished

func show_title() -> void:
	get_tree().paused = false
	Game.busy = false
	if world:
		world.queue_free()
		world = null
	hud.set_visible_hud(false)
	hud.boss_show(false)
	title = preload("res://scripts/title.gd").new()
	hud.root.add_child(title)
	hud.root.move_child(title, 0)
	Sound.music("village")

func start(cont: bool) -> void:
	if cont and Game.load_save():
		pass
	else:
		Game.reset()
	await _fade_to(1.0, 0.4)
	title.queue_free()
	title = null
	hud.set_visible_hud(true)
	var spawn := Vector2i(-1, -1)
	if cont and Game.map_key != "village":
		spawn = _entry_of(Game.map_key)
	_load(Game.map_key, spawn)
	await _fade_to(0.0, 0.5)
	if not cont:
		var me: String = Rules.hero(Game.hero).name
		hud.open_dialog([[me, "으아암… 잘 잤다! 오늘따라 마을이 조용하네."],
			[me, "촌장 할머니가 아침부터 찾으셨다고 했지. 마당으로 가 봐야겠다."],
			["", "방향키(WASD)로 걷고, Z 공격·말 걸기, X 구르기, C 갈고리 밧줄, V 약초, Esc 쉬기."]])

func _entry_of(key: String) -> Vector2i:
	# 이어하기: 그 지도로 들어오는 출구 자리에서 시작
	for k in Game.maps:
		for e in Game.maps[k].entities:
			if e.type == "warp" and e.to == key:
				return Vector2i(e.tx, e.ty)
	return Vector2i(-1, -1)

func _load(key: String, spawn: Vector2i) -> void:
	if world:
		world.queue_free()
	world = preload("res://scripts/world.gd").new()
	world.add_to_group("world")
	add_child(world)
	move_child(world, 0)
	world.build(key, spawn)
	Game.map_key = key
	var m: Dictionary = Game.maps[key]
	var bk := _boss_of(key)
	if bk == "":
		Sound.music(m.music)
	elif Game.flag(Rules.boss_flag(bk)):
		Sound.music(Game.maps[Rules.CHAPTERS[Rules.chapter_of(key)].maps[0]].music)
	else:
		Sound.stop_music()
	hud.show_banner(m.name)
	hud.refresh()
	hud.boss_show(false)
	Game.save()

func _boss_of(key: String) -> String:
	for e in Game.maps[key].entities:
		if e.type == "boss": return e.get("kind", "boar")
	return ""

func go_map(key: String, spawn: Vector2i) -> void:
	if moving:
		return
	moving = true
	Game.busy = true
	Sound.play("warp", 0.0, -8)
	await _fade_to(1.0, 0.3)
	_load.call_deferred(key, spawn)
	await get_tree().process_frame
	await get_tree().process_frame
	Game.busy = false
	await _fade_to(0.0, 0.35)
	moving = false

func dialog(lines: Array, cb := Callable(), choices: Array = []) -> void:
	hud.open_dialog(lines, cb, choices)

func got_shard() -> void:
	got_item("shard")

func got_item(item: String) -> void:
	var nm := ""
	var where := ""
	for c in Rules.CHAPTERS:
		if Rules.CHAPTERS[c].item == item:
			nm = Rules.CHAPTERS[c].item_name
			where = ["", "들판 동쪽 끝 숲길", "나루 동쪽 끝 이무기 소", "고개 꼭대기 얼음굴", "성터 안쪽 옛 궁터"][c]
	var me: String = Rules.hero(Game.hero).name
	var n := Game.count(item)
	if n >= Rules.SHARDS_NEEDED:
		hud.open_dialog([["", "%s을(를) 모두 모았다! (%d/%d)" % [nm, n, Rules.SHARDS_NEEDED]],
			[me, "셋이 모이니 따뜻하게 울린다… 이제 %s(으)로 가 보자." % where]])
	else:
		hud.open_dialog([["", "%s을(를) 얻었다! (%d/%d)" % [nm, n, Rules.SHARDS_NEEDED]]])
	hud.refresh()
	Game.save()

func player_died() -> void:
	await get_tree().create_timer(0.6).timeout
	await _fade_to(1.0, 0.8)
	Game.coins = Rules.death_coins(Game.coins)
	Game.hp = Game.max_hp
	Game.changed.emit()
	_load("village", Vector2i(10, 21))
	await _fade_to(0.0, 0.6)
	hud.open_dialog([["마루", "으윽… 집이다. 누가 데려다줬나 봐."], ["", "엽전을 절반 잃었다. 체력은 모두 돌아왔다."]])

func boss_start(b: Node) -> void:
	var nm := "이무기 소의 이무기" if b.kind == "serpent" else String(b.KINDS[b.kind].name)
	hud.boss_show(true, nm)
	hud.boss_hp(1, 1)

func boss_hp(hp: int, mx: int) -> void:
	hud.boss_hp(hp, mx)

func boss_defeated(b: Node) -> void:
	hud.boss_show(false)
	var kind: String = b.kind
	Game.set_flag(Rules.boss_flag(kind))
	Game.max_hp += 2
	Game.hp = Game.max_hp
	Game.changed.emit()
	Sound.play("shard", 0.0)
	for s in get_tree().get_nodes_in_group("spring"):
		s.refill()
	Sound.music("victory", false)
	await get_tree().create_timer(1.2).timeout
	Game.busy = false
	var me: String = Rules.hero(Game.hero).name
	var lines := []
	match kind:
		"boar":
			lines = [["", "달빛 조각 셋이 숲지기의 이마로 날아가 스며들었다…"],
				["숲지기", "……부우. (거친 숨이 잦아들고, 눈빛이 순해졌다)"],
				["", "달샘에 다시 달빛이 고이기 시작했다. 최대 체력이 하트 하나만큼 늘었다!"],
				[me, "이제 우물에도 물이 돌아오겠지. 할머니께 알려 드리자!"]]
		"serpent":
			lines = [["", "물방울 구슬 셋이 이무기의 비늘 사이로 스며들자, 물안개가 걷히기 시작했다."],
				["이무기", "…오래 묵은 꿈에서 깼구나. 용이 되려다 그림자에 홀렸던 게지."],
				["이무기", "북쪽 서리봉도 얼어붙었다. 산 위의 불씨가 꺼진 탓이야."],
				["", "최대 체력이 하트 하나만큼 늘었다! 나루 동쪽 길로 서리봉 고개에 갈 수 있다."]]
		"bear":
			lines = [["", "불씨 돌 셋이 서리곰의 가슴에서 따뜻하게 타올랐다."],
				["서리곰", "크르르… 춥고, 졸리다… 이제야 겨울잠을 잘 수 있겠군."],
				["", "얼음굴 안쪽 벽에 보랏빛 달그림자가 길게 드리웠다."],
				["", "최대 체력이 하트 하나만큼 늘었다! 굴 동쪽으로 달그림자 성터에 갈 수 있다."]]
		"king":
			lines = [["", "달그림자 조각 셋이 도깨비왕의 방망이에 박히자, 검은 안개가 터져 나갔다."],
				["도깨비왕", "허허… 달을 통째로 삼키려다 체했구먼. 꼬맹이가 제법이야."],
				["달님 아씨", "고마워요. 그림자에 가렸던 달이 다시 둥글게 차오를 거예요."],
				[me, "이제 달마루에도 밤마다 달빛이 가득하겠네요!"],
				["", "— 달마루 모험기 끝 — 함께해 주셔서 고맙습니다. (이정표로 어디든 다시 다닐 수 있어요)"]]
	hud.open_dialog(lines, func():
		Sound.music(Game.maps[Game.map_key].music if kind != "boar" else "field"))
	Game.save()
