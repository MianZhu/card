class_name ChestPlacer
extends RefCounted

# 第 4 步：按房间类型摆宝箱，并在路（走廊）上散落少量宝箱。
# 红色房 5~7 个；宝藏房 2~3 个高品质；蓝色房/龙珠房/出口房 0 个。

const RED_MIN := 5
const RED_MAX := 7
const ROAD_SCATTER_RATIO := 0.3

static func place(spec: MapSpec, rng: RandomNumberGenerator) -> void:
	var taken := {}
	for k in spec.keys:
		taken[k] = true
	taken[spec.spawn_cell] = true

	var next_id := 0
	for room in spec.rooms:
		var count := _chest_count(room.type, rng)
		for _i in range(count):
			var cell := _pick_free_ground(room, taken, rng)
			if cell == Vector2i(1 << 30, 1 << 30):
				continue
			var chest := Chest.new(cell, _quality_for(room.type, rng))
			chest.id = next_id
			next_id += 1
			spec.chests.append(chest)
			taken[cell] = true

	# 路上散落（沿 ROAD 连接）。
	for c in spec.connections:
		if c.connection_type != Connection.ROAD:
			continue
		if c.road_cells.is_empty():
			continue
		if rng.randf() < ROAD_SCATTER_RATIO:
			var cell: Vector2i = c.road_cells[rng.randi_range(0, c.road_cells.size() - 1)]
			if taken.has(cell):
				continue
			var chest := Chest.new(cell, Chest.WHITE if rng.randf() < 0.8 else Chest.BLUE)
			chest.id = next_id
			next_id += 1
			spec.chests.append(chest)
			taken[cell] = true

static func _chest_count(type: int, rng: RandomNumberGenerator) -> int:
	match type:
		RoomType.RED:
			return rng.randi_range(RED_MIN, RED_MAX)
		RoomType.TREASURE:
			return rng.randi_range(2, 3)
	return 0

static func _quality_for(type: int, rng: RandomNumberGenerator) -> int:
	match type:
		RoomType.TREASURE:
			var r := rng.randf()
			if r < 0.4:
				return Chest.PURPLE
			if r < 0.8:
				return Chest.GOLD
			return Chest.BLUE
		RoomType.RED:
			var r := rng.randf()
			if r < 0.7:
				return Chest.WHITE
			if r < 0.95:
				return Chest.BLUE
			return Chest.PURPLE
	return Chest.WHITE

static func _pick_free_ground(room: Room, taken: Dictionary, rng: RandomNumberGenerator) -> Vector2i:
	var candidates: Array = []
	for p in room.cells:
		if not taken.has(p):
			candidates.append(p)
	if candidates.is_empty():
		return Vector2i(1 << 30, 1 << 30)
	return candidates[rng.randi_range(0, candidates.size() - 1)]
