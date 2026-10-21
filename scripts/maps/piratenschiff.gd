extends Node3D
## Piratenschiff: langes Deck mit erhöhtem Achterdeck (rechts), Wanten am Bug (links),
## einer Rah am hinteren Mast und dem Ausguck hoch oben am Hauptmast. Bei Seegang schaukelt "Schiff".

const MAIN_MAST := -3.2
const AFT_MAST := 3.6


func _ready() -> void:
	var col: Node3D = $Collision
	var ship := Node3D.new()
	ship.name = "Schiff"
	$StageLook.add_child(ship)
	var bg: Node3D = $Background
	var deck := MapLook.mat(Color(0.62, 0.42, 0.24))
	var plank_line := MapLook.mat(Color(0.35, 0.22, 0.12))
	var hull := MapLook.mat(Color(0.32, 0.19, 0.1))
	var hull_dark := MapLook.mat(Color(0.2, 0.12, 0.07))
	var sail := MapLook.mat(Color(0.95, 0.92, 0.82))
	var red := MapLook.mat(Color(0.8, 0.12, 0.1))
	var rope := MapLook.mat(Color(0.75, 0.65, 0.45))
	var iron := MapLook.mat(Color(0.15, 0.15, 0.17), 0.4, 0.6)
	var sea := MapLook.mat(Color(0.08, 0.32, 0.5), 0.15, 0.2)
	$Spawn1.position = Vector3(-4.5, 0.2, 0)
	$Spawn2.position = Vector3(2.0, 0.2, 0)

	# Deck: 18 breit, rechts das erhöhte Achterdeck (fest, 1,2 hoch).
	MapLook.solid(col, Vector3(18, 2.2, 4), Vector3(0, -1.1, 0))
	MapLook.solid(col, Vector3(3.6, 1.2, 4), Vector3(7.2, 0.6, 0))
	MapLook.box(ship, Vector3(18.4, 0.3, 4.2), Vector3(0, -0.15, 0), deck)
	MapLook.box(ship, Vector3(3.8, 1.2, 4.2), Vector3(7.2, 0.6, 0), hull)
	MapLook.box(ship, Vector3(3.8, 0.12, 4.2), Vector3(7.2, 1.15, 0), deck)
	for i in 7:
		MapLook.box(ship, Vector3(18.4, 0.02, 0.05), Vector3(0, 0.005, -1.8 + i * 0.6), plank_line)
	MapLook.box(ship, Vector3(18.8, 2.2, 4.6), Vector3(0, -1.4, 0), hull)
	MapLook.box(ship, Vector3(16.6, 1.4, 3.6), Vector3(0, -3.1, 0), hull_dark)
	MapLook.box(ship, Vector3(19.0, 0.18, 4.7), Vector3(0, -1.0, 0), red)
	MapLook.box(ship, Vector3(3.2, 1.8, 4.4), Vector3(-10.5, -0.5, 0), hull, Vector3(0, 0, 22.0))
	MapLook.box(ship, Vector3(1.4, 0.9, 4.4), Vector3(-11.8, 0.9, 0), deck)
	MapLook.box(ship, Vector3(1.2, 3.0, 4.6), Vector3(9.6, 0.0, 0), hull)
	MapLook.cylinder(ship, 0.1, 4.5, Vector3(-12.8, 1.6, 0), hull, -1.0, Vector3(0, 0, 70))

	# Reling hinten (vorne nicht, damit sie die Kämpfer nicht verdeckt).
	for i in 14:
		MapLook.box(ship, Vector3(0.12, 0.8, 0.12), Vector3(-8.6 + i * 1.0, 0.4, -2.0), hull)
	MapLook.box(ship, Vector3(14.0, 0.12, 0.18), Vector3(-2.0, 0.82, -2.0), hull)

	# Hauptmast mit Ausguck, hinterer Mast mit Rah, Segel und Flaggen.
	MapLook.cylinder(ship, 0.25, 15.0, Vector3(MAIN_MAST, 7.5, -0.4), hull)
	MapLook.cylinder(ship, 0.22, 12.0, Vector3(AFT_MAST, 6.0, -0.4), hull)
	MapLook.box(ship, Vector3(5.4, 3.4, 0.12), Vector3(MAIN_MAST, 10.6, -0.9), sail)
	MapLook.box(ship, Vector3(4.6, 3.0, 0.12), Vector3(AFT_MAST, 7.0, -0.9), sail)
	MapLook.box(ship, Vector3(1.2, 0.6, 0.05), Vector3(MAIN_MAST + 0.7, 15.2, -0.4), red)
	MapLook.box(ship, Vector3(1.0, 0.5, 0.05), Vector3(AFT_MAST + 0.6, 12.2, -0.4), red)
	for b in [-7.4, -6.6, 5.0]:
		MapLook.cylinder(ship, 0.4, 0.9, Vector3(b, 0.45, -1.3), hull)
	for c in [-0.6, 1.8]:
		MapLook.cylinder(ship, 0.22, 1.4, Vector3(c, 0.35, -1.5), iron, -1.0, Vector3(90, 0, 0))

	# Plattformen.
	# Wanten am Bug (links, niedrig).
	MapLook.platform(col, Vector3(2.6, 0.3, 2.4), Vector3(-7.0, 2.6, 0))
	MapLook.box(ship, Vector3(2.7, 0.25, 2.5), Vector3(-7.0, 2.6, 0), deck)
	for x in [-8.2, -5.8]:
		MapLook.cylinder(ship, 0.03, 6.0, Vector3(x, 4.0, -0.4), rope, -1.0, Vector3(0, 0, 0))
	MapLook.cylinder(ship, 0.04, 7.5, Vector3(-5.4, 6.2, -0.4), rope, -1.0, Vector3(0, 0, 38))
	# Rah am hinteren Mast (mittelhoch).
	MapLook.platform(col, Vector3(3.4, 0.3, 2.4), Vector3(AFT_MAST, 3.4, 0))
	MapLook.cylinder(ship, 0.18, 3.6, Vector3(AFT_MAST, 3.35, 0), hull, -1.0, Vector3(0, 0, 90))
	MapLook.box(ship, Vector3(3.4, 0.12, 1.2), Vector3(AFT_MAST, 3.5, 0), deck)
	# Ausguck hoch oben am Hauptmast.
	MapLook.platform(col, Vector3(2.4, 0.3, 2.4), Vector3(MAIN_MAST, 6.2, 0))
	MapLook.cylinder(ship, 1.25, 0.6, Vector3(MAIN_MAST, 6.05, 0), deck, -1.0, Vector3.ZERO, 16)
	MapLook.cylinder(ship, 1.3, 0.12, Vector3(MAIN_MAST, 6.38, 0), hull, -1.0, Vector3.ZERO, 16)
	MapLook.cylinder(ship, 0.04, 6.5, Vector3(MAIN_MAST - 1.6, 3.0, -0.4), rope, -1.0, Vector3(0, 0, -14))
	MapLook.cylinder(ship, 0.04, 6.5, Vector3(MAIN_MAST + 1.6, 3.0, -0.4), rope, -1.0, Vector3(0, 0, 14))

	# Meer mit Gischt.
	MapLook.box(bg, Vector3(300, 0.5, 110), Vector3(0, -3.8, 0), sea)
	MapLook.particles(self, Vector3(0, -3.3, 3.0), Vector3(14, 0.2, 1), Color(1, 1, 1, 0.7), 50,
		Vector3(0, 1.5, 0), 0.15, 1.5, Vector3(0, -2, 0))
	MapLook.backdrop(bg, "res://assets/maps/piratenschiff/hintergrund.png")
