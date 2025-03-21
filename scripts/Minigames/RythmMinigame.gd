extends Node2D

signal minigame_result(success)

var sequence = []  # List of actions (real presses & fake-outs)
var current_index = 0  # Track the player's progress
var can_press = false  # Flag to allow/disallow input
var input_map = {KEY_LEFT: "left", KEY_RIGHT: "right", KEY_UP: "up", KEY_DOWN: "down"}
var arrow_nodes = {}  # Dictionary to store arrow nodes
var player_points = 0  # Will be set when minigame starts

func start_minigame(points):
	player_points = points  # Store player's current points
	$PressTimer.timeout.connect(_on_PressTimer_timeout)
	$CanvasLayer/ScareSprite.visible = false
	$CanvasLayer/MessageLabel.show()
	$CanvasLayer/LeftArrow.visible = true
	$CanvasLayer/RightArrow.visible = true
	$CanvasLayer/UpArrow.visible = true
	$CanvasLayer/DownArrow.visible = true
	
	# Store the arrow nodes for easy access
	arrow_nodes = {
		"left": $CanvasLayer/LeftArrow,
		"right": $CanvasLayer/RightArrow,
		"up": $CanvasLayer/UpArrow,
		"down": $CanvasLayer/DownArrow
	}
	
	generate_sequence()
	start_sequence()

func generate_sequence():
	var base_length = 6 + min(player_points / 50, 6)  # Increase length with score
	var num_presses = randi_range(base_length, base_length + 4)
	
	var min_interval = max(0.2, 0.5 - player_points * 0.001)  # Faster as points increase
	var max_interval = max(0.6, 1.2 - player_points * 0.002)
	var fakeout_chance = min(0.2 + player_points * 0.0015, 0.5)  # Max 50% fake-outs

	sequence.clear()
	for i in range(num_presses):
		var random_arrow = ["left", "right", "up", "down"].pick_random()
		var is_fakeout = randf() < fakeout_chance
		
		sequence.append({
			"arrow": random_arrow,
			"delay": randf_range(min_interval, max_interval),
			"fakeout": is_fakeout
		})

func start_sequence():
	current_index = 0
	process_next_arrow()

func process_next_arrow():
	if current_index >= sequence.size():
		win_minigame()
		return

	var arrow_data = sequence[current_index]
	var arrow_name = arrow_data["arrow"]
	var delay = arrow_data["delay"]
	var fakeout = arrow_data["fakeout"]

	await get_tree().create_timer(delay).timeout  # Wait before showing the next arrow

	if arrow_name in arrow_nodes:
		if fakeout:
			arrow_nodes[arrow_name].play("blue")  # Fake-out (don't press)
			await get_tree().create_timer(randf_range(0.3, 0.7)).timeout  # Fake-out duration
			arrow_nodes[arrow_name].play("red")  # Reset
			current_index += 1
			process_next_arrow()  # Move to next arrow
		else:
			arrow_nodes[arrow_name].play("green")  # Real input required
			can_press = true  # Allow player input
			$PressTimer.start(randf_range(0.7, 1.0))  # Reaction time window

func _input(event):
	if event is InputEventKey and event.pressed:
		var pressed_key = event.keycode

		if not can_press:
			# Pressing during a fake-out or outside of allowed input -> FAIL
			lose_minigame()
			return

		if input_map.has(pressed_key) and input_map[pressed_key] == sequence[current_index]["arrow"]:
			# Correct key pressed
			can_press = false  # Disable pressing for now
			$PressTimer.stop()  # Stop the fail timer
			arrow_nodes[sequence[current_index]["arrow"]].play("red")  # Reset arrow animation

			current_index += 1
			process_next_arrow()
		else:
			# Wrong key pressed
			lose_minigame()

func _on_PressTimer_timeout():
	# Player failed to press in time
	lose_minigame()

func win_minigame():
	minigame_result.emit(true)
	queue_free()

func lose_minigame():
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

	# Hide UI elements
	$CanvasLayer/ScareSprite.visible = true
	$CanvasLayer/MessageLabel.hide()
	$CanvasLayer/LeftArrow.visible = false
	$CanvasLayer/RightArrow.visible = false
	$CanvasLayer/UpArrow.visible = false
	$CanvasLayer/DownArrow.visible = false
	
	# Play jumpscare sound
	$Scare.play()

	# Start the blinking effect while the sound is playing
	await flash_screen_blink()

	$Scare.stop()
	queue_free()  # Remove minigame after jumpscare

func flash_screen_blink():
	var flash = $CanvasLayer/FlashScreen  # Reference the ColorRect
	flash.visible = true

	var blink_interval = 0.05  # Speed of blinking (adjustable)
	var blink_duration = 0.5  # Total time the blinking effect should last
	var elapsed_time = 0.0  # Track how long it's been blinking

	while elapsed_time < blink_duration:
		flash.visible = not flash.visible  # Toggle visibility
		await get_tree().create_timer(blink_interval).timeout
		elapsed_time += blink_interval  # Increment elapsed time

	# Ensure the screen ends with no red flash
	flash.visible = false
