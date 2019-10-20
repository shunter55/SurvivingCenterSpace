#extends KinematicBody2D
extends "ControllableObject.gd"

# Declare member variables here. Examples:
const UP = Vector2(0, -1)
const GRAVITY = 20 #Vector2(0, 20)
const SPEED = 200
const JUMP_HEIGHT = 270

var isOnLadder = false

var id
var teamId
var velocity = Vector2()

func calculatePhysics(controlData: Dictionary):
	velocity.x = 0
	# Apply Gravity
	if !is_on_floor() and !isOnLadder:
		velocity.y += GRAVITY
	# Move
	if controlData.left:
		velocity.x = -SPEED
	if controlData.right:
		velocity.x = SPEED
	if isOnLadder:
		if controlData.up:
			velocity.y = -SPEED
		elif controlData.down:
			velocity.y = SPEED
		else:
			velocity.y = 0
	# Jump
	if controlData.up and is_on_floor():
		velocity.y = -JUMP_HEIGHT
	# Move and Slide
	velocity = move_and_slide(velocity, UP)
