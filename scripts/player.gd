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

## Die Angriffe. damage = Schaden in %, base/scale = Rückstoß (base + Schaden * scale),
## range = Reichweite nach vorne und nach oben/unten, startup = Ausholzeit bis zum Treffer,
## cooldown = Zeit bis zum nächsten Angriff, angle = Flugrichtung des Getroffenen.
const ATTACKS := {
	"weak": {"damage": 4.0, "base": 3.0, "scale": 0.07, "range": Vector2(1.5, 1.2), "startup": 0.05,
		"cooldown": 0.25, "angle": Vector2(1, 0.35), "anim_speed": 2.2},
	"strong": {"damage": 13.0, "base": 6.5, "scale": 0.22, "range": Vector2(1.9, 1.4), "startup": 0.3,
		"cooldown": 0.75, "angle": Vector2(1, 0.7), "anim_speed": 1.4},
	"kick": {"damage": 8.0, "base": 5.0, "scale": 0.15, "range": Vector2(1.7, 1.0), "startup": 0.12,
		"cooldown": 0.45, "angle": Vector2(1, 0.25), "anim_speed": 1.8},
	"feuerball": {"damage": 9.0, "base": 4.0, "scale": 0.12, "startup": 0.2, "cooldown": 1.0,
		"angle": Vector2(1, 0.3), "anim_speed": 1.6},
	"sturm": {"damage": 10.0, "base": 5.5, "scale": 0.16, "range": Vector2(1.3, 1.2), "startup": 0.05,
		"cooldown": 1.0, "angle": Vector2(1, 0.4), "anim_speed": 1.6},
	"wirbel": {"damage": 11.0, "base": 6.0, "scale": 0.18, "range": Vector2(2.2, 1.5), "startup": 0.15,
		"cooldown": 1.1, "angle": Vector2(1, 0.8), "anim_speed": 1.5},
	"aufwaerts": {"damage": 9.0, "base": 6.0, "scale": 0.15, "range": Vector2(1.4, 2.8), "startup": 0.1,
		"cooldown": 0.9, "angle": Vector2(0.2, 1), "anim_speed": 1.6},
}

## Alles außerhalb dieses Bereichs zählt als heruntergefallen (x links, y unten, Breite, Höhe).
const BLAST_ZONE := Rect2(-19, -10, 38, 28)
## Die Figuren drehen sich nicht ganz zur Seite, damit man ihr Gesicht sieht (wie bei Smash Bros.).
const SIDE_ANGLE := deg_to_rad(70)
## Physik-Ebene, auf der die schwebenden Plattformen liegen (man kann von unten durchspringen).
const PLATFORM_LAYER := 2
const SHIELD_MAX := 100.0
const POWER_MULTIPLIER := 1.4
## Energie für die Spezialattacke: füllt sich mit der Zeit, durch Treffen und durch Getroffenwerden.
const SPECIAL_MAX := 100.0
const SPECIAL_PER_SECOND := 3.0
const SPECIAL_PER_DAMAGE_DEALT := 2.5
const SPECIAL_PER_DAMAGE_TAKEN := 1.2
const SHOUTS := ["ha", "hja", "hah"]

## Kunststücke am höchsten Punkt eines Sprungs. axis: Drehachse der Figur (x = Salto vorwärts,
## -x = rückwärts, y = Pirouette, z = Rad), turns = Umdrehungen, time = Dauer in Sekunden.
## hover: schwebt währenddessen kurz in der Luft.
const FLIPS := {
	"salto": {"axis": Vector3(1, 0, 0), "turns": 1.0, "time": 0.45},
	"rueckwaerts": {"axis": Vector3(-1, 0, 0), "turns": 1.0, "time": 0.5},
	"doppelsalto": {"axis": Vector3(1, 0, 0), "turns": 2.0, "time": 0.6},
	"doppel_rueckwaerts": {"axis": Vector3(-1, 0, 0), "turns": 2.0, "time": 0.65},
	"rad": {"axis": Vector3(0, 0, 1), "turns": 1.0, "time": 0.5},
	"pirouette": {"axis": Vector3(0, 1, 0), "turns": 2.0, "time": 0.55},
	"schraube": {"axis": Vector3(1, 1, 0), "turns": 1.0, "time": 0.6},
	"purzeln": {"axis": Vector3(1, 0, 1), "turns": 1.0, "time": 0.6},
	"schweben": {"axis": Vector3(0, 1, 0), "turns": 1.0, "time": 0.9, "hover": true},
	"propeller": {"axis": Vector3(0, 1, 0), "turns": 3.0, "time": 0.6},
}
## Doppelt tippen: zwei Tastendrücke innerhalb dieser Zeit (Sekunden).
const DOUBLE_TAP_TIME := 0.25
## Ausweichrolle: Dauer, Geschwindigkeit und Wartezeit bis zur nächsten Rolle.
const ROLL_TIME := 0.35
const ROLL_SPEED := 12.0
const ROLL_COOLDOWN := 0.6
## So lange fällt man nach doppeltem Runter durch eine Plattform.
const DROP_TIME := 0.45

