class_name TileType
extends RefCounted

# 地图格子类型（生成/渲染用）。对齐关卡.xlsx「场景物品类型」ID 1~7 的语义：
#   1 地块(可走) 2 障碍物(不可穿透) 3 装饰(可穿透) 4~7 场景建筑/宝箱
# 生成阶段只用下面这一组，装饰/可打碎建筑等留待后续。
enum {
	EMPTY = 0,      # 地图外 / 未赋值
	GROUND = 1,     # 房间地面（可走）
	WALL = 2,       # 房间四周障碍物（不可穿透）
	ROAD = 3,       # 路/走廊（可走地面，连接房间）
	DOOR = 4,       # 门（可交互开启）
	CHEST = 5,      # 宝箱（可交互）
	KEY = 6,        # 钥匙（可拾取）
	SPAWN = 7,      # 出生点
	EXIT = 8,       # 撤离点
}

# 是否是可走（玩家能站上去）的格子类型。
static func is_walkable(tile: int) -> bool:
	return tile == GROUND or tile == ROAD or tile == DOOR or tile == SPAWN or tile == EXIT
