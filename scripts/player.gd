extends CharacterBody2D
## 주인공 (마루·소리·돌쇠): 8방향 이동, 무기 공격, 구르기(무적), 갈고리 밧줄, 말 걸기.

var SPEED := 82.0
const ACCEL := 1100.0
const ROLL_SPEED := 200.0
const ROLL_TIME := 0.24
const ATTACK_TIME := 0.24

var cam: Camera2D
var spr: Sprite2D
var mat: ShaderMaterial
var facing := Vector2.DOWN
var state := "move"
var st := 0.0
var anim := 0.0
var invuln := 0.0
var roll_cd := 0.0
var combo := 0
var queued := false
var hit_done := false
var knock := Vector2.ZERO
var shake_amt := 0.0
var step_t := 0.0
var no_blink := false  # 개발용 화면 찍기
var weapon := "sword"
var hold_t := 0.0
var holding := false
var fire_cd := 0.0
var rope: Node2D
var zip_to := Vector2.ZERO
var charge_fx: Node2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 8
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var sh := CapsuleShape2D.new()
	sh.radius = 4.5
	sh.height = 10
	cs.rotation = PI / 2
	sh.radius = 3.5
	cs.shape = sh
	cs.position = Vector2(0, -3)
	add_child(cs)
	add_child(Fx.shadow(11, 4))
	spr = Sprite2D.new()
	var h := Rules.hero(Game.hero)
	weapon = h.weapon
	SPEED = h.speed
	spr.texture = Fx.tex("hero" if Game.hero == "maru" else "hero_" + Game.hero)
	spr.hframes = 8
	spr.vframes = 3
	spr.offset = Vector2(0, -10)
	mat = Fx.flash_material()
	spr.material = mat
	add_child(spr)
	Game.shake.connect(func(p): shake_amt = maxf(shake_amt, p))

func _input_dir() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func _physics_process(delta: float) -> void:
	st += delta
	invuln = maxf(0.0, invuln - delta)
	roll_cd = maxf(0.0, roll_cd - delta)
	fire_cd = maxf(0.0, fire_cd - delta)
	if Game.busy:
		velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
		_set_frame(0)
		move_and_slide()
		return
	var d := _input_dir()
	match state:
		"move":
			if d.length() > 0.1:
				facing = d.normalized()
				velocity = velocity.move_toward(d.normalized() * SPEED * minf(1.0, d.length() * 1.4), ACCEL * delta)
				anim += delta * 9.0
				step_t -= delta
				if step_t <= 0:
					step_t = 0.28
					Fx.anim(get_parent(), "dust", 4, position + Vector2(randf_range(-3, 3), 0), 14, -1)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, ACCEL * delta)
				anim = 0
			_set_frame(int(anim) % 4 if d.length() > 0.1 else 0)
			if holding:
				_hold_update(delta, d)
			elif Input.is_action_just_pressed("act"):
				if not _try_interact():
					if weapon == "sword":
						_start_attack(0)
					elif fire_cd <= 0:
						holding = true
						hold_t = 0.0
			elif Input.is_action_just_pressed("roll") and roll_cd <= 0:
				_start_roll(d if d.length() > 0.1 else facing)
			elif Input.is_action_just_pressed("item"):
				_fire_rope()
			elif Input.is_action_just_pressed("herb"):
				_use_herb()
		"attack":
			var at := ATTACK_TIME * (1.45 if weapon == "club" else 1.0)
			velocity = velocity.move_toward(facing * 18.0, ACCEL * delta)
			_set_frame(4 if st < at * 0.45 else 5)
			if not hit_done and st > (0.1 if weapon == "club" else 0.04):
				hit_done = true
				_do_hit()
			if weapon == "club":
				if st >= at:
					state = "move"
				move_and_slide()
				return
			if Input.is_action_just_pressed("act"):
				queued = true
			if st >= ATTACK_TIME:
				if queued and combo == 0:
					if d.length() > 0.1: facing = d.normalized()
					_start_attack(1)
				else:
					state = "move"
					combo = 0
		"roll":
			velocity = velocity.move_toward(facing * ROLL_SPEED * 0.4, 800 * delta)
			spr.frame = Rules.facing_row(facing) * 8 + 6
			spr.rotation = (st / ROLL_TIME) * TAU * (1 if facing.x >= 0 else -1) if Rules.facing_row(facing) == 2 else 0.0
			if st >= ROLL_TIME:
				state = "move"
				spr.rotation = 0
		"hurt":
			velocity = knock
			knock = knock.move_toward(Vector2.ZERO, 900 * delta)
			_set_frame(7)
			if st > 0.25:
				state = "move"
		"zip":
			# 밧줄을 따라 날아감 (물 위도 지나감)
			var to := zip_to - position
			velocity = to.normalized() * 260.0
			spr.frame = Rules.facing_row(facing) * 8 + 6
			if to.length() < 6 or st > 1.2:
				position = zip_to
				velocity = Vector2.ZERO
				collision_mask = 1 | 8
				state = "move"
				Fx.anim(get_parent(), "dust", 4, position, 14, -1)
		"dead":
			velocity = Vector2.ZERO
	move_and_slide()
	# 깜빡임 (무적 시간)
	spr.visible = no_blink or not (invuln > 0 and state != "roll" and int(invuln * 20) % 2 == 0)
	if cam:
		shake_amt = move_toward(shake_amt, 0.0, delta * 12.0)
		cam.offset = Vector2(0, -8) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amt

