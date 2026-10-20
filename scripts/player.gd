extends CharacterBody3D

## Wird ausgelöst, wenn die Figur aus der Arena gefallen ist.
signal fell_off(player)

## 1 oder 2: bestimmt, welche Tasten die Figur steuern (p1_... oder p2_...).
@export var player_id := 1
@export var color := Color(1, 0.82, 0.4)
@export var start_facing := 1
@export var speed := 7.0
@export var jump_velocity := 13.0
@export var gravity := 30.0
@export var max_jumps := 2

## Schaden pro Treffer in Prozent.
@export var attack_damage := 10.0
## Rückstoß bei 0 % Schaden und zusätzlicher Rückstoß pro Prozent Schaden.
@export var base_knockback := 5.0
@export var knockback_per_damage := 0.18

## Alles außerhalb dieses Bereichs zählt als heruntergefallen (x links, y unten, Breite, Höhe).
const BLAST_ZONE := Rect2(-17, -10, 34, 26)
const ATTACK_RANGE := Vector2(1.7, 1.3)
const ATTACK_COOLDOWN := 0.35
## Die Figuren drehen sich nicht ganz zur Seite, damit man ihr Gesicht sieht (wie bei Smash Bros.).
const SIDE_ANGLE := deg_to_rad(70)
## Physik-Ebene, auf der die schwebenden Plattformen liegen (man kann von unten durchspringen).
const PLATFORM_LAYER := 2

var opponent: CharacterBody3D
var fighter: Dictionary = {}
var controls_enabled := false
var damage := 0.0
var stocks := 3
var facing := 1
var jumps_left := 0
var hitstun := 0.0
var attack_timer := 0.0
var spawn_position := Vector3.ZERO
var anim_player: AnimationPlayer
var current_anim := ""

@onready var model_root: Node3D = $Model
@onready var tag: Label3D = $Tag


func _ready() -> void:
	spawn_position = position
	facing = start_facing
	jumps_left = max_jumps
	tag.text = "P%d" % player_id
	tag.modulate = color


## Tauscht das 3D-Modell gegen den Kämpfer an Stelle `index` im Roster.
func set_fighter(index: int) -> void:
	fighter = Roster.get_fighter(index)
	for child in model_root.get_children():
		model_root.remove_child(child)
		child.queue_free()
	current_anim = ""

	var model: Node3D = load(fighter.scene).instantiate()
	model_root.add_child(model)
	_setup_weapons(model)
	_apply_scale(model)

	anim_player = model.find_child("AnimationPlayer", true, false)
	if anim_player:
		for action in ["idle", "run", "jump"]:
			var anim_name := Roster.anim_name(fighter, action)
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_play("idle")


func _physics_process(delta: float) -> void:
	attack_timer = max(attack_timer - delta, 0.0)
	hitstun = max(hitstun - delta, 0.0)

	velocity.y -= gravity * delta
	# Von unten durch die schwebenden Plattformen springen, beim Fallen darauf landen.
	set_collision_mask_value(PLATFORM_LAYER, velocity.y <= 0.0)
	if is_on_floor():
		jumps_left = max_jumps

	if hitstun > 0.0:
		# Getroffen: keine Kontrolle, die Figur fliegt weiter.
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
	elif controls_enabled:
		_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 60.0 * delta)

	move_and_slide()
	_update_model(delta)

	if not BLAST_ZONE.has_point(Vector2(position.x, position.y)):
		_lose_stock()


func _handle_input(delta: float) -> void:
	var direction := Input.get_axis(_action("left"), _action("right"))
	var accel := 60.0 if is_on_floor() else 28.0
	velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	if direction != 0.0:
		facing = int(sign(direction))

	if Input.is_action_just_pressed(_action("jump")) and jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1

	if Input.is_action_just_pressed(_action("attack")) and attack_timer == 0.0:
		attack()


func attack() -> void:
	attack_timer = ATTACK_COOLDOWN
	_play("attack", 2.0)
	if opponent == null or not opponent.visible:
		return
	var offset := opponent.global_position - global_position
	var in_front: bool = signf(offset.x) == facing or absf(offset.x) < 0.2
	if in_front and absf(offset.x) <= ATTACK_RANGE.x and absf(offset.y) <= ATTACK_RANGE.y:
		opponent.take_hit(attack_damage, Vector3(facing, 0.6, 0).normalized())


## Je mehr Schaden die Figur schon hat, desto weiter fliegt sie.
func take_hit(amount: float, direction: Vector3) -> void:
	damage += amount
	velocity = direction * (base_knockback + damage * knockback_per_damage)
	hitstun = 0.15 + damage * 0.004
	_play("hit", 1.5)


func cheer() -> void:
	controls_enabled = false
	_play("cheer")


func _lose_stock() -> void:
	stocks -= 1
	damage = 0.0
	hitstun = 0.0
	velocity = Vector3.ZERO
	if stocks > 0:
		position = spawn_position + Vector3(0, 4, 0)
	else:
		visible = false
		set_physics_process(false)
	fell_off.emit(self)


func _update_model(delta: float) -> void:
	# Vor dem Kampf schauen die Figuren in die Kamera, im Kampf zum Gegner.
	var target_angle := facing * SIDE_ANGLE if controls_enabled or hitstun > 0.0 else 0.0
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, 15.0 * delta)

	if current_anim == "cheer":
		return
	if hitstun > 0.0:
		_play("hit", 1.5)
	elif current_anim == "attack" and attack_timer > 0.0:
		return
	elif not is_on_floor():
		_play("jump")
	elif absf(velocity.x) > 0.5:
		_play("run")
	else:
		_play("idle")


func _play(action: String, speed_scale := 1.0) -> void:
	if anim_player == null:
		return
	var anim_name := Roster.anim_name(fighter, action)
	if anim_name == "" or not anim_player.has_animation(anim_name):
		# Der Robo hat keine Schlag-Animation: dann kurz nach vorne stoßen.
		if action == "attack":
			_lunge()
		return
	if action == current_anim and action != "attack":
		return
	current_anim = action
	anim_player.play(anim_name, 0.1, speed_scale)


func _lunge() -> void:
	var tween := create_tween()
	tween.tween_property(model_root, "position:x", 0.4 * facing, 0.08)
	tween.tween_property(model_root, "position:x", 0.0, 0.15)


## Blendet alle Waffen aus, die nicht in "keep" stehen, und hängt "attach"-Waffen an die Hände.
func _setup_weapons(model: Node3D) -> void:
	var keep: Array = fighter.get("keep", [])
	for node in model.find_children("*", "MeshInstance3D", true, false):
		if node.get_parent() is BoneAttachment3D:
			node.visible = node.name in keep

	var attach: Dictionary = fighter.get("attach", {})
	if attach.is_empty():
		return
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	if skeleton == null:
		return
	for bone_name in attach:
		if skeleton.find_bone(bone_name) == -1:
			continue
		var slot := BoneAttachment3D.new()
		slot.bone_name = bone_name
		skeleton.add_child(slot)
		slot.add_child(load(attach[bone_name]).instantiate())


## Bringt das Modell auf eine einheitliche Größe (KayKit-Figuren sind größer als der Robo).
func _apply_scale(model: Node3D) -> void:
	model.scale = Vector3.ONE * fighter.get("scale", 0.8)


func _action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]
