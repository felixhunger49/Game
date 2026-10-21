extends Node3D
## Friedhof: die Grabplatten liegen weiter außen und tiefer, dazu eine Gruft in der Mitte
## (das Dach ist eine Plattform) und ein toter Baum rechts mit einem hohen Ast.

const LEFT_SHIFT := Vector3(-1.1, -0.45, 0)
const RIGHT_SHIFT := Vector3(1.1, -0.45, 0)


func _ready() -> void:
	for path in ["LeftPlatform", "Platforms/Slab", "Platforms/candle_triple", "Lights/Light"]:
		get_node(path).position += LEFT_SHIFT
	for path in ["RightPlatform", "Platforms/Slab2", "Platforms/candle_triple2", "Lights/Light2"]:
		get_node(path).position += RIGHT_SHIFT

	var col := Node3D.new()
	add_child(col)
	var stone := MapLook.mat(Color(0.45, 0.45, 0.52))
	var stone_dark := MapLook.mat(Color(0.3, 0.3, 0.36))
	var bark := MapLook.mat(Color(0.28, 0.22, 0.2))
	var glow := MapLook.mat(Color(0.6, 0.4, 1.0), 0.5, 0.0, 2.0)

	# Gruft in der Mitte: Dach als Plattform, leuchtende Tür.
	var roof := Vector3(0, 3.2, 0)
	MapLook.platform(col, Vector3(3.0, 0.3, 2.4), roof)
	MapLook.box(self, Vector3(2.6, 3.0, 1.4), Vector3(0, 1.5, -1.5), stone)
	MapLook.box(self, Vector3(3.3, 0.35, 2.6), roof + Vector3(0, -0.02, 0), stone_dark)
	MapLook.box(self, Vector3(2.4, 0.5, 0.6), roof + Vector3(0, 0.4, -1.2), stone_dark, Vector3(0, 0, 0))
	MapLook.box(self, Vector3(0.9, 1.5, 0.06), Vector3(0, 0.75, -0.78), glow)
	MapLook.light(self, Vector3(0, 1.2, 0.2), Color(0.6, 0.4, 1.0), 1.2, 4.0)

	# Toter Baum rechts hinten, sein Ast ist eine hohe Plattform.
	var branch := Vector3(5.4, 4.7, 0)
	MapLook.platform(col, Vector3(2.2, 0.3, 2.0), branch)
	MapLook.cylinder(self, 0.32, 5.6, Vector3(7.0, 2.8, -1.0), bark, 0.22, Vector3.ZERO, 8)
	MapLook.cylinder(self, 0.18, 2.6, branch + Vector3(0.3, -0.05, 0), bark, 0.12, Vector3(0, 0, 90), 8)
	MapLook.box(self, Vector3(2.2, 0.16, 1.0), branch + Vector3(0, 0.06, 0), bark)
	MapLook.cylinder(self, 0.08, 1.4, Vector3(6.6, 6.2, -1.0), bark, 0.02, Vector3(0, 0, 35), 6)
	MapLook.cylinder(self, 0.08, 1.2, Vector3(7.3, 6.0, -1.0), bark, 0.02, Vector3(0, 0, -30), 6)
