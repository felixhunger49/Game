class_name Item
extends CharacterBody3D
## Ein Item, das vom Himmel fällt. Wer es berührt, bekommt seine Wirkung.

const TYPES := {
	"heiltrank": {"model": "res://assets/maps/burg/bottle_A_labeled_green.glb", "scale": 1.0,
		"label": "Heiltrank: -30 % Schaden"},
	"kraft": {"model": "res://assets/maps/burg/sword_shield_gold.glb", "scale": 0.45,
		"label": "Kraft: härter zuschlagen"},
	"tempo": {"model": "res://assets/maps/burg/coin_stack_small.glb", "scale": 0.9,
		"label": "Tempo: schneller laufen"},
	"bombe": {"model": "res://assets/kaykit/weapons/smokebomb.gltf", "scale": 1.8,
		"label": "Bombe: explodiert bei Berührung"},
}
const LIFETIME := 14.0
const PICKUP_RADIUS := 1.1
const BOMB_RADIUS := 2.6
const BOMB_ATTACK := {"damage": 15.0, "base": 7.0, "scale": 0.2, "angle": Vector2(1, 0.8)}

var type := "heiltrank"
var players: Array = []
var age := 0.0
var fuse := -1.0
var model: Node3D


func setup(item_type: String, all_players: Array) -> void:
	type = item_type
	players = all_players
	collision_layer = 0
	collision_mask = 3
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	shape.shape = sphere
	shape.position.y = 0.3
	add_child(shape)
	model = load(TYPES[type].model).instantiate()
	model.scale = Vector3.ONE * TYPES[type].scale
	add_child(model)
	var light := OmniLight3D.new()
	light.light_color = Color(1, 0.4, 0.2) if type == "bombe" else Color(1, 0.95, 0.6)
	light.light_energy = 1.5
	light.omni_range = 2.5
	light.position.y = 0.6
	add_child(light)


func _physics_process(delta: float) -> void:
	age += delta
	velocity.y -= 20.0 * delta
	move_and_slide()
	model.rotation.y += 2.0 * delta
	model.position.y = 0.15 + 0.1 * sin(age * 3.0) if is_on_floor() else 0.0

	if fuse >= 0.0:
		fuse -= delta
		model.scale = Vector3.ONE * TYPES[type].scale * (1.0 + 0.3 * absf(sin(age * 25.0)))
		if fuse <= 0.0:
			_explode()
		return

	# In den letzten Sekunden blinkt das Item, bevor es verschwindet.
	if age > LIFETIME - 3.0:
		model.visible = int(age * 8.0) % 2 == 0
	if age > LIFETIME or position.y < -12.0:
		queue_free()
		return

	for p in players:
		if p.visible and p.controls_enabled and (p.global_position + Vector3(0, 0.6, 0)).distance_to(global_position) < PICKUP_RADIUS:
			_pick_up(p)
			return


func _pick_up(player: CharacterBody3D) -> void:
	match type:
		"heiltrank":
			player.heal(30.0)
			Audio.sfx("pickup_heal")
		"kraft":
			player.give_power(10.0)
			Audio.sfx("pickup_power")
		"tempo":
			player.give_speed(10.0)
			Audio.sfx("pickup_speed")
		"bombe":
			fuse = 0.4
			Audio.sfx("fuse")
			return
	queue_free()


func _explode() -> void:
	Audio.sfx("explosion")
	for p in players:
		var offset: Vector3 = p.global_position - global_position
		if p.visible and offset.length() < BOMB_RADIUS:
			var side := 1.0 if offset.x >= 0.0 else -1.0
			p.take_hit(BOMB_ATTACK, Vector3(side, 0.8, 0).normalized())
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = BOMB_RADIUS
	sphere.height = BOMB_RADIUS * 2.0
	flash.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.6, 0.2, 0.6)
	flash.material_override = mat
	get_parent().add_child(flash)
	flash.global_position = global_position + Vector3(0, 0.5, 0)
	var tween := flash.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_callback(flash.queue_free)
	queue_free()
