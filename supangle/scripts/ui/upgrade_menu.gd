extends Control
## Seviye atlama kart menüsü. Oyun durdurulmuşken çalışır (process_mode: Always).
## Level scripti open() ile açar; oyuncu kart seçince card_chosen sinyali yayılır.
## Üstte o ana kadar alınmış güçler ikon + seviye olarak listelenir.

signal card_chosen(id: String)

const UPGRADE_ENTRY_SCENE := preload("res://scenes/ui/upgrade_entry.tscn")

var _option_ids: Array[String] = []
## Kart çizimi kendi altın çerçevesini taşıdığı için nadirlik artık çerçeve
## rengiyle değil, çizimin üstüne verilen hafif bir renk tonuyla gösteriliyor.
## Ton beyaza doğru seyreltiliyor: aksi hâlde çizimin altın detayları
## nadirlik rengine boyanıp çamurlaşıyor.
const RARITY_TINT := 0.78
const RARITY_TINT_HOVER := 0.55
## Üzerine gelince kartın parlaması.
const HOVER_BRIGHTEN := 1.3

## Sahnedeki özgün kart stilleri; her açılışta bunların kopyası renklendirilir.
var _base_normal: StyleBoxTexture
var _base_hover: StyleBoxTexture

@onready var _buttons: Array[Button] = [%Card1, %Card2, %Card3]
@onready var _owned_label: Label = %OwnedLabel
## HFlowContainer: alınan güç sayısı artınca kutucuklar kendiliğinden
## alt satıra sarar, tek satırda ekran dışına taşmaz.
@onready var _owned_box: HFlowContainer = %OwnedBox

func _ready() -> void:
	visible = false
	_base_normal = _buttons[0].get_theme_stylebox("normal") as StyleBoxTexture
	_base_hover = _buttons[0].get_theme_stylebox("hover") as StyleBoxTexture
	for i in _buttons.size():
		_buttons[i].pressed.connect(_on_card_pressed.bind(i))

## Kart kimliklerini alır, başlık/açıklamaları havuzdan doldurur ve menüyü gösterir.
## Kartların boyutu sabittir; başlık ve açıklama etiketleri kart içinde sarar.
func open(options: Array[String]) -> void:
	_option_ids = options
	for i in _buttons.size():
		var has_option := i < options.size()
		_buttons[i].visible = has_option
		if has_option:
			var info: Dictionary = GameState.upgrade_card_info(options[i])
			(_buttons[i].get_node("Content/VBox/Title") as Label).text = info.title
			(_buttons[i].get_node("Content/VBox/Desc") as Label).text = info.desc
			(_buttons[i].get_node("Content/VBox/IconRect") as TextureRect).texture = GameState.upgrade_icon(options[i])
			var rarity_color := GameState.rarity_color(options[i])
			var rarity_label := _buttons[i].get_node("Content/VBox/RarityLabel") as Label
			rarity_label.text = GameState.rarity_name(options[i]).to_upper()
			rarity_label.add_theme_color_override("font_color", rarity_color)
			_apply_rarity_border(_buttons[i], rarity_color)
	_refresh_owned()
	visible = true

## Kartı nadirlik rengine boyar; üzerine gelince aynı renk doygunlaşıp parlar.
func _apply_rarity_border(button: Button, color: Color) -> void:
	var normal := _base_normal.duplicate() as StyleBoxTexture
	normal.modulate_color = color.lerp(Color.WHITE, RARITY_TINT)
	var hover := _base_hover.duplicate() as StyleBoxTexture
	var tint := color.lerp(Color.WHITE, RARITY_TINT_HOVER)
	# Alfa'yı da çarpmamak için bileşen bileşen kuruluyor; 1'i aşan alfa
	# kırpılırken kartın saydamlığı değişirdi.
	hover.modulate_color = Color(
		tint.r * HOVER_BRIGHTEN, tint.g * HOVER_BRIGHTEN, tint.b * HOVER_BRIGHTEN, 1.0
	)
	button.add_theme_stylebox_override("normal", normal)
	for state in ["hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, hover)

## Üst satır: şu ana kadar alınan güçler (ikon + Sv).
func _refresh_owned() -> void:
	for child in _owned_box.get_children():
		child.queue_free()
	var any := false
	for id: String in GameState.upgrades:
		var tier: int = GameState.upgrades[id]
		if tier <= 0:
			continue
		any = true
		var entry: PanelContainer = UPGRADE_ENTRY_SCENE.instantiate()
		_owned_box.add_child(entry)
		entry.setup(GameState.upgrade_icon(id), "%s  Sv %d" % [GameState.upgrade_name(id), tier], GameState.rarity_color(id))
	_owned_label.visible = any

func _on_card_pressed(index: int) -> void:
	visible = false
	card_chosen.emit(_option_ids[index])
