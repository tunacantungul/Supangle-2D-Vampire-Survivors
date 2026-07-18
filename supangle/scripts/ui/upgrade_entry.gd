extends PanelContainer
## Tek bir alınmış güç kutucuğu: ikon + "Ad  Sv N".
## HUD'un sol panelinde ve kart menüsünün üst satırında kullanılır.
## Önce ağaca ekleyin, sonra setup() çağırın.

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel

## rarity_color verilirse kutucuğun çerçevesi o renge boyanır; nadirliği
## soldaki listede de tek bakışta okuyabilelim diye.
func setup(icon_texture: Texture2D, text: String, rarity_color: Color = Color.TRANSPARENT) -> void:
	icon.texture = icon_texture
	name_label.text = text
	if rarity_color.a <= 0.0:
		return
	var style := (get_theme_stylebox("panel") as StyleBoxFlat).duplicate() as StyleBoxFlat
	style.border_color = rarity_color
	add_theme_stylebox_override("panel", style)
