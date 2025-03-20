extends Node2D

signal minigame_result(success)

var can_click := false

func _ready():
	$CanvasLayer/MessageLabel.text = "Get Ready..."
	
	# Random delay (0.5 - 3 seconds)
	var wait_time = randf_range(0.5, 3.0)
	$Timer.start(wait_time)
	await $Timer.timeout

	# Enable clicking
	can_click = true
	$CanvasLayer/MessageLabel.text = "Click Now!"

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if can_click:
			print("Success! Player reacted in time.")
			minigame_result.emit(true)
		else:
			print("Failed! Player clicked too early.")
			minigame_result.emit(false)

		queue_free()  # Remove minigame after result
