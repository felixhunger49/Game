extends Node3D
## Wolkentempel: großer Marmortempel auf einer schwebenden Felseninsel über dem Wolkenmeer, mit vier Stockwerken:
## - unten die Krypta im Felsen unter dem Tempelboden (über die Kanten links und rechts erreichbar),
## - der Tempelboden mit zwei Wolkenstufen zum Hochspringen und zwei Wolken, die außen auf und ab schweben,
## - Säulengang und Altar zwischen den Säulen, Wolkentreppen außen,
## - das Tempeldach und ganz oben die Giebelspitze.
## Tauben, goldener Glitzer und Kristalle in der Krypta.

const FLOOR_HALF := 10.0
const CRYPT_HALF := 12.5
const CRYPT_Y := -5.0
const ROOF_Y := 8.0
const ROOF_HALF := 8.6
const PEAK_Y := 10.4


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var marble_tex := MapFX.tex("marmor")
	var marble: Material = MapFX.textured(marble_tex, MapFX.tex("marmor_n"), Color(0.93, 0.89, 0.85), 0.3, 0.3) if marble_tex \
		else MapLook.mat(Color(0.94, 0.92, 0.88), 0.35)
	var marble_shade: Material = MapFX.textured(marble_tex, MapFX.tex("marmor_n"), Color(0.74, 0.7, 0.72), 0.3, 0.4) if marble_tex \
		else MapLook.mat(Color(0.8, 0.78, 0.76), 0.4)
	var marble_dark: Material = MapFX.textured(marble_tex, MapFX.tex("marmor_n"), Color(0.42, 0.42, 0.52), 0.3, 0.5) if marble_tex \
		else MapLook.mat(Color(0.45, 0.45, 0.55), 0.5)
	var gold := MapLook.mat(Color(1.0, 0.78, 0.3), 0.3, 0.8)
	var cloud := MapLook.mat(Color(0.93, 0.92, 0.96), 1.0)
	var cloud_pink := MapLook.mat(Color(1.0, 0.86, 0.9), 1.0)
	var rock := MapLook.mat(Color(0.55, 0.5, 0.52), 0.95)
	var crystal := MapLook.mat(Color(0.45, 0.75, 1.0, 0.85), 0.1, 0.2, 2.2)
	$Spawn1.position = Vector3(-4.0, 0.2, 0)
	$Spawn2.position = Vector3(4.0, 0.2, 0)
	MapLook.stage_area(self, Rect2(-15.2, CRYPT_Y, 30.4, PEAK_Y - CRYPT_Y), FLOOR_HALF)

	# Tempelboden: 20 breit, darunter ist Platz für die Krypta.
	MapLook.solid(col, Vector3(FLOOR_HALF * 2.0, 1.4, 4), Vector3(0, -0.7, 0))
	MapLook.box(look, Vector3(FLOOR_HALF * 2.0 + 0.4, 0.6, 4.4), Vector3(0, -0.3, 0), marble)
	MapLook.box(look, Vector3(FLOOR_HALF * 2.0 + 0.6, 0.1, 4.6), Vector3(0, -0.06, 0), gold)
	MapLook.box(look, Vector3(FLOOR_HALF * 2.0, 0.8, 4.0), Vector3(0, -1.0, 0), marble_shade)
	MapLook.box(look, Vector3(FLOOR_HALF * 2.0 + 0.2, 0.08, 4.1), Vector3(0, -1.42, 0), gold)

	_crypt(col, look, marble, marble_shade, marble_dark, gold, rock, crystal, cloud, cloud_pink)

	# Säulen mit Kapitellen hinten, sie tragen das Dach. Fahnen an den äußeren Säulen.
	for x in [-7.8, -5.2, -2.6, 2.6, 5.2, 7.8]:
		MapLook.cylinder(look, 0.38, 7.1, Vector3(x, 3.55, -1.7), marble, -1.0, Vector3.ZERO, 16)
		MapLook.box(look, Vector3(1.0, 0.3, 1.0), Vector3(x, 7.2, -1.7), gold)
		MapLook.box(look, Vector3(1.0, 0.3, 1.0), Vector3(x, 0.15, -1.7), marble_shade)
	for x in [-7.8, 7.8]:
		MapFX.cloth(look, Vector2(0.9, 2.8), Vector3(x, 5.4, -1.25), Color(0.25, 0.4, 0.85), null, true, 0.12)

	# Götterstatue zwischen den mittleren Säulen: 3D-Modell aus Flux + Trellis, sonst aus Formen gebaut.
	if MapLook.prop(look, "res://assets/maps/props/statue.glb", Vector3(0, 0.0, -1.6), 3.3) == null:
		_statue(look, Vector3(0, 0.0, -1.6), marble, marble_shade, gold)
	MapLook.light(look, Vector3(0, 2.6, -0.4), Color(1.0, 0.85, 0.5), 0.8, 3.5)

	# Säulengang links und rechts, der Altar in der Mitte, außen Wolkenstufen und Wolkentreppen.
	for p in [[-5.8, 2.6, 3.6], [5.8, 2.6, 3.6], [0.0, 5.2, 4.4]]:
		_marble_platform(col, plat, Vector3(p[0], p[1], 0), p[2], marble, gold, cloud)
	for p in [[-11.4, -2.4, 2.2], [11.4, -2.4, 2.2], [-11.2, 4.6, 2.6], [11.2, 4.6, 2.6]]:
		_cloud_platform(col, plat, Vector3(p[0], p[1], 0), p[2], cloud, cloud_pink)
	# Goldene Schale mit Feuer auf dem Altar.
	MapLook.cylinder(plat, 0.5, 0.3, Vector3(0, 5.55, -0.8), gold, 0.3, Vector3.ZERO, 16)
	MapLook.light(plat, Vector3(0, 6.1, -0.6), Color(1.0, 0.75, 0.4), 1.2, 4.0)
	MapLook.particles(plat, Vector3(0, 5.8, -0.8), Vector3(0.25, 0.05, 0.25), Color(1, 0.7, 0.2, 0.9), 25,
		Vector3(0, 1.2, 0), 0.12, 0.8)

	# Zwei Wolken schweben außen neben dem Tempelboden auf und ab.
	for side in [-1, 1]:
		var drift := MovingPlatform.create(plat, Vector3(2.8, 0.3, 2.2), Vector3(side * 13.6, 0.4, 0),
			Vector3(side * 13.6, 2.4, 0), 8.0, 0.0 if side < 0 else 0.5)
		MapLook.sphere(drift, 1.0, Vector3(0, -0.25, 0), cloud, Vector3(1.7, 0.5, 1.2))
		MapLook.sphere(drift, 0.7, Vector3(-0.7, -0.15, 0.3), cloud_pink, Vector3(1.2, 0.6, 1.0))
		MapLook.sphere(drift, 0.6, Vector3(0.8, -0.1, -0.2), cloud, Vector3(1.3, 0.6, 1.0))

	_roof(col, look, plat, marble, marble_shade, gold)

	# Ziehendes Wolkenmeer tief unter der Insel.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		var pos := Vector3(rng.randf_range(-70, 70), rng.randf_range(-17, -12), rng.randf_range(-55, 4))
		var s := rng.randf_range(3.0, 7.5)
		var puff := MapLook.sphere(bg, 1.0, pos, cloud if i % 3 else cloud_pink, Vector3(s * 1.6, s * 0.5, s))
		fx.drift(puff, rng.randf_range(0.5, 1.4), 75.0)

	MapLook.light(look, Vector3(0, 5.0, 4.0), Color(1.0, 0.9, 0.75), 0.8, 16.0)
	MapLook.light(look, Vector3(0, 11.0, 3.0), Color(1.0, 0.9, 0.8), 0.6, 9.0)
	fx.flicker_all(plat, 0.2)
	fx.flock(Vector3(0, 13.5, -6.0), 6, Color(1, 1, 1), Vector3(16, 1.0, 4), 0.3, 0.4)
	MapLook.particles(self, Vector3(0, 4.0, 0), Vector3(14, 6, 2), Color(1.0, 0.85, 0.4, 1.0), 50,
		Vector3(0, 0.2, 0), 0.05, 4.0)
	MapFX.mood(self, Color(1.0, 0.88, 0.85), 0.005, 0.25, 1.18, 1.2, 0.86)

	# Vordergrund: Wolkenfetzen in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.5, Vector3(side * 2.02, -1.30, -3.0), cloud, Vector3(1.6, 0.6, 0.6))
		MapLook.sphere(fg, 0.35, Vector3(side * 1.54, -1.35, -3.0), cloud_pink, Vector3(1.4, 0.6, 0.6))
	MapLook.backdrop(bg, "res://assets/maps/wolkentempel/hintergrund.png", -60.0, 180.0, 10.0)


