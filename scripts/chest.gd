extends Node2D
## 상자. 열면 물건이 튀어나온다. 그림은 코드로 그림(_draw).

var chest_id := ""
var item := ""
var radius := 16.0
var opened := false
var lid := 0.0

func _ready() -> void:
	add_to_group("interact")
	opened = Game.flag(chest_id)
	lid = 1.0 if opened else 0.0
	add_child(Fx.shadow(16, 4))
	var b := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(14, 7)
	cs.shape = sh
	cs.position = Vector2(0, -4)
	b.add_child(cs)
	add_child(b)

func _draw() -> void:
	var ink := Color("2b1e2f")
	draw_rect(Rect2(-8, -11, 16, 11), ink)
	draw_rect(Rect2(-7, -10, 14, 9), Color("8a5a3b"))
	draw_rect(Rect2(-7, -10, 14, 2), Color("b07f4f"))
	draw_rect(Rect2(-7, -3, 14, 2), Color("5e3a2c"))
	for x in [-6, 5]:
		draw_rect(Rect2(x, -10, 1, 9), Color("f6cf57"))
	# 뚜껑
	var ly := -11 - lid * 4
	draw_rect(Rect2(-8, ly - 5, 16, 6), ink)
	draw_rect(Rect2(-7, ly - 4, 14, 4), Color("a8323a") if not opened else Color("6e1f2c"))
	draw_rect(Rect2(-7, ly - 4, 14, 1), Color("d8524a"))
	draw_rect(Rect2(-1, ly - 1, 2, 3), Color("fff0a0"))
	if not opened:
		var tt := Time.get_ticks_msec() / 1000.0
		if int(tt * 2) % 3 == 0:
			draw_rect(Rect2(4, -16, 1, 1), Color(1, 1, 0.9))

func _process(_d: float) -> void:
	if not opened:
		queue_redraw()

func interact(_p: Node) -> void:
	if opened:
		get_tree().call_group("main", "dialog", [["", "빈 상자다."]])
		return
	opened = true
	Game.set_flag(chest_id)
	Sound.play("chest", 0.0)
	var tw := create_tween()
	tw.tween_method(func(v): lid = v; queue_redraw(), 0.0, 1.0, 0.25)
	var w = get_tree().get_first_node_in_group("world")
	match item:
		"shard", "pearl", "ember", "gloom":
			Game.add_item(item)
			Game.set_flag(chest_id + "_" + item)
			Sound.play("shard", 0.0)
			get_tree().call_group("main", "got_item", item)
		"coins20":
			Game.add_coins(20)
			get_tree().call_group("main", "dialog", [["", "엽전 꾸러미를 찾았다! (엽전 +20)"]])
		"herb":
			Game.herbs += 2
			Game.changed.emit()
			get_tree().call_group("main", "dialog", [["", "약초 두 묶음을 찾았다! (V 키로 먹기)"]])
