class_name FernSchuss
extends Node3D
## Geschoss der Fernkämpfer beim starken Angriff (auch hoch/tief und aufgeladen):
## "pfeil" = Pfeil der Jägerin (schnell, fällt leicht ab),
## "arkan" = Arkanblitz der Magierin (gerade, voll aufgeladen fliegt er durch alle Gegner hindurch),
## "fluch" = Fluchkugel der Hexe (langsamer, schlingert und lenkt etwas zum Gegner hin).
## Je länger aufgeladen (ladung 0..1), desto schneller, größer und stärker.

const STYLES := {
	"pfeil": {"speed": 22.0, "lifetime": 0.9, "radius": 0.8, "drop": 3.0, "color": Color(1, 1, 1)},
	"arkan": {"speed": 17.0, "lifetime": 1.1, "radius": 0.9, "drop": 0.0, "color": Color(0.7, 0.45, 1.0)},
	"fluch": {"speed": 11.0, "lifetime": 1.8, "radius": 1.0, "drop": 0.0, "color": Color(0.45, 1.0, 0.35)},
}
## Wie stark die Fluchkugel zum Gegner hin lenkt (Grad pro Sekunde).
const HOMING := 70.0
## Ab dieser Ladung fliegt der Arkanblitz durch Gegner hindurch.
const PIERCE_CHARGE := 0.9

var shooter: CharacterBody3D
var attack: Dictionary
var style := "pfeil"
var velocity := Vector3.ZERO
var age := 0.0
var lifetime := 1.0
var radius := 1.0
var drop := 0.0
var color := Color.WHITE
var pierce := false
## Schon getroffene Gegner (der Arkanblitz trifft jeden nur einmal).
var hit_already: Array = []
var body: Node3D


## dir = Flugrichtung (z. B. (1, 0) nach vorne, (0.5, 1) schräg nach oben), facing = Blickrichtung des Schützen.
func launch(from: CharacterBody3D, atk: Dictionary, start: Vector3, dir: Vector2, kind: String, ladung: float) -> void:
	shooter = from
	attack = atk
	style = kind
	var s: Dictionary = STYLES[kind]
	var speed: float = s.speed * (1.0 + 0.5 * ladung)
	velocity = Vector3(dir.x, dir.y, 0).normalized() * speed
	lifetime = s.lifetime * (1.0 + 0.3 * ladung)
	radius = s.radius * (1.0 + 0.3 * ladung)
	drop = s.drop
	color = from.color if kind == "pfeil" else s.color
	pierce = kind == "arkan" and ladung >= PIERCE_CHARGE
	global_position = start
	body = Node3D.new()
	add_child(body)
	match kind:
		"pfeil": _build_arrow(from.color)
		"arkan": _build_bolt()
		"fluch": _build_curse()
	body.scale = Vector3.ONE * (1.0 + 0.4 * ladung)
	_face()
	match kind:
		"pfeil": Audio.sfx("swing_weak", 1.6)
		"arkan": Audio.sfx("laser", 1.5, -4.0)
		"fluch": Audio.sfx("ghost", 1.3, -3.0)


func _build_arrow(feather_color: Color) -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.38, 0.2)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.8, 0.82, 0.85)
	steel.metallic = 0.8
	steel.roughness = 0.3
	var rod := CylinderMesh.new()
	rod.top_radius = 0.025
	rod.bottom_radius = 0.025
	rod.height = 1.0
	_part(rod, wood, Vector3.ZERO, PI / 2)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.07
	cone.height = 0.2
	_part(cone, steel, Vector3(0.58, 0, 0), -PI / 2)
	for side in [-1, 1]:
		var vane := BoxMesh.new()
		vane.size = Vector3(0.22, 0.1, 0.01)
		_part(vane, SpecialFX._glow_material(Color(feather_color, 0.9), 1.0), Vector3(-0.42, side * 0.05, 0))
	# Leuchtende Spur hinter dem Pfeil.
	var streak := BoxMesh.new()
	streak.size = Vector3(1.2, 0.04, 0.04)
	_part(streak, SpecialFX._glow_material(Color(1, 1, 1, 0.35), 1.5), Vector3(-1.0, 0, 0))


