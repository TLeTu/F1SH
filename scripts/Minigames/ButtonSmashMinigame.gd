extends Node2D

signal minigame_result(success)

var target_clicks = 0
var clicks = 0
var time_limit = 0.0
var timer_running = false

func _ready():
	generate_challenge()
	$CanvasLayer/TargetLabel.text = "Click %d times!" % target_clicks
	$CanvasLayer/TimerLabel.text = "Time: %.2f" % time_limit
	$CanvasLayer/ClicksLabel.text = "Clicks: %d/%d" % [clicks, target_clicks]
	
	# Start the timer
	timer_running = true
	$Timer.start(time_limit)

func generate_challenge():
	# Set an extreme yet possible challenge
	var min_cps = 6  # Minimum realistic clicks per second
	var max_cps = 12 # Maximum extreme challenge
	var base_time = randf_range(2.0, 5.0) # Random base time (2-5s)
	var difficulty_multiplier = randf_range(1.2, 2.5) # Random multiplier for extreme cases
	
	time_limit = base_time
	target_clicks = int(time_limit * randf_range(min_cps, max_cps) * difficulty_multiplier)

func _process(delta):
	if timer_running:
		time_limit -= delta  # Decrease remaining time
		$CanvasLayer/TimerLabel.text = "Time: %.2f" % max(time_limit, 0)  # Update UI
		
		if time_limit <= 0:
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
	timer_running = false
	minigame_result.emit(false)
	queue_free()
