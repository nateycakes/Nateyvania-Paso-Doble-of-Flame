extends KinematicBody2D

enum states{
	IDLE,
	MOVE,
	KNOCKBACK
}

enum facing_direction{
	RIGHT,
	LEFT
}

export(facing_direction) var current_direction = facing_direction.RIGHT
export var maxSpeedH  = 100
export var maxSpeedV = 1000
export var knockbackHSpeed = 50
export var knockbackVSpeed = 500
export var usesGravity : bool = true
export var gravity = 1000


onready var ray_right : RayCast2D = $ray_right
onready var ray_left : RayCast2D = $ray_left
onready var aniSprite : AnimatedSprite = $AnimatedSprite
onready var stats : Stats = $Stats
onready var knockbackTimer : Timer = $knockback_timer
onready var hurtboxCollisionShape : CollisionShape2D = $HurtBox/CollisionShape2D

var hSpeed = 0 #character horizontal speed this frame
var vSpeed = 0 #character vertical speed this frame
var on_ledge : bool = false #do we detect a ledge?
var is_invincible : bool = false #is the creature able to take damage?

var state = states.IDLE

var motion = Vector2.ZERO



func _ready() -> void:
	update_facing_direction()
	pass #END _ready


func _physics_process(delta: float) -> void:
	do_gravity(delta)
	do_physics(delta)
	pass #END _phsyics_process


#######################   CUSTOM FUNCTIONS #####################################

func do_physics(var delta):
	motion.y = vSpeed
	motion.x = hSpeed
	motion = move_and_slide(motion, Vector2.UP)
	pass #END do_physics


func do_gravity(var delta):
	if state == states.KNOCKBACK:
		vSpeed += (knockbackVSpeed * delta) * sign(vSpeed)
	elif is_on_floor():
		vSpeed = 0
		
	else:
		vSpeed += (maxSpeedV * delta)
	vSpeed = min(vSpeed, maxSpeedV) #limit fallspeed
	
	pass #END do_gravity


func do_movestate(var delta):
	if (current_direction == facing_direction.RIGHT):
		hSpeed += (hSpeed * delta) 
		hSpeed = min(hSpeed, maxSpeedH) 
	if (current_direction == facing_direction.LEFT):
		hSpeed -= (hSpeed * delta) 
		hSpeed = min(hSpeed, -maxSpeedH) 
	pass #END do_movement
	if (usesGravity):
		do_gravity(delta)


func update_facing_direction():
	if (current_direction == facing_direction.RIGHT):
		aniSprite.flip_h = false
	else:
		aniSprite.flip_h = true
pass #END update_facing_direction


func check_if_on_ledge():
	if (!ray_left.is_colliding() or !ray_right.is_colliding()):
		return true
	else:
		return false
	pass #END check_if_on_ledge


func match_speed_to_direction():
	if (current_direction == facing_direction.RIGHT):
		hSpeed = maxSpeedH
	else:
		hSpeed = -maxSpeedH
	pass#END match_speed_to_direction
	
	if (is_on_wall() or on_ledge):
		if (current_direction == facing_direction.RIGHT):
			position.x -= 10 #barely nudge away from the colliding wall
			current_direction = facing_direction.LEFT
		else:
			position.x += 10 #barely nudge away from the colliding wall
			current_direction = facing_direction.RIGHT
		update_facing_direction()
	
	pass#END match_speed_to_direction


func take_damage(var damage):
	if (state != states.KNOCKBACK) or (!is_invincible):
		state = states.KNOCKBACK
		stats.health -= damage
		is_invincible = true
		knockbackTimer.start()
		hurtboxCollisionShape.set_deferred("disabled", true)
		#hurtboxCollisionShape.disabled = true #enemy is invincible during knockback
		#print("Owwie I took " + str(damage) + " damage and have " + str(stats.health) + " health left")
	if stats.health <= 0:
		die()
	pass #END take_damage

func die():
	queue_free()
	pass #END die


func _on_knockback_timer_timeout() -> void:
	state = states.IDLE
	is_invincible = false
	hurtboxCollisionShape.set_deferred("disabled", false)
	#hurtboxCollisionShape.disabled = false #knockback finished, creature can be damaged again
	pass # Replace with function body.
