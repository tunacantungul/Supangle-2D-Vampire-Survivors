# Supangle — Güç Kartları

Seviye atlayınca 3 rastgele kart sunulur. Kartlar **her bölüm başında sıfırlanır**
(bedel teması: güçler kalıcı değil). Aynı hattın kartları sırayla gelir
(ör. Ares'in Yörüngesi II çıkması için önce Ares'in Yörüngesi alınmış olmalı).

XP artık ölümle doğrudan gelmez: düşmanlar **XP taşı** düşürür, oyuncu taşları
toplayınca XP kazanır (Vampire Survivors tarzı). Taşlar oyuncu yaklaşınca
kendiliğinden çekilir; "Kehribar Tılsımı" kartı çekim menzilini büyütür.
Ayrıca bazı düşmanlar düşük şansla **can küresi** düşürür (+15 can; tank %15,
diğerleri %6 ihtimal — `enemy*.tscn` → `health_drop_chance`).

Kart başlıkları/açıklamaları, ikonları, nadirlikleri ve bölüm şartları tek yerden
yönetilir: [`game_state.gd`](../supangle/scripts/autoload/game_state.gd) →
`UPGRADE_TRACKS`. Sayısal denge değerleri ise ilgili silah/oyuncu scriptlerindeki
`@export`larda. Kart ikonları: `assets/icons/icon_<id>.svg`.

## Nadirlik

Her hattın bir nadirliği var. Nadirlik iki şeyi belirler: kart menüsündeki
**çerçeve rengi** ve havuzdan **çekilme ağırlığı**. Ağırlıklar bilerek birbirine
yakın tutuldu — efsanevi kart özel hissettirsin ama bir bölüm boyunca rahatça
görülebilsin diye sadece hafifçe düşürüldü.

| Nadirlik | Renk | Ağırlık | Hatlar |
|---|---|---|---|
| Sıradan | gri | 1.0 | `speed`, `vitality`, `magnet` |
| Nadir | yeşil | 0.95 | `stab`, `armor`, `bloodprice` |
| Ender | mavi | 0.85 | `orbit`, `bolt`, `discus`, `artemis` |
| Destansı | mor | 0.7 | `freeze`, `kronos`, `nova` |
| Efsanevi | turuncu | 0.55 | `styx` |

Renkler ve ağırlıklar `game_state.gd` → `RARITIES`'te; çerçeveyi kart menüsü
(`upgrade_menu.gd` → `_apply_rarity_border()`) her açılışta buradan boyar.
Çekiliş `pick_upgrade_options()` içinde ağırlıklı rulet ile yapılır, aynı kart
iki kez gelmez.

## Kart listesi

