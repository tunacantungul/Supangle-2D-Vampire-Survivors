extends Control
## Oyun içi HUD: can barı, hedef metni + yön oku ve güç durumu.
## Ölümsüzlük varken can barı altın "korumalı" görünüme geçer.
## Canavar sayacı bilinçli olarak gösterilmez; kota arka planda sayılır.

const COLOR_ACTIVE := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LOST := Color(1.0, 1.0, 1.0, 0.2)

const UPGRADE_ENTRY_SCENE := preload("res://scenes/ui/upgrade_entry.tscn")

## Can barı dolgu stilleri: normal ve ölümsüzlük (korumalı) hali.
@export var fill_style_normal: StyleBox
@export var fill_style_immortal: StyleBox

@onready var upgrades_box: VBoxContainer = %UpgradesBox
@onready var health_bar: ProgressBar = %HealthBar
@onready var immortal_label: Label = %ImmortalLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var objective_arrow: Control = %ObjectiveArrow
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var power_immortality: Label = %PowerImmortality
@onready var power_flight: Label = %PowerFlight
@onready var power_attack: Label = %PowerAttack
@onready var flight_box: VBoxContainer = %FlightBox
@onready var flight_label: Label = %FlightLabel
@onready var flight_bar: ProgressBar = %FlightBar
@onready var control_fly: Label = %ControlFly

func _ready() -> void:
	GameState.powers_changed.connect(_refresh_powers)
	GameState.xp_changed.connect(_on_xp_changed)
	GameState.player_level_changed.connect(_on_player_level_changed)
	GameState.upgrades_changed.connect(_refresh_upgrades)
	_refresh_upgrades()
	_on_xp_changed(GameState.xp, GameState.xp_required())
	_on_player_level_changed(GameState.player_level)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.flight_changed.connect(_on_flight_changed)
		player.flight_cooldown_changed.connect(_on_flight_cooldown_changed)
		_on_health_changed(player.health, player.max_health)
	_refresh_powers()

func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current

func _on_xp_changed(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current

func _on_player_level_changed(level: int) -> void:
	level_label.text = "Seviye %d" % level

## Ekranın solundaki alınmış güçler listesi: her kart için ikon + ad + seviye.
func _refresh_upgrades() -> void:
	for child in upgrades_box.get_children():
		child.queue_free()
	for id: String in GameState.upgrades:
		var tier: int = GameState.upgrades[id]
		if tier <= 0:
			continue
		var entry: PanelContainer = UPGRADE_ENTRY_SCENE.instantiate()
		upgrades_box.add_child(entry)
		# Soldaki listede yalnızca ikon ve seviye: oynanış sırasında gücün adını
		# okumaya kimse fırsat bulmuyor, ikon zaten tanıtıyor. Ad çıkınca
		# kutucuklar daralıp ekranın solunu boşaltıyor.
		# Kart menüsündeki liste tam adı göstermeye devam ediyor.
		entry.setup(GameState.upgrade_icon(id), "Sv %d" % tier, GameState.rarity_color(id), true)

## Level scripti boss akışı sırasında ekranın üstündeki hedef metnini bununla
## değiştirir. Canavar sayacı artık gösterilmiyor, arka planda sayılıyor.
func set_objective(text: String) -> void:
	objective_label.text = text

## Hedef okunu verilen düğüme yöneltir (boss arenası, çıkış kapısı...).
func point_to(target: Node2D, color: Color) -> void:
	objective_arrow.point_to(target, color)

func clear_arrow() -> void:
	objective_arrow.clear_target()

## --- Uçuş göstergesi ---

## Havadayken sayaç yerine "HAVADASIN" yazar; bar bu sırada doluluğunu korur.
func _on_flight_changed(flying: bool) -> void:
	if flying:
		flight_label.text = "UÇUŞ  ·  HAVADASIN"
		flight_bar.value = 1.0

func _on_flight_cooldown_changed(remaining: float, total: float) -> void:
	if remaining <= 0.0:
		flight_label.text = "UÇUŞ  ·  HAZIR"
		flight_bar.value = 1.0
		return
	flight_label.text = "UÇUŞ  ·  %.1f sn" % remaining
	# Bar dolarak hazır olmaya ne kadar kaldığını gösteriyor.
	flight_bar.value = 1.0 - remaining / maxf(total, 0.001)

func _refresh_powers() -> void:
	var immortal := GameState.has_power(GameState.Power.IMMORTALITY)
	immortal_label.visible = immortal
	if fill_style_normal != null and fill_style_immortal != null:
		health_bar.add_theme_stylebox_override("fill", fill_style_immortal if immortal else fill_style_normal)
	power_immortality.modulate = COLOR_ACTIVE if immortal else COLOR_LOST
	var can_fly := GameState.has_power(GameState.Power.FLIGHT)
	power_flight.modulate = COLOR_ACTIVE if can_fly else COLOR_LOST
	power_attack.modulate = COLOR_ACTIVE if GameState.has_power(GameState.Power.ATTACK) else COLOR_LOST
	# Uçuş gücü gidince ne sayaç ne de tuş ipucu bir işe yarar.
	flight_box.visible = can_fly
	control_fly.visible = can_fly
