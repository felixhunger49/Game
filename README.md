# Game

Ein 2D-Plattformer-Grundgerüst für [Godot 4](https://godotengine.org) (getestet mit 4.3).

## Starten

1. Godot 4 herunterladen und öffnen (kostenlos, keine Installation nötig).
2. Im Projektmanager auf **Importieren** klicken und die Datei `project.godot` aus diesem Ordner wählen.
3. Mit **F5** (oder dem Play-Knopf oben rechts) starten.

## Steuerung

| Aktion | Tasten |
|---|---|
| Laufen | A / D oder Pfeiltasten |
| Springen | Leertaste, W oder Pfeil hoch |

## Aufbau

- `scenes/main.tscn` ist die Spielwelt mit Boden und Plattformen.
- `scenes/player.tscn` ist die Spielfigur mit Kollision und Kamera.
- `scripts/player.gd` enthält Laufen, Springen und Schwerkraft. Geschwindigkeit und Sprunghöhe lassen sich im Inspektor ändern.
