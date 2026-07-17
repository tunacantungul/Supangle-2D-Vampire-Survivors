extends Node2D
## Oyuncunun etrafında dönen kılıçlar; temas eden düşmanlara periyodik hasar verir.
## Başlangıçta kapalıdır: "orbit" kartı alındıkça 1 -> 2 -> 3 kılıca çıkar.
## Kılıçlar bu sahnenin Area2D çocuklarıdır, dizilim kart seviyesine göre eşit dağıtılır.

@export var rotation_speed: float = 1.8
@export var damage: float = 15.0
## Aynı düşmana iki vuruş arası minimum süre.
@export var hit_cooldown: float = 0.5
@export var orbit_radius: float = 90.0

var _last_hit_at: Dictionary = {}

@onready var _swords: Array[Area2D] = [$Sword1, $Sword2, $Sword3]

func _ready() -> void:
	GameState.upgrades_changed.connect(_refresh)
	GameState.powers_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var tier := GameState.upgrade_tier("orbit")
	var active := tier > 0 and GameState.has_power(GameState.Power.ATTACK)
	visible = active
	set_physics_process(active)
	for i in _swords.size():
		var on := active and i < tier
		_swords[i].visible = on
		_swords[i].monitoring = on
		if on:
			var angle := TAU * i / tier
			_swords[i].position = Vector2.from_angle(angle) * orbit_radius
			_swords[i].rotation = angle + PI / 2.0

func _physics_process(delta: float) -> void:
	rotation += rotation_speed * delta
	var now := Time.get_ticks_msec() / 1000.0
	for sword in _swords:
		if not sword.monitoring:
			continue
		for body in sword.get_overlapping_bodies():
			var enemy := body as Enemy
			if enemy == null:
				continue
			var id := enemy.get_instance_id()
			if now - float(_last_hit_at.get(id, -1000.0)) >= hit_cooldown:
				_last_hit_at[id] = now
				enemy.take_damage(damage)
	if _last_hit_at.size() > 512:
		_last_hit_at.clear()
