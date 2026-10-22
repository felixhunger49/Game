extends Node3D
## Vulkan: schmale Basalt-Arena über einem fließenden Lavasee, zwei niedrige Lavafelsen an den Seiten
## und ein hoher Fels in der Mitte. Glut, Funken und Asche in der Luft.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var basalt_tex := MapFX.tex("basalt")
	var basalt: Material = MapFX.textured(basalt_tex, MapFX.tex("basalt_n"), Color(0.75, 0.68, 0.66), 0.4) if basalt_tex \
		else MapLook.mat(Color(0.2, 0.16, 0.15))
	var basalt_dark := MapLook.mat(Color(0.12, 0.1, 0.1))
	var lava := MapFX.lava_material(MapFX.tex("lava"), 3.0)
	var lava_lake := MapFX.lava_material(MapFX.tex("lava"), 1.8)
	$Spawn1.position = Vector3(-3.0, 0.2, 0)
	$Spawn2.position = Vector3(3.0, 0.2, 0)

	# Boden: 14 breit (schmaler als die anderen Maps).
	MapLook.solid(col, Vector3(14, 2.2, 4), Vector3(0, -1.1, 0))
	MapLook.box(look, Vector3(14.4, 2.4, 4.2), Vector3(0, -1.2, 0), basalt)
	MapLook.box(look, Vector3(14.6, 0.15, 4.4), Vector3(0, -0.08, 0), basalt_dark)
	for i in 7:
		var x := -6.0 + i * 2.0
		MapLook.cylinder(look, 0.15, 2.6 + (i % 3) * 0.8, Vector3(x, -3.6 - (i % 3) * 0.4, 0), basalt, 1.3, Vector3.ZERO, 7)
	for c in [[-5.8, 20.0], [-3.6, -15.0], [-1.2, 30.0], [1.0, -10.0], [3.2, 25.0], [5.6, -20.0]]:
		MapLook.box(look, Vector3(0.14, 1.7, 0.06), Vector3(c[0], -1.2, 2.12), lava, Vector3(0, 0, c[1]))
	MapLook.box(look, Vector3(14.5, 0.07, 0.06), Vector3(0, -2.35, 2.12), lava)

	# Plattformen: zwei niedrige Lavafelsen und ein hoher Fels in der Mitte.
	for p in [[-5.2, 2.0, 2.6], [5.2, 2.0, 2.6], [0.0, 4.4, 3.2]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.4), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.45, 2.5), pos + Vector3(0, -0.07, 0), basalt)
		MapLook.box(plat, Vector3(width - 0.6, 0.06, 2.0), pos + Vector3(0, -0.32, 0), lava)
		MapLook.cylinder(plat, 0.1, 1.4, pos + Vector3(0, -1.0, 0), basalt, width * 0.35, Vector3.ZERO, 6)
		MapLook.light(plat, pos + Vector3(0, -0.8, 0.8), Color(1, 0.45, 0.1), 1.2, 4.0)

	# Fließender Lavasee bis kurz vor das Hintergrundbild (die Vulkane sind dort gemalt).
	MapLook.box(bg, Vector3(260, 0.5, 110), Vector3(0, -7.5, 0), lava_lake)
	for r in [[-11.0, -8.0, 6.0], [-9.0, -14.0, -4.0], [11.5, -10.0, -6.0], [13.0, -16.0, 5.0]]:
		MapLook.cylinder(bg, 1.6, 9.0, Vector3(r[0], -3.0, r[1]), basalt, 0.5, Vector3(0, 0, r[2]), 6)

	# Riesiger Drachenschädel im Lavasee: 3D-Modell aus Flux + Trellis, sonst aus Formen gebaut.
	if MapLook.prop(bg, "res://assets/maps/props/drachenschaedel.glb", Vector3(14.5, -7.3, -14.0), 7.5, -60.0) == null:
		_dragon_skull(bg, Vector3(14.5, -7.0, -14.0), 3.4, -50.0)
	MapLook.light(bg, Vector3(13.0, -3.0, -11.0), Color(1, 0.45, 0.1), 3.0, 9.0)

	# Licht von unten (flackert), aufsteigende Glut, Funkenregen und Asche.
	MapLook.light(look, Vector3(0, -5.0, 4.0), Color(1, 0.4, 0.1), 3.0, 14.0)
	fx.flicker_all(self, 0.2)
	MapLook.particles(self, Vector3(0, -5.0, 0), Vector3(16, 1, 5), Color(1, 0.55, 0.1, 0.9), 70,
		Vector3(0, 2.2, 0), 0.1, 6.0)
	MapLook.particles(self, Vector3(0, -6.5, -4), Vector3(18, 0.5, 6), Color(1, 0.8, 0.3, 1.0), 40,
		Vector3(0, 9.0, 0), 0.07, 1.6, Vector3(0, -9.0, 0))
	MapLook.particles(self, Vector3(0, 14.0, -2), Vector3(22, 1, 8), Color(0.35, 0.32, 0.3, 0.8), 60,
		Vector3(0.4, -0.8, 0), 0.08, 16.0)
	MapFX.mood(self, Color(0.45, 0.12, 0.04), 0.012, 0.9, 1.15, 1.08)

	# Vordergrund: dunkle Felsspitzen und Rauch in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.cylinder(fg, 0.5, 1.6, Vector3(side * 2.07, -1.40, -3.0), basalt_dark, 0.0, Vector3(0, 0, side * 12.0), 6)
		MapLook.cylinder(fg, 0.3, 1.0, Vector3(side * 1.72, -1.35, -3.0), basalt_dark, 0.0, Vector3(0, 0, -side * 8.0), 6)
	MapLook.backdrop(bg, "res://assets/maps/vulkan/hintergrund.png")


