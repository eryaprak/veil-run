extends Node
class_name AudioManager

# Audio manager for Veil Run
# Handles music + SFX with graceful fallback when audio files missing

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var sfx_player2: AudioStreamPlayer = $SFXPlayer2
@onready var sfx_player3: AudioStreamPlayer = $SFXPlayer3

var sfx_sounds := {}
var music_stream = null
var music_volume_db := -6.0
var sfx_volume_db := 0.0
var _sfx_queue := 0

func _ready():
	_load_audio()

func _load_audio():
	# Load music if file exists
	var music_paths = [
		"res://assets/sounds/music_gameplay.ogg",
		"res://assets/sounds/music_gameplay.mp3",
	]
	for path in music_paths:
		if ResourceLoader.exists(path):
			music_stream = load(path)
			break

	# Load SFX
	var sfx_map = {
		"coin": ["res://assets/sounds/sfx_coin.ogg", "res://assets/sounds/sfx_coin.wav"],
		"veil_shift": ["res://assets/sounds/sfx_veil_shift.ogg", "res://assets/sounds/sfx_veil.wav"],
		"death": ["res://assets/sounds/sfx_death.ogg", "res://assets/sounds/sfx_crash.wav"],
		"checkpoint": ["res://assets/sounds/sfx_checkpoint.ogg"],
		"button": ["res://assets/sounds/sfx_button.ogg"],
	}
	for sfx_name in sfx_map:
		for path in sfx_map[sfx_name]:
			if ResourceLoader.exists(path):
				sfx_sounds[sfx_name] = load(path)
				break

func play_music():
	if music_stream == null:
		return
	music_player.stream = music_stream
	music_player.volume_db = music_volume_db
	music_player.autoplay = true
	if not music_player.playing:
		music_player.play()

func stop_music():
	music_player.stop()

func play_sfx(sfx_name: String):
	if not sfx_sounds.has(sfx_name):
		return  # Silently skip missing SFX

	# Round-robin through SFX players to allow overlapping sounds
	var players = [sfx_player, sfx_player2, sfx_player3]
	_sfx_queue = (_sfx_queue + 1) % players.size()
	var player = players[_sfx_queue]
	player.stream = sfx_sounds[sfx_name]
	player.volume_db = sfx_volume_db
	player.play()

func set_music_volume(vol_linear: float):
	music_volume_db = linear_to_db(vol_linear)
	music_player.volume_db = music_volume_db

func set_sfx_volume(vol_linear: float):
	sfx_volume_db = linear_to_db(vol_linear)
