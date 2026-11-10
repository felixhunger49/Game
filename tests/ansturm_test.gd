extends Node
## Test für den Ansturm-Modus: der Computer spielt die Spieler, Schatten kommen aus Portalen.
## Prüft, dass Wellen starten, Schatten besiegt werden, nichts hängen bleibt und keine Fehler kommen.
## Aufruf: godot --headless res://tests/ansturm_test.tscn -- map=0 solo=1 seconds=90
## Bilder: ... -- shots=/pfad/ordner (dann ohne --headless starten)

var args := {}
var fight: Node
var t := 0.0
var finished := false
var next_shot := 6.0
var shot_index := 0
var max_minions := 0
var next_log := 10.0
var smashed := false
var over_time := 0.0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	seed(int(args.get("seed", "7")))
	await get_tree().process_frame
	Settings.map_index = int(args.get("map", "0"))
	Settings.fighters = 2
	Settings.solo = args.get("solo", "1") == "1"
	Settings.campaign = false
	Settings.teams = false
	Settings.target_mode = false
	Settings.boss_mode = false
	Settings.horde_mode = true
	Settings.horde_records = {}
	Settings.stocks = int(args.get("stocks", "3"))
	Settings.choices[0] = int(args.get("fighter", "2"))
	Settings.music_volume = 0
	Settings.sfx_volume = 0
	Audio.apply_volume()
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fight)
	await get_tree().process_frame
	await get_tree().process_frame
	next_shot = float(args.get("first", "6"))
	if args.has("shots"):
		await get_tree().create_timer(1.0).timeout
		_shot("auswahl")
	for i in fight.ready_flags.size():
		fight.ready_flags[i] = true


func _process(delta: float) -> void:
	if fight == null or not fight.is_inside_tree() or fight.state < 2 or finished:
		return
	t += delta / maxf(Engine.time_scale, 0.01)
	var a: Ansturm = fight.ansturm
	if a == null:
		return
	if fight.state == 2:
		# Der Computer spielt die Menschen (Stufe Schwer), damit auch spätere Wellen erreicht werden.
		var controlled: Array = fight.cpus.map(func(c): return c.me)
		for p in a.humans:
			if p.visible and not controlled.has(p):
				var cpu := CpuPlayer.new()
				fight.add_child(cpu)
				cpu.setup(p, null, 2, fight.map_node)
				fight.cpus.append(cpu)
		if args.has("wave") and a.wave == 0:
			a.wave = int(args.wave) - 1
		if args.has("god"):
			for p in a.humans:
				p.damage = minf(p.damage, 30.0)
	# smash=1: sobald drei Schatten da sind, löst Spieler 1 seinen Final Smash aus.
	if args.has("smash") and not smashed and a.minions.size() >= 3 and fight.state == 2:
		smashed = true
		a.humans[0].gain_final_smash()
		a.humans[0].start_final_smash()
	max_minions = maxi(max_minions, a.minions.size())
	if t >= next_log:
		next_log += 10.0
		print("t=%d welle=%d kos=%d punkte=%d schatten=%d leben=%s" % [int(t), a.wave, a.kos, a.score, a.minions.size(),
			str(a.humans.map(func(h): return h.stocks))])
	if args.has("shots") and t >= next_shot:
		next_shot += float(args.get("every", "5"))
		_shot("kampf_%02d" % shot_index)
		shot_index += 1
	if fight.state == 3:
		over_time += delta
	if t >= float(args.get("seconds", "90")) or (fight.state == 3 and (over_time > 1.5 or not args.has("shots"))):
		finished = true
		if args.has("shots"):
			_shot("ende")
		print("RESULT map=%d welle=%d kos=%d punkte=%d beste_kombo=%d max_schatten=%d ende=%s time_scale=%.2f bilder=%d" % [
			Settings.map_index, a.wave, a.kos, a.score, a.best_combo, max_minions, str(fight.state == 3), Engine.time_scale,
			Engine.get_frames_drawn()])
		get_tree().quit(0 if a.kos > 0 and a.wave >= 1 else 1)


func _shot(shot_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [args.shots, shot_name])
