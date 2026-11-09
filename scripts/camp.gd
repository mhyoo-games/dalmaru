extends Node2D
## 적 무리. 가까이 가면 깨어나고, 다 쓰러뜨리면 달빛 조각이 나온다.

var camp_id := ""
var kinds: Array = []
var alive := 0
var woke := false

func _ready() -> void:
	if Game.flag(camp_id):
		if not Game.flag(camp_id + "_shard"):
			var w = get_tree().get_first_node_in_group("world")
			w.spawn_pickup("shard", global_position, camp_id + "_shard")
		queue_free()
		return

func _process(_d: float) -> void:
	if woke:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position) < 90:
		woke = true
		Game.say("도깨비불 무리가 몰려든다!")
		var w = get_tree().get_first_node_in_group("world")
		for i in kinds.size():
			var pos := global_position + Vector2.from_angle(TAU * i / kinds.size()) * 26
			var e = w.spawn_enemy(kinds[i], pos)
			alive += 1
			e.died.connect(_one_down)

func _one_down() -> void:
	alive -= 1
	if alive <= 0:
		Game.set_flag(camp_id)
		var w = get_tree().get_first_node_in_group("world")
		w.spawn_pickup("shard", global_position, camp_id + "_shard")
		Game.say("무리가 흩어지며 무언가 반짝였다!")
		queue_free()
