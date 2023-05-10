class_name Player
extends KinematicBody2D

enum states{
	IDLE,
	MOVE,
	ATTACK,
	KNOCKBACK
}

const RIGHT = 1
const LEFT = -1

export var gravity = 500
export var acceleration = 2000
export var deacceleration = 2000
export var friction = 2000
export var current_friction = 2000
export var max_horizontal_speed = 100
export var max_fall_speed = 1000
export var jump_height = -700
export var coyote_time_length = 0.1
export var knockbackXStr = 50
export var knockbackYStr = -50 #negative so we go up


var state = states.IDLE
var vSpeed = 0
var hSpeed = 0

var touching_ground : bool = false #check if we're touching the ground
var touching_wall : bool = false #check if we're touching wall
var is_jumping : bool = false #check if we're currently jumping
var is_attacking : bool = false #flag for attacking being active
var air_jump_pressed : bool = false #check if we've pressed jump just before we land
var coyote_time_active : bool = false #check if we can jump JUST after we leave platform
var is_invincible : bool = false #use this for i-frames


var motion = Vector2.ZERO


onready var coyoteTimer = $CoyoteTimer
onready var animationTree = $AnimationTree
onready var animationState = $AnimationTree.get("parameters/playback")
onready var animationPlayer = $AnimationPlayer
onready var knockbackTimer = $knockbackTimer
onready var stats : Stats = $Stats



func _physics_process(delta: float) -> void:
	
	#DETECT GROUND
	#are we airborne or not? this will modify our state's chosen function
	#we will also handle coyote time in this function
	check_ground_logic()
	
	#DETECT PLAYER INPUT
	var player_input_vector = Vector2.ZERO
	player_input_vector = get_input_direction()
	
	#is the player attacking this frame? attacking interrupts other animations and takes precedence
	if Input.is_action_just_pressed("attack"): 
		is_attacking = true
		state = states.ATTACK
	
	
	#SET CHARACTER L/R ORIENTATION
	#only change the blend position if they're moving left or right and if they're not currently attacking
	if (player_input_vector.x != 0) and (!is_attacking): 
		set_animation_blend_position(player_input_vector.x) #set animation blend position for this frame
	
	#DETERMINE JUMP/FALL STATE
	handle_jumping(delta) #figure out if we are supposed to be airborne and set vars accordingly
	
	#RUN STATE MACHINE
	state = determine_current_state(player_input_vector, state)
	do_states(delta, player_input_vector)
	
	#apply the physics we calculated in our state
	do_physics(delta)


func _ready() -> void:
	coyoteTimer.wait_time = coyote_time_length
	animationTree.active = true #turn on the animationTree so we dont need to in the editor





######################### Custom Functions #####################################

func determine_current_state(var input_vector, var currentState):
	if (currentState != states.ATTACK) and (currentState != states.KNOCKBACK):
		if input_vector.x != 0:
			currentState = states.MOVE
		else:
			currentState = states.IDLE
	return currentState #END determine_current_state


func do_states(delta, input_vector):
	var airborne : bool = (is_jumping or !touching_ground)
	match state:
		states.MOVE:
			if (airborne):
				move_state_airborne(delta, input_vector)
			else:
				move_state_ground(delta, input_vector)
		states.IDLE:
			if (airborne):
				idle_state_airborne(delta)
			else:
				idle_state_ground(delta)
		states.ATTACK:
			if (airborne):
				attack_state_airborne(delta, input_vector)
			else:
				attack_state_ground()
		states.KNOCKBACK:
			if (airborne):
				knockback_state_ground(delta, input_vector)
			else:
				knockback_state_ground(delta, input_vector)
	
	pass #END do_states


func check_ground_logic():
	#check for coyote time being active (have we just left the platform)
	if (touching_ground and !is_on_floor()):
		touching_ground = false
		coyote_time_active = true
		coyoteTimer.start()
	#Set if we're touching the ground or not
	touching_ground = is_on_floor()
	if (touching_ground):
		is_jumping = false #we're touching the ground, no way can we be jumping
		motion.y = 0 #stop moving them
		vSpeed = 0
	pass #END check_ground_logic


func get_input_direction() -> Vector2: #is the player moving left or right? falling up or down?
	return Vector2(  
		#subtract right from left to determine horizontal
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
		#was jump just pressed AND they're on the floor? -1 (go up) otherwise, 1, (fall/go down)
		-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 1.0  
	)
	#END get_direction


func attack_state_ground():
	animationState.travel("ATTACK")
	hSpeed = 0
	pass #END attack_state_ground

