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
		hud.open_dialog([["마루", "으아암… 잘 잤다! 오늘따라 마을이 조용하네."],
			["마루", "촌장 할머니가 아침부터 찾으셨다고 했지. 마당으로 가 봐야겠다."],
			["", "방향키(WASD)로 걷고, Z로 말 걸기·휘두르기, X로 구르기. Esc는 쉬기."]])

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
	if not (key == "grove" and not Game.flag("boss_down")):
		Sound.music(m.music)
	else:
		Sound.stop_music()
	hud.show_banner(m.name)
	hud.boss_show(false)
	Game.save()

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
	if Game.shards >= Rules.SHARDS_NEEDED:
		hud.open_dialog([["", "달빛 조각을 모두 모았다! (%d/%d)" % [Game.shards, Rules.SHARDS_NEEDED]],
			["마루", "조각들이 서로 끌어당기듯 따뜻해… 이제 숲지기에게 가 보자. 들판 동쪽 끝이랬지."]])
	else:
		hud.open_dialog([["", "달빛 조각을 얻었다! (%d/%d)" % [Game.shards, Rules.SHARDS_NEEDED]]])
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

func boss_start(_b: Node) -> void:
	hud.boss_show(true)
	hud.boss_hp(1, 1)

func boss_hp(hp: int, mx: int) -> void:
	hud.boss_hp(hp, mx)

func boss_defeated(_b: Node) -> void:
	hud.boss_show(false)
	Game.set_flag("boss_down")
	Game.max_hp += 2
	Game.hp = Game.max_hp
	Game.changed.emit()
	Sound.play("shard", 0.0)
	for s in get_tree().get_nodes_in_group("spring"):
		s.refill()
	Sound.music("victory", false)
	await get_tree().create_timer(1.2).timeout
	Game.busy = false
	hud.open_dialog([["", "달빛 조각 셋이 숲지기의 이마로 날아가 스며들었다…"],
		["숲지기", "……부우. (거친 숨이 잦아들고, 눈빛이 순해졌다)"],
		["", "달샘에 다시 달빛이 고이기 시작했다. 최대 체력이 하트 하나만큼 늘었다!"],
		["마루", "이제 우물에도 물이 돌아오겠지. 할머니께 알려 드리자!"]], func():
			Sound.music("field"))
	Game.save()