## Höhe der Körpermitte: um diesen Punkt drehen sich die Kunststücke.
const FLIP_PIVOT_HEIGHT := 0.9
const CLOTH_SHADER := preload("res://scripts/cloth.gdshader")

var opponent: CharacterBody3D
var fighter: Dictionary = {}
var controls_enabled := false
var damage := 0.0
var stocks := 3
var facing := 1
var jumps_left := 0
var hitstun := 0.0
var stunned := 0.0
var attack_timer := 0.0
var pending_attack := ""
var pending_time := 0.0
var dash_time := 0.0
var dash_hit_done := false
var special_air_used := false
var shielding := false
var shield_hp := SHIELD_MAX
var power_time := 0.0
var speed_time := 0.0
var special_energy := 0.0
## Windgeschwindigkeit der Map (Dorf): schiebt die Figur zur Seite.
var wind_speed := 0.0
var spawn_position := Vector3.ZERO
var anim_player: AnimationPlayer
var current_anim := ""
## Drehpunkt in der Körpermitte für Saltos; darunter hängt das Modell.
var flip_pivot: Node3D
var flip_time := -1.0
var jumped := false
var was_rising := false
## Materialien der flatternden Teile (Umhänge, Hutspitzen, Haare).
var cloth_materials: Array[ShaderMaterial] = []
var fall_wind := 0.0
## Zeitpunkt des letzten Tastendrucks je Richtung, um doppeltes Tippen zu erkennen.
var last_tap := {"left": -1.0, "right": -1.0, "shield": -1.0}
var roll_time := 0.0
var roll_dir := 1
var roll_cooldown := 0.0
var drop_time := 0.0
var on_platform := false

@onready var model_root: Node3D = $Model
@onready var tag: Label3D = $Tag
@onready var shield_bubble: MeshInstance3D = $Shield


func _ready() -> void:
	spawn_position = position
	facing = start_facing
	jumps_left = max_jumps
	tag.modulate = color
	var mat: StandardMaterial3D = shield_bubble.material_override.duplicate()
	mat.albedo_color = Color(color, 0.35)
	mat.emission = color
	shield_bubble.material_override = mat
	shield_bubble.visible = false


## Tauscht das 3D-Modell gegen den Kämpfer an Stelle `index` im Roster.
func set_fighter(index: int) -> void:
	fighter = Roster.get_fighter(index)
	for child in model_root.get_children():
		model_root.remove_child(child)
		child.queue_free()
	current_anim = ""
	flip_time = -1.0

	flip_pivot = Node3D.new()
	flip_pivot.position.y = FLIP_PIVOT_HEIGHT
	model_root.add_child(flip_pivot)
	var model: Node3D = load(fighter.scene).instantiate()
	flip_pivot.add_child(model)
	model.position.y = -FLIP_PIVOT_HEIGHT
	_setup_weapons(model)
	_setup_cloth(model)
	model.scale = Vector3.ONE * fighter.get("scale", 0.8)

	anim_player = model.find_child("AnimationPlayer", true, false)
	if anim_player:
		for action in ["idle", "run", "jump", "shield", "stunned"]:
			var anim_name := Roster.anim_name(fighter, action)
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	_play("idle")