## Schwebende Marmorplatte mit Goldkante und einer Wolke darunter.
func _marble_platform(col: Node3D, plat: Node3D, pos: Vector3, width: float, marble: Material, gold: Material,
		cloud: Material) -> void:
	MapLook.platform(col, Vector3(width, 0.3, 2.4), pos)
	MapLook.box(plat, Vector3(width + 0.1, 0.4, 2.5), pos + Vector3(0, -0.05, 0), marble)
	MapLook.box(plat, Vector3(width + 0.2, 0.08, 2.6), pos + Vector3(0, 0.12, 0), gold)
	MapLook.sphere(plat, 1.0, pos + Vector3(0, -0.6, 0.2), cloud, Vector3(width * 0.5, 0.45, 1.2))


## Kleine feste Wolke als Stufe (von unten kann man durchspringen).
func _cloud_platform(col: Node3D, plat: Node3D, pos: Vector3, width: float, cloud: Material, pink: Material) -> void:
	MapLook.platform(col, Vector3(width, 0.3, 2.2), pos)
	MapLook.sphere(plat, 1.0, pos + Vector3(0, -0.3, 0), cloud, Vector3(width * 0.6, 0.5, 1.1))
	MapLook.sphere(plat, 0.6, pos + Vector3(-width * 0.3, -0.2, 0.35), pink, Vector3(1.1, 0.6, 0.9))
	MapLook.sphere(plat, 0.55, pos + Vector3(width * 0.32, -0.15, -0.3), cloud, Vector3(1.2, 0.6, 0.9))


