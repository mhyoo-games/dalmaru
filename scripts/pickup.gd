extends Area2D
## 엽전·하트·달빛 조각. 가까이 가면 끌려오고 닿으면 줍는다.

var kind := "coin"
var pickup_id := ""
var value := 1
var hit_radius := 4.0
var pulled_by_rope := true
var taken := false
var spr: Sprite2D
var t := 0.0
var vel := Vector2.ZERO
var h := 0.0
var vh := 0.0

func _ready() -> void:
	add_to_group("hookable")
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 6
	cs.shape = sh
	cs.position = Vector2(0, -3)
	add_child(cs)
	add_child(Fx.shadow(6, 2))
	spr = Sprite2D.new()
	match kind:
		"coin":
			spr.texture = Fx.tex("coin"); spr.hframes = 4
		"heart":
			var at := AtlasTexture.new()
			at.atlas = Fx.tex("hearts"); at.region = Rect2(0, 0, 9, 8)
			spr.texture = at
		"shard", "pearl", "ember", "gloom":
			spr.texture = Fx.tex("moonshard" if kind == "shard" else "item_" + kind)
			var lt := PointLight2D.new()
			lt.texture = preload("res://scripts/world.gd").light_texture()
			lt.color = Color(1, 0.9, 0.5)
			lt.energy = 0.8
			lt.texture_scale = 0.6
			add_child(lt)
	add_child(spr)
	body_entered.connect(_on_body)
	if not kind in ["shard", "pearl", "ember", "gloom"]:
		vel = Vector2.from_angle(randf() * TAU) * 30
		vh = 60

func _physics_process(delta: float) -> void:
	t += delta
	vh -= 260 * delta
	h = maxf(0.0, h + vh * delta)
	if h == 0.0 and vh < 0:
		vh = -vh * 0.35 if absf(vh) > 20 else 0.0
	position += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 80 * delta)
	var key_item := kind in ["shard", "pearl", "ember", "gloom"]
	spr.position.y = -6 - h - (sin(t * 4) * 1.5 if key_item else 0.0)
	if kind == "coin":
		spr.frame = int(t * 8) % 4
	var p = get_tree().get_first_node_in_group("player")
	if p and t > 0.4 and not key_item:
		var d: Vector2 = p.global_position - global_position
		if d.length() < 28:
			position += d.normalized() * 110 * delta
	# 생기자마자 주인공과 겹쳐 있으면 "들어옴" 신호가 다시 오지 않으므로 직접 확인한다
	# (밧줄로 끌어와 바로 앞에서 잡았을 때 엽전이 안 먹히던 문제)
	if t > 0.25 and not taken:
		for b in get_overlapping_bodies():
			_on_body(b)
			if taken: return
	if t > 12 and not key_item:
		modulate.a = 0.5 + 0.5 * sin(t * 20)
		if t > 15: queue_free()

func _on_body(b: Node) -> void:
	if taken or not b.is_in_group("player") or t < 0.25:
		return
	taken = true
	match kind:
		"coin":
			Game.add_coins(value)
			Sound.play("coin", 0.05, -4)
			Fx.number(get_parent(), position, "+%d" % value, Color(1, 0.9, 0.4))
		"heart":
			Game.heal(2)
			Sound.play("heal")
		"shard", "pearl", "ember", "gloom":
			Game.add_item(kind)
			if pickup_id != "":
				Game.set_flag(pickup_id)
			Sound.play("shard", 0.0)
			get_tree().call_group("main", "got_item", kind)
	queue_free()
