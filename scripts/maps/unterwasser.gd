extends Node3D
## Unterwasser-Kuppel: Arena unter einer Glaskuppel am Meeresgrund. Boden aus hellem Stein mit Korallen,
## draußen Riffe, Seetang, Fischschwärme und ein Wrack. Eine Luftschleuse in der Mitte, zwei schwebende Korallenfelsen,
## Korallen-Vorsprünge außen und oben eine Glasbrücke. Aufsteigende Blasen und Lichtstrahlen von der Oberfläche.


func _ready() -> void:
	var col: Node3D = $Collision
	var look: Node3D = $StageLook
	var plat: Node3D = $Platforms
	var bg: Node3D = $Background
	var fx := MapFX.attach(self)
	var floor_tex := MapFX.tex("korallen")
	var floor_mat: Material = MapFX.textured(floor_tex, MapFX.tex("korallen_n"), Color.WHITE, 0.3) if floor_tex \
		else MapLook.mat(Color(0.75, 0.82, 0.85))
	var steel := MapLook.mat(Color(0.55, 0.6, 0.65), 0.35, 0.8)
	var glass := MapLook.mat(Color(0.7, 0.9, 1.0, 0.18), 0.05, 0.0, 0.2)
	var glass_edge := MapLook.mat(Color(0.5, 0.95, 1.0), 0.3, 0.0, 2.0)
	var coral_pink := MapLook.mat(Color(1.0, 0.45, 0.55), 0.8)
	var coral_orange := MapLook.mat(Color(1.0, 0.6, 0.25), 0.8)
	var coral_purple := MapLook.mat(Color(0.65, 0.35, 0.9), 0.8)
	var kelp := MapLook.mat(Color(0.25, 0.55, 0.3), 1.0)
	var seabed := MapLook.mat(Color(0.75, 0.7, 0.55), 1.0)
	var wreck := MapLook.mat(Color(0.3, 0.25, 0.2), 1.0)
	$Spawn1.position = Vector3(-3.0, 0.2, 0)
	$Spawn2.position = Vector3(3.0, 0.2, 0)

	# Boden: 15 breit, Stahlring und leuchtende Kante.
	MapLook.solid(col, Vector3(15, 2.2, 4), Vector3(0, -1.1, 0))
	MapLook.box(look, Vector3(15.4, 0.6, 4.4), Vector3(0, -0.3, 0), floor_mat)
	MapLook.box(look, Vector3(15.6, 0.12, 4.6), Vector3(0, -0.62, 0), steel)
	MapLook.box(look, Vector3(15.6, 0.05, 0.06), Vector3(0, -0.02, 2.2), glass_edge)
	MapLook.box(look, Vector3(14.0, 1.6, 4.0), Vector3(0, -1.5, 0), steel)

	# Glaskuppel: Rippen aus Stahl und eine durchsichtige Halbkugel hinter der Arena.
	var dome := MapLook.sphere(bg, 11.0, Vector3(0, -1.0, -8.0), glass, Vector3(1.0, 1.0, 0.5))
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 7:
		var angle := -75.0 + i * 25.0
		var rib := Node3D.new()
		rib.position = Vector3(0, -1.0, -8.2)
		rib.rotation_degrees = Vector3(0, 0, angle)
		bg.add_child(rib)
		MapLook.box(rib, Vector3(0.2, 11.0, 0.2), Vector3(0, 5.5, 0), steel)
	MapLook.cylinder(bg, 11.2, 0.3, Vector3(0, -0.9, -8.0), steel, -1.0, Vector3.ZERO, 48)

	# Korallen und Seetang innen am Rand.
	for c in [[-6.6, coral_pink], [-5.8, coral_orange], [6.2, coral_purple], [6.9, coral_pink], [-1.4, coral_purple]]:
		var x: float = c[0]
		MapLook.cylinder(look, 0.12, 0.8, Vector3(x, 0.4, -1.7), c[1], 0.2, Vector3(0, 0, 10), 6)
		MapLook.cylinder(look, 0.1, 0.6, Vector3(x + 0.2, 0.45, -1.6), c[1], 0.16, Vector3(0, 0, -25), 6)
		MapLook.sphere(look, 0.28, Vector3(x - 0.15, 0.2, -1.5), c[1], Vector3(1.2, 0.7, 1.0))
	for x in [-4.0, 3.2, 5.0]:
		for k in 3:
			MapLook.cylinder(look, 0.06, 1.6 + k * 0.4, Vector3(x + k * 0.2, 0.8 + k * 0.2, -1.8), kelp, 0.03,
				Vector3(0, 0, -8 + k * 8), 5)

	# Luftschleuse in der Mitte: flacher Stahlbuckel mit leuchtendem Ring, auf den man steigen kann.
	MapLook.solid(col, Vector3(2.6, 0.5, 3.0), Vector3(0, 0.25, 0))
	MapLook.box(look, Vector3(2.6, 0.5, 3.0), Vector3(0, 0.25, 0), steel)
	MapLook.cylinder(look, 0.9, 0.08, Vector3(0, 0.52, 0), glass_edge, -1.0, Vector3.ZERO, 32)
	MapLook.cylinder(look, 0.8, 0.06, Vector3(0, 0.55, 0), MapLook.mat(Color(0.2, 0.25, 0.3), 0.4, 0.8), -1.0, Vector3.ZERO, 32)

	# Zwei Korallenfelsen, die gegenläufig auf und ab schweben.
	for b in [[-4.4, 0.0], [4.4, 0.5]]:
		var x: float = b[0]
		var rock := MovingPlatform.create(plat, Vector3(2.6, 0.3, 2.2), Vector3(x, 1.8, 0), Vector3(x, 3.6, 0), 6.0, b[1])
		MapLook.box(rock, Vector3(2.7, 0.45, 2.2), Vector3(0, -0.07, 0), floor_mat)
		MapLook.sphere(rock, 0.6, Vector3(-0.8, -0.45, 0.4), coral_pink, Vector3(1.4, 0.7, 1.0))
		MapLook.sphere(rock, 0.5, Vector3(0.9, -0.4, 0.3), coral_orange, Vector3(1.3, 0.6, 1.0))
		MapLook.cylinder(rock, 0.1, 0.6, Vector3(0.4, 0.3, -0.8), coral_purple, 0.16, Vector3(0, 0, -15), 6)
		MapLook.particles(rock, Vector3(0, -0.5, 0), Vector3(0.8, 0.1, 0.5), Color(0.85, 0.95, 1.0, 0.6), 12,
			Vector3(0, -1.0, 0), 0.06, 1.5)

	# Glasbrücke oben in der Mitte.
	var top := Vector3(0, 5.0, 0)
	MapLook.platform(col, Vector3(3.4, 0.3, 2.0), top)
	MapLook.box(plat, Vector3(3.5, 0.15, 2.0), top + Vector3(0, 0.05, 0), glass)
	MapLook.box(plat, Vector3(3.6, 0.05, 0.06), top + Vector3(0, 0.13, 1.0), glass_edge)
	MapLook.box(plat, Vector3(3.6, 0.05, 0.06), top + Vector3(0, 0.13, -1.0), glass_edge)
	for side in [-1, 1]:
		MapLook.box(plat, Vector3(0.2, 5.0, 0.2), Vector3(side * 1.7, 2.5, -0.8), steel)

	# Kleine Korallen-Vorsprünge außen an der Kuppelwand, hoch oben.
	for side in [-1, 1]:
		var pos := Vector3(side * 6.9, 4.0, 0)
		MapLook.platform(col, Vector3(1.6, 0.3, 1.8), pos)
		MapLook.box(plat, Vector3(1.6, 0.4, 1.8), pos + Vector3(0, -0.05, 0), floor_mat)
		MapLook.sphere(plat, 0.55, pos + Vector3(side * 0.2, -0.5, 0.0), coral_purple if side < 0 else coral_pink, Vector3(1.2, 1.0, 1.0))
		MapLook.box(plat, Vector3(0.25, 4.0, 0.25), Vector3(side * 7.5, 2.0, -0.8), steel)

	# Draußen: Meeresgrund, Riffe, ein Wrack, Fischschwärme.
	MapLook.box(bg, Vector3(140, 0.4, 70), Vector3(0, -1.5, -40), seabed)
	for r in [[-16.0, -14.0, coral_pink], [15.0, -12.0, coral_purple], [-8.0, -22.0, coral_orange], [9.0, -24.0, coral_pink]]:
		MapLook.sphere(bg, 2.5, Vector3(r[0], -0.5, r[1]), r[2], Vector3(1.6, 0.9, 1.2))
		MapLook.cylinder(bg, 0.3, 4.0, Vector3(r[0] + 1.5, 1.5, r[1]), kelp, 0.1, Vector3(0, 0, 8), 6)
	MapLook.box(bg, Vector3(14.0, 3.5, 4.0), Vector3(20.0, 0.5, -30.0), wreck, Vector3(0, -30, 18))
	MapLook.cylinder(bg, 0.3, 9.0, Vector3(19.0, 5.0, -30.0), wreck, -1.0, Vector3(0, 0, 25), 6)
	fx.flock(Vector3(0, 8.0, -12.0), 6, Color(1.0, 0.7, 0.2), Vector3(14, 1.0, 5), 0.25, 0.3)
	fx.flock(Vector3(-4.0, 11.0, -15.0), 5, Color(0.3, 0.7, 1.0), Vector3(12, 1.0, 5), -0.3, 0.3)

	# Aufsteigende Blasen, Lichtstrahlen von oben, blaues Licht.
	MapLook.particles(self, Vector3(0, -1.0, -1.5), Vector3(12, 0.5, 3), Color(0.85, 0.95, 1.0, 0.6), 60,
		Vector3(0, 2.0, 0), 0.08, 6.0)
	for x in [-7.0, -2.0, 3.0, 8.0]:
		MapLook.box(bg, Vector3(1.8, 24.0, 0.05), Vector3(x, 8.0, -9.0), MapLook.mat(Color(0.7, 0.95, 1.0, 0.1), 1.0, 0.0, 0.6),
			Vector3(0, 0, 12))
	MapLook.light(look, Vector3(0, 7.0, 4.0), Color(0.6, 0.85, 1.0), 1.0, 14.0)
	MapLook.light(look, Vector3(0, 0.6, 1.5), Color(0.3, 0.9, 1.0), 0.6, 8.0)
	MapFX.mood(self, Color(0.1, 0.35, 0.55), 0.02, 0.6, 1.15, 1.05)

	# Vordergrund: Korallen in den unteren Ecken.
	var fg := MapFX.foreground(self)
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.45, Vector3(side * 2.05, -1.32, -3.0), coral_pink if side < 0 else coral_purple, Vector3(1.5, 0.7, 0.5))
		MapLook.cylinder(fg, 0.06, 0.6, Vector3(side * 1.65, -1.2, -3.0), kelp, 0.03, Vector3(0, 0, side * 10.0), 5)
	MapLook.backdrop(bg, "res://assets/maps/unterwasser/hintergrund.png")
