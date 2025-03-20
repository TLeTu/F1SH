extends Node2D

signal minigame_result(success)

var can_click := false
var fail_timer: Timer  # Timer to track if the player clicks in time

func _ready():
	$CanvasLayer/MessageLabel.text = "Get Ready..."
	
	# Random delay (0.5 - 3 seconds)
	var wait_time = randf_range(0.5, 3.0)
	$Timer.start(wait_time)
	await $Timer.timeout

	# Enable clicking
	can_click = true
	$CanvasLayer/MessageLabel.text = "Click Now!"
	
	# Start fail timer (random 1 - 2 seconds after prompt)
	fail_timer = Timer.new()
	fail_timer.wait_time = randf_range(1.0, 2.0)
	fail_timer.one_shot = true
	fail_timer.timeout.connect(_on_fail_timeout)
	add_child(fail_timer)
	fail_timer.start()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if can_click:
			print("Success! Player reacted in time.")
			minigame_result.emit(true)
			fail_timer.stop()  # Stop fail timer since player clicked
		else:
			print("Failed! Player clicked too early.")
			minigame_result.emit(false)

		queue_free()  # Remove minigame after result

func _on_fail_timeout():
	if can_click:
		print("Failed! Player didn't click in time.")
		minigame_result.emit(false)
		queue_free()  # Remove minigame after failure
