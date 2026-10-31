class_name CpuPlayer
extends Node
## Computer-Gegner für den Solo-Modus: steuert einen Spieler, indem er dieselben Tasten "drückt"
## wie ein Mensch (p2_left, p2_weak, …). So gelten für ihn alle Regeln, Specials und Passiven genauso.

## Je Schwierigkeit: Reaktionszeit (s), Angriffslust (0..1), Blocken (0..1), Fehler (0..1).
const LEVELS := [
	{"name": "Leicht", "reaction": 0.45, "aggression": 0.35, "block": 0.10, "mistakes": 0.30},
	{"name": "Mittel", "reaction": 0.25, "aggression": 0.60, "block": 0.30, "mistakes": 0.12},
	{"name": "Schwer", "reaction": 0.12, "aggression": 0.85, "block": 0.55, "mistakes": 0.03},
]
## Specials, die aus der Ferne treffen (die anderen nur aus der Nähe einsetzen).
const RANGED_SPECIALS := ["feuerball", "frost", "schwein", "justice", "pfeilregen", "breitseite", "laser", "erdbeben"]
## So hoch kommt man mit Sprung + Doppelsprung ungefähr (etwas Luft gelassen).
const MAX_CLIMB := 4.8
## So weit kommt man seitlich mit einem Sprung über eine Lücke.
const MAX_GAP := 4.0

var me: CharacterBody3D
var foe: CharacterBody3D
var level: Dictionary
var think_timer := 0.0
var held := {}
var shield_time := 0.0
var wander := 0
## Wie lange der Computer schon jemanden im Griff hat oder an der Kante hängt.
var hold_time := 0.0
var hang_time := 0.0
## Die Map, um Böden und Plattformen zu finden (für Wege nach oben, nach unten und zurück auf die Bühne).
var map: Node
## Nächster Schritt auf dem Weg zum Gegner: {"x": wo man hinläuft, "do": "jump"/"drop"/"edge"/"walk",
## "steer": wohin man danach in der Luft steuert}. Leer = der Gegner ist auf derselben Ebene.
var route := {}
var steer := Vector2.ZERO
var steer_time := 0.0
var wall_jump_time := 0.0
## Ab und zu läuft der Computer woandershin (in die Höhle, aufs Dach …), statt nur dem Gegner nachzulaufen.
var roam := -1
var roam_time := 0.0
## Gerade auf dem Rückweg zur Bühne (bleibt so, bis man wieder steht oder an einer Kante hängt).
var recovering := false


func setup(player: CharacterBody3D, opponent: CharacterBody3D, difficulty: int, stage: Node = null) -> void:
	me = player
	foe = opponent
	map = stage
	level = LEVELS[clampi(difficulty, 0, LEVELS.size() - 1)]


