extends Node
## Test gegen "Dauersprung" in der Kämpferauswahl: Auf jeder Map stehen alle Kämpfer still auf ihrem Startplatz,
## bis alle bereit sind. Danach darf kein Startplatz auf einem Sprungfeld oder Aufwind liegen.
## Aufruf: godot --headless res://tests/startplatz_test.tscn

var fight: Node
var map := 0
var t := 0.0
var max_rise := 0.0
var riser := ""
var rest := {}
var failed := 0


func _ready() -> void:
	map = int(OS.get_environment("MINMAP"))
	Settings.solo = false
	Settings.campaign = false
	Settings.teams = false
	Settings.target_mode = false
	Settings.boss_mode = false
	Settings.fighters = 4
	Settings.music_volume = 0
	Settings.sfx_volume = 0
	_load_map.call_deferred()


func _load_map() -> void:
	Settings.map_index = map
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fight)
	t = 0.0
	max_rise = 0.0
	rest = {}
	riser = ""


func _physics_process(delta: float) -> void:
	if fight == null or fight.map_node == null:
		return
	t += delta
	# Nach dem Hinfallen (1,5 s) muss jeder ruhig stehen: Höhe darf sich nicht mehr ändern.
	if t > 1.5:
		for p in fight.players:
			if p.visible:
				var y: float = p.position.y
				if not rest.has(p):
					rest[p] = y
				if absf(y - rest[p]) > max_rise:
					max_rise = absf(y - rest[p])
					riser = "Spieler %d" % p.player_id
	if t < 3.0:
		return
	# Startplätze und Wiedereinstieg (4 über dem Startplatz) dürfen nicht in einem Sprungfeld liegen.
	var on_pad := []
	for pad in _pads(fight.map_node):
		var box: BoxShape3D = pad.get_child(0).shape
		var aabb := AABB(pad.global_position - box.size * 0.5, box.size).grow(0.3)
		for p in fight.players:
			for h in [0.5, 4.0]:
				if aabb.has_point(p.spawn_position + Vector3(0, h, 0)):
					on_pad.append("Spieler %d" % p.player_id)
	var ok := max_rise < 0.3 and on_pad.is_empty()
	if not ok:
		failed += 1
	print("%s map=%d %s: hoch=%.2f %s %s" % ["OK  " if ok else "FEHLER", map, Settings.current_map().name, max_rise, riser, on_pad])
	fight.queue_free()
	fight = null
	map += 1
	if map >= int(OS.get_environment("MAXMAP")) + 1:
		print("RESULT failed=%d" % failed)
		get_tree().quit(1 if failed > 0 else 0)
	else:
		_load_map.call_deferred()


func _pads(node: Node) -> Array:
	var out := []
	for c in node.get_children():
		if c is BouncePad:
			out.append(c)
		out.append_array(_pads(c))
	return out
