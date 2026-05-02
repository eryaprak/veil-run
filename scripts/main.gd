extends Node2D

# Main scene - orchestrates game flow
# Veil Run - Endless Runner MVP

@onready var player = $Player
@onready var track_manager = $TrackManager
@onready var ui = $UI
@onready var camera = $Camera2D

var game_state := "menu"  # menu, playing, paused, game_over
var score := 0
var coins := 0
var distance := 0.0
var checkpoint_interval := 500.0  # meters

func _ready():
	randomize()
	setup_camera()
	connect_signals()
	ui.show_menu()

func connect_signals():
	player.died.connect(game_over)
	player.coin_collected.connect(collect_coin)
	player.veil_shifted.connect(_on_veil_shifted)
	ui.continue_button_pressed.connect(continue_run)
	ui.double_coins_button_pressed.connect(_on_double_coins)
	ui.menu_button_pressed.connect(show_menu)

func _on_veil_shifted(dimension: String):
	ui.update_veil_indicator(dimension)

func _on_double_coins():
	# Rewarded ad callback -> double coins
	coins *= 2
	ui.update_coins(coins)

func _process(delta):
	if game_state == "playing":
		update_distance(delta)
		check_checkpoint()

func setup_camera():
	camera.position = Vector2(540, 960)  # center of 1080x1920
	camera.zoom = Vector2(1.0, 1.0)

func show_menu():
	game_state = "menu"
	ui.show_menu()

func start_game():
	game_state = "playing"
	score = 0
	coins = 0
	distance = 0.0
	player.reset()
	track_manager.start_generation()
	ui.show_hud()
	ui.update_coins(0)
	ui.update_distance(0)

func update_distance(delta):
	distance += player.current_speed * delta
	ui.update_distance(int(distance))

func check_checkpoint():
	var checkpoint_count = int(distance / checkpoint_interval)
	if checkpoint_count > ui.last_checkpoint:
		ui.last_checkpoint = checkpoint_count
		on_checkpoint_reached(checkpoint_count)

func on_checkpoint_reached(checkpoint: int):
	# Celebrate animation + optional rewarded ad offer
	ui.show_checkpoint_celebration(checkpoint)

func collect_coin():
	coins += 1
	ui.update_coins(coins)

func game_over():
	game_state = "game_over"
	ui.show_game_over(score, coins, int(distance))

func continue_run():
	# Called after rewarded ad
	game_state = "playing"
	player.revive()
