extends "res://src/Actors/Creature.gd"


export var constant_roam = false #if true, never IDLE
export var idle_length = 3 #How long in IDLE state before moving to MOVE
export var move_length = 5 #How long in MOVE state before moving to IDLE

onready var idle_timer = $idle_timer
onready var move_timer = $move_timer


func _ready() -> void:
	idle_timer.wait_time = idle_length
	move_timer.wait_time = move_length
	pass #END _ready


func _physics_process(delta: float) -> void:
	on_ledge = check_if_on_ledge()
	if (constant_roam):
		match_speed_to_direction()
		aniSprite.play("MOVE")
	else:
		do_states(state)
	
	pass #END _physics_process


###########################  CUSTOM FUNCTIONS  #################################

func do_states(var current_state):
	
	if (current_state == states.IDLE):
		aniSprite.play("IDLE")
		hSpeed = 0
		if $idle_timer.is_stopped():
			idle_timer.start()
	elif (current_state == states.MOVE):
		match_speed_to_direction()
		aniSprite.play("MOVE")
		if $move_timer.is_stopped():
			move_timer.start()
	elif (current_state == states.KNOCKBACK):
		aniSprite.play("GETHIT")
		hSpeed = 0
		
	pass #END do_states



func _on_idle_timer_timeout() -> void:
	state = states.MOVE
	pass # end IDLE_TIMER_TIMEOUT


func _on_move_timer_timeout() -> void:
	state = states.IDLE
	pass # end MOVE_TIMER_TIMEOUT
