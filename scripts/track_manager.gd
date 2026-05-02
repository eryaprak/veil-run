extends Node2D
class_name TrackManager

# Procedural track generation for endless runner
# Track scrolls DOWN, player stays relatively fixed

signal segment_spawned(segment: Node2D)

@export var segment_length := 1000.0
@export var base_scroll_speed := 400.0
@export var spawn_distance := 2000.0
@export var max_scroll_speed := 900.0

var scroll_speed := 400.0
var active_segments := []
var total_distance := 0.0
var difficulty := 1.0
var is_running := false

# Difficulty milestones (distance in meters)
const SPEED_CURVE = [
	[0, 400.0],
	[500, 460.0],
	[1000, 520.0],
	[2000, 600.0],
	[3500, 680.0],
	[5000, 760.0],
	[7500, 840.0],
	[10000, 900.0],
]

func _ready():
	pass

func _process(delta):
	if not is_running:
		return

	scroll_segments(delta)
	total_distance += scroll_speed * delta

	# Smooth difficulty/speed ramp based on distance
	update_difficulty()

	check_spawn()
	cleanup_old_segments()

func update_difficulty():
	var dist = total_distance
	# Find target speed from curve
	var target_speed = base_scroll_speed
	for i in range(SPEED_CURVE.size() - 1):
		var d0 = SPEED_CURVE[i][0]
		var d1 = SPEED_CURVE[i + 1][0]
		if dist >= d0 and dist < d1:
			var t = (dist - d0) / (d1 - d0)
			target_speed = lerp(float(SPEED_CURVE[i][1]), float(SPEED_CURVE[i + 1][1]), t)
			break
		elif dist >= SPEED_CURVE[-1][0]:
			target_speed = SPEED_CURVE[-1][1]

	scroll_speed = lerp(scroll_speed, target_speed, 0.02)
	difficulty = scroll_speed / base_scroll_speed

func start_generation():
	is_running = true
	total_distance = 0.0
	scroll_speed = base_scroll_speed
	difficulty = 1.0
	clear_all_segments()

	for i in range(5):
		spawn_segment()

func stop_generation():
	is_running = false

func scroll_segments(delta):
	var scroll_amount = scroll_speed * delta
	for segment in active_segments:
		segment.position.y += scroll_amount

func check_spawn():
	if active_segments.is_empty():
		spawn_segment()
		return

	var last_segment = active_segments.back()
	if last_segment.position.y > -spawn_distance:
		spawn_segment()

func spawn_segment():
	var segment = create_track_segment()

	var y_pos = 0.0
	if not active_segments.is_empty():
		var last_seg = active_segments.back()
		y_pos = last_seg.position.y - segment_length
	else:
		y_pos = -segment_length

	segment.position = Vector2(0, y_pos)
	add_child(segment)
	active_segments.append(segment)

	populate_segment(segment)
	segment_spawned.emit(segment)

func create_track_segment() -> Node2D:
	var segment = Node2D.new()
	segment.name = "TrackSegment"

	# Dark track background
	var track_bg = ColorRect.new()
	track_bg.size = Vector2(1080, segment_length)
	track_bg.color = Color(0.06, 0.04, 0.12, 1.0)
	track_bg.position = Vector2(0, 0)
	segment.add_child(track_bg)

	# Subtle grid lines for depth
	for row in range(int(segment_length / 100)):
		var line = ColorRect.new()
		line.size = Vector2(1080, 1)
		line.color = Color(0.3, 0.2, 0.5, 0.15)
		line.position = Vector2(0, row * 100)
		segment.add_child(line)

	# Lane dividers with glow effect
	var lane_dividers = [440, 640]  # Between lanes
	for lane_x in lane_dividers:
		var marker = ColorRect.new()
		marker.size = Vector2(2, segment_length)
		marker.color = Color(0.5, 0.2, 0.9, 0.5)
		marker.position = Vector2(lane_x, 0)
		segment.add_child(marker)
		# Soft glow around divider
		var glow_l = ColorRect.new()
		glow_l.size = Vector2(8, segment_length)
		glow_l.color = Color(0.5, 0.2, 0.9, 0.08)
		glow_l.position = Vector2(lane_x - 8, 0)
		segment.add_child(glow_l)
		var glow_r = ColorRect.new()
		glow_r.size = Vector2(8, segment_length)
		glow_r.color = Color(0.5, 0.2, 0.9, 0.08)
		glow_r.position = Vector2(lane_x + 2, 0)
		segment.add_child(glow_r)

	# Edge neon lines
	for edge_x in [20, 1058]:
		var edge = ColorRect.new()
		edge.size = Vector2(3, segment_length)
		edge.color = Color(0.4, 0.1, 0.8, 0.7)
		edge.position = Vector2(edge_x, 0)
		segment.add_child(edge)

	return segment

