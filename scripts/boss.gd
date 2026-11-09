extends CharacterBody2D
## 장마다 대왕: 숲지기 대왕멧돼지(boar) · 서리곰(bear) · 달그림자 도깨비왕(king)
## 돌진(벽에 박으면 휘청) · 뛰어올라 내리찍기(충격파) · 부하 부르기 · (곰·왕) 부채꼴로 쏘기

const KINDS := {
	"boar": {"hp": 26, "tex": "boss", "off": -19, "name": "숲지기 대왕멧돼지", "minion": "mushroom", "shot": "", "speed": 1.0},
	"bear": {"hp": 34, "tex": "bear", "off": -22, "name": "서리봉 서리곰", "minion": "frostblob", "shot": "snowball", "speed": 0.95},
	"king": {"hp": 44, "tex": "king", "off": -26, "name": "달그림자 도깨비왕", "minion": "shade", "shot": "darkball", "speed": 1.1},
}

var kind := "boar"
var MAX_HP := 26
var hp := MAX_HP
var hit_radius := 14.0
var spr: Sprite2D
var mat: ShaderMaterial
var shadow: Node2D
var state := "sleep"
var st := 0.0
var t := 0.0
var dir := Vector2.LEFT
var air := 0.0
var leap_from := Vector2.ZERO
var leap_to := Vector2.ZERO
var charges := 0
var pattern := 0
var hurt_cd := 0.0
var home := Vector2.ZERO

class Ring extends Node2D:
	var r := 0.0
	var max_r := 100.0
	var life := 0.55
	var t := 0.0
	var hit := false
	func _process(d: float) -> void:
		t += d
		r = max_r * (t / life)
		if t > life: queue_free()
		queue_redraw()
	func _draw() -> void:
		var a := 1.0 - t / life
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1, 0.95, 0.8, a), 3.0)
		draw_arc(Vector2.ZERO, r - 4, 0, TAU, 48, Color(0.8, 0.6, 0.4, a * 0.6), 2.0)

func _ready() -> void:
	add_to_group("hittable")
	add_to_group("boss")
	home = position
	MAX_HP = KINDS[kind].hp
	hp = MAX_HP
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var sh := CapsuleShape2D.new()
	sh.radius = 8
	sh.height = 34
	cs.rotation = PI / 2
	cs.shape = sh
	cs.position = Vector2(0, -6)
	add_child(cs)
	shadow = Fx.shadow(40, 8)
	add_child(shadow)
	spr = Sprite2D.new()
	spr.texture = Fx.tex(KINDS[kind].tex)
	spr.hframes = 4
	spr.offset = Vector2(0, KINDS[kind].off)
	spr.flip_h = true
	mat = Fx.flash_material()
	spr.material = mat
	add_child(spr)

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _go(s: String) -> void:
	state = s
	st = 0.0