func _physics_process(delta: float) -> void:
	attack_timer = max(attack_timer - delta, 0.0)
	hitstun = max(hitstun - delta, 0.0)
	stunned = max(stunned - delta, 0.0)
	power_time = max(power_time - delta, 0.0)
	speed_time = max(speed_time - delta, 0.0)
	roll_cooldown = max(roll_cooldown - delta, 0.0)
	drop_time = max(drop_time - delta, 0.0)
	if controls_enabled:
		add_special_energy(SPECIAL_PER_SECOND * delta)

	velocity.y -= gravity * delta
	# Von unten durch die schwebenden Plattformen springen, beim Fallen darauf landen.
	# Nach doppeltem Runter fällt man kurz durch sie hindurch.
	set_collision_mask_value(PLATFORM_LAYER, velocity.y <= 0.0 and drop_time <= 0.0)
	if is_on_floor():
		jumps_left = max_jumps
		special_air_used = false
		jumped = false

	_update_pending_attack(delta)
	_update_dash(delta)

	var can_act := controls_enabled and hitstun == 0.0 and stunned == 0.0
	if can_act and roll_time <= 0.0 and dash_time <= 0.0:
		_check_double_taps()
	shielding = can_act and is_on_floor() and Input.is_action_pressed(_action("shield")) and shield_hp > 0.0 \
		and roll_time <= 0.0 and drop_time <= 0.0
	if shielding:
		shield_hp = max(shield_hp - 18.0 * delta, 0.0)
	else:
		shield_hp = min(shield_hp + 12.0 * delta, SHIELD_MAX)

	if hitstun > 0.0:
		# Getroffen: keine Kontrolle, die Figur fliegt weiter.
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta) + wind_speed * delta
	elif dash_time > 0.0:
		pass
	elif roll_time > 0.0:
		_update_roll(delta)
	elif can_act and not shielding:
		_handle_input(delta)
	else:
		velocity.x = move_toward(velocity.x, wind_speed * 0.5, 60.0 * delta)
		if shielding and Input.is_action_just_pressed(_action("jump")):
			velocity.y = jump_velocity
			jumps_left -= 1
			Audio.sfx("jump")

	# Kunststück am höchsten Punkt eines Sprungs (nicht beim Wegfliegen nach einem Treffer).
	var rising := velocity.y > 0.0 and not is_on_floor()
	if was_rising and not rising and jumped and flip_time < 0.0 and hitstun == 0.0 and dash_time <= 0.0 \
			and pending_attack == "" and not is_on_floor():
		_start_flip()
	was_rising = rising
	if flip_time >= 0.0 and FLIPS[fighter.get("flip", "salto")].get("hover", false):
		velocity.y = maxf(velocity.y, -1.5)

	move_and_slide()
	on_platform = false
	if is_on_floor():
		for i in get_slide_collision_count():
			var body := get_slide_collision(i).get_collider() as CollisionObject3D
			if body and body.get_collision_layer_value(PLATFORM_LAYER):
				on_platform = true
	_update_visuals(delta)

	if not BLAST_ZONE.has_point(Vector2(position.x, position.y)):
		_lose_stock()


func _handle_input(delta: float) -> void:
	var direction := Input.get_axis(_action("left"), _action("right"))
	var top_speed := speed * (1.4 if speed_time > 0.0 else 1.0)
	var accel := 60.0 if is_on_floor() else 28.0
	if attack_timer > 0.0 and is_on_floor():
		# Beim Zuschlagen bleibt man fast stehen.
		direction = 0.0
	# Wind schiebt in der Luft stärker als am Boden.
	var wind := wind_speed * (0.6 if is_on_floor() else 1.0)
	velocity.x = move_toward(velocity.x, direction * top_speed + wind, accel * delta)
	if direction != 0.0:
		facing = int(sign(direction))

	if Input.is_action_just_pressed(_action("jump")) and jumps_left > 0:
		velocity.y = jump_velocity * (1.12 if speed_time > 0.0 else 1.0)
		Audio.sfx("jump", 1.0 if jumps_left == max_jumps else 1.25)
		jumps_left -= 1
		jumped = true
		# Ein neuer Sprung bricht ein laufendes Kunststück nicht ab, startet aber oben ein neues.
		if flip_time >= 0.0:
			_end_flip()

	if attack_timer > 0.0:
		return
	for kind in ["weak", "strong", "kick"]:
		if Input.is_action_just_pressed(_action(kind)):
			start_attack(kind)
			return
	if Input.is_action_just_pressed(_action("special")):
		start_special()