func _physics_process(delta: float) -> void:
	if me == null or not me.controls_enabled or not me.visible:
		_hold([])
		return
	# Mit mehr als zwei Kämpfern: immer den nächsten Gegner angehen.
	var nearest: CharacterBody3D = me.opponent
	if nearest:
		foe = nearest
	shield_time = maxf(shield_time - delta, 0.0)
	think_timer -= delta
	var want: Array = []
	var pos := me.global_position
	var to_foe := _goal_pos() - pos
	var dist := absf(to_foe.x)
	var toward := "right" if to_foe.x > 0.0 else "left"
	var to_center := "right" if pos.x < 0.0 else "left"

	# Gepackt: wild auf die Tasten hauen, um freizukommen.
	if me.held_by:
		_hold([])
		if think_timer <= 0.0:
			think_timer = 0.12 + level.reaction * 0.3
			_tap(["weak", "kick", "jump"].pick_random())
		return
	# Selbst gepackt: kurz zuschlagen, dann werfen (am liebsten Richtung Abgrund).
	if me.holding:
		_hold([])
		hold_time += delta
		if hold_time > 0.25 + level.reaction and think_timer <= 0.0:
			hold_time = 0.0
			var toward_edge: bool = signf(pos.x) == float(me.facing) or absf(pos.x) < 1.0
			me._throw(["oben", "unten"].pick_random() if randf() < 0.25 else "vorne" if toward_edge else "hinten")
		elif think_timer <= 0.0:
			think_timer = 0.2
			_tap("weak")
		return
	hold_time = 0.0
	# An der Kante: kurz hängen, dann hochklettern oder hochspringen.
	if me.ledge_side != 0:
		recovering = false
		_hold([])
		hang_time += delta
		if hang_time > level.reaction + 0.2:
			hang_time = 0.0
			if randf() < 0.5:
				me._climb_ledge()
			else:
				_tap("jump", 0.3)
		return
	hang_time = 0.0

	steer_time = maxf(steer_time - delta, 0.0)
	wall_jump_time = maxf(wall_jump_time - delta, 0.0)
	roam_time = maxf(roam_time - delta, 0.0)
	var on_floor := me.is_on_floor()

	# 1) Zurück auf die Bühne: kein Boden mehr unter einem, also zur nächsten Plattform steuern und springen.
	if on_floor:
		recovering = false
	elif not _ground_below(pos, 30.0):
		recovering = true
	if recovering:
		var goal := steer if steer_time > 0.0 else _recovery_goal(pos)
		want.append("right" if goal.x > pos.x else "left")
		if me.velocity.y < 1.0 and me.jumps_left > 0 and think_timer <= 0.0:
			_tap("jump", 0.3)
			think_timer = 0.25
		elif me.jumps_left == 0 and not me.special_air_used and me.velocity.y < 0.0:
			# Keine Sprünge mehr: Rettungssprung (hoch + Spezial).
			_tap("up", 0.15)
			_tap("special")
		_hold(want)
		return

	# 2) Blocken, wenn der Gegner nah ist und gerade zuschlägt (manchmal stattdessen kontern).
	var foe_attacking: bool = foe.pending_attack != "" or foe.attack_timer > 0.15
	if dist < 2.0 and foe.pending_attack != "" and me.konter_cooldown <= 0.0 and think_timer <= 0.0 \
			and randf() < level.block * 0.3:
		think_timer = 0.4
		_tap("down", 0.12)
		_tap("special")
		return
	if shield_time > 0.0 or (dist < 2.2 and foe_attacking and think_timer <= 0.0 and randf() < level.block):
		if shield_time == 0.0:
			shield_time = 0.35
		if not on_floor and not me.air_dodge_used:
			# In der Luft: ausweichen statt abwehren.
			_hold([])
			_tap("shield")
			shield_time = 0.0
			think_timer = level.reaction
			return
		_hold(["shield"])
		return

	if think_timer <= 0.0:
		route = _plan_route()

	# 3) Laufen: in der Luft nach einem Wegsprung zum Ziel steuern, sonst dem Weg folgen oder direkt zum Gegner.
	if steer_time > 0.0 and not on_floor:
		want.append("right" if steer.x > pos.x else "left")
		if absf(steer.x - pos.x) < 0.3:
			want.clear()
		# Noch zu tief: oben nachspringen.
		if me.velocity.y < 0.5 and pos.y < steer.y + 0.4 and me.jumps_left > 0:
			_tap("jump", 0.3)
	elif not route.is_empty():
		_follow_route(pos, on_floor, want)
	elif dist > 1.5:
		want.append(toward)
	elif dist < 0.6:
		# Zu nah dran: kurz zurück, damit die Schläge treffen.
		want.append("left" if toward == "right" else "right")

	# Nicht einfach über eine Kante ins Leere laufen (außer der Weg führt absichtlich hinunter).
	if on_floor and not want.is_empty() and route.get("do", "") != "edge":
		var dir := 1.0 if want[0] == "right" else -1.0
		if not _ground_below(pos + Vector3(dir * 0.9, 0.5, 0), 12.0):
			want.clear()
	# Gegen eine Wand oder Stufe gelaufen: drüberspringen.
	if on_floor and not want.is_empty() and me.is_on_wall() and wall_jump_time <= 0.0:
		wall_jump_time = 0.5
		_tap("jump", 0.3)

	if think_timer <= 0.0:
		think_timer = level.reaction * randf_range(0.7, 1.3)
		_decide(to_foe, dist, toward)
	_hold(want)


## Einen Schritt des Weges ausführen: zur Absprungstelle laufen, dort springen, durchfallen oder weiterlaufen.
func _follow_route(pos: Vector3, on_floor: bool, want: Array) -> void:
	if route.do in ["edge", "walk"]:
		# Einfach weiterlaufen, bis man drüben (oder unten) ist.
		want.append("right" if route.steer.x > pos.x else "left")
		return
	if absf(route.x - pos.x) > 0.3:
		want.append("right" if route.x > pos.x else "left")
		return
	if not on_floor:
		return
	match route.do:
		"jump":
			_tap("jump", 0.3)
			steer = route.steer
			steer_time = 1.3
			route = {}
		"drop":
			if me.on_platform:
				me._drop_through()
			route = {}


