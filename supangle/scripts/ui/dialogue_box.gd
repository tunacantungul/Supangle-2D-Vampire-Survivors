extends PanelContainer
## Basit sıralı diyalog kutusu. Oyun durdurulmuşken de çalışır (process_mode: Always).
## SPACE / E / Enter ile ilerler, satırlar bitince finished sinyali yayar.

signal finished

var _lines: Array[String] = []
var _index: int = 0

@onready var name_label: Label = %NameLabel
@onready var text_label: Label = %TextLabel

func start(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_index = 0
	name_label.text = speaker
	visible = true
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("advance"):
		get_viewport().set_input_as_handled()
		_index += 1
		if _index >= _lines.size():
			visible = false
			finished.emit()
		else:
			_show_line()

func _show_line() -> void:
	text_label.text = _lines[_index]
