extends Node2D
## 말 걸 수 있는 것 (표지판, 문, 우물). lines = [[이름, 말], ...]

var lines: Array = []
var radius := 14.0
var sprite_name := ""
var solid := Vector2.ZERO

func _ready() -> void:
	add_to_group("interact")
	if sprite_name != "":
		var s := Sprite2D.new()
		s.texture = Fx.tex(sprite_name)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0 + 1)
		add_child(s)
	if solid != Vector2.ZERO:
		var b := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = solid
		cs.shape = sh
		cs.position = Vector2(0, -solid.y / 2)
		b.add_child(cs)
		add_child(b)

func interact(_p: Node) -> void:
	get_tree().call_group("main", "dialog", lines)
