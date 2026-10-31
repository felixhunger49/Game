extends Node
## Test: Jägerin, Magierin und Hexe schießen mit dem starken Angriff (Pfeil, Arkanblitz, Fluchkugel), Nahkämpfer nicht.
## Aufruf: godot --headless res://tests/fernkampf_test.tscn

var fight: Node
var names := ["Jägerin", "Magierin", "Hexe", "Barbar"]
var step := 0
var t := 0.0
var failed := 0
var seen := false


func _ready() -> void:
	Settings.map_index = 0
	Settings.fighters = 2
	Settings.solo = false
	Settings.campaign = false
	Settings.target_mode = false
	Settings.boss_mode = false
	Settings.music_volume = 0
	Settings.sfx_volume = 0
	_next.call_deferred()


func _next() -> void:
	if step >= names.size():
		print("RESULT failed=%d" % failed)
		get_tree().quit(1 if failed > 0 else 0)
		return
	if fight:
		fight.queue_free()
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child(fight)
	var index := Roster.FIGHTERS.map(func(x): return x.name).find(names[step])
	Settings.choices[0] = index
	fight.players[0].set_fighter(index)
	t = 0.0
	seen = false
	for i in fight.ready_flags.size():
		fight.ready_flags[i] = true


func _physics_process(delta: float) -> void:
	if fight == null or fight.state < 2:
		return
	t += delta
	var p: CharacterBody3D = fight.players[0]
	if t > 0.2 and t < 0.25:
		p.start_attack("strong")
	for c in fight.get_children():
		if c is FernSchuss:
			seen = true
	if t > 2.0:
		var want: bool = names[step] != "Barbar"
		var ok := seen == want
		if not ok:
			failed += 1
		print("%s %s: Geschoss=%s (erwartet %s)" % ["OK  " if ok else "FEHLER", names[step], seen, want])
		step += 1
		_next.call_deferred()
