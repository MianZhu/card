class_name LockPlacer
extends RefCounted

# 第 3 步：给部分门「上锁」并放置钥匙，保证无软锁。
# 规则：只锁「叶子边」（分支尽头的门），钥匙放在父房间（父房间必可达）；
#       环路门只锁浅端非「被锁叶子」的边，钥匙放在浅端。这样钥匙永远在门可达的一侧。

const BRANCH_LOCK_RATIO := 0.5
const LOOP_LOCK_RATIO := 0.4

static func place(spec: MapSpec, rng: RandomNumberGenerator) -> void:
	var spawn_id := _spawn_id(spec)
	var depth := _depth(spec.connections, spawn_id, spec.rooms.size())
	var leaf := _leaf_set(spec.connections, spawn_id, spec.rooms.size())
	var by_id := {}
	for r in spec.rooms:
		by_id[r.id] = r

	var gated := {}  # 被锁住的叶子房间 id

	# 1) 叶子边（分支尽头）上锁。
	for c in spec.connections:
		if not c.is_tree:
			continue
		# 树边方向 room_a=父, room_b=子（room_graph 构造时保证）。
		var child := c.room_b
		if leaf.has(child) and rng.randf() < BRANCH_LOCK_RATIO:
			c.locked = true
			gated[child] = true
			_assign_key(spec, c, by_id[c.room_a], rng)

	# 2) 环路门：只锁浅端可达的边。
	for c in spec.connections:
		if c.is_tree:
			continue
		var a := c.room_a
		var b := c.room_b
		var near := a if depth[a] <= depth[b] else b
		if gated.has(near):
			continue
		if rng.randf() < LOOP_LOCK_RATIO:
			c.locked = true
			_assign_key(spec, c, by_id[near], rng)

static func _assign_key(spec: MapSpec, c: Connection, near_room: Room, rng: RandomNumberGenerator) -> void:
	if near_room.cells.is_empty():
		c.locked = false
		return
	var avoid := {}
	avoid[spec.spawn_cell] = true
	for e in spec.exit_cells:
		avoid[e] = true
	var candidates: Array = []
	for p in near_room.cells:
		if not avoid.has(p):
			candidates.append(p)
	if candidates.is_empty():
		# 找不到可放钥匙的格子就放弃上锁，避免锁死。
		c.locked = false
		return
	var cell: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
	spec.keys.append(cell)
	c.key_id = spec.keys.size() - 1

static func _spawn_id(spec: MapSpec) -> int:
	for r in spec.rooms:
		if r.is_spawn:
			return r.id
	return 0

static func _depth(connections: Array[Connection], spawn_id: int, room_count: int) -> Array:
	var adj: Array = []
	adj.resize(room_count)
	for i in range(room_count):
		adj[i] = []
	for c in connections:
		if c.is_tree:
			adj[c.room_a].append(c.room_b)
			adj[c.room_b].append(c.room_a)
	var depth: Array = []
	depth.resize(room_count)
	depth.fill(-1)
	depth[spawn_id] = 0
	var queue: Array = [spawn_id]
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		for nb in adj[cur]:
			if depth[nb] == -1:
				depth[nb] = depth[cur] + 1
				queue.append(nb)
	return depth

static func _leaf_set(connections: Array[Connection], spawn_id: int, room_count: int) -> Dictionary:
	var degree: Array = []
	degree.resize(room_count)
	degree.fill(0)
	for c in connections:
		if c.is_tree:
			degree[c.room_a] += 1
			degree[c.room_b] += 1
	var leaves := {}
	for i in range(room_count):
		if i != spawn_id and degree[i] == 1:
			leaves[i] = true
	return leaves
