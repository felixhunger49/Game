extends Node
## Spieleinstellungen, die zwischen Menü und Kampf geteilt und auf der Festplatte gespeichert werden.

const SAVE_PATH := "user://settings.cfg"

## event: der Map-Effekt (siehe MapEvents), effect: Beschreibung im Menü,
## backdrop: gemaltes Hintergrundbild weit hinter der Arena (optional).
const MAPS := [
	{"name": "Burg", "scene": "res://scenes/maps/burg.tscn", "music": "burg", "event": "kanonen",
		"backdrop": "res://assets/maps/burg/hintergrund.png",
		"effect": "Kanonenkugeln fliegen quer durch die Burg.\nAchte auf das rote Ausrufezeichen!"},
	{"name": "Dorf", "scene": "res://scenes/maps/dorf.tscn", "music": "dorf", "event": "wind",
		"backdrop": "res://assets/maps/dorf/hintergrund.png",
		"effect": "Windböen schieben alle Kämpfer zur Seite.\nDie Pfeile zeigen die Richtung."},
	{"name": "Friedhof", "scene": "res://scenes/maps/friedhof.tscn", "music": "friedhof", "event": "geister",
		"backdrop": "res://assets/maps/friedhof/hintergrund.png",
		"effect": "Weniger Schwerkraft: man springt höher.\nGeister schießen aus leuchtenden Stellen hoch."},
	{"name": "Vulkan", "scene": "res://scenes/maps/vulkan.tscn", "music": "vulkan", "event": "lava",
		"effect": "Lavafontänen schießen aus dem Boden.\nWeg von den glühenden Stellen!"},
	{"name": "Piratenschiff", "scene": "res://scenes/maps/piratenschiff.tscn", "music": "piratenschiff", "event": "wellen",
		"effect": "Seegang: Das Schiff schaukelt und Wellen\nschieben alle zur Seite."},
	{"name": "Eiswelt", "scene": "res://scenes/maps/eiswelt.tscn", "music": "eiswelt", "event": "eis",
		"effect": "Spiegelglatter Boden: man rutscht!\nEiszapfen fallen auf die blauen Stellen."},
	{"name": "Wolkentempel", "scene": "res://scenes/maps/wolkentempel.tscn", "music": "wolkentempel", "event": "blitze",
		"effect": "Blitze schlagen ein.\nGelbe Kreise zeigen, wo es gleich kracht."},
	{"name": "Japanischer Tempel", "scene": "res://scenes/maps/tempel.tscn", "music": "tempel", "event": "gong",
		"effect": "Der große Gong schlägt: eine goldene Schockwelle\nläuft über den Boden. Spring drüber!"},
	{"name": "Neonstadt bei Nacht", "scene": "res://scenes/maps/neonstadt.tscn", "music": "neonstadt", "event": "drohne",
		"effect": "Eine Polizeidrohne verfolgt einen Kämpfer\nmit dem roten Laserpunkt und feuert dann!"},
	{"name": "Dschungel-Ruinen", "scene": "res://scenes/maps/dschungel.tscn", "music": "dschungel", "event": "felsbrocken",
		"effect": "Ein riesiger Felsbrocken rollt durch die Ruinen.\nRauf auf die Plattformen!"},
	{"name": "Wüstenarena", "scene": "res://scenes/maps/wueste.tscn", "music": "wueste", "event": "treibsand",
		"effect": "Treibsand an markierten Stellen:\nwer drinsteht, wird langsam und springt kaum."},
	{"name": "Unterwasser-Kuppel", "scene": "res://scenes/maps/unterwasser.tscn", "music": "unterwasser", "event": "blasen",
		"effect": "Unter Wasser springt man höher.\nBlasen-Geysire schleudern alle nach oben."},
]
## Solo-Kampagne: feste Reihenfolge von Kämpfen. type: "kampf" (gegen den Computer),
## "ziele" (Bonus: alle Ziele zerstören) oder "boss" (Finale gegen den Riesen-Kampfroboter).
## cpu: Stärke des Computers (0 leicht, 1 mittel, 2 schwer), intro: Text vor dem Kampf.
const CAMPAIGN := [
	{"type": "kampf", "map": "Dorf", "cpu": 0, "intro": "Alles beginnt auf dem Dorfplatz."},
	{"type": "kampf", "map": "Burg", "cpu": 0, "intro": "Der Burgherr will sehen, was du kannst."},
	{"type": "kampf", "map": "Friedhof", "cpu": 0, "intro": "Nachts auf dem Friedhof wartet der nächste Gegner."},
	{"type": "kampf", "map": "Japanischer Tempel", "cpu": 1, "intro": "Im Tempel kämpfen nur die Besten weiter."},
	{"type": "ziele", "map": "Japanischer Tempel", "intro": "Bonus-Runde: Zerstöre alle Ziele so schnell du kannst!"},
	{"type": "kampf", "map": "Dschungel-Ruinen", "cpu": 1, "intro": "Tief im Dschungel rollt etwas Großes …"},
	{"type": "kampf", "map": "Wüstenarena", "cpu": 1, "intro": "Die Menge in der Wüstenarena tobt."},
	{"type": "kampf", "map": "Piratenschiff", "cpu": 1, "intro": "Auf hoher See: Halt dich fest!"},
	{"type": "kampf", "map": "Eiswelt", "cpu": 1, "intro": "Vorsicht, der Boden ist spiegelglatt."},
	{"type": "ziele", "map": "Eiswelt", "intro": "Bonus-Runde: Zerstöre alle Ziele so schnell du kannst!"},
	{"type": "kampf", "map": "Unterwasser-Kuppel", "cpu": 2, "intro": "Ab jetzt kämpft der Computer mit voller Kraft."},
	{"type": "kampf", "map": "Neonstadt bei Nacht", "cpu": 2, "intro": "Die Polizeidrohne hat dich schon im Visier."},
	{"type": "kampf", "map": "Vulkan", "cpu": 2, "intro": "Im Vulkan wird es richtig heiß."},
	{"type": "kampf", "map": "Wolkentempel", "cpu": 2, "intro": "Der letzte Kämpfer wartet über den Wolken."},
	{"type": "boss", "map": "Burg", "intro": "FINALE: Der Riesen-Kampfroboter greift die Burg an!"},
]
const ITEM_RATES := ["Selten", "Normal", "Oft"]
## Sekunden zwischen zwei Items je Häufigkeit (zufällig zwischen den beiden Werten).
const ITEM_INTERVALS := [Vector2(12, 18), Vector2(6, 10), Vector2(3, 5)]

