extends Node2D
## Oyunun açılışı: siyah ekranda Olympos'taki konuşma.
## Diyalog bitince ilk bölüm başlar. Epilogun aynadaki karşılığı.

@export var speaker_name: String = "Olympos"
## Vurgulanacak kelimeler satır metnine BBCode ile yazılır: [shake]gerek[/shake].
@export var dialogue_lines: Array[String] = []

@onready var dialogue_box: PanelContainer = $UI/DialogueBox

func _ready() -> void:
	# Menü müziği buraya taşmasın; açılış konuşması sessiz sahnede geçiyor.
	Music.pause_all()
	dialogue_box.finished.connect(_on_dialogue_finished)
	dialogue_box.start(speaker_name, dialogue_lines)

func _on_dialogue_finished() -> void:
	GameState.start_first_level()
