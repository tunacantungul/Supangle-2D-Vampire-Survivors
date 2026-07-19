extends Node2D
## Tek bir yıldırım düşüşü: önce yerde yarı saydam telegraf çemberi belirir,
## süre dolunca yıldırım düşer ve alandaki oyuncu ile düşmanlara hasar verir.

## Telegraf çemberinin görünme süresi (yıldırım düşmeden önce).
@export var telegraph_time: float = 1.0
@export var damage: float = 30.0

## Ses kaydında gök gürültüsünün patladığı an. Kayıt 4.7 sn ve ilk 1.5 sn'si
## alçak bir gürleme; çatırtı tam yıldırımın düştüğü kareye denk gelsin diye
## ses baştan değil, bu noktadan geriye sayacak şekilde başlatılıyor.
const SOUND_IMPACT_TIME := 1.5
## Çarpmadan sonra sesin kısılma süresi. Kaydın kalan ~3 saniyesi bırakılırsa
## yıldırımlar 2-4 sn'de bir düştüğü için gök gürültüleri üst üste biniyor ve
## bölüm boyunca susmayan bir uğultuya dönüşüyordu.
const SOUND_TAIL := 0.9
## Görsellerin sönme süresi. Sesten kısa; düğüm ikisi de bitene kadar yaşıyor.
const VISUAL_FADE := 0.3

@onready var telegraph: Sprite2D = $Telegraph
@onready var bolt_sprite: Sprite2D = $BoltSprite
@onready var damage_area: Area2D = $DamageArea
@onready var strike_timer: Timer = $StrikeTimer
@onready var thunder: AudioStreamPlayer = $Thunder

func _ready() -> void:
	bolt_sprite.visible = false
	strike_timer.wait_time = telegraph_time
	strike_timer.start()
	# Telegraf süresi çatırtı noktasından kısaysa ses ortadan başlar; uzunsa
	# baştan başlar ve çatırtı yine düşüşten sonraya kalmaz.
	thunder.play(maxf(SOUND_IMPACT_TIME - telegraph_time, 0.0))
	var tween := create_tween().set_loops()
	tween.tween_property(telegraph, "modulate:a", 0.45, 0.25)
	tween.tween_property(telegraph, "modulate:a", 1.0, 0.25)

func _on_strike_timer_timeout() -> void:
	bolt_sprite.visible = true
	telegraph.modulate = Color(1.6, 1.6, 1.2)
	for body in damage_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage)
		elif body is Enemy:
			body.take_damage(damage)
	# Görsel sönerken ses de kısılıyor; düğüm ancak ikisi de bittiğinde
	# siliniyor, yoksa silinme sesi ortasından keserdi.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, VISUAL_FADE)
	tween.tween_property(thunder, "volume_db", -40.0, SOUND_TAIL)
	tween.chain().tween_callback(queue_free)
