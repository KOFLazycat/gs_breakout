class_name TestWorld
extends Node2D

@onready var ball: Ball = $Ball
@onready var paddle: Paddle = $Paddle
@onready var camera_2d: Camera2D = $Camera2D
@onready var pattern: ColorRect = $Map/Pattern


func _ready() -> void:
	randomize()
	
	Globals.camera = camera_2d
	Globals.camera.objects = [ball]
	Globals.pattern = pattern
	
	ball.attached_to = paddle.launch_point
	paddle.ball_attached = ball
	paddle.ball = ball
