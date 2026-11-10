class_name Ansturm
extends Node
## Ansturm-Modus: Schattenkrieger strömen Welle um Welle aus leuchtenden Portalen.
## Allein oder zu zweit (dann im selben Team) so lange überleben wie möglich.
## - Schatten sind dunkle Kopien der Kämpfer: kleiner, schwächer und fliegen schon nach wenigen Treffern weg.
## - Drei Sorten: normale Schatten (lila), Flinke (türkis, klein und schnell), Brocken (orange, groß und zäh).
## - Jede 5. Welle kommt ein Schatten-Riese mit Lebensleiste. Wer ihn besiegt, bekommt ein Leben dazu.
## - Mehrere K. o. kurz hintereinander geben eine Kombo und mehr Punkte.
## - Rekord (Welle und Punkte) wird je Map gespeichert.

enum Phase { BREAK, WAVE, OVER }

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const SHADOW_SHADER := preload("res://scripts/schatten.gdshader")
## size: Größe, speed: Lauftempo, launch: wie leicht sie wegfliegen, hurt: mit so viel Schaden (%) kommen sie
## schon an (darum reicht oft ein starker Schlag oder Tritt), deal: wie hart sie zuschlagen.
const KINDS := {
	"schatten": {"size": 0.85, "speed": 0.9, "launch": 1.8, "hurt": 75.0, "deal": 0.55, "glow": Color(0.72, 0.35, 1.0), "points": 100},
	"flink": {"size": 0.66, "speed": 1.3, "launch": 2.1, "hurt": 100.0, "deal": 0.4, "glow": Color(0.3, 0.95, 1.0), "points": 150},
	"brocken": {"size": 1.22, "speed": 0.8, "launch": 1.2, "hurt": 25.0, "deal": 0.9, "glow": Color(1.0, 0.5, 0.15), "points": 250},
	"riese": {"size": 1.65, "speed": 0.85, "launch": 1.0, "hurt": 0.0, "deal": 1.0, "glow": Color(1.0, 0.15, 0.25), "points": 1000},
}
const GIANT_EVERY := 5
## So viele Sekunden nach einem K. o. zählt der nächste noch zur Kombo.
const COMBO_TIME := 2.5
const COMBO_WORDS := ["", "", "DOPPEL-K.O.!", "DREIFACH-K.O.!", "VIERFACH-K.O.!", "MEGA-K.O.!"]
## Nummern der Schatten (für ihre unsichtbaren Tasten, die der Computer drückt). 1 bis 4 sind die Spieler.
const FIRST_ID := 5
const BREAK_SECONDS := 3.2
const PORTAL_SECONDS := 0.5

var fight: Node3D
var humans: Array = []
## Alle, die gerade in der Arena sind (Spieler und Schatten): für Map-Ereignisse und Bomben.
var arena: Array = []
var minions: Array = []
var phase := Phase.BREAK
var wave := 0
var kos := 0
var score := 0
var combo := 0
var combo_timer := 0.0
var best_combo := 0
var break_time := 1.2
var spawn_timer := 0.0
## Sorten, die in dieser Welle noch aus Portalen kommen, und Portale, die gerade aufgehen.
var queue: Array = []
var pending := 0
var giant: CharacterBody3D
var cpu_of := {}
var kind_of := {}
var used_ids := {}
## Besiegte Schatten warten hier kurz, bis sie gelöscht werden (nie mitten in einem Final Smash).
var graveyard: Array = []

var wave_label: Label
var stats_label: Label
var combo_label: Label
var banner: Label
var banner_sub: Label
var giant_bar: ProgressBar
var giant_label: Label


func setup(the_fight: Node3D, human_players: Array, everyone: Array) -> void:
	fight = the_fight
	humans = human_players
	arena = everyone
	for h in humans:
		h.team = 1
		h.rivals = []
	_build_hud()


func _process(delta: float) -> void:
	_update_graveyard(delta)
	if phase == Phase.OVER:
		return
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	match phase:
		Phase.BREAK:
			break_time -= delta
			if break_time <= 0.0:
				_start_wave()
		Phase.WAVE:
			spawn_timer -= delta
			if not queue.is_empty() and spawn_timer <= 0.0 and minions.size() + pending < _max_alive():
				_open_portal(queue.pop_front())
				spawn_timer = maxf(0.55, 1.5 - wave * 0.08)
			elif queue.is_empty() and pending == 0 and minions.is_empty():
				_wave_cleared()
	_update_hud()


