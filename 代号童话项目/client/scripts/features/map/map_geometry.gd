class_name MapGeometry
extends RefCounted

# 地图几何工具（纯函数，供 layout_placer / tileizer 复用）。
static func neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(1, 0), cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1), cell + Vector2i(0, -1),
	]

# 房间地面格的「墙环」：所有与地面格正交相邻、但不属于地面格的格子（以 Dictionary 当集合用）。
static func wall_ring(cells: Array[Vector2i]) -> Dictionary:
	var ring := {}
	var cell_set := {}
	for c in cells:
		cell_set[c] = true
	for c in cells:
		for n in neighbors(c):
			if not cell_set.has(n):
				ring[n] = true
	return ring

static func manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

# 在所有房间地面格里挑一个中心（用于面向计算）。
static func room_center(room: Room) -> Vector2i:
	return room.center()

# 在 wall ring 里挑一个「朝向目标」的墙格（离目标中心曼哈顿距离最小的那个）。
static func nearest_ring_cell(ring: Dictionary, target: Vector2i) -> Vector2i:
	var best := Vector2i.ZERO
	var best_d := 1 << 30
	var first := true
	for key in ring:
		var p: Vector2i = key
		var d := manhattan(p, target)
		if first or d < best_d:
			best_d = d
			best = p
			first = false
	return best

# 两个墙环的交集（共墙格）。返回 Dictionary 集合。
static func ring_intersection(a: Dictionary, b: Dictionary) -> Dictionary:
	var inter := {}
	for key in a:
		if b.has(key):
			inter[key] = true
	return inter
