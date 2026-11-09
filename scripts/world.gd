extends Node2D
## data/maps.json 의 지도 하나를 화면에 짓는다: 바닥 타일, 소품, 사람, 적, 출구.

const T := 16
# 소품 글자 → [그림, 막는 크기(가로,세로), 벨 수 있나, 그림 아래 여백]
const OBJ := {
	"T": ["tree_round", Vector2(10, 6), false, 2], "t": ["tree_round2", Vector2(10, 6), false, 2],
	"M": ["tree_maple", Vector2(10, 6), false, 2], "N": ["tree_pine", Vector2(10, 6), false, 2],
	"r": ["rock", Vector2(12, 7), false, 1], "R": ["rock_big", Vector2(20, 9), false, 1],
	"b": ["bush", Vector2(12, 8), true, 1], "B": ["bush_berry", Vector2(12, 8), true, 1],
	"g": ["", Vector2.ZERO, true, 0], "w": ["", Vector2.ZERO, false, 0],
	"f": ["fence_h", Vector2(16, 4), false, 3], "F": ["fence_post", Vector2(5, 4), false, 3], "v": ["fence_v", Vector2(5, 16), false, 1],
	"l": ["lantern", Vector2(10, 6), false, 1], "j": ["jar", Vector2(10, 6), true, 1], "J": ["jar_red", Vector2(10, 6), true, 1],
	"c": ["crate", Vector2(13, 8), false, 1],
	"O": ["post", Vector2.ZERO, false, 1], "Y": ["jangseung", Vector2(8, 6), false, 1], "Z": ["jangseung2", Vector2(8, 6), false, 1],
	"I": ["pillar", Vector2(10, 6), false, 1],
}

static var _tilesets := {}
var theme := ""
static var _light_tex: Texture2D

var key := ""
var data := {}
var ysort: Node2D
var player: CharacterBody2D
var bounds := Rect2()
var _foot := {}

static func tileset(th := "") -> TileSet:
	if _tilesets.has(th):
		return _tilesets[th]
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	var src := TileSetAtlasSource.new()
	src.texture = Fx.tex("tiles" if th == "" else "tiles_" + th)
	src.texture_region_size = Vector2i(T, T)
	for x in 8:
		src.create_tile(Vector2i(x, 0))
		src.create_tile(Vector2i(x, 1))
	for m in range(1, 16):
		src.create_tile(Vector2i(m, 2))
		src.create_tile(Vector2i(m, 6))
		var w := Vector2i(m, 3)
		src.create_tile(w)
		src.set_tile_animation_columns(w, 1)
		src.set_tile_animation_frames_count(w, 3)
		for f in 3:
			src.set_tile_animation_frame_duration(w, f, 0.3)
	ts.add_source(src, 0)
	_tilesets[th] = ts
	return ts

## 지역 색이 있으면 그 그림을 쓴다 (tree_pine_snow 등)
func themed(n: String) -> Texture2D:
	if theme != "" and ResourceLoader.exists("res://assets/sprites/%s_%s.png" % [n, theme]):
		return Fx.tex(n + "_" + theme)
	return Fx.tex(n)

static func light_texture() -> Texture2D:
	if _light_tex:
		return _light_tex
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	_light_tex = t
	return t

