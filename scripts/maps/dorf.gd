extends Node3D
## Dorf: die rechte Wiesen-Insel schwebt höher, dazu ein Marktstand in der Mitte, auf dessen
## Dach man springen kann.

const RIGHT_ISLAND_SHIFT := Vector3(0.4, 1.35, 0)


func _ready() -> void:
	for path in ["RightPlatform", "Platforms/hex_grass3", "Platforms/hex_grass4", "Platforms/mountain_B_grass2"]:
		get_node(path).position += RIGHT_ISLAND_SHIFT

	var col := Node3D.new()
	add_child(col)
	var wood := MapLook.mat(Color(0.5, 0.33, 0.18))
	var red := MapLook.mat(Color(0.82, 0.18, 0.15))
	var white := MapLook.mat(Color(0.95, 0.93, 0.88))
	var green := MapLook.mat(Color(0.35, 0.6, 0.25))
	var orange := MapLook.mat(Color(0.95, 0.55, 0.15))

	# Marktstand: vier Pfosten, Theke hinten und ein gestreiftes Dach als Plattform.
	var roof := Vector3(0.6, 2.0, 0)
	MapLook.platform(col, Vector3(2.8, 0.3, 2.4), roof)
	for x in [-1.25, 1.25]:
		for z in [-1.0, 1.0]:
			MapLook.box(self, Vector3(0.14, 2.0, 0.14), Vector3(roof.x + x, 1.0, z), wood)
	for i in 6:
		MapLook.box(self, Vector3(0.5, 0.18, 2.6), Vector3(roof.x - 1.25 + i * 0.5, roof.y + 0.02, 0), red if i % 2 == 0 else white)
	MapLook.box(self, Vector3(2.6, 0.8, 0.5), Vector3(roof.x, 0.4, -0.9), wood)
	for i in 4:
		MapLook.sphere(self, 0.13, Vector3(roof.x - 0.9 + i * 0.55, 0.92, -0.9), orange if i % 2 else green)
	MapFX.cloth(self, Vector2(0.8, 0.5), Vector3(roof.x + 1.7, 2.6, -1.0), Color(0.2, 0.45, 0.85), null, false, 0.2)
	MapLook.cylinder(self, 0.03, 1.4, Vector3(roof.x + 1.3, 2.2, -1.0), wood)

	# Stimmung: sonnig, Schmetterlinge, Vögel, fallende Blüten.
	var fx := MapFX.attach(self)
	fx.flock(Vector3(0, 10.0, -8.0), 5, Color(0.2, 0.2, 0.25), Vector3(14, 1.0, 5), 0.25, 0.4)
	fx.flock(Vector3(0, 1.6, 0.8), 4, Color(1.0, 0.85, 0.2), Vector3(5, 0.6, 1.0), 0.6, 0.18)
	MapLook.particles(self, Vector3(0, 9.0, 0), Vector3(16, 1, 4), Color(1.0, 0.75, 0.85, 0.95), 40,
		Vector3(0.8, -0.7, 0), 0.1, 12.0)
	MapFX.mood(self, Color(0.82, 0.9, 1.0), 0.004, 0.3, 1.18, 1.05)

	# Vordergrund: Blätter in den oberen Ecken.
	var fg := MapFX.foreground(self)
	var leaves := MapLook.mat(Color(0.2, 0.42, 0.18))
	for side in [-1, 1]:
		MapLook.sphere(fg, 0.35, Vector3(side * 2.11, 1.22, -3.0), leaves, Vector3(1.5, 0.8, 0.6))
		MapLook.sphere(fg, 0.25, Vector3(side * 1.72, 1.26, -3.0), leaves, Vector3(1.4, 0.7, 0.6))
