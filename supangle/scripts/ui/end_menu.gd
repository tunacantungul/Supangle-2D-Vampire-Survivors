extends Control
## Hem zafer hem ölüm ekranı; metinler GameState.victory durumuna göre ayarlanır.

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel
@onready var retry_button: Button = %RetryButton

func _ready() -> void:
	if GameState.victory:
		title_label.text = "BEDEL ÖDENDİ"
		message_label.text = "Kalkanın, kanatların, gücün... hepsi geride kaldı.\nArtık sıradan bir insansın — ama kalbin nihayet özgür."
		retry_button.text = "Baştan Oyna"
	else:
		title_label.text = "OLYMPUS KAZANDI"
		message_label.text = "Bu sefer bedel canın oldu. Ama aşk pes etmez."
		retry_button.text = "Tekrar Dene"

func _on_retry_button_pressed() -> void:
	if GameState.victory:
		GameState.start_new_game()
	else:
		GameState.retry_level()

func _on_menu_button_pressed() -> void:
	GameState.go_to_main_menu()