func build(map_key: String, spawn := Vector2i(-1, -1)) -> void:
	key = map_key
	data = Game.maps[map_key]
	theme = data.get("theme", "")
	var W: int = data.w
	var H: int = data.h
	bounds = Rect2(0, 0, W * T, H * T)
	var ground: Array = data.ground
	var objs: Array = data.objects
	# 바닥
	var base := _layer(Vector2.ZERO, -20)
	var decal := _layer(Vector2.ZERO, -19)
	var water := _layer(Vector2(-8, -8), -18)
	var path := _layer(Vector2(-8, -8), -17)
	var plaza := _layer(Vector2(-8, -8), -16)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map_key)
	for y in H:
		for x in W:
			base.set_cell(Vector2i(x, y), 0, Vector2i(rng.randi_range(0, 7), 0))
			var g := Rules.cell(ground, x, y)
			var o := Rules.cell(objs, x, y)
			if g == "." and o == " " and rng.randf() < 0.14:
				decal.set_cell(Vector2i(x, y), 0, Vector2i(rng.randi_range(0, 7), 1))
	# 다리 칸도 물로 그린다 (그 위에 판자를 얹음)
	var wet := []
	for r in ground:
		wet.append((r as String).replace("D", "W"))
	for y in H + 1:
		for x in W + 1:
			var c := Vector2i(x, y)
			var m := Rules.dual_mask(ground, x, y, "P")
			if m: path.set_cell(c, 0, Vector2i(m, 2))
			m = Rules.dual_mask(wet, x, y, "W")
			if m: water.set_cell(c, 0, Vector2i(m, 3))
			m = Rules.dual_mask(ground, x, y, "S")
			if m: plaza.set_cell(c, 0, Vector2i(m, 6))
	# 물은 따로 (층 8): 걷기는 막지만 화살·밧줄·불씨는 넘어간다
	var walls := StaticBody2D.new()
	add_child(walls)
	var waters := StaticBody2D.new()
	waters.collision_layer = 8
	waters.collision_mask = 0
	add_child(waters)
	for y in H:
		var x := 0
		while x < W:
			if Rules.cell(ground, x, y) == "W":
				var x0 := x
				while x < W and Rules.cell(ground, x, y) == "W":
					x += 1
				_rect(waters, Rect2(x0 * T + 3, y * T + 2, (x - x0) * T - 6, T - 4))
			x += 1
	# 지도 끝 보이지 않는 벽
	_rect(walls, Rect2(-T, -T, W * T + 2 * T, T)); _rect(walls, Rect2(-T, H * T, W * T + 2 * T, T))
	_rect(walls, Rect2(-T, 0, T, H * T)); _rect(walls, Rect2(W * T, 0, T, H * T))
	for y in H:
		for x in W:
			if Rules.cell(ground, x, y) == "D":
				var b := Sprite2D.new()
				b.texture = Fx.tex("bridge")
				b.centered = false
				b.position = Vector2(x * T, y * T)
				b.z_index = -12
				add_child(b)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	for y in H:
		for x in W:
			var o := Rules.cell(objs, x, y)
			if o != " ":
				_object(o, x, y, walls, rng)
	for e in data.entities:
		_entity(e, spawn)
	if player == null:
		_spawn_player(spawn if spawn.x >= 0 else Vector2i(W / 2, H / 2))
	# 빛깔
	var tint: Array = data.tint
	var cm := CanvasModulate.new()
	cm.color = Color(tint[0], tint[1], tint[2])
	add_child(cm)
	_ambient()

func _layer(off: Vector2, z: int) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.tile_set = tileset(theme)
	l.position = off
	l.z_index = z
	add_child(l)
	return l

func _rect(body: StaticBody2D, r: Rect2) -> void:
	var s := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = r.size
	s.shape = sh
	s.position = r.position + r.size / 2
	body.add_child(s)

func feet(x: int, y: int) -> Vector2:
	return Vector2(x * T + T / 2.0, y * T + T - 2)

func _object(o: String, x: int, y: int, walls: StaticBody2D, rng: RandomNumberGenerator) -> void:
	if o == "#":
		_rect(walls, Rect2(x * T, y * T, T, T))
		return
	if not OBJ.has(o):
		return
	var info: Array = OBJ[o]
	var pos := feet(x, y) + Vector2(rng.randi_range(-2, 2) if o in "TtMN" else 0, 0)
	var node: Node2D
	if info[2]:
		node = preload("res://scripts/cuttable.gd").new()
		node.kind = o
	else:
		node = Node2D.new()
	node.position = pos
	ysort.add_child(node)
	var spr := Sprite2D.new()
	if o == "g" or o == "w":
		var at := AtlasTexture.new()
		at.atlas = Fx.tex("tiles")
		at.atlas = Fx.tex("tiles" if theme == "" else "tiles_" + theme)
		at.region = Rect2((3 if o == "g" else [0, 1, 5][rng.randi_range(0, 2)]) * T, T, T, T)
		spr.texture = at
		if o == "w":
			node.z_index = -10
	else:
		spr.texture = themed(info[0])
	spr.centered = true
	spr.offset = Vector2(0, -spr.texture.get_height() / 2.0 + info[3])
	if o in "TtMN" and rng.randf() < 0.5:
		spr.flip_h = true
	node.add_child(spr)
	if node.has_method("setup"):
		node.setup(spr)
	var sz: Vector2 = info[1]
	if sz != Vector2.ZERO:
		var b := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = sz
		cs.shape = sh
		cs.position = Vector2(0, -sz.y / 2.0)
		b.add_child(cs)
		node.add_child(b)
	if o == "O":
		node.add_to_group("post")
	if o == "l":
		var lt := PointLight2D.new()
		lt.texture = light_texture()
		lt.color = Color(1.0, 0.75, 0.4)
		lt.energy = 0.9
		lt.texture_scale = 1.1
		lt.position = Vector2(0, -18)
		node.add_child(lt)
		var tw := lt.create_tween().set_loops()
		tw.tween_property(lt, "energy", 0.7, 0.6 + rng.randf() * 0.3)
		tw.tween_property(lt, "energy", 0.95, 0.5 + rng.randf() * 0.3)

