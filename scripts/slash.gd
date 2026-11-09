extends Node2D
## 칼 휘두르기 호. 짧게 그렸다가 사라진다.

var dir := Vector2.RIGHT
var reverse := false
var t := 0.0
var life := 0.16
var radius := 17.0
var big := false

func _ready() -> void:
	z_index = 4

func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var k := clampf(t / life, 0.0, 1.0)
	var base := dir.angle()
	var span := 2.3
	var a0 := base - span / 2
	var a1 := base + span / 2
	if reverse:
		var tmp := a0; a0 = a1; a1 = tmp
	var head := lerpf(a0, a1, minf(1.0, k * 1.6))
	var tail := lerpf(a0, a1, maxf(0.0, k * 1.6 - 0.6))
	var steps := 10
	var r := radius * (1.25 if big else 1.0)
	for i in steps:
		var u0 := float(i) / steps
		var u1 := float(i + 1) / steps
		var b0 := lerpf(tail, head, u0)
		var b1 := lerpf(tail, head, u1)
		var w := lerpf(1.5, 6.0, u1) * (1.0 - k * 0.45)
		var col := Color(1, 1, 0.95, 0.5 + 0.5 * u1).lerp(Color(0.56, 0.94, 0.89, 0.7), 1.0 - u1)
		draw_line(Vector2.from_angle(b0) * r, Vector2.from_angle(b1) * r, col, w)
		draw_line(Vector2.from_angle(b0) * (r - 5), Vector2.from_angle(b1) * (r - 5), Color(1, 0.94, 0.63, 0.45 * u1), 3.0)
	# 목검: 손에서 호 끝까지
	if k < 0.75:
		var tip := Vector2.from_angle(head) * (r + 1)
		var hand := Vector2.from_angle(head) * 4
		draw_line(hand, tip, Color("2b1e2f"), 4.0)
		draw_line(hand, tip, Color("d6aa6e") if not big else Color("e2bd85"), 2.0)
		draw_line(hand, hand + Vector2.from_angle(head) * 3, Color("5e3a2c"), 2.0)
