extends Node3D
## Hauptmenü mit Optionen, im Stil von Smash Bros: links schräge farbige Kacheln,
## rechts stehen die zuletzt gewählten Kämpfer in der Map, unten eine Info-Karte.
## Steuerung: W/S oder Pfeile hoch/runter wählen, A/D oder Pfeile links/rechts ändern
## (bei Kacheln nebeneinander: wechseln), F, J oder Enter bestätigen, Esc zurück.
## Mit der Maus geht es auch: drüberfahren wählt, klicken bestätigt.

enum Page { MAIN, OPTIONS, CONTROLS }

## Linke Spalte mit den Kacheln.
const COLUMN_X := 70.0
const COLUMN_W := 540.0
const ROW_GAP := 10.0
const GROUP_GAP := 22.0
## So weit rutscht die gewählte Kachel nach rechts.
const SELECTED_SHIFT := 18.0

## Farbe jeder Kachel.
const COLORS := {
	"play": Color(0.9, 0.18, 0.2), "campaign": Color(0.9, 0.18, 0.2), "campaign_new": Color(0.95, 0.5, 0.12),
	"targets": Color(0.2, 0.68, 0.3), "boss": Color(0.55, 0.28, 0.85),
	"options": Color(0.18, 0.48, 0.95), "controls": Color(0.08, 0.62, 0.68), "quit": Color(0.42, 0.42, 0.5),
	"back": Color(0.42, 0.42, 0.5), "reset": Color(0.95, 0.5, 0.12),
}
## Einstell-Leisten (Wert mit ◀ ▶ ändern).
const SELECTOR_COLOR := Color(0.26, 0.32, 0.6)
const TILE_TEXTS := {
	"play": ["KAMPF", "Zwei Spieler, eine Arena"],
	"targets": ["ZIELE", "Gegen die Uhr"],
	"boss": ["ENDBOSS", "Riesen-Kampfroboter"],
	"campaign_new": ["NEU BEGINNEN", "Kampagne von vorne"],
	"options": ["OPTIONEN", ""],
	"controls": ["STEUERUNG", ""],
	"quit": ["BEENDEN", ""],
	"back": ["ZURÜCK", ""],
	"reset": ["STANDARD", ""],
}

var page := Page.MAIN
var row := 0
var col := 0
var time := 0.0
var map_node: Node3D
## Die zwei Kämpfer, die rechts im Bild stehen.
var fighters: Array = []
## Dahin schaut die Kamera (links neben den Kämpfern, damit sie rechts im Bild stehen).
var focus := Vector3(-2.3, 0, 0)
var podiums: Array = []
## Podeste stehen so weit vor der Bühne und sind so hoch.
const PODIUM_Z := 2.2
const PODIUM_HEIGHT := 0.22
## Spieler, dessen Tasten gerade auf der Steuerungs-Seite angezeigt werden.
var controls_player := 1
## Aktion, die gerade auf einen Tastendruck wartet ("" = keine).
var waiting_action := ""
## Nach dem Belegen einer Taste wird der Tastendruck nicht gleich als Menü-Eingabe gewertet.
var ignore_input_frames := 0
## Je Eintrag: {"panel", "home" (Grundposition), "title", "value", "sub"} für die Anzeige.
var tiles := {}

@onready var camera: Camera3D = $Camera3D
@onready var ui: CanvasLayer = $UI
var page_root: Control
var info_card: PanelContainer
var info_title: Label
var info_text: Label
var info_picture: TextureRect
var esc_hint: Control


func _ready() -> void:
	# Im Menü läuft keine Kampagne: Map-Auswahl und Modi gelten wieder wie eingestellt.
	Settings.campaign = false
	_load_map()
	_spawn_fighters()
	_build_frame()
	_open(Page.MAIN)
	Audio.music("menu")


