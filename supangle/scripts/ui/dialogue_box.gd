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
## Diyalog açıkken arkayı karartan filtrenin rengi ve yoğunluğu.
@export var dim_color := Color(0.0, 0.0, 0.0, 0.55)
@export var dim_fade_time: float = 0.25
## Portrenin kutuya göre konumu: x panelin sol kenarından kayma,
## y ise portrenin altının panelin üst kenarına ne kadar bineceği.
## (0, 0) = portre tam kutunun dış çerçevesinden başlar.
@export var portrait_offset := Vector2(0.0, 0.0)
## Portrelerin taban kenar uzunluğu. Kayıttaki "scale" bunu çarpar.
## Astarios'un ölçeği 1.0, yani bu değer doğrudan onun boyu; diğerleri ona göre
## büyütülüyor. Tavanı en büyük portrenin (Athena, 1.35) ekrandan taşmaması
## belirliyor: 500 x 1.35 = 675 ve kutunun üst kenarı 1080p'de y=734.
@export var portrait_size: float = 500.0

## Portrenin kutunun hangi ucunda duracağı. Astarios solda, tanrılar sağda:
## karşılıklı konuşma hissi versin diye.
## Ad bilerek "Side" değil: Godot'da o adda yerleşik bir global enum var ve
## tip olarak yazılınca yerleşik olana bağlanıp çakışıyor.
enum PortraitSide { LEFT, RIGHT }

## Konuşmacı adına göre diyalog portresi. Yeni portre eklemek için buraya
## bir satır eklemek yeterli; adı olmayan konuşmacıda portre gizlenir.
## "side" verilmezse sol, "scale" verilmezse portrait_size kullanılır.
##
## Ölçekler figürlerin BAŞ boyutuna göre veriliyor, çizim sınırlarına göre değil.
## Beş portre de tuvali dikeyde neredeyse dolduruyor, ama kadrajın ne kadarını
## karakterin yüzünün kapladığı çok değişiyor: Astarios'un yüzü en büyüğü,
## Athena'nınkiyse en küçüğü çünkü kadrajın yarısını miğfer tüyü yiyor. Sınır
## kutusuna göre eşitlemek bu yüzden Astarios'u herkesten iri gösteriyordu.
## Astarios referans (1.0); diğerleri onunla aynı boyda okunacak şekilde büyütüldü.
var _portraits := {
	"Astarios": {"texture": preload("res://assets/portraits/Astarios Dialogue.png"), "side": PortraitSide.LEFT},
	"Zeus": {"texture": preload("res://assets/portraits/Zeus.png"), "side": PortraitSide.RIGHT, "scale": 1.15},
	"Hermes": {"texture": preload("res://assets/portraits/Hermes.png"), "side": PortraitSide.RIGHT, "scale": 1.3},
	"Athena": {"texture": preload("res://assets/portraits/Athena.png"), "side": PortraitSide.RIGHT, "scale": 1.35},
	# Kavuşma sahnesinde Astarios ile yan yana duruyor; ikisi aynı boyda görünsün.
	"Kallisto": {"texture": preload("res://assets/portraits/Kallisto.png"), "side": PortraitSide.RIGHT, "scale": 1.3},
}

var _lines: Array[String] = []
var _index: int = 0
## O an gösterilen portrenin tarafı; konum hesabı bunu kullanıyor.
## Sözlükten Variant olarak geldiği için int tutuluyor (enum değerleri zaten int).
var _portrait_side: int = PortraitSide.LEFT
## Arkayı karartan tam ekran dikdörtgen. Kendi çocuğumuz olamaz (kutunun
## kapsayıcısı onu panele sığdırırdı ve panelin önüne çizilirdi), bu yüzden
## kardeşimiz olarak hemen önümüze ekleniyor: HUD/harita/canavarların üstünde,
## diyalog kutusu ve portrenin altında kalıyor.
var _dim: ColorRect
var _typing: bool = false
## Kesirli ilerleme; int'e yuvarlanarak visible_characters'a yazılır.
var _revealed: float = 0.0

@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var portrait: TextureRect = %Portrait

func _ready() -> void:
	set_process(false)
	# Portre top_level olduğu için kapsayıcı onu yerleştirmez; kutu her
	# yeniden boyutlandığında konumunu kendimiz tazeliyoruz.
	resized.connect(_update_portrait_position)

func start(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_index = 0
	name_label.text = speaker
	visible = true
	set_process(true)
	_show_dim()
	_show_line()
	# İlk karede kutunun yerleşimi henüz kesinleşmemiş olabiliyor.
	_update_portrait_position.call_deferred()

## --- Arka plan karartması ---

func _show_dim() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if _dim == null or not is_instance_valid(_dim):
		_dim = ColorRect.new()
		_dim.name = "DialogueDim"
		_dim.color = dim_color
		_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Oyun diyalog sırasında duraklatılmış oluyor.
		_dim.process_mode = Node.PROCESS_MODE_ALWAYS
		parent.add_child(_dim)
		_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Bizden hemen önceki sıraya al: arkamızda, diğer her şeyin önünde kalsın.
	parent.move_child(_dim, get_index())
	_dim.visible = true
	_dim.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_dim, "modulate:a", 1.0, dim_fade_time)

func _hide_dim() -> void:
	if _dim == null or not is_instance_valid(_dim):
		return
	var tween := create_tween()
	tween.tween_property(_dim, "modulate:a", 0.0, dim_fade_time)
	tween.tween_callback(_dim.hide)

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
	_update_portrait(name_label.text)
	text_label.text = line
	text_label.visible_characters = 0
	_revealed = 0.0
	_typing = true

## Konuşan kişinin portresi varsa gösterir, yoksa gizler.
func _update_portrait(speaker: String) -> void:
	var entry: Dictionary = _portraits.get(speaker, {})
	portrait.visible = not entry.is_empty()
	if entry.is_empty():
		return
	portrait.texture = entry["texture"]
	portrait.size = Vector2.ONE * portrait_size * float(entry.get("scale", 1.0))
	_portrait_side = entry.get("side", PortraitSide.LEFT)
	_update_portrait_position()

## Portre, konuşmacının tarafındaki üst köşeden yukarı taşacak şekilde konumlanır.
func _update_portrait_position() -> void:
	if not portrait.visible:
		return
	var x := global_position.x + portrait_offset.x
	if _portrait_side == PortraitSide.RIGHT:
		x = global_position.x + size.x - portrait_offset.x - portrait.size.x
	portrait.global_position = Vector2(x, global_position.y + portrait_offset.y - portrait.size.y)

func _complete_line() -> void:
	_typing = false
	text_label.visible_characters = -1

func _close() -> void:
	_typing = false
	visible = false
	portrait.visible = false
	set_process(false)
	_hide_dim()
	finished.emit()
