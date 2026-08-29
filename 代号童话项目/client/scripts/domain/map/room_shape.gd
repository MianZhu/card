class_name RoomShape
extends RefCounted

# 房间形状（关卡.xlsx「房间形状」）。每种形状用「相对格坐标」表示，(x 向右, y 向下)。
enum {
	SQUARE_2x2 = 0, # 正方形 2x2
	RECT_2x3 = 1,   # 长方形 2x3
	RECT_3x2 = 2,   # 长方形 3x2
	L_LONG = 3,     # 长L
	L_SHORT = 4,    # 短L
	L_FAT = 5,      # 胖L
	T_SHAPE = 6,    # T
	GRID_3x3 = 7,   # 九宫格 3x3
	SINGLE = 8,     # 单格 1x1
}

static func cells(shape: int) -> Array[Vector2i]:
	match shape:
		SQUARE_2x2:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
		RECT_2x3:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]
		RECT_3x2:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
		L_LONG:
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)]
		L_SHORT:
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]
		L_FAT:
			return [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
		T_SHAPE:
			return [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
		GRID_3x3:
			return [
				Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
				Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
			]
		SINGLE:
			return [Vector2i(0, 0)]
	return [Vector2i(0, 0)]

# 返回所有形状 id 的数组。
static func all_shapes() -> Array[int]:
	return [SQUARE_2x2, RECT_2x3, RECT_3x2, L_LONG, L_SHORT, L_FAT, T_SHAPE, GRID_3x3, SINGLE]

# 形状的包围盒（相对坐标）。
static func bounds(shape: int) -> Rect2i:
	var c := cells(shape)
	var min_x := c[0].x
	var max_x := c[0].x
	var min_y := c[0].y
	var max_y := c[0].y
	for p in c:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
