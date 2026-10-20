extends Node3D
## Hauptmenü mit Optionen. Steuerung: W/S oder Pfeile hoch/runter wählen,
## A/D oder Pfeile links/rechts ändern, F, J oder Enter bestätigen, Esc zurück.

enum Page { MAIN, OPTIONS, CONTROLS }

const CONTROLS_TEXT := """Spieler 1                          Spieler 2
A / D        laufen                Pfeil links / rechts
W            springen (2x)         Pfeil hoch
S            abwehren (halten)     Pfeil runter
F            schwacher Angriff     J
G            starker Angriff       K
H            Tritt                 L
T            Spezialattacke        I

R: nach dem Kampf nochmal     Esc: zurück ins Menü"""

var page := Page.MAIN
var selected := 0
var time := 0.0
var map_node: Node3D

@onready var camera: Camera3D = $Camera3D
@onready var entries_box: VBoxContainer = $UI/Entries
@onready var info_label: Label = $UI/Info


func _ready() -> void:
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["DejaVu Sans Mono", "Consolas", "Courier New", "monospace"])
	info_label.add_theme_font_override("font", mono)
	_load_map()
	_refresh()


func _process(delta: float) -> void:
	time += delta
	camera.position = Vector3(sin(time * 0.15) * 7.0, 4.0 + sin(time * 0.1), 19.0)
	camera.look_at(Vector3(0, 1.5, 0))

	var entries := _entries()
	if _pressed(["p1_jump", "p2_jump", "ui_up"]):
		selected = wrapi(selected - 1, 0, entries.size())
		_refresh()
	elif _pressed(["p1_shield", "p2_shield", "ui_down"]):
		selected = wrapi(selected + 1, 0, entries.size())
		_refresh()
	elif _pressed(["p1_left", "p2_left"]):
		_change(entries[selected], -1)
	elif _pressed(["p1_right", "p2_right"]):
		_change(entries[selected], 1)
	elif _pressed(["p1_weak", "p2_weak", "ui_accept"]):
		_activate(entries[selected])
	elif Input.is_action_just_pressed("back") and page != Page.MAIN:
		_open(Page.MAIN)


func _entries() -> Array:
	match page:
		Page.OPTIONS:
			return ["items", "rate", "stocks", "back"]
		Page.CONTROLS:
			return ["back"]
	return ["play", "map", "options", "controls", "quit"]


func _entry_text(entry: String) -> String:
	match entry:
		"play": return "Kampf starten"
		"map": return "Map:  ◀ %s ▶" % Settings.current_map().name
		"options": return "Optionen"
		"controls": return "Steuerung"
		"quit": return "Beenden"
		"items": return "Items:  ◀ %s ▶" % ("An" if Settings.items_enabled else "Aus")
		"rate": return "Item-Häufigkeit:  ◀ %s ▶" % Settings.ITEM_RATES[Settings.item_rate]
		"stocks": return "Leben:  ◀ %d ▶" % Settings.stocks
		"back": return "Zurück"
	return entry


func _change(entry: String, step: int) -> void:
	match entry:
		"map":
			Settings.map_index = wrapi(Settings.map_index + step, 0, Settings.MAPS.size())
			_load_map()
		"items":
			Settings.items_enabled = not Settings.items_enabled
		"rate":
			Settings.item_rate = clampi(Settings.item_rate + step, 0, Settings.ITEM_RATES.size() - 1)
		"stocks":
			Settings.stocks = clampi(Settings.stocks + step, 1, 9)
		_:
			return
	Settings.save()
	_refresh()


func _activate(entry: String) -> void:
	match entry:
		"play":
			get_tree().change_scene_to_file("res://scenes/fight.tscn")
		"options":
			_open(Page.OPTIONS)
		"controls":
			_open(Page.CONTROLS)
		"quit":
			get_tree().quit()
		"back":
			_open(Page.MAIN)
		"map", "items", "rate", "stocks":
			_change(entry, 1)


func _open(new_page: Page) -> void:
	page = new_page
	selected = 0
	_refresh()


func _refresh() -> void:
	for child in entries_box.get_children():
		child.queue_free()
	var entries := _entries()
	for i in entries.size():
		var label := Label.new()
		label.text = ("▶  " if i == selected else "") + _entry_text(entries[i])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 40 if i == selected else 34)
		label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if i == selected else Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		label.add_theme_constant_override("outline_size", 12)
		entries_box.add_child(label)
	match page:
		Page.CONTROLS:
			info_label.text = CONTROLS_TEXT
		Page.OPTIONS:
			info_label.text = "Items fallen während des Kampfes vom Himmel:\nHeiltrank, Kraft, Tempo und Bomben."
		_:
			info_label.text = "W/S wählen   A/D ändern   F bestätigen"


func _load_map() -> void:
	if map_node:
		map_node.queue_free()
	map_node = load(Settings.current_map().scene).instantiate()
	add_child(map_node)


func _pressed(actions: Array) -> bool:
	for a in actions:
		if Input.is_action_just_pressed(a):
			return true
	return false
