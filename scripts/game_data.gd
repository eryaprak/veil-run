extends Node
# GameData autoload singleton — do NOT add class_name here, it conflicts with the autoload registration
# Accessed globally as GameData.xxx

# Persistent game data - coins, unlocks, high score
# Uses ConfigFile (INI-style) for simple save/load

const SAVE_PATH = "user://veil_run_save.cfg"

var total_coins := 0
var high_score := 0
var unlocked_costumes := ["default"]  # Array of costume IDs
var selected_costume := "default"

# Costume prices
const COSTUME_PRICES = {
	"default": 0,
	"shadow": 1000,
	"light": 1500,
	"mystic": 2500
}

func _ready():
	load_game()

func save_game():
	var config = ConfigFile.new()
	
	config.set_value("progress", "total_coins", total_coins)
	config.set_value("progress", "high_score", high_score)
	config.set_value("progress", "unlocked_costumes", unlocked_costumes)
	config.set_value("progress", "selected_costume", selected_costume)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game data: " + str(err))

func load_game():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK:
		# No save file, use defaults
		save_game()
		return
	
	total_coins = config.get_value("progress", "total_coins", 0)
	high_score = config.get_value("progress", "high_score", 0)
	unlocked_costumes = config.get_value("progress", "unlocked_costumes", ["default"])
	selected_costume = config.get_value("progress", "selected_costume", "default")

func add_coins(amount: int):
	total_coins += amount
	save_game()

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		save_game()
		return true
	return false

func unlock_costume(costume_id: String) -> bool:
	if costume_id in unlocked_costumes:
		return false  # Already unlocked
	
	var price = COSTUME_PRICES.get(costume_id, 9999)
	if spend_coins(price):
		unlocked_costumes.append(costume_id)
		save_game()
		return true
	return false

func select_costume(costume_id: String):
	if costume_id in unlocked_costumes:
		selected_costume = costume_id
		save_game()

func is_costume_unlocked(costume_id: String) -> bool:
	return costume_id in unlocked_costumes

func update_high_score(score: int):
	if score > high_score:
		high_score = score
		save_game()