func _process(delta: float) -> void:
	time += delta
	# Kamera schwebt langsam vor den Kämpfern hin und her; die Kämpfer stehen rechts im Bild.
	camera.position = focus + Vector3(sin(time * 0.18) * 0.7, 1.75 + sin(time * 0.13) * 0.15, 7.2)
	camera.look_at(focus + Vector3(0, 0.9, 0))
	_animate_tiles(delta)

	if waiting_action != "":
		return
	if ignore_input_frames > 0:
		ignore_input_frames -= 1
		return

	var rows := _rows()
	if _pressed(["p1_up", "p2_up", "ui_up"]):
		var up := wrapi(row - 1, 0, rows.size())
		_select(up, _nearest_col(up))
	elif _pressed(["p1_down", "p2_down", "ui_down"]):
		var down := wrapi(row + 1, 0, rows.size())
		_select(down, _nearest_col(down))
	elif _pressed(["p1_left", "p2_left", "ui_left"]):
		_side(-1)
	elif _pressed(["p1_right", "p2_right", "ui_right"]):
		_side(1)
	elif _pressed(["p1_weak", "p2_weak", "ui_accept"]):
		_activate(_current())
	elif Input.is_action_just_pressed("back") and page != Page.MAIN:
		Audio.sfx("menu_back")
		_open(Page.MAIN, "options" if page == Page.OPTIONS else "controls")


## Wartet auf die neue Taste für eine Aktion (Tastatur oder Gamepad). Esc bricht ab.
func _input(event: InputEvent) -> void:
	if waiting_action == "" or not event.is_pressed() or event.is_echo():
		return
	var accepted := false
	if event is InputEventKey:
		if event.physical_keycode == KEY_ESCAPE:
			waiting_action = ""
			Audio.sfx("menu_back")
			ignore_input_frames = 2
			_refresh()
			get_viewport().set_input_as_handled()
			return
		var key := InputEventKey.new()
		key.physical_keycode = event.physical_keycode
		Settings.rebind(waiting_action, key)
		accepted = true
	elif event is InputEventJoypadButton:
		var button := InputEventJoypadButton.new()
		button.button_index = event.button_index
		button.device = event.device
		Settings.rebind(waiting_action, button)
		accepted = true
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.6:
		var motion := InputEventJoypadMotion.new()
		motion.axis = event.axis
		motion.axis_value = signf(event.axis_value)
		motion.device = event.device
		Settings.rebind(waiting_action, motion)
		accepted = true
	if accepted:
		waiting_action = ""
		ignore_input_frames = 2
		Audio.sfx("menu_select")
		_refresh()
		get_viewport().set_input_as_handled()


## Die Einträge der Seite als Zeilen. Mehrere Einträge in einer Zeile stehen nebeneinander.
func _rows() -> Array:
	match page:
		Page.OPTIONS:
			return [["items"], ["rate"], ["stocks"], ["map_effects"], ["special_charge"], ["graphics"],
				["music"], ["sfx"], ["back"]]
		Page.CONTROLS:
			var list := [["player"]]
			for a in Settings.BINDABLE:
				list.append(["key:" + a])
			list.append(["reset", "back"])
			return list
	if Settings.solo:
		# Solo ist eine durchgehende Kampagne: keine Map- oder Gegnerauswahl.
		if Settings.campaign_stage > 0:
			return [["mode"], ["campaign"], ["campaign_new"], ["options", "controls", "quit"]]
		return [["mode"], ["campaign"], ["options", "controls", "quit"]]
	return [["mode"], ["map"], ["play"], ["targets", "boss"], ["options", "controls", "quit"]]


## Alle Einträge der Seite hintereinander.
func _entries() -> Array:
	var list := []
	for r in _rows():
		list.append_array(r)
	return list


func _current() -> String:
	var rows := _rows()
	var r: Array = rows[clampi(row, 0, rows.size() - 1)]
	return r[clampi(col, 0, r.size() - 1)]


## Vor diesen Einträgen ist etwas mehr Platz (neue Gruppe).
func _gap_before(entry: String) -> bool:
	if page == Page.OPTIONS:
		return entry == "back"
	return entry in ["play", "campaign", "options", "reset"]


func _is_selector(entry: String) -> bool:
	return entry in ["map", "mode", "cpu", "items", "rate", "stocks", "map_effects", "special_charge",
		"graphics", "music", "sfx", "player"] or entry.begins_with("key:")


## Höhe einer Kachel in Pixeln (bei 1280 x 720, wird auf größere Fenster hochskaliert).
func _tile_height(entry: String) -> float:
	if page == Page.CONTROLS:
		return 44.0 if entry in ["reset", "back"] else 37.0
	if page == Page.OPTIONS:
		return 44.0
	match entry:
		"play", "campaign": return 110.0
		"targets", "boss", "campaign_new": return 84.0
		"options", "controls", "quit": return 62.0
	return 58.0


