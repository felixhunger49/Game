class_name SmashBall
extends Node3D
## Die Smash-Kugel: schwebt bunt leuchtend durch die Arena. Wer sie mit Schlägen oder Geschossen zerschlägt,
## kann mit der Spezial-Taste einmal den Final Smash auslösen (siehe Player.start_final_smash).
## Sie gehört zur Gruppe der Ziele, damit alle Angriffe sie treffen (Target.hit_melee / Target.hit_near).

## So viele Treffer hält die Kugel aus.
const HITS := 4
## Nach so vielen Sekunden fliegt sie davon, wenn niemand sie zerschlagen hat.
const LIFETIME := 22.0
const SPEED := 1.6
const RADIUS := 0.45

var area := Rect2(-8, 0, 16, 8)
var hits_left := HITS
var age := 0.0
var drift := Vector2(1, 0.6).normalized()
var hit_cooldown := 0.0
var core: MeshInstance3D
var glow: MeshInstance3D
var light: OmniLight3D


func setup(stage_area: Rect2) -> void:
	area = stage_area
	drift = Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)).normalized()


func _ready() -> void:
	add_to_group(Target.GROUP)
	core = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	core.mesh = sphere
	core.material_override = SpecialFX._glow_material(Color(1, 0.6, 0.2), 2.5)
	add_child(core)
	# Das Kreuz-Zeichen auf der Kugel, wie ein Wappen.
	for angle in [0.0, PI / 2.0]:
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.62, 0.12, 0.1)
		bar.mesh = box
		bar.material_override = SpecialFX._glow_material(Color(1, 1, 1), 3.0)
		bar.position.z = RADIUS * 0.9
		bar.rotation.z = angle
		core.add_child(bar)
	glow = MeshInstance3D.new()
	var halo := SphereMesh.new()
	halo.radius = RADIUS * 1.6
	halo.height = RADIUS * 3.2
	glow.mesh = halo
	glow.material_override = SpecialFX._glow_material(Color(1, 0.8, 0.3, 0.25), 1.5)
	add_child(glow)
	light = OmniLight3D.new()
	light.light_energy = 2.0
	light.omni_range = 4.0
	add_child(light)
	Audio.sfx("special_start", 0.8, -4.0)


func _process(delta: float) -> void:
	age += delta
	hit_cooldown = maxf(hit_cooldown - delta, 0.0)
	# Regenbogenfarben, die durchlaufen.
	var color := Color.from_hsv(fmod(age * 0.35, 1.0), 0.75, 1.0)
	core.material_override.albedo_color = color * 0.8
	light.light_color = color
	glow.scale = Vector3.ONE * (1.0 + 0.12 * sin(age * 6.0))
	core.rotation.y = sin(age * 1.5) * 0.6
	# Langsam durch die Arena treiben und am Rand umkehren; am Ende davonfliegen.
	if age > LIFETIME:
		position.y += 4.0 * delta
		if age > LIFETIME + 3.0:
			queue_free()
		return
	position.x += drift.x * SPEED * delta
	position.y += drift.y * SPEED * delta + sin(age * 2.0) * 0.4 * delta
	if position.x < area.position.x + 1.0 or position.x > area.end.x - 1.0:
		drift.x = -drift.x
		position.x = clampf(position.x, area.position.x + 1.0, area.end.x - 1.0)
	if position.y < area.position.y + 1.5 or position.y > area.end.y + 2.5:
		drift.y = -drift.y
		position.y = clampf(position.y, area.position.y + 1.5, area.end.y + 2.5)


## Ein Treffer von `player` (Schlag oder Geschoss). Der letzte Treffer zerschlägt die Kugel.
func hit_by(player: Node) -> void:
	if is_queued_for_deletion() or hit_cooldown > 0.0 or player == null or not player.has_method("gain_final_smash"):
		return
	hit_cooldown = 0.15
	hits_left -= 1
	var world := get_parent()
	SpecialFX._sparks(world, global_position, core.material_override.albedo_color, 20, 6.0, 0.4)
	Audio.sfx("hit_weak", 1.3)
	# Weggestoßen in Schlagrichtung, damit man ihr nachjagen muss.
	var away: float = signf(global_position.x - player.global_position.x)
	drift = Vector2(away if away != 0.0 else 1.0, randf_range(0.2, 0.8)).normalized()
	position.x += away * 0.6
	if hits_left > 0:
		return
	SpecialFX._flash_sphere(world, global_position, Color(1, 1, 1), 0.4, 2.5, 0.35)
	SpecialFX._sparks(world, global_position, Color(1, 0.9, 0.4), 70, 9.0, 0.7)
	SpecialFX._flash_light(world, global_position, Color(1, 0.9, 0.6), 10.0, 8.0, 0.5)
	Audio.sfx("special_hit")
	player.gain_final_smash()
	queue_free()


## Für Ziel-Treffer ohne Angreifer (sollte nicht vorkommen): nur ein Funke.
func pop() -> void:
	SpecialFX._sparks(get_parent(), global_position, Color(1, 0.9, 0.4), 10, 4.0, 0.3)