## Arkanblitz: langgezogener violetter Lichtspeer mit hellem Kern und Funkenspur.
func _build_bolt() -> void:
	var core := CapsuleMesh.new()
	core.radius = 0.1
	core.height = 0.9
	var hot := StandardMaterial3D.new()
	hot.albedo_color = Color(0.95, 0.9, 1.0)
	hot.emission_enabled = true
	hot.emission = color
	hot.emission_energy_multiplier = 5.0
	_part(core, hot, Vector3.ZERO, PI / 2)
	var shell := CapsuleMesh.new()
	shell.radius = 0.25
	shell.height = 1.4
	_part(shell, SpecialFX._glow_material(Color(color, 0.45), 2.5), Vector3(-0.15, 0, 0), PI / 2)
	var streak := BoxMesh.new()
	streak.size = Vector3(1.6, 0.08, 0.08)
	_part(streak, SpecialFX._glow_material(Color(color, 0.35), 2.0), Vector3(-1.2, 0, 0))
	SpecialFX.fire_trail(self, color)
	_light(3.5)


## Fluchkugel: dunkler Kern in grünem Schein, umkreist von kleinen Funken.
func _build_curse() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.05, 0.18)
	dark.emission_enabled = true
	dark.emission = Color(0.4, 0.1, 0.5)
	dark.emission_energy_multiplier = 1.5
	var core := SphereMesh.new()
	core.radius = 0.22
	core.height = 0.44
	_part(core, dark, Vector3.ZERO)
	var glow := SphereMesh.new()
	glow.radius = 0.5
	glow.height = 1.0
	_part(glow, SpecialFX._glow_material(Color(color, 0.4), 2.5), Vector3.ZERO)
	for i in 3:
		var orb := SphereMesh.new()
		orb.radius = 0.08
		orb.height = 0.16
		var a := TAU * i / 3.0
		_part(orb, SpecialFX._glow_material(Color(0.8, 0.4, 1.0, 0.9), 3.0), Vector3(cos(a), sin(a), 0) * 0.55)
	SpecialFX.fire_trail(self, color)
	_light(3.0)


func _part(mesh: Mesh, mat: Material, pos: Vector3, rot_z := 0.0) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	m.rotation.z = rot_z
	body.add_child(m)


func _light(energy: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 4.5
	add_child(light)


## Das Geschoss zeigt immer in Flugrichtung.
func _face() -> void:
	body.rotation.z = atan2(velocity.y, velocity.x)


func _physics_process(delta: float) -> void:
	age += delta
	velocity.y -= drop * delta
	if style == "fluch":
		_steer(delta)
		# Kreisende Funken drehen sich.
		for i in range(3, body.get_child_count()):
			var a := TAU * (i - 3) / 3.0 + age * 8.0
			body.get_child(i).position = Vector3(cos(a), sin(a), 0) * 0.55
	position += velocity * delta
	if style == "fluch":
		position.y += sin(age * 9.0) * 1.2 * delta
	_face()
	if Target.hit_near(self, global_position, radius + 0.3):
		queue_free()
		return
	if shooter and _check_hits():
		queue_free()
		return
	if age > lifetime:
		if style != "pfeil":
			SpecialFX._sparks(get_parent(), global_position, color, 14, 3.0, 0.3)
		queue_free()


## Fluchkugel: dreht langsam zum nächsten Gegner hin.
func _steer(delta: float) -> void:
	var target: CharacterBody3D = shooter.nearest_enemy_to(global_position) if shooter else null
	if not target or not target.visible:
		return
	var to := target.global_position + Vector3(0, 0.9, 0) - global_position
	# Nur lenken, wenn der Gegner vorne liegt (nicht umdrehen).
	if to.x * velocity.x <= 0.0:
		return
	var want := atan2(to.y, to.x)
	var now := atan2(velocity.y, velocity.x)
	var turn := clampf(wrapf(want - now, -PI, PI), -deg_to_rad(HOMING) * delta, deg_to_rad(HOMING) * delta)
	velocity = velocity.rotated(Vector3.BACK, turn)


## Trifft einen Gegner in der Nähe. Gibt true zurück, wenn das Geschoss danach verschwindet.
func _check_hits() -> bool:
	for target in shooter._enemies():
		if not target.visible or target in hit_already:
			continue
		var chest: Vector3 = target.global_position + Vector3(0, 0.9, 0)
		if absf(chest.x - global_position.x) > radius or absf(chest.y - global_position.y) > 1.1:
			continue
		hit_already.append(target)
		var side := signf(velocity.x) if absf(velocity.x) > 0.5 else float(shooter.facing)
		if target.take_hit(attack, Vector3(attack.angle.x * side, attack.angle.y, 0).normalized(),
				shooter.power_time > 0.0, shooter.outgoing_multiplier()):
			shooter.add_special_energy(attack.damage * shooter.SPECIAL_PER_DAMAGE_DEALT)
			shooter.on_hit_landed(target)
			SpecialFX.impact(shooter, global_position, color)
		if not pierce:
			return true
	return false