func attack_state_airborne(var delta, var input_vector):
	animationState.travel("ATTACK")
	if is_jumping:
		if abs(hSpeed) > max_horizontal_speed:
			hSpeed = max_horizontal_speed * sign(hSpeed)
		else:
			hSpeed += ((acceleration * delta) * sign(input_vector.x)) #if input is negative, will add a neg number
	else:
		if abs(hSpeed) > max_horizontal_speed:
			hSpeed = max_horizontal_speed * sign(hSpeed)
		else: hSpeed += ((acceleration * delta) * sign(hSpeed)) #keep moving along without user input
	pass #END attack_state_airborne

func attack_state_finished(): #need to be able to travel back to idle after attack
	state = states.IDLE
	is_attacking = false
	pass #END attack_state_finished

func idle_state_ground(var delta):
	animationState.travel("IDLE")
	hSpeed -= min(abs(hSpeed), current_friction * delta) * sign(hSpeed)
	pass #END idle_state_ground


func idle_state_airborne(var delta):
	animationState.travel("IDLE")
	hSpeed -= min(abs(hSpeed), current_friction * delta) * sign(hSpeed)
	pass #END idle_state_airborne


func knockback_state_ground(var delta, var input_vector):
	animationState.travel("KNOCKBACK")
	hSpeed -= min(abs(hSpeed), current_friction * delta) * sign(hSpeed)
	pass #END gethit_state_ground


func move_state_ground(var delta, var input_vector):
	animationState.travel("MOVE") 
	if input_vector.x == RIGHT: #player is trying to move right
		if(hSpeed <-100): #player is turning from moving left, deaccelerate
			hSpeed += (deacceleration * delta)
		elif (hSpeed < max_horizontal_speed): #move towards max horizontal speed
			hSpeed += (acceleration * delta)
			
	elif input_vector.x == LEFT: #player is trying to move left
		if(hSpeed >100): #player is turning from moving left, deaccelerate
			hSpeed -= (deacceleration * delta)
		elif (hSpeed > -max_horizontal_speed): #move towards max horizontal speed
			hSpeed -= (acceleration * delta)
		
	
	pass #END move_state_ground


func move_state_airborne(var delta, var input_vector):
	animationState.travel("IDLE") #i can make this the fall animation at some point
	if is_jumping:
		if (input_vector.x == RIGHT):
			if (hSpeed < max_horizontal_speed): #move towards max horizontal speed
				hSpeed += (acceleration * delta)
		if (input_vector.x == LEFT):
			if (hSpeed > -max_horizontal_speed): #move towards max horizontal speed
				hSpeed -= (acceleration * delta)
	else: #we're just airborne, move according to prior velocity
		if abs(hSpeed) > max_horizontal_speed:
			hSpeed = max_horizontal_speed * sign(hSpeed)
	pass #END move_state_airborne


func handle_jumping(var delta):
	if (coyote_time_active && Input.is_action_just_pressed("jump")):
		vSpeed = jump_height
		is_jumping = true
	
	if (touching_ground):
		if ((Input.is_action_just_pressed("jump") or air_jump_pressed) and !is_jumping):
			vSpeed = jump_height
			is_jumping = true
			touching_ground = false
	else: #not touching ground
		pass
		
	pass #END handle_jumping



func do_physics(var delta):
	if (is_on_ceiling()):
		motion.y = 10
		vSpeed = 10
	
	vSpeed += (gravity * delta) #apply gravity downwards
	vSpeed = min(vSpeed, max_fall_speed) #limit how fast we fall
	
	#update motion vector
	motion.y = vSpeed
	motion.x = hSpeed
	#apply motion vector
	motion = move_and_slide(motion, Vector2.UP)
	pass #END do_physics


func take_damage(var damage):
	if (!is_invincible): #are we able to take damage?
		stats.health -= damage
		print(state)
		if stats.health <= 0:
			die()
		#set up for knockback state
		is_invincible = true
		state = states.KNOCKBACK
		knockbackTimer.start()
		vSpeed = knockbackYStr
	pass #END take_damage

func die():
	get_tree().change_scene("res://src/Interface/GameOver.tscn")
	pass #END die

func set_animation_blend_position(var input):
	#set all character animations blend positions for left/right facing stuff
	animationTree.set("parameters/IDLE/blend_position", input)
	animationTree.set("parameters/MOVE/blend_position", input)
	animationTree.set("parameters/ATTACK/blend_position", input)
	animationTree.set("parameters/KNOCKBACK/blend_position", input)
	pass #end set_animation_blend_position



func _on_CoyoteTimer_timeout() -> void:
	coyote_time_active = false
	pass # Replace with function body.


func _on_knockbackTimer_timeout() -> void:
	state = states.IDLE
	is_invincible = false
	pass # Replace with function body.
