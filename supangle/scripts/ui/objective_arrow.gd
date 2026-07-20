extends Control
## Ekranın üstünde duran, hedefe doğru dönen yön oku (pusula gibi).
## Boss arenası açılınca arenayı, boss ölünce çıkış kapısını gösterir.
## Dünya koordinatlarında değil ekranda sabit durur; sadece yönü döner,
## böylece hedef ekran dışındayken de nereye gidileceği belli olur.

## Ok yukarıyı (-Y) gösterecek şekilde, merkezi orijinde çizildi.
## arrow_size ile ölçeklenir. PackedVector2Array sabit ifade olamadığı için
## düz dizi tutulup çizim sırasında paketleniyor.
const SHAPE: Array[Vector2] = [
	Vector2(0.0, -1.0),
	Vector2(0.72, -0.1),
	Vector2(0.3, -0.1),
	Vector2(0.3, 0.85),
	Vector2(-0.3, 0.85),
	Vector2(-0.3, -0.1),
	Vector2(-0.72, -0.1),
]

@export var arrow_color: Color = Color(1.0, 0.85, 0.25)
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var outline_width: float = 7.0
## Okun yarı yüksekliği (piksel). Uzaktan görünecek kadar büyük.
@export var arrow_size: float = 48.0
## Okun gösterdiği yönde hafifçe ileri geri süzülmesi.
@export var bob_amount: float = 8.0
@export var bob_speed: float = 3.5
## Okun karakterin ekrandaki merkezinden ne kadar yukarıda duracağı (piksel).
## Konumu zaten karaktere göre gösterdiği için ekranın tepesi yerine başının
## hemen üstünde duruyor.
@export var above_player: float = 130.0

var _target: Node2D
var _player: Node2D
var _time: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)

## Oku verilen düğüme yöneltir ve gösterir.
func point_to(target: Node2D, color: Color) -> void:
	_target = target
	arrow_color = color
	visible = true
	set_process(true)
	queue_redraw()

func clear_target() -> void:
	_target = null
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		clear_target()
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return
	# Ekranda karakterin başının hemen üstünde dur. Ok bir HUD (ekran uzayı)
	# ögesi; oyuncunun dünya konumu kamera dönüşümüyle ekrana çevriliyor.
	# Kontrolün orijini doğrudan hedef noktaya konuyor; şekil orijin etrafında
	# çiziliyor (aşağıya bak), böylece kontrolün boyutuna bağlı kalmıyor —
	# eskiden boyuta güvenince ok karakterin sol üstüne kayıyordu.
	var player_screen := get_viewport().get_canvas_transform() * _player.global_position
	global_position = player_screen - Vector2(0.0, above_player)
	# Şekil yukarıyı gösterdiği için açıya çeyrek tur eklenir.
	rotation = (_target_center() - _player.global_position).angle() + PI * 0.5
	_time += delta
	queue_redraw()

## Hedefin tam ortası. Düğüm orijini yerine çarpışma şeklinin global konumu
## kullanılıyor: arena çemberi ve kapı büyük alanlar, şekil düğüme göre
## kayarsa ok kenarı gösterip oyuncuyu yanlış noktaya yollardı.
func _target_center() -> Vector2:
	var shape := _target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		return shape.global_position
	return _target.global_position

func _draw() -> void:
	# Kontrolün orijini (0,0) etrafında çiziliyor; konum _process'te oraya
	# oturtuluyor. bob yalnızca hafif yukarı-aşağı süzülme.
	var center := Vector2(0.0, -absf(sin(_time * bob_speed)) * bob_amount)
	var points := PackedVector2Array()
	for point in SHAPE:
		points.append(center + point * arrow_size)
	# Önce kalın siyah kenarlık, sonra üstüne dolgu: her zeminde okunur kalsın.
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, outline_color, outline_width, true)
	draw_colored_polygon(points, arrow_color)
