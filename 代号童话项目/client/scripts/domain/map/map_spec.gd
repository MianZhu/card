class_name MapSpec
extends RefCounted

# 一张生成好的地图：房间图 + 空间布局 + 门/锁/钥匙 + 宝箱 + 密集 tile 网格。
var seed: int = 0
var rooms: Array[Room] = []
var connections: Array[Connection] = []
var doors: Array[Door] = []
var chests: Array[Chest] = []
var keys: Array[Vector2i] = []          # keys[i] = 钥匙 i 所在格（key_id 即下标）
var spawn_cell: Vector2i = Vector2i.ZERO
var exit_cells: Array[Vector2i] = []

# 密集 tile 网格。
var origin: Vector2i = Vector2i.ZERO    # 网格左上角的绝对格
var width: int = 0
var height: int = 0
var tiles: PackedInt32Array = PackedInt32Array()  # 长度 width*height，索引 = (y*width + x)

func _init(p_seed: int = 0) -> void:
	seed = p_seed

func tile_index(cell: Vector2i) -> int:
	var local := cell - origin
	return local.y * width + local.x

func in_bounds(cell: Vector2i) -> bool:
	var local := cell - origin
	return local.x >= 0 and local.x < width and local.y >= 0 and local.y < height

func get_tile(cell: Vector2i) -> int:
	if not in_bounds(cell):
		return TileType.EMPTY
	return tiles[tile_index(cell)]

func set_tile(cell: Vector2i, value: int) -> void:
	if in_bounds(cell):
		tiles[tile_index(cell)] = value

# 用 {Vector2i: int} 的稀疏格子表建立密集网格（tileizer 产出后调用）。
func apply_cell_map(cell_map: Dictionary) -> void:
	if cell_map.is_empty():
		return
	var min_x := 1 << 30
	var max_x := -(1 << 30)
	var min_y := 1 << 30
	var max_y := -(1 << 30)
	for key in cell_map:
		var p: Vector2i = key
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	origin = Vector2i(min_x, min_y)
	width = max_x - min_x + 1
	height = max_y - min_y + 1
	tiles = PackedInt32Array()
	tiles.resize(width * height)
	tiles.fill(TileType.EMPTY)
	for key in cell_map:
		var p: Vector2i = key
		tiles[tile_index(p)] = int(cell_map[key])

func get_room(room_id: int) -> Room:
	for r in rooms:
		if r.id == room_id:
			return r
	return null

func to_dict() -> Dictionary:
	var room_list: Array = []
	for r in rooms:
		room_list.append(r.to_dict())
	var conn_list: Array = []
	for c in connections:
		conn_list.append({
			"room_a": c.room_a, "room_b": c.room_b, "connection_type": c.connection_type,
			"locked": c.locked, "key_id": c.key_id, "one_way": c.one_way,
		})
	var door_list: Array = []
	for d in doors:
		door_list.append(d.to_dict())
	var chest_list: Array = []
	for c in chests:
		chest_list.append(c.to_dict())
	var key_list: Array = []
	for k in keys:
		key_list.append([k.x, k.y])
	var exit_list: Array = []
	for e in exit_cells:
		exit_list.append([e.x, e.y])
	return {
		"seed": seed,
		"rooms": room_list, "connections": conn_list, "doors": door_list,
		"chests": chest_list, "keys": key_list,
		"spawn_cell": [spawn_cell.x, spawn_cell.y], "exit_cells": exit_list,
		"origin": [origin.x, origin.y], "width": width, "height": height,
		"tiles": Array(tiles),
	}

static func from_dict(d: Dictionary) -> MapSpec:
	var m := MapSpec.new(int(d.get("seed", 0)))
	for rd in d.get("rooms", []):
		m.rooms.append(Room.from_dict(rd))
	for cd in d.get("connections", []):
		var c := Connection.new(int(cd.get("room_a", -1)), int(cd.get("room_b", -1)))
		c.connection_type = int(cd.get("connection_type", Connection.ROAD))
		c.locked = bool(cd.get("locked", false))
		c.key_id = int(cd.get("key_id", -1))
		c.one_way = bool(cd.get("one_way", false))
		m.connections.append(c)
	for dd in d.get("doors", []):
		m.doors.append(Door.from_dict(dd))
	for ch in d.get("chests", []):
		m.chests.append(Chest.from_dict(ch))
	for k in d.get("keys", []):
		m.keys.append(Vector2i(int(k[0]), int(k[1])))
	var sp: Array = d.get("spawn_cell", [0, 0])
	m.spawn_cell = Vector2i(int(sp[0]), int(sp[1]))
	for e in d.get("exit_cells", []):
		m.exit_cells.append(Vector2i(int(e[0]), int(e[1])))
	var o: Array = d.get("origin", [0, 0])
	m.origin = Vector2i(int(o[0]), int(o[1]))
	m.width = int(d.get("width", 0))
	m.height = int(d.get("height", 0))
	m.tiles = PackedInt32Array(d.get("tiles", []))
	return m
