extends Node2D

signal minigame_result(success)

var target_clicks = 0
var clicks = 0
var time_limit = 0.0
var timer_running = false
var player_points = 0  # Will be set when minigame starts

func start_minigame(points):
	player_points = points  # Store player's current points
	$CanvasLayer/ScareSprite.visible = false
	$CanvasLayer/Sprite2D.visible = true
	$CanvasLayer/TargetLabel.show()
	$CanvasLayer/TimerLabel.show()
	$CanvasLayer/ClicksLabel.show()
	
	generate_challenge()

	$CanvasLayer/TargetLabel.text = "Click %d times!" % target_clicks
	$CanvasLayer/TimerLabel.text = "Time: %.2f" % time_limit
	$CanvasLayer/ClicksLabel.text = "Clicks: %d/%d" % [clicks, target_clicks]
	
	# Start the timer
	timer_running = true
	$Timer.start(time_limit)

func generate_challenge():
	# Base values
	var base_min_cps = 4  # Easiest click rate per second
	var base_max_cps = 8  # Hardest click rate per second (before scaling)
	var base_time = randf_range(2.5, 5.0)  # Base challenge duration

	# Increase difficulty based on player points
	var difficulty_factor = 1.0 + (player_points * 0.02)  # Scales up with points

	var min_cps = min(12, base_min_cps * difficulty_factor)  # Hard cap at 12 CPS
	var max_cps = min(20, base_max_cps * difficulty_factor)  # Hard cap at 20 CPS
	time_limit = max(1.0, base_time / difficulty_factor)  # Minimum time 1s

	target_clicks = int(time_limit * randf_range(min_cps, max_cps))

func _process(delta):
	if timer_running:
		time_limit -= delta
		$CanvasLayer/TimerLabel.text = "Time: %.2f" % max(time_limit, 0)
		
		if time_limit <= 0:
			timer_running = false
			lose_minigame()

func _input(event):
	if timer_running and event is InputEventMouseButton and event.pressed:
		clicks += 1
		$CanvasLayer/ClicksLabel.text = "Clicks: %d/%d" % [clicks, target_clicks]
		
		if clicks >= target_clicks:
			win_minigame()

func win_minigame():
	timer_running = false
	minigame_result.emit(true)
	queue_free()

func lose_minigame():
	$Timer.stop()
	timer_running = false

	# **Jumpscare now has a random chance of triggering on failure**
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

	$CanvasLayer/ScareSprite.visible = true
	$CanvasLayer/Sprite2D.visible = false
	$CanvasLayer/TargetLabel.hide()
	$CanvasLayer/TimerLabel.hide()
	$CanvasLayer/ClicksLabel.hide()
	$Scare.play()

	await flash_screen_blink()
	$Scare.stop()
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