## Gibt es unter `from` (bis `depth` Meter tiefer) Boden oder eine Plattform?
func _ground_below(from: Vector3, depth: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -depth, 0), 3)
	return not me.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Alle Flächen, auf denen man stehen kann: {"x1", "x2" (linke und rechte Kante), "y" (Oberkante), "solid"}.
## Fahrende Plattformen werden jedes Mal neu vermessen.
func _surfaces() -> Array:
	var list := []
	if map == null:
		return list
	for body in map.find_children("*", "StaticBody3D", true, false):
		var solid: bool = body.get_collision_layer_value(1)
		if not solid and not body.get_collision_layer_value(2):
			continue
		for c in body.get_children():
			if not (c is CollisionShape3D and c.shape is BoxShape3D):
				continue
			var size: Vector3 = c.shape.size * c.global_transform.basis.get_scale()
			if size.x < 0.8:
				continue
			var at: Vector3 = c.global_position
			list.append({"x1": at.x - size.x / 2.0, "x2": at.x + size.x / 2.0, "y": at.y + size.y / 2.0, "solid": solid})
	return list


## Auf welcher Fläche steht jemand (oder über welcher ist er gerade)? -1 = über dem Abgrund.
func _surface_under(p: Vector3, list: Array) -> int:
	var best := -1
	var best_dy := 14.0
	for i in list.size():
		var s: Dictionary = list[i]
		if p.x < s.x1 - 0.3 or p.x > s.x2 + 0.3:
			continue
		var dy: float = p.y - s.y
		if dy > -0.5 and dy < best_dy:
			best = i
			best_dy = dy
	return best


## Kürzesten Weg von der eigenen Fläche zur Fläche des Gegners suchen und den ersten Schritt zurückgeben.
func _plan_route() -> Dictionary:
	var list := _surfaces()
	var start := _surface_under(me.global_position, list)
	var goal := _surface_under(_goal_pos(), list)
	var far: bool = absf(_goal_pos().x - me.global_position.x) > 3.0
	if roam_time <= 0.0 and far and not list.is_empty() and randf() < 0.025:
		roam = randi() % list.size()
		roam_time = 5.0
	if roam_time > 0.0 and far and roam < list.size():
		if roam == start:
			roam_time = 0.0
		else:
			goal = roam
	if start < 0 or goal < 0 or start == goal:
		return {}
	# Dijkstra: Kosten = gelaufene Strecke, Höhe zählt etwas mehr.
	var cost := {start: 0.0}
	var at_x := {start: me.global_position.x}
	var first := {start: {}}
	var open := [start]
	var done := {}
	while not open.is_empty():
		var a: int = open[0]
		for o in open:
			if cost[o] < cost[a]:
				a = o
		open.erase(a)
		if a == goal:
			return first[a]
		done[a] = true
		for b in list.size():
			if b == a or done.has(b):
				continue
			var link := _link(list[a], list[b], at_x[a])
			if link.is_empty():
				continue
			var c: float = cost[a] + link.cost
			if not cost.has(b) or c < cost[b]:
				cost[b] = c
				at_x[b] = link.steer.x
				first[b] = link if a == start else first[a]
				if b not in open:
					open.append(b)
	return {}


