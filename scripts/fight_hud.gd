class_name FightHud
extends Control
## Anzeige eines Kämpfers im Kampf (wie bei Smash Bros): rundes Kopfbild, große Schadens-Prozente,
## die mit jedem Treffer röter werden und kurz aufspringen, Leben als Punkte und die Spezial-Leiste.

const HEIGHT := 84.0
const FACE := 80.0
## Farbe der Prozentzahl: weiß bei 0 %, dann gelb, orange, rot, dunkelrot.
const DAMAGE_COLORS := [[0.0, Color(1, 1, 1)], [35.0, Color(1, 0.93, 0.45)], [70.0, Color(1, 0.62, 0.2)],
	[110.0, Color(1, 0.27, 0.2)], [170.0, Color(0.72, 0.08, 0.14)]]

var player: CharacterBody3D
var title := ""
## Rechts stehende Anzeige ist gespiegelt (Kopf rechts, Zahl links davon).
var mirrored := false
var show_stocks := true
var show_energy := true

var _face: TextureRect
var _face_fighter := ""
var _last_damage := 0.0
var _last_stocks := -1
var _pop := 0.0
var _flash := 0.0
var _shown_damage := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.size = Vector2(FACE, FACE)
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/portrait.gdshader")
	_face.material = mat
	add_child(_face)


func setup(p: CharacterBody3D, rect: Rect2, right_side: bool) -> void:
	player = p
	mirrored = right_side
	position = rect.position
	size = Vector2(rect.size.x, HEIGHT)
	_face.position = Vector2(size.x - FACE if mirrored else 0.0, 2.0)
	_face.flip_h = mirrored
	_last_damage = p.damage
	_last_stocks = p.stocks


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player) or not visible:
		return
	var fighter_name: String = player.fighter.get("name", "")
	if fighter_name != _face_fighter:
		_face_fighter = fighter_name
		_face.texture = Roster.portrait(player.fighter)
	if player.damage > _last_damage + 0.5:
		_pop = 1.0
	elif player.damage < _last_damage - 0.5:
		_pop = maxf(_pop, 0.4)
	_last_damage = player.damage
	if _last_stocks >= 0 and player.stocks < _last_stocks:
		_flash = 1.0
	_last_stocks = player.stocks
	_pop = maxf(_pop - delta * 3.5, 0.0)
	_flash = maxf(_flash - delta * 1.8, 0.0)
	# Die Zahl zählt schnell zum neuen Wert hoch statt zu springen.
	_shown_damage = move_toward(_shown_damage, player.damage, maxf(absf(player.damage - _shown_damage) * 12.0, 30.0) * delta)
	var out: bool = show_stocks and player.stocks <= 0
	var mat: ShaderMaterial = _face.material
	mat.set_shader_parameter("ring", Color.WHITE.lerp(player.color, 1.0 - _flash))
	mat.set_shader_parameter("grey", 1.0 if out else 0.0)
	modulate.a = 0.55 if out else 1.0
	queue_redraw()


static func damage_color(damage: float) -> Color:
	var last: Array = DAMAGE_COLORS[0]
	for step in DAMAGE_COLORS:
		if damage <= step[0]:
			var span: float = maxf(step[0] - last[0], 0.001)
			return (last[1] as Color).lerp(step[1], (damage - last[0]) / span)
		last = step
	return last[1]


## x-Position für ein Stück der Breite `w`, das links bei `x` beginnt; rechts stehende Anzeigen sind gespiegelt.
func _x(x: float, w: float) -> float:
	return size.x - x - w if mirrored else x


