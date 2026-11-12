extends Node
## Player options, saved to user://settings.cfg and pushed to audio, rendering and the player.

signal applied

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"master": 0.8, "music": 0.7, "sfx": 0.9, "brightness": 1.0,
	"mouse": 0.0025, "stick": 3.2, "fov": 75.0, "fullscreen": false, "jitter": true,
	"touch": 0, ## touch HUD: 0 auto (phones / touchscreens), 1 always, 2 never (TouchControls)
	"touch_look": 0.012, ## radians per viewport pixel dragged on the right half
}

var values := DEFAULTS.duplicate()


func _ready() -> void:
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for key: String in DEFAULTS:
			values[key] = file.get_value("options", key, DEFAULTS[key])
	apply()


func set_value(key: String, value: Variant) -> void:
	values[key] = value
	apply()
	var file := ConfigFile.new()
	for k: String in values:
		file.set_value("options", k, values[k])
	file.save(PATH)


func apply() -> void:
	for bus in ["Master", "Music", "SFX", "Ambience"]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var level: float = values["master"] if bus == "Master" else values["music" if bus == "Music" else "sfx"]
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	RenderingServer.global_shader_parameter_set("psx_brightness", values["brightness"])
	RenderingServer.global_shader_parameter_set("psx_vertex_snap", ProjectSettings.get_setting("shader_globals/psx_vertex_snap", {"value": 2.0})["value"] if values["jitter"] else 0.0)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if is_inside_tree():
		get_tree().call_group("player", "apply_settings", values["mouse"], values["stick"], values["fov"])
	TouchControls.update()
	applied.emit()
