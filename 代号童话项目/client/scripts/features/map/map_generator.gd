class_name MapGenerator
extends RefCounted

# 地图生成器门面：seed → MapSpec。
# 编排 room_graph → layout → 出生点/撤离点 → 锁/钥匙 → 宝箱 → 铺 tile。
# 摆放失败（重叠/放不下）时自动换种子重试；返回的 spec.seed 是实际成功的种子。

const MAX_ATTEMPTS := 40

static func generate(seed: int, room_count: int = 12) -> MapSpec:
	var last_spec: MapSpec = null
	for attempt in range(MAX_ATTEMPTS):
		var spec := _try_generate(seed + attempt, room_count)
		last_spec = spec
		if spec != null:
			return spec
	return last_spec

static func _try_generate(seed: int, room_count: int) -> MapSpec:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var result := RoomGraph.build(rng, room_count)
	var spec := MapSpec.new(seed)
	spec.rooms = result["rooms"]
	spec.connections = result["connections"]
	var spawn_id: int = result["spawn_id"]

	if not LayoutPlacer.place(spec.rooms, spec.connections, spawn_id, rng):
		return null

	_assign_spawn_exit_cells(spec)
	LockPlacer.place(spec, rng)
	ChestPlacer.place(spec, rng)
	Tileizer.run(spec)
	return spec

static func _assign_spawn_exit_cells(spec: MapSpec) -> void:
	for room in spec.rooms:
		var cell := _closest_ground_to_center(room)
		if room.is_spawn:
			spec.spawn_cell = cell
		if room.is_exit:
			spec.exit_cells.append(cell)

static func _closest_ground_to_center(room: Room) -> Vector2i:
	if room.cells.is_empty():
		return room.origin
	var center := room.center()
	var best: Vector2i = room.cells[0]
	var best_d := MapGeometry.manhattan(room.cells[0], center)
	for p in room.cells:
		var d := MapGeometry.manhattan(p, center)
		if d < best_d:
			best_d = d
			best = p
	return best