## Name und Wert einer Einstell-Leiste.
func _selector_name(entry: String) -> String:
	if entry.begins_with("key:"):
		return Settings.ACTION_NAMES[entry.substr(4)]
	match entry:
		"map": return "MAP"
		"mode": return "MODUS"
		"cpu": return "COMPUTER"
		"items": return "Items"
		"rate": return "Item-Häufigkeit"
		"stocks": return "Leben"
		"map_effects": return "Map-Effekte"
		"special_charge": return "Spezial aufladen"
		"graphics": return "Grafik"
		"music": return "Musik"
		"sfx": return "Geräusche & Stimmen"
		"player": return "Tasten von"
	return entry


func _selector_value(entry: String) -> String:
	if entry.begins_with("key:"):
		var action := "p%d_%s" % [controls_player, entry.substr(4)]
		return "Taste drücken …" if waiting_action == action else Settings.key_text(action)
	match entry:
		"map": return Settings.current_map().name
		"mode": return "Solo gegen Computer" if Settings.solo else "Zwei Spieler"
		"cpu": return CpuPlayer.LEVELS[Settings.cpu_level].name
		"items": return "An" if Settings.items_enabled else "Aus"
		"rate": return Settings.ITEM_RATES[Settings.item_rate]
		"stocks": return str(Settings.stocks)
		"map_effects": return "An" if Settings.map_effects else "Aus"
		"special_charge": return "An" if Settings.special_charge else "Aus"
		"graphics": return Settings.GRAPHICS[Settings.graphics]
		"music": return _bar(Settings.music_volume)
		"sfx": return _bar(Settings.sfx_volume)
		"player": return "Spieler %d" % controls_player
	return ""


## Überschrift und Untertitel einer Kachel.
func _tile_texts(entry: String) -> Array:
	if entry == "campaign":
		if Settings.campaign_stage == 0:
			return ["KAMPAGNE", "%d Kämpfe gegen den Computer" % Settings.CAMPAIGN.size()]
		return ["WEITER", "Kampagne: Kampf %d von %d" % [Settings.campaign_stage + 1, Settings.CAMPAIGN.size()]]
	return TILE_TEXTS.get(entry, [entry, ""])


## Überschrift, Text und Bild der Info-Karte für den gewählten Eintrag.
func _info(entry: String) -> Dictionary:
	if entry.begins_with("key:"):
		return {"title": "Taste ändern", "text": "F drücken, dann die neue Taste oder den Controller-Knopf.\nIst sie schon belegt, tauschen die beiden Aktionen. Esc bricht ab."}
	match entry:
		"play": return {"title": "Kampf", "text": "Zwei Spieler kämpfen auf der gewählten Map. Je mehr Schaden, desto weiter fliegt man. Wer alle Leben verliert, hat verloren."}
		"campaign", "campaign_new": return {"title": "Kampagne", "text": _campaign_info(entry == "campaign_new")}
		"targets": return {"title": "Ziele zerstören", "text": "Zerschlage alle Ziele der Map so schnell du kannst. Deine Bestzeit wird für jeden Kämpfer gespeichert."}
		"boss": return {"title": "Endboss", "text": "Allein gegen den Riesen-Kampfroboter mit Raketen und Laser. Schaffst du es, seine Lebensleiste zu leeren?"}
		"map":
			var map := Settings.current_map()
			return {"title": map.name, "picture": UiStyle.map_picture(map),
				"text": map.effect + ("" if Settings.map_effects else "\n(Map-Effekte sind ausgeschaltet)")}
		"mode": return {"title": "Modus", "text": "Zwei Spieler an einer Tastatur oder mit Controllern – oder allein gegen den Computer in der Kampagne."}
		"options": return {"title": "Optionen", "text": "Items, Leben, Map-Effekte, Grafik und Lautstärke einstellen."}
		"controls": return {"title": "Steuerung", "text": "Tasten und Controller-Knöpfe für beide Spieler ändern."}
		"quit": return {"title": "Beenden", "text": "Spiel schließen. Bis bald!"}
		"items": return {"title": "Items", "text": "Während des Kampfes fallen Gegenstände in die Arena, die man aufheben und benutzen kann."}
		"rate": return {"title": "Item-Häufigkeit", "text": "Wie oft neue Items erscheinen."}
		"stocks": return {"title": "Leben", "text": "So viele Leben hat jeder Spieler. Wer aus der Arena fliegt, verliert eins."}
		"map_effects": return {"title": "Map-Effekte", "text": "Jede Map hat ihr eigenes Ereignis, zum Beispiel Kanonen, Lava, Blitze oder Treibsand."}
		"special_charge": return {"title": "Spezial aufladen", "text": "Die Spezialattacke braucht eine volle Energieleiste. Sie füllt sich durch Treffen, Getroffenwerden und langsam mit der Zeit."}
		"graphics": return {"title": "Grafik", "text": "Hoch: schönste Optik mit Schatten und Leuchten.\nNiedrig: läuft auf schwachen PCs flüssiger."}
		"music": return {"title": "Musik", "text": "Lautstärke der Musik von 0 bis 10."}
		"sfx": return {"title": "Geräusche & Stimmen", "text": "Lautstärke der Treffer, Rufe und Menü-Geräusche von 0 bis 10."}
		"player": return {"title": "Spieler wählen", "text": "Mit A/D umschalten, wessen Tasten unten angezeigt werden."}
		"reset": return {"title": "Standard", "text": "Alle Tasten beider Spieler wieder wie am Anfang."}
		"back": return {"title": "Zurück", "text": "Zurück zum Hauptmenü. Alles ist schon gespeichert."}
	return {"title": "", "text": ""}


