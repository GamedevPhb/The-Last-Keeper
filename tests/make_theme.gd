extends SceneTree
## Regenerates res://ui/theme.tres from UiKit.build_theme(). Run after changing the look in ui_kit.gd:
## godot --headless --path . --script res://tests/make_theme.gd


func _initialize() -> void:
	var err := ResourceSaver.save(UiKit.build_theme(), "res://ui/theme.tres")
	print("theme saved: ", error_string(err))
	quit()
