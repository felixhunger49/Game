class_name ArrowShot
extends Node3D
## Pfeil der Jägerin (starker Angriff): fliegt schnell geradeaus in einem leichten Bogen und trifft den Gegner.

const SPEED := 22.0
const LIFETIME := 0.9
const HIT_RADIUS := 0.8
const DROP := 3.0

var shooter: CharacterBody3D
var attack: Dictionary
var direction := 1
var age := 0.0
var vertical := 0.6


func launch(from: CharacterBody3D, atk: Dictionary, start: Vector3, dir: int) -> void:
	shooter = from
	attack = atk
	direction = dir
	global_position = start
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.38, 0.2)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.8, 0.82, 0.85)
	steel.metallic = 0.8
	steel.roughness = 0.3
	var shaft := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = 0.025
	rod.bottom_radius = 0.025
	rod.height = 1.0
	shaft.mesh = rod
	shaft.material_override = wood
	shaft.rotation.z = PI / 2
	add_child(shaft)
	var tip := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.07
	cone.height = 0.2
	tip.mesh = cone
	tip.material_override = steel
	tip.rotation.z = -PI / 2
	tip.position.x = 0.58
	add_child(tip)
	for side in [-1, 1]:
		var feather := MeshInstance3D.new()
		var vane := BoxMesh.new()
		vane.size = Vector3(0.22, 0.1, 0.01)
		feather.mesh = vane
		feather.material_override = SpecialFX._glow_material(Color(from.color, 0.9), 1.0)
		feather.position = Vector3(-0.42, side * 0.05, 0)
		add_child(feather)
	# Leuchtende Spur hinter dem Pfeil.
	var trail := MeshInstance3D.new()
	var streak := BoxMesh.new()
	streak.size = Vector3(1.2, 0.04, 0.04)
	trail.mesh = streak
	trail.material_override = SpecialFX._glow_material(Color(1, 1, 1, 0.35), 1.5)
	trail.position.x = -1.0
	add_child(trail)
	scale.x = dir
	Audio.sfx("swing_weak", 1.6)


func _physics_process(delta: float) -> void:
	age += delta
	vertical -= DROP * delta
	position += Vector3(direction * SPEED, vertical, 0) * delta
	rotation.z = atan2(vertical, SPEED) * direction
	if Target.hit_near(self, global_position, HIT_RADIUS + 0.3):
		queue_free()
		return
	var target: CharacterBody3D = shooter.nearest_enemy_to(global_position) if shooter else null
	if target and target.visible:
		var body := target.global_position + Vector3(0, 0.9, 0)
		if absf(body.x - global_position.x) < HIT_RADIUS and absf(body.y - global_position.y) < 1.1:
			if target.take_hit(attack, Vector3(attack.angle.x * direction, attack.angle.y, 0).normalized(),
					shooter.power_time > 0.0, shooter.outgoing_multiplier()):
				shooter.add_special_energy(attack.damage * shooter.SPECIAL_PER_DAMAGE_DEALT)
				shooter.on_hit_landed(target)
				SpecialFX.impact(shooter, global_position, shooter.color)
			queue_free()
			return
	if age > LIFETIME:
		queue_free()