## Ist das der letzte Gegner der Welle? (Nur dann gibt es die große K.-o.-Zeitlupe.)
func is_last(m: CharacterBody3D) -> bool:
	return queue.is_empty() and pending == 0 and minions.size() == 1 and minions[0] == m


# --- Wellen ----------------------------------------------------------------------

func _coop() -> bool:
	return humans.size() > 1


func _max_alive() -> int:
	return clampi(3 + wave / 2, 3, 7) + (1 if _coop() else 0)


## Welche Sorten in der Welle kommen. Später mehr Gegner, mehr Flinke und Brocken.
func _plan(n: int) -> Array:
	var list := []
	var count := mini(4 + n * 2, 26)
	var is_giant := n % GIANT_EVERY == 0
	if is_giant:
		count = int(count * 0.6)
	if _coop():
		count = int(count * 1.4)
	for i in count:
		var r := randf()
		if n >= 4 and r < minf(0.06 + n * 0.02, 0.3):
			list.append("brocken")
		elif n >= 2 and r < 0.55:
			list.append("flink")
		else:
			list.append("schatten")
	if is_giant:
		list.insert(mini(2, list.size()), "riese")
	return list


func _start_wave() -> void:
	wave += 1
	queue = _plan(wave)
	phase = Phase.WAVE
	spawn_timer = 1.1
	var is_giant := wave % GIANT_EVERY == 0
	_show_banner("WELLE %d" % wave, "Ein Schatten-Riese naht!" if is_giant else "%d Schatten greifen an" % queue.size(),
		Color(1.0, 0.3, 0.3) if is_giant else UiStyle.GOLD)
	Audio.sfx("warning", 0.7 if is_giant else 1.0, -2.0)
	if is_giant:
		SpecialFX.shake(fight, 0.5, 0.8)
		Audio.sfx("thunder", 0.8, -3.0)


func _wave_cleared() -> void:
	phase = Phase.BREAK
	break_time = BREAK_SECONDS
	score += 200 * wave
	var was_giant := wave % GIANT_EVERY == 0
	var extra := "Alle erholen sich etwas"
	for h in humans:
		if h.stocks > 0:
			h.heal(60.0 if was_giant else 20.0)
	if was_giant:
		extra = "+1 Leben für den Sieg über den Riesen!"
		for h in humans:
			if h.stocks <= 0:
				_revive(h)
			else:
				h.stocks = mini(h.stocks + 1, 9)
	_show_banner("WELLE %d GESCHAFFT!" % wave, extra, Color(0.5, 1.0, 0.5))
	Audio.sfx("pickup_heal", 0.9)


## Mitspieler, der schon raus war, kommt nach einem Riesen mit einem Leben zurück.
func _revive(h: CharacterBody3D) -> void:
	h.stocks = 1
	h.damage = 0.0
	h.visible = true
	h.set_physics_process(true)
	h.velocity = Vector3.ZERO
	h.position = h.spawn_position + Vector3(0, 4, 0)
	if not arena.has(h):
		arena.append(h)
	SpecialFX.popup(h, "ZURÜCK IM KAMPF!", h.color)


# --- Schatten ----------------------------------------------------------------------

## Portal öffnen; kurz danach fällt der Schatten heraus.
func _open_portal(kind: String) -> void:
	pending += 1
	var k: Dictionary = KINDS[kind]
	var pos := _spot()
	_portal(pos, k.glow, 1.6 if kind == "riese" else 1.0)
	get_tree().create_timer(PORTAL_SECONDS).timeout.connect(func():
		pending -= 1
		if phase != Phase.OVER:
			_spawn(kind, pos))


## Eine Stelle über festem Boden, nicht direkt auf einem Spieler.
func _spot() -> Vector3:
	var area := MapLook.area_of(fight.map_node)
	var space := fight.get_world_3d().direct_space_state
	var top := area.end.y + 2.5
	for i in 12:
		var x := randf_range(area.position.x + 1.5, area.end.x - 1.5)
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, 0), Vector3(x, area.position.y - 1.0, 0), 3)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			continue
		var crowded := false
		for h in humans:
			if h.visible and absf(h.position.x - x) < 2.5 and i < 8:
				crowded = true
		if crowded:
			continue
		return Vector3(x, minf(hit.position.y + 3.0, top), 0)
	return humans[0].spawn_position + Vector3(0, 3.0, 0)


