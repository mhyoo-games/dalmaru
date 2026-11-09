extends Node
## 개발용 자동 조작: godot -- --dev=<장면> 으로 실행하면 그 장면을 찍고 끝낸다. 평소에는 아무것도 안 함.

var plan := ""
var out := "/tmp/dalmaru"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dev="):
			plan = a.substr(6)
		if a.begins_with("--out="):
			out = a.substr(6)
	if plan == "":
		queue_free()
		return
	DirAccess.make_dir_recursive_absolute(out)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run()

func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, n])
	print("shot ", n)

func wait(s: float) -> void:
	await get_tree().create_timer(s, true, false, true).timeout

func _send(a: String, on: bool) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = on
	e.strength = 1.0
	Input.parse_input_event(e)

func hold(a: String, s: float) -> void:
	_send(a, true)
	await wait(s)
	_send(a, false)

func tap(a: String) -> void:
	_send(a, true)
	await get_tree().process_frame
	await get_tree().process_frame
	_send(a, false)
	await get_tree().process_frame

func close_dialogs() -> void:
	var hud = get_tree().get_first_node_in_group("main").hud
	for i in 40:
		if not hud.talking: return
		await tap("act")
		await wait(0.05)

func main() -> Node:
	return get_tree().get_first_node_in_group("main")

