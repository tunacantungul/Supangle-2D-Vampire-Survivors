class_name Boss
extends Enemy
## Bölüm sonu bossu: üstünde can barı gösterir, ölünce boss_died sinyali yayar.
## Boss ölümü normal kill sayacına işlenmez (kota zaten dolmuştur).

signal boss_died

@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	super._ready()
	health_bar.max_value = max_health
	health_bar.value = health

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	health_bar.value = maxf(health, 0.0)

func _die() -> void:
	boss_died.emit()
	queue_free()
