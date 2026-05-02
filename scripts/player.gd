extends CharacterBody2D
class_name Player

# Veil Run Player Controller
# Player stays relatively fixed, world scrolls

signal died
signal coin_collected
signal veil_shifted(dimension: String)

enum Dimension { LIGHT, SHADOW }

@export var lane_switch_speed := 12.0  # Smooth lerp speed
@export var jump_velocity := -600.0
@export var gravity := 1800.0

var current_dimension := Dimension.LIGHT
var current_lane := 1  # 0=left, 1=center, 2=right
var target_lane := 1
var is_alive := true
var is_invincible := false
var veil_shift_cooldown := 0.0
var veil_shift_cooldown_time := 0.8

# Touch/swipe state
var touch_start_pos := Vector2.ZERO
var touch_start_time := 0.0
const SWIPE_THRESHOLD := 60.0
const SWIPE_TIME_LIMIT := 0.5

# Visual state
var idle_bob_time := 0.0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var veil_particles = $VeilParticles
@onready var coin_particles = $CoinParticles
@onready var trail_particles = $TrailParticles

const LANE_X_POSITIONS := [340.0, 540.0, 740.0]

# Costume color definitions
const COSTUME_COLORS = {
	"default": {"light": Color(1.0, 0.9, 0.7, 1.0), "shadow": Color(0.6, 0.3, 0.8, 1.0)},
	"shadow": {"light": Color(0.3, 0.8, 1.0, 1.0), "shadow": Color(0.1, 0.1, 0.4, 1.0)},
	"light": {"light": Color(1.0, 1.0, 0.8, 1.0), "shadow": Color(1.0, 0.7, 0.2, 1.0)},
	"mystic": {"light": Color(0.8, 1.0, 0.5, 1.0), "shadow": Color(0.5, 0.0, 0.8, 1.0)}
}

func _ready():
	position = Vector2(LANE_X_POSITIONS[1], 1400)
	reset()
	_setup_particles()

func _setup_particles():
	# Setup veil shift particles
	var veil_mat = ParticleProcessMaterial.new()
	veil_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	veil_mat.emission_sphere_radius = 30.0
	veil_mat.direction = Vector3(0, -1, 0)
	veil_mat.spread = 180.0
	veil_mat.initial_velocity_min = 100.0
	veil_mat.initial_velocity_max = 250.0
	veil_mat.gravity = Vector3.ZERO
	veil_mat.scale_min = 2.0
	veil_mat.scale_max = 5.0
	veil_mat.color = Color(0.8, 0.3, 1.0, 1.0)
	veil_mat.color_ramp = _make_fade_gradient(Color(0.8, 0.3, 1.0, 1.0))
	veil_particles.process_material = veil_mat
	veil_particles.amount = 24

	# Setup coin spark particles
	var coin_mat = ParticleProcessMaterial.new()
	coin_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	coin_mat.emission_sphere_radius = 20.0
	coin_mat.direction = Vector3(0, -1, 0)
	coin_mat.spread = 180.0
	coin_mat.initial_velocity_min = 80.0
	coin_mat.initial_velocity_max = 180.0
	coin_mat.gravity = Vector3(0, 200, 0)
	coin_mat.scale_min = 2.0
	coin_mat.scale_max = 4.0
	coin_mat.color = Color(1.0, 0.85, 0.1, 1.0)
	coin_mat.color_ramp = _make_fade_gradient(Color(1.0, 0.85, 0.1, 1.0))
	coin_particles.process_material = coin_mat
	coin_particles.amount = 12

	# Setup trail particles
	var trail_mat = ParticleProcessMaterial.new()
	trail_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	trail_mat.emission_box_extents = Vector3(15, 5, 0)
	trail_mat.direction = Vector3(0, 1, 0)
	trail_mat.spread = 30.0
	trail_mat.initial_velocity_min = 20.0
	trail_mat.initial_velocity_max = 80.0
	trail_mat.gravity = Vector3.ZERO
	trail_mat.scale_min = 1.0
	trail_mat.scale_max = 3.0
	trail_mat.color = Color(0.6, 0.2, 1.0, 0.6)
	trail_mat.color_ramp = _make_fade_gradient(Color(0.6, 0.2, 1.0, 0.4))
	trail_particles.process_material = trail_mat
	trail_particles.amount = 20
	trail_particles.emitting = true

func _make_fade_gradient(base_color: Color) -> Gradient:
	var g = Gradient.new()
	g.set_color(0, base_color)
	g.set_color(1, Color(base_color.r, base_color.g, base_color.b, 0.0))
	return g

