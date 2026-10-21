extends Node3D
## Vulkan: schmale Basalt-Arena über einem Lavasee, zwei niedrige Lavafelsen an den Seiten
## und ein hoher Fels in der Mitte.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var basalt := MapLook.mat(Color(0.2, 0.16, 0.15))
	var basalt_dark := MapLook.mat(Color(0.12, 0.1, 0.1))
	var lava := MapLook.mat(Color(1.0, 0.38, 0.05), 0.6, 0.0, 3.0)
	var lava_lake := MapLook.mat(Color(1.0, 0.3, 0.02), 0.5, 0.0, 1.6)
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

	# Lavasee bis kurz vor das Hintergrundbild (die Vulkane sind dort gemalt).
	MapLook.box(bg, Vector3(260, 0.5, 110), Vector3(0, -7.5, 0), lava_lake)
	for r in [[-11.0, -8.0, 6.0], [-9.0, -14.0, -4.0], [11.5, -10.0, -6.0], [13.0, -16.0, 5.0]]:
		MapLook.cylinder(bg, 1.6, 9.0, Vector3(r[0], -3.0, r[1]), basalt, 0.5, Vector3(0, 0, r[2]), 6)

	# Licht von unten, aufsteigende Glut.
	MapLook.light(look, Vector3(0, -5.0, 4.0), Color(1, 0.4, 0.1), 3.0, 14.0)
	MapLook.particles(self, Vector3(0, -5.0, 0), Vector3(16, 1, 5), Color(1, 0.55, 0.1, 0.9), 70,
		Vector3(0, 2.2, 0), 0.1, 6.0)
	MapLook.backdrop(bg, "res://assets/maps/vulkan/hintergrund.png")
