class_name Rules
extends RefCounted
## 화면과 상관없는 규칙만 모아 둔 곳. tests/run_tests.gd 가 확인한다.

const TILE := 16
const SHARDS_NEEDED := 3
const BLOCKING_OBJECTS := "TtMNrRbBfFvljJc#"
const CUTTABLE := "bBg"
const SWORD_COST := [30, 60]

## 지도 바깥은 가장자리 칸을 그대로 늘린 것으로 본다 (길·물이 화면 끝까지 이어지게).
static func cell(rows: Array, x: int, y: int) -> String:
	if rows.is_empty():
		return " "
	y = clampi(y, 0, rows.size() - 1)
	var r: String = rows[y]
	x = clampi(x, 0, r.length() - 1)
	return r[x]

## 이중 격자: 보이는 타일 (x,y)는 네 칸 (x-1,y-1) (x,y-1) (x-1,y) (x,y)의 모서리에 놓인다.
static func dual_mask(rows: Array, x: int, y: int, ch: String) -> int:
	var m := 0
	if cell(rows, x - 1, y - 1) == ch: m |= 8
	if cell(rows, x, y - 1) == ch: m |= 4
	if cell(rows, x - 1, y) == ch: m |= 2
	if cell(rows, x, y) == ch: m |= 1
	return m

static func blocks(ground: String, obj: String) -> bool:
	return ground == "W" or (obj != " " and BLOCKING_OBJECTS.contains(obj))

static func sword_damage(level: int) -> int:
	return 1 + level

static func sword_cost(level: int) -> int:
	return SWORD_COST[level] if level < SWORD_COST.size() else -1

## 하트 하나 = 체력 2. 돌려주는 값: 2 가득, 1 반, 0 빈칸
static func hearts(hp: int, max_hp: int) -> Array:
	var out := []
	for i in range(int(ceil(max_hp / 2.0))):
		out.append(clampi(hp - i * 2, 0, 2))
	return out

static func take(hp: int, dmg: int) -> int:
	return maxi(0, hp - dmg)

static func heal(hp: int, max_hp: int, amount: int) -> int:
	return mini(max_hp, hp + amount)

## 적이 떨어뜨리는 것. r은 0~1 난수.
static func drop_for(kind: String, r: float) -> String:
	var heart_p := 0.18
	var coin_p := 0.55
	if kind == "boar":
		coin_p = 0.85
	if r < heart_p:
		return "heart"
	if r < heart_p + coin_p:
		return "coin"
	return ""

static func coin_value(kind: String) -> int:
	return 3 if kind == "boar" else 1

## 죽으면 엽전 절반을 잃는다(내림).
static func death_coins(coins: int) -> int:
	return coins - coins / 2

static func can_enter(need: String, shards: int) -> bool:
	return need != "shards" or shards >= SHARDS_NEEDED

## 4방향 중 가장 가까운 쪽 (애니메이션 줄 고르기)
static func facing_row(dir: Vector2) -> int:
	if absf(dir.x) > absf(dir.y):
		return 2
	return 1 if dir.y < 0 else 0
