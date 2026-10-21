class_name MapFX
extends Node
## Effekte, die Maps lebendiger machen: Stimmung (Nebel, Glühen, Farben), flackernde Lichter,
## Vogel- und Fledermausschwärme, treibende Wolken, wehender Stoff, glühende Lava, Wasser
## und Silhouetten im Vordergrund. Ein MapFX-Knoten erledigt die Bewegungen in _process.

const LAVA_SHADER := preload("res://scripts/lava.gdshader")
const WATER_SHADER := preload("res://scripts/water.gdshader")
const CLOTH_SHADER := preload("res://scripts/cloth_wave.gdshader")

## Lichter, die flackern: [Licht, Grundhelligkeit, Stärke, Versatz].
var flickers: Array = []
## Schwärme: jedes Tier ist [Knoten, Mitte, Radius, Geschwindigkeit, Phase, Flügel links, Flügel rechts].
var flyers: Array = []
## Langsam treibende Knoten: [Knoten, Geschwindigkeit, Breite].
var drifters: Array = []
var time := 0.0


## Hängt einen MapFX-Knoten an die Map und gibt ihn zurück.
static func attach(map: Node3D) -> MapFX:
	var fx := MapFX.new()
	fx.name = "MapFX"
	map.add_child(fx)
	return fx


func _process(delta: float) -> void:
	time += delta
	for f in flickers:
		var light: Light3D = f[0]
		if is_instance_valid(light):
			var n := sin(time * 13.0 + f[3]) * 0.5 + sin(time * 7.3 + f[3] * 2.0) * 0.3 + sin(time * 23.0 + f[3]) * 0.2
			light.light_energy = f[1] * (1.0 + n * f[2])
	for b in flyers:
		var node: Node3D = b[0]
		var angle: float = b[4] + time * b[3]
		node.position = b[1] + Vector3(cos(angle) * b[2].x, sin(angle * 2.0) * b[2].y, sin(angle) * b[2].z)
		node.rotation.y = -angle + (PI if b[3] > 0.0 else 0.0)
		var flap := sin(time * (16.0 if b[2].y > 0.6 else 9.0) + b[4] * 5.0) * 0.6
		b[5].rotation.z = 0.35 + flap
		b[6].rotation.z = -0.35 - flap
	for d in drifters:
		var node: Node3D = d[0]
		node.position.x += d[1] * delta
		if node.position.x > d[2]:
			node.position.x -= d[2] * 2.0
		elif node.position.x < -d[2]:
			node.position.x += d[2] * 2.0


# --- Stimmung -------------------------------------------------------------------------

## Nebel in der Tiefe, Glühen und Farbanpassung für die WorldEnvironment der Map.
static func mood(map: Node3D, fog_color: Color, fog_density: float, glow := 0.5, saturation := 1.1,
		contrast := 1.05, brightness := 1.0) -> void:
	var we: WorldEnvironment = map.get_node_or_null("WorldEnvironment")
	if we == null or we.environment == null:
		return
	var env: Environment = we.environment
	env.fog_enabled = true
	env.fog_light_color = fog_color
	env.fog_density = fog_density
	env.fog_sky_affect = 0.0
	env.glow_enabled = glow > 0.0
	env.glow_intensity = glow
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_saturation = saturation
	env.adjustment_contrast = contrast
	env.adjustment_brightness = brightness


# --- Lichter --------------------------------------------------------------------------

## Lässt alle OmniLights unter `parent` flackern (Fackeln, Kerzen, Lava).
func flicker_all(parent: Node, amount := 0.25) -> void:
	for light in parent.find_children("*", "OmniLight3D", true, false):
		flicker(light, amount)


func flicker(light: Light3D, amount := 0.25) -> void:
	flickers.append([light, light.light_energy, amount, randf() * 100.0])


# --- Tiere ----------------------------------------------------------------------------

