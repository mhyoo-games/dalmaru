extends Node2D
## 소리의 화살. 꾹 눌렀다 쏘면 꿰뚫는다.

var dir := Vector2.RIGHT
var speed := 230.0
var life := 0.7
var damage := 1
var pierce := false
var hit := {}

func _ready() -> void:
	z_index = 3

func _physics_process(delta: float) -> void:
	var step := dir * speed * delta
	position += step
	life -= delta
	if life <= 0:
		queue_free()
		return
	# 벽(나무·바위·집)에 꽂힘 — 물은 넘어간다
	var q := PhysicsPointQueryParameters2D.new()
	q.position = global_position + Vector2(0, 6)
	q.collision_mask = 1
	if not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty():
		Fx.anim(get_parent(), "dust", 4, position + Vector2(0, 6), 16)
		queue_free()
		return
	for n in get_tree().get_nodes_in_group("hittable"):
		if not is_instance_valid(n) or hit.has(n):
			continue
		var p: Vector2 = n.global_position + Vector2(0, -6)
		if p.distance_to(global_position) < 6.0 + n.get("hit_radius"):
			hit[n] = true
			n.take_hit(damage, global_position - dir * 10)
			if not pierce:
				queue_free()
				return
	queue_redraw()

func _draw() -> void:
	var tail := -dir * 9
	draw_line(tail, Vector2.ZERO, Color("2b1e2f"), 3.0)
	draw_line(tail, Vector2.ZERO, Color("d6aa6e"), 1.0)
	draw_line(Vector2.ZERO, dir * 3, Color("d5d8e3"), 2.0)
	draw_line(tail, tail + dir.rotated(0.6) * 3, Color("f7b8c2"), 1.0)
	draw_line(tail, tail + dir.rotated(-0.6) * 3, Color("f7b8c2"), 1.0)
	if pierce:
		draw_circle(Vector2.ZERO, 3.0, Color(1, 0.95, 0.6, 0.35))
