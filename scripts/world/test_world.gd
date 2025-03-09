class_name TestWorld
extends Node2D

@export var brick_scene: PackedScene = preload("res://scenes/brick/brick.tscn")

@onready var ball: Ball = $Ball
@onready var paddle: Paddle = $Paddle
@onready var camera_2d: Camera2D = $Camera2D
@onready var pattern: ColorRect = $Map/Pattern
@onready var spawn_pos_container: Node = $SpawnPos
@onready var brick_container: Node = $Bricks
@onready var websocket_ui: CanvasLayer = $WebsocketUI
@onready var timer: Timer = $Timer
@onready var combo_lbl: Label = $Combo
@onready var combo_timer: Timer = $ComboTimer
@onready var score_ui: Score = $UI/Score

var bricks: Array
var bricks_to_destroy: Array
## 连击
var combo: int = 0
var combo_tween: Tween
## 分数
var score: int = 0 # 当前总得分
var score_brick_destroyed: int = 200 # 摧毁方块得分
var score_brick_touched: int = 50 # 触碰方块得分

func _ready() -> void:
	randomize()
	hide_combo()
	combo_lbl.scale = Vector2.ZERO
	reset_score()
	
	Globals.camera = camera_2d
	Globals.camera.objects = [ball]
	Globals.pattern = pattern
	
	ball.attached_to = paddle.launch_point
	paddle.ball_attached = ball
	paddle.ball = ball
	
	# Remove for testing with predefined bricks
	remove_all_bricks()
	layout_bricks()
	
	ball.hit_block.connect(on_ball_hit_block)
	timer.timeout.connect(on_timer_timeout)
	combo_timer.timeout.connect(on_combo_timer_timeout)


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
	instance.destroyed.connect(on_brick_destroyed)
	instance.global_position = pos
	bricks.append(instance)
	if instance.type != instance.TYPE.EXPLOSIVE and instance.type != instance.TYPE.ENERGY:
		bricks_to_destroy.append(instance)


func hide_combo() -> void:
	if combo_tween and combo_tween.is_running():
		combo_tween.kill()
	combo_tween = create_tween()
	combo_tween.tween_property(combo_lbl, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func show_combo(combo: int) -> void:
	combo_timer.start()
	combo_lbl.text = "COMBO " + str(combo)
	combo_lbl.material.set_shader_parameter("fill_v", 0.0)
	if combo_tween and combo_tween.is_running():
		combo_tween.kill()
	combo_tween = create_tween()
	combo_tween.tween_property(combo_lbl, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	combo_tween.tween_property(combo_lbl.material, "shader_parameter/fill_v", 0.28, combo_timer.wait_time).set_trans(Tween.TRANS_LINEAR)


# 重置分数
func reset_score() -> void:
	score = 0
	score_ui.set_score(score)


func on_timer_timeout() -> void:
	websocket_ui.visible = false


func on_combo_timer_timeout():
	combo = 0
	hide_combo()


func on_ball_hit_block(block) -> void:
	if block._destroyed: return
	combo += 1
	show_combo(combo)
	combo_timer.start()
	score += score_brick_touched * combo
	Globals.stats["score"] = score
	score_ui.set_score(score)


func on_brick_destroyed(which) -> void:
	bricks.erase(which)
	bricks_to_destroy.erase(which)
	
	combo += 1
	show_combo(combo)
	score += score_brick_destroyed * combo
	Globals.stats["score"] = score
	score_ui.set_score(score)
	
	#if bricks_to_destroy.is_empty():
		#started = false
		#paddle.stage_clear = true
		#Globals.stats["time"] = time
		#reset_and_attach_ball()
		#show_stage_clear()
