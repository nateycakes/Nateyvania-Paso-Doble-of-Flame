class_name VictoryArea
extends Area2D

func _ready() -> void:
	connect("area_entered", self, "_on_area_entered");

func _on_area_entered(hurtbox: HurtBox) -> void:
	get_tree().change_scene("res://src/Interface/WinScreen.tscn")
	pass # Replace with function body.
