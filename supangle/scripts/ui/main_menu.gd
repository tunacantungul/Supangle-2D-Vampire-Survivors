extends Control

func _on_start_button_pressed() -> void:
	GameState.start_new_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