func _entity(e: Dictionary, spawn: Vector2i) -> void:
	var t: String = e.type
	var x: int = e.x
	var y: int = e.y
	match t:
		"player":
			_spawn_player(spawn if spawn.x >= 0 else Vector2i(x, y))
		"house":
			var n := Node2D.new()
			var fw: int = e.fw
			var fh: int = e.fh
			n.position = Vector2(x * T + fw * T / 2.0, (y + 1) * T)
			var s := Sprite2D.new()
			s.texture = Fx.tex(e.sprite)
			s.offset = Vector2(0, -s.texture.get_height() / 2.0 + 4)
			n.add_child(s)
			var b := StaticBody2D.new()
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(fw * T - 8, fh * T - 18)
			cs.shape = sh
			cs.position = Vector2(0, -sh.size.y / 2 - 2)
			b.add_child(cs)
			n.add_child(b)
			ysort.add_child(n)
			var door: Array = e.door
			var d := preload("res://scripts/interact.gd").new()
			d.position = feet(door[0], door[1]) + Vector2(0, 4)
			d.lines = [[e.name, _door_text(e.name)]]
			add_child(d)
			# 창문 불빛
			if key == "village":
				var lt := PointLight2D.new()
				lt.texture = light_texture()
				lt.color = Color(1.0, 0.8, 0.45)
				lt.energy = 0.55
				lt.texture_scale = 1.6
				lt.position = Vector2(0, -22)
				n.add_child(lt)
		"well":
			var n := Node2D.new()
			n.position = Vector2(x * T, (y + 1) * T)
			var s := Sprite2D.new()
			s.texture = Fx.tex("well")
			s.offset = Vector2(0, -14)
			n.add_child(s)
			var b := StaticBody2D.new()
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(24, 10)
			cs.shape = sh
			cs.position = Vector2(0, -7)
			b.add_child(cs)
			n.add_child(b)
			ysort.add_child(n)
			var d := preload("res://scripts/interact.gd").new()
			d.position = n.position + Vector2(0, 2)
			d.lines = [["", "말라 버린 우물이다. 바닥에서 희미하게 달빛 냄새가 난다."]]
			d.radius = 20
			add_child(d)
		"sign":
			var n := preload("res://scripts/interact.gd").new()
			n.position = feet(x, y)
			n.sprite_name = "sign"
			n.lines = [["표지판", e.text]]
			n.solid = Vector2(10, 5)
			ysort.add_child(n)
		"npc":
			var n := preload("res://scripts/npc.gd").new()
			n.npc_id = e.id
			n.sprite_name = e.sprite
			n.display_name = e.name
			n.wander = e.get("wander", 0)
			n.position = feet(x, y)
			ysort.add_child(n)
		"chest":
			var n := preload("res://scripts/chest.gd").new()
			n.chest_id = e.id
			n.item = e.item
			n.position = feet(x, y)
			ysort.add_child(n)
		"shard", "pearl", "ember", "gloom":
			if not Game.flag(e.id):
				spawn_pickup(t, feet(x, y), e.id)
		"camp":
			var n := preload("res://scripts/camp.gd").new()
			n.camp_id = e.id
			n.kinds = e.kinds
			n.reward = e.get("reward", "shard")
			n.position = feet(x, y)
			add_child(n)
		"enemy":
			spawn_enemy(e.kind, feet(x, y))
		"boss":
			var bk: String = e.get("kind", "boar")
			if not Game.flag(Rules.boss_flag(bk)):
				var n: Node2D
				if bk == "serpent":
					n = preload("res://scripts/serpent.gd").new()
					n.lake = Rect2(e.lake[0] * T, e.lake[1] * T, e.lake[2] * T, e.lake[3] * T)
				else:
					n = preload("res://scripts/boss.gd").new()
					n.kind = bk
				n.position = feet(x, y)
				ysort.add_child(n)
		"waystone":
			var n := preload("res://scripts/interact.gd").new()
			n.position = feet(x, y)
			n.sprite_name = "waystone"
			n.solid = Vector2(12, 6)
			n.action = "travel"
			ysort.add_child(n)
		"spring":
			var n := preload("res://scripts/spring.gd").new()
			n.position = feet(x, y)
			n.boss_kind = e.get("boss", "boar")
			add_child(n)
		"warp":
			var a := Area2D.new()
			var cs := CollisionShape2D.new()
			var sh := RectangleShape2D.new()
			sh.size = Vector2(e.w * T, e.h * T)
			cs.shape = sh
			a.position = Vector2(x * T, y * T) + sh.size / 2
			a.collision_layer = 0
			a.collision_mask = 2  # 주인공 층
			a.add_child(cs)
			add_child(a)
			var to: String = e.to
			var tx: int = e.tx
			var ty: int = e.ty
			var need: String = e.get("need", "")
			a.body_entered.connect(func(body):
				if body == player:
					if Rules.can_enter(need, Game.items, Game.flags):
						get_tree().call_group("main", "go_map", to, Vector2i(tx, ty))
					else:
						Game.say(_locked_text(need))
						player.push_back(Vector2(-1, 0) if x > 2 else Vector2(1, 0)))

