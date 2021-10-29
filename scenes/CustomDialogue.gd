extends Popup

onready var ContentContainer = $CenterContainer
onready var OkayButton = $CenterContainer/Panel/MarginContainer/VBoxContainer/OkayButton

func _ready():
	OkayButton.connect("pressed", self, "hide")

func popup_centered(size: Vector2 = ContentContainer.rect_size) -> void:
	.popup_centered(size)
