class_name TestWorld
extends Node2D

@export var brick_scene: PackedScene = preload("res://scenes/brick/brick.tscn")

@onready var ball: Ball = $Ball
@onready var paddle: Paddle = $Paddle
@onready var camera_2d: Camera2D = $Camera2D
@onready var pattern: ColorRect = $Map/Pattern
@onready var spawn_pos_container: Node = $SpawnPos
@onready var brick_container: Node = $Bricks
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var timer: Timer = $Timer

var bricks: Array
var bricks_to_destroy: Array


func _ready() -> void:
	randomize()
	
	Globals.camera = camera_2d
	Globals.camera.objects = [ball]
	Globals.pattern = pattern
	
	ball.attached_to = paddle.launch_point
	paddle.ball_attached = ball
	paddle.ball = ball
	
	# Remove for testing with predefined bricks
	remove_all_bricks()
	layout_bricks()
	
	timer.timeout.connect(on_timer_timeout)


func remove_all_bricks() -> void:
	bricks.clear()
	bricks_to_destroy.clear()
	for brick in brick_container.get_children():
		brick.queue_free()


func layout_bricks() -> void:
	var bricks_tween: Tween = create_tween()
	var max_bricks: int = spawn_pos_container.get_child_count()
	for i in range(max_bricks):
		# 90% chance of having a block
		if randf() < 0.1: continue
		bricks_tween.tween_callback(add_brick.bind(brick_container, spawn_pos_container.get_child(i).global_position))
		bricks_tween.tween_interval(randf_range(0.05, 0.15))


func add_brick(parent: Node, pos: Vector2) -> void:
	var instance = brick_scene.instantiate()
	parent.add_child(instance)
	#instance.energy_brick_destroyed.connect(on_energy_brick_destroyed)
	#instance.destroyed.connect(on_brick_destroyed)
	instance.global_position = pos
	bricks.append(instance)
	if instance.type != instance.TYPE.EXPLOSIVE and instance.type != instance.TYPE.ENERGY:
		bricks_to_destroy.append(instance)


func on_timer_timeout() -> void:
	canvas_layer.visible = false
