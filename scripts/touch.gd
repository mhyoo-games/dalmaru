extends Control
## 휴대폰 화면용 조작: 왼쪽 아래 끌어서 이동, 오른쪽 아래 버튼 세 개.

var enabled := false
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var buttons := {"act": Vector2(352, 176), "roll": Vector2(322, 196), "item": Vector2(356, 140)}
var held := {}

func _ready() -> void:
	enabled = DisplayServer.is_touchscreen_available()
	visible = enabled
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _to_local(p: Vector2) -> Vector2:
	return p  # 화면 늘리기(viewport) 방식이라 입력 좌표가 이미 384×216 기준

func _input(e: InputEvent) -> void:
	if not enabled:
		return
	if e is InputEventScreenTouch:
		var p := _to_local(e.position)
		if e.pressed:
			for a in buttons:
				if p.distance_to(buttons[a]) < 15:
					held[e.index] = a
					Input.action_press(a)
					queue_redraw()
					return
			if p.x < 192 and stick_id == -1:
				stick_id = e.index
				stick_origin = p
				stick_pos = p
		else:
			if held.has(e.index):
				Input.action_release(held[e.index])
				held.erase(e.index)
			if e.index == stick_id:
				stick_id = -1
				for a in ["left", "right", "up", "down"]:
					Input.action_release(a)
		queue_redraw()
	elif e is InputEventScreenDrag and e.index == stick_id:
		stick_pos = _to_local(e.position)
		var d := (stick_pos - stick_origin).limit_length(20) / 20.0
		_axis("left", "right", d.x)
		_axis("up", "down", d.y)
		queue_redraw()

func _axis(neg: String, pos: String, v: float) -> void:
	if v < -0.2:
		Input.action_press(neg, -v); Input.action_release(pos)
	elif v > 0.2:
		Input.action_press(pos, v); Input.action_release(neg)
	else:
		Input.action_release(neg); Input.action_release(pos)

func _draw() -> void:
	if not enabled:
		return
	if stick_id != -1:
		draw_circle(stick_origin, 20, Color(1, 1, 1, 0.15))
		draw_circle(stick_origin + (stick_pos - stick_origin).limit_length(20), 8, Color(1, 1, 1, 0.35))
	var names := {"act": "공격", "roll": "구르기", "item": "약초"}
	for a in buttons:
		var on: bool = a in held.values()
		draw_circle(buttons[a], 13, Color(1, 1, 1, 0.35 if on else 0.18))
		draw_arc(buttons[a], 13, 0, TAU, 24, Color(1, 1, 1, 0.4), 1.0)
		var s: String = names[a]
		var w := Game.font_small.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(Game.font_small, buttons[a] + Vector2(-w / 2, 4), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))