## Ein Schwarm, der um `center` kreist. Fledermäuse flattern schneller (bat = true).
func flock(center: Vector3, count: int, color: Color, radius := Vector3(10, 0.8, 4), speed := 0.35,
		size := 0.35, bat := false) -> void:
	var mat := MapLook.mat(color, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in count:
		var bird := Node3D.new()
		var wings: Array = []
		for side in [-1, 1]:
			var pivot := Node3D.new()
			bird.add_child(pivot)
			var wing := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(size, size * 0.08, size * (0.5 if bat else 0.35))
			wing.mesh = mesh
			wing.material_override = mat
			wing.position.x = side * size * 0.5
			pivot.add_child(wing)
			wings.append(pivot)
		add_child(bird)
		var r := radius * randf_range(0.7, 1.1)
		if bat:
			r.y = maxf(r.y, 0.9)
		var sp := speed * randf_range(0.8, 1.2) * (1.0 if i % 2 == 0 else -1.0)
		flyers.append([bird, center + Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-1, 1)),
			r, sp, randf() * TAU, wings[0], wings[1]])


# --- Bewegung -------------------------------------------------------------------------

## Lässt einen Knoten langsam seitlich treiben und am Rand wieder von vorne beginnen.
func drift(node: Node3D, speed: float, width := 70.0) -> void:
	drifters.append([node, speed, width])


# --- Materialien ----------------------------------------------------------------------

static func lava_material(texture: Texture2D = null, glow := 3.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = LAVA_SHADER
	m.set_shader_parameter("glow", glow)
	if texture:
		m.set_shader_parameter("lava_texture", texture)
		m.set_shader_parameter("use_texture", true)
	return m


## Wasserfläche mit Wellen (braucht viele Unterteilungen, deshalb eine eigene PlaneMesh).
static func water(parent: Node, size: Vector2, pos: Vector3) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = size
	mesh.subdivide_width = 120
	mesh.subdivide_depth = 60
	var m := ShaderMaterial.new()
	m.shader = WATER_SHADER
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = m
	node.position = pos
	parent.add_child(node)
	return node


## Wehendes Tuch (Fahne, Segel, Banner). Die Fläche steht senkrecht, `pin_top` = an der Oberkante befestigt.
static func cloth(parent: Node, size: Vector2, pos: Vector3, color: Color, texture: Texture2D = null,
		pin_top := false, strength := 0.25, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	mesh.subdivide_width = 16
	mesh.subdivide_depth = 12
	var m := ShaderMaterial.new()
	m.shader = CLOTH_SHADER
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("pin_top", 1.0 if pin_top else 0.0)
	if texture:
		m.set_shader_parameter("cloth_texture", texture)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = m
	node.position = pos
	node.rotation_degrees = rot_deg
	parent.add_child(node)
	return node


## Material mit Textur, die per Weltkoordinaten auf jede Fläche gelegt wird (ohne UV-Probleme bei Kästen).
static func textured(albedo: Texture2D, normal: Texture2D = null, tint := Color.WHITE, scale := 0.35,
		roughness := 0.85, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = albedo
	m.albedo_color = tint
	m.roughness = roughness
	m.metallic = metallic
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	if normal:
		m.normal_enabled = true
		m.normal_texture = normal
		m.normal_scale = 1.0
	return m


## Lädt eine Map-Textur aus assets/maps/texturen, falls vorhanden.
static func tex(name: String) -> Texture2D:
	var path := "res://assets/maps/texturen/%s.png" % name
	return load(path) if ResourceLoader.exists(path) else null


# --- Vordergrund ----------------------------------------------------------------------

## Silhouetten an den Bildrändern, die an der Kamera hängen und so immer im Bild bleiben,
## ohne die Kämpfer zu verdecken. `shapes`: [Mesh-Knoten], in Kamera-Koordinaten platziert.
static func foreground(map: Node3D) -> Node3D:
	var cam := map.get_viewport().get_camera_3d() if map.is_inside_tree() else null
	var holder := Node3D.new()
	holder.name = "Vordergrund"
	if cam:
		cam.add_child(holder)
		# Beim Verlassen der Map (Kampfende) wieder entfernen.
		map.tree_exiting.connect(holder.queue_free)
	else:
		map.add_child(holder)
	return holder
