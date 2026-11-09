extends CanvasLayer
## 체력·엽전·조각 표시, 대화창, 알림, 대왕 체력, 멈춤 메뉴, 손가락 조작.

var root: Control
var hearts: HBoxContainer
var coin_lbl: Label
var herb_lbl: Label
var shard_icons: Array = []
var banner: Label
var toast_lbl: Label
var toast_bg: ColorRect
var boss_box: Control
var boss_fill: ColorRect
var boss_ghost: ColorRect
# 대화
var dlg: NinePatchRect
var dlg_name: Label
var dlg_name_bg: NinePatchRect
var dlg_text: Label
var dlg_arrow: Label
var dlg_choices: VBoxContainer
var lines: Array = []
var line_i := 0
var shown := 0.0
var choices: Array = []
var choice_i := 0
var on_done := Callable()
var talking := false
var blip := 0
# 멈춤
var pause_box: Control
var pause_i := 0
var pause_items: Array = []
var touch: Control

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hearts = HBoxContainer.new()
	hearts.position = Vector2(6, 6)
	hearts.add_theme_constant_override("separation", 1)
	root.add_child(hearts)
	var coin := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = Fx.tex("coin")
	at.region = Rect2(0, 0, 8, 8)
	coin.texture = at
	coin.position = Vector2(6, 17)
	root.add_child(coin)
	coin_lbl = UI.label("0", 10, Color(1, 0.93, 0.6), true, true)
	coin_lbl.position = Vector2(17, 14)
	root.add_child(coin_lbl)
	herb_lbl = UI.label("", 10, Color(0.7, 1, 0.7), true, true)
	herb_lbl.position = Vector2(52, 14)
	root.add_child(herb_lbl)
	for i in Rules.SHARDS_NEEDED:
		var s := TextureRect.new()
		s.texture = Fx.tex("moonshard")
		s.position = Vector2(384 - 16 - (Rules.SHARDS_NEEDED - 1 - i) * 13, 5)
		root.add_child(s)
		shard_icons.append(s)
	banner = UI.label("", 12, UI.PAPER)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.size = Vector2(384, 16)
	banner.position = Vector2(0, 30)
	banner.modulate.a = 0
	root.add_child(banner)
	toast_bg = ColorRect.new()
	toast_bg.color = Color(0.17, 0.12, 0.18, 0.8)
	toast_bg.modulate.a = 0
	root.add_child(toast_bg)
	toast_lbl = UI.label("", 10, Color.WHITE, false, true)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_bg.add_child(toast_lbl)
	_build_boss()
	_build_dialog()
	_build_pause()
	touch = preload("res://scripts/touch.gd").new()
	root.add_child(touch)
	Game.changed.connect(refresh)
	Game.toast.connect(show_toast)
	refresh()

func set_visible_hud(v: bool) -> void:
	for n in [hearts, coin_lbl, herb_lbl] + shard_icons:
		n.visible = v
	root.get_child(1).visible = v
	touch.visible = v and touch.enabled

func refresh() -> void:
	var hs := Rules.hearts(Game.hp, Game.max_hp)
	while hearts.get_child_count() < hs.size():
		hearts.add_child(TextureRect.new())
	for i in hearts.get_child_count():
		var tr: TextureRect = hearts.get_child(i)
		tr.visible = i < hs.size()
		if i < hs.size():
			tr.texture = UI.heart_tex([2, 1, 0][hs[i]])
	coin_lbl.text = str(Game.coins)
	herb_lbl.text = "약초 %d" % Game.herbs if Game.herbs > 0 else ""
	for i in shard_icons.size():
		shard_icons[i].modulate = Color.WHITE if i < Game.shards else Color(0.2, 0.2, 0.3, 0.6)

func show_banner(text: String) -> void:
	banner.text = "〜 %s 〜" % text
	var tw := create_tween()
	banner.modulate.a = 0
	banner.position.y = 24
	tw.set_parallel(true)
	tw.tween_property(banner, "modulate:a", 1.0, 0.4)
	tw.tween_property(banner, "position:y", 30.0, 0.4)
	tw.chain().tween_interval(1.6)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.6)

func show_toast(text: String) -> void:
	toast_lbl.text = text
	var w := Game.font_small.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16
	toast_bg.size = Vector2(w, 15)
	toast_bg.position = Vector2((384 - w) / 2, 158)
	toast_lbl.size = toast_bg.size
	toast_lbl.position = Vector2(0, 1)
	var tw := create_tween()
	toast_bg.modulate.a = 1
	tw.tween_interval(2.2)
	tw.tween_property(toast_bg, "modulate:a", 0.0, 0.5)

