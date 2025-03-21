extends Control

func _ready():
	load_and_display_high_score()

func load_and_display_high_score():
	var high_score = 0  # Default high score
	if FileAccess.file_exists("user://high_score.save"):
		var file = FileAccess.open("user://high_score.save", FileAccess.READ)
		high_score = int(file.get_as_text())  # Read and convert to int
	
	$HighScore.text = "High Score: %s" % high_score  # Update label

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Fishing.tscn")

func _on_quit_btn_pressed() -> void:
	get_tree().quit()
