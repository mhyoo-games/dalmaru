extends Node
## 진행 상태, 저장, 입력·글꼴 준비. (자동 로드: Game)

signal changed
signal toast(text: String)
signal shake(power: float)

const SAVE_PATH := "user://dalmaru_save.json"

var hp := 6
var max_hp := 6
var coins := 0
var sword := 0
var items := {}       # 장마다 모으는 물건 셋: shard / pearl / ember / gloom
var shards: int:
	get: return int(items.get("shard", 0))
	set(v): items["shard"] = v
var herbs := 0
var hero := "maru"
var flags := {}
var map_key := "village"
var busy := false   # 대화 중이면 움직이지 않음
var maps := {}
var font: Font
var font_small: Font
var theme: Theme

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_setup_fonts()
	maps = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps.json"))

func reset() -> void:
	max_hp = int(Rules.hero(hero).hp); hp = max_hp; coins = 0; sword = 0; items = {}; herbs = 1
	flags = {}; map_key = "village"; busy = false
	changed.emit()

func flag(k: String) -> bool:
	return flags.get(k, false)

func set_flag(k: String, v := true) -> void:
	flags[k] = v
	changed.emit()

func add_item(item: String, n := 1) -> void:
	items[item] = int(items.get(item, 0)) + n
	changed.emit()

func count(item: String) -> int:
	return int(items.get(item, 0))

func add_coins(n: int) -> void:
	coins += n
	changed.emit()

func hurt(dmg: int) -> void:
	hp = Rules.take(hp, dmg)
	changed.emit()

func heal(n: int) -> void:
	hp = Rules.heal(hp, max_hp, n)
	changed.emit()

func say(text: String) -> void:
	toast.emit(text)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"hp": hp, "max_hp": max_hp, "coins": coins, "sword": sword, "items": items,
		"herbs": herbs, "flags": flags, "map": map_key, "hero": hero}))

func load_save() -> bool:
	if not has_save():
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY:
		return false
	max_hp = int(d.get("max_hp", 6)); hp = max_hp
	coins = int(d.get("coins", 0)); sword = int(d.get("sword", 0))
	items = d.get("items", {"shard": int(d.get("shards", 0))})
	hero = str(d.get("hero", "maru"))
	herbs = int(d.get("herbs", 0)); flags = d.get("flags", {}); map_key = str(d.get("map", "village"))
	if not maps.has(map_key):
		map_key = "village"
	changed.emit()
	return true

func _add_key(action: String, keys: Array, pad_buttons: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in pad_buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)

func _add_axis(action: String, axis: int, dir: float) -> void:
	var j := InputEventJoypadMotion.new()
	j.axis = axis
	j.axis_value = dir
	InputMap.action_add_event(action, j)

func _setup_input() -> void:
	_add_key("left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT]); _add_axis("left", JOY_AXIS_LEFT_X, -1)
	_add_key("right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT]); _add_axis("right", JOY_AXIS_LEFT_X, 1)
	_add_key("up", [KEY_UP, KEY_W], [JOY_BUTTON_DPAD_UP]); _add_axis("up", JOY_AXIS_LEFT_Y, -1)
	_add_key("down", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN]); _add_axis("down", JOY_AXIS_LEFT_Y, 1)
	_add_key("act", [KEY_Z, KEY_J, KEY_ENTER], [JOY_BUTTON_A])
	_add_key("roll", [KEY_X, KEY_K, KEY_SPACE], [JOY_BUTTON_B])
	_add_key("item", [KEY_C, KEY_L], [JOY_BUTTON_Y])   # 갈고리 밧줄
	_add_key("herb", [KEY_V, KEY_SEMICOLON], [JOY_BUTTON_X])
	_add_key("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])

func _pixel_font(path: String) -> Font:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f

func _setup_fonts() -> void:
	font = _pixel_font("res://assets/fonts/Galmuri11.ttf")
	font_small = _pixel_font("res://assets/fonts/Galmuri9.ttf")
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 12
	get_tree().root.theme = theme