## Links/rechts: zwischen Kacheln nebeneinander wechseln oder den Wert einer Leiste ändern.
func _side(step: int) -> void:
	var r: Array = _rows()[row]
	if r.size() > 1:
		_select(row, wrapi(col + step, 0, r.size()))
	else:
		_change(r[0], step)


## Beim Wechsel in eine Zeile mit anderer Kachel-Anzahl die Kachel nehmen, die am nächsten darunter/darüber liegt.
func _nearest_col(new_row: int) -> int:
	var current: Dictionary = tiles.get(_current(), {})
	if current.is_empty():
		return col
	var x: float = current.home.x + current.panel.size.x / 2.0
	var best := 0
	var best_distance := INF
	var r: Array = _rows()[new_row]
	for c in r.size():
		var t: Dictionary = tiles.get(r[c], {})
		if t.is_empty():
			continue
		var distance := absf(t.home.x + t.panel.size.x / 2.0 - x)
		if distance < best_distance:
			best = c
			best_distance = distance
	return best


func _select(new_row: int, new_col: int) -> void:
	var rows := _rows()
	new_row = clampi(new_row, 0, rows.size() - 1)
	new_col = clampi(new_col, 0, rows[new_row].size() - 1)
	if new_row == row and new_col == col:
		return
	row = new_row
	col = new_col
	Audio.sfx("menu_move")
	_refresh()


func _change(entry: String, step: int) -> void:
	match entry:
		"map":
			Settings.map_index = wrapi(Settings.map_index + step, 0, Settings.MAPS.size())
			_load_map()
		"mode":
			Settings.solo = not Settings.solo
		"cpu":
			Settings.cpu_level = clampi(Settings.cpu_level + step, 0, CpuPlayer.LEVELS.size() - 1)
		"items":
			Settings.items_enabled = not Settings.items_enabled
		"rate":
			Settings.item_rate = clampi(Settings.item_rate + step, 0, Settings.ITEM_RATES.size() - 1)
		"stocks":
			Settings.stocks = clampi(Settings.stocks + step, 1, 9)
		"map_effects":
			Settings.map_effects = not Settings.map_effects
		"special_charge":
			Settings.special_charge = not Settings.special_charge
		"graphics":
			Settings.graphics = wrapi(Settings.graphics + step, 0, Settings.GRAPHICS.size())
		"music":
			Settings.music_volume = clampi(Settings.music_volume + step, 0, 10)
			Audio.apply_volume()
		"sfx":
			Settings.sfx_volume = clampi(Settings.sfx_volume + step, 0, 10)
			Audio.apply_volume()
		"player":
			controls_player = 2 if controls_player == 1 else 1
		_:
			return
	Audio.sfx("menu_move")
	Settings.save()
	if entry == "mode":
		# Solo und zwei Spieler haben andere Kacheln: Seite neu aufbauen, Modus bleibt gewählt.
		_open(Page.MAIN, "mode")
		return
	_refresh()
	_bump_value(entry, step)


