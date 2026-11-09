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
			await shot("grove_enter")
			await hold("right", 0.9)
			await wait(1.8)
			await shot("boss_intro")
			await wait(1.5)
			await shot("boss_fight")
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