func populate_segment(segment: Node2D):
	# Difficulty-scaled obstacle count, capped
	var min_obs = min(2, 1 + int(difficulty * 0.5))
	var max_obs = min(6, 2 + int(difficulty * 1.5))
	var num_obstacles = randi_range(min_obs, max_obs)
	var num_coins = randi_range(4, 10)

	# Ensure at least one clear lane per obstacle row
	var used_lanes_by_y := {}
	for i in range(num_obstacles):
		spawn_obstacle_on_segment(segment, used_lanes_by_y)

	for i in range(num_coins):
		spawn_coin_on_segment(segment)

const LANE_X_POSITIONS := [340.0, 540.0, 740.0]

func spawn_obstacle_on_segment(segment: Node2D, used_lanes: Dictionary):
	var obstacle = create_obstacle()
	var random_y = randf_range(150, segment_length - 150)
	# Quantize Y to rows to avoid impossible clustered obstacles
	var row_key = int(random_y / 200)
	if not used_lanes.has(row_key):
		used_lanes[row_key] = []
	var available = [0, 1, 2]
	for l in used_lanes[row_key]:
		available.erase(l)
	if available.is_empty():
		return  # Skip to avoid blocking all lanes
	var chosen_lane = available[randi() % available.size()]
	used_lanes[row_key].append(chosen_lane)
	obstacle.position = Vector2(LANE_X_POSITIONS[chosen_lane], random_y)
	segment.add_child(obstacle)
	obstacle.body_entered.connect(_on_obstacle_hit)

func spawn_coin_on_segment(segment: Node2D):
	var coin = create_coin()
	var random_lane = randi() % 3
	var random_y = randf_range(100, segment_length - 100)
	coin.position = Vector2(LANE_X_POSITIONS[random_lane], random_y)
	segment.add_child(coin)
	coin.body_entered.connect(_on_coin_collected.bind(coin))

func create_obstacle() -> Area2D:
	var obstacle = Area2D.new()
	obstacle.name = "Obstacle"
	obstacle.add_to_group("obstacle")

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(70, 70)
	collision.shape = shape
	obstacle.add_child(collision)

	var is_light = randf() > 0.5
	var base_color: Color
	if is_light:
		obstacle.collision_layer = 1
		base_color = Color(1.0, 0.75, 0.2, 1.0)
	else:
		obstacle.collision_layer = 2
		base_color = Color(0.55, 0.15, 0.95, 1.0)
	obstacle.collision_mask = 1 | 2

	# Obstacle body with glow layers
	var glow = ColorRect.new()
	glow.size = Vector2(90, 90)
	glow.position = Vector2(-45, -45)
	glow.color = Color(base_color.r, base_color.g, base_color.b, 0.25)
	obstacle.add_child(glow)

	var core = ColorRect.new()
	core.size = Vector2(70, 70)
	core.position = Vector2(-35, -35)
	core.color = base_color
	obstacle.add_child(core)

	var inner = ColorRect.new()
	inner.size = Vector2(40, 40)
	inner.position = Vector2(-20, -20)
	inner.color = Color(
		min(base_color.r + 0.3, 1.0),
		min(base_color.g + 0.3, 1.0),
		min(base_color.b + 0.3, 1.0), 0.9)
	obstacle.add_child(inner)

	return obstacle

func create_coin() -> Area2D:
	var coin = Area2D.new()
	coin.name = "Coin"
	coin.add_to_group("coin")

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 22
	collision.shape = shape
	coin.add_child(collision)

	# Coin visual with glow ring
	var outer_glow = ColorRect.new()
	outer_glow.size = Vector2(54, 54)
	outer_glow.position = Vector2(-27, -27)
	outer_glow.color = Color(1.0, 0.85, 0.1, 0.2)
	coin.add_child(outer_glow)

	var body = ColorRect.new()
	body.size = Vector2(38, 38)
	body.position = Vector2(-19, -19)
	body.color = Color(1.0, 0.85, 0.1, 1.0)
	coin.add_child(body)

	var shine = ColorRect.new()
	shine.size = Vector2(14, 14)
	shine.position = Vector2(-16, -16)
	shine.color = Color(1.0, 1.0, 0.85, 0.9)
	coin.add_child(shine)

	coin.collision_layer = 4
	coin.collision_mask = 1 | 2

	return coin

func _on_obstacle_hit(body):
	if body.is_in_group("player"):
		body.take_damage()

func _on_coin_collected(body, coin):
	if body.is_in_group("player"):
		body.collect_coin_visual()
		body.coin_collected.emit()
		coin.queue_free()

func cleanup_old_segments():
	var to_remove = []
	for segment in active_segments:
		if segment.position.y > 2500:
			segment.queue_free()
			to_remove.append(segment)
	for s in to_remove:
		active_segments.erase(s)

func clear_all_segments():
	for segment in active_segments:
		segment.queue_free()
	active_segments.clear()

func get_current_speed() -> float:
	return scroll_speed