func _spawn(kind: String, pos: Vector3) -> void:
	var k: Dictionary = KINDS[kind]
	var m: CharacterBody3D = PLAYER_SCENE.instantiate()
	m.player_id = _take_id()
	m.name = "Schatten%d" % m.player_id
	m.minion = true
	m.team = 2
	m.color = k.glow
	m.speed *= k.speed
	m.start_facing = 1 if pos.x < humans[0].position.x else -1
	fight.add_child(m)
	m.position = pos
	m.spawn_position = Vector3(pos.x, pos.y - 3.0, 0)
	m.blast_zone = humans[0].blast_zone
	m.stocks = 1
	m.set_fighter(randi() % Roster.count())
	# Mit jeder Welle halten die Schatten mehr aus und schlagen härter zu.
	m.launch_scale = k.launch * maxf(0.7, 1.0 - 0.03 * (wave - 1))
	m.damage = k.hurt * maxf(0.35, 1.0 - 0.06 * (wave - 1))
	m.deal_scale = k.deal * minf(1.6, 1.0 + 0.06 * (wave - 1))
	if kind == "riese":
		m.make_boss((90.0 + 10.0 * wave) * (1.4 if _coop() else 1.0), k.size)
		m.boss_defeated.connect(_on_giant_defeated.bind(m))
		giant = m
		giant_bar.max_value = m.boss_hp_max
		SpecialFX.shake(fight, 0.6, 0.6)
		Audio.sfx("thunder", 0.6)
	else:
		m.set_size(k.size)
	_shadow_look(m, k.glow)
	m.rivals = humans.duplicate()
	for h in humans:
		h.rivals.append(m)
	m.fell_off.connect(_on_minion_out)
	m.ko_hit.connect(fight._on_ko_hit)
	m.velocity = Vector3(0, -3.0, 0)
	m.controls_enabled = true
	m.attack_timer = 0.5
	minions.append(m)
	kind_of[m] = kind
	arena.append(m)
	if fight.map_events:
		fight.map_events.adopt(m)
	var cpu := CpuPlayer.new()
	fight.add_child(cpu)
	cpu.setup(m, humans[0], 1, fight.map_node)
	var t := clampf((wave - 1) / 9.0, 0.0, 1.0)
	if kind == "riese":
		cpu.level = {"name": "Riese", "reaction": 0.32, "aggression": 0.6, "block": 0.12, "mistakes": 0.1}
	else:
		cpu.level = {"name": "Schatten", "reaction": lerpf(0.6, 0.25, t), "aggression": lerpf(0.3, 0.7, t),
			"block": lerpf(0.0, 0.3, t), "mistakes": lerpf(0.35, 0.1, t)}
	cpu_of[m] = cpu


## Dunkler Körper mit glühendem Rand (liegt als zweite Schicht über allen Teilen der Figur).
func _shadow_look(m: CharacterBody3D, glow: Color) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADOW_SHADER
	mat.set_shader_parameter("glow", glow)
	for mi in m.model_root.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = mat
	m.shield_bubble.visible = false


## Leuchtender Ring mit dunkler Mitte, der aufgeht, sich dreht und wieder zugeht.
func _portal(pos: Vector3, color: Color, size: float) -> void:
	var root := Node3D.new()
	fight.add_child(root)
	root.position = pos + Vector3(0, 0.9 * size, -0.5)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.25
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.rotation.x = PI / 2.0
	ring.material_override = SpecialFX._glow_material(color, 3.5)
	root.add_child(ring)
	var hole := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	hole.mesh = sphere
	hole.scale = Vector3(1, 1, 0.06)
	var dark := StandardMaterial3D.new()
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.albedo_color = Color(color.darkened(0.88), 0.92)
	hole.material_override = dark
	root.add_child(hole)
	# Funken, die aus dem Portal sprühen.
	var sparks := SpecialFX._particles(color.lightened(0.3), SpecialFX.amount_for_quality(36), 0.7, 0.1)
	sparks.one_shot = false
	sparks.explosiveness = 0.0
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 1.1
	sparks.spread = 180.0
	sparks.initial_velocity_min = 0.5
	sparks.initial_velocity_max = 2.0
	sparks.gravity = Vector3.ZERO
	root.add_child(sparks)
	sparks.emitting = true
	SpecialFX._flash_light(fight, root.position, color, 6.0, 6.0, 1.3)
	Audio.sfx("special_start", 0.6 if size > 1.2 else 1.25, -8.0)
	root.scale = Vector3.ONE * 0.05
	var tween := root.create_tween()
	tween.tween_property(root, "scale", Vector3.ONE * size, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "rotation:z", TAU, 1.3)
	tween.tween_interval(0.75)
	tween.tween_callback(func(): sparks.emitting = false)
	tween.tween_property(root, "scale", Vector3.ONE * 0.02, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_callback(root.queue_free)


func _take_id() -> int:
	var id := FIRST_ID
	while used_ids.has(id):
		id += 1
	used_ids[id] = true
	# Unsichtbare Tasten für diese Nummer anlegen: der Computer "drückt" sie wie ein Mensch.
	for a in Settings.BINDABLE:
		var action := "p%d_%s" % [id, a]
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.5)
	return id


