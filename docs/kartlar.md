# Supangle — Güç Kartları

Seviye atlayınca 3 rastgele kart sunulur. Kartlar **her bölüm başında sıfırlanır**
(bedel teması: güçler kalıcı değil). Aynı hattın kartları sırayla gelir
(ör. Dönen Kılıç II çıkması için önce Dönen Kılıç alınmış olmalı).

Kart başlıkları/açıklamaları ve bölüm şartları tek yerden yönetilir:
[`game_state.gd`](../supangle/scripts/autoload/game_state.gd) → `UPGRADE_TRACKS`.
Sayısal denge değerleri ise ilgili silah/oyuncu scriptlerindeki `@export`larda.

## Kart listesi

| Hat (id) | Kademe | Kart | Etkisi | Bölüm | Değerlerin yeri |
|---|---|---|---|---|---|
| `stab` | temel | *Kılıç Saplaması* | Başlangıç silahı: 3 sn'de bir menzildeki (240 px) en yakın düşmana saplama, 35 hasar | 1+ | `stab_sword.gd` |
| `stab` | 1 | Çift Saplama | Art arda 2 saplama, sonra bekleme | 1+ | `stab_sword.gd` |
| `stab` | 2 | Keskin Kılıç | Saplama hasarı %50 artar (52.5) | 1+ | `stab_sword.gd` |
| `stab` | 3 | Savaş Çığlığı | Saplama menzili %50 artar (360 px) | 1+ | `stab_sword.gd` |
| `orbit` | 1 | Dönen Kılıç | Etrafında dönen 1 kılıç (15 hasar, 0.5 sn vuruş aralığı) | 1+ | `orbiting_swords.gd` |
| `orbit` | 2 | Dönen Kılıç II | 2 kılıç | 1+ | `orbiting_swords.gd` |
| `orbit` | 3 | Dönen Kılıç III | 3 kılıç | 1+ | `orbiting_swords.gd` |
| `bolt` | 1 | Büyü Işını | 15 sn'de bir en yakın düşmana ışın (40 hasar) | 1+ | `bolt_shooter.gd` |
| `bolt` | 2 | Hızlı Işın | Bekleme 8 sn'ye iner | 1+ | `bolt_shooter.gd` |
| `bolt` | 3 | Güçlü Işın | Hasar iki katına çıkar (80) | 1+ | `bolt_shooter.gd` |
| `bolt` | 4 | İkiz Işın | Aynı anda 2 ayrı hedefe atış | 1+ | `bolt_shooter.gd` |
| `speed` | 1 | Rüzgar Adımı | Hareket hızı +%20 | 1+ | `player.gd` (`_physics_process`) |
| `speed` | 2 | Rüzgar Adımı II | Hareket hızı toplam +%40 | 1+ | `player.gd` |
| `vitality` | 1-3 | Yaşam Gücü I-III | Her biri +25 azami can ve anında iyileşme | 1+ | `player.gd` (`_on_upgrades_changed`) |
| `nova` | 1 | Yıldırım Kalkanı | 6 sn'de bir çevreye (160 px) yıldırım şoku, 25 hasar | **2+** | `lightning_nova.gd` |
| `nova` | 2 | Fırtına Yüreği | Şok sıklığı 4 sn'ye çıkar | **2+** | `lightning_nova.gd` |
| `nova` | 3 | Gök Gürültüsü | Hasar 40, alan 210 px | **2+** | `lightning_nova.gd` |
| `armor` | 1 | Kalıntı Zırh | Alınan tüm hasar %20 azalır | **2+** | `player.gd` (`ARMOR_REDUCTION`) |
| `armor` | 2 | Kalıntı Zırh II | Azalma toplam %35 olur | **2+** | `player.gd` |
| `bloodprice` | 1 | Kan Bedeli | Düşman ölümünde %10 ihtimalle 5 can | **2+** | `player.gd` (`_on_enemy_killed`) |
| `bloodprice` | 2 | Kan Bedeli II | İhtimal %20, iyileşme 8 can | **2+** | `player.gd` |

**Havuz büyüklüğü:** Bölüm 1'de 5 hat (13 kart), Bölüm 2-3'te 8 hat (22 kart).
Bölüm 2+ kartları ölümsüzlük gittikten sonra anlam kazandığı için kısıtlı
(`min_chapter: 1`).

## Yeni kart nasıl eklenir

1. `game_state.gd` → `UPGRADE_TRACKS`'e yeni hat ekle (`min_chapter` + `tiers`).
2. Etkiyi uygula: ya mevcut bir scripte `GameState.upgrade_tier("id")` kontrolü,
   ya da yeni silahsa `scenes/weapons/` altına sahne + script yazıp
   `player.tscn`'e çocuk olarak ekle (örnek: `lightning_nova.tscn`).
3. Silah scriptinde `GameState.upgrades_changed` ve `GameState.powers_changed`
   sinyallerine bağlanıp `_refresh()` ile aç/kapa yap (bölüm geçişindeki
   sıfırlama bu sinyallerle otomatik çalışır).

## İlgili diğer denge değerleri

| Ne | Değer | Yer |
|---|---|---|
| XP eşiği | seviye × 10 (10, 20, 30...) | `game_state.gd` → `XP_STEP` |
| Ölüm başına XP | 1 | `game_state.gd` → `XP_PER_KILL` |
| Bölüm kotaları | 40 / 60 / 80 | `level_1/2/3.tscn` → `kill_quota` (Inspector) |
| Düşman canları | temel 30, hızlı 15, tank 90 | `enemy*.tscn` (Inspector) |
| Kart sayısı (menü) | 3 | `level.gd` → `pick_upgrade_options()` |
