extends Node
## Kalıcı oyun durumu: güçler, bölüm sırası, canavar sayacı ve sahne geçişleri.
## Autoload olarak her yerden GameState adıyla erişilir.

signal powers_changed
signal kills_changed(current: int, required: int)
## Yalnızca gerçek bir düşman ölümünde yayılır (sayaç sıfırlamalarında yayılmaz).
signal enemy_killed
signal xp_changed(current: int, required: int)
signal player_level_changed(level: int)
## Seviye atlanınca yayılır; bölüm sahnesi kart menüsünü bununla açar.
signal leveled_up
signal upgrades_changed

## Güçler kayıp sırasına göre: önce ölümsüzlük, sonra uçuş, en son atak.
enum Power { IMMORTALITY, FLIGHT, ATTACK }

const XP_PER_KILL := 1
## Her seviye bir öncekinden bu kadar fazla XP ister (1->2: 10, 2->3: 20...).
const XP_STEP := 10

## Kart havuzu: her hat {min_chapter, tiers} taşır; tiers'ın sıradaki elemanı
## alınacak kartı anlatır. min_chapter, kartın havuza girdiği bölüm (0 tabanlı).
const UPGRADE_TRACKS: Dictionary = {
	"orbit": {
		"min_chapter": 0,
		"tiers": [
			{"title": "Dönen Kılıç", "desc": "Etrafında dönen 1 kılıç"},
			{"title": "Dönen Kılıç II", "desc": "Dönen kılıç sayısı 2 olur"},
			{"title": "Dönen Kılıç III", "desc": "Dönen kılıç sayısı 3 olur"},
		],
	},
	"bolt": {
		"min_chapter": 0,
		"tiers": [
			{"title": "Büyü Işını", "desc": "15 sn'de bir en yakın düşmana ışın"},
			{"title": "Hızlı Işın", "desc": "Işın bekleme süresi 8 sn'ye iner"},
			{"title": "Güçlü Işın", "desc": "Işın hasarı iki katına çıkar"},
			{"title": "İkiz Işın", "desc": "Işın aynı anda 2 ayrı hedefe gider"},
		],
	},
	"stab": {
		"min_chapter": 0,
		"tiers": [
			{"title": "Çift Saplama", "desc": "Kılıç art arda 2 kez saplanır"},
			{"title": "Keskin Kılıç", "desc": "Saplama hasarı %50 artar"},
			{"title": "Savaş Çığlığı", "desc": "Saplama menzili %50 artar"},
		],
	},
	"speed": {
		"min_chapter": 0,
		"tiers": [
			{"title": "Rüzgar Adımı", "desc": "Hareket hızı %20 artar"},
			{"title": "Rüzgar Adımı II", "desc": "Hareket hızı toplam %40 artar"},
		],
	},
	"vitality": {
		"min_chapter": 0,
		"tiers": [
			{"title": "Yaşam Gücü", "desc": "+25 azami can ve anında iyileşme"},
			{"title": "Yaşam Gücü II", "desc": "+25 azami can ve anında iyileşme"},
			{"title": "Yaşam Gücü III", "desc": "+25 azami can ve anında iyileşme"},
		],
	},
	# Zeus'un gazabına karşılık: yıldırım bölümlerinde (2+) açılır.
	"nova": {
		"min_chapter": 1,
		"tiers": [
			{"title": "Yıldırım Kalkanı", "desc": "6 sn'de bir çevrene yıldırım şoku"},
			{"title": "Fırtına Yüreği", "desc": "Şok sıklığı artar (4 sn)"},
			{"title": "Gök Gürültüsü", "desc": "Şok hasarı ve alanı büyür"},
		],
	},
	# Ölümsüzlük gittikten sonra (2+) anlam kazanan savunma kartları.
	"armor": {
		"min_chapter": 1,
		"tiers": [
			{"title": "Kalıntı Zırh", "desc": "Alınan hasar %20 azalır"},
			{"title": "Kalıntı Zırh II", "desc": "Alınan hasar toplam %35 azalır"},
		],
	},
	"bloodprice": {
		"min_chapter": 1,
		"tiers": [
			{"title": "Kan Bedeli", "desc": "Öldürünce %10 ihtimalle 5 can"},
			{"title": "Kan Bedeli II", "desc": "İhtimal %20, iyileşme 8 can olur"},
		],
	},
}

