extends Node3D
## Vulkan: Basalt-Arena über einem fließenden Lavasee. Darunter eine glühende Lavahöhle mit Lavafällen und einem
## Drachennest, außen zwei Felsnadeln aus der Lava. Zwei Lavafelsen, ein hoher Fels in der Mitte, zwei Vorsprünge
## am Kraterrand und ganz oben die Obsidian-Spitze. Glut, Funken und Asche in der Luft.

const HALF := 10.0
const CAVE_Y := -4.6
const CAVE_HALF := 12.0


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var basalt_tex := MapFX.tex("basalt")
	var basalt: Material = MapFX.textured(basalt_tex, MapFX.tex("basalt_n"), Color(0.75, 0.68, 0.66), 0.4) if basalt_tex \
		else MapLook.mat(Color(0.2, 0.16, 0.15))
	var basalt_dark := MapFX.surface("fels_dunkel", Color(0.12, 0.1, 0.1))
	var lava := MapFX.lava_material(MapFX.tex("lava"), 3.0)
	var lava_lake := MapFX.lava_material(MapFX.tex("lava"), 1.8)
	$Spawn1.position = Vector3(-3.5, 0.2, 0)
	$Spawn2.position = Vector3(3.5, 0.2, 0)
	MapLook.stage_area(self, Rect2(-14.8, CAVE_Y, 29.6, 7.4 - CAVE_Y), HALF)

	# Boden: 20 breit, Lavaadern an der Vorderkante, darunter ist die Höhle.
	MapLook.solid(col, Vector3(HALF * 2.0, 1.4, 4), Vector3(0, -0.7, 0))
	MapLook.box(look, Vector3(HALF * 2.0 + 0.4, 1.5, 4.2), Vector3(0, -0.75, 0), basalt)
	MapLook.box(look, Vector3(HALF * 2.0 + 0.6, 0.15, 4.4), Vector3(0, -0.08, 0), basalt_dark)
	for c in [[-8.6, 20.0], [-5.8, -15.0], [-3.0, 30.0], [-0.4, -10.0], [2.4, 25.0], [5.2, -20.0], [8.2, 15.0]]:
		MapLook.box(look, Vector3(0.12, 1.1, 0.06), Vector3(c[0], -0.75, 2.12), lava, Vector3(0, 0, c[1]))
	MapLook.box(look, Vector3(HALF * 2.0 + 0.5, 0.07, 0.06), Vector3(0, -1.45, 2.12), lava)

	_cave(col, look, plat, basalt, basalt_dark, lava)

	# Plattformen: zwei Lavafelsen, ein hoher Fels in der Mitte, zwei Vorsprünge am Kraterrand, die Obsidian-Spitze.
	for p in [[-5.2, 2.2, 2.6], [5.2, 2.2, 2.6], [0.0, 4.6, 3.2], [-8.8, 5.0, 2.6], [8.8, 5.0, 2.6]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.4), pos)
		MapLook.box(plat, Vector3(width + 0.1, 0.45, 2.5), pos + Vector3(0, -0.07, 0), basalt)
		MapLook.box(plat, Vector3(width - 0.6, 0.06, 2.0), pos + Vector3(0, -0.32, 0), lava)
		MapLook.cylinder(plat, 0.1, 1.4, pos + Vector3(0, -1.0, 0), basalt, width * 0.35, Vector3.ZERO, 6)
		MapLook.light(plat, pos + Vector3(0, -0.8, 0.8), Color(1, 0.45, 0.1), 1.2, 4.0)
	var peak := Vector3(0, 7.4, 0)
	var obsidian := MapFX.surface("fels_dunkel", Color(0.07, 0.06, 0.1), 0.15, 0.5)
	MapLook.platform(col, Vector3(2.4, 0.3, 2.0), peak)
	MapLook.box(plat, Vector3(2.5, 0.4, 2.1), peak + Vector3(0, -0.05, 0), obsidian)
	MapLook.cylinder(plat, 0.05, 1.6, peak + Vector3(0, -1.0, 0), obsidian, 1.1, Vector3(180, 0, 0), 6)
	for side in [-1, 1]:
		MapLook.cylinder(plat, 0.18, 1.0, peak + Vector3(side * 0.9, 0.6, -0.7), obsidian, 0.0, Vector3(0, 0, -side * 15), 5)
	MapLook.box(plat, Vector3(1.8, 0.05, 0.06), peak + Vector3(0, 0.16, 1.02), lava)
	MapLook.light(plat, peak + Vector3(0, 0.6, 0.8), Color(1, 0.4, 0.1), 1.0, 4.0)

	# Zwei Felsnadeln aus der Lava neben der Arena: von hier kommt man aus der Höhle wieder hoch.
	for side in [-1, 1]:
		var pos := Vector3(side * 13.6, -1.6, 0)
		MapLook.platform(col, Vector3(2.2, 0.3, 2.2), pos)
		MapLook.box(plat, Vector3(2.3, 0.45, 2.3), pos + Vector3(0, -0.07, 0), basalt)
		MapLook.cylinder(plat, 0.6, 6.0, pos + Vector3(0, -3.3, -0.2), basalt, 1.1, Vector3.ZERO, 7)
		MapLook.box(plat, Vector3(1.6, 0.06, 1.8), pos + Vector3(0, -0.32, 0), lava)

	# Fließender Lavasee bis kurz vor das Hintergrundbild (die Vulkane sind dort gemalt).
	MapLook.box(bg, Vector3(260, 0.5, 110), Vector3(0, -7.5, 0), lava_lake)
	for r in [[-16.0, -9.0, 6.0], [-11.0, -16.0, -4.0], [16.5, -11.0, -6.0], [14.0, -18.0, 5.0]]:
		MapLook.cylinder(bg, 1.6, 9.0, Vector3(r[0], -3.0, r[1]), basalt, 0.5, Vector3(0, 0, r[2]), 6)

	# Riesiger Drachenschädel im Lavasee: 3D-Modell aus Flux + Trellis, sonst aus Formen gebaut.
	if MapLook.prop(bg, "res://assets/maps/props/drachenschaedel.glb", Vector3(19.5, -7.3, -16.0), 7.5, -60.0) == null:
		_dragon_skull(bg, Vector3(19.5, -7.0, -16.0), 3.4, -50.0)
	MapLook.light(bg, Vector3(18.0, -3.0, -13.0), Color(1, 0.45, 0.1), 3.0, 9.0)

	# Licht von unten (flackert), aufsteigende Glut, Funkenregen und Asche.
	MapLook.light(look, Vector3(0, -6.0, 4.0), Color(1, 0.4, 0.1), 3.0, 16.0)
	fx.flicker_all(self, 0.2)
	MapLook.particles(self, Vector3(0, -6.0, 0), Vector3(20, 1, 5), Color(1, 0.55, 0.1, 0.9), 80,
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
	MapLook.backdrop(bg, "res://assets/maps/vulkan/hintergrund.png", -60.0, 180.0, 10.0)


## Drachenschädel aus glänzendem Obsidian: Schädel, Schnauze, Kiefer, Zähne, Hörner und glühende Augen.
func _dragon_skull(parent: Node3D, pos: Vector3, size: float, turn: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = turn
	root.scale = Vector3.ONE * size
	parent.add_child(root)
	var obsidian := MapFX.surface("fels_dunkel", Color(0.07, 0.06, 0.08), 0.2, 0.4)
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


## Lavahöhle unter der Arena: Basaltwände, Lavafälle an der Rückwand, glühende Kristalle, Basaltsäulen an der Decke
## und ein Drachennest mit glühenden Eiern. Darunter reicht der Fels bis in den Lavasee.
func _cave(col: Node3D, look: Node3D, plat: Node3D, basalt: Material, dark: Material, lava: Material) -> void:
	MapLook.solid(col, Vector3(CAVE_HALF * 2.0, 1.6, 4), Vector3(0, CAVE_Y - 0.8, 0))
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 + 0.3, 1.7, 4.2), Vector3(0, CAVE_Y - 0.85, 0), basalt)
	MapLook.box(look, Vector3(CAVE_HALF * 2.0 + 0.4, 0.12, 4.3), Vector3(0, CAVE_Y - 0.06, 0), dark)
	for i in 9:
		var x := -10.0 + i * 2.5
		MapLook.cylinder(look, 0.2, 2.6 + (i % 3) * 0.6, Vector3(x, CAVE_Y - 2.6 - (i % 3) * 0.3, 0), basalt, 1.3, Vector3.ZERO, 7)
	var h := -1.4 - CAVE_Y
	MapLook.box(look, Vector3(HALF * 2.0, h, 0.4), Vector3(0, CAVE_Y + h / 2.0, -2.0), dark)
	# Lavafälle an der Rückwand, die in eine glühende Rinne fließen.
	for x in [-6.5, 2.0, 7.5]:
		MapLook.box(look, Vector3(0.9, h, 0.1), Vector3(x, CAVE_Y + h / 2.0, -1.75), lava)
		MapLook.light(look, Vector3(x, CAVE_Y + 1.5, -1.0), Color(1, 0.45, 0.1), 1.4, 5.0)
	MapLook.box(look, Vector3(HALF * 2.0 - 0.5, 0.1, 0.5), Vector3(0, CAVE_Y + 0.05, -1.6), lava)
	# Basaltsäulen hängen von der Decke, glühende Kristalle am Boden.
	var crystal := MapLook.mat(Color(1.0, 0.3, 0.1, 0.9), 0.2, 0.0, 3.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 10:
		var x := rng.randf_range(-9.5, 9.5)
		var len := rng.randf_range(0.4, 1.1)
		MapLook.cylinder(look, 0.0, len, Vector3(x, -1.4 - len / 2.0, rng.randf_range(-1.8, -1.0)), basalt, 0.25, Vector3.ZERO, 6)
	for i in 7:
		var x := rng.randf_range(-10.0, 10.0)
		var hgt := rng.randf_range(0.4, 1.0)
		MapLook.cylinder(look, 0.15, hgt, Vector3(x, CAVE_Y + hgt / 2.0, rng.randf_range(-1.7, -1.2)), crystal, 0.0,
			Vector3(0, 0, rng.randf_range(-25, 25)), 5)
	# Drachennest mit drei glühenden Eiern.
	var nest := Vector3(-2.5, CAVE_Y, -1.3)
	MapLook.cylinder(look, 1.1, 0.35, nest + Vector3(0, 0.17, 0), MapFX.surface("rinde", Color(0.25, 0.18, 0.12)), 0.9, Vector3.ZERO, 14)
	for e in [[-0.35, 0.0, 15.0], [0.3, 0.1, -10.0], [0.0, -0.3, 5.0]]:
		MapLook.sphere(look, 0.28, nest + Vector3(e[0], 0.6, e[1]), MapLook.mat(Color(0.9, 0.35, 0.1), 0.3, 0.2, 1.4),
			Vector3(0.85, 1.15, 0.85)).rotation_degrees.z = e[2]
	MapLook.light(look, nest + Vector3(0, 1.0, 1.0), Color(1, 0.5, 0.15), 1.2, 4.0)
	MapLook.particles(look, Vector3(0, CAVE_Y + 0.4, -0.5), Vector3(10, 0.2, 1.0), Color(1, 0.6, 0.2, 0.9), 25,
		Vector3(0, 1.2, 0), 0.06, 2.0)
