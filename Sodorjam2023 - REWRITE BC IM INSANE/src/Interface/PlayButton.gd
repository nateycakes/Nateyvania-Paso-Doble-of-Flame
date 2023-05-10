extends Button

export(String, FILE) var next_scene_path : = ""

func _on_button_up() -> void:
	get_tree().change_scene(next_scene_path)
	pass # Replace with function body.

func _get_configuration_warning() -> String:
	return "next_scene_path must be set for UI button" if next_scene_path == "" else ""