func _physics_process(delta: float) -> void:
	t += delta
	st += delta
	hurt_cd = maxf(0.0, hurt_cd - delta)
	var p := _player()
	if p == null:
		return
	var to_p: Vector2 = p.global_position - global_position
	var fast: float = (1.0 if hp > MAX_HP / 2 else 1.3) * KINDS[kind].speed
	match state:
		"sleep":
			spr.frame = 0
			spr.scale.y = 1.0 + sin(t * 2) * 0.03
			if to_p.length() < 120:
				_go("intro")
				Game.busy = true
				Sound.stop_music()
				Sound.play("roar", 0.0)
				Game.shake.emit(5.0)
				get_tree().call_group("main", "boss_start", self)
		"intro":
			spr.frame = 2 + int(t * 10) % 2
			if st > 1.6:
				Game.busy = false
				Sound.music("boss")
				_go("think")
		"think":
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			spr.frame = int(t * 4) % 2
			spr.flip_h = to_p.x < 0
			if st > 0.7 / fast:
				pattern += 1
				if KINDS[kind].shot != "" and pattern % 4 == 2:
					_go("fan")
				elif hp <= MAX_HP / 2 and pattern % 4 == 0:
					_go("summon")
				elif pattern % 3 == 0:
					_go("leap_up")
					leap_from = position
					leap_to = p.global_position
					var w = get_tree().get_first_node_in_group("world")
					var tries := 0
					while w and not (w.walkable_at(leap_to) and w.walkable_at(leap_to + Vector2(-20, 0)) and w.walkable_at(leap_to + Vector2(20, 0))) and tries < 8:
						leap_to = leap_to.lerp(home, 0.3)
						tries += 1
				else:
					charges = 2 if hp <= MAX_HP / 2 else 1
					_go("aim")
		"fan":
			# 일어섰다가 내리치며 부채꼴로 쏜다
			velocity = Vector2.ZERO
			spr.frame = 2 if st < 0.6 else 3
			spr.flip_h = to_p.x < 0
			if st > 0.6 and st - delta <= 0.6:
				Game.shake.emit(4.0)
				Sound.play("stomp", 0.0, -2)
				var n := 7 if kind == "bear" else 10
				for i in n:
					var b := preload("res://scripts/projectile.gd").new()
					b.tex_name = KINDS[kind].shot
					b.dir = to_p.normalized().rotated((i - (n - 1) / 2.0) * (0.22 if kind == "bear" else TAU / n))
					b.speed = 85.0
					b.position = position + Vector2(0, -14)
					get_parent().add_child(b)
			if st > 1.2:
				_go("think")
		"aim":
			velocity = Vector2.ZERO
			if kind == "king" and st < delta * 1.5:
				Fx.anim(get_parent(), "puff", 5, position + Vector2(0, -16), 18, 6)
				var w = get_tree().get_first_node_in_group("world")
				var tgt: Vector2 = p.global_position + Vector2.from_angle(randf() * TAU) * 80
				if w and w.walkable_at(tgt) and w.walkable_at(tgt + Vector2(20, 0)) and w.walkable_at(tgt - Vector2(20, 0)):
					position = tgt
					to_p = p.global_position - global_position
			spr.flip_h = to_p.x < 0
			spr.frame = 2
			spr.position.x = sin(st * 70) * 1.5
			dir = to_p.normalized()
			if st > 0.65 / fast:
				spr.position.x = 0
				Sound.play("roar", 0.2, -10)
				_go("charge")
		"charge":
			spr.frame = (2 + int(t * 14) % 2) if kind == "boar" else int(t * 10) % 2
			velocity = dir * 215 * fast
			if int(st * 30) % 2 == 0:
				Fx.anim(get_parent(), "dust", 4, position + Vector2(randf_range(-10, 10), 0), 14, -1)
			if get_slide_collision_count() > 0 and st > 0.12:
				Game.shake.emit(6.0)
				Sound.play("stomp", 0.0)
				_go("stun")
			elif st > 1.3:
				charges -= 1
				_go("aim" if charges > 0 else "think")
		"stun":
			velocity = Vector2.ZERO
			spr.frame = 0
			spr.rotation = sin(st * 16) * 0.1
			if st > 1.7:
				spr.rotation = 0
				_go("think")
		"leap_up":
			# 높이 뛰어 플레이어 자리로
			var k := st / 0.85
			air = sin(minf(1.0, k) * PI) * 46
			position = leap_from.lerp(leap_to, minf(1.0, k))
			spr.position.y = -air
			spr.frame = 2
			if k >= 1.0:
				air = 0
				spr.position.y = 0
				Game.shake.emit(7.0)
				Sound.play("stomp", 0.0)
				var ring := Ring.new()
				ring.position = position
				ring.z_index = 2
				get_parent().add_child(ring)
				_watch_ring(ring)
				for i in 8:
					Fx.anim(get_parent(), "dust", 4, position + Vector2.from_angle(TAU * i / 8) * 18, 12, -1)
				_go("land")
		"land":
			spr.frame = 0
			spr.scale = Vector2(1.15, 0.85).lerp(Vector2.ONE, minf(1.0, st * 4))
			if st > 0.7:
				spr.scale = Vector2.ONE
				_go("think")
		"summon":
			velocity = Vector2.ZERO
			spr.frame = 2 + int(t * 10) % 2
			if st > 0.6:
				var w = get_tree().get_first_node_in_group("world")
				Sound.play("roar", 0.2, -6)
				for i in 2:
					w.spawn_enemy(KINDS[kind].minion, position + Vector2(-30 + i * 60, 24))
				_go("think")
		"dying":
			velocity = Vector2.ZERO
			spr.position.x = sin(st * 50) * 2
			if int(st * 8) % 2 == 0 and st < 2.0:
				Fx.anim(get_parent(), "puff", 5, position + Vector2(randf_range(-20, 20), randf_range(-30, 0)), 14, 6)
			if st > 2.4:
				_go("calm")
				spr.position.x = 0
				spr.modulate = Color(0.9, 0.95, 1)
				get_tree().call_group("main", "boss_defeated", self)
		"calm":
			spr.frame = 0
	move_and_slide()
	if state in ["charge", "think", "aim", "stun", "land", "summon"] and to_p.length() < 18 and not p.is_rolling():
		p.hurt(2 if state == "charge" else 1, global_position)

func _watch_ring(ring: Ring) -> void:
	while is_instance_valid(ring):
		var p := _player()
		if p and not ring.hit:
			var d: float = p.global_position.distance_to(ring.position)
			if absf(d - ring.r) < 7 and not p.is_rolling():
				ring.hit = true
				p.hurt(2, ring.position)
		await get_tree().physics_frame

func take_hit(dmg: int, from: Vector2) -> void:
	if state in ["sleep", "intro", "dying", "calm"] or air > 6 or hurt_cd > 0:
		return
	hurt_cd = 0.12
	var d := dmg * (2 if state == "stun" else 1)
	hp -= d
	Sound.play("hit", 0.1)
	Fx.anim(get_parent(), "spark", 4, from.lerp(global_position, 0.6) + Vector2(0, -12), 20, 6)
	Fx.number(get_parent(), position + Vector2(0, -14), str(d), Color(1, 0.8, 0.5) if d > dmg else Color(1, 0.95, 0.7))
	mat.set_shader_parameter("tint", Color(1, 1, 1))
	mat.set_shader_parameter("flash", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.15)
	get_tree().call_group("main", "boss_hp", hp, MAX_HP)
	if hp <= 0:
		hp = 0
		remove_from_group("hittable")
		Sound.stop_music()
		Sound.play("roar", 0.0)
		Game.busy = true
		for e in get_tree().get_nodes_in_group("enemy"):
			e.take_hit(99, e.global_position)
		_go("dying")
