extends Node2D

var is_casting = false
var fish_data = {}

func _ready():
	fish_data = load_fish_data()
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

func start_casting():
	$CanvasLayer2/TIPS.disable_blinking()
	$CanvasLayer2/FishCaughtLabel.hide()
	is_casting = true
	$CanvasLayer2/FishCaughtLabel.text = "Fishing..."
	$CanvasLayer2/FishCaughtLabel.show()

	# Simulate waiting for a fish (randomized time)
	await get_tree().create_timer(randf_range(2, 5)).timeout

	# Pick a random fish from JSON data
	var fish_keys = fish_data.keys()
	var fish_type = fish_keys[randi() % fish_keys.size()]
	$CanvasLayer2/FishCaughtLabel.hide()
	print("A ", fish_type, " bit the bait!")

	# Start the corresponding minigame
	start_minigame(fish_type)

func start_minigame(fish_type):
	$CanvasLayer2/FishCaughtLabel.text = "A fish is biting!"
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
	if success:
		$CanvasLayer2/FishCaughtLabel.text = "You caught a %s!" % fish_name
		print("Caught:", fish_name)
	else:
		$CanvasLayer2/FishCaughtLabel.text = "The %s escaped!" % fish_name
		print(fish_name, "escaped!")

	$CanvasLayer2/FishCaughtLabel.show()
	$CanvasLayer2/TIPS.enable_blinking()
	is_casting = false

func _on_return_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
