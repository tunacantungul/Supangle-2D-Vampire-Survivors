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

## Hasar veren skiller. Erken oyunda (aşağıdaki seviyeye kadar) üç karttan biri
## mutlaka bunlardan olur; oyuncu ilk boss'a silahsız yakalanmasın diye.
## Perseus (stab) taban saldırı zaten hep açık, o yüzden garanti listesinde yok.
const OFFENSIVE_CARDS: Array[String] = ["orbit", "bolt", "discus", "artemis", "styx"]
## Garanti hasar kartının verildiği üst seviye sınırı (kabaca ilk boss'a kadar).
## İlk boss tetik seviyesini değiştirirsen burayı da güncelle.
const GUARANTEED_OFFENSIVE_UNTIL_LEVEL := 8

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

## Kart havuzu: her hat {name, icon, rarity, tiers} taşır; tiers'ın sıradaki
## elemanı alınacak kartı anlatır. "mortal_only": true olan kartlar yalnızca
## ölümsüzlük kaybedildikten sonra havuza girer. name/icon HUD'daki güç listesi
## ve kart menüsünde kullanılır.
const UPGRADE_TRACKS: Dictionary = {
	"orbit": {
		"name": "Ares'in Yörüngesi",
		"icon": "res://assets/icons/icon_orbit.png",
		"rarity": Rarity.RARE,
		"tiers": [
			{"title": "Ares'in Yörüngesi", "desc": "Etrafında dönen 1 kılıç"},
			{"title": "Ares'in Yörüngesi II", "desc": "Dönen kılıç sayısı 2 olur"},
			{"title": "Ares'in Yörüngesi III", "desc": "Dönen kılıç sayısı 3 olur"},
		],
	},
	"bolt": {
		"name": "Athena'nın Kargısı",
		"icon": "res://assets/icons/icon_javelin.png",
		"rarity": Rarity.RARE,
		"tiers": [
			{"title": "Athena'nın Kargısı", "desc": "4 sn'de bir en yakın düşmana kargı fırlatır"},
			{"title": "Hızlı Kargı", "desc": "Kargı bekleme süresi 2 sn'ye iner"},
			{"title": "Güçlü Kargı", "desc": "Kargı hasarı iki katına çıkar"},
			{"title": "İkiz Kargı", "desc": "Aynı anda 2 ayrı hedefe kargı"},
		],
	},
	"stab": {
		"name": "Perseus'un Hamlesi",
		"icon": "res://assets/icons/icon_stab.png",
		"rarity": Rarity.UNCOMMON,
		"tiers": [
			{"title": "Perseus'un Hamlesi", "desc": "Kılıç art arda 2 kez saplanır"},
			{"title": "Keskin Kılıç", "desc": "Saplama hasarı %50 artar"},
			{"title": "Savaş Çığlığı", "desc": "Saplama menzili %50 artar"},
		],
	},
	"discus": {
		"name": "Olimpiyat Diski",
		"icon": "res://assets/icons/icon_discus.png",
		"rarity": Rarity.RARE,
		"tiers": [
			{"title": "Olimpiyat Diski", "desc": "6 sn'de bir gidip geri dönen disk fırlatır"},
			{"title": "Olimpiyat Diski II", "desc": "Disk bekleme süresi 4 sn'ye iner"},
			{"title": "Şampiyon Diski", "desc": "Disk hasarı %60 artar ve hızlanır"},
		],
	},
	"freeze": {
		"name": "Boreas'ın Soluğu",
		"icon": "res://assets/icons/icon_freeze.png",
		"rarity": Rarity.EPIC,
		"tiers": [
			{"title": "Boreas'ın Soluğu", "desc": "10 sn'de bir yakındaki düşmanları 1.5 sn dondurur"},
			{"title": "Boreas'ın Soluğu II", "desc": "Sıklık 7 sn, donma 2.5 sn olur"},
			{"title": "Kuzeyin Öfkesi", "desc": "Donma alanı büyür"},
		],
	},
	"speed": {
		"name": "Hermes'in Sandalı",
		"icon": "res://assets/icons/icon_speed.png",
		"rarity": Rarity.COMMON,
		"tiers": [
			{"title": "Hermes'in Sandalı", "desc": "Hareket hızı %10 artar"},
			{"title": "Hermes'in Sandalı II", "desc": "Hareket hızı toplam %20 artar"},
		],
	},
	# Bölüm 1'de oyuncu zaten ölümsüz; can kartı orada anlamsız olurdu.
	"vitality": {
		"name": "Hygieia'nın Lütfu",
		"icon": "res://assets/icons/icon_vitality.png",
		"rarity": Rarity.COMMON,
		"mortal_only": true,
		"tiers": [
			{"title": "Hygieia'nın Lütfu", "desc": "+25 azami can ve anında iyileşme"},
			{"title": "Hygieia'nın Lütfu II", "desc": "+25 azami can ve anında iyileşme"},
			{"title": "Hygieia'nın Lütfu III", "desc": "+25 azami can ve anında iyileşme"},
		],
	},
	"kronos": {
		"name": "Kronos'un Kumu",
		"icon": "res://assets/icons/icon_kronos.png",
		"rarity": Rarity.EPIC,
		"tiers": [
			{"title": "Kronos'un Kumu", "desc": "Tüm düşmanlar kalıcı %12 yavaşlar"},
			{"title": "Kronos'un Kumu II", "desc": "Yavaşlama toplam %24 olur"},
			{"title": "Zamanın Ağırlığı", "desc": "Yavaşlama toplam %36 olur"},
		],
	},
	"artemis": {
		"name": "Artemis'in Oku",
		"icon": "res://assets/icons/icon_artemis.png",
		"rarity": Rarity.RARE,
		"tiers": [
			{"title": "Artemis'in Oku", "desc": "6 sn'de bir hattaki tüm düşmanları delen ok"},
			{"title": "Artemis'in Oku II", "desc": "Ok bekleme süresi 4 sn'ye iner"},
			{"title": "Gümüş Ok", "desc": "Ok hasarı iki katına çıkar"},
		],
	},
	"magnet": {
		"name": "Kehribar Tılsımı",
		"icon": "res://assets/icons/icon_magnet.png",
		"rarity": Rarity.COMMON,
		"tiers": [
			{"title": "Kehribar Tılsımı", "desc": "XP taşlarını biraz uzaktan çeker"},
			{"title": "Kehribar Tılsımı II", "desc": "Çekim menzili iki katına çıkar"},
		],
	},
	# Ölümsüzlük gittikten sonra (2+) anlam kazanan savunma kartları.
	"armor": {
		"name": "Hephaistos Zırhı",
		"icon": "res://assets/icons/icon_armor.png",
		"rarity": Rarity.UNCOMMON,
		"mortal_only": true,
		"tiers": [
			{"title": "Hephaistos Zırhı", "desc": "Alınan hasar %20 azalır"},
			{"title": "Hephaistos Zırhı II", "desc": "Alınan hasar toplam %35 azalır"},
		],
	},
	"bloodprice": {
		"name": "Kan Bedeli",
		"icon": "res://assets/icons/icon_bloodprice.png",
		"rarity": Rarity.UNCOMMON,
		"mortal_only": true,
		"tiers": [
			{"title": "Kan Bedeli", "desc": "Öldürünce %8 ihtimalle 2 can"},
			{"title": "Kan Bedeli II", "desc": "İhtimal %12, iyileşme 3 can olur"},
		],
	},
	# Efsanevi: nişan almadan çevredeki her şeyi eriten sürekli aura.
	"styx": {
		"name": "Styx'in Halkası",
		"icon": "res://assets/icons/icon_styx.png",
		"rarity": Rarity.LEGENDARY,
		"tiers": [
			{"title": "Styx'in Halkası", "desc": "Çevrendeki düşmanlara sürekli hasar veren zehirli halka"},
			{"title": "Styx'in Halkası II", "desc": "Halkanın alanı büyür"},
			{"title": "Kara Irmak", "desc": "Halkanın hasarı belirgin şekilde artar"},
			{"title": "Kharon'un Bedeli", "desc": "Halkanın hasarı bir kez daha artar"},
		],
	},
}

