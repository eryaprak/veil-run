extends Node2D
class_name TrackManager

# Procedural track generation for endless runner
# Track scrolls DOWN, player stays relatively fixed

signal segment_spawned(segment: Node2D)

@export var segment_length := 1000.0
@export var scroll_speed := 400.0  # Base scroll speed
@export var spawn_distance := 2000.0  # Distance ahead to spawn
@export var difficulty_scaling := 0.05

var active_segments := []
var total_distance := 0.0
var difficulty := 1.0
var is_running := false

func _ready():
	pass

func _process(delta):
	if not is_running:
		return
	
	# Scroll all segments downward
	scroll_segments(delta)
	
	# Update distance and difficulty
	total_distance += scroll_speed * delta
	difficulty = 1.0 + (total_distance / 1000.0) * difficulty_scaling
	
	# Check if we need to spawn new segments
	check_spawn()
	
	# Clean up off-screen segments
	cleanup_old_segments()

func start_generation():
	is_running = true
	total_distance = 0.0
	difficulty = 1.0
	clear_all_segments()
	
	# Spawn initial segments
	for i in range(5):
		spawn_segment()

func stop_generation():
	is_running = false

func scroll_segments(delta):
	var scroll_amount = scroll_speed * delta
	for segment in active_segments:
		segment.position.y += scroll_amount

func check_spawn():
	# Spawn new segment if the last one is approaching visible area
	if active_segments.is_empty():
		spawn_segment()
		return
	
	var last_segment = active_segments.back()
	if last_segment.position.y > -spawn_distance:
		spawn_segment()

func spawn_segment():
	var segment = create_track_segment()
	
	# Position new segment above the last one
	var y_pos = 0.0
	if not active_segments.is_empty():
		var last_seg = active_segments.back()
		y_pos = last_seg.position.y - segment_length
	else:
		y_pos = -segment_length
	
	segment.position = Vector2(0, y_pos)
	add_child(segment)
	active_segments.append(segment)
	
	# Populate with obstacles and coins
	populate_segment(segment)
	
	segment_spawned.emit(segment)

func create_track_segment() -> Node2D:
	var segment = Node2D.new()
	segment.name = "TrackSegment"
	
	# Visual track background
	var track_visual = ColorRect.new()
	track_visual.size = Vector2(1080, segment_length)
	track_visual.color = Color(0.1, 0.08, 0.15, 0.3)
	track_visual.position = Vector2(0, 0)
	segment.add_child(track_visual)
	
	# Lane markers (3 lanes: left, center, right)
	var lane_x_positions = [340, 540, 740]  # Adjusted for 1080px width
	for lane_x in lane_x_positions:
		var marker = ColorRect.new()
		marker.size = Vector2(4, segment_length)
		marker.color = Color(0.5, 0.3, 0.8, 0.4)
		marker.position = Vector2(lane_x - 2, 0)
		segment.add_child(marker)
	
	return segment

func populate_segment(segment: Node2D):
	var num_obstacles = int(randf_range(2, 5) * difficulty)
	var num_coins = int(randf_range(4, 10))
	
	# Spawn obstacles
	for i in range(num_obstacles):
		spawn_obstacle_on_segment(segment)
	
	# Spawn coins in clusters
	for i in range(num_coins):
		spawn_coin_on_segment(segment)

const LANE_X_POSITIONS := [340.0, 540.0, 740.0]

func spawn_obstacle_on_segment(segment: Node2D):
	var obstacle = create_obstacle()
	var random_lane = randi() % 3
	var random_y = randf_range(100, segment_length - 100)
	
	obstacle.position = Vector2(LANE_X_POSITIONS[random_lane], random_y)
	segment.add_child(obstacle)
	
	# Connect collision
	obstacle.body_entered.connect(_on_obstacle_hit)

func spawn_coin_on_segment(segment: Node2D):
	var coin = create_coin()
	var random_lane = randi() % 3
	var random_y = randf_range(100, segment_length - 100)
	
	coin.position = Vector2(LANE_X_POSITIONS[random_lane], random_y)
	segment.add_child(coin)
	
	# Connect collection
	coin.body_entered.connect(_on_coin_collected.bind(coin))

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
	
	# Visual
	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = Color(0.9, 0.2, 0.5, 0.9)  # Pink obstacle
	obstacle.add_child(visual)
	
	# Randomly assign dimension
	if randf() > 0.5:
		obstacle.collision_layer = 1  # Light dimension
		visual.color = Color(1.0, 0.8, 0.3, 0.9)  # Golden (light)
	else:
		obstacle.collision_layer = 2  # Shadow dimension
		visual.color = Color(0.6, 0.3, 0.9, 0.9)  # Purple (shadow)
	
	obstacle.collision_mask = 1 | 2  # Can hit both dimensions
	
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
	
	# Visual
	var visual = ColorRect.new()
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = Color(1.0, 0.85, 0.1, 1.0)  # Gold
	coin.add_child(visual)
	
	coin.collision_layer = 4  # Collectible layer
	coin.collision_mask = 1 | 2  # Can be collected by both dimensions
	
	return coin

func _on_obstacle_hit(body):
	if body.is_in_group("player"):
		body.take_damage()

func _on_coin_collected(body, coin):
	if body.is_in_group("player"):
		body.coin_collected.emit()
		coin.queue_free()

func cleanup_old_segments():
	for segment in active_segments:
		# Remove segments that are far below screen
		if segment.position.y > 2500:
			segment.queue_free()
			active_segments.erase(segment)

func clear_all_segments():
	for segment in active_segments:
		segment.queue_free()
	active_segments.clear()

func get_current_speed() -> float:
	return scroll_speed
