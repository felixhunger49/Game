class_name MapLook
## Bausteine für Maps, deren Aussehen und Boden per Skript aus einfachen Formen gebaut werden
## (Vulkan, Piratenschiff, Eiswelt, Wolkentempel).

## Kollisionsebene der schwebenden Plattformen (wie Player.PLATFORM_LAYER).
const PLATFORM_LAYER := 2


## Fester Boden (man kann nicht hindurchspringen). `pos` ist die Mitte, die Oberkante liegt bei pos.y + size.y / 2.
static func solid(parent: Node, size: Vector3, pos: Vector3) -> StaticBody3D:
	return _body(parent, size, pos, 1)


## Schwebende Plattform: von unten kann man durchspringen, mit 2× Runter durchfallen (wie bei Burg/Dorf/Friedhof).
static func platform(parent: Node, size: Vector3, pos: Vector3) -> StaticBody3D:
	return _body(parent, size, pos, PLATFORM_LAYER)


static func _body(parent: Node, size: Vector3, pos: Vector3, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 0
	body.set_collision_layer_value(layer, true)
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	return body


## Material mit Farbe; `glow` > 0 lässt es leuchten (z. B. Lava).
static func mat(color: Color, roughness := 0.9, metallic := 0.0, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func box(parent: Node, size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, material, rot_deg)


## Zylinder; mit top_radius = 0 wird es ein Kegel (Eiszapfen, Spitzen).
static func cylinder(parent: Node, radius: float, height: float, pos: Vector3, material: Material,
		top_radius := -1.0, rot_deg := Vector3.ZERO, sides := 12) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = sides
	return _add(parent, mesh, pos, material, rot_deg)


static func sphere(parent: Node, radius: float, pos: Vector3, material: Material, scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var node := _add(parent, mesh, pos, material, Vector3.ZERO)
	node.scale = scale
	return node


static func light(parent: Node, pos: Vector3, color: Color, energy := 1.5, reach := 6.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = reach
	parent.add_child(l)
	return l


## 3D-Modell (z. B. mit Flux + Trellis erzeugt) laden, auf `height` skalieren und mit der Unterkante
## auf `pos` stellen. Fehlt die Datei, passiert nichts.
static func prop(parent: Node, path: String, pos: Vector3, height: float, rot_y_deg := 0.0) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var model: Node3D = load(path).instantiate()
	var bounds := AABB()
	var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = m.transform * m.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var s := height / maxf(bounds.size.y, 0.001)
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation_degrees.y = rot_y_deg
	parent.add_child(holder)
	holder.add_child(model)
	model.scale = Vector3.ONE * s
	model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * s
	return holder


## Großes, unbeleuchtetes Hintergrundbild weit hinter der Arena (falls die Datei existiert).
static func backdrop(parent: Node, texture_path: String, z := -60.0, width := 150.0, y := 12.0) -> MeshInstance3D:
	if not ResourceLoader.exists(texture_path):
		return null
	var tex: Texture2D = load(texture_path)
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, width * tex.get_height() / float(tex.get_width()))
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = tex
	m.disable_receive_shadows = true
	m.disable_fog = true
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = m
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = Vector3(0, y, z)
	parent.add_child(node)
	return node


## Partikel als kleine leuchtende Plättchen (Glut, Schnee, Gischt …), die in einem Kasten entstehen.
static func particles(parent: Node, pos: Vector3, extents: Vector3, color: Color, amount: int,
		velocity: Vector3, size := 0.12, lifetime := 4.0, gravity := Vector3.ZERO) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = SpecialFX.amount_for_quality(amount)
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.direction = velocity.normalized() if velocity != Vector3.ZERO else Vector3.UP
	p.spread = 20.0
	p.initial_velocity_min = velocity.length() * 0.6
	p.initial_velocity_max = velocity.length() * 1.2
	p.gravity = gravity
	var quad := QuadMesh.new()
	# Weicher runder Punkt statt Quadrat, darum etwas größer.
	quad.size = Vector2(size, size) * 1.7
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = SpecialFX.soft_dot()
	m.albedo_color = color
	quad.material = m
	p.mesh = quad
	parent.add_child(p)
	return p


static func _add(parent: Node, mesh: Mesh, pos: Vector3, material: Material, rot_deg: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = pos
	node.rotation_degrees = rot_deg
	parent.add_child(node)
	return node
