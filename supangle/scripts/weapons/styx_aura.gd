extends Node2D
## "styx" kartı: Styx'in Halkası — oyuncunun çevresindeki halkada duran her
## düşmana sürekli hasar veren zehirli aura. Nişan almak gerekmez, yakındaki
## her şeyi eritir; bu yüzden efsanevi (legendary) nadirlikte.
## Kart seviyeleri: 1 = açılır, 2 = alan büyür, 3 ve 4 = hasar artar.

## Hasarın kaç saniyede bir uygulandığı. Halka sürekli açık olduğundan
## saniyelik hasar = o kademenin hasarı / tick_interval.
@export var tick_interval: float = 0.5
## Kademe başına yarıçap ve tik hasarı. 0. eleman "kart alınmadı" durumu.
@export var tier_radius: Array[float] = [0.0, 420.0, 560.0, 560.0, 560.0]
@export var tier_damage: Array[float] = [0.0, 9.0, 9.0, 14.0, 20.0]
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
	var dmg := _tier_value(tier_damage, tier)
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null:
			continue
		if global_position.distance_to(enemy.global_position) <= r:
			enemy.take_damage(dmg)

func _current_radius(tier: int) -> float:
	return _tier_value(tier_radius, tier)

## Kademe tablosundan güvenli okuma: tablo kısaysa son değer kullanılır.
func _tier_value(table: Array[float], tier: int) -> float:
	if table.is_empty():
		return 0.0
	return table[clampi(tier, 0, table.size() - 1)]
