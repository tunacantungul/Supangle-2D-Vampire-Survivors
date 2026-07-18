extends Node2D
## "styx" kartı: Styx'in Halkası — oyuncunun çevresindeki halkada duran her
## düşmana sürekli hasar veren zehirli aura. Nişan almak gerekmez, yakındaki
## her şeyi eritir; bu yüzden efsanevi (legendary) nadirlikte.
## Kart seviyeleri: 1 = açılır, 2 = hasar artar, 3 = alan büyür ve hasar biraz daha artar.

## Hasarın kaç saniyede bir uygulandığı. Halka sürekli açık olduğundan
## saniyelik hasar = tick_damage / tick_interval.
@export var tick_interval: float = 0.5
@export var tick_damage: float = 9.0
@export var strong_tick_damage: float = 15.0
@export var radius: float = 620.0
@export var big_radius: float = 860.0
## Halkanın nefes alır gibi büyüyüp küçülme oranı ve hızı.
@export var pulse_amount: float = 0.04
@export var pulse_speed: float = 2.2

var _pulse_time: float = 0.0
## Halkanın o anki yarıçapa karşılık gelen taban ölçeği.
var _base_scale: float = 1.0

@onready var ring: Sprite2D = $Ring
@onready var tick_timer: Timer = $TickTimer

func _ready() -> void:
	ring.visible = false
	tick_timer.wait_time = tick_interval
	GameState.upgrades_changed.connect(_refresh)
	GameState.powers_changed.connect(_refresh)
	_refresh()

func _process(delta: float) -> void:
	if not ring.visible:
		return
	_pulse_time += delta * pulse_speed
	ring.scale = Vector2.ONE * _base_scale * (1.0 + sin(_pulse_time) * pulse_amount)

func _refresh() -> void:
	var tier := GameState.upgrade_tier("styx")
	if tier <= 0 or not GameState.has_power(GameState.Power.ATTACK):
		tick_timer.stop()
		ring.visible = false
		set_process(false)
		return
	# Halka görseli 220 px çapında çizildi; yarıçapa ölçekleniyor.
	_base_scale = _current_radius(tier) / 110.0
	ring.scale = Vector2.ONE * _base_scale
	ring.visible = true
	set_process(true)
	if tick_timer.is_stopped():
		tick_timer.start()

func _on_tick_timer_timeout() -> void:
	var tier := GameState.upgrade_tier("styx")
	if tier <= 0:
		return
	var r := _current_radius(tier)
	var dmg := strong_tick_damage if tier >= 2 else tick_damage
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		if global_position.distance_to(enemy.global_position) <= r:
			enemy.take_damage(dmg)

func _current_radius(tier: int) -> float:
	return big_radius if tier >= 3 else radius
