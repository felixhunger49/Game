class_name Projectile
extends Node3D
## Ein leuchtender Feuerball (oder die Frostkugel der Hexe), der geradeaus fliegt und den Gegner trifft.

const SPEED := 14.0
const LIFETIME := 1.6
const HIT_RADIUS := 1.1

var shooter: CharacterBody3D
var attack: Dictionary
var direction := 1
var age := 0.0
## Frostkugel: friert den Gegner beim Treffer ein.
var frost := false
const FROST_COLOR := Color(0.55, 0.85, 1.0)
const FREEZE_TIME := 1.8
## Schweinezauber: grüne Kugel, verwandelt den Gegner in ein Schwein.
var pig := false
const PIG_COLOR := Color(0.45, 1.0, 0.4)


func launch(from: CharacterBody3D, atk: Dictionary, start: Vector3, dir: int, is_frost := false, is_pig := false) -> void:
	shooter = from
	attack = atk
	direction = dir
	frost = is_frost
	pig = is_pig
	global_position = start
	var color: Color = FROST_COLOR if frost else PIG_COLOR if pig else from.color

	# Heller Kern
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.64
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.lightened(0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 4.0
	mesh.material_override = mat
	add_child(mesh)
	# Leuchtende Hülle
	var glow := MeshInstance3D.new()
	var outer := SphereMesh.new()
	outer.radius = 0.6
	outer.height = 1.2
	glow.mesh = outer
	glow.material_override = SpecialFX._glow_material(Color(color, 0.45), 2.5)
	add_child(glow)
	SpecialFX.fire_trail(self, color)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 4.0
	light.omni_range = 5.0
	add_child(light)


func _physics_process(delta: float) -> void:
	age += delta
	position.x += direction * SPEED * delta
	scale = Vector3.ONE * (1.0 + 0.15 * sin(age * 30.0))
	rotation.z += 12.0 * delta
	if Target.hit_near(self, global_position, HIT_RADIUS + 0.3):
		queue_free()
		return
	var target: CharacterBody3D = shooter.nearest_enemy_to(global_position) if shooter else null
	if target and target.visible:
		var chest := target.global_position + Vector3(0, 0.9, 0)
		if chest.distance_to(global_position) < HIT_RADIUS:
			if target.take_hit(attack, Vector3(attack.angle.x * direction, attack.angle.y, 0).normalized(),
					shooter.power_time > 0.0, shooter.outgoing_multiplier()):
				shooter.add_special_energy(attack.damage * shooter.SPECIAL_PER_DAMAGE_DEALT)
				shooter.on_hit_landed(target)
				SpecialFX.impact(shooter, global_position, FROST_COLOR if frost else shooter.color)
				if frost:
					target.freeze(FREEZE_TIME)
				if pig:
					target.pigify(target.PIG_TIME)
			queue_free()
			return
	if age > LIFETIME:
		queue_free()
