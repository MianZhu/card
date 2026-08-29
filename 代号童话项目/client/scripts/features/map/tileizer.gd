class_name Tileizer
extends RefCounted

# 第 5 步：把房间/连接/门/宝箱/钥匙/出生点/撤离点铺成密集 tile 网格。
# 绘制顺序（后者覆盖前者）：地面 → 墙 → 路 → 门 → 宝箱 → 钥匙 → 出生点/撤离点。

static func run(spec: MapSpec) -> void:
	var cell_map := {}
	var ground_set := {}

	# 地面
	for room in spec.rooms:
		for p in room.cells:
			ground_set[p] = true
			cell_map[p] = TileType.GROUND

	# 墙（房间外圈，跳过任何房间地面）
	for room in spec.rooms:
		var ring := MapGeometry.wall_ring(room.cells)
		for key in ring:
			if not ground_set.has(key):
				cell_map[key] = TileType.WALL

	# 路（走廊）
	for c in spec.connections:
		for p in c.road_cells:
			cell_map[p] = TileType.ROAD

	# 门（覆盖墙），并生成 Door 对象
	for c in spec.connections:
		for p in c.door_cells:
			var door := Door.new(p)
			door.id = spec.doors.size()
			door.room_a = c.room_a
			door.room_b = c.room_b
			door.locked = c.locked
			door.key_id = c.key_id
			door.one_way = c.one_way
			spec.doors.append(door)
			cell_map[p] = TileType.DOOR

	# 宝箱（覆盖地面）
	for chest in spec.chests:
		cell_map[chest.cell] = TileType.CHEST

	# 钥匙（覆盖地面）
	for k in spec.keys:
		cell_map[k] = TileType.KEY

	# 出生点 / 撤离点（最后覆盖）
	cell_map[spec.spawn_cell] = TileType.SPAWN
	for e in spec.exit_cells:
		cell_map[e] = TileType.EXIT

	spec.apply_cell_map(cell_map)