func walkable_at(p: Vector2) -> bool:
	var c := Vector2i(int(p.x / T), int(p.y / T))
	if c.x < 1 or c.y < 1 or c.x >= int(data.w) - 1 or c.y >= int(data.h) - 1:
		return false
	if _foot.is_empty():
		_foot = Rules.footprint_cells(data.entities)
	return not _foot.has(c) and not Rules.blocks(Rules.cell(data.ground, c.x, c.y), Rules.cell(data.objects, c.x, c.y))

func _locked_text(need: String) -> String:
	if need == "shards" or need.begins_with("item:"):
		var it := "shard" if need == "shards" else need.substr(5)
		var nm := "물건"
		for c in Rules.CHAPTERS:
			if Rules.CHAPTERS[c].item == it: nm = Rules.CHAPTERS[c].item_name
		return "%s이(가) 모자라다 (%d/%d)" % [nm, Game.count(it), Rules.SHARDS_NEEDED]
	return "아직은 갈 수 없다. 앞의 일을 먼저 마무리하자."

func _door_text(n: String) -> String:
	match n:
		"촌장 댁": return "문이 굳게 닫혀 있다. 할머니는 마당에 계신다."
		"대장간": return "안에서 쇠 냄새가 난다. 쇠돌 아저씨는 앞에 나와 있다."
		_: return "우리 집이다. 지금은 쉴 때가 아니야."

func _spawn_player(c: Vector2i) -> void:
	player = preload("res://scripts/player.gd").new()
	player.position = feet(c.x, c.y)
	ysort.add_child(player)
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(bounds.size.x)
	cam.limit_bottom = int(bounds.size.y)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	cam.offset = Vector2(0, -8)
	player.add_child(cam)
	player.cam = cam

func spawn_enemy(kind: String, pos: Vector2) -> Node2D:
	var n := preload("res://scripts/enemy.gd").new()
	n.kind = kind
	n.position = pos
	ysort.add_child.call_deferred(n)
	return n

func spawn_pickup(kind: String, pos: Vector2, id := "", value := 1) -> void:
	var p := preload("res://scripts/pickup.gd").new()
	p.kind = kind
	p.pickup_id = id
	p.value = value
	p.position = pos
	ysort.add_child.call_deferred(p)

func _ambient() -> void:
	# 들판엔 날리는 꽃잎, 마을엔 반딧불, 빈터엔 달빛 가루
	var p := CPUParticles2D.new()
	p.amount = 24
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(240, 140)
	p.direction = Vector2(1, 0.4)
	p.spread = 25
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 6
	p.initial_velocity_max = 14
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.z_index = 30
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color(1, 1, 1, 1))
	ramp.add_point(0.8, Color(1, 1, 1, 1))
	ramp.set_color(ramp.get_point_count() - 1, Color(1, 1, 1, 0))
	p.color_ramp = ramp
	match key:
		"village":
			p.color = Color(1.0, 0.95, 0.55)
			p.direction = Vector2(0, -1)
			p.spread = 180
			p.initial_velocity_max = 6
			p.amount = 18
		"field":
			p.color = Color(1.0, 0.8, 0.85)
		"peak", "cave":
			p.color = Color(1, 1, 1)
			p.direction = Vector2(0.3, 1)
			p.amount = 60
			p.initial_velocity_min = 14
			p.initial_velocity_max = 26
		"ferry", "lake":
			p.color = Color(0.75, 1.0, 0.6)
			p.direction = Vector2(0, -1)
			p.spread = 180
		"ruins", "throne":
			p.color = Color(0.75, 0.55, 1.0)
			p.direction = Vector2(0, -1)
		_:
			p.color = Color(0.7, 0.95, 1.0)
			p.direction = Vector2(0, -1)
	p.local_coords = false
	if player:
		player.add_child(p)