## Holt zum Angriff aus. Der Treffer kommt nach der Ausholzeit (startup).
func start_attack(kind: String) -> void:
	var atk: Dictionary = ATTACKS[kind]
	attack_timer = atk.cooldown
	pending_attack = kind
	pending_time = atk.startup
	_end_flip()
	_play(kind, atk.anim_speed)
	match kind:
		"weak":
			Audio.sfx("swing_weak")
		"strong":
			Audio.sfx("swing_strong")
			_shout()
		"kick":
			Audio.sfx("swing_weak", 0.8)


func start_special() -> void:
	var kind: String = fighter.get("special", "feuerball")
	if not special_ready():
		# Noch nicht aufgeladen.
		Audio.sfx("fizzle")
		attack_timer = 0.2
		return
	if kind == "aufwaerts":
		if special_air_used:
			return
		special_air_used = true
		velocity.y = 14.0
	elif kind == "sturm":
		dash_time = 0.25
		dash_hit_done = false
	special_energy = 0.0
	start_attack(kind)
	_play("special", ATTACKS[kind].anim_speed)
	var sounds := {"feuerball": "fireball", "sturm": "dash", "wirbel": "whirl", "aufwaerts": "uppercut"}
	Audio.sfx(sounds.get(kind, "swing_strong"))
	Audio.voice("spezial", voice_pitch())


func add_special_energy(amount: float) -> void:
	if not Settings.special_charge or special_energy >= SPECIAL_MAX:
		return
	special_energy = minf(special_energy + amount, SPECIAL_MAX)
	if special_energy >= SPECIAL_MAX:
		Audio.sfx("special_ready")


func special_ready() -> bool:
	return not Settings.special_charge or special_energy >= SPECIAL_MAX


## Stimmlage der Figur (aus dem Roster), damit Skelette tiefer und der Robo höher klingen.
func voice_pitch() -> float:
	return fighter.get("voice", 1.0)


func _shout() -> void:
	if randf() < 0.6:
		Audio.voice(SHOUTS.pick_random(), voice_pitch() * randf_range(0.95, 1.05), -2.0)


func _update_pending_attack(delta: float) -> void:
	if pending_attack == "":
		return
	pending_time -= delta
	if pending_time > 0.0:
		return
	var kind := pending_attack
	pending_attack = ""
	var atk: Dictionary = ATTACKS[kind]
	match kind:
		"feuerball":
			var ball := Projectile.new()
			get_parent().add_child(ball)
			ball.launch(self, atk, global_position + Vector3(0.8 * facing, 1.1, 0), facing)
		"sturm":
			pass  # trifft während des Stoßes, siehe _update_dash
		"wirbel":
			_try_hit(atk, true)
		_:
			_try_hit(atk, false)


func _update_dash(delta: float) -> void:
	if dash_time <= 0.0:
		return
	dash_time -= delta
	velocity.x = facing * 16.0
	velocity.y = max(velocity.y, 0.0)
	if not dash_hit_done and _try_hit(ATTACKS.sturm, false):
		dash_hit_done = true
		dash_time = 0.0
		velocity.x = 0.0


## Trifft den Gegner, wenn er in Reichweite ist. both_sides: trifft vorne und hinten.
func _try_hit(atk: Dictionary, both_sides: bool) -> bool:
	if opponent == null or not opponent.visible:
		return false
	var offset := opponent.global_position - global_position
	var forward := offset.x * facing
	var reach: Vector2 = atk.range
	var in_range := false
	if both_sides:
		in_range = absf(offset.x) <= reach.x and absf(offset.y) <= reach.y
	elif atk == ATTACKS.aufwaerts:
		in_range = absf(offset.x) <= reach.x and offset.y > -0.5 and offset.y <= reach.y
	else:
		in_range = forward > -0.3 and forward <= reach.x and absf(offset.y) <= reach.y
	if not in_range:
		return false
	var side := facing
	if both_sides:
		side = 1 if offset.x >= 0.0 else -1
	var angle: Vector2 = atk.angle
	if opponent.take_hit(atk, Vector3(angle.x * side, angle.y, 0).normalized(), power_time > 0.0):
		add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_DEALT)
	return true


