extends CharacterBody2D
## 주인공 마루: 8방향 이동, 목검 2연타, 구르기(무적), 말 걸기.

const SPEED := 82.0
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

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
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
	spr.texture = Fx.tex("hero")
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
			if Input.is_action_just_pressed("act"):
				if not _try_interact():
					_start_attack(0)
			elif Input.is_action_just_pressed("roll") and roll_cd <= 0:
				_start_roll(d if d.length() > 0.1 else facing)
			elif Input.is_action_just_pressed("item"):
				_use_herb()
		"attack":
			velocity = velocity.move_toward(facing * 18.0, ACCEL * delta)
			_set_frame(4 if st < ATTACK_TIME * 0.45 else 5)
			if not hit_done and st > 0.04:
				hit_done = true
				_do_hit()
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
		"dead":
			velocity = Vector2.ZERO
	move_and_slide()
	# 깜빡임 (무적 시간)
	spr.visible = not (invuln > 0 and state != "roll" and int(invuln * 20) % 2 == 0)
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
	s.position = Vector2(0, -8)
	add_child(s)

func _snap(v: Vector2) -> Vector2:
	# 8방향으로 맞춤
	var a := snappedf(v.angle(), PI / 4)
	return Vector2.from_angle(a)

func _do_hit() -> void:
	var center := global_position + Vector2(0, -6) + _snap(facing) * 12.0
	var reach := 15.0 + (3.0 if Game.sword > 0 else 0.0)
	var hit_any := false
	for n in get_tree().get_nodes_in_group("hittable"):
		if not is_instance_valid(n) or not n.has_method("take_hit"):
			continue
		var p: Vector2 = n.global_position + Vector2(0, -6)
		if p.distance_to(center) < reach + n.get("hit_radius"):
			n.take_hit(Rules.sword_damage(Game.sword) + (1 if combo == 1 else 0), global_position)
			hit_any = true
	if hit_any:
		Fx.hitstop(self, 0.045)
		shake_amt = maxf(shake_amt, 1.5)

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
		Game.say("약초가 없다. (대장간 옆 쇠돌 아저씨에게 살 수 있다)")
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
	return state == "roll"

func hurt(dmg: int, from: Vector2) -> void:
	if invuln > 0 or state == "dead" or Game.busy:
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