## Wie kommt man von Fläche a (man steht bei x) auf Fläche b? Leer = gar nicht.
func _link(a: Dictionary, b: Dictionary, x: float) -> Dictionary:
	var dy: float = b.y - a.y
	var lo: float = maxf(a.x1, b.x1)
	var hi: float = minf(a.x2, b.x2)
	var right: bool = (b.x1 + b.x2) > (a.x1 + a.x2)
	var gap: float = maxf(b.x1 - a.x2, a.x1 - b.x2)
	var link := {}
	if absf(dy) <= 0.35:
		# Gleiche Höhe: direkt weiterlaufen oder über die Lücke springen.
		if gap <= 0.3:
			link = {"x": a.x2 if right else a.x1, "do": "walk", "steer": Vector2(b.x1 + 0.8 if right else b.x2 - 0.8, b.y)}
		elif gap <= MAX_GAP:
			link = {"x": a.x2 - 0.3 if right else a.x1 + 0.3, "do": "jump",
				"steer": Vector2(b.x1 + 0.8 if right else b.x2 - 0.8, b.y)}
	elif dy > 0.0:
		# Nach oben: durch eine Plattform hindurch oder seitlich an ihr vorbei hochspringen.
		if dy > MAX_CLIMB or gap > 3.0:
			return {}
		if not b.solid and hi - lo > 0.8:
			var jx := clampf(x, lo + 0.4, hi - 0.4)
			link = {"x": jx, "do": "jump", "steer": Vector2(jx, b.y)}
		elif gap > 0.0:
			link = {"x": a.x2 - 0.3 if right else a.x1 + 0.3, "do": "jump",
				"steer": Vector2(b.x1 + 0.8 if right else b.x2 - 0.8, b.y)}
		else:
			var left_ok: bool = a.x1 < b.x1 - 0.7
			var right_ok: bool = a.x2 > b.x2 + 0.7
			if left_ok and (not right_ok or absf(x - b.x1) < absf(x - b.x2)):
				link = {"x": b.x1 - 0.6, "do": "jump", "steer": Vector2(b.x1 + 0.8, b.y)}
			elif right_ok:
				link = {"x": b.x2 + 0.6, "do": "jump", "steer": Vector2(b.x2 - 0.8, b.y)}
	else:
		# Nach unten: durch die Plattform fallen lassen oder über die Kante hinunterlaufen.
		if not a.solid and hi - lo > 0.8:
			var dx := clampf(x, lo + 0.4, hi - 0.4)
			link = {"x": dx, "do": "drop", "steer": Vector2(dx, b.y)}
		else:
			var off_right: bool = b.x2 > a.x2 + 0.5 and b.x1 < a.x2 + 2.5
			var off_left: bool = b.x1 < a.x1 - 0.5 and b.x2 > a.x1 - 2.5
			if off_right and (not off_left or absf(x - a.x2) < absf(x - a.x1)):
				link = {"x": a.x2, "do": "edge", "steer": Vector2(maxf(a.x2 + 1.0, b.x1 + 0.6), b.y)}
			elif off_left:
				link = {"x": a.x1, "do": "edge", "steer": Vector2(minf(a.x1 - 1.0, b.x2 - 0.6), b.y)}
	if link.is_empty():
		return {}
	# Beim Hochspringen darf kein fester Boden über dem Kopf sein (sonst stößt man sich an und fällt).
	if link.do == "jump" and not _clear_above(link.x, a.y + 0.3, maxf(b.y, a.y) + 2.0):
		return {}
	link.cost = absf(link.x - x) + absf(link.steer.x - link.x) + maxf(dy, 0.0) * 1.5 + absf(dy) * 0.5 + 0.5
	return link


## Ist senkrecht über x zwischen den Höhen y1 und y2 frei (kein fester Boden)?
func _clear_above(x: float, y1: float, y2: float) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, y1, 0), Vector3(x, y2, 0), 1)
	return me.get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Wohin steuern, wenn man neben der Bühne fällt: die nächste Fläche, die man noch erreichen kann.
## Unter festem Boden geht es nicht hindurch, dann zur Kante steuern (dort hält man sich fest).
func _recovery_goal(pos: Vector3) -> Vector2:
	var best := Vector2(0, 0)
	var best_cost := INF
	for s in _surfaces():
		var x := clampf(pos.x, s.x1 + 0.6, s.x2 - 0.6)
		if s.solid and pos.y < s.y - 0.5:
			# Unter festem Boden kommt man nicht hindurch: außen an der Kante hochsteigen.
			if pos.x <= s.x1 or (pos.x < s.x2 and pos.x - s.x1 < s.x2 - pos.x):
				x = s.x1 - 0.3
			else:
				x = s.x2 + 0.3
		var c: float = absf(x - pos.x) + maxf(s.y - pos.y, 0.0) * 1.5
		if c < best_cost:
			best_cost = c
			best = Vector2(x, s.y)
	return best


