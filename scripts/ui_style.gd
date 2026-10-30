class_name UiStyle
## Gemeinsamer Look für Menü und Kämpferauswahl (im Stil von Smash Bros):
## dicke Spielschrift für Überschriften, schräge farbige Kacheln, dunkle Leisten.

const TITLE_FONT: Font = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY_FONT: Font = preload("res://assets/fonts/nunito_extrabold.tres")

const GOLD := Color(1, 0.84, 0.3)
const INK := Color(0.04, 0.04, 0.09)
const BAR := Color(0.07, 0.08, 0.15, 0.86)
## Schräge der Kacheln (wie bei Smash leicht nach rechts geneigt).
const SKEW := 0.18


## Label mit Schrift, Größe, Farbe und dunklem Rand.
static func label(text: String, size: int, color := Color.WHITE, title := false, outline := 8) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", TITLE_FONT if title else BODY_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Kachel-Hintergrund: schräg, mit Rand und Schatten. Ausgewählt leuchtet sie und bekommt einen weißen Rand.
static func tile(color: Color, selected: bool, skew := SKEW, radius := 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color if selected else Color(color.darkened(0.55), 0.88)
	s.skew = Vector2(skew, 0)
	s.set_corner_radius_all(radius)
	s.set_border_width_all(4 if selected else 2)
	s.border_color = Color.WHITE if selected else Color(color.lightened(0.15), 0.55)
	s.shadow_color = Color(color.lightened(0.3), 0.55) if selected else Color(0, 0, 0, 0.35)
	s.shadow_size = 14 if selected else 6
	s.shadow_offset = Vector2.ZERO if selected else Vector2(4, 5)
	s.content_margin_left = 26
	s.content_margin_right = 26
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


## Dunkle Karte für Texte (Info, Spielerkarten).
static func card(border: Color, alpha := 0.88) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(INK, alpha)
	s.set_corner_radius_all(12)
	s.set_border_width_all(3)
	s.border_color = border
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 6)
	s.set_content_margin_all(18)
	return s


## Kleine Taste wie auf dem Controller, z. B. [F] Bestätigen.
static func key_hint(key: String, text: String) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.95, 0.95, 1.0)
	s.set_corner_radius_all(6)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 0
	s.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", s)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := label(key, 16, INK, false, 0)
	chip.add_child(k)
	box.add_child(chip)
	box.add_child(label(text, 17, Color(1, 1, 1, 0.92), false, 4))
	return box


## Waagerechter Farbverlauf als Textur (für Abdunklungen hinter Menüs).
static func gradient(colors: PackedColorArray, offsets: PackedFloat32Array, vertical := false) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = colors
	g.offsets = offsets
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 8 if vertical else 256
	t.height = 256 if vertical else 8
	if vertical:
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(0, 1)
	return t


## Gemaltes Bild einer Map (für die Vorschau im Menü), "" wenn es keins gibt.
static func map_picture(map: Dictionary) -> String:
	var folder: String = map.scene.get_file().get_basename()
	for file in ["hintergrund.png", "hintergrund_scharf.jpg"]:
		var path := "res://assets/maps/%s/%s" % [folder, file]
		if ResourceLoader.exists(path):
			return path
	return ""
