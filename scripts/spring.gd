extends Node2D
## 달샘. 숲지기를 달래면 물이 차오르며 빛난다.

var t := 0.0
var fill := 0.0
var boss_kind := "boar"

func _ready() -> void:
	z_index = -15
	fill = 1.0 if Game.flag(Rules.boss_flag(boss_kind)) else 0.0
	add_to_group("spring")

func refill() -> void:
	var tw := create_tween()
	tw.tween_property(self, "fill", 1.0, 2.5)

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	# 돌바닥 위 웅덩이. 비면 갈라진 흙, 차면 달빛 물
	var r := Vector2(30, 14)
	_ellipse(Vector2(0, 2), r + Vector2(3, 2), Color("3d3b4f"))
	_ellipse(Vector2.ZERO, r, Color("7d5438").lerp(Color("2f7fa0"), fill))
	if fill > 0.05:
		_ellipse(Vector2.ZERO, r * fill * 0.85, Color("4fb0c6"))
		for i in 6:
			var a := t * 0.6 + i
			var p := Vector2(cos(a) * r.x * 0.6, sin(a * 1.3) * r.y * 0.5) * fill
			draw_rect(Rect2(p, Vector2(2, 1)), Color(0.9, 1, 0.95, 0.8))
		_ellipse(Vector2(-6, -3), Vector2(6, 2) * fill, Color(1, 0.95, 0.7, 0.6))
	else:
		for k in [[-14, -2, -4, 3], [2, -5, 12, 1], [-6, 4, 6, 6]]:
			draw_line(Vector2(k[0], k[1]), Vector2(k[2], k[3]), Color("5a3b2e"), 1)

func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
