extends "res://scenes/CustomDialogue.gd"

var dialog_text: String = "" setget set_dialog_text, get_dialog_text

onready var DialogLabel = $CenterContainer/Panel/MarginContainer/VBoxContainer/DialogLabel

func _ready():
	DialogLabel.text = dialog_text

func set_dialog_text(text: String) -> void:
	dialog_text = text
	
	if is_inside_tree():
		DialogLabel.text = dialog_text

func get_dialog_text() -> String:
	return dialog_text
