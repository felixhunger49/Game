class_name ArrowRain
extends Node3D
## Pfeilregen der Jägerin: Erst leuchtet am Boden ein Kreis, dann regnen Pfeile darauf herab.

const WARN_TIME := 0.45
const ARROWS := 6
const SPREAD := 1.6
const FALL_SPEED := 26.0
const HIT_RADIUS := 0.7
const ATTACK := {"damage": 4.0, "base": 2.5, "scale": 0.08, "angle": Vector2(0.4, -0.2)}

var shooter: CharacterBody3D
var target_x := 0.0
var ground_y := 0.0
var age := 0.0
var arrows: Array[Node3D] = []
var hit_count := 0
var marker: MeshInstance3D


func launch(from: CharacterBody3D, x: float, y: float) -> void:
	shooter = from
	target_x = x
	ground_y = y
	marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = SPREAD
	disc.bottom_radius = SPREAD
	disc.height = 0.04
	marker.mesh = disc
	marker.material_override = SpecialFX._glow_material(Color(from.color, 0.5), 2.0)
	add_child(marker)
	global_position = Vector3(x, y + 0.05, 0)
	Audio.sfx("warning", 1.4, -6.0)


func _physics_process(delta: float) -> void:
	age += delta
	if age < WARN_TIME:
		marker.scale = Vector3.ONE * (0.6 + 0.4 * age / WARN_TIME)
		return
	if arrows.is_empty() and hit_count >= 0:
		_spawn_arrows()
		marker.queue_free()
	var target: CharacterBody3D = shooter.opponent
	for arrow in arrows.duplicate():
		arrow.global_position.y -= FALL_SPEED * delta
		if target and target.visible:
			var chest := target.global_position + Vector3(0, 0.9, 0)
			if chest.distance_to(arrow.global_position) < HIT_RADIUS + 0.4:
				var side := 1.0 if target.global_position.x >= arrow.global_position.x else -1.0
				if target.take_hit(ATTACK, Vector3(ATTACK.angle.x * side, ATTACK.angle.y, 0).normalized(),
						shooter.power_time > 0.0, shooter.outgoing_multiplier()):
					shooter.add_special_energy(ATTACK.damage * shooter.SPECIAL_PER_DAMAGE_DEALT)
					hit_count += 1
					if hit_count == 1:
						SpecialFX.impact(shooter, chest, shooter.color)
				arrows.erase(arrow)
				arrow.queue_free()
				continue
		if arrow.global_position.y < ground_y:
			SpecialFX._sparks(get_parent(), arrow.global_position, shooter.color, 8, 4.0, 0.3)
			arrows.erase(arrow)
			arrow.queue_free()
	if arrows.is_empty() and age > WARN_TIME + 0.1:
		queue_free()


func _spawn_arrows() -> void:
	Audio.sfx("swing_strong", 1.5)
	for i in ARROWS:
		var arrow := MeshInstance3D.new()
		var shaft := CylinderMesh.new()
		shaft.top_radius = 0.03
		shaft.bottom_radius = 0.07
		shaft.height = 1.0
		arrow.mesh = shaft
		arrow.material_override = SpecialFX._glow_material(Color(shooter.color, 0.95), 3.0)
		add_child(arrow)
		var x := target_x + lerpf(-SPREAD, SPREAD, float(i) / (ARROWS - 1)) + randf_range(-0.2, 0.2)
		# Gestaffelt, damit es wie ein Regen aussieht.
		arrow.global_position = Vector3(x, ground_y + 9.0 + i * 0.8, 0)
		arrows.append(arrow)
