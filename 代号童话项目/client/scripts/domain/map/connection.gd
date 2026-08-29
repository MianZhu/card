class_name Connection
extends RefCounted

# 房间图里的一条「边」：两个房间之间的连接。
# connection_type 由 layout_placer 根据两房间的实际相邻关系确定；locked/key_id 由 lock_placer 确定。
enum {
	SHARED_WALL = 0, # 共墙：两房间相邻，门直接开在墙上（1 扇门）
	ROAD = 1,        # 路：两房间相隔，用走廊连接（2 扇门 + 走廊格）
}

var room_a: int = -1
var room_b: int = -1
var connection_type: int = ROAD
var is_tree: bool = true   # true = 生成树主干边；false = 额外环路
var locked: bool = false
var key_id: int = -1
var one_way: bool = false
# 铺 tile 时计算出的门格与路格（相对地图整体坐标）。
var door_cells: Array[Vector2i] = []
var road_cells: Array[Vector2i] = []

func _init(p_a: int = -1, p_b: int = -1) -> void:
	room_a = p_a
	room_b = p_b