func _activate(entry: String) -> void:
	if entry.begins_with("key:"):
		waiting_action = "p%d_%s" % [controls_player, entry.substr(4)]
		Audio.sfx("menu_select")
		_refresh()
		return
	match entry:
		"play", "targets", "boss":
			Settings.target_mode = entry == "targets"
			Settings.boss_mode = entry == "boss"
			Audio.sfx("menu_select")
			get_tree().change_scene_to_file("res://scenes/fight.tscn")
		"campaign", "campaign_new":
			if entry == "campaign_new" or Settings.campaign_opponents.is_empty():
				Settings.new_campaign()
			Settings.campaign = true
			Audio.sfx("menu_select")
			get_tree().change_scene_to_file("res://scenes/fight.tscn")
		"options":
			Audio.sfx("menu_select")
			_open(Page.OPTIONS)
		"controls":
			Audio.sfx("menu_select")
			_open(Page.CONTROLS)
		"quit":
			get_tree().quit()
		"back":
			Audio.sfx("menu_back")
			_open(Page.MAIN, "options" if page == Page.OPTIONS else "controls")
		"reset":
			Settings.reset_controls()
			Audio.sfx("menu_select")
			_refresh()
		_:
			if _is_selector(entry):
				_change(entry, 1)


## Seite öffnen. focus: dieser Eintrag ist gewählt (sonst im Hauptmenü der große Kampf-Knopf).
func _open(new_page: Page, focus := "") -> void:
	var rebuild := new_page != page or tiles.is_empty() or new_page == Page.MAIN
	var intro := new_page != page or tiles.is_empty()
	page = new_page
	row = 0
	col = 0
	if focus == "" and page == Page.MAIN:
		focus = "campaign" if Settings.solo else "play"
	var rows := _rows()
	for i in rows.size():
		if focus in rows[i]:
			row = i
			col = rows[i].find(focus)
	if rebuild:
		_build_page(intro)
	_refresh()


## Bleibt immer: Abdunklung links, Info-Karte unten rechts, Tastenleiste unten.
func _build_frame() -> void:
	var shade := TextureRect.new()
	shade.texture = UiStyle.gradient(PackedColorArray([Color(0.02, 0.02, 0.07, 0.88), Color(0.02, 0.02, 0.07, 0.55), Color(0.02, 0.02, 0.07, 0.0)]),
		PackedFloat32Array([0.0, 0.42, 0.62]))
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	var bottom_shade := TextureRect.new()
	bottom_shade.texture = UiStyle.gradient(PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.75)]), PackedFloat32Array([0.0, 1.0]), true)
	bottom_shade.stretch_mode = TextureRect.STRETCH_SCALE
	bottom_shade.position = Vector2(0, 560)
	bottom_shade.size = Vector2(1280, 160)
	bottom_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bottom_shade)

	page_root = Control.new()
	page_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	page_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(page_root)

	info_card = PanelContainer.new()
	info_card.add_theme_stylebox_override("panel", UiStyle.card(Color(1, 1, 1, 0.25)))
	# Unten rechts festgemacht: die Karte wächst mit dem Text nach oben.
	info_card.anchor_top = 1.0
	info_card.anchor_bottom = 1.0
	info_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info_card.offset_left = 712
	info_card.offset_right = 1232
	info_card.offset_bottom = -56
	info_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 16)
	info_card.add_child(info_row)
	info_picture = TextureRect.new()
	info_picture.custom_minimum_size = Vector2(150, 86)
	info_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	info_picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_row.add_child(info_picture)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 2)
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(info_box)
	info_title = UiStyle.label("", 28, UiStyle.GOLD, true)
	info_box.add_child(info_title)
	info_text = UiStyle.label("", 17, Color(1, 1, 1, 0.94), false, 4)
	info_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_text.custom_minimum_size = Vector2(484, 0)
	info_box.add_child(info_text)
	ui.add_child(info_card)

	var hints := HBoxContainer.new()
	hints.add_theme_constant_override("separation", 30)
	hints.position = Vector2(COLUMN_X, 680)
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for h in [["W / S", "Wählen"], ["A / D", "Ändern"], ["F / Enter", "Bestätigen"], ["Esc", "Zurück"]]:
		esc_hint = UiStyle.key_hint(h[0], h[1])
		hints.add_child(esc_hint)
	ui.add_child(hints)