## Ein Schatten ist aus der Arena geflogen.
func _on_minion_out(m: CharacterBody3D) -> void:
	if m.stocks > 0 or not minions.has(m):
		# Der Riese hat keine Leben: fällt er herunter, kommt er einfach wieder.
		return
	_count_ko(m)
	_retire(m)


func _on_giant_defeated(m: CharacterBody3D) -> void:
	if not minions.has(m):
		return
	_count_ko(m)
	_retire(m)
	giant = null
	m.controls_enabled = false
	SpecialFX.impact(m, m.global_position + Vector3(0, 2.0, 0), m.color)
	SpecialFX.slow_motion(m, 0.3, 0.8)
	SpecialFX.shake(fight, 0.8, 0.8)
	Audio.sfx("explosion", 0.7)
	_show_banner("RIESE BESIEGT!", "", Color(1.0, 0.85, 0.3))
	var tween: Tween = m.create_tween()
	tween.tween_property(m.model_root, "scale", m.model_root.scale * 0.01, 0.9).set_delay(0.3)
	tween.tween_callback(func():
		m.visible = false
		m.set_physics_process(false))


func _count_ko(m: CharacterBody3D) -> void:
	kos += 1
	combo = combo + 1 if combo_timer > 0.0 else 1
	combo_timer = COMBO_TIME
	best_combo = maxi(best_combo, combo)
	var points: int = KINDS[kind_of.get(m, "schatten")].points * mini(combo, 5)
	score += points
	if combo >= 2:
		combo_label.text = "%s\n%d× Punkte" % [COMBO_WORDS[mini(combo, COMBO_WORDS.size() - 1)], mini(combo, 5)]
		combo_label.modulate = Color(1, 1, 1, 1)
		combo_label.pivot_offset = combo_label.size / 2.0
		combo_label.scale = Vector2.ONE * 1.5
		var tween := combo_label.create_tween()
		tween.tween_property(combo_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(1.1)
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.4)
		Audio.sfx("special_hit", 0.9 + 0.12 * mini(combo, 6), -5.0)


## Schatten aus allen Listen nehmen; gelöscht wird er etwas später.
func _retire(m: CharacterBody3D) -> void:
	minions.erase(m)
	arena.erase(m)
	kind_of.erase(m)
	for h in humans:
		h.rivals.erase(m)
	if cpu_of.has(m):
		cpu_of[m].queue_free()
		cpu_of.erase(m)
	if fight.map_events:
		fight.map_events.forget(m)
	graveyard.append({"node": m, "time": 2.5})


func _update_graveyard(delta: float) -> void:
	if graveyard.is_empty() or not get_tree().get_nodes_in_group(FinalSmash.GROUP).is_empty():
		return
	for g in graveyard.duplicate():
		g.time -= delta
		if g.time <= 0.0:
			graveyard.erase(g)
			used_ids.erase(g.node.player_id)
			g.node.queue_free()


# --- Spieler ----------------------------------------------------------------------

## Ein Spieler ist aus der Arena geflogen. Vorbei ist es erst, wenn niemand mehr Leben hat.
func human_fell(player: CharacterBody3D) -> void:
	if player.stocks > 0 or phase == Phase.OVER:
		return
	arena.erase(player)
	for h in humans:
		if h.stocks > 0:
			_show_banner("Spieler %d ist raus!" % player.player_id, "Besiegt den nächsten Riesen, dann kommt er zurück", Color(1, 0.5, 0.4))
			return
	_game_over()


