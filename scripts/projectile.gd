extends Area2D
## 도깨비불이 쏘는 불씨.

var dir := Vector2.RIGHT
var tex_name := "fireball"
var speed := 72.0
var life := 3.0
var spr: Sprite2D

func _ready() -> void:
	z_index = 3
	collision_layer = 0
	collision_mask = 1 | 2
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 3
	cs.shape = sh
	add_child(cs)
	spr = Sprite2D.new()
	spr.texture = Fx.tex(tex_name)
	spr.hframes = 2
	add_child(spr)
	var lt := PointLight2D.new()
	lt.texture = preload("res://scripts/world.gd").light_texture()
	lt.color = {"fireball": Color(0.5, 1, 1), "waterball": Color(0.4, 0.7, 1), "snowball": Color(0.9, 0.95, 1), "darkball": Color(0.7, 0.4, 1)}.get(tex_name, Color.WHITE)
	lt.energy = 0.5
	lt.texture_scale = 0.35
	add_child(lt)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	spr.frame = int(life * 10) % 2
	if life <= 0:
		queue_free()

func _on_body(b: Node) -> void:
	if b.is_in_group("player"):
		if b.is_rolling():
			return
		b.hurt(1, global_position - dir * 8)
	Fx.anim(get_parent(), "spark", 4, position, 20)
	queue_free()
