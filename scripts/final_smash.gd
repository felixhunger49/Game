class_name FinalSmash
extends Node3D
## Der Final Smash als kleine Filmszene, für jede Figur eine eigene (wie bei Smash Bros):
## 1. Auftakt: Bild wird dunkler, die Kamera fährt an die Figur heran, der Name des Final Smash erscheint.
## 2. Die eigentliche Szene der Figur (siehe SCENES). Getroffene Gegner werden festgehalten ("gefangen")
##    und bekommen nach und nach Schaden.
## 3. Abschlussschlag: alle Gefangenen fliegen weit weg.
## Solange die Szene läuft, führt sie die Kamera (Fight._update_camera macht dann nichts).

const GROUP := "final_smash"
## Name des Final Smash und Funktion der Szene je Figur. Unbekannte Figuren bekommen den Strahl.
const SCENES := {
	"Barbar": ["Kriegsgott", "_barbar"],
	"Schurke": ["Schattenklingen", "_schurke"],
	"Held": ["Phönixflug", "_held"],
	"Paladin": ["Heiliger Hammer", "_paladin"],
	"Brummbart": ["Steinriese", "_brummbart"],
	"Hexe": ["Hexenkessel", "_hexe"],
	"Jägerin": ["Geisterwolf-Rudel", "_jaegerin"],
	"Piratin": ["Krake", "_piratin"],
	"Mönch": ["Goldener Drache", "_moench"],
	"Kampfroboter": ["Raketensturm", "_roboter"],
	"Magierin": ["Zeitstopp", "_magierin"],
}
## Kleine Treffer während der Szene (nur Schaden, kein Wegfliegen).
const TICK := 2.5
## Der Abschlussschlag: sehr stark, damit man ab etwa 60 % aus der Arena fliegt.
const FINISH := {"damage": 12.0, "base": 15.0, "scale": 0.32, "angle": Vector2(1, 0.6)}

var player: CharacterBody3D
var world: Node
var camera: Camera3D
var victims: Array = []
var overlay: ColorRect
var ui: CanvasLayer
var area := Rect2(-8, 0, 16, 8)
var color := Color.WHITE


func start(attacker: CharacterBody3D) -> void:
	add_to_group(GROUP)
	player = attacker
	world = get_parent()
	camera = get_viewport().get_camera_3d()
	# Die Szenen spielen über dem Hauptboden (y = 0), nicht in Kellern oder Höhlen der Map.
	var map: Node = world.get("map_node")
	var half: float = map.get_meta("event_half", 7.5) if map else 7.5
	area = Rect2(-half, 0.0, half * 2.0, maxf(MapLook.area_of(map).end.y, 5.0))
	color = player.color
	_run()


func _run() -> void:
	var entry: Array = SCENES.get(player.fighter.get("name", ""), ["Super-Strahl", "_strahl"])
	await _intro(entry[0])
	await call(entry[1])
	await _outro()


# --- Auftakt und Ende ---------------------------------------------------------------------------------------

func _intro(title: String) -> void:
	ui = CanvasLayer.new()
	ui.layer = 1
	add_child(ui)
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(overlay)
	_dim(0.45, 0.3)
	_banner(title)
	player._play("special", 0.8)
	player.say("spezial")
	Audio.sfx("special_start", 0.7)
	Audio.sfx("thunder", 1.4, -8.0)
	var pos := _chest(player)
	SpecialFX._flash_sphere(world, pos, color.lightened(0.4), 0.2, 1.8, 0.8)
	SpecialFX._ring(world, pos, color, 3.0, 0.3, 0.8, true)
	SpecialFX._ring(world, pos, Color.WHITE, 4.0, 0.5, 0.6, true)
	SpecialFX._flash_light(world, pos, color, 8.0, 6.0, 0.8)
	_cam(pos, 6.0, 0.35)
	await _wait(0.9)


func _outro() -> void:
	for v in victims:
		if is_instance_valid(v):
			v.caught = false
	_dim(0.0, 0.4)
	if is_instance_valid(player):
		player.end_final_smash()
	await _wait(0.45)
	queue_free()


