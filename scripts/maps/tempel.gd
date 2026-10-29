extends Node3D
## Japanischer Tempel: Steinhof mit rotem Holzgeländer vor einer Tempelhalle mit geschwungenem Dach,
## eine erhöhte Schrein-Terrasse mit Gong, eine zweistöckige Pagode, der Torii-Balken und ein Ausguck. Kirschbäume,
## Steinlaternen, ein großer Gong (für das Gong-Ereignis) und fallende Kirschblüten.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var stone_tex := MapFX.tex("steinplatten")
	var stone: Material = MapFX.textured(stone_tex, MapFX.tex("steinplatten_n"), Color.WHITE, 0.35) if stone_tex \
		else MapLook.mat(Color(0.72, 0.72, 0.7))
	var stone_dark := MapLook.mat(Color(0.45, 0.45, 0.44))
	var red := MapLook.mat(Color(0.78, 0.12, 0.08), 0.6)
	var black := MapLook.mat(Color(0.1, 0.08, 0.08), 0.5)
	var wood := MapLook.mat(Color(0.45, 0.28, 0.16), 0.8)
	var roof := MapLook.mat(Color(0.2, 0.22, 0.28), 0.6, 0.2)
	var paper := MapLook.mat(Color(1.0, 0.92, 0.75), 0.9, 0.0, 0.8)
	var gold := MapLook.mat(Color(0.95, 0.72, 0.3), 0.3, 0.8)
	$Spawn1.position = Vector3(-3.0, 0.2, 0)
	$Spawn2.position = Vector3(2.0, 0.2, 0)

	# Steinhof: 15 breit, darunter Stufen.
	MapLook.solid(col, Vector3(15, 2.2, 4), Vector3(0, -1.1, 0))
	MapLook.box(look, Vector3(15.4, 0.6, 4.4), Vector3(0, -0.3, 0), stone)
	MapLook.box(look, Vector3(14.8, 0.6, 4.2), Vector3(0, -0.9, 0.2), stone_dark)
	MapLook.box(look, Vector3(14.0, 0.8, 4.0), Vector3(0, -1.6, 0.4), stone_dark)
	# Rotes Holzgeländer hinten.
	for i in 8:
		MapLook.box(look, Vector3(0.14, 1.0, 0.14), Vector3(-7.4 + i * 1.45, 0.5, -1.9), red)
	MapLook.box(look, Vector3(10.3, 0.12, 0.16), Vector3(-2.3, 0.95, -1.9), red)
	MapLook.box(look, Vector3(10.3, 0.08, 0.12), Vector3(-2.3, 0.5, -1.9), red)

	# Tempelhalle hinten: Pfosten, Papierwände und ein geschwungenes Dach.
	for i in 7:
		MapLook.box(bg, Vector3(0.4, 5.0, 0.4), Vector3(-9.0 + i * 3.0, 2.5, -7.0), red)
	for i in 6:
		MapLook.box(bg, Vector3(2.6, 3.6, 0.1), Vector3(-7.5 + i * 3.0, 2.0, -7.3), paper)
	MapLook.box(bg, Vector3(20.0, 0.4, 1.2), Vector3(0, 5.1, -7.0), black)
	MapLook.box(bg, Vector3(23.0, 0.5, 5.0), Vector3(0, 5.9, -7.0), roof, Vector3(-12, 0, 0))
	MapLook.box(bg, Vector3(15.0, 1.4, 3.0), Vector3(0, 7.0, -7.6), roof, Vector3(-18, 0, 0))
	for side in [-1, 1]:
		MapLook.box(bg, Vector3(3.0, 0.4, 4.0), Vector3(side * 11.8, 6.4, -7.0), roof, Vector3(-12, 0, side * -14))
		MapLook.sphere(bg, 0.25, Vector3(side * 13.2, 6.9, -6.0), gold)

	# Schrein-Terrasse rechts: erhöht, mit zwei Stufen. Darauf hängt der große Gong (für das Gong-Ereignis).
	MapLook.solid(col, Vector3(3.8, 1.0, 4), Vector3(5.6, 0.5, 0))
	MapLook.solid(col, Vector3(0.8, 0.5, 4), Vector3(3.3, 0.25, 0))
	MapLook.box(look, Vector3(3.9, 1.0, 4.2), Vector3(5.6, 0.5, 0), stone)
	MapLook.box(look, Vector3(4.0, 0.1, 4.3), Vector3(5.6, 1.0, 0), red)
	MapLook.box(look, Vector3(0.8, 0.5, 4.2), Vector3(3.3, 0.25, 0), stone_dark)
	var gong_root := Node3D.new()
	gong_root.name = "Gong"
	gong_root.position = Vector3(6.2, 2.9, -1.4)
	look.add_child(gong_root)
	for side in [-1, 1]:
		MapLook.box(look, Vector3(0.18, 3.4, 0.18), Vector3(6.2 + side * 1.0, 2.7, -1.4), wood)
	MapLook.box(look, Vector3(2.4, 0.18, 0.2), Vector3(6.2, 4.4, -1.4), wood)
	MapLook.cylinder(gong_root, 0.8, 0.1, Vector3(0, 0, 0), gold, -1.0, Vector3(90, 0, 0), 32)
	MapLook.cylinder(gong_root, 0.3, 0.12, Vector3(0, 0, 0.02), MapLook.mat(Color(0.8, 0.55, 0.2), 0.3, 0.9), -1.0,
		Vector3(90, 0, 0), 24)

	# Steinlaternen.
	for l in [[-6.9, 0.0], [-1.2, 0.0], [4.3, 1.0]]:
		var x: float = l[0]
		var y: float = l[1]
		MapLook.box(look, Vector3(0.5, 0.2, 0.5), Vector3(x, y + 0.1, -1.2), stone_dark)
		MapLook.cylinder(look, 0.12, 0.9, Vector3(x, y + 0.65, -1.2), stone_dark)
		MapLook.box(look, Vector3(0.5, 0.45, 0.5), Vector3(x, y + 1.3, -1.2), paper)
		MapLook.cylinder(look, 0.45, 0.25, Vector3(x, y + 1.65, -1.2), stone_dark, 0.05, Vector3.ZERO, 4)
		MapLook.light(look, Vector3(x, y + 1.3, -0.8), Color(1.0, 0.75, 0.4), 0.9, 3.5)

	# Zweistöckige Pagode links: zwei geschwungene Dächer als Plattformen übereinander.
	for p in [[-5.3, 2.3, 3.2], [-5.3, 4.5, 2.2]]:
		var pos := Vector3(p[0], p[1], 0)
		var width: float = p[2]
		MapLook.platform(col, Vector3(width, 0.3, 2.2), pos)
		MapLook.box(plat, Vector3(width + 0.4, 0.25, 2.4), pos + Vector3(0, -0.02, 0), roof)
		MapLook.box(plat, Vector3(width + 0.8, 0.12, 2.6), pos + Vector3(0, -0.2, 0.1), roof, Vector3(-6, 0, 0))
		for side in [-1, 1]:
			MapLook.sphere(plat, 0.12, pos + Vector3(side * (width * 0.5 + 0.4), -0.15, 1.1), gold)
		MapLook.box(plat, Vector3(width - 0.6, 1.9, 1.6), pos + Vector3(0, -1.2, -0.5), red)
		MapLook.box(plat, Vector3(width - 1.0, 1.2, 0.05), pos + Vector3(0, -1.2, 0.31), paper)
	MapLook.cylinder(plat, 0.06, 1.2, Vector3(-5.3, 5.2, 0), gold, 0.02, Vector3.ZERO, 8)

	# Bambus-Sprungbrett links unten: schleudert hoch auf die Pagode.
	var spring := BouncePad.create(plat, Vector3(1.0, 0.4, 2.0), Vector3(-7.0, 0.2, 0), 16.5)
	spring.visual = Node3D.new()
	spring.add_child(spring.visual)
	var bamboo := MapLook.mat(Color(0.55, 0.7, 0.3), 0.7)
	for k in 4:
		MapLook.cylinder(spring.visual, 0.08, 1.0, Vector3(-0.3 + k * 0.2, 0.05, 0.2), bamboo, -1.0, Vector3(90, 0, 0), 8)
	MapLook.box(spring.visual, Vector3(0.9, 0.08, 0.5), Vector3(0, 0.15, 0.2), MapLook.mat(Color(0.75, 0.15, 0.1), 0.6))

	# Torii in der Mitte: der Querbalken ist eine Plattform.
	var torii := Vector3(-0.6, 3.4, 0)
	MapLook.platform(col, Vector3(3.8, 0.3, 1.6), torii)
	MapLook.box(plat, Vector3(5.0, 0.35, 0.9), torii + Vector3(0, 0.0, -0.3), black)
	MapLook.box(plat, Vector3(4.0, 0.3, 1.6), torii + Vector3(0, -0.02, 0.1), red)
	MapLook.box(plat, Vector3(3.6, 0.25, 0.4), torii + Vector3(0, -0.8, -0.6), red)
	MapLook.box(plat, Vector3(0.5, 0.6, 0.12), torii + Vector3(0, -0.45, -0.45), black)
	for side in [-1, 1]:
		MapLook.cylinder(plat, 0.22, 3.5, torii + Vector3(side * 1.6, -1.7, -0.6), red, -1.0, Vector3.ZERO, 12)
		MapLook.box(plat, Vector3(0.55, 0.3, 0.55), Vector3(torii.x + side * 1.6, 0.15, -0.6), black)

	# Ausguck rechts oben über der Terrasse, auf Holzpfosten.
	var lookout := Vector3(4.6, 5.0, 0)
	MapLook.platform(col, Vector3(2.4, 0.3, 2.0), lookout)
	MapLook.box(plat, Vector3(2.5, 0.25, 2.0), lookout, wood)
	MapLook.box(plat, Vector3(2.7, 0.1, 0.1), lookout + Vector3(0, 0.6, -0.95), red)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.16, 4.0, 0.16), lookout + Vector3(side * 1.0, -2.1, -0.8), wood)
		MapLook.box(plat, Vector3(0.1, 0.7, 0.1), lookout + Vector3(side * 1.25, 0.3, -0.95), red)

	# Kirschbäume: gemalt (Flux) und ausgeschnitten (BiRefNet), damit Blüten und Rinde Struktur haben.
	# [x, z, Höhe, Bild, gespiegelt]
	for t in [[-9.8, -3.0, 6.5, "baum_gross", false], [9.6, -3.5, 6.0, "baum_doppel", true],
			[-13.5, -9.0, 7.5, "baum_doppel", false], [14.0, -10.0, 7.5, "baum_gross", true],
			[-5.5, -11.0, 5.5, "baum_mittel", false], [5.0, -12.0, 5.0, "baum_mittel", true]]:
		MapLook.sprite(bg, "res://assets/maps/tempel/%s.png" % t[3], Vector3(t[0], -0.15, t[1]), t[2], t[4])
	MapLook.box(bg, Vector3(80, 0.4, 40), Vector3(0, -0.2, -22), MapLook.mat(Color(0.5, 0.6, 0.38)))

	# Fallende Kirschblüten, warmes Nachmittagslicht, ein paar Vögel.
	MapLook.particles(self, Vector3(0, 9.0, -1.0), Vector3(14, 1, 4), Color(1.0, 0.75, 0.85, 1.0), 90,
		Vector3(0.6, -0.9, 0), 0.09, 12.0)
	MapLook.light(look, Vector3(0, 5.0, 4.0), Color(1.0, 0.88, 0.75), 0.8, 14.0)
	fx.flicker_all(look, 0.12)
	fx.flock(Vector3(0, 10.0, -8.0), 4, Color(0.2, 0.2, 0.25), Vector3(12, 0.8, 4), 0.3, 0.35)
	MapFX.mood(self, Color(1.0, 0.85, 0.85), 0.004, 0.2, 1.15, 1.1, 0.9)

	# Vordergrund: Kirschblütenzweige in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sprite(fg, "res://assets/maps/tempel/bluetenzweig.png", Vector3(side * 1.95, -1.65, -3.0), 0.75,
			side < 0)
	# Tiefen-Ebene: Kirschbäume, Laterne und Toriis (mit Flux gemalt, mit BiRefNet ausgeschnitten)
	# zwischen Tempel und Hintergrundbild. Die Graskante (bei 83 % der Bildhöhe) steht auf dem Boden.
	MapLook.layer(bg, "res://assets/maps/tempel/mittelgrund.png", -32.0, 76.0, -76.0 * 640.0 / 1536.0 * 0.17, 2,
		Color(0.95, 0.93, 0.97))
	MapLook.backdrop(bg, "res://assets/maps/tempel/hintergrund.png")
