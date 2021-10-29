extends "res://scenes/CustomDialogue.gd"

onready var AboutRichTextLabel := $CenterContainer/Panel/MarginContainer/VBoxContainer/AboutRichTextLabel

func _ready():
	AboutRichTextLabel.connect("meta_clicked", self, "_on_meta_clicked")

func _on_meta_clicked(meta) -> void:
	OS.shell_open(meta)