## Aktionen, die man in den Optionen neu belegen kann (ohne "p1_"/"p2_").
const BINDABLE := ["left", "right", "jump", "shield", "weak", "strong", "kick", "special"]
const ACTION_NAMES := {
	"left": "Links", "right": "Rechts", "jump": "Springen", "shield": "Abwehren",
	"weak": "Schwacher Angriff", "strong": "Starker Angriff", "kick": "Tritt", "special": "Spezialattacke",
}

var items_enabled := true
var item_rate := 1
var stocks := 3
var map_index := 0
var choices := [0, 1]
var map_effects := true
var special_charge := true
## Solo: Spieler 2 ist der Computer (Schwierigkeit 0 leicht, 1 mittel, 2 schwer).
var solo := false
var cpu_level := 1
## Ziele zerstören: allein gegen die Uhr. Bestzeiten je "Map|Kämpfer" in Sekunden.
var target_mode := false
## Endboss: allein gegen den Riesen-Kampfroboter.
var boss_mode := false
var target_records := {}
## Kampagne: true, solange ein Kampagnen-Kampf läuft (nur im Kampf, nicht im Menü).
var campaign := false
## Gespeicherter Fortschritt: nächster Kampf (Index in CAMPAIGN), Gegner-Reihenfolge (Namen),
## Niederlagen in diesem Durchgang und wie oft die Kampagne schon geschafft wurde.
var campaign_stage := 0
var campaign_opponents := []
var campaign_losses := 0
var campaign_wins := 0
var music_volume := 7
var sfx_volume := 8
## Grafik: 0 Niedrig (für schwache PCs), 1 Hoch (Kantenglättung, Schatten, Glühen, mehr Funken).
const GRAPHICS := ["Niedrig", "Hoch"]
var graphics := 1