# ── 대왕 체력 ──
func _build_boss() -> void:
	boss_box = Control.new()
	boss_box.position = Vector2(92, 196)
	boss_box.visible = false
	root.add_child(boss_box)
	var nm := UI.label("숲지기 대왕멧돼지", 10, UI.PAPER, true, true)
	nm.position = Vector2(0, -13)
	boss_box.add_child(nm)
	var bg := ColorRect.new()
	bg.color = UI.INK
	bg.size = Vector2(200, 7)
	boss_box.add_child(bg)
	boss_ghost = ColorRect.new()
	boss_ghost.color = Color(1, 0.9, 0.7)
	boss_ghost.position = Vector2(1, 1)
	boss_ghost.size = Vector2(198, 5)
	boss_box.add_child(boss_ghost)
	boss_fill = ColorRect.new()
	boss_fill.color = Color("d8524a")
	boss_fill.position = Vector2(1, 1)
	boss_fill.size = Vector2(198, 5)
	boss_box.add_child(boss_fill)

func boss_show(v: bool) -> void:
	boss_box.visible = v
	boss_fill.size.x = 198
	boss_ghost.size.x = 198

func boss_hp(hp: int, mx: int) -> void:
	var w := 198.0 * hp / mx
	boss_fill.size.x = w
	create_tween().tween_property(boss_ghost, "size:x", w, 0.5).set_delay(0.2)

# ── 대화창 ──
func _build_dialog() -> void:
	dlg = UI.box()
	dlg.position = Vector2(10, 154)
	dlg.size = Vector2(364, 56)
	dlg.visible = false
	root.add_child(dlg)
	dlg_name_bg = UI.box()
	dlg_name_bg.position = Vector2(8, -12)
	dlg_name_bg.size = Vector2(80, 18)
	dlg.add_child(dlg_name_bg)
	dlg_name = UI.label("", 10, UI.INK, false, true)
	dlg_name.position = Vector2(8, 3)
	dlg_name_bg.add_child(dlg_name)
	dlg_text = UI.label("", 12, UI.INK, false)
	dlg_text.position = Vector2(12, 10)
	dlg_text.size = Vector2(340, 40)
	dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dlg_text.add_theme_constant_override("line_spacing", 1)
	dlg.add_child(dlg_text)
	dlg_arrow = UI.label("▼", 10, Color("a8323a"), false, true)
	dlg_arrow.position = Vector2(348, 42)
	dlg.add_child(dlg_arrow)
	dlg_choices = VBoxContainer.new()
	dlg_choices.add_theme_constant_override("separation", 0)
	root.add_child(dlg_choices)