## Krypta im Felsen unter dem Tempel: dunkler Marmor, kurze Säulen, leuchtende Kristalle und Schatztruhen.
## Darunter die schwebende Felseninsel, von Wolken umhüllt.
func _crypt(col: Node3D, look: Node3D, marble: Material, shade: Material, dark: Material, gold: Material,
		rock: Material, crystal: Material, cloud: Material, pink: Material) -> void:
	MapLook.solid(col, Vector3(CRYPT_HALF * 2.0, 1.6, 4), Vector3(0, CRYPT_Y - 0.8, 0))
	MapLook.box(look, Vector3(CRYPT_HALF * 2.0 + 0.3, 0.5, 4.3), Vector3(0, CRYPT_Y - 0.25, 0), shade)
	MapLook.box(look, Vector3(CRYPT_HALF * 2.0 + 0.4, 0.08, 4.4), Vector3(0, CRYPT_Y - 0.04, 0), gold)
	MapLook.box(look, Vector3(CRYPT_HALF * 2.0, 1.2, 4.0), Vector3(0, CRYPT_Y - 1.1, 0), rock)
	# Rückwand und Decke der Krypta.
	var h := -1.4 - CRYPT_Y
	MapLook.box(look, Vector3(FLOOR_HALF * 2.0 - 0.4, h, 0.4), Vector3(0, CRYPT_Y + h / 2.0, -2.0), dark)
	for x in [-8.4, -4.2, 4.2, 8.4]:
		MapLook.cylinder(look, 0.3, h, Vector3(x, CRYPT_Y + h / 2.0, -1.5), shade, -1.0, Vector3.ZERO, 12)
		MapLook.box(look, Vector3(0.8, 0.25, 0.8), Vector3(x, -1.55, -1.5), gold)
		# Fackel an jeder Säule.
		MapLook.cylinder(look, 0.12, 0.2, Vector3(x + 0.55, CRYPT_Y + 2.3, -1.6), gold, 0.2)
		MapLook.light(look, Vector3(x + 0.55, CRYPT_Y + 2.6, -1.0), Color(1.0, 0.7, 0.35), 0.9, 4.0)
		MapLook.particles(look, Vector3(x + 0.55, CRYPT_Y + 2.45, -1.6), Vector3(0.06, 0.02, 0.06),
			Color(1, 0.65, 0.2, 0.9), 12, Vector3(0, 0.9, 0), 0.08, 0.5)
	# Leuchtende Kristalle am Boden und an der Wand.
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 9:
		var x := rng.randf_range(-9.5, 9.5)
		var hgt := rng.randf_range(0.5, 1.3)
		MapLook.cylinder(look, 0.18, hgt, Vector3(x, CRYPT_Y + hgt / 2.0, rng.randf_range(-1.8, -1.2)), crystal, 0.0,
			Vector3(0, 0, rng.randf_range(-20, 20)), 6)
	MapLook.light(look, Vector3(-2.0, CRYPT_Y + 1.2, 0.5), Color(0.5, 0.75, 1.0), 1.0, 7.0)
	MapLook.light(look, Vector3(6.0, CRYPT_Y + 1.2, 0.5), Color(0.5, 0.75, 1.0), 0.8, 6.0)
	# Schatztruhen und eine kleine goldene Schale mit blauem Licht in der Mitte.
	for x in [-6.3, 6.3]:
		MapLook.box(look, Vector3(0.9, 0.55, 0.6), Vector3(x, CRYPT_Y + 0.28, -1.5), MapLook.mat(Color(0.45, 0.28, 0.15)))
		MapLook.box(look, Vector3(0.95, 0.1, 0.65), Vector3(x, CRYPT_Y + 0.5, -1.5), gold)
	MapLook.cylinder(look, 0.45, 0.25, Vector3(0, CRYPT_Y + 0.9, -1.6), gold, 0.25, Vector3.ZERO, 16)
	MapLook.cylinder(look, 0.2, 0.9, Vector3(0, CRYPT_Y + 0.45, -1.6), shade, 0.25, Vector3.ZERO, 12)
	MapLook.sphere(look, 0.25, Vector3(0, CRYPT_Y + 1.2, -1.6), crystal)
	MapLook.particles(look, Vector3(0, CRYPT_Y + 1.6, -1.2), Vector3(9, 1.2, 0.6), Color(0.6, 0.85, 1.0, 0.9), 25,
		Vector3(0, 0.15, 0), 0.05, 4.0)
	# Schwebende Felseninsel unter der Krypta (ein umgedrehter, flacher Kegel) mit Wolken.
	var island := MapLook.cylinder(look, 1.0, 7.0, Vector3(0, CRYPT_Y - 5.2, -1.0), rock, CRYPT_HALF + 0.6,
		Vector3.ZERO, 20)
	island.scale = Vector3(1.0, 1.0, 0.32)
	MapLook.cylinder(look, 0.6, 2.6, Vector3(-4.0, CRYPT_Y - 3.0, 0.6), rock, 2.4, Vector3.ZERO, 10)
	MapLook.cylinder(look, 0.5, 2.2, Vector3(5.0, CRYPT_Y - 2.8, 0.7), rock, 2.0, Vector3.ZERO, 10)
	for i in 7:
		var x := -9.0 + i * 3.0
		MapLook.sphere(look, 1.4, Vector3(x, CRYPT_Y - 2.4 - absf(x) * 0.05, 1.2), cloud if i % 2 else pink,
			Vector3(1.6, 0.55, 1.0))


