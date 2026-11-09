extends Node2D
## 갈고리 밧줄: 앞으로 던져 말뚝에 걸리면 날아가고, 적은 끌어와 어지럽게, 물건은 끌어온다.

const SPEED := 330.0
const LEN := float(Rules.ROPE_TILES * 16 + 8)

var owner_player: Node2D
var dir := Vector2.RIGHT
var tip := Vector2.ZERO      # 주인공 기준 끝 위치
var state := "out"
var caught: Node2D
var t := 0.0

func _ready() -> void:
	z_index = 4

func _origin() -> Vector2:
	return owner_player.global_position + Vector2(0, -7)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return
	t += delta
	global_position = _origin()
	match state:
		"out":
			tip += dir * SPEED * delta
			var world_tip := global_position + tip
			# 말뚝
			for p in get_tree().get_nodes_in_group("post"):
				if p.global_position.distance_to(owner_player.global_position) < 20:
					continue  # 지금 서 있는 말뚝은 건너뜀
				if p.global_position.distance_to(world_tip + Vector2(0, 14)) < 12 or p.global_position.distance_to(world_tip + Vector2(0, 8)) < 10:
					state = "zip"
					Sound.play("hit", 0.0, -4)
					owner_player.zip(p.global_position + Vector2(0, 6))
					caught = p
					return
			# 적·물건 걸기
			for n in get_tree().get_nodes_in_group("hookable"):
				if is_instance_valid(n) and (n.global_position + Vector2(0, -6)).distance_to(world_tip) < 10.0 + n.get("hit_radius"):
					state = "pull"
					caught = n
					Sound.play("hit", 0.1, -2)
					if n.has_method("hooked"):
						n.hooked(owner_player)
					return
			var q := PhysicsPointQueryParameters2D.new()
			q.position = world_tip + Vector2(0, 7)
			q.collision_mask = 1
			if tip.length() >= LEN or not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty():
				state = "back"
		"back", "pull":
			tip = tip.move_toward(Vector2.ZERO, SPEED * 1.3 * delta)
			if state == "pull" and is_instance_valid(caught) and caught.get("pulled_by_rope") == true:
				caught.global_position = global_position + tip + Vector2(0, 6)
			if tip.length() < 8:
				if is_instance_valid(caught) and caught.has_method("released"):
					caught.released()
				queue_free()
		"zip":
			if not is_instance_valid(caught):
				queue_free()
				return
			tip = caught.global_position - global_position + Vector2(0, -10)
			if owner_player.state != "zip":
				queue_free()
	queue_redraw()

func _draw() -> void:
	var n := int(tip.length() / 3)
	var sag := 2.0 if state != "zip" else 0.5
	var prev := Vector2.ZERO
	for i in range(1, n + 1):
		var u := float(i) / n
		var pt := tip * u + Vector2(0, sin(u * PI) * sag)
		draw_line(prev, pt, Color("2b1e2f"), 2.0)
		draw_line(prev, pt, Color("c8975f") if i % 2 else Color("a3714a"), 1.0)
		prev = pt
	# 갈고리
	var a := dir.angle()
	draw_line(tip, tip + Vector2.from_angle(a + 2.4) * 4, Color("d5d8e3"), 2.0)
	draw_line(tip, tip + Vector2.from_angle(a - 2.4) * 4, Color("d5d8e3"), 2.0)
	draw_circle(tip, 1.5, Color("a9abc0"))