| Hat (id) | Nadirlik | Kademe | Kart | Etkisi | Bölüm | Değerlerin yeri |
|---|---|---|---|---|---|---|
| `stab` | Nadir | temel | *Perseus'un Hamlesi* | Başlangıç silahı: 2 sn'de bir menzildeki (1080 px) en yakın düşmana saplama, 35 hasar | 1+ | `stab_sword.gd` |
| `stab` | Nadir | 1 | Perseus'un Hamlesi | Art arda 2 saplama, sonra bekleme | 1+ | `stab_sword.gd` |
| `stab` | Nadir | 2 | Keskin Kılıç | Saplama hasarı %50 artar (52.5) | 1+ | `stab_sword.gd` |
| `stab` | Nadir | 3 | Savaş Çığlığı | Saplama menzili %50 artar (1620 px) | 1+ | `stab_sword.gd` |
| `orbit` | Ender | 1 | Ares'in Yörüngesi | Etrafında dönen 1 kılıç (15 hasar, 0.5 sn vuruş aralığı) | 1+ | `orbiting_swords.gd` |
| `orbit` | Ender | 2 | Ares'in Yörüngesi II | 2 kılıç | 1+ | `orbiting_swords.gd` |
| `orbit` | Ender | 3 | Ares'in Yörüngesi III | 3 kılıç | 1+ | `orbiting_swords.gd` |
| `bolt` | Ender | 1 | Athena'nın Kargısı | 4 sn'de bir en yakın düşmana kargı (30 hasar) | 1+ | `bolt_shooter.gd` |
| `bolt` | Ender | 2 | Hızlı Kargı | Bekleme 2 sn'ye iner | 1+ | `bolt_shooter.gd` |
| `bolt` | Ender | 3 | Güçlü Kargı | Hasar iki katına çıkar (60) | 1+ | `bolt_shooter.gd` |
| `bolt` | Ender | 4 | İkiz Kargı | Aynı anda 2 ayrı hedefe atış | 1+ | `bolt_shooter.gd` |
| `discus` | Ender | 1 | Olimpiyat Diski | 6 sn'de bir gidip geri dönen disk (20 hasar, her bacakta düşman başına 1 vuruş) | 1+ | `discus_thrower.gd`, `discus.gd` |
| `discus` | Ender | 2 | Olimpiyat Diski II | Bekleme 4 sn'ye iner | 1+ | `discus_thrower.gd` |
| `discus` | Ender | 3 | Şampiyon Diski | Hasar %60 artar (32), disk hızlanır | 1+ | `discus_thrower.gd` |
| `freeze` | Destansı | 1 | Boreas'ın Soluğu | 10 sn'de bir 1000 px içindeki düşmanları 1.5 sn dondurur | 1+ | `freeze_nova.gd` |
| `freeze` | Destansı | 2 | Boreas'ın Soluğu II | Sıklık 7 sn, donma 2.5 sn | 1+ | `freeze_nova.gd` |
| `freeze` | Destansı | 3 | Kuzeyin Öfkesi | Donma alanı 1450 px olur | 1+ | `freeze_nova.gd` |
| `styx` | **Efsanevi** | 1 | Styx'in Halkası | Çevredeki 420 px içindeki düşmanlara 0.5 sn'de bir 9 hasar (sürekli aura) | 1+ | `styx_aura.gd` |
| `styx` | **Efsanevi** | 2 | Styx'in Halkası II | Tik hasarı 15 olur | 1+ | `styx_aura.gd` |
| `styx` | **Efsanevi** | 3 | Kara Irmak | Halka yarıçapı 560 px olur | 1+ | `styx_aura.gd` |
| `speed` | Sıradan | 1 | Hermes'in Sandalı | Hareket hızı +%10 | 1+ | `player.gd` (`_physics_process`) |
| `speed` | Sıradan | 2 | Hermes'in Sandalı II | Hareket hızı toplam +%20 | 1+ | `player.gd` |
| `vitality` | Sıradan | 1-3 | Hygieia'nın Lütfu I-III | Her biri +25 azami can ve anında iyileşme | 1+ | `player.gd` (`_on_upgrades_changed`) |
| `kronos` | Destansı | 1 | Kronos'un Kumu | Tüm düşmanlar kalıcı %12 yavaşlar (bosslar dahil) | 1+ | `enemy.gd` (`KRONOS_SLOW_PER_TIER`) |
| `kronos` | Destansı | 2 | Kronos'un Kumu II | Yavaşlama toplam %24 | 1+ | `enemy.gd` |
| `kronos` | Destansı | 3 | Zamanın Ağırlığı | Yavaşlama toplam %36 | 1+ | `enemy.gd` |
| `artemis` | Ender | 1 | Artemis'in Oku | 6 sn'de bir hattaki tüm düşmanları delip geçen ok (25 hasar) | 1+ | `arrow_shooter.gd`, `arrow.gd` |
| `artemis` | Ender | 2 | Artemis'in Oku II | Bekleme 4 sn'ye iner | 1+ | `arrow_shooter.gd` |
| `artemis` | Ender | 3 | Gümüş Ok | Ok hasarı iki katına çıkar (50) | 1+ | `arrow_shooter.gd` |
| `magnet` | Sıradan | 1 | Kehribar Tılsımı | XP taşı çekim menzili 1.1 katına çıkar | 1+ | `xp_gem.gd` (`MAGNET_MULT`) |
| `magnet` | Sıradan | 2 | Kehribar Tılsımı II | Çekim menzili 2 katına çıkar | 1+ | `xp_gem.gd` |
| `nova` | Destansı | 1 | Aigis Kalkanı | 6 sn'de bir çevreye (720 px) yıldırım şoku, 25 hasar | **2+** | `lightning_nova.gd` |
| `nova` | Destansı | 2 | Fırtına Yüreği | Şok sıklığı 4 sn'ye çıkar | **2+** | `lightning_nova.gd` |
| `nova` | Destansı | 3 | Gök Gürültüsü | Hasar 40, alan 950 px | **2+** | `lightning_nova.gd` |
| `armor` | Nadir | 1 | Hephaistos Zırhı | Alınan tüm hasar %20 azalır | **2+** | `player.gd` (`ARMOR_REDUCTION`) |
| `armor` | Nadir | 2 | Hephaistos Zırhı II | Azalma toplam %35 olur | **2+** | `player.gd` |
| `bloodprice` | Nadir | 1 | Kan Bedeli | Düşman ölümünde %10 ihtimalle 5 can | **2+** | `player.gd` (`_on_enemy_killed`) |
| `bloodprice` | Nadir | 2 | Kan Bedeli II | İhtimal %20, iyileşme 8 can | **2+** | `player.gd` |

