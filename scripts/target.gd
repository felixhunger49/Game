class_name Target
extends Node3D
## Ziel für den Modus "Ziele zerstören": schwebende Zielscheibe, die bei einem Treffer zerplatzt.
## Alle Angriffe zerstören Ziele: Schläge und Tritte (Player._try_hit), Erdbeben, Feuerball, Kanonenkugel,
## Pfeilregen, Laser und Overcharge. Die Ziele werden aus den Böden und Plattformen der Map gesetzt (place).

signal destroyed

const GROUP := "ziel"
const COUNT := 10
## Ziele schweben so hoch über dem Boden (etwa Brusthöhe), damit Schläge sie treffen.
const HOVER := 1.0
const MIN_GAP := 1.8

var base_y := 0.0
var time := randf() * TAU


func _ready() -> void:
	add_to_group(GROUP)
	base_y = position.y
	for ring in [[0.55, Color(0.9, 0.1, 0.1)], [0.4, Color(1, 1, 1)], [0.25, Color(0.9, 0.1, 0.1)], [0.1, Color(1, 0.85, 0.2)]]:
		var disc := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = ring[0]
		c.bottom_radius = ring[0]
		c.height = 0.08
		disc.mesh = c
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ring[1]
		mat.emission_enabled = true
		mat.emission = ring[1]
		mat.emission_energy_multiplier = 0.6
		disc.material_override = mat
		disc.rotation.x = PI / 2.0
		disc.position.z = 0.02 * (0.55 - ring[0]) * 10.0
		add_child(disc)
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.5, 0.4)
	light.light_energy = 0.8
	light.omni_range = 2.0
	add_child(light)


func _process(delta: float) -> void:
	time += delta
	position.y = base_y + sin(time * 2.0) * 0.12
	rotation.y = sin(time * 1.3) * 0.5


func pop() -> void:
	if is_queued_for_deletion():
		return
	var world := get_parent()
	SpecialFX._flash_sphere(world, global_position, Color(1, 0.4, 0.2), 0.3, 1.3, 0.25)
	SpecialFX._sparks(world, global_position, Color(1, 0.85, 0.3), 40, 7.0, 0.5)
	SpecialFX._flash_light(world, global_position, Color(1, 0.6, 0.3), 6.0, 4.0, 0.3)
	Audio.sfx("coin")
	destroyed.emit()
	queue_free()


## Zerstört alle Ziele im Treffer-Bereich eines Nahkampf-Angriffs (gleiche Regeln wie beim Gegner).
static func hit_melee(player: Node3D, reach: Vector2, both_sides: bool) -> void:
	for t in player.get_tree().get_nodes_in_group(GROUP):
		var offset: Vector3 = t.global_position - Vector3(0, HOVER, 0) - player.global_position
		var forward: float = offset.x * player.get("facing")
		var in_range := absf(offset.x) <= reach.x if both_sides else forward > -0.3 and forward <= reach.x
		if in_range and absf(offset.y) <= reach.y + 0.3:
			t.pop()


## Zerstört alle Ziele in der Nähe eines Geschosses. Gibt true zurück, wenn eins getroffen wurde.
static func hit_near(node: Node3D, pos: Vector3, radius: float) -> bool:
	var hit := false
	for t in node.get_tree().get_nodes_in_group(GROUP):
		if t.global_position.distance_to(pos) < radius:
			t.pop()
			hit = true
	return hit


## Verteilt COUNT Ziele über die Map: auf jeder Plattform eins, dann schwebend in der Luft und über dem Boden.
## Immer an denselben Stellen, damit die Bestzeiten vergleichbar sind. spawn_x: dort startet der Spieler.
static func place(map: Node3D, parent: Node3D, spawn_x: float) -> Array:
	var platforms := []
	var floors := []
	var area := MapLook.area_of(map).grow(1.0)
	for body in map.find_children("*", "StaticBody3D", true, false):
		for c in body.get_children():
			if not (c is CollisionShape3D and c.shape is BoxShape3D):
				continue
			var size: Vector3 = c.shape.size * c.global_transform.basis.get_scale()
			var top := Vector3(c.global_position.x, c.global_position.y + size.y / 2.0, 0)
			if not area.has_point(Vector2(top.x, top.y)):
				continue
			(platforms if body.get_collision_layer_value(MapLook.PLATFORM_LAYER) else floors).append([top, size.x])
	var spots := []
	for p in platforms:
		spots.append(p[0] + Vector3(0, HOVER, 0))
	# In der Luft über dem Boden, wo keine Plattform im Weg ist.
	# Mit Doppelsprung erreichbar, alle 2 m, nicht direkt in einer Plattform.
	for f in floors:
		var width: float = f[1]
		var n := int(width / 2.0)
		for i in n:
			var x: float = f[0].x - width / 2.0 + (i + 0.5) * width / n
			var air: Vector3 = Vector3(x, f[0].y + 3.4, 0)
			var blocked := platforms.any(func(p): return absf(p[0].x - x) < p[1] / 2.0 + 0.3 and absf(p[0].y + HOVER - air.y) < 1.2)
			if not blocked:
				spots.append(air)
	for f in floors:
		var width: float = f[1]
		var n := int(width / 2.5)
		for i in n:
			spots.append(Vector3(f[0].x - width / 2.0 + (i + 0.5) * width / n, f[0].y + HOVER, 0))
	var chosen := []
	for s in spots:
		if chosen.size() >= COUNT:
			break
		if absf(s.x - spawn_x) < 1.6 and s.y < 2.0:
			continue
		if chosen.all(func(c): return c.distance_to(s) >= MIN_GAP):
			chosen.append(s)
	var targets := []
	for s in chosen:
		var t := Target.new()
		t.position = s
		parent.add_child(t)
		targets.append(t)
	return targets
