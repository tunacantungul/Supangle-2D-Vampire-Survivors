# Kum + Çimen tileset'i

Kaynak: `resources/kum_cimen_tileset.tres`
Sahne: `scenes/levels/ground_layers.tscn` (iki katman: `Kum` altta, `Cimen` üstte)

Üç atlas, her biri 384×384 → 128×128'lik 3×3 = 9 kare:

| Kaynak | Dosya | Ne işe yarıyor |
|---|---|---|
| 0 | `Kum.png` | Zemin. 9 dolu kum varyantı. |
| 1 | `Grass.png` | Çimen yaması. Ortası dolu, kenarları dışa doğru soluyor. |
| 2 | `Grass_2.png` | Çimen çerçevesi (ortası boş halka). Elle yerleştirilir. |

## Arazi (terrain) kuralları

İki ayrı **terrain set** var; ayrı olmalarının sebebi ikisinin farklı
katmanlarda çalışması — aynı sette olsalardı Godot ikisi arasında geçiş
yapmaya çalışırdı.

| Set | Arazi | Mod | Kaynak |
|---|---|---|---|
| 0 | Çimen | Match Sides | `Grass.png` |
| 1 | Kum | Match Sides | `Kum.png` |

**Kum** — 9 karenin hepsine "her yanı kum" biti verildi. Godot eşleşen
kareler arasından rastgele seçtiği için, Kum arazisiyle boyayınca zemin
kendiliğinden çeşitleniyor; aynı desen tekrar etmiyor.

**Çimen** — klasik 3×3 yerleşim. Her kare, çimenin devam ettiği yönleri
işaretliyor:

```
(0,0) sağ+alt      (1,0) sol+sağ+alt      (2,0) sol+alt
(0,1) üst+sağ+alt  (1,1) dört yön (dolu)  (2,1) üst+sol+alt
(0,2) üst+sağ      (1,2) üst+sol+sağ      (2,2) üst+sol
```

## Nasıl map yapılır

1. Bölüm sahnesine `ground_layers.tscn`'i çocuk olarak ekle (ya da mevcut
   `Ground` düğümünün yanına iki `TileMapLayer` koyup tileset'i ata).
2. `Kum` katmanını seç → TileMap panelinde **Terrains** sekmesi → set 1,
   "Kum" → tüm haritayı boya. Alt zemin hazır.
3. `Cimen` katmanını seç → **Terrains** → set 0, "Çimen" → çimen istediğin
   yerleri boya. Kenarlar otomatik oturur.
4. Süs için `Grass_2` karelerini üst katmana elle serpiştir.

`Cimen` katmanının `z_index`'i 1; kum katmanının üstünde çizilsin diye.

## Bilinen sınır

Godot'nun "Match Sides" modu 16 komşuluk kombinasyonu tanır, elimizde ise
9 kare var. Yani her kombinasyonun birebir karşılığı yok — örneğin tek
başına duran bir çimen karesi ya da çapraz bağlantılar için tam eşleşme
bulunmuyor. Godot bu durumda en çok bite uyan kareyi seçiyor, sonuç
genellikle kabul edilebilir görünüyor ama kusursuz değil.

Kusursuz geçiş istenirse `Grass.png` 16 kareye (4×4) çıkarılmalı:
mevcut 9 kareye ek olarak tek başına duran kare, uç kareler (yalnızca bir
yönde devam eden) ve yatay/dikey koridor kareleri.
