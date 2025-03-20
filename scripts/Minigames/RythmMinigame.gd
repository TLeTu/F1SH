extends Node2D

signal minigame_result(success)

var sequence = []  # List of actions (real presses & fake-outs)
var current_index = 0  # Track the player's progress
var can_press = false  # Flag to allow/disallow input
var input_map = {KEY_LEFT: "left", KEY_RIGHT: "right", KEY_UP: "up", KEY_DOWN: "down"}
var arrow_nodes = {}  # Dictionary to store arrow nodes

func _ready():
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
	var num_presses = randi_range(6, 14)  # Random number of required presses
	var min_interval = 0.2  # Minimum time between presses
	var max_interval = 1.0  # Maximum time between presses

	for i in range(num_presses):
		var random_arrow = ["left", "right", "up", "down"].pick_random()
		var is_fakeout = randf() < 0.3  # 30% chance to be a fake-out
		
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
			$PressTimer.start(randf_range(0.5, 1.0))  # Reaction time window
			$PressTimer.timeout.connect(_on_PressTimer_timeout)

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
	minigame_result.emit(false)
	queue_free()