Notlar:
- **Styx'in Halkası** nişan almaz, bekleme süresi yoktur: halka sürekli açıktır ve
  içine giren her düşman erir. Efsanevi olmasının sebebi bu — tek kartla tam
  çevre kaplama sağlıyor.
- Bosslar donmaya (**Boreas'ın Soluğu**) bağışıktır (`boss_base.gd` → `freeze()`).
- **Kronos'un Kumu** donmanın aksine bossları da yavaşlatır (`enemy.gd` → `speed_multiplier()`).
- **Artemis'in Oku** düşmanları delip geçer, duvarlarda da durmaz; her ok aynı düşmana bir kez vurur.
- Disk, gidiş ve dönüş yolunda ayrı ayrı vurur; duvarlardan geçer.
- Eski "Büyü Işını" hattı temaya uymadığı için **Athena'nın Kargısı**na çevrildi
  (id `bolt` olarak kaldı; sahne/script adları da aynı).
- Kart adları Olympus temasına göre yenilendi; **id'ler değişmedi**, dolayısıyla
  kaydedilmiş ilerleme ve script kontrolleri etkilenmez.

**Havuz büyüklüğü:** Bölüm 1'de 11 hat (32 kart), Bölüm 2-3'te 14 hat (39 kart).
Bölüm 2+ kartları ölümsüzlük gittikten sonra anlam kazandığı için kısıtlı
(`min_chapter: 1`).

## Yeni kart nasıl eklenir

1. `game_state.gd` → `UPGRADE_TRACKS`'e yeni hat ekle
   (`name`, `icon`, `rarity`, `min_chapter` + `tiers`) ve `assets/icons/`e ikon
   SVG'si koy. `rarity` zorunlu — kartın çerçeve rengi ve çekiliş ağırlığı buradan.
2. Etkiyi uygula: ya mevcut bir scripte `GameState.upgrade_tier("id")` kontrolü,
   ya da yeni silahsa `scenes/weapons/` altına sahne + script yazıp
   `player.tscn`'e çocuk olarak ekle (örnek: `styx_aura.tscn`).
3. Silah scriptinde `GameState.upgrades_changed` ve `GameState.powers_changed`
   sinyallerine bağlanıp `_refresh()` ile aç/kapa yap (bölüm geçişindeki
   sıfırlama bu sinyallerle otomatik çalışır).

## İlgili diğer denge değerleri

| Ne | Değer | Yer |
|---|---|---|
| Oyuncu hızı | 1100 | `player.gd` → `move_speed` |
| Düşman hızları | temel 395, hızlı 660, tank 230 | `enemy.gd`, `enemy*.tscn` → `move_speed` |
| Boss hızları | boss1 360, boss2 460, boss3 295 | `boss*.tscn` → `move_speed` |
| XP eşiği | seviye × 10 (10, 20, 30...) | `game_state.gd` → `XP_STEP` |
| XP taşı değeri | temel/hızlı 1, tank 3 | `enemy*.tscn` → `xp_value` |
| XP taşı çekim menzili | 360 px (kartla 1.1x / 2x) | `xp_gem.gd` |
| Can küresi | +15 can; %6 şans (tank %15) | `health_orb.gd`, `enemy*.tscn` |
| Bölüm kotaları | 40 / 60 / 80 | `level_1/2/3.tscn` → `kill_quota` (Inspector) |
| Düşman canları | temel 30, hızlı 15, tank 90 | `enemy*.tscn` (Inspector) |
| Kart sayısı (menü) | 3 | `level.gd` → `pick_upgrade_options()` |
