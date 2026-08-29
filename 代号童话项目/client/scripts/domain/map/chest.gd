class_name Chest
extends RefCounted

# 宝箱品质，对应回收物价值档位（白/蓝/紫/金/红）。
enum {
	WHITE = 0,
	BLUE = 1,
	PURPLE = 2,
	GOLD = 3,
	RED = 4,
}

var id: int = -1
var cell: Vector2i = Vector2i.ZERO
var quality: int = WHITE

func _init(p_cell: Vector2i = Vector2i.ZERO, p_quality: int = WHITE) -> void:
	cell = p_cell
	quality = p_quality

func to_dict() -> Dictionary:
	return {"id": id, "cell": [cell.x, cell.y], "quality": quality}

static func from_dict(d: Dictionary) -> Chest:
	var c := Chest.new(Vector2i(int(d.get("cell", [0, 0])[0]), int(d.get("cell", [0, 0])[1])), int(d.get("quality", WHITE)))
	c.id = int(d.get("id", -1))
	return c