## Kacheln der aktuellen Seite neu anlegen. intro: Kacheln fliegen von links herein.
func _build_page(intro: bool) -> void:
	for child in page_root.get_children():
		child.queue_free()
	tiles.clear()

	# Überschrift: im Hauptmenü das Logo, sonst der Name der Seite auf einem farbigen Band.
	var band := Panel.new()
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = UiStyle.GOLD if page == Page.MAIN else COLORS["options" if page == Page.OPTIONS else "controls"]
	band_style.skew = Vector2(0.45, 0)
	band.add_theme_stylebox_override("panel", band_style)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_root.add_child(band)
	var heading: Label
	if page == Page.MAIN:
		heading = UiStyle.label("ARENA-KAMPF", 84, UiStyle.GOLD, true, 22)
		heading.add_theme_color_override("font_outline_color", Color(0.22, 0.07, 0.0))
		heading.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		heading.add_theme_constant_override("shadow_offset_x", 5)
		heading.add_theme_constant_override("shadow_offset_y", 6)
		heading.position = Vector2(COLUMN_X - 6, 16)
		heading.rotation = deg_to_rad(-2.5)
		band.position = Vector2(COLUMN_X + 8, 112)
		band.size = Vector2(500, 8)
	else:
		heading = UiStyle.label("OPTIONEN" if page == Page.OPTIONS else "STEUERUNG", 62, Color.WHITE, true, 16)
		heading.position = Vector2(COLUMN_X, 22)
		band.position = Vector2(COLUMN_X + 4, 100)
		band.size = Vector2(380, 7)
	page_root.add_child(heading)

	var y := 150.0 if page == Page.MAIN else 128.0
	if page == Page.CONTROLS:
		y = 120.0
	var rows := _rows()
	var count := 0
	for r in rows.size():
		var entries: Array = rows[r]
		if r > 0 and _gap_before(entries[0]):
			y += GROUP_GAP - ROW_GAP
		var h := _tile_height(entries[0])
		var w := (COLUMN_W - (entries.size() - 1) * 14.0) / entries.size()
		for c in entries.size():
			var entry: String = entries[c]
			var home := Vector2(COLUMN_X + c * (w + 14.0), y)
			var panel := _make_tile(entry, Vector2(w, h))
			panel.position = home
			page_root.add_child(panel)
			tiles[entry]["home"] = home
			if intro:
				panel.position.x -= 70.0
				panel.modulate.a = 0.0
				var tw := panel.create_tween().set_parallel()
				tw.tween_property(panel, "position:x", home.x, 0.28).set_delay(count * 0.035).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(panel, "modulate:a", 1.0, 0.28).set_delay(count * 0.035)
			panel.mouse_entered.connect(_on_hover.bind(r, c))
			panel.gui_input.connect(_on_tile_input.bind(entry, panel))
			count += 1
		y += h + ROW_GAP


