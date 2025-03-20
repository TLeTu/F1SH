extends Node2D

signal minigame_result(success)

var can_click := false
var fail_timer: Timer

func _ready():
	$CanvasLayer/AnimatedSprite2D.play("red")

	# Unpredictable wait time (0.1 - 7 seconds)
	var wait_time = randf_range(0.1, 7.0)
	$Timer.start(wait_time)
	await $Timer.timeout

	# 50% chance to play a FAKE cue before real one
	if randf() < 0.5:
		$CanvasLayer/AnimatedSprite2D.play("blue")
		await get_tree().create_timer(randf_range(0.3, 1.2)).timeout
		$CanvasLayer/AnimatedSprite2D.play("red")  # Fakeout! Back to red
		await get_tree().create_timer(randf_range(0.1, 3.0)).timeout

	# Now the real reaction cue
	can_click = true
	$CanvasLayer/AnimatedSprite2D.play("green")
	
	# Very short reaction window (0.2 - 0.6 seconds)
	fail_timer = Timer.new()
	fail_timer.wait_time = randf_range(0.2, 0.6)
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
			print("Failed! Player clicked too early!")
			minigame_result.emit(false)

		queue_free()  # Remove minigame after result

func _on_fail_timeout():
	if can_click:
		print("Failed! Player didn't click in time.")
		minigame_result.emit(false)
		queue_free()  # Remove minigame after failure
