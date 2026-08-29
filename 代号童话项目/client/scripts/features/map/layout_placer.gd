class_name LayoutPlacer
extends RefCounted

# 第 2 步：把房间摆到网格上（无重叠），并确定每条连接是「共墙」还是「路」，
# 同时算出门格与路格。共墙 = 两房间墙环相交（相邻），路 = 两房间墙环不相交（相隔）。

const MAX_RADIUS := 14   # 房间摆放的扩散半径（相对父房间原点）
const EXTENT := 42       # 房间中心允许偏离原点的最大切比雪夫距离
const ADJACENT_RATIO := 0.35

static func place(rooms: Array[Room], connections: Array[Connection], spawn_id: int, rng: RandomNumberGenerator) -> bool:
	var by_id := {}
	for r in rooms:
		by_id[r.id] = r

	var occupied := {}

	var spawn: Room = by_id[spawn_id]
	spawn.origin = Vector2i.ZERO
	spawn.set_cells_from_origin()
	_mark_occupied(spawn, occupied)

	var parent_of := _parent_map(connections, spawn_id)
	var order := _bfs_order(connections, spawn_id)

	for rid in order:
		if rid == spawn_id:
			continue
		var room: Room = by_id[rid]
		var parent: Room = by_id[parent_of[rid]]
		var want_adjacent: bool = rng.randf() < ADJACENT_RATIO
		if not _try_place(room, parent, occupied, want_adjacent, rng):
			return false

	# 连接解析：需要所有房间的 ground + 墙环（用于路的寻路避让）。
	var blocked := {}
	for r in rooms:
		for p in r.cells:
			blocked[p] = true
		var ring := MapGeometry.wall_ring(r.cells)
		for key in ring:
			blocked[key] = true

	for c in connections:
		_resolve_connection(c, by_id[c.room_a], by_id[c.room_b], blocked)

	return true

static func _mark_occupied(room: Room, occupied: Dictionary) -> void:
	for p in room.cells:
		occupied[p] = true

static func _fits_at(room: Room, origin: Vector2i, occupied: Dictionary) -> bool:
	for rel in RoomShape.cells(room.shape):
		var cell := origin + rel
		if occupied.has(cell):
			return false
		# 不允许与已有地面格正交相邻，保证两房间之间至少留 1 格（墙），避免墙压地面。
		for n in MapGeometry.neighbors(cell):
			if occupied.has(n):
				return false
		if max(absi(cell.x), absi(cell.y)) > EXTENT:
			return false
	return true

static func _try_place(room: Room, parent: Room, occupied: Dictionary, want_adjacent: bool, rng: RandomNumberGenerator) -> bool:
	for origin in _candidate_origins(parent, room.shape, want_adjacent, rng):
		if _fits_at(room, origin, occupied):
			room.origin = origin
			room.set_cells_from_origin()
			_mark_occupied(room, occupied)
			return true
	return false

# 候选摆放原点：相邻（贴边）优先或相隔优先，二者混合。
static func _candidate_origins(parent: Room, child_shape: int, want_adjacent: bool, rng: RandomNumberGenerator) -> Array:
	var pb := parent.bounds
	var cb := RoomShape.bounds(child_shape)
	var cw := cb.size.x
	var ch := cb.size.y

	# 相邻：子包围盒与父包围盒之间留 1 格（这 1 格就是两房间的共墙）。
	var adj := {}
	for y in range(pb.position.y - ch, pb.position.y + pb.size.y + 1):
		adj[Vector2i(pb.position.x - cw - 1, y)] = true
		adj[Vector2i(pb.position.x + pb.size.x + 1, y)] = true
	for x in range(pb.position.x - cw, pb.position.x + pb.size.x + 1):
		adj[Vector2i(x, pb.position.y - ch - 1)] = true
		adj[Vector2i(x, pb.position.y + pb.size.y + 1)] = true
	var adj_unique: Array = adj.keys()
	_shuffle(adj_unique, rng)

	# 相隔：随机偏移（切比雪夫距离 3..MAX_RADIUS）。
	var spaced := {}
	for _i in range(240):
		var dx := rng.randi_range(-MAX_RADIUS, MAX_RADIUS)
		var dy := rng.randi_range(-MAX_RADIUS, MAX_RADIUS)
		if max(absi(dx), absi(dy)) >= 3:
			spaced[parent.origin + Vector2i(dx, dy)] = true
	var spaced_unique: Array = spaced.keys()
	_shuffle(spaced_unique, rng)

	if want_adjacent:
		return adj_unique + spaced_unique
	return spaced_unique + adj_unique