func _game_over() -> void:
	phase = Phase.OVER
	fight.state = fight.State.GAME_OVER
	if fight.map_events:
		fight.map_events.stop()
	for m in minions:
		if cpu_of.has(m):
			cpu_of[m].queue_free()
		if not m.boss:
			m.cheer()
		m.controls_enabled = false
	cpu_of.clear()
	banner.visible = false
	banner_sub.visible = false
	combo_label.visible = false
	var map_name: String = Settings.current_map().name
	var old: Dictionary = Settings.horde_records.get(map_name, {})
	var record := score > int(old.get("punkte", 0))
	var text := "ANSTURM VORBEI!\nWelle %d   ·   %d K. o.   ·   %s Punkte\n" % [wave, kos, _points(score)]
	if record:
		Settings.horde_records[map_name] = {"welle": wave, "punkte": score, "kos": kos}
		Settings.save()
		text += "NEUER REKORD!" if not old.is_empty() else "Erster Rekord auf dieser Map!"
		Audio.jingle("sieg")
	else:
		text += "Rekord: Welle %d, %s Punkte" % [int(old.get("welle", 0)), _points(int(old.get("punkte", 0)))]
		Audio.sfx("ko", 0.6)
	fight.center_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fight.center_label.add_theme_font_size_override("font_size", 40)
	fight.center_label.text = text + "\nR: nochmal   Esc: Menü"
	_update_hud()


# --- Anzeige ----------------------------------------------------------------------

func _build_hud() -> void:
	var hud: Node = fight.center_label.get_parent()
	wave_label = _hud_label(hud, 34, UiStyle.GOLD, true, Vector2(0, 2), 44)
	stats_label = _hud_label(hud, 17, Color.WHITE, false, Vector2(0, 46), 26)
	combo_label = _hud_label(hud, 40, Color(1.0, 0.9, 0.3), true, Vector2(0, 130), 110)
	combo_label.modulate.a = 0.0
	banner = _hud_label(hud, 96, UiStyle.GOLD, true, Vector2(0, 230), 120)
	banner_sub = _hud_label(hud, 28, Color.WHITE, false, Vector2(0, 350), 40)
	banner.modulate.a = 0.0
	banner_sub.modulate.a = 0.0
	giant_bar = ProgressBar.new()
	giant_bar.show_percentage = false
	giant_bar.size = Vector2(440, 20)
	giant_bar.position = Vector2(420, 96)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.6)
	bg.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.12, 0.2)
	fill.set_corner_radius_all(8)
	giant_bar.add_theme_stylebox_override("background", bg)
	giant_bar.add_theme_stylebox_override("fill", fill)
	giant_bar.visible = false
	hud.add_child(giant_bar)
	giant_label = _hud_label(hud, 16, Color(1, 0.8, 0.8), true, Vector2(0, 72), 24)
	giant_label.text = "SCHATTEN-RIESE"
	giant_label.visible = false


func _hud_label(hud: Node, font_size: int, color: Color, title: bool, pos: Vector2, height: float) -> Label:
	var label := UiStyle.label("", font_size, color, title, 10 if font_size >= 30 else 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos
	label.size = Vector2(1280, height)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(label)
	return label


func _update_hud() -> void:
	wave_label.text = "WELLE %d" % maxi(wave, 1)
	var left := queue.size() + pending + minions.size()
	var record: Dictionary = Settings.horde_records.get(Settings.current_map().name, {})
	var text := "K. o.: %d   ·   Punkte: %s" % [kos, _points(score)]
	if phase == Phase.WAVE:
		text += "   ·   Noch %d" % left
	if not record.is_empty():
		text += "   ·   Rekord: %s" % _points(int(record.get("punkte", 0)))
	stats_label.text = text
	var show_giant := is_instance_valid(giant) and minions.has(giant)
	giant_bar.visible = show_giant
	giant_label.visible = show_giant
	if show_giant:
		giant_bar.value = giant.boss_hp


## Großer Schriftzug in der Bildmitte, der kurz aufploppt und wieder verschwindet.
func _show_banner(text: String, sub: String, color: Color) -> void:
	banner.text = text
	banner_sub.text = sub
	banner.add_theme_color_override("font_color", color)
	banner.add_theme_font_size_override("font_size", 96 if text.length() <= 10 else 64)
	for label in [banner, banner_sub]:
		label.modulate.a = 1.0
		label.pivot_offset = label.size / 2.0
		label.scale = Vector2.ONE * 0.4
		var tween: Tween = label.create_tween()
		tween.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(1.3)
		tween.tween_property(label, "modulate:a", 0.0, 0.35)


## 12500 wird "12.500".
static func _points(value: int) -> String:
	var s := str(value)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
