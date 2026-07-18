extends PanelContainer
## Basit sıralı diyalog kutusu. Oyun durdurulmuşken de çalışır (process_mode: Always).
## Satırlar soldan sağa harf harf yazılır; SPACE / E / Enter yazımı tamamlar,
## satır tamamsa bir sonrakine geçer. Satırlar bitince finished sinyali yayar.
##
## Vurgu efektleri doğrudan satır metnine BBCode olarak yazılır, örneğin:
##   "Madem ölümlüler gibi seveceksin, [shake rate=22 level=14]ölebileceksin[/shake] de."
## Kullanılabilir etiketlerden bazıları: [shake] (titreme), [wave] (dalga),
## [tornado] (savrulma), [b], [i], [color=...]. rate = titreme hızı,
## level = genlik; ikisi de büyüdükçe efekt sertleşir.

signal finished

## Satır başındaki adın en fazla kaç karakter olabileceği. Replik içinde geçen
## iki nokta üst üstenin yanlışlıkla konuşmacı sanılmasını engeller.
const SPEAKER_MAX_LENGTH := 24

## Saniyede kaç harf yazılacağı.
@export var chars_per_second: float = 45.0

var _lines: Array[String] = []
var _index: int = 0
var _typing: bool = false
## Kesirli ilerleme; int'e yuvarlanarak visible_characters'a yazılır.
var _revealed: float = 0.0

@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %TextLabel

func _ready() -> void:
	set_process(false)

func start(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_index = 0
	name_label.text = speaker
	visible = true
	set_process(true)
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("advance"):
		return
	get_viewport().set_input_as_handled()
	if _typing:
		# Yazım sürüyorsa önce satırı tamamla, geçmek için ikinci basış gerekir.
		_complete_line()
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()

func _process(delta: float) -> void:
	if not _typing:
		return
	_revealed += chars_per_second * delta
	text_label.visible_characters = int(_revealed)
	# BBCode etiketleri sayılmaz; get_total_character_count yalnızca görünen harfleri verir.
	if int(_revealed) >= text_label.get_total_character_count():
		_complete_line()

func _show_line() -> void:
	var line := _lines[_index]
	# "Konuşmacı: replik" biçimindeki satırlarda ad üst etikete taşınır, böylece
	# aynı diyalogda iki kişi karşılıklı konuşabilir.
	var colon := line.find(":")
	if colon > 0 and colon <= SPEAKER_MAX_LENGTH:
		name_label.text = line.substr(0, colon).strip_edges()
		line = line.substr(colon + 1).strip_edges()
	text_label.text = line
	text_label.visible_characters = 0
	_revealed = 0.0
	_typing = true

func _complete_line() -> void:
	_typing = false
	text_label.visible_characters = -1

func _close() -> void:
	_typing = false
	visible = false
	set_process(false)
	finished.emit()
