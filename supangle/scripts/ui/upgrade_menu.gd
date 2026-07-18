extends Control
## Seviye atlama kart menüsü. Oyun durdurulmuşken çalışır (process_mode: Always).
## Level scripti open() ile açar; oyuncu kart seçince card_chosen sinyali yayılır.
## Üstte o ana kadar alınmış güçler ikon + seviye olarak listelenir.

signal card_chosen(id: String)

const UPGRADE_ENTRY_SCENE := preload("res://scenes/ui/upgrade_entry.tscn")

var _option_ids: Array[String] = []
## Sahnedeki özgün kart çerçeveleri; her açılışta bunların kopyası boyanır.
var _base_normal: StyleBoxFlat
var _base_hover: StyleBoxFlat

@onready var _buttons: Array[Button] = [%Card1, %Card2, %Card3]
@onready var _owned_label: Label = %OwnedLabel
@onready var _owned_box: HBoxContainer = %OwnedBox

func _ready() -> void:
	visible = false
	_base_normal = _buttons[0].get_theme_stylebox("normal") as StyleBoxFlat
	_base_hover = _buttons[0].get_theme_stylebox("hover") as StyleBoxFlat
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

## Kartın çerçevesini nadirlik rengine boyar; üzerine gelince aynı renk parlar.
func _apply_rarity_border(button: Button, color: Color) -> void:
	var normal := _base_normal.duplicate() as StyleBoxFlat
	normal.border_color = color
	var hover := _base_hover.duplicate() as StyleBoxFlat
	hover.border_color = color.lightened(0.3)
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
