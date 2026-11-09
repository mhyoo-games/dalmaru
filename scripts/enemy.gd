extends CharacterBody2D
## 들판의 적: 버섯돌이(통통 뜀), 도깨비불(거리 두고 불씨 쏨), 멧돼지(노려보다 돌진).

signal died

const INFO := {
	"mushroom": {"hp": 2, "tex": "mushroom", "frames": 4, "off": -9, "r": 6.0, "dmg": 1, "name": "버섯돌이"},
	"wisp": {"hp": 2, "tex": "wisp", "frames": 4, "off": -14, "r": 6.0, "dmg": 1, "name": "도깨비불"},
	"boar": {"hp": 5, "tex": "boar", "frames": 4, "off": -11, "r": 9.0, "dmg": 2, "name": "멧돼지"},
}

var kind := "mushroom"
var hp := 2
var hit_radius := 6.0
var spr: Sprite2D
var mat: ShaderMaterial
var state := "idle"
var st := 0.0
var t := 0.0
var home := Vector2.ZERO
var target := Vector2.ZERO
var knock := Vector2.ZERO
var charge_dir := Vector2.ZERO
var fire_cd := 1.5
var wander_to := Vector2.ZERO
var spawning := 0.35

func _ready() -> void:
	add_to_group("hittable")
	add_to_group("enemy")
	var info: Dictionary = INFO[kind]
	hp = info.hp
	hit_radius = info.r
	home = position
	wander_to = position
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 5.0 if kind != "boar" else 7.0
	cs.shape = sh
	cs.position = Vector2(0, -3)
	add_child(cs)
	add_child(Fx.shadow(12 if kind != "boar" else 22, 4))
	spr = Sprite2D.new()
	spr.texture = Fx.tex(info.tex)
	spr.hframes = info.frames
	spr.offset = Vector2(0, info.off)
	mat = Fx.flash_material()
	spr.material = mat
	add_child(spr)
	t = randf() * 3.0
	fire_cd = randf_range(1.0, 2.5)
	spr.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(spr, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	t += delta
	st += delta
	spawning = maxf(0.0, spawning - delta)
	var p := _player()
	if p == null or Game.busy:
		return
	var to_p: Vector2 = p.global_position - global_position
	var dist := to_p.length()
	if state == "hurt":
		velocity = knock
		knock = knock.move_toward(Vector2.ZERO, 700 * delta)
		if st > 0.22:
			state = "idle"; st = 0.0
		move_and_slide()
		return
	match kind:
		"mushroom": _mushroom(delta, to_p, dist)
		"wisp": _wisp(delta, to_p, dist)
		"boar": _boar(delta, to_p, dist)
	move_and_slide()
	# 몸에 닿으면 다침
	if spawning <= 0 and dist < hit_radius + 6 and not p.is_rolling():
		p.hurt(INFO[kind].dmg, global_position)

func _mushroom(delta: float, to_p: Vector2, dist: float) -> void:
	match state:
		"idle":
			velocity = velocity.move_toward(Vector2.ZERO, 600 * delta)
			spr.frame = int(t * 3) % 2
			if st > (0.5 if dist < 100 else 1.4):
				state = "crouch"; st = 0.0
		"crouch":
			spr.frame = 2
			if st > 0.16:
				state = "hop"; st = 0.0
				var dir := to_p.normalized() if dist < 100 else Vector2.from_angle(randf() * TAU)
				velocity = dir * (78.0 if dist < 100 else 35.0)
				Sound.play("hop", 0.2, -10)
		"hop":
			spr.frame = 3
			spr.offset.y = INFO.mushroom.off - sin(st / 0.32 * PI) * 6
			if st > 0.32:
				spr.offset.y = INFO.mushroom.off
				state = "idle"; st = 0.0
				Fx.anim(get_parent(), "dust", 4, position, 14, -1)

func _wisp(delta: float, to_p: Vector2, dist: float) -> void:
	spr.frame = int(t * 8) % 4
	spr.offset.y = INFO.wisp.off + sin(t * 3.0) * 2.5
	var want := Vector2.ZERO
	if dist < 130:
		# 60~80 거리를 유지하며 빙글빙글
		var side := to_p.orthogonal().normalized() * (1 if int(t / 3) % 2 == 0 else -1)
		if dist < 55: want = -to_p.normalized() * 40 + side * 20
		elif dist > 85: want = to_p.normalized() * 30 + side * 20
		else: want = side * 32
		fire_cd -= delta
		if fire_cd <= 0:
			fire_cd = randf_range(1.8, 2.6)
			_fire(to_p.normalized())
	else:
		want = (home + Vector2(sin(t * 0.7), cos(t * 0.5)) * 20 - position) * 0.8
	velocity = velocity.move_toward(want, 160 * delta)

func _fire(dir: Vector2) -> void:
	mat.set_shader_parameter("flash", 0.7)
	mat.set_shader_parameter("tint", Color(0.8, 1, 1))
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_callback(func():
		mat.set_shader_parameter("flash", 0.0)
		if not is_inside_tree(): return
		var b := preload("res://scripts/projectile.gd").new()
		b.dir = dir
		b.position = position + Vector2(0, -12)
		get_parent().add_child(b)
		Sound.play("fire", 0.1, -6))

func _boar(delta: float, to_p: Vector2, dist: float) -> void:
	match state:
		"idle":
			spr.frame = int(t * 4) % 2 if velocity.length() > 5 else 0
			if position.distance_to(wander_to) < 4 or st > 3.0:
				wander_to = home + Vector2.from_angle(randf() * TAU) * randf_range(10, 40)
				st = 0.0
			velocity = velocity.move_toward((wander_to - position).normalized() * 24, 300 * delta)
			if absf(velocity.x) > 2: spr.flip_h = velocity.x < 0
			if dist < 110 and st > 0.6:
				state = "aim"; st = 0.0
				Sound.play("roar", 0.15, -14)
		"aim":
			velocity = Vector2.ZERO
			spr.flip_h = to_p.x < 0
			spr.frame = 2
			spr.position.x = sin(st * 60) * 1.2
			charge_dir = to_p.normalized()
			if st > 0.55:
				spr.position.x = 0
				state = "charge"; st = 0.0
		"charge":
			spr.frame = 2 + int(t * 12) % 2
			velocity = charge_dir * 175
			if int(st * 20) % 2 == 0:
				Fx.anim(get_parent(), "dust", 4, position, 14, -1)
			if get_slide_collision_count() > 0 and st > 0.1:
				state = "stun"; st = 0.0
				Game.shake.emit(2.0)
				Sound.play("stomp", 0.1, -6)
			elif st > 0.8:
				state = "idle"; st = 0.0
		"stun":
			velocity = Vector2.ZERO
			spr.frame = 0
			spr.rotation = sin(st * 20) * 0.08
			if st > 1.1:
				spr.rotation = 0
				state = "idle"; st = 0.0

func take_hit(dmg: int, from: Vector2) -> void:
	if hp <= 0:
		return
	hp -= dmg
	var bonus := state == "stun"
	if bonus:
		hp -= 1
	Sound.play("hit", 0.1)
	Fx.anim(get_parent(), "spark", 4, position + Vector2(0, -8), 20, 6)
	Fx.number(get_parent(), position, str(dmg + (1 if bonus else 0)))
	mat.set_shader_parameter("tint", Color(1, 1, 1))
	mat.set_shader_parameter("flash", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.18)
	if hp <= 0:
		_die()
		return
	state = "hurt"; st = 0.0
	knock = (global_position - from).normalized() * (110.0 if kind != "boar" else 70.0)
	spr.position.x = 0
	spr.rotation = 0

func _die() -> void:
	Sound.play("enemy_die", 0.1)
	Fx.anim(get_parent(), "puff", 5, position + Vector2(0, -8), 14, 6)
	var w = get_tree().get_first_node_in_group("world")
	var drop := Rules.drop_for(kind, randf())
	if w and drop != "":
		w.spawn_pickup(drop, position, "", Rules.coin_value(kind) if drop == "coin" else 1)
	died.emit()
	set_physics_process(false)
	remove_from_group("hittable")
	var tw := create_tween()
	tw.tween_property(spr, "scale", Vector2(1.4, 0.2), 0.12)
	tw.tween_callback(queue_free)
