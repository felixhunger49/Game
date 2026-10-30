extends Node3D
## Friedhof: Grabfeld mit der Gruft in der Mitte (das Dach ist eine Plattform), die Grabplatten liegen weiter außen
## und tiefer. Vor der Gruft führt eine offene Treppe hinunter in die Katakomben mit Schädelwänden und Särgen.
## Links steht die Kapelle mit Glockenturm (Dach, Glockenstube, Turmspitze), rechts ein großer toter Baum
## mit Ästen bis weit nach oben.

const LEFT_SHIFT := Vector3(-1.1, -0.45, 0)
const RIGHT_SHIFT := Vector3(1.1, -0.45, 0)
const HALF := 8.0
## Treppenschacht vor der Gruft (halbe Breite).
const SHAFT := 1.0
const CATA_Y := -4.8
const CATA_HALF := 9.0


func _ready() -> void:
	for path in ["LeftPlatform", "Platforms/Slab", "Platforms/candle_triple", "Lights/Light"]:
		get_node(path).position += LEFT_SHIFT
	for path in ["RightPlatform", "Platforms/Slab2", "Platforms/candle_triple2", "Lights/Light2"]:
		get_node(path).position += RIGHT_SHIFT

	var col := Node3D.new()
	add_child(col)
	var stone := MapFX.surface("burgstein", Color(0.45, 0.45, 0.52))
	var stone_dark := MapFX.surface("burgstein", Color(0.3, 0.3, 0.36))
	var bark := MapFX.surface("rinde", Color(0.28, 0.22, 0.2))
	var glow := MapLook.mat(Color(0.6, 0.4, 1.0), 0.5, 0.0, 2.0)
	var earth := MapLook.mat(Color(0.18, 0.13, 0.12), 1.0)
	var dirt := MapLook.mat(Color(0.3, 0.24, 0.2), 1.0)
	$Spawn1.position = Vector3(-3.5, 0.2, 0)
	$Spawn2.position = Vector3(3.5, 0.2, 0)
	MapLook.stage_area(self, Rect2(-13.6, CATA_Y, 26.8, 8.2 - CATA_Y), HALF)

	# Boden: zwei Hälften mit dem Treppenschacht dazwischen. Die mittleren Bodenplatten und die Erde darunter
	# werden ersetzt, damit man in die Katakomben sieht.
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF - SHAFT, 1.4, 4)
	$Stage/CollisionShape3D.shape = shape
	$Stage/CollisionShape3D.position = Vector3((HALF + SHAFT) / 2.0, -0.7, 0)
	MapLook.solid(col, Vector3(HALF - SHAFT, 1.4, 4), Vector3(-(HALF + SHAFT) / 2.0, -0.7, 0))
	for node in $StageLook.get_children():
		if node.name in ["Earth", "EarthBottom"] or (node.name.begins_with("floor_dirt") and absf(node.position.x) < 3.0):
			node.queue_free()
	for side in [-1, 1]:
		MapLook.box(self, Vector3(4.0 - SHAFT, 0.3, 4.0), Vector3(side * (SHAFT + 4.0) / 2.0, -0.15, 0), dirt)
		MapLook.box(self, Vector3(HALF - SHAFT, 1.1, 4.0), Vector3(side * (HALF + SHAFT) / 2.0, -0.85, 0), earth)
		MapLook.box(self, Vector3(0.25, 0.4, 2.6), Vector3(side * (SHAFT + 0.12), 0.1, -0.2), stone_dark)

	_catacombs(col, stone, stone_dark, earth, glow)

	# Gruft in der Mitte: Dach als Plattform, leuchtende Tür über der Treppe.
	var roof := Vector3(0, 3.2, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 2.4), roof)
	MapLook.box(self, Vector3(2.6, 3.0, 1.4), Vector3(0, 1.5, -1.5), stone)
	MapLook.box(self, Vector3(3.3, 0.35, 2.6), roof + Vector3(0, -0.02, 0), stone_dark)
	MapLook.box(self, Vector3(2.4, 0.5, 0.6), roof + Vector3(0, 0.4, -1.2), stone_dark, Vector3(0, 0, 0))
	MapLook.box(self, Vector3(0.9, 1.5, 0.06), Vector3(0, 0.75, -0.78), glow)
	MapLook.light(self, Vector3(0, 1.2, 0.2), Color(0.6, 0.4, 1.0), 1.2, 4.0)
	# Engel auf dem Gruftdach, darüber ein schwebender Grabstein-Bogen.
	var arch := Vector3(0, 6.0, 0)
	MapLook.platform(col, Vector3(2.6, 0.3, 2.0), arch)
	MapLook.box(self, Vector3(2.7, 0.35, 2.0), arch + Vector3(0, -0.05, -0.2), stone)
	MapLook.box(self, Vector3(0.12, 0.6, 0.12), arch + Vector3(0, 0.45, -0.8), stone_dark)
	MapLook.box(self, Vector3(0.5, 0.12, 0.12), arch + Vector3(0, 0.55, -0.8), stone_dark)
	MapLook.particles(self, arch + Vector3(0, -0.4, 0), Vector3(1.0, 0.1, 0.6), Color(0.7, 0.5, 1.0, 0.7), 12,
		Vector3(0, -0.6, 0), 0.06, 1.5)

	# Kapelle links auf einem Hügel: Dach, Glockenstube und Turmspitze.
	MapLook.solid(col, Vector3(4.8, 1.2, 3.6), Vector3(-10.4, -0.9, 0))
	MapLook.box(self, Vector3(5.0, 1.3, 3.8), Vector3(-10.5, -0.9, 0), earth)
	MapLook.box(self, Vector3(5.0, 0.1, 3.8), Vector3(-10.5, -0.28, 0), MapLook.mat(Color(0.2, 0.28, 0.15)))
	var chapel := -11.4
	MapLook.box(self, Vector3(3.2, 3.0, 1.6), Vector3(chapel, 1.2, -1.2), stone)
	MapLook.box(self, Vector3(0.8, 1.4, 0.06), Vector3(chapel, 0.4, -0.38), MapFX.surface("holz", Color(0.25, 0.15, 0.1)))
	MapLook.box(self, Vector3(0.6, 0.8, 0.06), Vector3(chapel - 0.9, 1.6, -0.38), glow)
	MapLook.platform(col, Vector3(3.4, 0.3, 2.2), Vector3(chapel, 2.8, 0))
	MapLook.box(self, Vector3(3.6, 0.35, 2.4), Vector3(chapel, 2.8, -0.2), stone_dark)
	MapLook.box(self, Vector3(1.6, 2.4, 1.4), Vector3(chapel + 0.6, 4.1, -1.2), stone)
	MapLook.platform(col, Vector3(2.0, 0.3, 2.0), Vector3(chapel + 0.6, 5.4, 0))
	MapLook.box(self, Vector3(2.1, 0.3, 2.0), Vector3(chapel + 0.6, 5.4, -0.2), stone_dark)
	MapLook.cylinder(self, 0.3, 0.6, Vector3(chapel + 0.6, 4.7, -0.9), MapLook.mat(Color(0.55, 0.45, 0.3), 0.4, 0.7), 0.2)
	MapLook.cylinder(self, 0.9, 1.8, Vector3(chapel + 0.6, 6.5, -1.0), stone_dark, 0.0, Vector3.ZERO, 4)
	MapLook.platform(col, Vector3(1.4, 0.3, 1.6), Vector3(chapel + 0.6, 7.8, 0))
	MapLook.box(self, Vector3(0.1, 0.8, 0.1), Vector3(chapel + 0.6, 8.3, -0.8), stone)
	MapLook.box(self, Vector3(0.45, 0.1, 0.1), Vector3(chapel + 0.6, 8.45, -0.8), stone)
	MapLook.light(self, Vector3(chapel, 2.0, 0.6), Color(0.6, 0.4, 1.0), 0.8, 4.0)

	# Großer toter Baum rechts auf einem Hügel: Äste in drei Höhen.
	MapLook.solid(col, Vector3(4.4, 1.0, 3.6), Vector3(10.2, -0.4, 0))
	MapLook.box(self, Vector3(4.6, 1.2, 3.8), Vector3(10.3, -0.45, 0), earth)
	MapLook.cylinder(self, 0.45, 9.0, Vector3(10.8, 4.4, -1.0), bark, 0.25, Vector3.ZERO, 8)
	for b in [[8.6, 2.6, 2.4, 90], [12.4, 4.8, 2.2, 90], [9.2, 7.0, 2.4, 90]]:
		var pos := Vector3(b[0], b[1], 0)
		MapLook.platform(col, Vector3(b[2], 0.3, 2.0), pos)
		MapLook.cylinder(self, 0.16, b[2] + 1.0, pos + Vector3(signf(10.8 - b[0]) * 0.5, -0.05, 0), bark, 0.1,
			Vector3(0, 0, b[3]), 8)
		MapLook.box(self, Vector3(b[2], 0.14, 1.0), pos + Vector3(0, 0.06, 0), bark)
	MapLook.cylinder(self, 0.08, 1.6, Vector3(10.4, 8.8, -1.0), bark, 0.02, Vector3(0, 0, 35), 6)
	MapLook.cylinder(self, 0.08, 1.4, Vector3(11.3, 8.6, -1.0), bark, 0.02, Vector3(0, 0, -30), 6)
	# Ein Rabe sitzt ganz oben.
	MapLook.sphere(self, 0.18, Vector3(9.4, 7.4, -0.6), MapLook.mat(Color(0.05, 0.05, 0.07)), Vector3(1.3, 1.0, 0.9))

	# Stimmung: lila Nebel, flackernde Kerzen, Fledermäuse, Glühwürmchen.
	var fx := MapFX.attach(self)
	fx.flicker_all($Lights, 0.35)
	fx.flicker_all(self, 0.2)
	fx.flock(Vector3(2.0, 9.0, -4.0), 6, Color(0.08, 0.06, 0.1), Vector3(11, 1.2, 3), 0.55, 0.35, true)
	MapLook.particles(self, Vector3(0, 1.5, 0.5), Vector3(11, 1.2, 1.5), Color(0.75, 1.0, 0.4, 1.0), 30,
		Vector3(0, 0.2, 0), 0.06, 5.0)
	MapFX.mood(self, Color(0.3, 0.18, 0.45), 0.02, 0.8, 1.1, 1.08)

	# Vordergrund: kahle Äste in den oberen Ecken.
	var fg := MapFX.foreground(self)
	var dark := MapLook.mat(Color(0.06, 0.05, 0.08))
	for side in [-1, 1]:
		MapLook.cylinder(fg, 0.04, 1.6, Vector3(side * 1.94, 1.08, -3.0), dark, 0.015, Vector3(0, 0, side * 65.0), 5)
		MapLook.cylinder(fg, 0.025, 0.7, Vector3(side * 1.54, 0.95, -3.0), dark, 0.01, Vector3(0, 0, -side * 20.0), 5)


