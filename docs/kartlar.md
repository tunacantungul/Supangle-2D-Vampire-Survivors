# Supangle — Güç Kartları

Seviye atlayınca 3 rastgele kart sunulur. Kartlar **her bölüm başında sıfırlanır**
(bedel teması: güçler kalıcı değil). Aynı hattın kartları sırayla gelir
(ör. Dönen Kılıç II çıkması için önce Dönen Kılıç alınmış olmalı).

XP artık ölümle doğrudan gelmez: düşmanlar **XP taşı** düşürür, oyuncu taşları
toplayınca XP kazanır (Vampire Survivors tarzı). Taşlar oyuncu yaklaşınca
kendiliğinden çekilir; "Kehribar Tılsımı" kartı çekim menzilini büyütür.
Ayrıca bazı düşmanlar düşük şansla **can küresi** düşürür (+15 can; tank %15,
diğerleri %6 ihtimal — `enemy*.tscn` → `health_drop_chance`).

Kart başlıkları/açıklamaları, ikonları ve bölüm şartları tek yerden yönetilir:
[`game_state.gd`](../supangle/scripts/autoload/game_state.gd) → `UPGRADE_TRACKS`.
Sayısal denge değerleri ise ilgili silah/oyuncu scriptlerindeki `@export`larda.
Kart ikonları: `assets/icons/icon_<id>.svg`.

## Kart listesi

| Hat (id) | Kademe | Kart | Etkisi | Bölüm | Değerlerin yeri |
|---|---|---|---|---|---|
| `stab` | temel | *Kılıç Saplaması* | Başlangıç silahı: 2 sn'de bir menzildeki (240 px) en yakın düşmana saplama, 35 hasar | 1+ | `stab_sword.gd` |
| `stab` | 1 | Çift Saplama | Art arda 2 saplama, sonra bekleme | 1+ | `stab_sword.gd` |
| `stab` | 2 | Keskin Kılıç | Saplama hasarı %50 artar (52.5) | 1+ | `stab_sword.gd` |
| `stab` | 3 | Savaş Çığlığı | Saplama menzili %50 artar (360 px) | 1+ | `stab_sword.gd` |
| `orbit` | 1 | Dönen Kılıç | Etrafında dönen 1 kılıç (15 hasar, 0.5 sn vuruş aralığı) | 1+ | `orbiting_swords.gd` |
| `orbit` | 2 | Dönen Kılıç II | 2 kılıç | 1+ | `orbiting_swords.gd` |
| `orbit` | 3 | Dönen Kılıç III | 3 kılıç | 1+ | `orbiting_swords.gd` |
| `bolt` | 1 | Kargı | 8 sn'de bir en yakın düşmana kargı (30 hasar) | 1+ | `bolt_shooter.gd` |
| `bolt` | 2 | Hızlı Kargı | Bekleme 4 sn'ye iner | 1+ | `bolt_shooter.gd` |
| `bolt` | 3 | Güçlü Kargı | Hasar iki katına çıkar (60) | 1+ | `bolt_shooter.gd` |
| `bolt` | 4 | İkiz Kargı | Aynı anda 2 ayrı hedefe atış | 1+ | `bolt_shooter.gd` |
| `discus` | 1 | Olimpiyat Diski | 6 sn'de bir gidip geri dönen disk (20 hasar, her bacakta düşman başına 1 vuruş) | 1+ | `discus_thrower.gd`, `discus.gd` |
| `discus` | 2 | Olimpiyat Diski II | Bekleme 4 sn'ye iner | 1+ | `discus_thrower.gd` |
| `discus` | 3 | Şampiyon Diski | Hasar %60 artar (32), disk hızlanır | 1+ | `discus_thrower.gd` |
| `freeze` | 1 | Boreas'ın Soluğu | 10 sn'de bir 220 px içindeki düşmanları 1.5 sn dondurur | 1+ | `freeze_nova.gd` |
| `freeze` | 2 | Boreas'ın Soluğu II | Sıklık 7 sn, donma 2.5 sn | 1+ | `freeze_nova.gd` |
| `freeze` | 3 | Kuzeyin Öfkesi | Donma alanı 320 px olur | 1+ | `freeze_nova.gd` |
| `speed` | 1 | Rüzgar Adımı | Hareket hızı +%20 | 1+ | `player.gd` (`_physics_process`) |
| `speed` | 2 | Rüzgar Adımı II | Hareket hızı toplam +%40 | 1+ | `player.gd` |
| `vitality` | 1-3 | Yaşam Gücü I-III | Her biri +25 azami can ve anında iyileşme | 1+ | `player.gd` (`_on_upgrades_changed`) |
| `magnet` | 1 | Kehribar Tılsımı | XP taşı çekim menzili 2.2 katına çıkar | 1+ | `xp_gem.gd` (`MAGNET_MULT`) |
| `magnet` | 2 | Kehribar Tılsımı II | Çekim menzili 4 katına çıkar | 1+ | `xp_gem.gd` |
| `nova` | 1 | Yıldırım Kalkanı | 6 sn'de bir çevreye (160 px) yıldırım şoku, 25 hasar | **2+** | `lightning_nova.gd` |
| `nova` | 2 | Fırtına Yüreği | Şok sıklığı 4 sn'ye çıkar | **2+** | `lightning_nova.gd` |
| `nova` | 3 | Gök Gürültüsü | Hasar 40, alan 210 px | **2+** | `lightning_nova.gd` |
| `armor` | 1 | Kalıntı Zırh | Alınan tüm hasar %20 azalır | **2+** | `player.gd` (`ARMOR_REDUCTION`) |
| `armor` | 2 | Kalıntı Zırh II | Azalma toplam %35 olur | **2+** | `player.gd` |
| `bloodprice` | 1 | Kan Bedeli | Düşman ölümünde %10 ihtimalle 5 can | **2+** | `player.gd` (`_on_enemy_killed`) |
| `bloodprice` | 2 | Kan Bedeli II | İhtimal %20, iyileşme 8 can | **2+** | `player.gd` |

