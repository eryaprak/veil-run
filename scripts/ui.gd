extends CanvasLayer
class_name GameUI

# Main UI controller for Veil Run

signal continue_button_pressed
signal double_coins_button_pressed
signal menu_button_pressed

@onready var hud = $HUD
@onready var menu = $Menu
@onready var game_over_screen = $GameOverScreen
@onready var checkpoint_popup = $CheckpointPopup

# HUD elements
@onready var distance_label = $HUD/DistanceLabel
@onready var coins_label = $HUD/CoinsLabel
@onready var veil_indicator = $HUD/VeilIndicator

var last_checkpoint := 0

func _ready():
	show_menu()

func show_menu():
	menu.visible = true
	hud.visible = false
	game_over_screen.visible = false
	checkpoint_popup.visible = false

func show_hud():
	menu.visible = false
	hud.visible = true
	game_over_screen.visible = false

func update_distance(dist: int):
	distance_label.text = "%dm" % dist

func update_coins(coin_count: int):
	coins_label.text = "Coins: %d" % coin_count

func update_veil_indicator(dimension: String):
	if dimension == "light":
		veil_indicator.text = "☀️ LIGHT"
		veil_indicator.modulate = Color(1.0, 0.9, 0.7)
	else:
		veil_indicator.text = "🌙 SHADOW"
		veil_indicator.modulate = Color(0.6, 0.3, 0.8)

func show_checkpoint_celebration(checkpoint: int):
	checkpoint_popup.visible = true
	checkpoint_popup.get_node("Label").text = "CHECKPOINT %d\n+500m" % checkpoint
	await get_tree().create_timer(2.0).timeout
	checkpoint_popup.visible = false

func show_game_over(score: int, coins: int, distance: int):
	game_over_screen.visible = true
	hud.visible = false
	
	game_over_screen.get_node("ScoreLabel").text = "Distance: %dm" % distance
	game_over_screen.get_node("CoinsLabel").text = "Coins: %d" % coins

func _on_start_button_pressed():
	get_tree().call_group("game", "start_game")
	show_hud()

func _on_continue_button_pressed():
	continue_button_pressed.emit()

func _on_double_coins_button_pressed():
	double_coins_button_pressed.emit()

func _on_menu_button_pressed():
	menu_button_pressed.emit()
	show_menu()