func _set_frame(col: int) -> void:
	var row := Rules.facing_row(facing)
	spr.flip_h = row == 2 and facing.x < 0
	spr.frame = row * 8 + col

func _start_attack(n: int) -> void:
	state = "attack"
	st = 0.0
	combo = n
	queued = false
	hit_done = false
	velocity = facing * 60.0
	Sound.play("swing", 0.12)
	var s := preload("res://scripts/slash.gd").new()
	s.dir = _snap(facing)
	s.reverse = n == 1
	s.big = Game.sword > 0
	s.kind = weapon
	s.position = Vector2(0, -8)
	add_child(s)

func _snap(v: Vector2) -> Vector2:
	# 8방향으로 맞춤
	var a := snappedf(v.angle(), PI / 4)
	return Vector2.from_angle(a)

func _do_hit() -> void:
	var center := global_position + Vector2(0, -6) + _snap(facing) * 12.0
	var reach := 15.0 + (3.0 if Game.sword > 0 else 0.0) + (5.0 if weapon == "club" else 0.0)
	var hit_any := false
	for n in get_tree().get_nodes_in_group("hittable"):
		if not is_instance_valid(n) or not n.has_method("take_hit"):
			continue
		var p: Vector2 = n.global_position + Vector2(0, -6)
		if p.distance_to(center) < reach + n.get("hit_radius"):
			n.take_hit(Rules.weapon_damage(weapon, Game.sword, false, combo), global_position)
			if weapon == "club" and n.has_method("knock_extra"):
				n.knock_extra(global_position)
			hit_any = true
	if hit_any:
		Fx.hitstop(self, 0.045)
		shake_amt = maxf(shake_amt, 1.5)

## 활·방망이: 누르고 있으면 힘을 모은다
func _hold_update(delta: float, d: Vector2) -> void:
	hold_t += delta
	velocity = velocity.move_toward(d * SPEED * 0.4, ACCEL * delta)
	_set_frame(4)
	if hold_t > 0.5 and charge_fx == null:
		charge_fx = Fx.anim(self, "spark", 4, Vector2(0, -10), 10, 6)
		Sound.play("select", 0.0, -6)
	if not Input.is_action_pressed("act"):
		holding = false
		var charged := hold_t > 0.5
		charge_fx = null
		if weapon == "bow":
			_shoot(charged)
		elif charged:
			_slam()
		else:
			_start_attack(0)

