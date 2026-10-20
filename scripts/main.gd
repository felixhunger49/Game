extends Node2D

@onready var player1: CharacterBody2D = $Player1
@onready var player2: CharacterBody2D = $Player2
@onready var p1_label: Label = $HUD/P1Label
@onready var p2_label: Label = $HUD/P2Label
@onready var win_label: Label = $HUD/WinLabel

var game_over := false


func _ready() -> void:
	player1.opponent = player2
	player2.opponent = player1
	player1.fell_off.connect(_on_player_fell_off)
	player2.fell_off.connect(_on_player_fell_off)
	win_label.visible = false


func _process(_delta: float) -> void:
	p1_label.text = _hud_text("Spieler 1", player1)
	p2_label.text = _hud_text("Spieler 2", player2)
	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()


func _hud_text(name: String, player: CharacterBody2D) -> String:
	return "%s\n%d %%   Leben: %s" % [name, player.damage, "●".repeat(player.stocks)]


func _on_player_fell_off(player: CharacterBody2D) -> void:
	if player.stocks > 0 or game_over:
		return
	game_over = true
	var winner := 2 if player == player1 else 1
	win_label.text = "Spieler %d gewinnt!\nR drücken für Neustart" % winner
	win_label.visible = true
