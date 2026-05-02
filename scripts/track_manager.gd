extends Node2D
class_name TrackManager

# Procedural track generation for endless runner
# Spawns track segments, obstacles, and coins

signal segment_spawned(segment: Node2D)

@export var track_segment_scene: PackedScene
@export var obstacle_scenes: Array[PackedScene] = []
@export var coin_scene: PackedScene

@export var segment_length := 1000.0
@export var spawn_distance := 3000.0  # Distance ahead to spawn
@export var difficulty_scaling := 0.05  # Obstacle density increase per 1000m

var active_segments := []
var spawn_position := 0.0
var player_distance := 0.0
var difficulty := 1.0

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	pass

func _process(delta):
	if player and player.is_alive:
		player_distance = player.global_position.y  # Approximation
		check_spawn()
		cleanup_old_segments()

func start_generation():
	spawn_position = 0.0
	difficulty = 1.0
	# Spawn initial segments
	for i in range(4):
		spawn_segment()

func check_spawn():
	while spawn_position < player_distance + spawn_distance:
		spawn_segment()

func spawn_segment():
	var segment = create_track_segment()
	segment.position = Vector2(540, -spawn_position)
	add_child(segment)
	active_segments.append(segment)
	
	spawn_position += segment_length
	
	# Update difficulty
	difficulty = 1.0 + (spawn_position / 1000.0) * difficulty_scaling
	
	# Spawn obstacles and coins on segment
	populate_segment(segment)
	
	segment_spawned.emit(segment)

func create_track_segment() -> Node2D:
	var segment = Node2D.new()
	segment.name = "TrackSegment"
	
	# Visual track (placeholder - will be replaced with proper graphics)
	var track_visual = ColorRect.new()
	track_visual.size = Vector2(1080, segment_length)
	track_visual.color = Color(0.1, 0.08, 0.15, 0.3)  # Dark purple translucent
	track_visual.position = Vector2(0, 0)
	segment.add_child(track_visual)
	
	# Lane markers (light glow lines)
	for lane in [-200, 0, 200]:
		var marker = ColorRect.new()
		marker.size = Vector2(4, segment_length)
		marker.color = Color(0.5, 0.3, 0.8, 0.5)  # Purple glow
		marker.position = Vector2(540 + lane - 2, 0)
		segment.add_child(marker)
	
	return segment

func populate_segment(segment: Node2D):
	var num_obstacles = int(randf_range(1, 3) * difficulty)
	var num_coins = int(randf_range(3, 8))
	
	# Spawn obstacles
	for i in range(num_obstacles):
		spawn_obstacle_on_segment(segment)
	
	# Spawn coins
	for i in range(num_coins):
		spawn_coin_on_segment(segment)

func spawn_obstacle_on_segment(segment: Node2D):
	var obstacle = create_obstacle()
	var random_lane = randi() % 3
	var random_y = randf_range(100, segment_length - 100)
	
	obstacle.position = Vector2(LANE_POSITIONS[random_lane], random_y)
	segment.add_child(obstacle)

func spawn_coin_on_segment(segment: Node2D):
	var coin = create_coin()
	var random_lane = randi() % 3
	var random_y = randf_range(100, segment_length - 100)
	
	coin.position = Vector2(LANE_POSITIONS[random_lane], random_y)
	segment.add_child(coin)

const LANE_POSITIONS := [-200.0, 0.0, 200.0]

func create_obstacle() -> Area2D:
	var obstacle = Area2D.new()
	obstacle.name = "Obstacle"
	obstacle.add_to_group("obstacle")
	
	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	collision.shape = shape
	obstacle.add_child(collision)
	
	# Visual (purple glow box)
	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = Color(0.8, 0.2, 0.6, 0.9)  # Pink-purple
	obstacle.add_child(visual)
	
	# Randomly assign dimension layer
	if randf() > 0.5:
		obstacle.collision_layer = 1  # Light
	else:
		obstacle.collision_layer = 2  # Shadow
	
	return obstacle

func create_coin() -> Area2D:
	var coin = Area2D.new()
	coin.name = "Coin"
	coin.add_to_group("coin")
	
	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20
	collision.shape = shape
	coin.add_child(collision)
	
	# Visual (golden circle)
	var visual = ColorRect.new()
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = Color(1.0, 0.8, 0.1, 1.0)  # Gold
	coin.add_child(visual)
	
	coin.collision_layer = 3  # Collectible layer
	coin.collision_mask = 0
	
	return coin

func cleanup_old_segments():
	for segment in active_segments:
		if segment.global_position.y > player_distance + 2000:
			segment.queue_free()
			active_segments.erase(segment)
