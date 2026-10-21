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