## Standardbelegung aus project.godot, damit man sie wiederherstellen kann.
var _default_events := {}


func _ready() -> void:
	for p in [1, 2]:
		for a in BINDABLE:
			var action := "p%d_%s" % [p, a]
			_default_events[action] = InputMap.action_get_events(action)

	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	items_enabled = cfg.get_value("game", "items_enabled", items_enabled)
	item_rate = cfg.get_value("game", "item_rate", item_rate)
	stocks = cfg.get_value("game", "stocks", stocks)
	map_index = cfg.get_value("game", "map_index", map_index)
	choices = cfg.get_value("game", "choices", choices)
	# Gespeicherte Auswahl kann auf eine inzwischen entfernte Figur zeigen.
	choices = choices.map(func(c): return clampi(c, 0, Roster.FIGHTERS.size() - 1))
	map_effects = cfg.get_value("game", "map_effects", map_effects)
	special_charge = cfg.get_value("game", "special_charge", special_charge)
	solo = cfg.get_value("game", "solo", solo)
	cpu_level = cfg.get_value("game", "cpu_level", cpu_level)
	target_records = cfg.get_value("game", "target_records", target_records)
	campaign_stage = clampi(cfg.get_value("campaign", "stage", campaign_stage), 0, CAMPAIGN.size() - 1)
	campaign_opponents = cfg.get_value("campaign", "opponents", campaign_opponents)
	campaign_losses = cfg.get_value("campaign", "losses", campaign_losses)
	campaign_wins = cfg.get_value("campaign", "wins", campaign_wins)
	music_volume = cfg.get_value("audio", "music_volume", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	graphics = clampi(cfg.get_value("video", "graphics", graphics), 0, GRAPHICS.size() - 1)
	if cfg.has_section("controls"):
		for action in cfg.get_section_keys("controls"):
			if action in _default_events:
				_set_events(action, cfg.get_value("controls", action))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "items_enabled", items_enabled)
	cfg.set_value("game", "item_rate", item_rate)
	cfg.set_value("game", "stocks", stocks)
	cfg.set_value("game", "map_index", map_index)
	cfg.set_value("game", "choices", choices)
	cfg.set_value("game", "map_effects", map_effects)
	cfg.set_value("game", "special_charge", special_charge)
	cfg.set_value("game", "solo", solo)
	cfg.set_value("game", "cpu_level", cpu_level)
	cfg.set_value("game", "target_records", target_records)
	cfg.set_value("campaign", "stage", campaign_stage)
	cfg.set_value("campaign", "opponents", campaign_opponents)
	cfg.set_value("campaign", "losses", campaign_losses)
	cfg.set_value("campaign", "wins", campaign_wins)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "graphics", graphics)
	for action in _default_events:
		cfg.set_value("controls", action, InputMap.action_get_events(action))
	cfg.save(SAVE_PATH)


func current_map() -> Dictionary:
	if campaign:
		for m in MAPS:
			if m.name == campaign_step().map:
				return m
	return MAPS[wrapi(map_index, 0, MAPS.size())]


## Der aktuelle Kampagnen-Kampf (siehe CAMPAIGN).
func campaign_step() -> Dictionary:
	return CAMPAIGN[clampi(campaign_stage, 0, CAMPAIGN.size() - 1)]


## Stärke des Computers: in der Kampagne fest je Kampf, sonst wie im Menü eingestellt.
func cpu_difficulty() -> int:
	return campaign_step().get("cpu", 1) if campaign else cpu_level


## Fortschritt als Zeichenkette: ● geschafft, ◉ jetzt dran, ○ noch offen, ★ Bonus, ☠ Endboss.
func campaign_dots(stage: int) -> String:
	var dots := ""
	for i in CAMPAIGN.size():
		var type: String = CAMPAIGN[i].type
		if i < stage:
			dots += "●"
		elif i == stage:
			dots += "◉"
		elif type == "ziele":
			dots += "★"
		elif type == "boss":
			dots += "☠"
		else:
			dots += "○"
		dots += " "
	return dots.strip_edges()


