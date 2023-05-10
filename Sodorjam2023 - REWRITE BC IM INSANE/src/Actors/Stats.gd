class_name Stats
extends Node

export var max_health : int
onready var health = max_health

signal no_health
signal health_change(value)
signal max_health_change(value)

func set_max_health(value):
	max_health = value
	emit_signal("max_health_change", max_health)

func set_health(healthUpdate):
	health = healthUpdate
	emit_signal("health_change", health)
	if health <= 0:
		emit_signal("no_health")
		
