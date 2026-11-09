extends Node2D
## 2장 대왕 이무기: 물속을 헤엄치다 떠올라 물방울을 쏜다.
## 떠올랐을 때 갈고리 밧줄로 걸면 물가로 끌려 나와 한동안 꼼짝 못 한다 — 그때가 기회.

const MAX_HP := 30
const SEG := 7

var kind := "serpent"
var hp := MAX_HP
var hit_radius := 12.0
var pulled_by_rope := false
var lake := Rect2()
var head: Sprite2D
var mat: ShaderMaterial
var segs: Array[Sprite2D] = []
var trail: Array[Vector2] = []
var state := "sleep"
var st := 0.0
var t := 0.0
var goal := Vector2.ZERO
var hurt_cd := 0.0
var spits := 0
var bubbles := 0.0

func _ready() -> void:
	add_to_group("boss")
	for i in SEG:
		var b := Sprite2D.new()
		b.texture = Fx.tex("serpent_body")
		b.top_level = true
		b.z_index = -14 + 0
		b.scale = Vector2.ONE * (1.0 - i * 0.07)
		add_child(b)
		segs.append(b)
	head = Sprite2D.new()
	head.texture = Fx.tex("serpent_head")
	head.hframes = 2
	head.offset = Vector2(0, -12)
	mat = Fx.flash_material()
	head.material = mat
	add_child(head)
	for i in SEG * 6:
		trail.append(position)
	_dive_look(true)

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _go(s: String) -> void:
	state = s
	st = 0.0

func _surfaced() -> bool:
	return state in ["rise", "spit", "beached"]

func _dive_look(under: bool) -> void:
	var a := 0.35 if under else 1.0
	head.modulate.a = a
	for b in segs:
		b.modulate.a = a * 0.9
		b.z_index = -14 if under else 1

## 물가 쪽 아무 데나 (주인공과 가까운 쪽)
func _pick_spot(p: Vector2) -> Vector2:
	var c := lake.get_center()
	var d := (p - c).normalized()
	var r := Vector2(lake.size.x * 0.36, lake.size.y * 0.34)
	return c + Vector2(d.x * r.x, d.y * r.y).rotated(randf_range(-0.6, 0.6))

func _process(delta: float) -> void:
	t += delta
	st += delta
	hurt_cd = maxf(0.0, hurt_cd - delta)
	var p := _player()
	if p == null:
		return
	var to_p: Vector2 = p.global_position - global_position
	match state:
		"sleep":
			position = lake.get_center() + Vector2(sin(t * 0.7) * 30, cos(t * 0.5) * 16)
			if p.global_position.distance_to(lake.get_center()) < lake.size.length() * 0.45:
				_go("intro")
				Game.busy = true
				Sound.stop_music()
				Sound.play("roar", 0.0)
				Game.shake.emit(5.0)
				_dive_look(false)
				get_tree().call_group("main", "boss_start", self)
		"intro":
			head.frame = int(t * 6) % 2
			position.y -= delta * 6
			if st > 1.6:
				Game.busy = false
				Sound.music("boss")
				Game.say("떠올랐을 때 갈고리 밧줄(C)로 걸어 끌어내자!")
				_dive()
		"swim":
			position = position.move_toward(goal, 70.0 * delta)
			bubbles -= delta
			if bubbles <= 0:
				bubbles = 0.12
				Fx.anim(get_parent(), "dust", 4, position + Vector2(randf_range(-6, 6), 2), 16, -13)
			if position.distance_to(goal) < 3 or st > 2.4:
				_go("rise")
				_dive_look(false)
				Sound.play("hop", 0.0, -2)
				for i in 6:
					Fx.anim(get_parent(), "puff", 5, position + Vector2.from_angle(TAU * i / 6) * 12, 16, 2)
				add_to_group("hittable")
				add_to_group("hookable")
		"rise":
			head.frame = 0
			head.flip_h = to_p.x < 0
			if st > 0.55:
				_go("spit")
				spits = 3 if hp > MAX_HP / 2 else 5
		"spit":
			head.frame = 1
			head.flip_h = to_p.x < 0
			if st > 0.35 and spits > 0:
				st = 0.0
				spits -= 1
				var n := 1 if hp > MAX_HP / 2 else 3
				for i in n:
					var b := preload("res://scripts/projectile.gd").new()
					b.tex_name = "waterball"
					b.dir = to_p.normalized().rotated((i - (n - 1) / 2.0) * 0.35)
					b.speed = 95.0
					b.position = position + Vector2(0, -14)
					get_parent().add_child(b)
				Sound.play("fire", 0.1, -6)
			elif spits <= 0 and st > 0.6:
				_dive()
		"beached":
			# 물가로 끌려 나와 퍼덕거림
			head.frame = int(t * 8) % 2
			head.rotation = sin(t * 14) * 0.12
			position = position.move_toward(goal, 120.0 * delta)
			if st > 2.8:
				head.rotation = 0
				_dive()
		"dying":
			head.position.x = sin(st * 50) * 2
			if int(st * 8) % 2 == 0 and st < 2.0:
				Fx.anim(get_parent(), "puff", 5, position + Vector2(randf_range(-20, 20), randf_range(-20, 4)), 14, 6)
			if st > 2.4:
				_go("calm")
				head.position.x = 0
				_dive_look(false)
				get_tree().call_group("main", "boss_defeated", self)
		"calm":
			head.frame = 0
			position = position.move_toward(lake.get_center(), 20 * delta)
	# 몸통이 머리 자취를 따라감
	trail.push_front(position)
	trail.resize(SEG * 6)
	for i in SEG:
		segs[i].global_position = trail[mini(trail.size() - 1, (i + 1) * 5)] + Vector2(0, -6 + sin(t * 3 + i) * 1.5)

func _dive() -> void:
	_go("swim")
	remove_from_group("hittable")
	remove_from_group("hookable")
	_dive_look(true)
	goal = _pick_spot(_player().global_position)

func hooked(p: Node) -> void:
	if not _surfaced():
		return
	_go("beached")
	Sound.play("roar", 0.2, -6)
	Game.shake.emit(3.0)
	# 주인공 쪽 물가로 끌려 나온다
	var dir: Vector2 = (p.global_position - global_position).normalized()
	goal = global_position + dir * minf(48.0, p.global_position.distance_to(global_position) - 18.0)

func released() -> void:
	pass

func take_hit(dmg: int, from: Vector2) -> void:
	if not _surfaced() or hurt_cd > 0 or state in ["dying", "calm"]:
		return
	hurt_cd = 0.12
	var d := dmg if state == "beached" else 1
	if state == "beached": d = int(ceil(dmg * 1.5))
	hp -= d
	Sound.play("hit", 0.1)
	Fx.anim(get_parent(), "spark", 4, from.lerp(global_position, 0.6) + Vector2(0, -12), 20, 6)
	Fx.number(get_parent(), position + Vector2(0, -16), str(d))
	mat.set_shader_parameter("tint", Color(1, 1, 1))
	mat.set_shader_parameter("flash", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.15)
	get_tree().call_group("main", "boss_hp", hp, MAX_HP)
	if hp <= 0:
		hp = 0
		remove_from_group("hittable")
		remove_from_group("hookable")
		Sound.stop_music()
		Sound.play("roar", 0.0)
		Game.busy = true
		for e in get_tree().get_nodes_in_group("enemy"):
			e.take_hit(99, e.global_position)
		_go("dying")
