extends Control
## Oyun içi HUD: can barı, canavar sayacı ve güç durumu.
## Ölümsüzlük varken can barı altın "korumalı" görünüme geçer.

const COLOR_ACTIVE := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LOST := Color(1.0, 1.0, 1.0, 0.2)

## Can barı dolgu stilleri: normal ve ölümsüzlük (korumalı) hali.
@export var fill_style_normal: StyleBox
@export var fill_style_immortal: StyleBox

@onready var health_bar: ProgressBar = %HealthBar
@onready var immortal_label: Label = %ImmortalLabel
@onready var kill_label: Label = %KillLabel
@onready var power_immortality: Label = %PowerImmortality
@onready var power_flight: Label = %PowerFlight
@onready var power_attack: Label = %PowerAttack

func _ready() -> void:
	GameState.kills_changed.connect(_on_kills_changed)
	GameState.powers_changed.connect(_refresh_powers)
	_on_kills_changed(GameState.kills, GameState.kill_quota)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.health_changed.connect(_on_health_changed)
		_on_health_changed(player.health, player.max_health)
	_refresh_powers()

func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current

var _kills: int = 0
var _required: int = 0
var _objective: String = ""

func _on_kills_changed(current: int, required: int) -> void:
	_kills = current
	_required = required
	_update_kill_label()

## Level scripti boss akışı sırasında hedef metnini bununla değiştirir.
func set_objective(text: String) -> void:
	_objective = text
	_update_kill_label()

func _update_kill_label() -> void:
	if _objective != "":
		kill_label.text = _objective
	elif _required <= 0:
		kill_label.text = ""
	elif _kills >= _required:
		kill_label.text = "Arena hazır! İşaretli alana gir"
	else:
		kill_label.text = "Canavar: %d / %d" % [_kills, _required]

func _refresh_powers() -> void:
	var immortal := GameState.has_power(GameState.Power.IMMORTALITY)
	immortal_label.visible = immortal
	if fill_style_normal != null and fill_style_immortal != null:
		health_bar.add_theme_stylebox_override("fill", fill_style_immortal if immortal else fill_style_normal)
	power_immortality.modulate = COLOR_ACTIVE if immortal else COLOR_LOST
	power_flight.modulate = COLOR_ACTIVE if GameState.has_power(GameState.Power.FLIGHT) else COLOR_LOST
	power_attack.modulate = COLOR_ACTIVE if GameState.has_power(GameState.Power.ATTACK) else COLOR_LOST
