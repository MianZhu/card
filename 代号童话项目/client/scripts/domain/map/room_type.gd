class_name RoomType
extends RefCounted

# 房间类型（关卡.xlsx「房间系统」）。
enum {
	BLUE = 0,       # 蓝色房：不刷宝箱（主干/过道）
	RED = 1,        # 红色房：刷 5~7 个宝箱（副线/搜刮点）
	TREASURE = 2,   # 宝藏房：高品质宝箱
	DRAGONBALL = 3, # 龙珠房
	EXIT = 4,       # 出口房（撤离点）
}

static func display_name(type: int) -> String:
	match type:
		BLUE: return "蓝色房"
		RED: return "红色房"
		TREASURE: return "宝藏房"
		DRAGONBALL: return "龙珠房"
		EXIT: return "出口房"
	return "未知"
