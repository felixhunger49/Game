extends Node3D
## Wolkentempel: Marmortempel über einem ziehenden Wolkenmeer, drei Ebenen: Boden, zwei Seitenplattformen
## und hoch oben die Altarplattform zwischen den Säulen. Tauben und goldener Glitzer.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var marble_tex := MapFX.tex("marmor")
	var marble: Material = MapFX.textured(marble_tex, MapFX.tex("marmor_n"), Color.WHITE, 0.3, 0.3) if marble_tex \
		else MapLook.mat(Color(0.94, 0.92, 0.88), 0.35)
	var marble_shade: Material = MapFX.textured(marble_tex, MapFX.tex("marmor_n"), Color(0.82, 0.8, 0.8), 0.3, 0.4) if marble_tex \
		else MapLook.mat(Color(0.8, 0.78, 0.76), 0.4)
	var gold := MapLook.mat(Color(1.0, 0.78, 0.3), 0.3, 0.8)
	var cloud := MapLook.mat(Color(1, 1, 1), 1.0)
	var cloud_pink := MapLook.mat(Color(1.0, 0.86, 0.9), 1.0)
	$Spawn1.position = Vector3(-3.0, 0.2, 0)
	$Spawn2.position = Vector3(3.0, 0.2, 0)

	# Tempelboden: 15 breit, mit Stufen und Goldkante.
	MapLook.solid(col, Vector3(15, 2.2, 4), Vector3(0, -1.1, 0))
	MapLook.box(look, Vector3(15.4, 0.6, 4.4), Vector3(0, -0.3, 0), marble)
	MapLook.box(look, Vector3(15.6, 0.1, 4.6), Vector3(0, -0.06, 0), gold)
	MapLook.box(look, Vector3(14.6, 0.6, 4.0), Vector3(0, -0.9, 0), marble_shade)
	MapLook.box(look, Vector3(13.6, 0.8, 3.6), Vector3(0, -1.6, 0), marble_shade)
	for i in 8:
		MapLook.sphere(look, 1.6, Vector3(-7.0 + i * 2.0, -2.6, 0.3), cloud, Vector3(1.4, 0.6, 1.2))

	# Säulen mit Kapitellen und Dachbalken hinten, Fahnen an den äußeren Säulen.
	for i in 6:
		var x := -6.5 + i * 2.6
		MapLook.cylinder(look, 0.38, 6.6, Vector3(x, 3.3, -1.7), marble, -1.0, Vector3.ZERO, 16)
		MapLook.box(look, Vector3(1.0, 0.3, 1.0), Vector3(x, 6.7, -1.7), gold)
		MapLook.box(look, Vector3(1.0, 0.3, 1.0), Vector3(x, 0.15, -1.7), marble_shade)
	MapLook.box(look, Vector3(15.0, 0.6, 1.2), Vector3(0, 7.15, -1.7), marble)
	MapLook.box(look, Vector3(15.0, 0.12, 1.25), Vector3(0, 7.5, -1.7), gold)
	MapLook.box(look, Vector3(15.0, 1.6, 0.4), Vector3(0, 8.3, -1.7), marble)
	for x in [-6.5, 6.5]:
		MapFX.cloth(look, Vector2(0.9, 2.6), Vector3(x, 5.2, -1.25), Color(0.25, 0.4, 0.85), null, true, 0.12)

	# Götterstatue mit goldenem Speer zwischen den mittleren Säulen.
	_statue(look, Vector3(0, 0.0, -1.6), marble, marble_shade, gold)

	# Plattformen: zwei Seitenplattformen und die hohe Altarplattform in der Mitte.
	for p in [[-4.3, 2.3, 3.2], [4.3, 2.3, 3.2], [0.0, 4.7, 3.6]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.4), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.4, 2.5), pos + Vector3(0, -0.05, 0), marble)
		MapLook.box(plat, Vector3(width + 0.2, 0.08, 2.6), pos + Vector3(0, 0.12, 0), gold)
		MapLook.sphere(plat, 1.0, pos + Vector3(0, -0.6, 0.2), cloud, Vector3(width * 0.5, 0.45, 1.2))
	# Goldene Schale mit Feuer auf dem Altar.
	MapLook.cylinder(plat, 0.5, 0.3, Vector3(0, 5.05, -0.8), gold, 0.3, Vector3.ZERO, 16)
	MapLook.light(plat, Vector3(0, 5.6, -0.6), Color(1.0, 0.75, 0.4), 1.2, 4.0)
	MapLook.particles(plat, Vector3(0, 5.3, -0.8), Vector3(0.25, 0.05, 0.25), Color(1, 0.7, 0.2, 0.9), 25,
		Vector3(0, 1.2, 0), 0.12, 0.8)

	# Ziehendes Wolkenmeer unter dem Tempel.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var pos := Vector3(rng.randf_range(-60, 60), rng.randf_range(-9, -6), rng.randf_range(-50, 4))
		var s := rng.randf_range(3.0, 7.0)
		var puff := MapLook.sphere(bg, 1.0, pos, cloud if i % 3 else cloud_pink, Vector3(s * 1.6, s * 0.5, s))
		fx.drift(puff, rng.randf_range(0.5, 1.4), 65.0)

	MapLook.light(look, Vector3(0, 5.0, 4.0), Color(1.0, 0.9, 0.75), 0.8, 14.0)
	fx.flicker_all(plat, 0.2)
	fx.flock(Vector3(0, 9.5, -6.0), 5, Color(1, 1, 1), Vector3(12, 0.8, 4), 0.3, 0.4)
	MapLook.particles(self, Vector3(0, 4.0, 0), Vector3(9, 4, 2), Color(1.0, 0.85, 0.4, 1.0), 35,
		Vector3(0, 0.2, 0), 0.05, 4.0)
	MapFX.mood(self, Color(1.0, 0.88, 0.85), 0.006, 0.2, 1.15, 1.12, 0.92)

	# Vordergrund: Wolkenfetzen in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.5, Vector3(side * 2.02, -1.30, -3.0), cloud, Vector3(1.6, 0.6, 0.6))
		MapLook.sphere(fg, 0.35, Vector3(side * 1.54, -1.35, -3.0), cloud_pink, Vector3(1.4, 0.6, 0.6))
	MapLook.backdrop(bg, "res://assets/maps/wolkentempel/hintergrund.png")


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
