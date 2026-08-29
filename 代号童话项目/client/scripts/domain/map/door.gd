class_name Door
extends RefCounted

# 一扇「门」：地图上可交互的通行口。门总是落在房间的墙上（WALL 格改为 DOOR）。
# 一个连接可能产生 1 扇门（共墙）或 2 扇门（路的两端）。
var id: int = -1
var cell: Vector2i = Vector2i.ZERO
var room_a: int = -1
var room_b: int = -1
var locked: bool = false
var key_id: int = -1   # 需要的钥匙 id（-1 表示不上锁）
var one_way: bool = false

func _init(p_cell: Vector2i = Vector2i.ZERO) -> void:
	cell = p_cell

func to_dict() -> Dictionary:
	return {
		"id": id, "cell": [cell.x, cell.y],
		"room_a": room_a, "room_b": room_b,
		"locked": locked, "key_id": key_id, "one_way": one_way,
	}

static func from_dict(d: Dictionary) -> Door:
	var door := Door.new(Vector2i(int(d.get("cell", [0, 0])[0]), int(d.get("cell", [0, 0])[1])))
	door.id = int(d.get("id", -1))
	door.room_a = int(d.get("room_a", -1))
	door.room_b = int(d.get("room_b", -1))
	door.locked = bool(d.get("locked", false))
	door.key_id = int(d.get("key_id", -1))
	door.one_way = bool(d.get("one_way", false))
	return door