## Artık tek bir harita var: üç boss aynı sahnede sırayla çıkıyor ve oyuncu
## kesintisiz olarak seviye atlıyor. Bölüm bazlı sıfırlama kaldırıldı.
const LEVEL_SCENE := "res://scenes/levels/level_1.tscn"
const PROLOGUE_SCENE := "res://scenes/levels/prologue.tscn"
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
## Bölümün seviye atlama maliyeti çarpanı. 1'in altında olması o bölümde
## daha sık seviye atlanması demek; zor bölümleri yumuşatmak için kullanılır.
var xp_requirement_mult: float = 1.0
## Bölümün düşman hasarı çarpanı. Temas, mermi ve boss vuruşlarının hepsine
## uygulanır; zemin tehlikeleri (bulut boşluğu, su) etkilenmez.
var enemy_damage_mult: float = 1.0

func _ready() -> void:
	_reset_powers()

func has_power(power: Power) -> bool:
	return powers.get(power, false)

## Düşman kaynaklı hasarı bölümün çarpanıyla ölçekler.
func scaled_enemy_damage(amount: float) -> float:
	return amount * enemy_damage_mult

func power_loss_text(power: int) -> String:
	return POWER_LOSS_TEXT.get(power, "")

func lose_power(power: int) -> void:
	powers[power] = false
	powers_changed.emit()

