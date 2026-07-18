extends Sprite2D
## Halka/aura görsellerini sabit hızda döndürür. Tamamen görsel bir efekt;
## menzil, hasar gibi hiçbir oyun değerini etkilemez.
## Negatif hız ters yöne döndürür — üst üste binen halkalar birbirinden
## ayrılsın diye farklı yön/hız vermek iyi sonuç veriyor.

@export var degrees_per_second: float = 30.0

func _process(delta: float) -> void:
	# Görünmeyen halkayı döndürmenin anlamı yok.
	if not visible:
		return
	rotation_degrees = wrapf(rotation_degrees + degrees_per_second * delta, 0.0, 360.0)