func _run() -> void:
	await wait(0.8)
	await shot("title")
	if plan == "title":
		get_tree().quit(); return
	if plan == "select":
		if Game.has_save(): await tap("down")
		await tap("act"); await wait(0.4)
		await shot("select_maru")
		await tap("right"); await wait(0.3); await shot("select_sori")
		await tap("right"); await wait(0.3); await shot("select_dolsoe")
		await tap("left"); await wait(0.2)
		await tap("act"); await wait(1.6)
		await close_dialogs()
		print("hero: ", Game.hero, " hp ", Game.max_hp)
		main().go_map("field", Vector2i(16, 22)); await wait(1.2)
		var p0 = get_tree().get_first_node_in_group("player")
		p0.invuln = 9999.0; p0.no_blink = true
		for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
		var w0 = get_tree().get_first_node_in_group("world")
		var en = w0.spawn_enemy("boar", p0.position + Vector2(90, 0))
		await wait(0.4)
		p0.facing = Vector2.RIGHT
		await tap("act"); await wait(0.08); await shot("bow_shot")
		await wait(0.3)
		_send("act", true); await wait(0.7); await shot("bow_charge"); _send("act", false); await wait(0.06); await shot("bow_pierce")
		await wait(0.5)
		print("boar hp after arrows: ", en.hp if is_instance_valid(en) else "dead")
		await tap("item"); await wait(0.15); await shot("rope_throw")
		await wait(0.5); await shot("rope_after")
		get_tree().quit(); return
	if plan in ["club"]:
		Game.hero = "dolsoe"
	main().start(false)
	await wait(1.4)
	await shot("intro_dialog")
	await close_dialogs()
	await wait(0.3)
	await shot("village_start")
	match plan:
		"village":
			await hold("up", 0.9)
			await hold("right", 1.0)
			await shot("village_walk")
			await tap("act")
			await wait(0.08)
			await shot("village_attack")
			await hold("up", 0.6)
			await shot("village_plaza")
		"warp":
			# 마을 동쪽 출구까지 걸어가서 들판으로 넘어가는지
			var p = get_tree().get_first_node_in_group("player")
			p.position = Vector2(38 * 16 + 8, 15 * 16 + 14)
			await hold("right", 2.0)
			await wait(1.0)
			print("map after walk: ", Game.map_key)
			await shot("warp_field")
			p = get_tree().get_first_node_in_group("player")
			p.position = Vector2(4 * 16, 21 * 16 + 14)
			await hold("left", 1.5)
			await wait(1.0)
			print("map after walk back: ", Game.map_key)
			await shot("warp_back")
		"full":
			# 처음부터 끝까지 순서대로 (순간이동 + 직접 호출로 빠르게)
			var p = get_tree().get_first_node_in_group("player")
			p.invuln = 9999.0
			for n in get_tree().get_nodes_in_group("interact"):
				if n.get("npc_id") == "granny":
					p.position = n.position + Vector2(0, 16); p.facing = Vector2.UP
			await tap("act"); await wait(0.3); await close_dialogs()
			print("talked granny: ", Game.flag("talked_granny"))
			p.position = Vector2(41 * 16, 15 * 16 + 14)
			await hold("right", 1.2); await wait(1.0)
			print("map: ", Game.map_key)
			p = get_tree().get_first_node_in_group("player"); p.invuln = 9999.0
			# 동쪽 숲길: 조각이 모자라면 못 들어감
			p.position = Vector2(60 * 16, 22 * 16 + 14)
			await hold("right", 1.0); await wait(0.5)
			print("blocked without shards, map: ", Game.map_key)
			await close_dialogs()
			# 상자
			for n in get_tree().get_nodes_in_group("interact"):
				if n.get("chest_id") == "chest_n":
					p.position = n.position + Vector2(0, 16); p.facing = Vector2.UP
			await wait(0.2); await tap("act"); await wait(0.5); await close_dialogs()
			print("after chest shards: ", Game.shards)
			# 섬
			p.position = Vector2(13 * 16 + 8, 33 * 16 + 14); await wait(0.6); await close_dialogs()
			print("after island shards: ", Game.shards)
			# 무리
			p.position = Vector2(48 * 16, 30 * 16 + 40); await wait(1.0)
			for i in 6:
				for e in get_tree().get_nodes_in_group("enemy"):
					if e.global_position.distance_to(p.global_position) < 120: e.take_hit(99, p.global_position)
				await wait(0.3)
			await wait(0.5)
			var w = get_tree().get_first_node_in_group("world")
			for n in w.ysort.get_children():
				if n.get("kind") == "shard": p.position = n.position
			await wait(0.6); await close_dialogs()
			print("after camp shards: ", Game.shards)
			p.position = Vector2(60 * 16, 22 * 16 + 14)
			await hold("right", 1.2); await wait(1.2)
			print("map: ", Game.map_key)
			p = get_tree().get_first_node_in_group("player"); p.invuln = 9999.0; p.no_blink = true
			var b = get_tree().get_first_node_in_group("boss")
			p.position = b.position - Vector2(100, 0)
			await wait(2.4)
			b.take_hit(99, p.global_position)
			await wait(4.0)
			await shot("full_end")
			await close_dialogs()
			print("boss_down: ", Game.flag("boss_down"), " max_hp ", Game.max_hp)
			main().go_map("village", Vector2i(10, 21)); await wait(1.2)
			p = get_tree().get_first_node_in_group("player")
			for n in get_tree().get_nodes_in_group("interact"):
				if n.get("npc_id") == "granny":
					p.position = n.position + Vector2(0, 16); p.facing = Vector2.UP
			await tap("act"); await wait(1.0); await shot("full_thanks"); await close_dialogs()
			print("thanked: ", Game.flag("thanked"))
		"club":
			main().go_map("field", Vector2i(16, 22)); await wait(1.2)
			var p = get_tree().get_first_node_in_group("player")
			p.invuln = 9999.0; p.no_blink = true
			for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
			var w = get_tree().get_first_node_in_group("world")
			var en = w.spawn_enemy("mushroom", p.position + Vector2(22, 0))
			var en2 = w.spawn_enemy("mushroom", p.position + Vector2(-26, 10))
			await wait(0.3); p.facing = Vector2.RIGHT
			await tap("act"); await wait(0.12); await shot("club_swing")
			await wait(0.4)
			_send("act", true); await wait(0.7); _send("act", false); await wait(0.08); await shot("club_slam")
			print("club: ", en.hp if is_instance_valid(en) else "dead", " ", en2.hp if is_instance_valid(en2) else "dead")
		"rope":
			main().go_map("ferry", Vector2i(17, 18)); await wait(1.2)
			for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
			var p = get_tree().get_first_node_in_group("player")
			p.no_blink = true
			p.position = Vector2(17 * 16 + 8, 18 * 16 + 14)
			for i in 4:
				p.facing = Vector2.RIGHT
				await tap("item"); await wait(0.1)
				if i == 1: await shot("rope_fly")
				await wait(0.9)
				print("rope ", i, " x tile ", int(p.position.x / 16), " state ", p.state)
			await shot("rope_cross")
		"chapters":
			var p = get_tree().get_first_node_in_group("player")
			Game.set_flag("boss_down"); Game.items = {"shard": 3, "pearl": 3, "ember": 3, "gloom": 3}
			for mk in [["ferry", Vector2i(8, 18)], ["lake", Vector2i(3, 13)], ["peak", Vector2i(8, 30)], ["cave", Vector2i(4, 12)], ["ruins", Vector2i(8, 20)], ["throne", Vector2i(5, 13)]]:
				main().go_map(mk[0], mk[1]); await wait(1.3)
				p = get_tree().get_first_node_in_group("player"); p.invuln = 9999.0; p.no_blink = true
				await shot("map_" + mk[0])
				var b = get_tree().get_first_node_in_group("boss")
				if b:
					var c: Vector2 = b.lake.get_center() if b.get("kind") == "serpent" else b.position
					p.position = c + Vector2(-100 if b.get("kind") != "serpent" else -150, 0)
					await wait(2.6)
					await shot("boss_" + mk[0])
					if b.get("kind") == "serpent":
						while b.state != "rise" and b.state != "spit":
							await wait(0.1)
						p.position = b.position + Vector2(-70, 0)
						p.facing = Vector2.RIGHT
						var w = get_tree().get_first_node_in_group("world")
						await tap("item"); await wait(0.5)
						print("serpent state after rope: ", b.state)
						await shot("serpent_beached")
					await wait(2.0)
					await shot("boss2_" + mk[0])
					b.hurt_cd = 0
					b.take_hit(999, p.global_position)
					await wait(4.2)
					await shot("end_" + mk[0])
					await close_dialogs()
					print(mk[0], " boss ", b.kind, " flag ", Game.flag(Rules.boss_flag(b.kind)))
		"pickup":
			# 바로 앞에서 잡은 적의 엽전이 발밑에 떨어져도 먹히는지
			main().go_map("field", Vector2i(16, 22)); await wait(1.2)
			for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
			var p = get_tree().get_first_node_in_group("player")
			p.invuln = 9999.0
			var w = get_tree().get_first_node_in_group("world")
			var before := Game.coins
			for i in 3:
				w.spawn_pickup("coin", p.position, "", 1)
			await wait(1.0)
			print("coins ", before, " -> ", Game.coins)
		"bridge":
			main().go_map("field", Vector2i(23, 33))
			await wait(1.2)
			for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
			await shot("bridge_start")
			await hold("left", 2.2)
			await wait(0.6)
			print("shards after island: ", Game.shards)
			await shot("bridge_island")
			await close_dialogs()
		"field":
			main().go_map("field", Vector2i(16, 22))
			await wait(1.2)
			await shot("field_enter")
			await hold("right", 0.8)
			await tap("act"); await wait(0.06); await shot("field_attack")
			await wait(1.2)
			await shot("field_fight")
			await tap("roll"); await wait(0.1); await shot("field_roll")
		"grove":
			Game.shards = 3
			main().go_map("grove", Vector2i(6, 12))
			await wait(1.0)
			get_tree().get_first_node_in_group("player").invuln = 9999.0
			get_tree().get_first_node_in_group("player").no_blink = true
			await shot("grove_enter")
			await hold("right", 1.6)
			await wait(0.4)
			await shot("boss_intro")
			await wait(2.0)
			await shot("boss_fight")
			var b = get_tree().get_first_node_in_group("boss")
			for i in 14:
				await wait(0.35)
				var p = get_tree().get_first_node_in_group("player")
				if b and is_instance_valid(b):
					p.facing = (b.global_position - p.global_position).normalized()
				await tap("act")
				if i % 4 == 1: await shot("boss_%d" % i)
				await tap("roll")
			b._go("stun")
			b.velocity = Vector2.ZERO
			var p2 = get_tree().get_first_node_in_group("player")
			p2.position = b.position - Vector2(26, 0)
			p2.facing = Vector2.RIGHT
			await wait(0.1)
			var before: int = b.hp
			await tap("act")
			await wait(0.2)
			print("boss hp ", before, " -> ", b.hp)
			await shot("boss_hit")
			await wait(0.4)
			b.take_hit(99, p2.global_position)
			await wait(0.6)
			await shot("boss_dying")
			await wait(3.4)
			print("boss state ", b.state if is_instance_valid(b) else "freed", " st ", b.st if is_instance_valid(b) else 0, " busy ", Game.busy, " ts ", Engine.time_scale)
			await shot("boss_calm")
			await close_dialogs()
			await wait(2.6)
			await shot("spring_full")
		"combat":
			main().go_map("field", Vector2i(16, 22))
			await wait(1.0)
			var w = get_tree().get_first_node_in_group("world")
			var p = get_tree().get_first_node_in_group("player")
			for e in get_tree().get_nodes_in_group("enemy"): e.queue_free()
			w.spawn_enemy("mushroom", p.position + Vector2(60, 0))
			w.spawn_enemy("boar", p.position + Vector2(-90, 40))
			w.spawn_enemy("wisp", p.position + Vector2(60, -60))
			await wait(1.0)
			await shot("c_spawn")
			p.facing = Vector2.RIGHT
			await tap("act"); await wait(0.05); await shot("c_slash1")
			await wait(0.12); await tap("act"); await wait(0.05); await shot("c_slash2")
			await wait(0.8); await shot("c_after")
			await wait(1.0); await shot("c_wisp")
			await tap("roll"); await wait(0.08); await shot("c_roll")
		"talk":
			var g := get_tree().get_nodes_in_group("interact")
			for n in g:
				if n.get("npc_id") == "smith":
					get_tree().get_first_node_in_group("player").position = n.position + Vector2(0, 18)
			await wait(0.3)
			await hold("up", 0.1)
			await tap("act")
			await wait(1.5)
			await shot("talk_smith")
			await tap("act"); await wait(1.5); await tap("act"); await wait(0.3)
			await shot("talk_choice")
	await wait(0.2)
	get_tree().quit()