## Drachenschädel aus glänzendem Obsidian: Schädel, Schnauze, Kiefer, Zähne, Hörner und glühende Augen.
func _dragon_skull(parent: Node3D, pos: Vector3, size: float, turn: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = turn
	root.scale = Vector3.ONE * size
	parent.add_child(root)
	var obsidian := MapLook.mat(Color(0.07, 0.06, 0.08), 0.2, 0.4)
	var bone := MapLook.mat(Color(0.18, 0.16, 0.15), 0.6)
	var eye := MapLook.mat(Color(1.0, 0.45, 0.05), 0.5, 0.0, 6.0)
	MapLook.sphere(root, 1.0, Vector3(0, 1.0, 0), obsidian, Vector3(1.1, 0.85, 1.0))           # Schädel
	MapLook.box(root, Vector3(0.9, 0.55, 1.5), Vector3(0, 0.75, 1.2), obsidian, Vector3(12, 0, 0))   # Schnauze
	MapLook.box(root, Vector3(0.8, 0.25, 1.4), Vector3(0, 0.25, 1.1), bone, Vector3(-6, 0, 0))     # Unterkiefer
	for x in [-0.32, -0.12, 0.12, 0.32]:
		MapLook.cylinder(root, 0.06, 0.25, Vector3(x, 0.5, 1.75), bone, 0.0, Vector3(180, 0, 0), 5)
	for side in [-1, 1]:
		MapLook.sphere(root, 0.18, Vector3(side * 0.42, 1.15, 0.78), eye)
		MapLook.cylinder(root, 0.22, 1.6, Vector3(side * 0.7, 1.8, -0.4), obsidian, 0.0, Vector3(-40, 0, side * 30), 8)
		MapLook.cylinder(root, 0.12, 0.9, Vector3(side * 0.95, 1.2, -0.7), obsidian, 0.0, Vector3(-70, 0, side * 50), 6)
	MapLook.light(root, Vector3(0, 1.2, 1.4), Color(1, 0.45, 0.1), 2.5, 6.0)
