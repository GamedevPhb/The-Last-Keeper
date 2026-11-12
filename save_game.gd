class_name SaveGame
extends RefCounted
## Save slots 1-3 in user://save_<n>.json. A save holds all of `GameState` (`to_save()`),
## the keeper's position and facing, every pickup lying on the ground, and the state of each
## node in the "saveable" group (they implement `save_state()` / `load_state(data)`), keyed by
## their path under main.tscn.

const SLOTS := 3
const VERSION := 1


static func path(slot: int) -> String:
	return "user://save_%d.json" % slot


static func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


static func delete(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


static func read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path(slot)))
	return parsed if parsed is Dictionary else {}


## What the slot screen shows: night time, real date of the save, lamp state.
static func meta(slot: int) -> Dictionary:
	var data := read(slot)
	return data.get("meta", {}) if not data.is_empty() else {}


static func write(slot: int, main: Node) -> void:
	var data := capture(main)
	var file := FileAccess.open(path(slot), FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save slot %d: %s" % [slot, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))


static func capture(main: Node) -> Dictionary:
	var state: Node = main.get_node("/root/GameState")
	var player: Node3D = main.get_node_or_null("Player")
	var nodes := {}
	for node in main.get_tree().get_nodes_in_group("saveable"):
		if main.is_ancestor_of(node):
			nodes[str(main.get_path_to(node))] = node.save_state()
	var pickups: Array = []
	for pickup in main.get_tree().get_nodes_in_group("pickups"):
		if main.is_ancestor_of(pickup) and not pickup.is_queued_for_deletion():
			pickups.append({"item": pickup.item, "count": pickup.count, "at": _vec(pickup.global_position)})
	var data := {
		"version": VERSION,
		"meta": {
			"minutes": state.minutes,
			"clock": state.clock_text(),
			"saved_at": Time.get_datetime_string_from_system(false, true),
			"lamp": "ACESA" if state.lamp_lit else "APAGADA",
			"finished": state.finished or state.dead,
		},
		"state": state.to_save(),
		"nodes": nodes,
		"pickups": pickups,
	}
	if player:
		data["player"] = {
			"at": _vec(player.global_position),
			"yaw": player.rotation.y,
			"pitch": player.get_node("Head").rotation.x,
		}
	return data


static func apply(data: Dictionary, main: Node) -> void:
	var state: Node = main.get_node("/root/GameState")
	state.from_save(data.get("state", {}))
	var nodes: Dictionary = data.get("nodes", {})
	for key: String in nodes:
		var node := main.get_node_or_null(NodePath(key))
		if node and node.has_method("load_state"):
			node.load_state(nodes[key])
	for pickup in main.get_tree().get_nodes_in_group("pickups"):
		if main.is_ancestor_of(pickup):
			pickup.remove_from_group("pickups")
			pickup.queue_free()
	for saved: Dictionary in data.get("pickups", []):
		var pickup: Node3D = load("res://items/pickup.gd").new()
		pickup.item = saved.item
		pickup.count = int(saved.count)
		main.add_child(pickup)
		pickup.global_position = _to_vec(saved.at)
	var player: Node3D = main.get_node_or_null("Player")
	var where: Dictionary = data.get("player", {})
	if player and not where.is_empty():
		player.global_position = _to_vec(where.at)
		player.rotation.y = where.yaw
		player.get_node("Head").rotation.x = where.pitch
		player.velocity = Vector3.ZERO


static func _vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _to_vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