## Entscheidung im Takt der Reaktionszeit: springen, schlagen, treten, Spezial.
func _decide(to_foe: Vector3, dist: float, toward: String) -> void:
	# Final Smash bereit und der Gegner etwa auf gleicher Höhe: abfeuern.
	if me.final_smash_ready:
		var real := foe.global_position - me.global_position
		if foe.visible and absf(real.y) < 2.0 and randf() < 0.5 + level.aggression * 0.5:
			_turn_to("right" if real.x > 0.0 else "left")
			_tap("special")
			return
	# Gegner deutlich tiefer und man steht auf einer Plattform: hindurchfallen (wie doppelt "runter").
	if to_foe.y < -1.2 and me.on_platform and route.is_empty():
		me._drop_through()
		return
	# Gegner deutlich höher (auf einer Plattform): hinterherspringen, oben noch ein zweites Mal.
	if to_foe.y > 1.2 and dist < 4.0 and route.is_empty() and me.jumps_left > 0 and (me.is_on_floor() or me.velocity.y < 1.0):
		_tap("jump", 0.3)
		return
	if randf() < level.mistakes:
		# Fehler: zufällig ins Leere schlagen oder herumhüpfen.
		_tap(["weak", "jump", "kick"].pick_random(), 0.1)
		return
	var special: String = me.fighter.get("special", "feuerball")
	if me.special_ready() and absf(to_foe.y) < 1.5:
		var in_range := dist < 9.0 if special in RANGED_SPECIALS else dist < 2.0
		if in_range and randf() < level.aggression:
			_turn_to(toward)
			_tap("special")
			return
	# Fernkämpfer: aus der Ferne den starken Angriff verschießen (manchmal aufgeladen), schräg nach oben, wenn der Gegner höher ist.
	if me.fighter.has("fernschuss") and me.is_on_floor() and dist > 2.5 and dist < 11.0 and randf() < level.aggression * 0.6:
		var up := to_foe.y > 1.5 and to_foe.y < dist * 2.5
		if up or absf(to_foe.y) < (2.0 if me.fighter.fernschuss == "fluch" else 1.0):
			_turn_to(toward)
			if up:
				_tap("up", 0.15)
			_tap("strong", 0.06 if randf() < 0.5 else 0.3 + randf() * 0.7)
			return
	# Gegner wehrt ab (oder steht einfach dicht davor): packen, denn Greifen geht durch den Schild.
	if me.is_on_floor() and dist < 1.3 and absf(to_foe.y) < 1.0 and (foe.shielding and randf() < level.aggression \
			or randf() < 0.12):
		_turn_to(toward)
		me.start_grab()
		return
	# Richtungs-Angriffe: Gegner über einem = nach oben schlagen, unter einem (in der Luft) = nach unten.
	if dist < 1.4 and to_foe.y > 1.0 and to_foe.y < 2.6 and randf() < level.aggression:
		_turn_to(toward)
		_tap("up", 0.12)
		_tap("strong" if me.is_on_floor() and randf() < 0.4 else "weak")
		return
	if not me.is_on_floor() and dist < 1.2 and to_foe.y < -0.6 and to_foe.y > -2.2 and randf() < level.aggression:
		_tap("down", 0.12)
		_tap("weak")
		return
	if dist < 1.9 and absf(to_foe.y) < 1.4 and randf() < level.aggression:
		_turn_to(toward)
		var r := randf()
		if me.is_on_floor() and r < 0.75 and randf() < 0.3:
			# Manchmal tief schlagen (schwach oder stark).
			_tap("down", 0.12)
		if r >= 0.5 and r < 0.75 and me.is_on_floor() and (foe.stunned > 0.0 or randf() < 0.3 * level.aggression):
			# Smash-Angriff: starken Angriff etwas aufladen.
			_tap("strong", 0.4 + randf() * 0.5)
			return
		_tap("weak" if r < 0.5 else "strong" if r < 0.75 else "kick")


## Wohin der Computer will: zum Gegner, oder zur Smash-Kugel, wenn sie nicht zu weit weg ist.
func _goal_pos() -> Vector3:
	if not me.final_smash_ready:
		for ball in get_tree().get_nodes_in_group(Target.GROUP):
			if ball.has_method("hit_by") and ball.global_position.distance_to(me.global_position) < 9.0:
				return ball.global_position - Vector3(0, 1.0, 0)
	return foe.global_position


## Kurz in Richtung des Gegners drehen, damit der Schlag nach vorne geht.
func _turn_to(dir: String) -> void:
	var want := 1 if dir == "right" else -1
	if me.facing != want:
		me.facing = want


func _action(name: String) -> String:
	return "p%d_%s" % [me.player_id, name]


## Tasten gedrückt halten (Richtungen, Schild); alles andere wird losgelassen.
## Gehaltene Richtungen bleiben gedrückt, sonst würde doppeltes Antippen eine Ausweichrolle auslösen.
func _hold(actions: Array) -> void:
	for a in held.keys():
		if a not in actions:
			Input.action_release(_action(a))
			held.erase(a)
	for a in actions:
		if not held.has(a):
			Input.action_press(_action(a))
			held[a] = true


## Taste kurz drücken (Sprung, Schlag, Spezial). Beim Sprung bestimmt die Haltezeit die Höhe.
func _tap(name: String, hold := 0.06) -> void:
	var action := _action(name)
	Input.action_press(action)
	get_tree().create_timer(hold).timeout.connect(func(): Input.action_release(action))


func _exit_tree() -> void:
	for a in held.keys():
		Input.action_release(_action(a))