## Eine Kachel: entweder Knopf (Überschrift + Untertitel) oder Einstell-Leiste (Name ◀ Wert ▶).
func _make_tile(entry: String, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var info := {"panel": panel}
	if _is_selector(entry):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(line)
		var main := page == Page.MAIN
		var name_label := UiStyle.label(_selector_name(entry), 18 if main else (20 if page == Page.OPTIONS else 18), UiStyle.GOLD if main else Color.WHITE, false, 5)
		name_label.custom_minimum_size = Vector2(96 if main else 230, 0)
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(name_label)
		var left := UiStyle.label("◀", 20, Color(1, 1, 1, 0.8), false, 4)
		left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(left)
		var value := UiStyle.label("", 26 if main else (24 if page == Page.OPTIONS else 21), Color.WHITE, true, 8)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		value.clip_text = true
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.add_child(value)
		var right := UiStyle.label("▶", 20, Color(1, 1, 1, 0.8), false, 4)
		right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(right)
		info.merge({"value": value, "left": left, "right": right, "name": name_label})
	else:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", -4)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(box)
		var big := size.y >= 90.0
		var texts := _tile_texts(entry)
		var font_size := 52 if big else (34 if size.y >= 70.0 else (26 if page == Page.MAIN else 24 if size.y >= 44.0 else 22))
		var title := UiStyle.label(texts[0], font_size, Color.WHITE, true, 10)
		var sub := UiStyle.label(texts[1], 18 if big else 15, Color(1, 1, 1, 0.88), false, 5)
		var centered := size.x < 300.0
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
		sub.horizontal_alignment = title.horizontal_alignment
		box.add_child(title)
		if texts[1] != "":
			box.add_child(sub)
		info.merge({"title": title, "sub": sub})
	tiles[entry] = info
	return panel


## Texte und Farben aller Kacheln und die Info-Karte auf den neuesten Stand bringen.
func _refresh() -> void:
	var current := _current()
	for entry in tiles:
		var t: Dictionary = tiles[entry]
		var selected: bool = entry == current
		var color: Color = COLORS.get(entry, SELECTOR_COLOR)
		var style := UiStyle.tile(color, selected)
		if page != Page.MAIN:
			style.skew = Vector2(0.1, 0)
			style.content_margin_left = 22
			style.content_margin_top = 2
			style.content_margin_bottom = 2
		t.panel.add_theme_stylebox_override("panel", style)
		t.panel.z_index = 1 if selected else 0
		if t.has("value"):
			t.value.text = _selector_value(entry)
			var waiting: bool = waiting_action != "" and entry.begins_with("key:") and waiting_action.ends_with(entry.substr(4))
			t.value.add_theme_color_override("font_color", UiStyle.GOLD if selected or waiting else Color.WHITE)
			t.left.visible = selected and not entry.begins_with("key:")
			t.right.visible = t.left.visible
		elif t.has("title"):
			var texts := _tile_texts(entry)
			t.title.text = texts[0]
			t.sub.text = texts[1]
	var info := _info(current)
	info_title.text = info.title
	info_text.text = info.text
	var picture: String = info.get("picture", "")
	info_picture.visible = picture != ""
	# Umbrechender Text braucht seine echte Breite, sonst rechnet er zu viele Zeilen.
	info_text.custom_minimum_size.x = 484.0 - (166.0 if info_picture.visible else 0.0)
	info_picture.texture = load(picture) if picture != "" else null
	esc_hint.visible = page != Page.MAIN
	_fit_info_card()
	_fit_info_card.call_deferred()


## Höhe 0 verlangen: die Karte wird so hoch wie ihr Inhalt (nachdem der Text umgebrochen ist).
func _fit_info_card() -> void:
	info_card.offset_top = info_card.offset_bottom




## Gewählte Kachel rutscht etwas nach rechts und pulsiert leicht, die anderen gleiten zurück.
func _animate_tiles(delta: float) -> void:
	var current := _current()
	for entry in tiles:
		var t: Dictionary = tiles[entry]
		var panel: PanelContainer = t.panel
		if panel.modulate.a < 1.0:
			continue  # fliegt gerade herein
		var target: Vector2 = t.home + Vector2(SELECTED_SHIFT if entry == current else 0.0, 0)
		panel.position = panel.position.lerp(target, minf(1.0, delta * 14.0))
		var glow := 1.0 + (0.08 * (0.5 + 0.5 * sin(time * 5.0)) if entry == current else 0.0)
		panel.self_modulate = Color(glow, glow, glow)


## Kurzes Aufblitzen des Pfeils, in dessen Richtung der Wert geändert wurde.
func _bump_value(entry: String, step: int) -> void:
	if not tiles.has(entry) or not tiles[entry].has("value"):
		return
	var arrow: Label = tiles[entry].right if step > 0 else tiles[entry].left
	arrow.scale = Vector2(1.5, 1.5)
	arrow.pivot_offset = arrow.size / 2
	arrow.create_tween().tween_property(arrow, "scale", Vector2.ONE, 0.18)


func _on_hover(r: int, c: int) -> void:
	if waiting_action == "":
		_select(r, c)


## Maus: Klick bestätigt; bei Einstell-Leisten ändert ein Klick links/rechts den Wert.
func _on_tile_input(event: InputEvent, entry: String, panel: PanelContainer) -> void:
	if waiting_action != "" or not (event is InputEventMouseButton and event.pressed):
		return
	var step := 0
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if _is_selector(entry) and not entry.begins_with("key:"):
				step = -1 if event.position.x < panel.size.x * 0.4 else 1
				_change(entry, step)
			else:
				_activate(entry)
		MOUSE_BUTTON_WHEEL_UP:
			_change(entry, 1)
		MOUSE_BUTTON_WHEEL_DOWN:
			_change(entry, -1)


## Beschreibung der Kampagne in der Info-Karte, mit Fortschritt als Punkten.
func _campaign_info(fresh: bool) -> String:
	var stage := 0 if fresh else Settings.campaign_stage
	var text := "%d Kämpfe, Map für Map, der Computer wird immer stärker. Zwei Bonus-Runden und am Ende der Riesen-Kampfroboter.\n" % Settings.CAMPAIGN.size()
	text += Settings.campaign_dots(stage)
	if Settings.campaign_wins > 0:
		text += "   Schon %d× geschafft!" % Settings.campaign_wins
	return text


func _bar(level: int) -> String:
	return "▮".repeat(level) + "▯".repeat(10 - level)


func _load_map() -> void:
	if map_node:
		map_node.queue_free()
	map_node = load(Settings.current_map().scene).instantiate()
	add_child(map_node)
	move_child(map_node, 0)
	if Settings.current_map().has("backdrop"):
		MapLook.backdrop(map_node, Settings.current_map().backdrop)
	_place_fighters.call_deferred(map_node)


## Die zuletzt gewählten Kämpfer stehen rechts im Bild und schauen in die Kamera.
func _spawn_fighters() -> void:
	var scene: PackedScene = load("res://scenes/player.tscn")
	for i in 2:
		var p: CharacterBody3D = scene.instantiate()
		p.player_id = i + 1
		p.color = Color(1, 0.82, 0.3) if i == 0 else Color(0.4, 0.75, 1)
		p.visible = false
		add_child(p)
		# Keine Physik: die Kämpfer stehen nur da und spielen ihre Warte-Animation.
		p.set_physics_process(false)
		p.set_fighter(Settings.choices[i])
		p.get_node("Tag").visible = false
		fighters.append(p)
		podiums.append(_make_podium(p.color))


## Kämpfer nebeneinander zwischen die Startpunkte der Map stellen, auf den Boden darunter.
## Was zwischen ihnen und der Kamera steht (Kisten, Mauern, Kanonen), wird ausgeblendet.
func _place_fighters(map: Node3D) -> void:
	if map != map_node or not is_instance_valid(map):
		return  # inzwischen schon die nächste Map gewählt
	var a: Vector3 = map.get_node("Spawn1").global_position if map.has_node("Spawn1") else Vector3(-3, 0.2, 0)
	var b: Vector3 = map.get_node("Spawn2").global_position if map.has_node("Spawn2") else Vector3(3, 0.2, 0)
	var middle := (a + b) / 2.0
	# Die Kämpfer stehen auf eigenen Podesten etwas vor der Bühne, so passen sie auf jede Map
	# (manche Maps haben in der Mitte Lücken, Treppen oder Treibsand).
	var ground := minf(a.y, b.y) - 0.2
	for i in fighters.size():
		fighters[i].position = Vector3(middle.x + (-1.15 if i == 0 else 1.15), ground + PODIUM_HEIGHT, PODIUM_Z)
		fighters[i].visible = true
		podiums[i].position = Vector3(fighters[i].position.x, ground, PODIUM_Z)
		podiums[i].visible = true
	focus = Vector3(middle.x - 2.3, ground, PODIUM_Z)
	for node in map.find_children("*", "GeometryInstance3D", true, false):
		var g := node as GeometryInstance3D
		if not g.is_visible_in_tree():
			continue
		var bounds := g.global_transform * g.get_aabb()
		if bounds.size.length() > 60.0 or bounds.end.z < PODIUM_Z - 0.9:
			continue
		for p in fighters:
			var body := AABB(p.position + Vector3(-1.0, 0.0, -0.9), Vector3(2.0, 2.4, 50.0))
			if bounds.intersects(body):
				g.visible = false
				break


## Rundes dunkles Podest mit leuchtendem Ring in der Spielerfarbe (wie bei Smash in der Auswahl).
func _make_podium(color: Color) -> Node3D:
	var podium := Node3D.new()
	podium.visible = false
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.8
	cylinder.bottom_radius = 0.9
	cylinder.height = PODIUM_HEIGHT
	base.mesh = cylinder
	base.position.y = PODIUM_HEIGHT / 2.0
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.1, 0.1, 0.15)
	stone.metallic = 0.6
	stone.roughness = 0.35
	base.material_override = stone
	podium.add_child(base)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.74
	torus.outer_radius = 0.82
	ring.mesh = torus
	ring.position.y = PODIUM_HEIGHT
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color
	glow.emission_enabled = true
	glow.emission = color
	glow.emission_energy_multiplier = 2.5
	ring.material_override = glow
	podium.add_child(ring)
	add_child(podium)
	return podium


func _pressed(actions: Array) -> bool:
	for a in actions:
		if InputMap.has_action(a) and Input.is_action_just_pressed(a):
			return true
	return false
