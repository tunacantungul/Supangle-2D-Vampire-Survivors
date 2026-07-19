extends PanelContainer
## Tek bir alınmış güç kutucuğu: ikon + "Ad  Sv N".
## HUD'un sol panelinde ve kart menüsünün üst satırında kullanılır.
## Önce ağaca ekleyin, sonra setup() çağırın.

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel

## HUD'un sol panelindeki dar kutucuğun sabit ölçüsü. Kart menüsündeki liste
## gücün tam adını yazdığı için orada kullanılmıyor.
const COMPACT_SIZE := Vector2(110, 44)

## rarity_color verilirse kutucuğun çerçevesi o renge boyanır; nadirliği
## soldaki listede de tek bakışta okuyabilelim diye.
## compact: HUD listesi için. Kapsayıcı VBoxContainer çocuklarını kendi
## genişliğine yaydığı için, kısa metne rağmen kutucuk 278 px kalıyordu;
## bu modda içeriğine göre daralıyor.
func setup(
	icon_texture: Texture2D,
	text: String,
	rarity_color: Color = Color.TRANSPARENT,
	compact: bool = false
) -> void:
	icon.texture = icon_texture
	name_label.text = text
	if compact:
		size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		custom_minimum_size = COMPACT_SIZE
	if rarity_color.a <= 0.0:
		return
	var style := (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.border_color = rarity_color
	add_theme_stylebox_override("panel", style)
