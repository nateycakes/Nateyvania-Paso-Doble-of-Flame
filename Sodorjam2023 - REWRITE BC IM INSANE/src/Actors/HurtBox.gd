class_name HurtBox
extends Area2D

func _init() -> void:
	pass


func _ready() -> void:
	connect("area_entered", self, "_on_area_entered");


func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null: #if anything that isn't a hitbox hits, just return
		return
		
	if owner.has_method("take_damage"):
			owner.take_damage(hitbox.damage)
