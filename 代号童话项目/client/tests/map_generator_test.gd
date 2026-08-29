extends SceneTree

# 无头测试：godot --headless --path <client> --script res://tests/map_generator_test.gd
# 断言：生成成功 / 房间数 / 连通 / 无重叠 / 锁可解 / 宝箱数量。
# 注意：--script 模式没有编辑器缓存，这里用 preload（按依赖顺序）来注册 class_name。

const _tile_type = preload("res://scripts/domain/map/tile_type.gd")
const _room_type = preload("res://scripts/domain/map/room_type.gd")
const _room_shape = preload("res://scripts/domain/map/room_shape.gd")
const _chest = preload("res://scripts/domain/map/chest.gd")
const _door = preload("res://scripts/domain/map/door.gd")
const _connection = preload("res://scripts/domain/map/connection.gd")
const _room = preload("res://scripts/domain/map/room.gd")
const _map_spec = preload("res://scripts/domain/map/map_spec.gd")
const _map_geometry = preload("res://scripts/features/map/map_geometry.gd")
const _room_graph = preload("res://scripts/features/map/room_graph.gd")
const _layout_placer = preload("res://scripts/features/map/layout_placer.gd")
const _lock_placer = preload("res://scripts/features/map/lock_placer.gd")
const _chest_placer = preload("res://scripts/features/map/chest_placer.gd")
const _tileizer = preload("res://scripts/features/map/tileizer.gd")
const _map_generator = preload("res://scripts/features/map/map_generator.gd")

var _failures := 0

func _init() -> void:
	_run()
	if _failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TESTS FAILED: ", _failures)
		quit(1)

func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_failures += 1
		print("  FAIL: ", msg)

func _run() -> void:
	for seed in [1, 42, 2024, 7, 123456]:
		var spec = MapGenerator.generate(seed, 12)
		print("seed ", seed, " -> actual ", spec.seed,
			" | rooms=", spec.rooms.size(),
			" doors=", spec.doors.size(),
			" chests=", spec.chests.size(),
			" keys=", spec.keys.size(),
			" grid=", spec.width, "x", spec.height)
		_check(spec != null, "spec generated")
		_check(spec.rooms.size() == 12, "room count == 12")
		_check(_connected(spec), "rooms connected")
		_check(_no_overlap(spec), "rooms not overlapping")
		_check(_locks_solvable(spec), "locks solvable")
		_check(_chest_counts(spec), "chest counts valid")
		_check(_has_spawn_and_exit(spec), "has spawn + exit")

func _spawn_id(spec) -> int:
	for r in spec.rooms:
		if r.is_spawn:
			return r.id
	return 0

func _connected(spec) -> bool:
	var spawn_id := _spawn_id(spec)
	var adj := {}
	for c in spec.connections:
		if not adj.has(c.room_a):
			adj[c.room_a] = []
		if not adj.has(c.room_b):
			adj[c.room_b] = []
		adj[c.room_a].append(c.room_b)
		adj[c.room_b].append(c.room_a)
	var seen := {spawn_id: true}
	var queue: Array = [spawn_id]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for nb in adj.get(cur, []):
			if not seen.has(nb):
				seen[nb] = true
				queue.append(nb)
	return seen.size() == spec.rooms.size()

func _no_overlap(spec) -> bool:
	var owner := {}
	for r in spec.rooms:
		for p in r.cells:
			if owner.has(p):
				return false
			owner[p] = r.id
	return true

func _locks_solvable(spec) -> bool:
	var spawn_id := _spawn_id(spec)
	var reachable := {spawn_id: true}
	var keys_held := {}
	var changed := true
	while changed:
		changed = false
		for r in spec.rooms:
			if reachable.has(r.id):
				for i in range(spec.keys.size()):
					if r.contains_cell(spec.keys[i]):
						keys_held[i] = true
		for c in spec.connections:
			if c.locked and not keys_held.has(c.key_id):
				continue
			if reachable.has(c.room_a) and not reachable.has(c.room_b):
				reachable[c.room_b] = true
				changed = true
			if reachable.has(c.room_b) and not reachable.has(c.room_a):
				reachable[c.room_a] = true
				changed = true
	return reachable.size() == spec.rooms.size()

func _chest_counts(spec) -> bool:
	for r in spec.rooms:
		var count := 0
		for ch in spec.chests:
			if r.contains_cell(ch.cell):
				count += 1
		match r.type:
			RoomType.RED:
				if count < 5 or count > 7:
					return false
			RoomType.TREASURE:
				if count < 2 or count > 3:
					return false
			_:
				if count != 0:
					return false
	return true

func _has_spawn_and_exit(spec) -> bool:
	if spec.width == 0:
		return false
	if spec.exit_cells.is_empty():
		return false
	return spec.get_tile(spec.spawn_cell) == TileType.SPAWN
