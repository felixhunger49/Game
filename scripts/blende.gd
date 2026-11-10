extends CanvasLayer
## Weicher Übergang zwischen Menü und Kampf: das Bild wird kurz schwarz, statt hart umzuschalten.
## Als Autoload "Blende" überall erreichbar:  Blende.to("res://scenes/fight.tscn")   Blende.reload()

const OUT_SECONDS := 0.22
const IN_SECONDS := 0.35

var _rect: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.02, 0.02, 0.05, 0.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


## Zu einer anderen Szene wechseln.
func to(scene_path: String) -> void:
	_switch(func(): get_tree().change_scene_to_file(scene_path))


## Die laufende Szene neu starten (nochmal kämpfen).
func reload() -> void:
	_switch(func(): get_tree().reload_current_scene())


func _switch(change: Callable) -> void:
	if _busy:
		return
	_busy = true
	await _fade(1.0, OUT_SECONDS)
	change.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(0.0, IN_SECONDS)
	_busy = false


func _fade(alpha: float, seconds: float) -> void:
	var tween := create_tween()
	# Auch in Zeitlupe (K.-o.-Moment) gleich schnell.
	tween.set_ignore_time_scale(true)
	tween.tween_property(_rect, "color:a", alpha, seconds)
	await tween.finished
