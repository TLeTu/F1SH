extends Node2D

signal minigame_result(success)

var can_click := false
var fail_timer: Timer
var player_points = 0  # Will be set when minigame starts

func start_minigame(points):
	player_points = points  # Store player's current points
	$CanvasLayer/MessageLabel.show()
	$CanvasLayer/AnimatedSprite2D.visible = true
	$CanvasLayer/AnimatedSprite2D.play("red")
	$CanvasLayer/ScareSprite.visible = false
	
	# Adjust difficulty based on points
	var min_wait = max(0.1, 7.0 - player_points * 0.1)  
	var max_wait = max(1.0, 7.0 - player_points * 0.15)  
	var wait_time = randf_range(min_wait, max_wait)
	
	$Timer.start(wait_time)
	await $Timer.timeout

	# **Fake-out Probability Increases with Points**
	var fakeout_chance = min(0.8, 0.3 + player_points * 0.02)  
	if randf() < fakeout_chance:
		$CanvasLayer/AnimatedSprite2D.play("blue")
		await get_tree().create_timer(randf_range(0.3, 1.2)).timeout
		$CanvasLayer/AnimatedSprite2D.play("red")
		await get_tree().create_timer(randf_range(0.1, 3.0)).timeout

	# **The Real Reaction Cue**
	can_click = true
	$CanvasLayer/AnimatedSprite2D.play("green")
	
	# **Reaction Time Shrinks as Difficulty Increases**
	var min_react_time = max(0.1, 0.6 - player_points * 0.01)  
	var max_react_time = max(0.2, 0.8 - player_points * 0.01)  
	var reaction_window = randf_range(min_react_time, max_react_time)

	fail_timer = Timer.new()
	fail_timer.wait_time = reaction_window
	fail_timer.one_shot = true
	fail_timer.timeout.connect(_on_fail_timeout)
	add_child(fail_timer)
	fail_timer.start()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if can_click:
			print("Success! Player reacted in time.")
			minigame_result.emit(true)
			fail_timer.stop()
			queue_free()
		else:
			_fail_action()

func _on_fail_timeout():
	if can_click:
		_fail_action()

func _fail_action():
	# **Jumpscare triggers randomly upon failure**
	var jumpscare_chance = min(0.9, 0.3 + player_points * 0.01)  # 50% → 90% chance
	if randf() < jumpscare_chance:
		_trigger_jumpscare()
	else:
		print("Failed! No jumpscare this time.")
		minigame_result.emit(false)
		queue_free()

func _trigger_jumpscare():
	print("Failed! Jumpscare triggered.")
	minigame_result.emit(false)

	# **Hide UI elements**
	$CanvasLayer/MessageLabel.hide()
	$CanvasLayer/AnimatedSprite2D.visible = false
	$CanvasLayer/ScareSprite.visible = true

	# **Jumpscare Sound & Effects**
	$Scare.play()
	await flash_screen_blink()
	$Scare.stop()
	$CanvasLayer/ScareSprite.visible = false
	queue_free()

func flash_screen_blink():
	var flash = $CanvasLayer/FlashScreen
	flash.visible = true

	var blink_interval = 0.05
	var blink_duration = 0.5
	var elapsed_time = 0.0

	while elapsed_time < blink_duration:
		flash.visible = not flash.visible
		await get_tree().create_timer(blink_interval).timeout
		elapsed_time += blink_interval

	flash.visible = false