static func _resolve_connection(c: Connection, a: Room, b: Room, blocked: Dictionary) -> void:
	var ring_a := MapGeometry.wall_ring(a.cells)
	var ring_b := MapGeometry.wall_ring(b.cells)
	var shared := MapGeometry.ring_intersection(ring_a, ring_b)
	if not shared.is_empty():
		c.connection_type = Connection.SHARED_WALL
		var mid := Vector2i((a.center().x + b.center().x) / 2, (a.center().y + b.center().y) / 2)
		var door := MapGeometry.nearest_ring_cell(shared, mid)
		c.door_cells = [door]
		c.road_cells = []
	else:
		c.connection_type = Connection.ROAD
		var door_a := MapGeometry.nearest_ring_cell(ring_a, b.center())
		var door_b := MapGeometry.nearest_ring_cell(ring_b, a.center())
		c.door_cells = [door_a, door_b]
		c.road_cells = _find_road(door_a, door_b, blocked)

# 在空地（非 ground、非墙）上做 BFS，找 door_a → door_b 的最短路径。
static func _find_road(door_a: Vector2i, door_b: Vector2i, blocked: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var min_x := min(door_a.x, door_b.x) - 4
	var max_x := max(door_a.x, door_b.x) + 4
	var min_y := min(door_a.y, door_b.y) - 4
	var max_y := max(door_a.y, door_b.y) + 4

	var prev := {}
	var queue: Array = [door_a]
	prev[door_a] = Vector2i(1 << 30, 1 << 30)  # 哨兵
	var found := false
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == door_b:
			found = true
			break
		for n in MapGeometry.neighbors(cur):
			if n.x < min_x or n.x > max_x or n.y < min_y or n.y > max_y:
				continue
			if prev.has(n):
				continue
			var passable := (not blocked.has(n)) or n == door_a or n == door_b
			if not passable:
				continue
			prev[n] = cur
			queue.append(n)

	if not found:
		return _direct_road(door_a, door_b)

	# 回溯
	var path: Array[Vector2i] = []
	var cur := door_b
	while prev[cur] != Vector2i(1 << 30, 1 << 30):
		path.append(cur)
		cur = prev[cur]
	path.append(door_a)
	path.reverse()
	# 去掉两端门格，保留中间路格
	for p in path:
		if p != door_a and p != door_b:
			result.append(p)
	return result

# 兜底：曼哈顿 L 形路径（可能穿过房间，仅极端情况下用到）。
static func _direct_road(door_a: Vector2i, door_b: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var x := door_a.x
	var y := door_a.y
	while x != door_b.x:
		x += signi(door_b.x - door_a.x)
		if Vector2i(x, y) != door_a and Vector2i(x, y) != door_b:
			result.append(Vector2i(x, y))
	while y != door_b.y:
		y += signi(door_b.y - door_a.y)
		if Vector2i(x, y) != door_a and Vector2i(x, y) != door_b:
			result.append(Vector2i(x, y))
	return result

static func _tree_adj(connections: Array[Connection]) -> Dictionary:
	var adj := {}
	for c in connections:
		if not c.is_tree:
			continue
		if not adj.has(c.room_a):
			adj[c.room_a] = []
		if not adj.has(c.room_b):
			adj[c.room_b] = []
		adj[c.room_a].append(c.room_b)
		adj[c.room_b].append(c.room_a)
	return adj

static func _parent_map(connections: Array[Connection], spawn_id: int) -> Dictionary:
	var adj := _tree_adj(connections)
	var parent_of := {}
	var visited := {spawn_id: true}
	var queue: Array = [spawn_id]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for nb in adj.get(cur, []):
			if not visited.has(nb):
				visited[nb] = true
				parent_of[nb] = cur
				queue.append(nb)
	return parent_of

static func _bfs_order(connections: Array[Connection], spawn_id: int) -> Array:
	var adj := _tree_adj(connections)
	var order: Array = []
	var visited := {spawn_id: true}
	var queue: Array = [spawn_id]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		order.append(cur)
		for nb in adj.get(cur, []):
			if not visited.has(nb):
				visited[nb] = true
				queue.append(nb)
	return order

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