func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var color: Color = player.color
	var ready: bool = player.final_smash_ready
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	# Dunkle schräge Tafel hinter Zahl und Namen.
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(UiStyle.INK, 0.74)
	plate.skew = Vector2(-0.22 if mirrored else 0.22, 0)
	plate.set_corner_radius_all(8)
	plate.set_border_width_all(3)
	plate.border_color = color.lerp(Color.WHITE, _flash)
	plate.shadow_color = Color(0, 0, 0, 0.4)
	plate.shadow_size = 6
	plate.shadow_offset = Vector2(0, 4)
	if ready:
		# Smash-Kugel geholt: die Tafel leuchtet golden.
		plate.border_color = UiStyle.GOLD.lerp(Color.WHITE, pulse)
		plate.shadow_color = Color(UiStyle.GOLD, 0.5 + 0.4 * pulse)
		plate.shadow_size = 14
		plate.shadow_offset = Vector2.ZERO
	var plate_w := size.x - FACE * 0.5 - 8.0
	draw_style_box(plate, Rect2(_x(FACE * 0.5, plate_w), 16.0, plate_w, 60.0))

	var text_x := FACE + 8.0
	var text_w := size.x - text_x - 16.0
	var align := HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
	# Name über der Tafel.
	var name_pos := Vector2(_x(text_x - 4.0, text_w + 16.0), 13.0)
	draw_string_outline(UiStyle.BODY_FONT, name_pos, title, align, text_w + 16.0, 15, 6, Color(0, 0, 0, 0.85))
	draw_string(UiStyle.BODY_FONT, name_pos, title, align, text_w + 16.0, 15, color.lightened(0.25))

	# Große Prozentzahl: springt bei einem Treffer kurz auf und wackelt.
	var number := "%d" % roundi(_shown_damage)
	var font := UiStyle.TITLE_FONT
	var num_size := 46
	var num_w := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, num_size).x
	var pct_w := font.get_string_size("%", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var block_w := num_w + 3.0 + pct_w
	var start := _x(text_x, block_w)
	var center := Vector2(start + block_w * 0.5, 44.0)
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 5.0 * _pop
	var grow := 1.0 + 0.38 * _pop
	draw_set_transform(center + shake, 0.0, Vector2(grow, grow))
	var dmg_color := damage_color(player.damage).lerp(Color.WHITE, _pop * 0.6)
	var base := Vector2(-block_w * 0.5, 16.0)
	draw_string_outline(font, base, number, HORIZONTAL_ALIGNMENT_LEFT, -1, num_size, 10, Color(0, 0, 0, 0.9))
	draw_string_outline(font, base + Vector2(num_w + 3.0, 0), "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 8, Color(0, 0, 0, 0.9))
	draw_string(font, base, number, HORIZONTAL_ALIGNMENT_LEFT, -1, num_size, dmg_color)
	draw_string(font, base + Vector2(num_w + 3.0, 0), "%", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, dmg_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Leben als Punkte am äußeren Rand der Tafel.
	if show_stocks:
		var stocks: int = player.stocks
		if stocks > 5:
			var s := "● × %d" % stocks
			var pos := Vector2(_x(size.x - 96.0, 80.0), 44.0)
			var a := HORIZONTAL_ALIGNMENT_LEFT if mirrored else HORIZONTAL_ALIGNMENT_RIGHT
			draw_string_outline(UiStyle.BODY_FONT, pos, s, a, 80.0, 16, 6, Color(0, 0, 0, 0.85))
			draw_string(UiStyle.BODY_FONT, pos, s, a, 80.0, 16, color)
		else:
			for n in stocks:
				var cx := _x(size.x - 26.0 - n * 17.0, 0.0)
				draw_circle(Vector2(cx, 37.0), 7.5, Color(0, 0, 0, 0.85))
				draw_circle(Vector2(cx, 37.0), 5.5, color)
				draw_circle(Vector2(cx - 1.5, 35.5), 1.8, Color(1, 1, 1, 0.7))

	# Spezial-Leiste unten in der Tafel; voll blinkt sie.
	if show_energy:
		var bar_w := size.x - text_x - 22.0
		var bar := Rect2(_x(text_x, bar_w), 64.0, bar_w, 6.0)
		var back := StyleBoxFlat.new()
		back.bg_color = Color(0, 0, 0, 0.6)
		back.set_corner_radius_all(3)
		draw_style_box(back, bar)
		var fill: float = clampf(player.special_energy / player.SPECIAL_MAX, 0.0, 1.0)
		if fill > 0.01:
			var front := StyleBoxFlat.new()
			front.bg_color = color.lerp(Color.WHITE, pulse * 0.7) if fill >= 1.0 else color
			front.set_corner_radius_all(3)
			var fw := maxf(bar_w * fill, 6.0)
			draw_style_box(front, Rect2(bar.position.x + (bar_w - fw if mirrored else 0.0), bar.position.y, fw, bar.size.y))
