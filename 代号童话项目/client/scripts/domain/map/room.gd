class_name Room
extends RefCounted

# 一个房间：由形状（相对格）+ 摆放原点决定的一批地面格，四周会被墙围住。
var id: int = -1
var shape: int = RoomShape.SQUARE_2x2
var type: int = RoomType.BLUE
var origin: Vector2i = Vector2i.ZERO      # 形状相对坐标的原点对应的绝对格
var cells: Array[Vector2i] = []          # 绝对地面格（含 origin 偏移）
var bounds: Rect2i = Rect2i()            # 地面格的包围盒（绝对坐标）
var is_spawn: bool = false
var is_exit: bool = false

func _init(p_id: int = -1, p_shape: int = RoomShape.SQUARE_2x2, p_type: int = RoomType.BLUE) -> void:
	id = p_id
	shape = p_shape
	type = p_type

# 用原点 + 形状算出绝对地面格与包围盒。
func set_cells_from_origin() -> void:
	cells = []
	for rel in RoomShape.cells(shape):
		cells.append(origin + rel)
	_recompute_bounds()

func _recompute_bounds() -> void:
	if cells.is_empty():
		bounds = Rect2i()
		return
	var min_x := cells[0].x
	var max_x := cells[0].x
	var min_y := cells[0].y
	var max_y := cells[0].y
	for p in cells:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)
	bounds = Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))

func contains_cell(p: Vector2i) -> bool:
	return p in cells

func center() -> Vector2i:
	if cells.is_empty():
		return origin
	var sum := Vector2i.ZERO
	for p in cells:
		sum += p
	return Vector2i(sum.x / cells.size(), sum.y / cells.size())

func to_dict() -> Dictionary:
	var cell_list: Array = []
	for p in cells:
		cell_list.append([p.x, p.y])
	return {
		"id": id, "shape": shape, "type": type,
		"origin": [origin.x, origin.y], "cells": cell_list,
		"is_spawn": is_spawn, "is_exit": is_exit,
	}

static func from_dict(d: Dictionary) -> Room:
	var r := Room.new(int(d.get("id", -1)), int(d.get("shape", RoomShape.SQUARE_2x2)), int(d.get("type", RoomType.BLUE)))
	var o: Array = d.get("origin", [0, 0])
	r.origin = Vector2i(int(o[0]), int(o[1]))
	r.set_cells_from_origin()
	r.is_spawn = bool(d.get("is_spawn", false))
	r.is_exit = bool(d.get("is_exit", false))
	return r
