extends Node2D

# Main scene - orchestrates game flow
# Veil Run - Endless Runner MVP

@onready var player = $Player
@onready var track_manager = $TrackManager
@onready var ui = $UI
@onready var camera = $Camera2D
@onready var admob = $AdMobManager
@onready var audio_manager = $AudioManager

var game_state := "menu"  # menu, playing, paused, game_over
var score := 0
var coins := 0
var distance := 0.0
var checkpoint_interval := 500.0

func _ready():
	randomize()
	setup_camera()
	connect_signals()
	ui.show_menu()

func connect_signals():
	player.died.connect(game_over)
	player.coin_collected.connect(collect_coin)
	player.veil_shifted.connect(_on_veil_shifted)
	ui.continue_button_pressed.connect(_on_continue_requested)
	ui.double_coins_button_pressed.connect(_on_double_coins_requested)
	ui.menu_button_pressed.connect(show_menu)
	admob.rewarded_ad_earned.connect(_on_rewarded_earned)
	admob.rewarded_ad_failed.connect(_on_rewarded_failed)

func _on_veil_shifted(dimension: String):
	ui.update_veil_indicator(dimension)
	audio_manager.play_sfx("veil_shift")

func _on_continue_requested():
	admob.show_rewarded_ad("continue")

func _on_double_coins_requested():
	admob.show_rewarded_ad("double_coins")

func _on_rewarded_earned(reward_type: String):
	match reward_type:
		"continue":
			_do_continue()
		"double_coins":
			_do_double_coins()
		"daily_bonus":
			_do_daily_bonus()

func _on_rewarded_failed(reward_type: String):
	# Silently ignore — ad wasn't ready
	print("[Main] Rewarded ad failed for: ", reward_type)

func _do_continue():
	game_state = "playing"
	player.revive()
	track_manager.is_running = true
	ui.show_hud()

func _do_double_coins():
	coins *= 2
	GameData.add_coins(coins)
	ui.update_coins(coins)

func _do_daily_bonus():
	var bonus = 50
	GameData.add_coins(bonus)
	ui.show_menu()

func _process(delta):
	if game_state == "playing":
		update_distance(delta)
		check_checkpoint()
		ui.update_speed_bar(track_manager.scroll_speed, track_manager.max_scroll_speed)

func setup_camera():
	camera.position = Vector2(540, 960)
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
	ui.last_checkpoint = 0
	audio_manager.play_music()

func update_distance(delta):
	distance = track_manager.total_distance
	ui.update_distance(int(distance))

func check_checkpoint():
	var checkpoint_count = int(distance / checkpoint_interval)
	if checkpoint_count > ui.last_checkpoint:
		ui.last_checkpoint = checkpoint_count
		on_checkpoint_reached(checkpoint_count)

func on_checkpoint_reached(checkpoint: int):
	ui.show_checkpoint_celebration(checkpoint)
	audio_manager.play_sfx("checkpoint")

func collect_coin():
	coins += 1
	ui.update_coins(coins)
	audio_manager.play_sfx("coin")

func game_over():
	game_state = "game_over"
	track_manager.stop_generation()

	GameData.add_coins(coins)
	GameData.update_high_score(int(distance))

	audio_manager.play_sfx("death")
	await get_tree().create_timer(0.5).timeout
	ui.show_game_over(score, coins, int(distance))