## Her bölüm başında bölüm sahnesi tarafından çağrılır.
## Bedel teması gereği XP, seviye ve alınan kartlar da her bölümde sıfırlanır.
func setup_level(quota: int, xp_mult: float = 1.0, damage_mult: float = 1.0) -> void:
	kills = 0
	kill_quota = quota
	xp_requirement_mult = xp_mult
	enemy_damage_mult = damage_mult
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
	return maxi(int(round(player_level * XP_STEP * xp_requirement_mult)), 1)

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

## Açık olan ve henüz tükenmemiş hatlardan en fazla `count` kart seçer.
## Seçim nadirlik ağırlıklarına göre yapılır; aynı kart iki kez gelmesin diye
## çekilen kart havuzdan düşürülür.
## Erken oyunda seçenekler arasında hiç hasar kartı yoksa, sıradanlardan biri
## bir hasar kartıyla değiştirilir.
func pick_upgrade_options(count: int = 3) -> Array[String]:
	var pool: Array[String] = []
	for id: String in UPGRADE_TRACKS:
		var track: Dictionary = UPGRADE_TRACKS[id]
		# "mortal_only" kartlar (can, zırh, kan bedeli) ölümsüzken anlamsız;
		# yalnızca ölümsüzlük kaybedildikten (ilk boss) sonra havuza girer.
		if track.get("mortal_only", false) and has_power(Power.IMMORTALITY):
			continue
		if upgrade_tier(id) < track["tiers"].size():
			pool.append(id)
	var picked: Array[String] = []
	while picked.size() < count and not pool.is_empty():
		var id := _draw_weighted(pool)
		picked.append(id)
		pool.erase(id)
	_ensure_offensive(picked, pool)
	return picked

## Erken oyunda seçeneklerin arasına en az bir hasar kartı sokuşturur.
func _ensure_offensive(picked: Array[String], pool: Array[String]) -> void:
	if player_level > GUARANTEED_OFFENSIVE_UNTIL_LEVEL:
		return
	for id in picked:
		if id in OFFENSIVE_CARDS:
			return
	# Havuzda (henüz çekilmemiş) bir hasar kartı varsa seçeneklerden birini
	# onunla değiştir. Sıradan/nadir olmayan bir slotu feda ederiz.
	var offensive_pool: Array[String] = []
	for id in pool:
		if id in OFFENSIVE_CARDS:
			offensive_pool.append(id)
	if offensive_pool.is_empty() or picked.is_empty():
		return
	picked[picked.size() - 1] = offensive_pool[randi() % offensive_pool.size()]

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

## Yeni oyun prologla başlar; harita prolog bitince açılır.
func start_new_game() -> void:
	_reset_powers()
	current_level = 0
	victory = false
	_change_scene(PROLOGUE_SCENE)

## Prolog diyaloğu bitince çağrılır.
## Perdeli geçiş: harita ağır (elle çizilmiş) ve yüklenirken oyun donuyor.
## Perde olmadan oyuncu prolog ekranına bakarken saniyelerce takılıyor ve
## oyunu kilitlenmiş sanıyordu.
func start_first_level() -> void:
	SceneTransition.change_scene_covered(LEVEL_SCENE)

## Ölünce tüm run baştan başlar: tek harita olduğu için güçler ve ilerleme
## tamamen sıfırlanır (setup_level yeniden çağrılıyor).
func retry_level() -> void:
	_reset_powers()
	victory = false
	SceneTransition.change_scene_covered(LEVEL_SCENE)

## Son boss yenilip kapıdan çıkılınca çağrılır: kavuşma sahnesine geçilir.
func go_to_epilogue() -> void:
	SceneTransition.change_scene_covered(EPILOGUE_SCENE)

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
