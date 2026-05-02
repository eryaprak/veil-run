extends CharacterBody2D
class_name Player

# Veil Run Player Controller
# Core mechanic: Veil Shift (dimension switching)

signal died
signal coin_collected
signal veil_shifted(dimension: String)

enum Dimension { LIGHT, SHADOW }

@export var base_speed := 400.0
@export var max_speed := 800.0
@export var acceleration := 50.0
@export var lane_switch_speed := 800.0
@export var jump_velocity := -600.0
@export var gravity := 1800.0

var current_speed := base_speed
var current_dimension := Dimension.LIGHT
var current_lane := 1  # 0=left, 1=center, 2=right
var is_alive := true
var is_invincible := false
var veil_shift_cooldown := 0.0
var veil_shift_cooldown_time := 0.8

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var veil_particles = $VeilParticles

const LANE_POSITIONS := [-200.0, 0.0, 200.0]

func _ready():
	position = Vector2(540, 1500)  # Start position
	reset()

func _physics_process(delta):
	if not is_alive:
		return
	
	# Update veil shift cooldown
	if veil_shift_cooldown > 0:
		veil_shift_cooldown -= delta
	
	# Auto-forward movement
	velocity.y = 0  # 2.5D: we move "into screen" via scene scroll
	
	# Lane switching (left/right input)
	handle_lane_input(delta)
	
	# Jumping
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		jump()
	
	# Apply gravity if jumping
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Veil Shift input (swipe up or space when available)
	if Input.is_action_just_pressed("veil_shift") and veil_shift_cooldown <= 0:
		shift_dimension()
	
	# Speed acceleration
	current_speed = min(current_speed + acceleration * delta, max_speed)
	
	move_and_slide()
	
	# Update visual state
	update_visual_state()

func handle_lane_input(delta):
	var target_lane := current_lane
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		target_lane = max(0, current_lane - 1)
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		target_lane = min(2, current_lane + 1)
	
	if target_lane != current_lane:
		current_lane = target_lane
	
	# Smooth lane transition
	var target_x = LANE_POSITIONS[current_lane] + 540  # offset by screen center
	position.x = lerp(position.x, target_x, lane_switch_speed * delta / 100.0)

func jump():
	if is_on_floor():
		velocity.y = jump_velocity

func shift_dimension():
	if current_dimension == Dimension.LIGHT:
		current_dimension = Dimension.SHADOW
	else:
		current_dimension = Dimension.LIGHT
	
	veil_shift_cooldown = veil_shift_cooldown_time
	veil_shifted.emit("shadow" if current_dimension == Dimension.SHADOW else "light")
	
	# Visual effect
	play_veil_shift_effect()
	
	# Change collision layer
	update_collision_layer()

func play_veil_shift_effect():
	veil_particles.emitting = true
	# TODO: Add glow flash animation

func update_collision_layer():
	# Light dimension: layer 1, Shadow dimension: layer 2
	if current_dimension == Dimension.LIGHT:
		collision_layer = 1
		collision_mask = 1
	else:
		collision_layer = 2
		collision_mask = 2

func update_visual_state():
	# Update sprite based on dimension
	if current_dimension == Dimension.LIGHT:
		sprite.modulate = Color(1.0, 0.9, 0.7, 1.0)  # golden tint
	else:
		sprite.modulate = Color(0.6, 0.3, 0.8, 1.0)  # purple tint

func take_damage():
	if is_invincible or not is_alive:
		return
	
	die()

func die():
	is_alive = false
	died.emit()
	# TODO: Death animation

func revive():
	is_alive = true
	is_invincible = true
	await get_tree().create_timer(2.0).timeout
	is_invincible = false

func reset():
	is_alive = true
	is_invincible = false
	current_speed = base_speed
	current_dimension = Dimension.LIGHT
	current_lane = 1
	position = Vector2(540, 1500)
	velocity = Vector2.ZERO
	update_collision_layer()

func _on_hitbox_body_entered(body):
	if body.is_in_group("obstacle"):
		take_damage()
	elif body.is_in_group("coin"):
		coin_collected.emit()
		body.queue_free()
