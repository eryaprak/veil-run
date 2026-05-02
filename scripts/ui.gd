extends CanvasLayer
class_name GameUI

# Main UI controller for Veil Run

signal continue_button_pressed
signal double_coins_button_pressed
signal menu_button_pressed
signal shop_requested

@onready var hud = $HUD
@onready var menu = $Menu
@onready var game_over_screen = $GameOverScreen
@onready var checkpoint_popup = $CheckpointPopup
@onready var shop_screen = $ShopScreen

# HUD elements
@onready var distance_label = $HUD/DistanceLabel
@onready var coins_label = $HUD/CoinsLabel
@onready var veil_indicator = $HUD/VeilIndicator
@onready var speed_bar = $HUD/SpeedBar

# Menu elements
@onready var total_coins_label = $Menu/TotalCoinsLabel
@onready var high_score_label = $Menu/HighScoreLabel

# Game over elements
@onready var continue_uses_label = $GameOverScreen/ContinueButton/UsesLabel

var last_checkpoint := 0
var continue_uses_remaining := 2

func _ready():
	show_menu()
	update_veil_indicator("light")

func show_menu():
	menu.visible = true
	hud.visible = false
	game_over_screen.visible = false
	checkpoint_popup.visible = false
	if shop_screen:
		shop_screen.visible = false
	# Update persistent stats
	total_coins_label.text = "Coins: %d" % GameData.total_coins
	high_score_label.text = "Best: %dm" % GameData.high_score

func show_hud():
	menu.visible = false
	hud.visible = true
	game_over_screen.visible = false
	if shop_screen:
		shop_screen.visible = false
	continue_uses_remaining = 2

func update_distance(dist: int):
	distance_label.text = "%dm" % dist

func update_coins(coin_count: int):
	coins_label.text = "● %d" % coin_count

func update_speed_bar(speed: float, max_speed: float):
	if speed_bar:
		speed_bar.value = (speed / max_speed) * 100.0

func update_veil_indicator(dimension: String):
	if dimension == "light":
		veil_indicator.text = "☀ LIGHT"
		veil_indicator.modulate = Color(1.0, 0.9, 0.5)
	else:
		veil_indicator.text = "◑ SHADOW"
		veil_indicator.modulate = Color(0.7, 0.3, 1.0)

func show_checkpoint_celebration(checkpoint: int):
	checkpoint_popup.visible = true
	checkpoint_popup.get_node("Label").text = "CHECKPOINT %d\n+%dm" % [checkpoint, checkpoint * 500]
	var tween = create_tween()
	tween.tween_property(checkpoint_popup, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(1.8).timeout
	tween = create_tween()
	tween.tween_property(checkpoint_popup, "modulate:a", 0.0, 0.3)
	await tween.finished
	checkpoint_popup.visible = false
	checkpoint_popup.modulate.a = 1.0

func show_game_over(score: int, coins: int, distance: int):
	game_over_screen.visible = true
	hud.visible = false

	game_over_screen.get_node("ScoreLabel").text = "Distance: %dm" % distance
	game_over_screen.get_node("CoinsLabel").text = "Coins: %d" % coins
	game_over_screen.get_node("HighScoreLabel").text = "Best: %dm" % GameData.high_score
	_update_continue_button()

func _update_continue_button():
	var btn = game_over_screen.get_node("ContinueButton")
	if continue_uses_remaining > 0:
		btn.disabled = false
		btn.text = "▶ CONTINUE (%d left)" % continue_uses_remaining
	else:
		btn.disabled = true
		btn.text = "▶ CONTINUE (used)"

func show_shop():
	if shop_screen:
		shop_screen.visible = true
		_refresh_shop()

func _refresh_shop():
	if not shop_screen:
		return
	var coins_lbl = shop_screen.get_node_or_null("TotalCoinsLabel")
	if coins_lbl:
		coins_lbl.text = "Your Coins: %d" % GameData.total_coins

	var costumes = ["default", "shadow", "light", "mystic"]
	var names = ["Default\n(Free)", "Shadow\n1000●", "Light\n1500●", "Mystic\n2500●"]
	for i in range(costumes.size()):
		var slot = shop_screen.get_node_or_null("CostumeSlot%d" % i)
		if not slot:
			continue
		var label = slot.get_node_or_null("Label")
		var button = slot.get_node_or_null("Button")
		if label:
			label.text = names[i]
		if button:
			if GameData.is_costume_unlocked(costumes[i]):
				if GameData.selected_costume == costumes[i]:
					button.text = "✓ Selected"
					button.disabled = true
				else:
					button.text = "Select"
					button.disabled = false
			else:
				button.text = "Buy"
				button.disabled = false

func _on_start_button_pressed():
	get_tree().call_group("game", "start_game")
	show_hud()

func _on_shop_button_pressed():
	shop_requested.emit()
	show_shop()

func _on_shop_close_pressed():
	if shop_screen:
		shop_screen.visible = false
	show_menu()

func _on_costume_buy_0():
	_handle_costume_action("default")
func _on_costume_buy_1():
	_handle_costume_action("shadow")
func _on_costume_buy_2():
	_handle_costume_action("light")
func _on_costume_buy_3():
	_handle_costume_action("mystic")

func _handle_costume_action(costume_id: String):
	if GameData.is_costume_unlocked(costume_id):
		GameData.select_costume(costume_id)
	else:
		if not GameData.unlock_costume(costume_id):
			# Not enough coins - flash label
			var coins_lbl = shop_screen.get_node_or_null("TotalCoinsLabel")
			if coins_lbl:
				var tween = create_tween()
				tween.tween_property(coins_lbl, "modulate", Color(1.0, 0.3, 0.3), 0.1)
				tween.tween_property(coins_lbl, "modulate", Color.WHITE, 0.3)
	_refresh_shop()

func _on_continue_button_pressed():
	if continue_uses_remaining > 0:
		continue_uses_remaining -= 1
		_update_continue_button()
		continue_button_pressed.emit()

func _on_double_coins_button_pressed():
	double_coins_button_pressed.emit()

func _on_menu_button_pressed():
	menu_button_pressed.emit()
	show_menu()
