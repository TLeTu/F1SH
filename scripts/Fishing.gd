extends Node2D

var is_casting = false
var fish_data = {}
var points = 0

func _ready():
	fish_data = load_fish_data()
	$CanvasLayer2/Points.text = "Points: %s" % points
	$CanvasLayer2/FishCaughtLabel.hide()

func load_fish_data():
	var file = FileAccess.open("res://data/fish_data.json", FileAccess.READ)
	var json_text = file.get_as_text()
	return JSON.parse_string(json_text)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and not is_casting:
			start_casting()
		elif event.keycode == KEY_ESCAPE:
			_on_return_pressed()

func pick_random_fish():
	var fish_keys = fish_data.keys()
	var weighted_list = []
	
	# Build a weighted list
	for fish in fish_keys:
		var weight = fish_data[fish].get("weight", 1)  # Default weight is 1 if missing
		for i in range(weight):
			weighted_list.append(fish)
	
	# Pick a fish from weighted list
	return weighted_list[randi() % weighted_list.size()]


func start_casting():
	$CanvasLayer2/TIPS.disable_blinking()
	$CanvasLayer2/FishCaughtLabel.hide()
	is_casting = true
	$CanvasLayer2/FishCaughtLabel.text = "Fishing..."
	$CanvasLayer2/FishCaughtLabel.show()

	# Simulate waiting for a fish (randomized time)
	await get_tree().create_timer(randf_range(2, 5)).timeout

	# Pick a random fish from JSON data
	var fish_type = pick_random_fish()

	$CanvasLayer2/FishCaughtLabel.hide()
	print("A ", fish_type, " bit the bait!")

	# Start the corresponding minigame
	start_minigame(fish_type)

func start_minigame(fish_type):
	$CanvasLayer2/FishCaughtLabel.text = "Something is biting!"
	$CanvasLayer2/FishCaughtLabel.show()
	await get_tree().create_timer(1.0).timeout  # Short delay before minigame starts
	$CanvasLayer2/FishCaughtLabel.hide()
	
	var fish_info = fish_data.get(fish_type, {})
	var minigame_path = fish_info.get("minigame", "")

	if minigame_path:
		var minigame_scene = load(minigame_path)
		var minigame_instance = minigame_scene.instantiate()
		add_child(minigame_instance)
		minigame_instance.minigame_result.connect(_on_minigame_result.bind(fish_type))

func _on_minigame_result(success, fish_type):
	var fish_info = fish_data.get(fish_type, {})
	var fish_name = fish_info.get("name", "")
	var value = fish_info.get("value", "")
	if success:
		$CanvasLayer2/FishCaughtLabel.text = "You caught %s!" % fish_name
		points += value
		$CanvasLayer2/Points.text = "Points: %s" % points
		print("Caught:", fish_name)
	else:
		$CanvasLayer2/FishCaughtLabel.text = "It escaped!"
		print(fish_name, "escaped!")

	$CanvasLayer2/FishCaughtLabel.show()
	$CanvasLayer2/TIPS.enable_blinking()
	is_casting = false

func _on_return_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
