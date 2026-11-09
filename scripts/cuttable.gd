extends Node2D
## 벨 수 있는 덤불·긴풀·항아리.

var kind := "b"
var hit_radius := 6.0
var spr: Sprite2D

func setup(s: Sprite2D) -> void:
	spr = s
	add_to_group("hittable")

func take_hit(_dmg: int, _from: Vector2) -> void:
	remove_from_group("hittable")
	var w = get_tree().get_first_node_in_group("world")
	if kind in "jJ":
		Sound.play("hit", 0.1)
		Fx.anim(get_parent(), "puff", 5, position + Vector2(0, -6), 16)
	else:
		Sound.play("cut", 0.15)
		_leaves()
	var r := randf()
	if w:
		if kind == "B" or (kind in "jJ" and r < 0.7):
			w.spawn_pickup("coin", position, "", 1)
		elif r < 0.12:
			w.spawn_pickup("heart", position)
		elif r < 0.35:
			w.spawn_pickup("coin", position)
	queue_free()

func _leaves() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 80
	p.initial_velocity_min = 30
	p.initial_velocity_max = 70
	p.gravity = Vector2(0, 160)
	p.scale_amount_min = 1
	p.scale_amount_max = 2
	p.color = Color(0.52, 0.75, 0.35) if kind != "B" else Color(0.85, 0.32, 0.29)
	p.position = position + Vector2(0, -6)
	p.z_index = 5
	get_parent().add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
