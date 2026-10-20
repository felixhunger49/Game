# Game

Ein Plattform-Kampfspiel für zwei Spieler an einer Tastatur, gebaut mit [Godot 4](https://godotengine.org) (getestet mit 4.3).

## Regeln

- Beide Spieler kämpfen auf einer Plattform.
- Es gibt keine Lebenspunkte: Jeder Treffer erhöht den Schaden (in %). Je höher der Schaden, desto weiter fliegt man beim nächsten Treffer weg.
- Wer aus der Arena fällt oder geschleudert wird, verliert ein Leben und startet mit 0 % neu.
- Wer dreimal heruntergefallen ist, hat verloren.

## Steuerung

| Aktion | Spieler 1 (gelb) | Spieler 2 (blau) |
|---|---|---|
| Laufen | A / D | Pfeil links / rechts |
| Springen (2× in der Luft möglich) | W | Pfeil hoch |
| Schlagen | F oder Leertaste | L oder Enter |
| Neustart nach Spielende | R | R |

## Starten

1. Godot 4 herunterladen und öffnen.
2. Im Projektmanager auf **Importieren** klicken und `project.godot` wählen.
3. Mit **F5** starten.

## Aufbau

- `scenes/main.tscn` ist die Arena mit Hauptplattform, zwei Plattformen zum Draufspringen und der Anzeige.
- `scenes/player.tscn` ist eine Kämpfer-Figur, die zweimal in der Arena steckt.
- `scripts/player.gd` enthält Bewegung, Angriff, Schaden und Rückstoß. Werte wie `attack_damage` oder `knockback_per_damage` lassen sich im Inspektor ändern.
- `scripts/main.gd` verbindet die Spieler, zeigt Schaden und Leben an und erkennt den Sieger.
