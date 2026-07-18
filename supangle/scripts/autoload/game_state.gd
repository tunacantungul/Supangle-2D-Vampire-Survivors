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

## Güçler kayıp sırasına göre: önce ölümsüzlük, sonra uçuş, en son tanrısal güç.
enum Power { IMMORTALITY, FLIGHT, ATTACK }

## Bölüm sonunda siyah ekranda yazılacak kayıp metni.
const POWER_LOSS_TEXT: Dictionary = {
	Power.IMMORTALITY: "Ölümsüzlüğünü kaybettin...",
	Power.FLIGHT: "Kanatlarını kaybettin...",
	Power.ATTACK: "Tanrısal gücünü kaybettin...",
}

## Her seviye bir öncekinden bu kadar fazla XP ister (1->2: 10, 2->3: 20...).
const XP_STEP := 10

## Kart nadirlikleri. Kart menüsünde kartın çerçeve rengini ve havuzdan
## çekilme ağırlığını belirler.
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Nadirlik başına görünen ad, çerçeve rengi ve çekiliş ağırlığı.
## Ağırlıklar bilerek birbirine yakın: efsanevi kart nadir hissettirsin ama
## bir bölüm boyunca rahatça görülebilsin diye sadece hafifçe düşürülmüş.
const RARITIES: Dictionary = {
	Rarity.COMMON: {"name": "Sıradan", "color": Color(0.72, 0.74, 0.78), "weight": 1.0},
	Rarity.UNCOMMON: {"name": "Nadir", "color": Color(0.42, 0.82, 0.45), "weight": 0.95},
	Rarity.RARE: {"name": "Ender", "color": Color(0.36, 0.62, 0.95), "weight": 0.85},
	Rarity.EPIC: {"name": "Destansı", "color": Color(0.68, 0.44, 0.92), "weight": 0.7},
	Rarity.LEGENDARY: {"name": "Efsanevi", "color": Color(1.0, 0.62, 0.16), "weight": 0.55},
}

