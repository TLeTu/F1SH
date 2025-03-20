extends Control

var is_casting = false
var fish_data = {}

func _ready():
	fish_data = load_fish_data()
	$CastButton.pressed.connect(_on_cast_button_pressed)
	$ReturnButton.pressed.connect(_on_return_button_pressed)
	$FishCaughtLabel.hide()

func load_fish_data():
	var file = FileAccess.open("res://data/fish_data.json", FileAccess.READ)
	var json_text = file.get_as_text()
	return JSON.parse_string(json_text)

func _on_cast_button_pressed():
	$FishCaughtLabel.hide()
	if is_casting:
		return
	
	is_casting = true
	$CastButton.disabled = true
	$CastButton.hide()
	$FishCaughtLabel.text = "Casting line!"
	$FishCaughtLabel.show()

	# Simulate waiting for a fish (randomized time)
	await get_tree().create_timer(randf_range(2, 5)).timeout

	# Pick a random fish from JSON data
	var fish_keys = fish_data.keys()
	var fish_type = fish_keys[randi() % fish_keys.size()]
	$FishCaughtLabel.hide()
	print("A ", fish_type, " bit the bait!")

	# Start the corresponding minigame
	start_minigame(fish_type)

func start_minigame(fish_type):
	$FishCaughtLabel.text = "A fish is biting!"
	$FishCaughtLabel.show()
	await get_tree().create_timer(1.0).timeout  # Short delay before minigame starts
	$FishCaughtLabel.hide()
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
		$FishCaughtLabel.text = "You caught a %s!" % fish_name
		print("Caught:", fish_name)
	else:
		$FishCaughtLabel.text = "The %s escaped!" % fish_name
		print(fish_name, "escaped!")

	$FishCaughtLabel.show()
	is_casting = false
	$CastButton.disabled = false
	$CastButton.show()

func _on_return_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
