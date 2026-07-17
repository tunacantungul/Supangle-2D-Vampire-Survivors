extends Control
## Oyun içi HUD: can barı, canavar sayacı ve güç durumu göstergesi.

const COLOR_READY := Color(0.98, 0.85, 0.35, 1.0)
const COLOR_ACTIVE := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_RECHARGING := Color(1.0, 1.0, 1.0, 0.55)
const COLOR_LOST := Color(1.0, 1.0, 1.0, 0.2)

@onready var health_bar: ProgressBar = %HealthBar
@onready var kill_label: Label = %KillLabel
@onready var power_shield: Label = %PowerShield
@onready var power_flight: Label = %PowerFlight
@onready var power_attack: Label = %PowerAttack

var _shield_ready: bool = false

func _ready() -> void:
	GameState.kills_changed.connect(_on_kills_changed)
	GameState.powers_changed.connect(_refresh_powers)
	_on_kills_changed(GameState.kills, GameState.kill_quota)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.health_changed.connect(_on_health_changed)
		player.shield_state_changed.connect(_on_shield_state_changed)
		_on_health_changed(player.health, player.max_health)
		_shield_ready = player.shield_ready
	_refresh_powers()

func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current

func _on_kills_changed(current: int, required: int) -> void:
	if required <= 0:
		kill_label.text = ""
	elif current >= required:
		kill_label.text = "Kapı açıldı! Çıkışa ilerle"
	else:
		kill_label.text = "Canavar: %d / %d" % [current, required]

func _on_shield_state_changed(is_ready: bool) -> void:
	_shield_ready = is_ready
	_refresh_powers()

func _refresh_powers() -> void:
	if not GameState.has_power(GameState.Power.SHIELD):
		power_shield.modulate = COLOR_LOST
	elif _shield_ready:
		power_shield.modulate = COLOR_READY
	else:
		power_shield.modulate = COLOR_RECHARGING
	power_flight.modulate = COLOR_ACTIVE if GameState.has_power(GameState.Power.FLIGHT) else COLOR_LOST
	power_attack.modulate = COLOR_ACTIVE if GameState.has_power(GameState.Power.ATTACK) else COLOR_LOST
