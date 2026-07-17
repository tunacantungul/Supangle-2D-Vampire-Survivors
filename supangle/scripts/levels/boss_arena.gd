extends Area2D
## Boss arenası: kota dolunca level tarafından "arm" edilir.
## Oyuncu içine girince triggered sinyali yayar ve işaret gizlenir.
## İşaretin görseli test için belirgin; sonradan tilemap'e göre tasarlanacak.

signal triggered

var armed: bool = false

var _used: bool = false

@onready var marker: Sprite2D = $Marker

func _ready() -> void:
	# Kota dolana kadar soluk görünür.
	marker.modulate = Color(1, 1, 1, 0.35)

func arm() -> void:
	if armed:
		return
	armed = true
	marker.modulate = Color.WHITE
	var tween := create_tween().set_loops()
	tween.tween_property(marker, "modulate:a", 0.55, 0.5)
	tween.tween_property(marker, "modulate:a", 1.0, 0.5)

func _on_body_entered(body: Node2D) -> void:
	if not armed or _used or not body is Player:
		return
	_used = true
	triggered.emit()
	hide()