## Neue Kampagne: Fortschritt auf Anfang, Gegner in zufälliger Reihenfolge.
func new_campaign() -> void:
	campaign_stage = 0
	campaign_losses = 0
	campaign_opponents = Roster.FIGHTERS.map(func(f): return f.name)
	campaign_opponents.shuffle()
	save()


## Gegner für den aktuellen Kampf: jedes Mal ein anderer, nie derselbe Kämpfer wie man selbst.
func campaign_opponent(own: int) -> int:
	var names := Roster.FIGHTERS.map(func(f): return f.name)
	var order := campaign_opponents.filter(func(n): return n in names)
	if order.is_empty():
		order = names
	var fights := 0
	for i in campaign_stage:
		if CAMPAIGN[i].type == "kampf":
			fights += 1
	var others := order.filter(func(n): return names.find(n) != own)
	if others.is_empty():
		return (own + 1) % names.size()
	return names.find(others[fights % others.size()])


## Belegt eine Aktion neu. Hat eine andere Aktion schon diese Taste, bekommt sie die alte Taste.
func rebind(action: String, event: InputEvent) -> void:
	var old_events := InputMap.action_get_events(action)
	for other in _default_events:
		if other == action:
			continue
		for e in InputMap.action_get_events(other):
			if _same_input(e, event):
				InputMap.action_erase_event(other, e)
				for old in old_events:
					InputMap.action_add_event(other, old)
	_set_events(action, [event])
	save()


func reset_controls() -> void:
	for action in _default_events:
		_set_events(action, _default_events[action])
	save()


## Lesbarer Name der Taste(n) einer Aktion, z. B. "A" oder "Pfeil links".
func key_text(action: String) -> String:
	var names := []
	for e in InputMap.action_get_events(action):
		names.append(event_text(e))
	return " / ".join(names) if names else "—"


func event_text(e: InputEvent) -> String:
	if e is InputEventKey:
		var code: Key = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		match code:
			KEY_LEFT: return "Pfeil links"
			KEY_RIGHT: return "Pfeil rechts"
			KEY_UP: return "Pfeil hoch"
			KEY_DOWN: return "Pfeil runter"
			KEY_SPACE: return "Leertaste"
			KEY_SHIFT: return "Umschalt"
			KEY_CTRL: return "Strg"
			KEY_ALT: return "Alt"
			KEY_ENTER: return "Enter"
			KEY_KP_ENTER: return "Ziffernblock Enter"
		var shown := code
		if e.physical_keycode != KEY_NONE and DisplayServer.get_name() != "headless":
			# Zeigt die Taste so, wie sie auf der eigenen Tastatur beschriftet ist (z. B. Z/Y bei QWERTZ).
			shown = DisplayServer.keyboard_get_keycode_from_physical(code)
		return OS.get_keycode_string(shown)
	if e is InputEventJoypadButton:
		return "Pad %d Knopf %d" % [e.device + 1, e.button_index]
	if e is InputEventJoypadMotion:
		return "Pad %d Stick %d%s" % [e.device + 1, e.axis, "+" if e.axis_value > 0 else "-"]
	return e.as_text()


func _set_events(action: String, events: Array) -> void:
	InputMap.action_erase_events(action)
	for e in events:
		if e is InputEvent:
			InputMap.action_add_event(action, e)


func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		var ka: Key = a.physical_keycode if a.physical_keycode != KEY_NONE else a.keycode
		var kb: Key = b.physical_keycode if b.physical_keycode != KEY_NONE else b.keycode
		return ka == kb
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return a.button_index == b.button_index and a.device == b.device
	if a is InputEventJoypadMotion and b is InputEventJoypadMotion:
		return a.axis == b.axis and signf(a.axis_value) == signf(b.axis_value) and a.device == b.device
	return false
