class_name WebsocketClient
extends Node

@export var test_edit: TextEdit
@export var button: Button
@export var label: Label
## The URL we will connect to.
@export var websocket_url: StringName = "ws://54.178.221.15:8080"
#@export var websocket_url: StringName = "ws://localhost:8080"

var position: int = 0 #1左电机，2右电机
var status: int = 0 # 电机状态，0休眠状态，1暂停状态，2启动状态
var power: int = 2 # 电机反馈的力量值，单位kg
var mode: int = 1 # 电机当前的模式，1 基础力模式，2 标准模式，3 等速模式，4 弹力模式，5 离心模式
var distance: float = 0.0 # 电机拉绳的位置信息，单位mm
var speed: float = 0.0 # 速度数据反馈，单位mm/s，左电机拉绳是正值，回绳是负值；右电机拉绳是负值，回绳是正值
var efficiency: float = 0.0 # 功率数据反馈，单位W，
var calorie: float = 0.0 # 卡路里，单位kcal

var socket: WebSocketPeer = WebSocketPeer.new()

func log_message(message: String) -> void:
	var time := Time.get_time_string_from_system()
	label.text = time + " " + message + "\n"


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	
	if socket.connect_to_url(websocket_url) != OK:
		log_message("Unable to connect.")
		set_process(false)


func _process(_delta: float) -> void:
	socket.poll()

	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var game_data: String = socket.get_packet().get_string_from_ascii()
			log_message(game_data)
			var game_data_parse = JSON.parse_string(game_data)
			if game_data_parse.get("type") == "ROOM_MESSAGE":
				var motor_data = game_data_parse.get("data").get("data").get("motor_data")
				if (motor_data):
					status = motor_data.get("status")
					mode = motor_data.get("mode")
					## TODO 电机暂停、休眠、基础力处理逻辑
					if status == 0 || status == 1 || mode == 1:
						position = 0
						efficiency = 0
						return
					position = motor_data.get("position")
					efficiency = motor_data.get("efficiency")
					speed = motor_data.get("speed")
					## TODO 对于回绳处理逻辑
					# 左电机回绳
					if position == 1 && sign(speed) < 0:
						position = 0
						efficiency = 0
						return
					# 右电机回绳
					if position == 2 && sign(speed) > 0:
						position = 0
						efficiency = 0
						return
					## TODO 对于速度过小或者功率过小处理逻辑
					if abs(speed) < 50 || efficiency < 10:
						position = 0
						efficiency = 0
						return
					power = motor_data.get("power")
					distance = motor_data.get("distance")
					speed = motor_data.get("speed")
					calorie = motor_data.get("calorie")


func _exit_tree() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close()

### 创建房间 {"type": "CREATE_ROOM"}
### 加入房间 {"type": "JOIN_ROOM","data": {"roomId": "6c7a3805-8597-496f-aefc-04a1c3da3681"}}
func _on_button_pressed() -> void:
	var cmd: String = test_edit.text
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if cmd != "":
			socket.send_text(cmd)
		else:
			socket.send_text('''{"type": "CREATE_ROOM"}''')