Notlar:
- Bosslar donmaya (**Boreas'ın Soluğu**) bağışıktır (`boss_base.gd` → `freeze()`).
- Disk, gidiş ve dönüş yolunda ayrı ayrı vurur; duvarlardan geçer.
- Eski "Büyü Işını" hattı temaya uymadığı için **Kargı**ya çevrildi
  (id `bolt` olarak kaldı; sahne/script adları da aynı).

**Havuz büyüklüğü:** Bölüm 1'de 8 hat (23 kart), Bölüm 2-3'te 11 hat (30 kart).
Bölüm 2+ kartları ölümsüzlük gittikten sonra anlam kazandığı için kısıtlı
(`min_chapter: 1`).

## Yeni kart nasıl eklenir

1. `game_state.gd` → `UPGRADE_TRACKS`'e yeni hat ekle
   (`name`, `icon`, `min_chapter` + `tiers`) ve `assets/icons/`e ikon SVG'si koy.
2. Etkiyi uygula: ya mevcut bir scripte `GameState.upgrade_tier("id")` kontrolü,
   ya da yeni silahsa `scenes/weapons/` altına sahne + script yazıp
   `player.tscn`'e çocuk olarak ekle (örnek: `freeze_nova.tscn`).
3. Silah scriptinde `GameState.upgrades_changed` ve `GameState.powers_changed`
   sinyallerine bağlanıp `_refresh()` ile aç/kapa yap (bölüm geçişindeki
   sıfırlama bu sinyallerle otomatik çalışır).

## İlgili diğer denge değerleri

| Ne | Değer | Yer |
|---|---|---|
| XP eşiği | seviye × 10 (10, 20, 30...) | `game_state.gd` → `XP_STEP` |
| XP taşı değeri | temel/hızlı 1, tank 3 | `enemy*.tscn` → `xp_value` |
| XP taşı çekim menzili | 80 px (kartla 2.2x / 4x) | `xp_gem.gd` |
| Can küresi | +15 can; %6 şans (tank %15) | `health_orb.gd`, `enemy*.tscn` |
| Bölüm kotaları | 40 / 60 / 80 | `level_1/2/3.tscn` → `kill_quota` (Inspector) |
| Düşman canları | temel 30, hızlı 15, tank 90 | `enemy*.tscn` (Inspector) |
| Kart sayısı (menü) | 3 | `level.gd` → `pick_upgrade_options()` |
