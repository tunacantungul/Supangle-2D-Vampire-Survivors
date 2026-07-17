extends Area2D
## Bölüm çıkış kapısı. Kota dolana kadar soluk ve pasif durur;
## aktifleşince oyuncu girdiğinde player_entered sinyali yayar.

signal player_entered

var active: bool = false

func activate() -> void:
	if active:
		return
	active = true
	monitoring = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _on_body_entered(body: Node2D) -> void:
	if not active or not body is Player:
		return
	active = false
	# body_entered fizik akışı sırasında gelir; pause/diyalog başlatmayı idle'a ertele.
	player_entered.emit.call_deferred()
