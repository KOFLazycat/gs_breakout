class_name WebsocketClient
extends Node

@export var test_edit: TextEdit
@export var button: Button
@export var label: Label
## The URL we will connect to.
@export var websocket_url: StringName = "ws://54.178.221.15:8080"
#@export var websocket_url: StringName = "ws://localhost:8080"

enum POS_TYPE {NONE, LEFT, RIGHT}
var position: int = POS_TYPE.NONE #指令来源，1左电机，2右电机
var current_position: int = POS_TYPE.NONE #当前应该使用哪个来源的数据，1左电机，2右电机
var current_efficiency: float = 0.0 #当前功率数据反馈，单位W
# 左电机数据
var left_motor_data: Dictionary = {
	"status": 0, # 电机状态，0休眠状态，1暂停状态，2启动状态
	"power": 0, # 电机反馈的力量值，单位kg
	"mode": 0, # 电机当前的模式，1 基础力模式，2 标准模式，3 等速模式，4 弹力模式，5 离心模式
	"distance": 0, # 电机拉绳的位置信息，单位mm
	"speed": 0, # 速度数据反馈，单位mm/s，左电机拉绳是正值，回绳是负值；右电机拉绳是负值，回绳是正值
	"efficiency": 0, # 功率数据反馈，单位W，
	"calorie": 0,  # 卡路里，单位kcal
	"spring_back": 1, # 是否是回绳，0否，1是
}

# 右电机数据
var right_motor_data: Dictionary = {
	"status": 0, # 电机状态，0休眠状态，1暂停状态，2启动状态
	"power": 0, # 电机反馈的力量值，单位kg
	"mode": 0, # 电机当前的模式，1 基础力模式，2 标准模式，3 等速模式，4 弹力模式，5 离心模式
	"distance": 0, # 电机拉绳的位置信息，单位mm
	"speed": 0, # 速度数据反馈，单位mm/s，左电机拉绳是正值，回绳是负值；右电机拉绳是负值，回绳是正值
	"efficiency": 0, # 功率数据反馈，单位W，
	"calorie": 0,  # 卡路里，单位kcal
	"spring_back": 1, # 是否是回绳，0否，1是
}

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
					position = motor_data.get("position")
					if position == POS_TYPE.LEFT:
						left_motor_data["status"] = motor_data.get("status")
						left_motor_data["mode"] = motor_data.get("mode")
						left_motor_data["power"] = motor_data.get("power")
						left_motor_data["distance"] = motor_data.get("distance")
						left_motor_data["speed"] = motor_data.get("speed")
						left_motor_data["efficiency"] = motor_data.get("efficiency")
						left_motor_data["calorie"] = motor_data.get("calorie")
						# 左电机回绳
						if abs(left_motor_data["speed"]) > 20:
							left_motor_data["spring_back"] = 0
						else:
							left_motor_data["spring_back"] = 1
					
					if position == POS_TYPE.RIGHT:
						right_motor_data["status"] = motor_data.get("status")
						right_motor_data["mode"] = motor_data.get("mode")
						right_motor_data["power"] = motor_data.get("power")
						right_motor_data["distance"] = motor_data.get("distance")
						right_motor_data["speed"] = motor_data.get("speed")
						right_motor_data["efficiency"] = motor_data.get("efficiency")
						right_motor_data["calorie"] = motor_data.get("calorie")
						# 右电机回绳
						if abs(right_motor_data["speed"]) > 20:
							right_motor_data["spring_back"] = 0
						else:
							right_motor_data["spring_back"] = 1
					
					deal_current_data()


func deal_current_data() -> void:
	if left_motor_data["spring_back"] == 1 && right_motor_data["spring_back"] == 1:
		current_position = POS_TYPE.NONE
		current_efficiency = 0
		return
	
	# 仅左电机拉绳，右电机未拉绳
	if left_motor_data["spring_back"] == 0 && right_motor_data["spring_back"] != 0:
		current_position = POS_TYPE.LEFT
		current_efficiency = left_motor_data["efficiency"]
	# 仅右电机拉绳，左电机未拉绳
	if right_motor_data["spring_back"] == 0 && left_motor_data["spring_back"] != 0:
		current_position = POS_TYPE.RIGHT
		current_efficiency = right_motor_data["efficiency"]
	# 左右电机同时拉绳
	if left_motor_data["spring_back"] == 0 && right_motor_data["spring_back"] == 0:
		if left_motor_data["efficiency"] > right_motor_data["efficiency"]:
			current_position = POS_TYPE.LEFT
		else:
			current_position = POS_TYPE.RIGHT
		current_efficiency = abs(left_motor_data["efficiency"] - right_motor_data["efficiency"])


func _exit_tree() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.close()

### 创建房间 {"type": "CREATE_ROOM"}
### 加入房间 {"type": "JOIN_ROOM","data": {"roomId": "e318c888-c5bc-4804-8357-8fbc6c5a93ff"}}
func _on_button_pressed() -> void:
	var cmd: String = test_edit.text
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		if cmd != "":
			socket.send_text(cmd)
		else:
			socket.send_text('''{"type": "CREATE_ROOM"}''')
