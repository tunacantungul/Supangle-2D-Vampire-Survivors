extends Node2D
## Vampire Survivors tarzı spawner: oyuncunun etrafında, ekran dışında düşman doğurur.
## Zamanla spawn aralığı kısalır, tempo artar.

@export var enemy_scenes: Array[PackedScene] = []
## enemy_scenes ile aynı sıradaki doğma ağırlıkları. Boş bırakılırsa hepsi
## eşit olasılıkla doğar. Zor düşmanların sayısını kısmak için kullanılıyor.
@export var spawn_weights: Array[float] = []
@export var spawn_interval: float = 1.2
@export var min_spawn_interval: float = 0.28
## Her spawn sonrası aralığın ne kadar kısalacağı. Bölüm ilerledikçe
## tempo bununla artıyor; min_spawn_interval tabanına kadar iniyor.
@export var interval_decay: float = 0.022
## Oyuncudan ne kadar uzakta doğacakları (ekran dışı olacak şekilde).
@export var spawn_distance: float = 4300.0
## Düşmanların doğabileceği dünya alanı (duvarların içi).
@export var spawn_area: Rect2 = Rect2(-7000, -4300, 14000, 8600)
## Haritadaki azami canavar sayısı. Harita çok geniş olduğu için yüksek bir
## sınır, oyuncunun hiç görmediği yerlerde yığılmaya yol açıyordu.
@export var max_enemies: int = 90
## Bu mesafeden uzaktaki canavarlar silinir. Oyuncu görüş alanının yarı köşegeni
## ~2200 birim, doğma mesafesi 4300; bu yüzden sınır ikisinin de belirgin
## üstünde: kaçarken peşindekiler silinmiyor, ama geride kalan sürü birikip
## sayıyı doldurmuyordu. Sayı dolunca oyuncunun yanında yeni canavar doğmuyor
## ve bölüm ölü hissettiriyordu.
@export var despawn_distance: float = 6800.0

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

## Boss ölünce çağrılır: sahne temizlendikten sonra yeni canavar gelmesin,
## oyuncu kapıya rahatça yürüsün.
func stop() -> void:
	spawn_timer.stop()

func _on_spawn_timer_timeout() -> void:
	_despawn_far_enemies()
	_try_spawn()
	spawn_timer.wait_time = maxf(min_spawn_interval, spawn_timer.wait_time - interval_decay)
	spawn_timer.start()

## Oyuncunun çok gerisinde kalan canavarları siler. Onlar geri yetişemiyor ama
## azami sayıyı doldurup oyuncunun çevresinde yeni canavar doğmasını
## engelliyorlardı. Boss asla silinmez: o da "enemies" grubunda ve arenadan
## uzaklaşınca yok olması dövüşü bozardı.
func _despawn_far_enemies() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var limit_squared := despawn_distance * despawn_distance
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null or enemy is Boss:
			continue
		if enemy.global_position.distance_squared_to(player.global_position) > limit_squared:
			enemy.queue_free()

func _try_spawn() -> void:
	if enemy_scenes.is_empty():
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var pos := player.global_position + Vector2.from_angle(randf() * TAU) * spawn_distance
	pos.x = clampf(pos.x, spawn_area.position.x, spawn_area.end.x)
	pos.y = clampf(pos.y, spawn_area.position.y, spawn_area.end.y)
	var enemy: Node2D = _pick_scene().instantiate()
	enemy.position = pos
	get_parent().add_child(enemy)

## Ağırlıklar verilmişse onlara göre, verilmemişse eşit olasılıkla seçer.
func _pick_scene() -> PackedScene:
	if spawn_weights.size() != enemy_scenes.size():
		return enemy_scenes.pick_random()
	var total := 0.0
	for weight in spawn_weights:
		total += weight
	if total <= 0.0:
		return enemy_scenes.pick_random()
	var roll := randf() * total
	for i in enemy_scenes.size():
		roll -= spawn_weights[i]
		if roll <= 0.0:
			return enemy_scenes[i]
	return enemy_scenes[enemy_scenes.size() - 1]
