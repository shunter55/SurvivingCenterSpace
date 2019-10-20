#extends Node
extends KinematicBody2D

const UPDATE_AFTER_FRAMES: int = 6

# The Network ID of the player allowed to controll the Object.
var controllerId: int = 0
var messageNum: int = 0

# Control Messages for the next blocks of frames. List[Dictionary] - messageNum, startPos, data: List[Dictionary]
var controlMessageQueue: Array = []
# The ControlData for the current set of frames we are on.
# List[Dictionary] - movement controls and the frame that it changed.
var controlData: Array = []
# Starting position at the 0th frame
var startPos: Vector2 = self.position
# The frame that is currently being rendered.
var currentFrame = 0

var time = Network.time()

# Object that can be controlled by a player. Handles network communication with the Server.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if canControl():
		# Get Control Input
		var control = getControlDataForFrame()
		
		if controlData.empty() or !controlDataIsEqual(control, controlData.back()):
			controlData.push_back(control)
		
		# Calculate Physics
		calculatePhysics(controlData.back())
		currentFrame += 1
		
		# Update Server
		if currentFrame >= UPDATE_AFTER_FRAMES:
			var controlMessage = addControlMessageToQueue(messageNum, startPos, controlData)
			if !get_tree().is_network_server():
				rpc_unreliable_id(1, "controlMessageRecieved", controlMessage)
			else:
				rpc_unreliable("controlMessageRecieved", controlMessage)
			messageNum += 1
			controlData = []
			currentFrame = 0
			startPos = position
	else:
		# Calculate Physics
		runNextMove(controlData)
		
		# Get next command frame buffer
		if currentFrame >= UPDATE_AFTER_FRAMES:
			loadNextControlData()
			if get_tree().is_network_server():
				rpc_unreliable("controlMessageRecieved", makeControlMessage(messageNum, position, controlData))

func loadNextControlData():
	# load next controlData
	if !controlMessageQueue.empty() and controlMessageQueue.front().messageNum >= messageNum:
		controlData = controlMessageQueue.front().controlData
		if !get_tree().is_network_server():
			position = controlMessageQueue.front().startPos
		messageNum = controlMessageQueue.front().messageNum
		currentFrame = 0
		controlMessageQueue.pop_front()

# Logic to get Input Data.
func getControlDataForFrame() -> Dictionary:
	var movement = {
		frame = currentFrame,
		left = false,
		right = false,
		up = false,
		down = false
	}
	
	# Input for next frame
	if Input.is_action_pressed("left"):
		movement.left = true
	if Input.is_action_pressed("right"):
		movement.right = true
	if Input.is_action_pressed("up"):
		movement.up = true
	if Input.is_action_pressed("down"):
		movement.down = true
	
	return movement

# Abstract - Logic to calculate physics for a frame.
func calculatePhysics(controlData: Dictionary):
	pass

# Abstract - Send control data.
#func sendControlData(messageNum: int, data: Array):
#	rpc_unreliable("controlDataRecieved", messageNum, controlData = data)

# Abstract - Recieve control data.
remote func controlMessageRecieved(controlMessage: Dictionary):
	#if get_tree().get_rpc_sender_id() == 1:
		if canControl():
			#assert(messageNum == controlMessage.messageNum + 1)
			assert(!controlMessageQueue.empty())
			# Get the controllerControlMessage that corresponds to the server's controlMessage.
			while !controlMessageQueue.empty() and controlMessageQueue.front().messageNum < controlMessage.messageNum:
				controlMessageQueue.pop_front()
	
			var controllerControlMessage = controlMessageQueue.front()
			if controllerControlMessage.startPos != controlMessage.startPos:
				position = controlMessage.startPos
				
				var controllerFrame = currentFrame
				var controllerData = controlData
				
				currentFrame = 0
				for i in range(UPDATE_AFTER_FRAMES):
					runNextMove(controlMessage.controlData)
				currentFrame = 0
				for i in range(controllerFrame):
					runNextMove(controllerData)
		else:
			controlMessageQueue.push_back(controlMessage)

# controlData - list of commands. {frame, right, left, up, down}
func runNextMove(controlData: Array):
	if controlData.size() > 1 and controlData[1].frame == currentFrame:
		controlData.pop_front()
	
	if !controlData.empty():
		calculatePhysics(controlData.front())
	else:
		print("No control data")
		calculatePhysics({left = false, right = false, up = false, down = false})
	
	currentFrame += 1

func makeControlMessage(messageNum: int, startPos: Vector2, data: Array) -> Dictionary:
	return {
		messageNum = messageNum,
		startPos = startPos,
		controlData = data
	}

func addControlMessageToQueue(messageNum: int, startPos: Vector2, data: Array) -> Dictionary:
	var controlMessage = makeControlMessage(messageNum, startPos, data)
	
	if messageNum >= self.messageNum:
		controlMessageQueue.push_back(controlMessage)
	
	return controlMessage

remote func setControllerId(id: int):
	if get_tree().get_rpc_sender_id() == 1:
		controllerId = id


func controlDataIsEqual(data1, data2) -> bool:
	return data1.left == data2.left and data1.right == data2.right and data1.up == data2.up and data1.down == data2.down

func canControl() -> bool:
	return is_network_master()