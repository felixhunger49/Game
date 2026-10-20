extends Node3D
## Der Kampf: lädt die gewählte Map, lässt die Spieler Kämpfer wählen und kämpfen,
## lässt Items erscheinen und erkennt den Sieger.

enum State { SELECT, FIGHT, GAME_OVER }

const CONTROLS_HINT := "Spieler 1: A/D laufen, W springen, S abwehren, F schwach, G stark, H Tritt, T Spezial\n" \
	+ "Spieler 2: Pfeile laufen/springen, Pfeil runter abwehren, J schwach, K stark, L Tritt, I Spezial   |   Esc: Menü"

var state := State.SELECT
var ready_flags := [false, false]
var item_timer := 0.0

@onready var players: Array = [$Player1, $Player2]
@onready var labels: Array = [$HUD/P1Label, $HUD/P2Label]
@onready var center_label: Label = $HUD/CenterLabel
@onready var bottom_label: Label = $HUD/BottomLabel
@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	var map: Node3D = load(Settings.current_map().scene).instantiate()
	add_child(map)
	move_child(map, 0)

	players[0].opponent = players[1]
	players[1].opponent = players[0]
	for i in players.size():
		var p = players[i]
		var spawn: Node3D = map.get_node("Spawn%d" % (i + 1))
		p.position = spawn.position
		p.spawn_position = spawn.position
		p.stocks = Settings.stocks
		p.set_fighter(Settings.choices[i])
		p.fell_off.connect(_on_player_fell_off)
	center_label.text = "Wählt eure Kämpfer!\nLaufen-Tasten: wechseln   Schwacher Angriff: bereit"
	bottom_label.text = CONTROLS_HINT
	_reset_item_timer()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("back"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	match state:
		State.SELECT:
			_handle_select()
		State.FIGHT:
			_update_items(delta)
		State.GAME_OVER:
			if Input.is_action_just_pressed("restart"):
				get_tree().reload_current_scene()
	_update_hud()
	_update_camera(delta)


func _handle_select() -> void:
	for i in players.size():
		var prefix := "p%d_" % (i + 1)
		if ready_flags[i]:
			continue
		var step := 0
		if Input.is_action_just_pressed(prefix + "left"):
			step = -1
		elif Input.is_action_just_pressed(prefix + "right"):
			step = 1
		if step != 0:
			Settings.choices[i] = wrapi(Settings.choices[i] + step, 0, Roster.count())
			players[i].set_fighter(Settings.choices[i])
		if Input.is_action_just_pressed(prefix + "weak"):
			ready_flags[i] = true
	if ready_flags[0] and ready_flags[1]:
		_start_fight()


func _start_fight() -> void:
	Settings.save()
	state = State.FIGHT
	center_label.text = ""
	bottom_label.text = ""
	for p in players:
		p.controls_enabled = true
		# Der Bereit-Tastendruck soll nicht gleich als Schlag zählen.
		p.attack_timer = 0.3


func _update_items(delta: float) -> void:
	if not Settings.items_enabled:
		return
	item_timer -= delta
	if item_timer > 0.0:
		return
	_reset_item_timer()
	var item := Item.new()
	add_child(item)
	item.setup(Item.TYPES.keys().pick_random(), players)
	item.position = Vector3(randf_range(-7.0, 7.0), 9.0, 0.0)


func _reset_item_timer() -> void:
	var interval: Vector2 = Settings.ITEM_INTERVALS[Settings.item_rate]
	item_timer = randf_range(interval.x, interval.y)


func _update_hud() -> void:
	for i in players.size():
		var p = players[i]
		var text: String = p.fighter.get("name", "")
		if state == State.SELECT:
			var special: String = Roster.SPECIALS.get(p.fighter.get("special", ""), "")
			text = "Spieler %d\n◀ %s ▶\n%s" % [i + 1, text, "Bereit!" if ready_flags[i] else special]
		else:
			text = "Spieler %d: %s\n%d %%   %s" % [i + 1, text, p.damage, "●".repeat(p.stocks)]
		labels[i].text = text


## Die Kamera folgt beiden Spielern und zoomt heraus, wenn sie weit auseinander sind.
func _update_camera(delta: float) -> void:
	var visible_players := players.filter(func(p): return p.visible)
	if visible_players.is_empty():
		return
	var min_pos: Vector3 = visible_players[0].position
	var max_pos: Vector3 = min_pos
	for p in visible_players:
		min_pos = min_pos.min(p.position)
		max_pos = max_pos.max(p.position)
	var mid := (min_pos + max_pos) / 2.0
	var spread := maxf(max_pos.x - min_pos.x, (max_pos.y - min_pos.y) * 1.6)
	var target := Vector3(
		clampf(mid.x * 0.6, -6.0, 6.0),
		clampf(mid.y * 0.5 + 2.2, 1.8, 7.0),
		clampf(9.0 + spread * 0.9, 14.0, 26.0))
	if state == State.SELECT:
		target = Vector3(0, 1.6, 9)
	camera.position = camera.position.lerp(target, 3.0 * delta)


func _on_player_fell_off(player: CharacterBody3D) -> void:
	if player.stocks > 0 or state == State.GAME_OVER:
		return
	state = State.GAME_OVER
	var winner: CharacterBody3D = player.opponent
	winner.cheer()
	center_label.text = "Spieler %d gewinnt!\nR: nochmal   Esc: Menü" % winner.player_id