const LEVEL_SCENES: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const END_MENU_SCENE := "res://scenes/ui/end_menu.tscn"
const EPILOGUE_SCENE := "res://scenes/levels/epilogue.tscn"

var powers: Dictionary = {}
var current_level: int = 0
var kills: int = 0
var kill_quota: int = 0
var victory: bool = false

## Bölüm içi ilerleme: her bölüm başında sıfırlanır.
var player_level: int = 1
var xp: int = 0
var upgrades: Dictionary = {}

func _ready() -> void:
	_reset_powers()

func has_power(power: Power) -> bool:
	return powers.get(power, false)

func lose_power(power: int) -> void:
	powers[power] = false
	powers_changed.emit()

## Her bölüm başında bölüm sahnesi tarafından çağrılır.
## Bedel teması gereği XP, seviye ve alınan kartlar da her bölümde sıfırlanır.
func setup_level(quota: int) -> void:
	kills = 0
	kill_quota = quota
	player_level = 1
	xp = 0
	upgrades = {}
	kills_changed.emit(kills, kill_quota)
	xp_changed.emit(xp, xp_required())
	player_level_changed.emit(player_level)
	upgrades_changed.emit()

## Düşmanlar ölürken çağırır.
func register_kill() -> void:
	kills += 1
	kills_changed.emit(kills, kill_quota)
	enemy_killed.emit()
	_gain_xp(XP_PER_KILL)

## Bir sonraki seviye için gereken XP.
func xp_required() -> int:
	return player_level * XP_STEP

func _gain_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_required():
		# Seviye atlandı: XP sıfırdan başlar, taşan miktar yanar.
		player_level += 1
		xp = 0
		xp_changed.emit(xp, xp_required())
		player_level_changed.emit(player_level)
		leveled_up.emit()
	else:
		xp_changed.emit(xp, xp_required())

## --- Kart / gelişim sistemi ---

func upgrade_tier(id: String) -> int:
	return upgrades.get(id, 0)

## Sıradaki kartın başlık/açıklaması (havuzdaki mevcut seviyeye göre).
func upgrade_card_info(id: String) -> Dictionary:
	return UPGRADE_TRACKS[id]["tiers"][upgrade_tier(id)]

## Bu bölümde açık olan ve henüz tükenmemiş hatlardan rastgele en fazla
## `count` kart seçer.
func pick_upgrade_options(count: int = 3) -> Array[String]:
	var pool: Array[String] = []
	for id: String in UPGRADE_TRACKS:
		var track: Dictionary = UPGRADE_TRACKS[id]
		if current_level < track["min_chapter"]:
			continue
		if upgrade_tier(id) < track["tiers"].size():
			pool.append(id)
	pool.shuffle()
	return pool.slice(0, count)

func apply_upgrade(id: String) -> void:
	upgrades[id] = upgrade_tier(id) + 1
	upgrades_changed.emit()

func start_new_game() -> void:
	_reset_powers()
	current_level = 0
	victory = false
	_change_scene(LEVEL_SCENES[0])

## Ölünce mevcut bölümü, o ana kadar kaybedilmiş güçlerle yeniden başlatır.
func retry_level() -> void:
	_reset_powers()
	for power in current_level:
		powers[power] = false
	powers_changed.emit()
	victory = false
	_change_scene(LEVEL_SCENES[current_level])

## Bölüm sonu diyaloğu bitince çağrılır. Son bölümden sonra kavuşma sahnesine geçilir.
func advance_level() -> void:
	current_level += 1
	if current_level >= LEVEL_SCENES.size():
		_change_scene(EPILOGUE_SCENE)
	else:
		_change_scene(LEVEL_SCENES[current_level])

## Kavuşma sahnesi bitince çağrılır: zaferle oyun sonu.
func finish_game() -> void:
	victory = true
	_change_scene(END_MENU_SCENE)

func game_over() -> void:
	victory = false
	_change_scene(END_MENU_SCENE)

func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)

func _reset_powers() -> void:
	powers = {
		Power.IMMORTALITY: true,
		Power.FLIGHT: true,
		Power.ATTACK: true,
	}

func _change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
