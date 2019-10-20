extends KinematicBody2D

# Declare member variables here. Examples:
const UP = Vector2(0, -1)
const GRAVITY = 20 #Vector2(0, 20)
const SPEED = 200
const JUMP_HEIGHT = 270

var isOnLadder = false

var id
var teamId

var sendMovement = 0

var velocity = Vector2()

var movement = {
	left = false,
	right = false,
	up = false,
	down = false
}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	### MOVEMENT ###
	#velocity.x = lerp(velocity.x, 0, .4)
	velocity.x = 0
	# Apply Gravity
	if !is_on_floor() and !isOnLadder:
		velocity.y += GRAVITY
	# Move
	if movement.left:
		velocity.x = -SPEED
	if movement.right:
		velocity.x = SPEED
	if isOnLadder:
		if movement.up:
			velocity.y = -SPEED
		elif movement.down:
			velocity.y = SPEED
		else:
			velocity.y = 0
	# Jump
	if movement.up and is_on_floor():
		velocity.y = -JUMP_HEIGHT
	# Move and Slide
	velocity = move_and_slide(velocity, UP)
	
	
	sendMovement = (sendMovement + 1) % 10
	### CONTROL ###
	if (is_network_master()):
		var lastMovement = movement
		movement = {
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
		
		if (!equals(movement, lastMovement)):
			if get_tree().is_network_server():
				notifyOfMovement(movement, Network.time())
			else:
				rpc_unreliable_id(1, "notifyOfMovement", movement, Network.time())


remote func notifyOfMovement(movement, timeSent):
	self.movement = movement
	#if get_tree().is_network_server():
		#for playerId in Network.world.teams[teamId]:
		#	rpc_id(playerId, "notifyOfMovement", movement, timeSent)
		
		#Network.world.server_update_other_players_on_team(teamId, id)
		#Network.world.server_update_players_on_team(teamId)

# Server override of position. remote from world.
func updateData(timeSent, playerData):
	print("resync player: " + str(id))
	#if playerData.position - (position - velocity) * 10 > Vector2(1, 1):
	#velocity = playerData.velocity
	#movement = playerData.movement
	#if playerData.position - (position - velocity * 5) > Vector2(0.01, 0.01):
	#	position = playerData.position
	
	#move_and_slide(Vector2(0, 0), UP)

#func reconcile(serverPos):
#	var maxDelta = position 

func equals(d1, d2):
	for key in d1:
		if !d2.has(key) or d1[key] != d2[key]:
			return false
	return true
