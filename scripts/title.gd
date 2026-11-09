extends Control
## 처음 화면: 달 뜬 밤하늘, 언덕 위 기와지붕, 제목, 메뉴.

var t := 0.0
var items: Array = []
var sel := 0
var stars: Array = []
var logo: Label
var sub: Label
var labels: Array = []
var house: Texture2D
var tree: Texture2D

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for i in 70:
		stars.append(Vector3(r.randf() * 384, r.randf() * 120, r.randf() * TAU))
	house = Fx.tex("hanok")
	tree = Fx.tex("tree_pine")
	logo = UI.label("달마루 모험기", 24, Color("fff0a0"))
	logo.add_theme_font_override("font", load("res://assets/fonts/Galmuri11-Bold.ttf"))
	logo.add_theme_constant_override("outline_size", 6)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.size = Vector2(384, 30)
	logo.position = Vector2(0, 44)
	add_child(logo)
	sub = UI.label("숲지기와 달빛 조각", 10, Color("b98be0"), true, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(384, 14)
	sub.position = Vector2(0, 74)
	add_child(sub)
	items = ["처음부터"]
	if Game.has_save():
		items.push_front("이어하기")
	for i in items.size():
		var l := UI.label("", 12, UI.PAPER)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(384, 16)
		l.position = Vector2(0, 118 + i * 18)
		add_child(l)
		labels.append(l)
	var hint := UI.label("Z 고르기 · 방향키 움직이기", 10, Color(1, 1, 1, 0.55), true, true)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(384, 14)
	hint.position = Vector2(0, 198)
	add_child(hint)
	_labels()

func _labels() -> void:
	for i in labels.size():
		labels[i].text = ("▶ " + items[i] + " ◀") if i == sel else items[i]
		labels[i].add_theme_color_override("font_color", Color("fff0a0") if i == sel else Color(0.9, 0.85, 0.8, 0.7))

func _process(delta: float) -> void:
	t += delta
	logo.position.y = 44 + sin(t * 1.5) * 1.5
	queue_redraw()
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("down"):
		sel = posmod(sel + (1 if Input.is_action_just_pressed("down") else -1), items.size())
		Sound.play("select", 0.0, -4)
		_labels()
	if Input.is_action_just_pressed("act"):
		Sound.play("chest", 0.0, -4)
		set_process(false)
		get_tree().call_group("main", "start", items[sel] == "이어하기")

func _draw() -> void:
	# 하늘: 위는 짙은 남색, 아래는 보랏빛 노을
	for y in range(0, 216, 4):
		var k := y / 216.0
		var c := Color("1b1733").lerp(Color("5c3b7d"), k * k * 1.3)
		draw_rect(Rect2(0, y, 384, 4), c)
	for s in stars:
		var a := 0.4 + 0.6 * absf(sin(t * 1.3 + s.z))
		draw_rect(Rect2(s.x, s.y, 1, 1), Color(1, 1, 0.9, a))
	# 달
	var mc := Vector2(300, 46)
	draw_circle(mc, 26, Color(1, 0.95, 0.7, 0.08))
	draw_circle(mc, 20, Color(1, 0.95, 0.7, 0.12))
	draw_circle(mc, 15, Color("fff0a0"))
	draw_circle(mc + Vector2(-4, -3), 3, Color("f6cf57"))
	draw_circle(mc + Vector2(5, 4), 2, Color("f6cf57"))
	# 먼 산
	var pts := PackedVector2Array([Vector2(0, 216)])
	for x in range(0, 392, 8):
		pts.append(Vector2(x, 150 - sin(x * 0.02) * 14 - sin(x * 0.05 + 1) * 6))
	pts.append(Vector2(384, 216))
	draw_colored_polygon(pts, Color("3a2552"))
	# 언덕과 마을
	pts = PackedVector2Array([Vector2(0, 216)])
	for x in range(0, 392, 8):
		pts.append(Vector2(x, 176 - sin(x * 0.012 + 0.5) * 12))
	pts.append(Vector2(384, 216))
	draw_colored_polygon(pts, Color("24203a"))
	for i in 5:
		draw_texture(tree, Vector2(8 + i * 76 + (i % 2) * 20, 140 + (i % 3) * 6), Color(0.3, 0.25, 0.45))
	draw_texture(house, Vector2(22, 126), Color(0.45, 0.4, 0.6))
	draw_texture(house, Vector2(296, 132), Color(0.4, 0.35, 0.55))
	# 창문 불빛
	for p in [Vector2(42, 150), Vector2(74, 150), Vector2(316, 156), Vector2(348, 156)]:
		draw_circle(p, 6, Color(1, 0.8, 0.4, 0.15 + 0.05 * sin(t * 3)))
	# 반딧불
	for i in 12:
		var p := Vector2(fmod(i * 47.0 + t * (6 + i % 3), 384), 170 + sin(t + i) * 14)
		draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 0.95, 0.5, 0.5 + 0.5 * sin(t * 4 + i)))
