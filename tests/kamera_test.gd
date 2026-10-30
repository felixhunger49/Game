extends Node
## Automatischer Kamera-Test: Computer gegen Computer auf einer Map, misst, ob alle Kämpfer im Bild sind,
## und macht auf Wunsch Bildschirmfotos.
## Aufruf: godot res://tests/kamera_test.tscn -- map=0 fighters=2 seconds=40 shots=5,15 out=/pfad fs=1

var args := {}
var fight: Node
var t := 0.0
var frames := 0
var player_frames := 0
var off_frames := 0
var edge_frames := 0
var px_sum := 0.0
var shots: Array = []
var fs_done := false
var cam_moves := 0.0
var last_cam := Vector3.ZERO


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv: PackedStringArray = a.split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	seed(int(args.get("seed", "7")))
	Settings.map_index = int(args.get("map", "0"))
	Settings.fighters = int(args.get("fighters", "2"))
	Settings.solo = false
	Settings.campaign = false
	Settings.teams = false
	Settings.target_mode = false
	Settings.boss_mode = false
	Settings.stocks = 3
	if args.has("c0"):
		Settings.choices[0] = int(args.c0)
	Settings.music_volume = 0
	Settings.sfx_volume = 0
	for s in String(args.get("shots", "")).split(",", false):
		shots.append(float(s))
	if not shots.is_empty():
		RenderingServer.render_loop_enabled = false
	fight = load("res://scenes/fight.tscn").instantiate()
	get_tree().root.add_child.call_deferred(fight)
	await get_tree().process_frame
	await get_tree().process_frame
	for i in fight.ready_flags.size():
		fight.ready_flags[i] = true


func _physics_process(delta: float) -> void:
	if fight == null or not fight.is_inside_tree() or fight.state < 2:
		return
	if fight.state == 2:
		_ensure_cpus()
	t += delta
	var cam: Camera3D = fight.camera
	var vp := get_viewport().get_visible_rect().size
	var inner := Rect2(Vector2.ZERO, vp).grow(-vp.y * 0.03)
	frames += 1
	cam_moves += cam.position.distance_to(last_cam)
	last_cam = cam.position
	# Beim K.-o.-Zoom und im Final Smash darf jemand bewusst außerhalb sein.
	var special_view: bool = fight.ko_focus_time > 0.0 or not get_tree().get_nodes_in_group(FinalSmash.GROUP).is_empty()
	for p in fight.players:
		if not p.visible or p.stocks <= 0 or special_view:
			continue
		var zone: Rect2 = MapLook.area_of(fight.map_node).grow_individual(6.0, 6.0, 6.0, 8.0)
		if not zone.has_point(Vector2(p.position.x, p.position.y)):
			continue
		player_frames += 1
		var feet := cam.unproject_position(p.global_position)
		var head := cam.unproject_position(p.global_position + Vector3(0, 1.9 * p.size_scale, 0))
		var full := Rect2(Vector2.ZERO, vp)
		if not full.has_point(head) or not full.has_point(feet) or cam.is_position_behind(p.global_position):
			off_frames += 1
			if args.has("log") and Engine.get_physics_frames() % 30 == 0:
				print("OFF t=%.1f p%d pos=%s cam=%s head=%s feet=%s vp=%s" % [t, p.player_id, p.position, cam.position, head, feet, vp])
		elif not inner.has_point(head) or not inner.has_point(feet):
			edge_frames += 1
		px_sum += absf(feet.y - head.y)
	if args.has("fs") and not fs_done and t > float(args.fs):
		fs_done = true
		fight.players[0].start_final_smash()
	if not shots.is_empty() and t >= shots[0]:
		shots.pop_front()
		_shot()
	if t >= float(args.get("seconds", "40")) or fight.state == 3:
		_finish()


func _ensure_cpus() -> void:
	var controlled: Array = fight.cpus.map(func(c): return c.me)
	for p in fight.players:
		if p.visible and not controlled.has(p):
			var cpu := CpuPlayer.new()
			fight.add_child(cpu)
			cpu.setup(p, fight.players[1] if p == fight.players[0] else fight.players[0], 2, fight.map_node)
			fight.cpus.append(cpu)


func _shot() -> void:
	RenderingServer.render_loop_enabled = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if shots.is_empty() or shots[0] - t > 0.3:
		RenderingServer.render_loop_enabled = false
	var img := get_viewport().get_texture().get_image()
	var name := "%s/m%d_f%d_%04.1f.png" % [args.get("out", "/tmp"), Settings.map_index, Settings.fighters, t]
	img.save_png(name)


var finished := false

func _finish() -> void:
	if finished:
		return
	finished = true
	var pf := maxf(player_frames, 1)
	print("RESULT map=%d name=%s fighters=%d time=%.1f off=%.2f%% edge=%.2f%% px=%.0f jitter=%.3f" % [
		Settings.map_index, Settings.current_map().name.replace(" ", "_"), Settings.fighters, t,
		100.0 * off_frames / pf, 100.0 * edge_frames / pf, px_sum / pf, cam_moves / maxf(frames, 1)])
	get_tree().quit()
