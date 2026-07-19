extends Node2D
## Oyunun açılışı: siyah ekranda Olympos'taki konuşma.
## Diyalog bitince ilk bölüm başlar. Epilogun aynadaki karşılığı.

@export var speaker_name: String = "Olympos"
## Vurgulanacak kelimeler satır metnine BBCode ile yazılır: [shake]gerek[/shake].
@export var dialogue_lines: Array[String] = []

@onready var dialogue_box: PanelContainer = $UI/DialogueBox

func _ready() -> void:
	# Menü müziğinden çapraz geçiş. Prolog müziği 1. bölüm yüklenirken de
	# çalmaya devam eder: sahne değişimi ağır ve o sırada ekran siyah,
	# müziğin kesilmesi bekleyişi çok daha uzun hissettiriyordu.
	Music.play_prologue()
	dialogue_box.finished.connect(_on_dialogue_finished)
	dialogue_box.start(speaker_name, dialogue_lines)

func _on_dialogue_finished() -> void:
	GameState.start_first_level()