func open_dialog(l: Array, cb := Callable(), ch: Array = []) -> void:
	lines = l
	line_i = 0
	on_done = cb
	choices = ch
	choice_i = 0
	talking = true
	Game.busy = true
	dlg.visible = true
	dlg.scale = Vector2(1, 0.2)
	dlg.pivot_offset = dlg.size / 2
	create_tween().tween_property(dlg, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_line()

func _show_line() -> void:
	var who: String = lines[line_i][0]
	dlg_name_bg.visible = who != ""
	dlg_name.text = who
	dlg_name_bg.size.x = Game.font_small.get_string_size(who, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16
	dlg_text.text = lines[line_i][1]
	dlg_text.visible_characters = 0
	shown = 0.0
	_clear_choices()

func _clear_choices() -> void:
	for c in dlg_choices.get_children():
		c.queue_free()
	dlg_choices.visible = false

func _show_choices() -> void:
	_clear_choices()
	dlg_choices.visible = true
	var wmax := 0.0
	for i in choices.size():
		var l := UI.label(("▶ " if i == choice_i else "   ") + choices[i], 10, UI.INK if i == choice_i else Color("5b5a70"), false, true)
		dlg_choices.add_child(l)
		wmax = maxf(wmax, Game.font_small.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x)
	var bg := UI.box()
	bg.show_behind_parent = true
	bg.size = Vector2(wmax + 18, choices.size() * 13 + 10)
	bg.position = Vector2(-9, -5)
	dlg_choices.add_child(bg)
	dlg_choices.move_child(bg, 0)
	dlg_choices.position = Vector2(374 - wmax - 14, 150 - choices.size() * 13 - 4)

func _process(delta: float) -> void:
	if talking:
		var full := dlg_text.text.length()
		if dlg_text.visible_characters < full:
			shown += delta * 42.0
			var n := mini(full, int(shown))
			if n > dlg_text.visible_characters:
				blip += 1
				if blip % 2 == 0: Sound.play("talk", 0.05, -12)
			dlg_text.visible_characters = n
		dlg_arrow.visible = dlg_text.visible_characters >= full and int(Time.get_ticks_msec() / 300) % 2 == 0 and not dlg_choices.visible
		if Input.is_action_just_pressed("act") or Input.is_action_just_pressed("roll"):
			_advance(Input.is_action_just_pressed("roll"))
		elif dlg_choices.visible:
			if Input.is_action_just_pressed("up"): _move_choice(-1)
			elif Input.is_action_just_pressed("down"): _move_choice(1)
	elif pause_box.visible:
		if Input.is_action_just_pressed("up"): _pause_move(-1)
		elif Input.is_action_just_pressed("down"): _pause_move(1)
		elif Input.is_action_just_pressed("act"): _pause_pick()
		elif Input.is_action_just_pressed("pause"): toggle_pause()
	elif Input.is_action_just_pressed("pause") and get_tree().get_first_node_in_group("world") and not Game.busy:
		toggle_pause()

func _move_choice(d: int) -> void:
	choice_i = posmod(choice_i + d, choices.size())
	Sound.play("select", 0.0, -6)
	_show_choices()

func _advance(cancel: bool) -> void:
	if dlg_text.visible_characters < dlg_text.text.length():
		dlg_text.visible_characters = dlg_text.text.length()
		shown = 9999
		if line_i == lines.size() - 1 and not choices.is_empty():
			_show_choices()
		return
	if dlg_choices.visible:
		if cancel:
			choice_i = choices.size() - 1
		_close(choice_i)
		return
	if line_i == lines.size() - 1 and not choices.is_empty():
		_show_choices()
		return
	line_i += 1
	if line_i >= lines.size():
		_close(-1)
	else:
		_show_line()

func _close(pick: int) -> void:
	talking = false
	dlg.visible = false
	_clear_choices()
	Sound.play("select", 0.0, -8)
	# 같은 프레임의 입력이 공격으로 이어지지 않게 한 박자 쉬고 풀어 준다
	await get_tree().create_timer(0.08).timeout
	Game.busy = false
	if on_done.is_valid():
		if pick >= 0: on_done.call(pick)
		else: on_done.call()

# ── 멈춤 ──
func _build_pause() -> void:
	pause_box = Control.new()
	pause_box.visible = false
	pause_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(pause_box)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.12, 0.6)
	dim.size = Vector2(384, 216)
	pause_box.add_child(dim)
	var b := UI.box()
	b.position = Vector2(132, 62)
	b.size = Vector2(120, 92)
	pause_box.add_child(b)
	var t := UI.label("잠깐 쉬기", 12, UI.INK, false)
	t.position = Vector2(14, 8)
	b.add_child(t)
	for i in 3:
		var l := UI.label("", 10, UI.INK, false, true)
		l.position = Vector2(14, 30 + i * 16)
		b.add_child(l)
		pause_items.append(l)
	var help := UI.label("이동 방향키/WASD · Z 공격·말하기 · X 구르기 · C 약초", 10, UI.PAPER, true, true)
	help.position = Vector2(0, 170)
	help.size = Vector2(384, 14)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_box.add_child(help)

func _pause_labels() -> void:
	var names := ["계속하기", "소리 " + ("켜기" if Sound.muted else "끄기"), "처음 화면으로"]
	for i in 3:
		pause_items[i].text = ("▶ " if i == pause_i else "   ") + names[i]

func toggle_pause() -> void:
	pause_box.visible = not pause_box.visible
	get_tree().paused = pause_box.visible
	pause_i = 0
	_pause_labels()
	Sound.play("select", 0.0, -6)

func _pause_move(d: int) -> void:
	pause_i = posmod(pause_i + d, 3)
	Sound.play("select", 0.0, -6)
	_pause_labels()

func _pause_pick() -> void:
	match pause_i:
		0: toggle_pause()
		1:
			Sound.toggle_mute()
			_pause_labels()
		2:
			toggle_pause()
			get_tree().call_group("main", "show_title")