## Name des Final Smash als großes Banner, das von rechts hereinfliegt.
func _banner(title: String) -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	box.position = Vector2(get_viewport().get_visible_rect().size.x + 50, get_viewport().get_visible_rect().size.y * 0.22)
	var small := Label.new()
	small.text = "FINAL SMASH"
	small.add_theme_font_size_override("font_size", 26)
	small.add_theme_color_override("font_color", Color(1, 1, 1))
	small.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	small.add_theme_constant_override("outline_size", 8)
	var big := Label.new()
	big.text = title
	var font: Font = load("res://assets/fonts/LilitaOne-Regular.ttf")
	big.add_theme_font_override("font", font)
	small.add_theme_font_override("font", font)
	big.add_theme_font_size_override("font_size", 64)
	big.add_theme_color_override("font_color", color.lightened(0.35))
	big.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	big.add_theme_constant_override("outline_size", 14)
	box.add_child(small)
	box.add_child(big)
	ui.add_child(box)
	var target_x := get_viewport().get_visible_rect().size.x * 0.5 - 40.0
	var tween := box.create_tween()
	tween.tween_property(box, "position:x", target_x, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(box, "position:x", target_x - 60.0, 1.2)
	tween.tween_property(box, "modulate:a", 0.0, 0.3)
	tween.tween_callback(box.queue_free)


# --- Werkzeuge für die Szenen ------------------------------------------------------------------------------

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


func _dim(alpha: float, seconds: float) -> void:
	if overlay:
		overlay.create_tween().tween_property(overlay, "color:a", alpha, seconds)


func _tint(c: Color, seconds: float) -> void:
	if overlay:
		var tween := overlay.create_tween()
		tween.tween_property(overlay, "color", c, seconds)


## Kamera auf eine Stelle fahren (distance = Abstand nach vorne).
func _cam(pos: Vector3, distance: float, seconds: float) -> void:
	if camera == null:
		return
	var target := Vector3(pos.x, pos.y + 0.6, pos.z + distance)
	camera.create_tween().tween_property(camera, "position", target, seconds).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## Kamera so, dass die ganze Bühne zu sehen ist.
func _cam_stage(seconds: float, extra := 0.0) -> void:
	var c := area.get_center()
	_cam(Vector3(c.x, c.y + 1.0, 0), clampf(9.0 + area.size.x * 0.4, 13.0, 19.0) + extra, seconds)


func _chest(p: Node3D) -> Vector3:
	return p.global_position + Vector3(0, 1.0 * p.get("size_scale"), 0)


func _enemies() -> Array:
	return player._enemies().filter(func(e): return is_instance_valid(e) and e.visible and not e.boss)


## Gegner festhalten (er bleibt in der Luft stehen, bis der Abschlussschlag kommt).
func _catch(enemy: Node) -> void:
	if enemy in victims:
		return
	victims.append(enemy)
	enemy.caught = true
	enemy.hitstun = 0.0
	enemy.velocity = Vector3.ZERO
	SpecialFX._flash_sphere(world, _chest(enemy), Color.WHITE, 0.2, 1.0, 0.15)
	Audio.sfx("hit_strong", 1.1)


## Kleiner Treffer mit Funken (zählt Schaden hoch, ohne dass der Gefangene wegfliegt).
func _tick(enemy: Node, c: Color, amount := TICK) -> void:
	if not is_instance_valid(enemy):
		return
	enemy.damage += amount * player.outgoing_multiplier() * enemy._damage_taken_multiplier()
	var pos := _chest(enemy) + Vector3(randf_range(-0.4, 0.4), randf_range(-0.5, 0.5), 0.3)
	SpecialFX._sparks(world, pos, c, 10, 6.0, 0.3)
	SpecialFX._flash_sphere(world, pos, Color.WHITE, 0.1, 0.45, 0.08)
	Audio.sfx("hit_weak", randf_range(0.9, 1.3), -3.0)


func _tick_all(c: Color, amount := TICK) -> void:
	for v in victims:
		_tick(v, c, amount)


## Abschlussschlag für alle Gefangenen. direction: Richtung (x wird zur Seite weg vom Angreifer gedreht, wenn away).
func _launch_all(direction: Vector2, away := true, attack := FINISH) -> void:
	for v in victims:
		if not is_instance_valid(v):
			continue
		v.caught = false
		var side := signf(v.global_position.x - player.global_position.x)
		if side == 0.0:
			side = float(player.facing)
		var dir := Vector3(direction.x * (side if away else 1.0), direction.y, 0).normalized()
		if v.take_hit(attack, dir, false, player.outgoing_multiplier()):
			player.on_hit_landed(v)
	victims.clear()


## Leuchtendes Teil (unbeleuchtet, additiv), z. B. für Licht, Strahlen, Klingen.
func _glow(mesh: Mesh, c: Color, energy := 2.5) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = SpecialFX._glow_material(c, energy)
	add_child(m)
	return m


## Festes Teil mit Farbe (z. B. Schiff, Felsen, Kessel). emission > 0 lässt es leuchten.
func _solid(mesh: Mesh, c: Color, emission := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.6
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = emission
	if c.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	add_child(m)
	return m


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _cyl(radius: float, height: float, top := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = radius if top < 0.0 else top
	c.bottom_radius = radius
	c.height = height
	return c


func _ball(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	return s


func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	return t


## Explosion an einer Stelle (Kanonenkugel, Meteor, Fels).
func _boom(pos: Vector3, c: Color, size := 1.0) -> void:
	SpecialFX._flash_sphere(world, pos, Color(1, 0.95, 0.8), 0.3 * size, 2.2 * size, 0.3)
	SpecialFX._sparks(world, pos, c, int(30 * size), 8.0 * size, 0.6)
	SpecialFX._ring(world, pos, c, 0.3, 2.5 * size, 0.35, true)
	SpecialFX._flash_light(world, pos, c, 8.0 * size, 6.0 * size, 0.4)
	SpecialFX.shake(player, 0.25 * size, 0.25)
	Audio.sfx("explosion", randf_range(0.85, 1.1), -2.0)


## Gegner in der Nähe einer Stelle (für Treffer von Geschossen in der Szene).
func _enemies_near(pos: Vector3, rx: float, ry: float) -> Array:
	return _enemies().filter(func(e):
		var d: Vector3 = _chest(e) - pos
		return absf(d.x) <= rx and absf(d.y) <= ry)


func _fade_out(node: Node3D, seconds: float) -> void:
	var tween := node.create_tween()
	tween.tween_property(node, "scale", node.scale * 0.01, seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(node.queue_free)


# --- Die Szenen ----------------------------------------------------------------------------------------------

## Schurke: alles wird dunkel, er verschwindet und zerschneidet die Gegner mit leuchtenden Schattenklingen.
func _schurke() -> void:
	var purple := Color(0.7, 0.3, 1.0)
	_tint(Color(0.08, 0, 0.15, 0.75), 0.25)
	for e in _enemies():
		if absf(e.global_position.y - player.global_position.y) < 4.0 and absf(e.global_position.x - player.global_position.x) < 12.0:
			_catch(e)
	SpecialFX._flash_sphere(world, _chest(player), purple, 0.3, 1.2, 0.2)
	player.model_root.visible = false
	Audio.sfx("dash", 1.3)
	if victims.is_empty():
		await _wait(0.5)
		player.model_root.visible = true
		return
	_cam(_chest(victims[0]), 6.5, 0.3)
	for i in 12:
		for v in victims:
			var pos := _chest(v)
			var slash := _glow(_box(Vector3(4.0, 0.08, 0.08)), purple if i % 2 == 0 else Color(1, 1, 1), 3.0)
			slash.global_position = pos + Vector3(0, 0, 0.4)
			slash.rotation.z = randf_range(-PI, PI)
			slash.scale = Vector3(0.1, 1, 1)
			var tween := slash.create_tween()
			tween.tween_property(slash, "scale", Vector3(1, 1, 1), 0.06)
			tween.tween_property(slash, "scale", Vector3(1.2, 0.1, 0.1), 0.15)
			tween.tween_callback(slash.queue_free)
			_tick(v, purple, 2.0)
		Audio.sfx("swing_weak", randf_range(1.1, 1.5), -2.0)
		await _wait(0.08)
	# Großer X-Schnitt, dann taucht der Schurke hinter den Gegnern wieder auf.
	var target := _chest(victims[0])
	for angle in [PI / 4.0, -PI / 4.0]:
		var cut := _glow(_box(Vector3(7.0, 0.25, 0.1)), Color(1, 0.85, 1.0), 3.5)
		cut.global_position = target + Vector3(0, 0, 0.5)
		cut.rotation.z = angle
		_fade_out(cut, 0.5)
	player.global_position = victims[0].global_position + Vector3(player.facing * 1.6, 0, 0)
	player.model_root.visible = true
	player._play("strong", 1.6)
	Audio.sfx("sword_clash")
	_boom(target, purple, 1.3)
	_launch_all(Vector2(1.0, 0.45), true)
	await _wait(0.5)


## Paladin: ein riesiger heiliger Hammer saust vom Himmel, Lichtsäulen laufen über den Boden.
func _paladin() -> void:
	var light := Color(1, 0.95, 0.6)
	_tint(Color(0.12, 0.1, 0.02, 0.35), 0.3)
	var ground := player.global_position
	var impact := ground + Vector3(player.facing * 3.0, 0, 0)
	# Hammer mit Stiel und Kopf, dreht sich um das obere Ende nach vorne.
	var pivot := Node3D.new()
	add_child(pivot)
	pivot.global_position = ground + Vector3(0, 7.0, 0)
	var handle := _solid(_cyl(0.18, 6.0), Color(0.55, 0.4, 0.2))
	handle.reparent(pivot, false)
	handle.position.y = -3.0
	var head := _glow(_box(Vector3(2.4, 1.4, 1.4)), light, 2.6)
	head.reparent(pivot, false)
	head.position.y = -6.2
	var trim := _glow(_box(Vector3(2.6, 0.3, 1.6)), Color(1, 0.75, 0.3), 3.0)
	trim.reparent(pivot, false)
	trim.position.y = -6.2
	pivot.rotation.z = -player.facing * 2.6
	pivot.scale = Vector3.ONE * 0.01
	pivot.create_tween().tween_property(pivot, "scale", Vector3.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	player._start_dome() if player.has_method("_start_dome") else null
	Audio.sfx("pickup_heal", 0.7)
	_cam(ground + Vector3(player.facing * 1.5, 2.5, 0), 11.0, 0.4)
	await _wait(0.55)
	var swing := pivot.create_tween()
	swing.tween_property(pivot, "rotation:z", player.facing * 0.45, 0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	Audio.sfx("swing_strong", 0.6)
	await _wait(0.28)
	if player.has_method("_end_dome"):
		player._end_dome()
	_boom(impact + Vector3(0, 0.4, 0), light, 2.0)
	for e in _enemies():
		if absf(e.global_position.y - ground.y) < 3.0 and absf(e.global_position.x - impact.x) < 9.0:
			_catch(e)
	_cam_stage(0.4)
	# Lichtsäulen laufen nach beiden Seiten.
	for i in 7:
		for side in [-1, 1]:
			var col := _glow(_cyl(0.45, 6.0), light, 2.2)
			col.global_position = impact + Vector3(side * (i + 1) * 1.4, 3.0, 0)
			col.scale = Vector3(1, 0.05, 1)
			var t := col.create_tween()
			t.tween_property(col, "scale", Vector3.ONE, 0.12)
			t.tween_property(col, "scale", Vector3(0.05, 1, 0.05), 0.35)
			t.tween_callback(col.queue_free)
		_tick_all(light, 2.5)
		Audio.sfx("special_hit", 1.3, -8.0)
		await _wait(0.07)
	_launch_all(Vector2(0.55, 0.85))
	_fade_out(pivot, 0.4)
	await _wait(0.5)


## Hexe: ein riesiger Kessel steigt aus dem Boden, ein grüner Strudel saugt die Gegner hinein, dann explodiert alles.
func _hexe() -> void:
	var green := Color(0.4, 1.0, 0.35)
	var dark := Color(0.12, 0.1, 0.12)
	_tint(Color(0.02, 0.12, 0.02, 0.5), 0.3)
	var spot := Vector3(clampf(player.global_position.x + player.facing * 3.0, area.position.x + 2.0, area.end.x - 2.0),
		player.global_position.y, 0)
	var pot := Node3D.new()
	add_child(pot)
	var body := _solid(_cyl(1.8, 2.2, 2.1), dark)
	body.reparent(pot, false)
	body.position.y = 1.1
	var rim := _solid(_torus(1.9, 2.3), Color(0.2, 0.18, 0.2))
	rim.reparent(pot, false)
	rim.position.y = 2.2
	var brew := _glow(_cyl(1.85, 0.1), green, 2.8)
	brew.reparent(pot, false)
	brew.position.y = 2.1
	pot.global_position = spot - Vector3(0, 3.0, 0)
	pot.create_tween().tween_property(pot, "global_position", spot, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	Audio.sfx("bubbles", 0.7)
	_cam(spot + Vector3(0, 2.0, 0), 11.0, 0.4)
	await _wait(0.5)
	# Strudel über dem Kessel, zieht alle Gegner in der Nähe hinein.
	var swirl := []
	for i in 3:
		var ring := _glow(_torus(1.0 + i * 0.9, 1.25 + i * 0.9), green, 2.4)
		ring.global_position = spot + Vector3(0, 3.0 + i * 0.6, 0)
		swirl.append(ring)
	for e in _enemies():
		if e.global_position.distance_to(spot) < 9.0:
			_catch(e)
			e.create_tween().tween_property(e, "global_position", spot + Vector3(randf_range(-0.6, 0.6), 2.3, 0), 0.7) \
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	Audio.sfx("wind", 1.2)
	for i in 16:
		for j in swirl.size():
			swirl[j].rotation.y += 0.5 + j * 0.2
			swirl[j].rotation.x = sin(i * 0.4 + j) * 0.3
		if i > 6:
			_tick_all(green, 2.0)
			SpecialFX._sparks(world, spot + Vector3(0, 2.3, 0), green, 12, 4.0, 0.5)
			if i % 4 == 0:
				Audio.sfx("bubbles", randf_range(0.9, 1.3), -4.0)
		await _wait(0.07)
	for ring in swirl:
		_fade_out(ring, 0.25)
	_boom(spot + Vector3(0, 2.4, 0), green, 2.0)
	_launch_all(Vector2(0.2, 1.0))
	await _wait(0.3)
	pot.create_tween().tween_property(pot, "global_position", spot - Vector3(0, 3.5, 0), 0.5).set_ease(Tween.EASE_IN)
	await _wait(0.4)


## Mönch: beschwört einen goldenen Geisterdrachen, der sich durch die Arena schlängelt und die Gegner mitreißt.
func _moench() -> void:
	var gold := Color(1, 0.62, 0.08)
	_tint(Color(0.12, 0.08, 0, 0.5), 0.3)
	player._play("special", 0.9)
	_cam_stage(0.6)
	# Der Drache: eine Kette leuchtender Kugeln (Kopf vorne groß), die einer Schlangenlinie folgt.
	var segments := []
	for i in 18:
		var size := 1.2 - i * 0.045
		var seg := _solid(_ball(size), gold.lerp(Color(0.9, 0.3, 0.05), i / 18.0) if i > 0 else Color(1, 0.8, 0.3), 1.1)
		segments.append(seg)
	var eyes := _glow(_box(Vector3(0.5, 0.12, 0.1)), Color(1, 0.2, 0.1), 4.0)
	var horn := _glow(_cyl(0.12, 1.2, 0.0), Color(1, 1, 0.9), 3.0)
	var x0 := area.position.x - 6.0 if player.facing > 0 else area.end.x + 6.0
	var dir := float(player.facing)
	var path := func(t: float) -> Vector3:
		var x: float = x0 + dir * t * (area.size.x + 12.0)
		var y: float = area.position.y + 2.5 + sin(t * TAU * 1.5) * 2.2
		return Vector3(x, y, 0.3)
	Audio.sfx("wind", 0.6)
	Audio.sfx("thunder", 0.8, -4.0)
	var steps := 60
	for s in steps:
		var t := float(s) / steps
		for i in segments.size():
			var ti := maxf(t - i * 0.018, 0.0)
			segments[i].global_position = path.call(ti)
		var head: Vector3 = segments[0].global_position
		eyes.global_position = head + Vector3(dir * 0.5, 0.25, 0.6)
		horn.global_position = head + Vector3(-dir * 0.3, 0.8, 0)
		horn.rotation.z = -dir * 0.6
		for e in _enemies_near(head, 1.6, 1.8):
			_catch(e)
		for v in victims:
			v.global_position = head - Vector3(0, 1.0, 0) + Vector3(-dir * 0.4, 0, 0)
		if s % 4 == 0:
			_tick_all(gold, 2.5)
			SpecialFX._sparks(world, head, gold, 8, 3.0, 0.4)
		await _wait(0.03)
	for seg in segments:
		_fade_out(seg, 0.3)
	_fade_out(eyes, 0.3)
	_fade_out(horn, 0.3)
	Audio.sfx("special_hit")
	for v in victims:
		_boom(_chest(v), gold, 1.4)
	_launch_all(Vector2(dir * 0.7, 0.75), false)
	await _wait(0.5)


## Barbar: wächst zum Kriegsgott, stampft nach vorne und zerschmettert alles mit einem gewaltigen Axthieb.
func _barbar() -> void:
	var red := Color(1, 0.35, 0.15)
	_tint(Color(0.25, 0.02, 0, 0.45), 0.3)
	var pivot: Node3D = player.flip_pivot
	pivot.create_tween().tween_property(pivot, "scale", Vector3.ONE * 2.6, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	SpecialFX._flash_sphere(world, _chest(player), red, 0.5, 3.0, 0.5)
	Audio.sfx("thunder", 0.7)
	player.say("ha", "ha", 0.7)
	_cam(_chest(player) + Vector3(player.facing * 3.0, 1.5, 0), 13.0, 0.5)
	await _wait(0.6)
	# Drei schwere Schritte nach vorne.
	for step in 3:
		player._play("run", 0.8)
		var goal := player.global_position + Vector3(player.facing * 1.8, 0, 0)
		goal.x = clampf(goal.x, area.position.x - 1.0, area.end.x + 1.0)
		player.create_tween().tween_property(player, "global_position", goal, 0.25)
		await _wait(0.25)
		SpecialFX.dust(world, player.global_position, 14, 3.0)
		SpecialFX.shake(player, 0.6, 0.25)
		Audio.sfx("boulder", 0.6, -2.0)
		for e in _enemies_near(_chest(player) + Vector3(player.facing * 2.5, 1.0, 0), 3.5, 3.5):
			_catch(e)
		# Gefangene werden vor ihm hergeschoben.
		for v in victims:
			var front: float = goal.x + player.facing * 1.8
			if (v.global_position.x - front) * player.facing < 0.0:
				v.create_tween().tween_property(v, "global_position:x", front, 0.15)
		_tick_all(red, 3.0)
		await _wait(0.1)
	# Der Riesenhieb.
	player._play("strong", 1.0)
	Audio.sfx("swing_strong", 0.5)
	await _wait(0.35)
	var impact := player.global_position + Vector3(player.facing * 3.0, 0.5, 0)
	for e in _enemies_near(impact + Vector3(0, 1.0, 0), 4.0, 4.0):
		_catch(e)
	_boom(impact, red, 2.4)
	SpecialFX.quake(player)
	SpecialFX.shake(player, 1.2, 0.6)
	_launch_all(Vector2(player.facing * 0.7, 0.75), false)
	await _wait(0.4)
	pivot.create_tween().tween_property(pivot, "scale", Vector3.ONE, 0.4)
	await _wait(0.4)


## Held: verwandelt sich in einen brennenden Phönix, fegt durch die Arena, steigt auf und stürzt explodierend herab.
func _held() -> void:
	var fire := Color(1, 0.55, 0.15)
	var gold := Color(1, 0.9, 0.5)
	_tint(Color(0.2, 0.06, 0, 0.5), 0.3)
	var bird := Node3D.new()
	add_child(bird)
	var body := _solid(_ball(0.7), gold, 1.4)
	body.reparent(bird, false)
	body.scale = Vector3(1.6, 0.8, 0.8)
	var head := _solid(_ball(0.38), Color(1, 1, 0.85), 1.4)
	head.reparent(bird, false)
	head.position = Vector3(1.1, 0.35, 0)
	var beak := _solid(_cyl(0.18, 0.6, 0.0), Color(1, 0.7, 0.2), 1.4)
	beak.reparent(bird, false)
	beak.position = Vector3(1.55, 0.3, 0)
	beak.rotation.z = -PI / 2.0
	var wings := []
	for side in [-1, 1]:
		var wing := Node3D.new()
		bird.add_child(wing)
		var plume := _solid(_box(Vector3(1.6, 0.12, 3.2)), fire, 1.4)
		plume.reparent(wing, false)
		plume.position.z = side * 1.6
		var tip := _solid(_box(Vector3(1.0, 0.1, 1.6)), Color(1, 0.3, 0.1), 1.4)
		tip.reparent(wing, false)
		tip.position = Vector3(-0.5, 0, side * 3.6)
		wing.rotation.x = 0.0
		wings.append([wing, side])
	var tail := _solid(_box(Vector3(2.4, 0.1, 1.0)), fire, 1.4)
	tail.reparent(bird, false)
	tail.position = Vector3(-1.8, 0, 0)
	var dir := float(player.facing)
	bird.scale = Vector3(dir, 1, 1) * 1.4
	bird.global_position = _chest(player)
	player.model_root.visible = false
	SpecialFX._flash_sphere(world, _chest(player), fire, 0.3, 2.5, 0.3)
	Audio.sfx("fireball", 0.6)
	_cam(_chest(player), 11.0, 0.3)
	# Flug quer über die Bühne (die Kamera fliegt mit).
	var y := player.global_position.y + 1.2
	var from_x := player.global_position.x
	var to_x := area.end.x + 2.0 if dir > 0 else area.position.x - 2.0
	var steps := 30
	for s in steps:
		var t := float(s + 1) / steps
		bird.global_position = Vector3(lerpf(from_x, to_x, t), y + sin(t * PI * 2.0) * 0.5, 0.3)
		for w in wings:
			w[0].rotation.x = w[1] * sin(s * 0.9) * 0.6
		SpecialFX._sparks(world, bird.global_position - Vector3(dir * 1.5, 0, 0), fire, 6, 2.0, 0.4)
		for e in _enemies_near(bird.global_position, 2.0, 2.5):
			_catch(e)
		for v in victims:
			v.global_position = bird.global_position + Vector3(dir * 0.8, -1.0, 0)
		if s % 5 == 0:
			_tick_all(fire, 2.5)
			Audio.sfx("whirl", 1.3, -6.0)
		if s % 3 == 0:
			_cam(bird.global_position, 11.0, 0.09)
			SpecialFX._flash_sphere(world, bird.global_position - Vector3(dir * 2.5, 0, 0), fire, 0.6, 1.4, 0.35)
		await _wait(0.03)
	_cam(Vector3(area.get_center().x, area.end.y * 0.6 + 2.0, 0), 20.0, 0.4)
	# Aufsteigen, umdrehen und herabstürzen.
	var top := Vector3(to_x - dir * 2.0, area.end.y + 5.0, 0.3)
	bird.create_tween().tween_property(bird, "global_position", top, 0.45).set_ease(Tween.EASE_OUT)
	for v in victims:
		v.create_tween().tween_property(v, "global_position", top + Vector3(0, -1.2, 0), 0.45)
	Audio.sfx("wind", 1.2)
	await _wait(0.5)
	bird.scale = Vector3(-dir, 1, 1) * 1.4
	bird.rotation.z = -dir * 0.9
	var dive := Vector3(area.get_center().x, area.position.y + 0.8, 0.3)
	bird.create_tween().tween_property(bird, "global_position", dive, 0.3).set_ease(Tween.EASE_IN)
	for v in victims:
		v.create_tween().tween_property(v, "global_position", dive - Vector3(0, 0.4, 0), 0.3).set_ease(Tween.EASE_IN)
	await _wait(0.3)
	_boom(dive, fire, 2.6)
	for i in 3:
		var ring := _glow(_torus(0.3, 0.6), gold, 3.0)
		ring.global_position = dive + Vector3(0, 0.1, 0)
		ring.rotation.x = PI / 2.0
		var rt := ring.create_tween()
		rt.tween_property(ring, "scale", Vector3.ONE * (8.0 + i * 4.0), 0.45)
		rt.tween_callback(ring.queue_free)
	for e in _enemies_near(dive + Vector3(0, 1.0, 0), 4.0, 3.0):
		_catch(e)
	_launch_all(Vector2(0.4, 1.0))
	_fade_out(bird, 0.3)
	player.global_position = dive + Vector3(0, 0.2, 0)
	player.model_root.visible = true
	player._play("cheer" if player._has_anim("cheer") else "idle")
	await _wait(0.5)


## Brummbart: ein riesiger Steingolem steigt hinter der Bühne auf und schlägt mit der Faust auf die Gegner.
func _brummbart() -> void:
	var stone := Color(0.5, 0.45, 0.4)
	var glow_eye := Color(1, 0.6, 0.15)
	_tint(Color(0.1, 0.06, 0.02, 0.45), 0.3)
	player._play("special", 0.8)
	var golem := Node3D.new()
	add_child(golem)
	var torso := _solid(_box(Vector3(5.0, 5.5, 3.0)), stone)
	torso.reparent(golem, false)
	var head := _solid(_box(Vector3(2.6, 2.2, 2.4)), stone.darkened(0.1))
	head.reparent(golem, false)
	head.position.y = 4.0
	for side in [-1, 1]:
		var eye := _glow(_box(Vector3(0.5, 0.3, 0.2)), glow_eye, 4.0)
		eye.reparent(golem, false)
		eye.position = Vector3(side * 0.6, 4.2, 1.25)
	var arm_pivot := Node3D.new()
	golem.add_child(arm_pivot)
	arm_pivot.position = Vector3(2.8, 2.0, 0)
	var arm := _solid(_box(Vector3(1.6, 5.0, 1.6)), stone.darkened(0.05))
	arm.reparent(arm_pivot, false)
	arm.position.y = 2.5
	var fist := _solid(_box(Vector3(2.6, 2.4, 2.6)), stone.darkened(0.15))
	fist.reparent(arm_pivot, false)
	fist.position.y = 5.6
	var rune := _glow(_box(Vector3(1.4, 0.3, 0.1)), glow_eye, 3.0)
	rune.reparent(golem, false)
	rune.position = Vector3(0, 0.8, 1.55)
	# Ziel: der nächste Gegner.
	var enemies := _enemies()
	var aim := Vector3(player.global_position.x + player.facing * 4.0, player.global_position.y, 0)
	if not enemies.is_empty():
		enemies.sort_custom(func(a, b): return absf(a.global_position.x - player.global_position.x) < absf(b.global_position.x - player.global_position.x))
		aim = enemies[0].global_position
	# Groß und hinter der Bühne, damit er über Mauern und Türme hinausragt.
	var base := Vector3(aim.x - 4.5, -14.0, -4.5)
	golem.scale = Vector3.ONE * 1.4
	golem.global_position = base
	_cam(Vector3(aim.x, aim.y + 3.0, 0), 18.0, 0.5)
	Audio.sfx("boulder", 0.5)
	SpecialFX.shake(player, 0.6, 1.0)
	golem.create_tween().tween_property(golem, "global_position:y", 2.2, 0.9).set_ease(Tween.EASE_OUT)
	await _wait(0.9)
	# Schatten am Boden, dann holt er aus und schlägt zu.
	var shadow := _glow(_torus(1.6, 2.0), Color(1, 0.2, 0.1), 3.0)
	shadow.global_position = aim + Vector3(0, 0.1, 0)
	shadow.rotation.x = PI / 2.0
	for e in _enemies_near(aim + Vector3(0, 1.0, 0), 3.5, 3.0):
		_catch(e)
	arm_pivot.create_tween().tween_property(arm_pivot, "rotation:z", 0.5, 0.35)
	Audio.sfx("warning", 0.8, -4.0)
	await _wait(0.4)
	var slam := arm_pivot.create_tween()
	slam.tween_property(arm_pivot, "rotation:z", -1.75, 0.18).set_ease(Tween.EASE_IN)
	golem.create_tween().tween_property(golem, "global_position:z", -1.0, 0.18)
	await _wait(0.18)
	shadow.queue_free()
	_boom(aim + Vector3(0, 0.6, 0), glow_eye, 2.4)
	SpecialFX.quake(player)
	SpecialFX.shake(player, 1.3, 0.6)
	for i in 6:
		_tick_all(stone, 2.5)
		SpecialFX._sparks(world, aim + Vector3(randf_range(-2, 2), 0.5, 0.5), stone.lightened(0.3), 12, 7.0, 0.6)
		await _wait(0.06)
	_launch_all(Vector2(0.3, 1.0))
	await _wait(0.3)
	golem.create_tween().tween_property(golem, "global_position:y", -16.0, 0.7).set_ease(Tween.EASE_IN)
	await _wait(0.5)


## Jägerin: heult, und ein Rudel leuchtender Geisterwölfe jagt über die Bühne; der Leitwolf springt zum Schluss.
func _jaegerin() -> void:
	var spirit := Color(0.25, 0.7, 1.0)
	_tint(Color(0, 0.04, 0.12, 0.6), 0.3)
	player._play("special", 0.9)
	Audio.sfx("ghost", 0.9)
	_cam(_chest(player), 10.0, 0.4)
	await _wait(0.3)
	var dir := float(player.facing)
	var start_x := area.position.x - 3.0 if dir > 0 else area.end.x + 3.0
	var end_x := area.end.x + 3.0 if dir > 0 else area.position.x - 3.0
	var floor_y := player.global_position.y
	var wolves := []
	for i in 6:
		wolves.append([_wolf(spirit, 1.0), start_x - dir * i * 2.2, floor_y + (i % 2) * 0.4])
	var steps := 45
	for s in steps:
		var t := float(s + 1) / steps
		for w in wolves:
			var x: float = lerpf(w[1], end_x + dir * 13.0, t)
			var hop := absf(sin(t * PI * 6.0 + w[1])) * 0.8
			w[0].global_position = Vector3(x, w[2] + hop, 0.2)
			w[0].scale = Vector3(dir, 1, 1) * 1.5
			for e in _enemies_near(w[0].global_position + Vector3(0, 0.5, 0), 1.3, 1.6):
				_catch(e)
				_tick(e, spirit, 1.5)
		if s % 6 == 0:
			Audio.sfx("dash", randf_range(1.2, 1.5), -6.0)
		if s % 3 == 0:
			var lead: Vector3 = wolves[2][0].global_position
			_cam(Vector3(clampf(lead.x, area.position.x, area.end.x), floor_y + 1.5, 0), 13.0, 0.09)
		await _wait(0.03)
	for w in wolves:
		w[0].queue_free()
	# Der Leitwolf: riesig, springt von oben auf die Gefangenen.
	var target := _chest(victims[0]) if not victims.is_empty() else Vector3(area.get_center().x, floor_y + 1.0, 0)
	var alpha := _wolf(Color(0.5, 0.85, 1.0), 1.3)
	alpha.global_position = target + Vector3(-dir * 8.0, 6.0, 0.4)
	alpha.scale = Vector3(dir * 3.0, 3.0, 3.0)
	_cam(target + Vector3(-dir * 2.0, 2.0, 0), 15.0, 0.3)
	Audio.sfx("ghost_warn", 0.7)
	alpha.create_tween().tween_property(alpha, "global_position", target + Vector3(0, -0.5, 0.4), 0.35).set_ease(Tween.EASE_IN)
	await _wait(0.35)
	_boom(target, spirit, 2.0)
	for e in _enemies_near(target, 3.0, 3.0):
		_catch(e)
	_launch_all(Vector2(dir * 0.6, 0.8), false)
	_fade_out(alpha, 0.4)
	await _wait(0.5)


## Ein Geisterwolf aus leuchtenden Kästen (Körper, Kopf, Schnauze, Ohren, Schwanz, Beine).
func _wolf(c: Color, energy_scale: float) -> Node3D:
	var wolf := Node3D.new()
	add_child(wolf)
	var parts := [
		[Vector3(1.4, 0.55, 0.5), Vector3(0, 0.75, 0)],
		[Vector3(0.55, 0.5, 0.45), Vector3(0.85, 1.05, 0)],
		[Vector3(0.4, 0.22, 0.3), Vector3(1.2, 0.95, 0)],
		[Vector3(0.12, 0.25, 0.1), Vector3(0.8, 1.4, 0.12)],
		[Vector3(0.12, 0.25, 0.1), Vector3(0.8, 1.4, -0.12)],
		[Vector3(0.7, 0.14, 0.14), Vector3(-0.95, 0.95, 0)],
		[Vector3(0.14, 0.55, 0.14), Vector3(0.5, 0.28, 0.15)],
		[Vector3(0.14, 0.55, 0.14), Vector3(-0.5, 0.28, -0.15)],
	]
	for part in parts:
		# Fest statt additiv, sonst werden die überlappenden Teile weiß.
		var m := _solid(_box(part[0]), Color(c, 0.8), 1.2 * minf(energy_scale, 1.3))
		m.reparent(wolf, false)
		m.position = part[1]
	var eye := _glow(_box(Vector3(0.1, 0.06, 0.5)), Color(1, 1, 1), 4.0)
	eye.reparent(wolf, false)
	eye.position = Vector3(1.0, 1.15, 0)
	return wolf


## Piratin: riesige Krakenarme brechen aus der Tiefe, packen die Gegner, schlagen sie auf die Bühne und schleudern sie weg.
func _piratin() -> void:
	var skin := Color(0.6, 0.15, 0.35)
	var sea := Color(0.2, 0.6, 1.0)
	_tint(Color(0, 0.06, 0.12, 0.55), 0.3)
	player._play("special", 0.9)
	Audio.sfx("waves", 0.8)
	_cam_stage(0.5, 2.0)
	var floor_y := area.position.y
	var enemies := _enemies()
	var spots := []
	for e in enemies:
		spots.append(e.global_position.x)
	while spots.size() < 4:
		spots.append(randf_range(area.position.x, area.end.x))
	var arms := []
	for x in spots:
		arms.append(_tentacle(Vector3(x, floor_y - 6.0, 0.6), skin))
		SpecialFX._sparks(world, Vector3(x, floor_y + 0.2, 0.6), sea, 25, 6.0, 0.6)
	Audio.sfx("bubbles", 0.6)
	# Arme steigen auf (Wellenbewegung).
	for s in 20:
		var t := float(s + 1) / 20
		for i in arms.size():
			_bend_tentacle(arms[i], t * 1.0, sin(s * 0.4 + i) * 0.4)
		await _wait(0.03)
	# Jeder Arm packt "seinen" Gegner (der erste Arme gehört zu den Gegnern).
	for i in enemies.size():
		if is_instance_valid(enemies[i]) and enemies[i].visible:
			_catch(enemies[i])
	Audio.sfx("hit_strong", 0.7)
	for slam in 3:
		for s in 6:
			var t := float(s + 1) / 6
			for i in arms.size():
				_bend_tentacle(arms[i], 1.0, lerpf(0.0, 1.3 if slam % 2 == 0 else -1.3, t))
				if i < enemies.size() and enemies[i] in victims:
					enemies[i].global_position = _tentacle_tip(arms[i]) - Vector3(0, 1.0, 0)
			await _wait(0.03)
		for v in victims:
			_boom(_chest(v), sea, 0.8)
			_tick(v, skin, 4.0)
		SpecialFX.shake(player, 0.5, 0.2)
	Audio.sfx("whirl", 0.7)
	_launch_all(Vector2(0.8, 0.6))
	for arm in arms:
		arm.create_tween().tween_property(arm, "global_position:y", floor_y - 9.0, 0.6).set_ease(Tween.EASE_IN)
	await _wait(0.6)


## Krakenarm: Kette aus Kugeln, die nach oben dünner werden, mit Saugnäpfen.
func _tentacle(base: Vector3, c: Color) -> Node3D:
	var arm := Node3D.new()
	add_child(arm)
	arm.global_position = base
	for i in 14:
		var seg := _solid(_ball(0.75 - i * 0.045), c.lightened(i * 0.015), 0.4)
		seg.reparent(arm, false)
		var cup := _solid(_ball(0.16), Color(1, 0.75, 0.8), 0.3)
		cup.reparent(seg, false)
		cup.position = Vector3(0, 0, 0.55 - i * 0.03)
	return arm


## Biegt einen Krakenarm: rise = wie weit er aus dem Boden ist (0..1), bend = Krümmung zur Seite.
func _bend_tentacle(arm: Node3D, rise: float, bend: float) -> void:
	var pos := Vector3.ZERO
	var angle := 0.0
	for i in arm.get_child_count():
		var seg: Node3D = arm.get_child(i)
		seg.position = pos
		angle += bend * 0.12
		pos += Vector3(sin(angle), cos(angle), 0) * 0.6
	arm.position.y = lerpf(arm.position.y, arm.position.y, 0.0)
	var top := area.position.y - 6.0 + rise * 6.5
	arm.global_position.y = top


func _tentacle_tip(arm: Node3D) -> Vector3:
	return arm.get_child(arm.get_child_count() - 1).global_position


## Kampfroboter: Düsenrucksack an, Zielerfassung auf jeden Gegner, dann ein Schwarm Raketen und eine Riesenrakete.
func _roboter() -> void:
	var red := Color(1, 0.2, 0.1)
	var flame := Color(1, 0.6, 0.2)
	_tint(Color(0.12, 0, 0, 0.5), 0.3)
	var start := player.global_position
	player.create_tween().tween_property(player, "global_position", start + Vector3(-player.facing * 1.5, 4.5, 0), 0.5).set_ease(Tween.EASE_OUT)
	Audio.sfx("dash", 0.6)
	_cam_stage(0.5)
	for i in 8:
		SpecialFX._sparks(world, player.global_position + Vector3(0, 0.3, -0.3), flame, 12, 3.0, 0.4)
		await _wait(0.06)
	# Zielerfassung: rote Klammern um jeden Gegner.
	var enemies := _enemies()
	for e in enemies:
		_catch(e)
		for corner in [Vector2(-1, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1)]:
			var bracket := _glow(_box(Vector3(0.5, 0.08, 0.08)), red, 3.5)
			bracket.global_position = _chest(e) + Vector3(corner.x * 0.9, corner.y * 1.1, 0.6)
			var b2 := _glow(_box(Vector3(0.08, 0.5, 0.08)), red, 3.5)
			b2.global_position = bracket.global_position + Vector3(-corner.x * 0.21, -corner.y * 0.21, 0)
			_fade_out(bracket, 1.6)
			_fade_out(b2, 1.6)
	Audio.sfx("warning", 1.3, -2.0)
	await _wait(0.5)
	# Raketenschwarm in Bögen.
	for i in 18:
		var from := player.global_position + Vector3(0, 1.2, 0)
		var target := Vector3(randf_range(area.position.x, area.end.x), 0.4, 0)
		if not enemies.is_empty() and i % 2 == 0:
			target = _chest(enemies[i / 2 % enemies.size()]) + Vector3(randf_range(-0.5, 0.5), randf_range(-0.4, 0.4), 0)
		_rocket(from, target, from + Vector3(randf_range(-4, 4), randf_range(4, 7), 0), red, 0.5, 1.7)
		Audio.sfx("fuse", randf_range(1.2, 1.6), -8.0)
		await _wait(0.06)
	await _wait(0.5)
	# Die Riesenrakete.
	var aim := _chest(victims[0]) if not victims.is_empty() else Vector3(area.get_center().x, area.position.y + 0.5, 0)
	_rocket(player.global_position + Vector3(0, 1.2, 0), aim, player.global_position + Vector3(0, 8, 0), red, 0.6, 3.0)
	Audio.sfx("laser", 0.6)
	await _wait(0.6)
	for e in _enemies_near(aim, 3.5, 3.0):
		_catch(e)
	_launch_all(Vector2(0.45, 1.0))
	player.create_tween().tween_property(player, "global_position", start + Vector3(0, 0.3, 0), 0.4)
	await _wait(0.5)


## Eine Rakete fliegt im Bogen (über `control`) zum Ziel und explodiert dort.
func _rocket(from: Vector3, target: Vector3, control: Vector3, c: Color, seconds: float, size := 1.0) -> void:
	var rocket := Node3D.new()
	add_child(rocket)
	var body := _solid(_cyl(0.12 * size, 0.7 * size), Color(0.85, 0.85, 0.9), 0.2)
	body.reparent(rocket, false)
	body.rotation.z = -PI / 2.0
	var nose := _glow(_cyl(0.12 * size, 0.25 * size, 0.0), c, 3.0)
	nose.reparent(rocket, false)
	nose.rotation.z = -PI / 2.0
	nose.position.x = 0.45 * size
	rocket.global_position = from
	var last := [from]
	var tween := rocket.create_tween()
	tween.tween_method(func(t: float):
		var a := from.lerp(control, t)
		var b := control.lerp(target, t)
		var p := a.lerp(b, t)
		var d: Vector3 = p - last[0]
		if d.length() > 0.001:
			rocket.rotation.z = atan2(d.y, d.x)
		last[0] = p
		rocket.global_position = p
		if randf() < 0.6:
			SpecialFX._sparks(world, p, Color(1, 0.6, 0.2), 4, 1.5, 0.3)
			SpecialFX._flash_sphere(world, p, Color(0.5, 0.5, 0.55), 0.1 * size, 0.25 * size, 0.3), 0.0, 1.0, seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_boom(target, c, 0.7 * size)
		for e in _enemies_near(target, 1.3 * size, 1.6 * size):
			_catch(e)
			_tick(e, c, 2.0 * size)
		rocket.queue_free())


## Magierin: eine riesige Uhr erscheint und hält die Zeit an; Kristallspeere umkreisen die Gegner und schießen herein.
func _magierin() -> void:
	var arcane := Color(0.6, 0.45, 1.0)
	var crystal := Color(0.7, 0.9, 1.0)
	_tint(Color(0.2, 0.2, 0.25, 0.65), 0.4)
	player._play("special", 0.8)
	_cam_stage(0.5, 1.0)
	var clock := Node3D.new()
	add_child(clock)
	var face := _glow(_torus(4.2, 4.6), arcane, 4.0)
	face.reparent(clock, false)
	face.rotation.x = PI / 2.0
	for i in 12:
		var mark := _glow(_box(Vector3(0.18, 0.7, 0.1)), arcane.lightened(0.3), 3.0)
		mark.reparent(clock, false)
		var a := i * TAU / 12.0
		mark.position = Vector3(sin(a) * 3.8, cos(a) * 3.8, 0)
		mark.rotation.z = -a
	var hand_long := Node3D.new()
	clock.add_child(hand_long)
	var hl := _glow(_box(Vector3(0.2, 3.4, 0.1)), Color(1, 1, 1), 3.0)
	hl.reparent(hand_long, false)
	hl.position.y = 1.7
	var hand_short := Node3D.new()
	clock.add_child(hand_short)
	var hs := _glow(_box(Vector3(0.3, 2.2, 0.1)), Color(1, 1, 1), 3.0)
	hs.reparent(hand_short, false)
	hs.position.y = 1.1
	clock.global_position = Vector3(area.get_center().x, area.position.y + area.size.y * 0.5 + 2.0, -4.0)
	clock.scale = Vector3.ONE * 0.05
	clock.create_tween().tween_property(clock, "scale", Vector3.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	Audio.sfx("gong", 1.2)
	await _wait(0.4)
	# Zeit steht still: alle Gegner erstarren mitten in der Bewegung.
	var frozen := []
	for e in _enemies():
		_catch(e)
		if e.anim_player:
			e.anim_player.speed_scale = 0.0
			frozen.append(e)
	Audio.sfx("ice_crack", 0.7)
	# Kristallspeere erscheinen im Kreis um jeden Gegner und zeigen auf ihn.
	var spears := []
	for v in victims:
		for i in 8:
			var a := i * TAU / 8.0
			var spear := _glow(_cyl(0.16, 1.6, 0.0), crystal, 3.0)
			var center := _chest(v)
			spear.global_position = center + Vector3(cos(a), sin(a), 0) * 2.6
			spear.rotation.z = a + PI / 2.0
			spear.scale = Vector3.ONE * 0.05
			spear.create_tween().tween_property(spear, "scale", Vector3.ONE, 0.2)
			spears.append([spear, center])
		await _wait(0.05)
	for i in 10:
		hand_long.rotation.z -= TAU / 12.0
		hand_short.rotation.z -= TAU / 60.0
		Audio.sfx("menu_move", 0.6, -2.0)
		await _wait(0.1)
	# Die Zeit läuft weiter: alle Speere schießen gleichzeitig herein.
	for s in spears:
		var t: Tween = s[0].create_tween()
		t.tween_property(s[0], "global_position", s[1], 0.12).set_ease(Tween.EASE_IN)
		t.tween_callback(s[0].queue_free)
	await _wait(0.12)
	for e in frozen:
		if is_instance_valid(e) and e.anim_player:
			e.anim_player.speed_scale = 1.0
	_tint(Color(0.6, 0.5, 1.0, 0.5), 0.05)
	for v in victims:
		_tick(v, crystal, 12.0)
		_boom(_chest(v), arcane, 1.6)
	Audio.sfx("ice_crack")
	_launch_all(Vector2(0.5, 0.9))
	_tint(Color(0, 0, 0, 0.3), 0.3)
	_fade_out(clock, 0.4)
	await _wait(0.5)


## Für Figuren ohne eigene Szene: ein riesiger Strahl in Blickrichtung.
func _strahl() -> void:
	SpecialFX.final_beam(player, 34.0)
	for e in _enemies():
		var offset: Vector3 = e.global_position - player.global_position
		if offset.x * player.facing > -0.6 and absf(offset.y) < 3.0:
			_catch(e)
	_tick_all(color, 4.0)
	await _wait(0.5)
	_launch_all(Vector2(1.0, 0.45))
	await _wait(0.4)


## Etwas nach einer Weile ausführen (ohne die Szene anzuhalten).
func _after(seconds: float, what: Callable) -> void:
	get_tree().create_timer(seconds, false).timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(player):
			what.call())
