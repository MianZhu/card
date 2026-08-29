class_name RoomGraph
extends RefCounted

# 第 1 步：生成房间图。
# 产出：房间（形状/类型/出生点/撤离点）+ 连接（生成树主干 + 额外环路）。
# 房间类型规则：主干内部=蓝色房（不刷宝箱），叶子=红色房（宝箱），最深处=备用撤离点，
#              随机挑 1 个叶子=宝藏房、1 个叶子=龙珠房；出生点=主撤离点（从哪进从哪出）。

static func build(rng: RandomNumberGenerator, room_count: int = 12) -> Dictionary:
	var rooms: Array[Room] = []
	var shapes := RoomShape.all_shapes()
	for i in range(room_count):
		var shape: int = shapes[rng.randi_range(0, shapes.size() - 1)]
		rooms.append(Room.new(i, shape, RoomType.BLUE))

	var spawn_id := 0

	# 生成树：从出生点开始，逐个把「未连通」房间挂到某个已连通房间下。
	var connections: Array[Connection] = []
	var connected := {spawn_id: true}
	var frontier: Array = []
	for i in range(1, room_count):
		frontier.append(i)
	_shuffle(frontier, rng)
	while not frontier.is_empty():
		var child: int = frontier.pop_back()
		var parent: int = _pick_parent(connected, rng)
		connections.append(Connection.new(parent, child))  # is_tree 默认 true
		connected[child] = true

	# 环路：随机补几条非树边（「其他的路」）。
	var loop_count := rng.randi_range(1, 3)
	for _i in range(loop_count):
		var a := rng.randi_range(0, room_count - 1)
		var b := rng.randi_range(0, room_count - 1)
		if a == b:
			continue
		if _already_connected(connections, a, b):
			continue
		var c := Connection.new(a, b)
		c.is_tree = false
		connections.append(c)

	# 深度（BFS over 树边）+ 叶子集合。
	var depth := _compute_depth(connections, spawn_id, room_count)
	var leaf_ids := _leaf_ids(connections, spawn_id, room_count)

	var deepest_id := spawn_id
	var deepest_d := -1
	for i in range(room_count):
		if depth[i] > deepest_d:
			deepest_d = depth[i]
			deepest_id = i

	# 类型分配。
	rooms[spawn_id].is_spawn = true
	rooms[spawn_id].is_exit = true  # 主撤离点 = 出生点
	rooms[spawn_id].type = RoomType.BLUE

	if deepest_id != spawn_id:
		rooms[deepest_id].is_exit = true  # 备用撤离点（最深处）
		rooms[deepest_id].type = RoomType.EXIT

	# 从叶子里挑宝藏房 / 龙珠房（跳过出生点与最深处）。
	var available: Array = []
	for lid in leaf_ids:
		if lid != spawn_id and lid != deepest_id:
			available.append(lid)
	_shuffle(available, rng)
	if available.size() >= 1:
		rooms[available[0]].type = RoomType.TREASURE
	if available.size() >= 2:
		rooms[available[1]].type = RoomType.DRAGONBALL

	# 其余叶子 → 红色房（宝箱）。
	for lid in leaf_ids:
		if lid == spawn_id or lid == deepest_id:
			continue
		if rooms[lid].type == RoomType.BLUE:
			rooms[lid].type = RoomType.RED

	var exit_ids: Array[int] = []
	for r in rooms:
		if r.is_exit:
			exit_ids.append(r.id)

	return {
		"rooms": rooms,
		"connections": connections,
		"spawn_id": spawn_id,
		"exit_ids": exit_ids,
	}

static func _pick_parent(connected: Dictionary, rng: RandomNumberGenerator) -> int:
	var ids: Array = connected.keys()
	return int(ids[rng.randi_range(0, ids.size() - 1)])

static func _already_connected(connections: Array[Connection], a: int, b: int) -> bool:
	for c in connections:
		if (c.room_a == a and c.room_b == b) or (c.room_a == b and c.room_b == a):
			return true
	return false

# 无向树 BFS 计算深度。
static func _compute_depth(connections: Array[Connection], spawn_id: int, room_count: int) -> Array:
	var depth: Array = []
	depth.resize(room_count)
	depth.fill(-1)
	var adj: Array = []
	adj.resize(room_count)
	for i in range(room_count):
		adj[i] = []
	for c in connections:
		if c.is_tree:
			adj[c.room_a].append(c.room_b)
			adj[c.room_b].append(c.room_a)
	depth[spawn_id] = 0
	var queue: Array = [spawn_id]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for nb in adj[cur]:
			if depth[nb] == -1:
				depth[nb] = depth[cur] + 1
				queue.append(nb)
	return depth

# 树叶子 = 度数 1 且非出生点。
static func _leaf_ids(connections: Array[Connection], spawn_id: int, room_count: int) -> Array:
	var degree: Array = []
	degree.resize(room_count)
	degree.fill(0)
	for c in connections:
		if c.is_tree:
			degree[c.room_a] += 1
			degree[c.room_b] += 1
	var leaves: Array = []
	for i in range(room_count):
		if i != spawn_id and degree[i] == 1:
			leaves.append(i)
	return leaves

static func _shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