## Getroffen werden. Je mehr Schaden die Figur schon hat, desto weiter fliegt sie.
## Gibt false zurück, wenn der Treffer abgewehrt wurde.
func take_hit(atk: Dictionary, direction: Vector3, powered := false) -> bool:
	if roll_time > 0.0:
		# Mitten in der Ausweichrolle: der Treffer geht ins Leere.
		Audio.sfx("swing_weak", 1.4, -4.0)
		return false
	var multiplier := POWER_MULTIPLIER if powered else 1.0
	if shielding:
		shield_hp -= atk.damage * 3.0 * multiplier
		velocity.x = direction.x * 3.0
		if shield_hp <= 0.0:
			# Schild zerbrochen: kurz betäubt.
			shield_hp = SHIELD_MAX * 0.4
			shielding = false
			stunned = 2.5
			velocity.y = 6.0
			Audio.sfx("shield_break")
			Audio.voice("au", voice_pitch())
		else:
			Audio.sfx("shield_block")
		return false
	damage += atk.damage * multiplier
	var knockback: float = (atk.base + damage * atk.scale) * multiplier
	velocity = direction * knockback
	hitstun = 0.12 + knockback * 0.02
	pending_attack = ""
	dash_time = 0.0
	_end_flip()
	_play("hit", 1.5)
	add_special_energy(atk.damage * SPECIAL_PER_DAMAGE_TAKEN)
	var heavy: bool = atk.damage * multiplier >= 10.0
	Audio.sfx("hit_strong" if heavy else "hit_weak")
	if heavy or randf() < 0.3:
		Audio.voice("au", voice_pitch() * randf_range(0.95, 1.05), -2.0)
	return true


func heal(amount: float) -> void:
	damage = max(damage - amount, 0.0)


func give_power(seconds: float) -> void:
	power_time = seconds


func give_speed(seconds: float) -> void:
	speed_time = seconds


func cheer() -> void:
	controls_enabled = false
	_play("cheer")
	Audio.voice("jubel", voice_pitch())


func _lose_stock() -> void:
	stocks -= 1
	damage = 0.0
	hitstun = 0.0
	stunned = 0.0
	power_time = 0.0
	speed_time = 0.0
	shield_hp = SHIELD_MAX
	pending_attack = ""
	dash_time = 0.0
	roll_time = 0.0
	drop_time = 0.0
	_end_flip()
	velocity = Vector3.ZERO
	Audio.sfx("ko")
	if stocks > 0:
		position = spawn_position + Vector3(0, 4, 0)
	else:
		visible = false
		set_physics_process(false)
	fell_off.emit(self)


func _update_visuals(delta: float) -> void:
	# Vor dem Kampf schauen die Figuren in die Kamera, im Kampf zum Gegner.
	var target_angle := facing * SIDE_ANGLE if controls_enabled or hitstun > 0.0 else 0.0
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, 15.0 * delta)

	if roll_time <= 0.0:
		_update_flip(delta)
	_update_cloth(delta)

	shield_bubble.visible = shielding
	shield_bubble.scale = Vector3.ONE * lerpf(0.5, 1.0, shield_hp / SHIELD_MAX)

	var text := "P%d" % player_id
	if stunned > 0.0:
		text += "\nBetäubt!"
	elif power_time > 0.0 and speed_time > 0.0:
		text += "\nKraft + Tempo"
	elif power_time > 0.0:
		text += "\nKraft!"
	elif speed_time > 0.0:
		text += "\nTempo!"
	elif Settings.special_charge and special_energy >= SPECIAL_MAX and controls_enabled:
		text += "\nSpezial bereit!"
	tag.text = text

	if current_anim == "cheer":
		return
	if hitstun > 0.0:
		_play("hit", 1.5)
	elif stunned > 0.0:
		_play("stunned")
	elif roll_time > 0.0:
		return
	elif current_anim in ATTACKS or current_anim in ["weak", "strong", "kick", "special"]:
		if attack_timer > 0.0:
			return
		_play_movement()
	elif shielding:
		_play("shield")
	else:
		_play_movement()


func _play_movement() -> void:
	if not is_on_floor():
		_play("jump")
	elif absf(velocity.x) > 0.5:
		_play("run")
	else:
		_play("idle")


func _play(action: String, speed_scale := 1.0) -> void:
	if anim_player == null:
		return
	var is_attack := action in ["weak", "strong", "kick", "special"]
	var anim_name := Roster.anim_name(fighter, action)
	if anim_name == "" or not anim_player.has_animation(anim_name):
		# Der Robo hat keine Schlag-Animationen: dann kurz nach vorne stoßen.
		if is_attack:
			current_anim = action
			_lunge()
		return
	if action == current_anim and not is_attack:
		return
	current_anim = action
	anim_player.play(anim_name, 0.08, speed_scale)
	if is_attack:
		anim_player.seek(0.0, true)


