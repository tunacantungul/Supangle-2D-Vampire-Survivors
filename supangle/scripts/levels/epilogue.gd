extends Node2D
## Kavuşma sahnesi: Olympus'tan ayrıldıktan sonra sevgiliyle buluşma.
## Sadece diyalogdan oluşur; diyalog bitince oyun zaferle sonlanır.

@export var speaker_name: String = "Kavuşma"
## Vurgulanacak kelimeler satır metnine BBCode ile yazılır: [shake]ölümsüz[/shake].
@export var dialogue_lines: Array[String] = []

@onready var dialogue_box: PanelContainer = $UI/DialogueBox

func _ready() -> void:
	dialogue_box.finished.connect(_on_dialogue_finished)
	dialogue_box.start(speaker_name, dialogue_lines)

func _on_dialogue_finished() -> void:
	GameState.finish_game()