func _physics_process(delta):
	if not is_alive:
		return

	# Update veil shift cooldown
	if veil_shift_cooldown > 0:
		veil_shift_cooldown -= delta

	# Lane switching
	handle_lane_input(delta)

	# Veil Shift input
	if Input.is_action_just_pressed("veil_shift") and veil_shift_cooldown <= 0:
		shift_dimension()

	# Keep player vertically fixed
	velocity.y = 0
	move_and_slide()

	# Idle bob animation
	idle_bob_time += delta
	sprite.position.y = sin(idle_bob_time * 3.0) * 4.0

	update_visual_state()

func _input(event):
	if not is_alive:
		return
	# Touch swipe input
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			touch_start_time = Time.get_ticks_msec() / 1000.0
		else:
			var elapsed = (Time.get_ticks_msec() / 1000.0) - touch_start_time
			if elapsed < SWIPE_TIME_LIMIT:
				var delta_pos = event.position - touch_start_pos
				if abs(delta_pos.x) > SWIPE_THRESHOLD and abs(delta_pos.x) > abs(delta_pos.y):
					# Horizontal swipe - lane change
					if delta_pos.x > 0:
						target_lane = min(2, current_lane + 1)
					else:
						target_lane = max(0, current_lane - 1)
					if target_lane != current_lane:
						current_lane = target_lane
				elif abs(delta_pos.y) < -SWIPE_THRESHOLD and abs(delta_pos.y) > abs(delta_pos.x):
					# Swipe up - veil shift
					if veil_shift_cooldown <= 0:
						shift_dimension()

func handle_lane_input(delta):
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		current_lane = max(0, current_lane - 1)
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		current_lane = min(2, current_lane + 1)

	# Smooth lane transition
	var target_x = LANE_X_POSITIONS[current_lane]
	position.x = lerp(position.x, target_x, lane_switch_speed * delta)

func shift_dimension():
	if current_dimension == Dimension.LIGHT:
		current_dimension = Dimension.SHADOW
	else:
		current_dimension = Dimension.LIGHT

	veil_shift_cooldown = veil_shift_cooldown_time
	veil_shifted.emit("shadow" if current_dimension == Dimension.SHADOW else "light")

	play_veil_shift_effect()
	update_collision_layer()

func play_veil_shift_effect():
	veil_particles.emitting = true
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.2, 0.08)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.08)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)

func play_coin_effect():
	coin_particles.restart()
	coin_particles.emitting = true
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.06)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func play_death_effect():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.1)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.0, 0.0), 0.4)

func update_collision_layer():
	if current_dimension == Dimension.LIGHT:
		collision_layer = 1
		collision_mask = 1 | 4
	else:
		collision_layer = 2
		collision_mask = 2 | 4

func update_visual_state():
	var costume = GameData.selected_costume if GameData else "default"
	var colors = COSTUME_COLORS.get(costume, COSTUME_COLORS["default"])
	if current_dimension == Dimension.LIGHT:
		sprite.modulate = Color(colors["light"].r, colors["light"].g, colors["light"].b, sprite.modulate.a)
		trail_particles.process_material.color = Color(colors["light"].r, colors["light"].g, colors["light"].b * 0.5, 0.5)
	else:
		sprite.modulate = Color(colors["shadow"].r, colors["shadow"].g, colors["shadow"].b, sprite.modulate.a)
		trail_particles.process_material.color = Color(colors["shadow"].r, colors["shadow"].g * 0.5, colors["shadow"].b, 0.5)

func collect_coin_visual():
	play_coin_effect()

func take_damage():
	if is_invincible or not is_alive:
		return
	die()

func die():
	is_alive = false
	trail_particles.emitting = false
	died.emit()
	play_death_effect()

func revive():
	is_alive = true
	is_invincible = true
	sprite.modulate.a = 1.0
	sprite.scale = Vector2(1.0, 1.0)
	trail_particles.emitting = true
	# Invincibility flash
	var tween = create_tween()
	tween.set_loops(6)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.15)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(2.0).timeout
	is_invincible = false

func reset():
	is_alive = true
	is_invincible = false
	current_dimension = Dimension.LIGHT
	current_lane = 1
	target_lane = 1
	position = Vector2(LANE_X_POSITIONS[1], 1400)
	velocity = Vector2.ZERO
	sprite.modulate.a = 1.0
	sprite.scale = Vector2(1.0, 1.0)
	idle_bob_time = 0.0
	if trail_particles:
		trail_particles.emitting = true
	update_collision_layer()
	update_visual_state()