func _shoot(charged: bool) -> void:
	fire_cd = 0.28
	state = "attack"
	st = ATTACK_TIME * 0.5
	hit_done = true
	combo = 1
	queued = false
	var a := preload("res://scripts/arrow.gd").new()
	a.dir = _snap(facing)
	a.pierce = charged
	a.damage = Rules.weapon_damage("bow", Game.sword, charged)
	a.position = position + Vector2(0, -8) + a.dir * 6
	get_parent().add_child(a)
	Sound.play("swing", 0.05, 2.0 if charged else 0.0)
	velocity = -a.dir * 30

func _slam() -> void:
	state = "attack"
	st = ATTACK_TIME * 0.6
	hit_done = true
	combo = 0
	Sound.play("stomp", 0.05)
	Game.shake.emit(4.0)
	shake_amt = 4.0
	var ring := preload("res://scripts/boss.gd").Ring.new()
	ring.position = position
	ring.life = 0.3
	ring.max_r = 40.0
	ring.z_index = 2
	get_parent().add_child(ring)
	for i in 8:
		Fx.anim(get_parent(), "dust", 4, position + Vector2.from_angle(TAU * i / 8) * 14, 12, -1)
	for n in get_tree().get_nodes_in_group("hittable"):
		if is_instance_valid(n) and n.global_position.distance_to(global_position) < 40.0 + n.get("hit_radius"):
			n.take_hit(Rules.weapon_damage("club", Game.sword, true), global_position)
	Fx.hitstop(self, 0.06)

func _fire_rope() -> void:
	if rope and is_instance_valid(rope):
		return
	rope = preload("res://scripts/rope.gd").new()
	rope.owner_player = self
	rope.dir = _snap(facing)
	get_parent().add_child(rope)
	Sound.play("swing", 0.1, -4)

## 밧줄이 말뚝에 걸리면 불림
func zip(target: Vector2) -> void:
	state = "zip"
	st = 0.0
	zip_to = target
	collision_mask = 0
	invuln = maxf(invuln, 0.3)
	Sound.play("roll", 0.0)

func _start_roll(d: Vector2) -> void:
	state = "roll"
	st = 0.0
	facing = d.normalized()
	velocity = facing * ROLL_SPEED
	roll_cd = 0.38
	invuln = maxf(invuln, ROLL_TIME)
	Sound.play("roll")
	for i in 3:
		Fx.anim(get_parent(), "dust", 4, position - facing * i * 4, 12, -1)

func _use_herb() -> void:
	if Game.herbs <= 0:
		Game.say("약초가 없다. (마을 대장간에서 살 수 있다)")
		return
	if Game.hp >= Game.max_hp:
		Game.say("지금은 기운이 넘친다.")
		return
	Game.herbs -= 1
	Game.heal(4)
	Sound.play("heal")
	Fx.number(get_parent(), position, "+2♥", Color(1, 0.6, 0.7))

func _try_interact() -> bool:
	var probe := global_position + facing * 12.0
	if holding: return false
	var best: Node2D = null
	var bd := 1e9
	for n in get_tree().get_nodes_in_group("interact"):
		var dd: float = n.global_position.distance_to(probe)
		if dd < n.get("radius") and dd < bd:
			best = n
			bd = dd
	if best:
		best.interact(self)
		return true
	return false

func is_rolling() -> bool:
	return state == "roll" or state == "zip"

func hurt(dmg: int, from: Vector2) -> void:
	if invuln > 0 or state == "dead" or state == "zip" or Game.busy:
		return
	Game.hurt(dmg)
	Sound.play("hurt", 0.05)
	invuln = 1.0
	state = "hurt"
	st = 0.0
	knock = (global_position - from).normalized() * 150.0
	mat.set_shader_parameter("flash", 1.0)
	mat.set_shader_parameter("tint", Color(1, 0.3, 0.3))
	var tw := create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 1.0, 0.0, 0.25)
	shake_amt = 3.0
	Fx.hitstop(self, 0.07)
	if Game.hp <= 0:
		state = "dead"
		Game.busy = false
		get_tree().call_group("main", "player_died")

func push_back(d: Vector2) -> void:
	position += d * 10
	velocity = Vector2.ZERO
