extends Control



func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Fishing.tscn")

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