## Kart havuzu: her hat {name, icon, rarity, min_chapter, tiers} taşır; tiers'ın
## sıradaki elemanı alınacak kartı anlatır. min_chapter, kartın havuza girdiği
## bölüm (0 tabanlı). name/icon HUD'daki güç listesi ve kart menüsünde kullanılır.
const UPGRADE_TRACKS: Dictionary = {
	"orbit": {
		"name": "Ares'in Yörüngesi",
		"icon": "res://assets/icons/icon_orbit.svg",
		"rarity": Rarity.RARE,
		"min_chapter": 0,
		"tiers": [
			{"title": "Ares'in Yörüngesi", "desc": "Etrafında dönen 1 kılıç"},
			{"title": "Ares'in Yörüngesi II", "desc": "Dönen kılıç sayısı 2 olur"},
			{"title": "Ares'in Yörüngesi III", "desc": "Dönen kılıç sayısı 3 olur"},
		],
	},
	"bolt": {
		"name": "Athena'nın Kargısı",
		"icon": "res://assets/icons/icon_javelin.svg",
		"rarity": Rarity.RARE,
		"min_chapter": 0,
		"tiers": [
			{"title": "Athena'nın Kargısı", "desc": "4 sn'de bir en yakın düşmana kargı fırlatır"},
			{"title": "Hızlı Kargı", "desc": "Kargı bekleme süresi 2 sn'ye iner"},
			{"title": "Güçlü Kargı", "desc": "Kargı hasarı iki katına çıkar"},
			{"title": "İkiz Kargı", "desc": "Aynı anda 2 ayrı hedefe kargı"},
		],
	},
	"stab": {
		"name": "Perseus'un Hamlesi",
		"icon": "res://assets/icons/icon_stab.svg",
		"rarity": Rarity.UNCOMMON,
		"min_chapter": 0,
		"tiers": [
			{"title": "Perseus'un Hamlesi", "desc": "Kılıç art arda 2 kez saplanır"},
			{"title": "Keskin Kılıç", "desc": "Saplama hasarı %50 artar"},
			{"title": "Savaş Çığlığı", "desc": "Saplama menzili %50 artar"},
		],
	},
	"discus": {
		"name": "Olimpiyat Diski",
		"icon": "res://assets/icons/icon_discus.svg",
		"rarity": Rarity.RARE,
		"min_chapter": 0,
		"tiers": [
			{"title": "Olimpiyat Diski", "desc": "6 sn'de bir gidip geri dönen disk fırlatır"},
			{"title": "Olimpiyat Diski II", "desc": "Disk bekleme süresi 4 sn'ye iner"},
			{"title": "Şampiyon Diski", "desc": "Disk hasarı %60 artar ve hızlanır"},
		],
	},
	"freeze": {
		"name": "Boreas'ın Soluğu",
		"icon": "res://assets/icons/icon_freeze.svg",
		"rarity": Rarity.EPIC,
		"min_chapter": 0,
		"tiers": [
			{"title": "Boreas'ın Soluğu", "desc": "10 sn'de bir yakındaki düşmanları 1.5 sn dondurur"},
			{"title": "Boreas'ın Soluğu II", "desc": "Sıklık 7 sn, donma 2.5 sn olur"},
			{"title": "Kuzeyin Öfkesi", "desc": "Donma alanı büyür"},
		],
	},
	"speed": {
		"name": "Hermes'in Sandalı",
		"icon": "res://assets/icons/icon_speed.svg",
		"rarity": Rarity.COMMON,
		"min_chapter": 0,
		"tiers": [
			{"title": "Hermes'in Sandalı", "desc": "Hareket hızı %10 artar"},
			{"title": "Hermes'in Sandalı II", "desc": "Hareket hızı toplam %20 artar"},
		],
	},
	"vitality": {
		"name": "Hygieia'nın Lütfu",
		"icon": "res://assets/icons/icon_vitality.svg",
		"rarity": Rarity.COMMON,
		"min_chapter": 0,
		"tiers": [
			{"title": "Hygieia'nın Lütfu", "desc": "+25 azami can ve anında iyileşme"},
			{"title": "Hygieia'nın Lütfu II", "desc": "+25 azami can ve anında iyileşme"},
			{"title": "Hygieia'nın Lütfu III", "desc": "+25 azami can ve anında iyileşme"},
		],
	},
	"kronos": {
		"name": "Kronos'un Kumu",
		"icon": "res://assets/icons/icon_kronos.svg",
		"rarity": Rarity.EPIC,
		"min_chapter": 0,
		"tiers": [
			{"title": "Kronos'un Kumu", "desc": "Tüm düşmanlar kalıcı %12 yavaşlar"},
			{"title": "Kronos'un Kumu II", "desc": "Yavaşlama toplam %24 olur"},
			{"title": "Zamanın Ağırlığı", "desc": "Yavaşlama toplam %36 olur"},
		],
	},
	"artemis": {
		"name": "Artemis'in Oku",
		"icon": "res://assets/icons/icon_artemis.svg",
		"rarity": Rarity.RARE,
		"min_chapter": 0,
		"tiers": [
			{"title": "Artemis'in Oku", "desc": "6 sn'de bir hattaki tüm düşmanları delen ok"},
			{"title": "Artemis'in Oku II", "desc": "Ok bekleme süresi 4 sn'ye iner"},
			{"title": "Gümüş Ok", "desc": "Ok hasarı iki katına çıkar"},
		],
	},
	"magnet": {
		"name": "Kehribar Tılsımı",
		"icon": "res://assets/icons/icon_magnet.svg",
		"rarity": Rarity.COMMON,
		"min_chapter": 0,
		"tiers": [
			{"title": "Kehribar Tılsımı", "desc": "XP taşlarını biraz uzaktan çeker"},
			{"title": "Kehribar Tılsımı II", "desc": "Çekim menzili iki katına çıkar"},
		],
	},
	# Ölümsüzlük gittikten sonra (2+) anlam kazanan savunma kartları.
	"armor": {
		"name": "Hephaistos Zırhı",
		"icon": "res://assets/icons/icon_armor.svg",
		"rarity": Rarity.UNCOMMON,
		"min_chapter": 1,
		"tiers": [
			{"title": "Hephaistos Zırhı", "desc": "Alınan hasar %20 azalır"},
			{"title": "Hephaistos Zırhı II", "desc": "Alınan hasar toplam %35 azalır"},
		],
	},
	"bloodprice": {
		"name": "Kan Bedeli",
		"icon": "res://assets/icons/icon_bloodprice.svg",
		"rarity": Rarity.UNCOMMON,
		"min_chapter": 1,
		"tiers": [
			{"title": "Kan Bedeli", "desc": "Öldürünce %10 ihtimalle 5 can"},
			{"title": "Kan Bedeli II", "desc": "İhtimal %20, iyileşme 8 can olur"},
		],
	},
	# Efsanevi: nişan almadan çevredeki her şeyi eriten sürekli aura.
	"styx": {
		"name": "Styx'in Halkası",
		"icon": "res://assets/icons/icon_styx.svg",
		"rarity": Rarity.LEGENDARY,
		"min_chapter": 0,
		"tiers": [
			{"title": "Styx'in Halkası", "desc": "Çevrendeki düşmanlara sürekli hasar veren zehirli halka"},
			{"title": "Styx'in Halkası II", "desc": "Halkanın alanı büyür"},
			{"title": "Kara Irmak", "desc": "Halkanın hasarı belirgin şekilde artar"},
			{"title": "Kharon'un Bedeli", "desc": "Halkanın hasarı bir kez daha artar"},
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

func power_loss_text(power: int) -> String:
	return POWER_LOSS_TEXT.get(power, "")

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

## Düşmanlar ölürken çağırır. XP vermez; düşman öldüğünde XP taşı düşürür
## ve XP, taş toplanınca gain_xp() ile kazanılır (Vampire Survivors tarzı).
func register_kill() -> void:
	kills += 1
	kills_changed.emit(kills, kill_quota)
	enemy_killed.emit()

## XP taşı toplanınca taş tarafından çağrılır.
func gain_xp(amount: int) -> void:
	_gain_xp(amount)

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

## Hattın kısa adı (HUD güç listesi ve kart menüsü üst satırı için).
func upgrade_name(id: String) -> String:
	return UPGRADE_TRACKS[id]["name"]

func upgrade_icon(id: String) -> Texture2D:
	return load(UPGRADE_TRACKS[id]["icon"])

## --- Nadirlik ---

func upgrade_rarity(id: String) -> Rarity:
	return UPGRADE_TRACKS[id]["rarity"]

## Kart menüsünün çerçeve rengi.
func rarity_color(id: String) -> Color:
	return RARITIES[upgrade_rarity(id)]["color"]

## "Efsanevi", "Sıradan" gibi görünen ad.
func rarity_name(id: String) -> String:
	return RARITIES[upgrade_rarity(id)]["name"]

func rarity_weight(id: String) -> float:
	return RARITIES[upgrade_rarity(id)]["weight"]

## Bu bölümde açık olan ve henüz tükenmemiş hatlardan en fazla `count` kart seçer.
## Seçim nadirlik ağırlıklarına göre yapılır; aynı kart iki kez gelmesin diye
## çekilen kart havuzdan düşürülür.
func pick_upgrade_options(count: int = 3) -> Array[String]:
	var pool: Array[String] = []
	for id: String in UPGRADE_TRACKS:
		var track: Dictionary = UPGRADE_TRACKS[id]
		if current_level < track["min_chapter"]:
			continue
		if upgrade_tier(id) < track["tiers"].size():
			pool.append(id)
	var picked: Array[String] = []
	while picked.size() < count and not pool.is_empty():
		var id := _draw_weighted(pool)
		picked.append(id)
		pool.erase(id)
	return picked

## Havuzdan ağırlıklara göre tek kart çeker (rulet tekerleği).
func _draw_weighted(pool: Array[String]) -> String:
	var total := 0.0
	for id in pool:
		total += rarity_weight(id)
	var roll := randf() * total
	for id in pool:
		roll -= rarity_weight(id)
		if roll <= 0.0:
			return id
	# Kayan nokta yuvarlamasına karşı emniyet.
	return pool[pool.size() - 1]

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