## Tempeldach: Gebälk über den Säulen (man kann draufspringen), dahinter der Giebel und ganz oben die Spitze.
func _roof(col: Node3D, look: Node3D, plat: Node3D, marble: Material, shade: Material, gold: Material) -> void:
	MapLook.platform(col, Vector3(ROOF_HALF * 2.0, 0.3, 2.6), Vector3(0, ROOF_Y - 0.15, 0))
	MapLook.box(plat, Vector3(ROOF_HALF * 2.0 + 0.2, 0.25, 3.6), Vector3(0, ROOF_Y - 0.12, -0.6), marble)
	MapLook.box(plat, Vector3(ROOF_HALF * 2.0 + 0.3, 0.08, 3.7), Vector3(0, ROOF_Y + 0.01, -0.6), gold)
	MapLook.box(look, Vector3(ROOF_HALF * 2.0, 0.7, 1.4), Vector3(0, ROOF_Y - 0.6, -1.7), marble)
	MapLook.box(look, Vector3(ROOF_HALF * 2.0 + 0.05, 0.1, 1.45), Vector3(0, ROOF_Y - 0.95, -1.7), gold)
	# Dreieckiger Giebel hinter den Kämpfern, mit Goldrand.
	var gable := PrismMesh.new()
	gable.size = Vector3(ROOF_HALF * 2.0, PEAK_Y - ROOF_Y - 0.15, 1.0)
	var g := MeshInstance3D.new()
	g.mesh = gable
	g.material_override = shade
	g.position = Vector3(0, ROOF_Y + (PEAK_Y - ROOF_Y - 0.15) / 2.0, -1.9)
	look.add_child(g)
	var inner := PrismMesh.new()
	inner.size = Vector3(ROOF_HALF * 2.0 - 2.0, PEAK_Y - ROOF_Y - 0.9, 0.2)
	var gi := MeshInstance3D.new()
	gi.mesh = inner
	gi.material_override = MapLook.mat(Color(0.3, 0.45, 0.85), 0.6)
	gi.position = Vector3(0, ROOF_Y + 0.15 + (PEAK_Y - ROOF_Y - 0.9) / 2.0, -1.35)
	look.add_child(gi)
	# Goldene Sonne im Giebelfeld.
	MapLook.cylinder(look, 0.45, 0.06, Vector3(0, ROOF_Y + 0.75, -1.2), MapLook.mat(Color(1.0, 0.82, 0.35), 0.3, 0.6, 1.2),
		-1.0, Vector3(90, 0, 0), 24)
	# Spitze: kleine goldene Plattform ganz oben, an den Dachecken goldene Zierspitzen.
	MapLook.platform(col, Vector3(4.0, 0.3, 2.2), Vector3(0, PEAK_Y - 0.15, 0))
	MapLook.box(plat, Vector3(4.1, 0.3, 2.3), Vector3(0, PEAK_Y - 0.15, -0.3), gold)
	MapLook.cylinder(plat, 0.3, 0.9, Vector3(0, PEAK_Y + 0.45, -1.4), gold, 0.0, Vector3.ZERO, 8)
	for x in [-ROOF_HALF + 0.3, ROOF_HALF - 0.3]:
		MapLook.cylinder(plat, 0.25, 0.7, Vector3(x, ROOF_Y + 0.4, -1.7), gold, 0.0, Vector3.ZERO, 8)
	MapLook.light(plat, Vector3(0, PEAK_Y + 0.8, 0.6), Color(1.0, 0.85, 0.55), 0.8, 5.0)


