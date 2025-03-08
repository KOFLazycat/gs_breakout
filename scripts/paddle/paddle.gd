class_name Paddle
extends CharacterBody2D

signal start

@export var websocket_client: WebsocketClient
@export var speed: float = 600.0
@export var accel: float = 5.0
@export var deccel: float = 10.0
@export_category("Oscillator")
@export var spring: float = 400.0
@export var damp: float = 20.0
@export var velocity_multiplier: float = 1.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var thickness: float = $CollisionShape2D.shape.extents.y
@onready var paddle: Sprite2D = $Paddle
@onready var launch_point: Marker2D = $LaunchPoint

var ball_attached = null
var game_over: bool = false
var stage_clear: bool = false
var ball = null
var frames_since_bump: int = 0
var last_efficiency: float = 0.0

## Oscillator
var displacement: float = 0.0
var oscillator_velocity: float = 0.0

## HitStop
var hitstop_frames: int = 0


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if game_over or stage_clear: return
	var dir: float = 0
	if websocket_client.current_position == websocket_client.POS_TYPE.NONE:
		dir = Input.get_action_strength("right") - Input.get_action_strength("left")
	else:
		if websocket_client.current_position == websocket_client.POS_TYPE.LEFT:
			dir = -1
		elif websocket_client.current_position == websocket_client.POS_TYPE.RIGHT:
			dir = 1
		else:
			dir = 0
	
	# 平滑移动
	if dir != 0:
		if ball_attached: 
			launch_ball()
		last_efficiency = websocket_client.current_efficiency
		velocity.x = lerp(velocity.x, dir * speed, accel * last_efficiency * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, deccel * delta)
	## 限制速度范围
	velocity.x = clampf(velocity.x, -500, 500);
	print("速度: " + str(velocity.x))
	
	## Oscillator
	oscillator_velocity += (velocity.x / speed) * velocity_multiplier
	var force = -spring * displacement + damp * oscillator_velocity
	oscillator_velocity -= force * delta
	displacement -= oscillator_velocity * delta
	
	paddle.rotation = -displacement


func _physics_process(delta: float) -> void:
	if game_over or stage_clear: return
	
	# HitStop
	if hitstop_frames > 0:
		hitstop_frames -= 1
		if hitstop_frames <= 0:
			stop_hitstop()
		return
	
	frames_since_bump += 1
	
	var collision = move_and_collide(velocity * delta)
	
	if not collision: return
	if collision.get_collider().is_in_group("Ball"):
		pass


func ball_bounce() -> void:
	anim.stop()
	anim.play("bounce")


func start_hitstop(hitstop_amount: int) -> void:
	anim.pause()
	hitstop_frames = hitstop_amount


func stop_hitstop() -> void:
	anim.play()
	hitstop_frames = 0


func launch_ball() -> void:
	emit_signal("start")
	ball_attached.launch()
	ball_attached = null