## Katakomben unter dem Grabfeld: Schädelnischen, Särge, Spinnweben, Kerzen und grünes Geisterlicht.
## Im Treppenschacht hilft eine Steinstufe beim Hochspringen, an den Enden schließen Erdwände den Gang.
func _catacombs(col: Node3D, stone: Material, dark: Material, earth: Material, glow: Material) -> void:
	MapLook.solid(col, Vector3(CATA_HALF * 2.0 + 1.2, 1.6, 4), Vector3(0, CATA_Y - 0.8, 0))
	MapLook.box(self, Vector3(CATA_HALF * 2.0 + 1.4, 1.7, 4.2), Vector3(0, CATA_Y - 0.85, 0), earth)
	MapLook.box(self, Vector3(CATA_HALF * 2.0 + 1.2, 0.12, 4.0), Vector3(0, CATA_Y - 0.06, 0), dark)
	MapLook.box(self, Vector3(12.0, 2.5, 3.2), Vector3(0, CATA_Y - 2.6, 0), earth)
	var h := -1.4 - CATA_Y
	for side in [-1, 1]:
		MapLook.solid(col, Vector3(0.6, h, 4), Vector3(side * (CATA_HALF + 0.3), CATA_Y + h / 2.0, 0))
		MapLook.box(self, Vector3(0.7, h, 4.2), Vector3(side * (CATA_HALF + 0.3), CATA_Y + h / 2.0, 0), dark)
	MapLook.box(self, Vector3(CATA_HALF * 2.0, h, 0.4), Vector3(0, CATA_Y + h / 2.0, -2.0), MapLook.mat(Color(0.22, 0.2, 0.24)))
	# Schädelnischen an der Rückwand.
	var bone := MapLook.mat(Color(0.85, 0.82, 0.72), 0.8)
	for i in 6:
		var x := -7.5 + i * 3.0
		if absf(x) < 1.5:
			continue
		MapLook.box(self, Vector3(2.0, 1.0, 0.1), Vector3(x, CATA_Y + 2.2, -1.75), MapLook.mat(Color(0.08, 0.07, 0.09)))
		for k in 4:
			MapLook.sphere(self, 0.16, Vector3(x - 0.6 + k * 0.4, CATA_Y + 2.0, -1.65), bone, Vector3(1.0, 0.9, 0.9))
		MapLook.box(self, Vector3(2.0, 0.06, 0.1), Vector3(x, CATA_Y + 1.6, -1.65), bone)
	# Särge, Kerzen und grünes Geisterlicht.
	var coffin := MapFX.surface("holz", Color(0.3, 0.2, 0.14))
	for x in [-5.5, 5.0]:
		MapLook.box(self, Vector3(1.8, 0.5, 0.7), Vector3(x, CATA_Y + 0.25, -1.3), coffin)
		MapLook.box(self, Vector3(0.08, 0.06, 0.5), Vector3(x - 0.3, CATA_Y + 0.52, -1.3), MapLook.mat(Color(0.8, 0.7, 0.4), 0.4, 0.7))
	for x in [-8.0, -2.5, 2.5, 8.0]:
		MapLook.cylinder(self, 0.05, 0.3, Vector3(x, CATA_Y + 0.15, -1.5), MapLook.mat(Color(0.95, 0.92, 0.8)), -1.0, Vector3.ZERO, 6)
		MapLook.sphere(self, 0.06, Vector3(x, CATA_Y + 0.36, -1.5), MapLook.mat(Color(1, 0.8, 0.4), 0.5, 0.0, 3.0))
		MapLook.light(self, Vector3(x, CATA_Y + 0.8, -0.8), Color(1.0, 0.75, 0.4), 0.7, 3.5)
	MapLook.light(self, Vector3(0, CATA_Y + 1.5, 1.0), Color(0.4, 1.0, 0.6), 0.8, 9.0)
	MapLook.particles(self, Vector3(0, CATA_Y + 1.2, -0.5), Vector3(8, 1.0, 1.0), Color(0.5, 1.0, 0.6, 0.6), 20,
		Vector3(0.2, 0.15, 0), 0.08, 5.0)
	# Steinstufe im Treppenschacht.
	var step := Vector3(0, -2.4, 0)
	MapLook.platform(col, Vector3(SHAFT * 2.0 - 0.2, 0.3, 1.8), step)
	MapLook.box(self, Vector3(SHAFT * 2.0 - 0.1, 0.3, 1.8), step, stone)
	for k in 3:
		MapLook.box(self, Vector3(SHAFT * 2.0, 0.25, 0.6), Vector3(0, CATA_Y + 0.6 + k * 1.1, -1.4 + k * 0.15), dark)
	MapLook.box(self, Vector3(0.5, 1.0, 0.06), Vector3(0, CATA_Y + 0.5, -1.78), glow)