## Stilisierte Göttin aus Marmor auf einem Sockel, mit goldenem Speer und Heiligenschein.
func _statue(parent: Node3D, pos: Vector3, marble: Material, shade: Material, gold: Material) -> void:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	MapLook.cylinder(root, 0.6, 0.5, Vector3(0, 0.25, 0), shade, 0.55, Vector3.ZERO, 16)
	MapLook.cylinder(root, 0.62, 0.08, Vector3(0, 0.52, 0), gold, -1.0, Vector3.ZERO, 16)
	MapLook.cylinder(root, 0.45, 1.5, Vector3(0, 1.3, 0), marble, 0.22, Vector3.ZERO, 16)   # Gewand
	MapLook.cylinder(root, 0.2, 0.45, Vector3(0, 2.25, 0), marble, 0.16, Vector3.ZERO, 12)   # Oberkörper
	MapLook.sphere(root, 0.2, Vector3(0, 2.62, 0), marble)                                   # Kopf
	MapLook.sphere(root, 0.17, Vector3(0, 2.68, -0.06), shade, Vector3(1.1, 1.0, 1.0))      # Haar
	MapLook.cylinder(root, 0.07, 0.75, Vector3(-0.32, 2.2, 0.1), marble, 0.06, Vector3(0, 0, -35))
	MapLook.cylinder(root, 0.07, 0.6, Vector3(0.3, 2.35, 0.05), marble, 0.06, Vector3(0, 0, 60))
	MapLook.cylinder(root, 0.035, 2.9, Vector3(0.55, 1.95, 0.08), gold, -1.0, Vector3.ZERO, 8)   # Speer
	MapLook.cylinder(root, 0.0, 0.3, Vector3(0.55, 3.55, 0.08), gold, 0.08, Vector3(180, 0, 0), 8)
	MapLook.cylinder(root, 0.3, 0.03, Vector3(0, 2.72, -0.15), MapLook.mat(Color(1.0, 0.85, 0.4), 0.3, 0.6, 1.5),
		-1.0, Vector3(90, 0, 0), 24)                                                           # Heiligenschein
	MapLook.light(root, Vector3(0, 2.6, 0.5), Color(1.0, 0.85, 0.5), 0.8, 3.0)
