extends Node2D
## 마을 사람. 숨쉬듯 들썩이고, 말을 걸면 dialogs.gd 의 대사를 고른다.

var npc_id := ""
var sprite_name := ""
var display_name := ""
var wander := 0
var radius := 16.0
var spr: Sprite2D
var t := 0.0
var home := Vector2.ZERO
var goal := Vector2.ZERO
var wait := 1.0
var mark: Label

func _ready() -> void:
	add_to_group("interact")
	home = position
	goal = position
	add_child(Fx.shadow(11, 4))
	spr = Sprite2D.new()
	spr.texture = Fx.tex(sprite_name)
	spr.hframes = 2
	spr.offset = Vector2(0, -10)
	add_child(spr)
	var b := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 5
	cs.shape = sh
	cs.position = Vector2(0, -3)
	b.add_child(cs)
	add_child(b)
	# 할 말이 있으면 머리 위 느낌표
	mark = Label.new()
	mark.text = "!"
	mark.add_theme_color_override("font_color", Color(1, 0.86, 0.35))
	mark.add_theme_color_override("font_outline_color", Color(0.17, 0.12, 0.18))
	mark.add_theme_constant_override("outline_size", 3)
	mark.position = Vector2(-3, -40)
	add_child(mark)
	t = randf() * 2

func _process(delta: float) -> void:
	t += delta
	spr.frame = int(t * 1.6) % 2
	mark.visible = Dialogs.has_news(npc_id)
	mark.position.y = -40 + sin(t * 4) * 1.5
	if wander > 0 and not Game.busy:
		if position.distance_to(goal) < 1:
			wait -= delta
			if wait <= 0:
				var g := home + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * wander * 16
				var w = get_tree().get_first_node_in_group("world")
				if w == null or w.walkable_at(g):
					goal = g
				wait = randf_range(1.5, 3.5)
		else:
			position = position.move_toward(goal, 18 * delta)
			spr.flip_h = goal.x < position.x

func interact(p: Node) -> void:
	goal = position
	spr.flip_h = p.global_position.x < global_position.x
	Dialogs.talk(get_tree(), npc_id, display_name)
