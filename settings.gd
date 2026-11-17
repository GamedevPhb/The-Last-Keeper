extends Node
## Player options, saved to user://settings.cfg and pushed to audio, rendering and the player.

signal applied

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"master": 0.8, "music": 0.7, "sfx": 0.9, "brightness": 1.0,
	"mouse": 0.0025, "stick": 3.2, "fov": 75.0, "fullscreen": false, "jitter": true, "impact": true, ## flash and shake when enemies emerge / in scenes (ui/impact.gd)
	"hands": true, ## first-person hands (ui/hands.gd)
	"crt": 0.7, ## CRT filter strength, 0 = off (psx_post.gdshader)
	"grain": 0.6, ## film/VHS grain strength, 0 = off (psx_post.gdshader)
	"fps": 30, ## frame cap, 30 or 60
	"aspect": 0, ## index into ASPECTS: 4:3 (native 320x240), 16:9, 16:10, 21:9 or the window's own shape
	"resolution": "960x720", ## windowed size, "WxH" (ignored in full screen)
	"touch": 0, ## touch HUD: 0 auto (phones / touchscreens), 1 always, 2 never (TouchControls)
	"touch_look": 0.012, ## radians per viewport pixel dragged on the right half
}

## Aspect choices: [label, ratio]; ratio 0 = whatever the window is (extra view beyond 4:3, no bars).
const ASPECTS := [["4:3 (PS1)", 4.0 / 3.0], ["16:9", 16.0 / 9.0], ["16:10", 16.0 / 10.0], ["21:9", 21.0 / 9.0], ["Tela nativa", 0.0]]
const RESOLUTIONS: Array[Vector2i] = [Vector2i(640, 480), Vector2i(960, 720), Vector2i(1024, 768), Vector2i(1280, 720), Vector2i(1280, 800),
	Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440)]
const BASE := Vector2i(320, 240)

var values := DEFAULTS.duplicate()
var _video_key := ""
## Headless tests run uncapped so the cap never slows them down.
var _headless := DisplayServer.get_name() == "headless"


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


## Window sizes offered: the common ones that fit the monitor, plus the monitor's own size.
func resolutions() -> Array[Vector2i]:
	var screen := DisplayServer.screen_get_size()
	var list: Array[Vector2i] = []
	for size in RESOLUTIONS:
		if size.x <= screen.x and size.y <= screen.y:
			list.append(size)
	if screen.x > 0 and screen.y > 0 and not list.has(screen):
		list.append(screen)
	return list


func parse_resolution(text: String) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i(960, 720)
	return Vector2i(maxi(int(parts[0]), BASE.x), maxi(int(parts[1]), BASE.y))


## Logical view for an aspect index: height stays 240 (the PS1 look), width follows the ratio.
## Returns the size and whether the window shape may add extra view (native).
func view_size(aspect: int) -> Vector2i:
	var ratio: float = ASPECTS[clampi(aspect, 0, ASPECTS.size() - 1)][1]
	if ratio <= 0.0:
		return BASE
	return Vector2i(roundi(BASE.y * ratio), BASE.y)


## Window mode, size and aspect. The 320x240-based view scales by whole numbers and keeps its
## ratio: any leftover window space is black bars, never a stretch. Only re-applied when changed.
func _apply_video() -> void:
	var key := "%s|%s|%s" % [values["fullscreen"], values["aspect"], values["resolution"]]
	if key == _video_key or _headless:
		return
	_video_key = key
	var window := get_window()
	var aspect := clampi(int(values["aspect"]), 0, ASPECTS.size() - 1)
	window.content_scale_size = view_size(aspect)
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if ASPECTS[aspect][1] <= 0.0 else Window.CONTENT_SCALE_ASPECT_KEEP
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if not values["fullscreen"]:
		var size := parse_resolution(str(values["resolution"]))
		var screen := DisplayServer.screen_get_usable_rect()
		size = Vector2i(mini(size.x, screen.size.x), mini(size.y, screen.size.y)) if screen.size.x > 0 else size
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


func apply() -> void:
	for bus in ["Master", "Music", "SFX", "Ambience"]:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			var level: float = values["master"] if bus == "Master" else values["music" if bus == "Music" else "sfx"]
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)))
	RenderingServer.global_shader_parameter_set("psx_brightness", values["brightness"])
	RenderingServer.global_shader_parameter_set("psx_vertex_snap", ProjectSettings.get_setting("shader_globals/psx_vertex_snap", {"value": 2.0})["value"] if values["jitter"] else 0.0)
	RenderingServer.global_shader_parameter_set("psx_crt", values["crt"])
	RenderingServer.global_shader_parameter_set("psx_grain", values["grain"])
	Engine.max_fps = 0 if _headless else int(values["fps"])
	_apply_video()
	if is_inside_tree():
		get_tree().call_group("player", "apply_settings", values["mouse"], values["stick"], values["fov"])
	TouchControls.update()
	applied.emit()