## Doppelt links/rechts: Ausweichrolle. Doppelt runter auf einer Plattform: hindurchfallen.
func _check_double_taps() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for dir in last_tap:
		if not Input.is_action_just_pressed(_action(dir)):
			continue
		var double: bool = now - last_tap[dir] <= DOUBLE_TAP_TIME
		last_tap[dir] = -1.0 if double else now
		if not double:
			continue
		if dir == "shield":
			if on_platform:
				_drop_through()
		elif roll_cooldown <= 0.0 and attack_timer <= 0.0:
			_start_roll(1 if dir == "right" else -1)


func _start_roll(dir: int) -> void:
	roll_dir = dir
	facing = dir
	roll_time = ROLL_TIME
	roll_cooldown = ROLL_COOLDOWN
	_end_flip()
	pending_attack = ""
	Audio.sfx("dash", 0.8, -3.0)
	_play("dodge", 1.6)


func _update_roll(delta: float) -> void:
	roll_time = maxf(roll_time - delta, 0.0)
	# Schnell los, zum Ende hin langsamer; in der Luft etwas kürzer.
	var progress := 1.0 - roll_time / ROLL_TIME
	var speed_now := ROLL_SPEED * (1.0 - progress * 0.6) * (1.0 if is_on_floor() else 0.75)
	velocity.x = roll_dir * speed_now
	# Die Figur rollt einmal vorwärts um ihre Körpermitte.
	flip_pivot.rotation = Vector3(TAU * progress * progress * (3.0 - 2.0 * progress), 0, 0)
	if roll_time <= 0.0:
		flip_pivot.rotation = Vector3.ZERO


func _drop_through() -> void:
	drop_time = DROP_TIME
	velocity.y = -3.0
	shielding = false
	Audio.sfx("swing_weak", 0.6, -4.0)


func _start_flip() -> void:
	flip_time = 0.0
	Audio.sfx("swing_weak", 0.7, -6.0)


func _end_flip() -> void:
	flip_time = -1.0
	if flip_pivot:
		flip_pivot.rotation = Vector3.ZERO


func _update_flip(delta: float) -> void:
	if flip_time < 0.0:
		return
	if is_on_floor():
		_end_flip()
		return
	var flip: Dictionary = FLIPS[fighter.get("flip", "salto")]
	flip_time += delta
	var progress := clampf(flip_time / flip.time, 0.0, 1.0)
	# Langsam rein, schnell durch, langsam raus.
	var eased := progress * progress * (3.0 - 2.0 * progress)
	flip_pivot.rotation = flip.axis * flip.turns * TAU * eased
	if progress >= 1.0:
		_end_flip()


## Teile mit eingebackener Flatter-Stärke (Vertex-Farbe) bekommen den Stoff-Shader.
func _setup_cloth(model: Node3D) -> void:
	cloth_materials.clear()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = node.mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		if not (mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR):
			continue
		if _max_red(mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]) <= 0.0:
			continue
		var original := mesh.surface_get_material(0) as BaseMaterial3D
		var mat := ShaderMaterial.new()
		mat.shader = CLOTH_SHADER
		if original:
			mat.set_shader_parameter("albedo_tex", original.albedo_texture)
		node.material_override = mat
		cloth_materials.append(mat)


func _max_red(colors: PackedColorArray) -> float:
	var m := 0.0
	for c in colors:
		m = maxf(m, c.r)
	return m


func _update_cloth(delta: float) -> void:
	if cloth_materials.is_empty():
		return
	var target := clampf(-velocity.y / 14.0, 0.0, 1.0) if not is_on_floor() else 0.0
	fall_wind = lerpf(fall_wind, target, 8.0 * delta)
	var run := clampf(absf(velocity.x) / 12.0, 0.0, 1.0)
	for mat in cloth_materials:
		mat.set_shader_parameter("fall_wind", fall_wind)
		mat.set_shader_parameter("run_wind", run)


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


func _action(action_name: String) -> String:
	return "p%d_%s" % [player_id, action_name]
