# Arena-Kampf

Ein Plattform-Kampfspiel für zwei Spieler an einer Tastatur oder allein gegen den Computer, gebaut mit [Godot 4](https://godotengine.org) (getestet mit 4.3).
Wie bei Super Smash Bros. sind Figuren und Arenen 3D-Modelle, gekämpft wird aber nur nach links, rechts, oben und unten.

![Burg](docs/burg.png)
![Dorf](docs/dorf.png)
![Friedhof](docs/friedhof.png)
![Vulkan](docs/vulkan.png)
![Piratenschiff](docs/piratenschiff.png)
![Eiswelt](docs/eiswelt.png)
![Wolkentempel](docs/wolkentempel.png)

## Regeln

- Es gibt keine Lebenspunkte: Jeder Treffer erhöht den Schaden (in %). Je höher der Schaden, desto weiter fliegt man beim nächsten Treffer.
- Wer aus der Arena fällt oder geschleudert wird, verliert ein Leben und startet mit 0 % neu.
- Wer keine Leben mehr hat, hat verloren. Wie viele Leben es gibt, stellst du in den Optionen ein (Standard: 3).

## Menü

- **Kampf starten**: Danach wählt jeder Spieler mit seinen Laufen-Tasten einen Kämpfer und drückt den schwachen Angriff, wenn er bereit ist.
- **Modus**: Zwei Spieler oder Solo gegen den Computer. Im Solo-Modus wählt der Computer einen zufälligen anderen
  Kämpfer und ist sofort bereit. Seine Stärke stellt man darunter ein: Leicht, Mittel oder Schwer
  (Schwer reagiert schneller, greift öfter an, blockt mehr und macht kaum Fehler).
- **Ziele zerstören (gegen die Uhr)**: allein auf der gewählten Map. Zehn schwebende Zielscheiben sind verteilt: auf den
  Plattformen, in der Luft und über dem Boden. Jeder Angriff zerstört sie (auch Feuerball, Laser, Pfeilregen, Erdbeben …).
  Die Zeit läuft, bis alle kaputt sind; die Bestzeit wird je Map und Kämpfer gespeichert.
- **Endboss: Riesen-Kampfroboter**: allein gegen einen 1,7-mal so großen Kampfroboter mit Lebensleiste (220) statt Prozent.
  Er wird kaum weggeschleudert, schießt regelmäßig seinen Laser (drüberspringen!), lässt Raketen regnen (rote Kreise am Boden
  zeigen, wo sie einschlagen) und entlädt Overcharge. Ab halber Leiste wird er WÜTEND: glüht rot, ist schneller und schießt öfter.
- **Map**: Burg, Dorf, Friedhof, Vulkan, Piratenschiff, Eiswelt oder Wolkentempel. Jede Map hat ihren eigenen Effekt (siehe unten).
- **Optionen**: Items an oder aus, wie oft Items erscheinen (selten, normal, oft), die Anzahl der Leben,
  Map-Effekte an oder aus, Spezial aufladen an oder aus, Lautstärke von Musik und Geräuschen.
- **Steuerung anpassen**: jede Taste beider Spieler neu belegen (Tastatur oder Gamepad). Ist die neue Taste
  schon belegt, tauschen die beiden Aktionen. „Standard wiederherstellen“ setzt alles zurück.

Im Menü: W/S oder Pfeile hoch/runter wählen, A/D oder Pfeile links/rechts ändern, F, J oder Enter bestätigen, Esc zurück.

## Steuerung

Standardbelegung (im Menü unter „Steuerung anpassen“ änderbar):

| Aktion | Spieler 1 | Spieler 2 |
|---|---|---|
| Laufen | A / D | Pfeil links / rechts |
| Hoch / Runter (für Richtungs-Angriffe) | W / S | Pfeil hoch / runter |
| Springen (2× in der Luft möglich) | Leertaste | Num 0 (oder Strg rechts) |
| Abwehren (gedrückt halten) | Umschalt links | Umschalt rechts (oder Num ,) |
| Schwacher Angriff | F | J (oder Num 1) |
| Starker Angriff | G | K (oder Num 2) |
| Tritt | H | L (oder Num 3) |
| Spezialattacke | T | I (oder Num 5) |
| Richtungs-Angriffe | W oder S halten + F/G; in der Luft: F mit W, S oder zurück (A/D) | genauso mit Pfeilen und J/K |
| Ausweichrolle | 2× schnell links oder rechts, oder Umschalt halten + A/D | 2× schnell Pfeil links oder rechts, oder Abwehren halten + links/rechts |
| Smash-Angriff aufladen | G gedrückt halten, loslassen | K gedrückt halten, loslassen |
| Greifen | Umschalt links halten + F | Abwehren halten + J |
| Werfen (im Griff) | A/D vor/zurück, W hoch, S runter, F zuschlagen | Pfeile, J zuschlagen |
| Ausweichen in der Luft | Umschalt links in der Luft | Abwehren in der Luft |
| Schnell fallen | S in der Luft gedrückt halten | Pfeil runter in der Luft gedrückt halten |
| An der Kante | automatisch beim Fallen; Leertaste hochspringen, W oder zur Bühne hochklettern, Angriff = hochklettern mit Tritt, S oder weg = loslassen | genauso mit den Pfeilen |
| Durch eine Plattform fallen | 2× schnell S (auf einer Plattform) | 2× schnell Pfeil runter |
| Nach dem Kampf nochmal | R | R |
| Zurück ins Menü | Esc | Esc |

## Angriffe

| Angriff | Schaden | Besonderheit |
|---|---|---|
| Schwach | 4 % | sehr schnell, kaum Rückstoß |
| Stark | 13 % | kurzes Ausholen, schleudert weit |
| Tritt | 8 % | schleudert flach zur Seite |
| Spezial | 9–11 % | je nach Kämpfer, siehe unten |

**Abwehr:** Solange du die Abwehr-Taste hältst, schützt dich eine Blase vor allen Treffern. Sie wird kleiner, je länger du sie hältst und je mehr Treffer sie abfängt. Zerbricht sie, bist du kurz betäubt.

**Ausweichrolle:** Zweimal schnell in eine Richtung tippen (oder beim Abwehren eine Richtung drücken): Die Figur rollt ein Stück in diese Richtung und kann dabei nicht getroffen werden. Danach kurz warten bis zur nächsten Rolle.

**Smash-Angriff:** Den starken Angriff gedrückt halten: Die Figur bleibt in der Ausholbewegung stehen, zittert und sprüht Funken. Je länger (bis 1 Sekunde), desto stärker, voll aufgeladen gibt es 60 % mehr Schaden und Rückstoß. Kurz antippen ist ein normaler starker Schlag.

**Greifen und Werfen:** Abwehren halten und schwach angreifen packt den Gegner, auch wenn er gerade abwehrt. Im Griff: schwacher Angriff schlägt zu, vor/zurück wirft nach vorne oder hinter sich, hoch wirft nach oben, runter nach unten. Wer gepackt ist, kommt durch schnelles Tastendrücken früher frei. Daneben gegriffen: kurz ohne Schild.

**In der Luft:** Abwehren antippen = ausweichen (kurz unverwundbar, einmal pro Sprung). Runter halten = schnell fallen. In der Luft dreht man sich nicht um (wie bei Smash), so gibt es auch einen Angriff nach hinten.

**Richtungs-Angriffe:** Wie bei Smash hängt der Angriff von der gehaltenen Richtung ab. Am Boden: hoch + schwach = Schlag nach oben, runter + schwach = tiefer Schlag, hoch + stark = großer Hieb nach oben, runter + stark = Feger, der vorne und hinten trifft (beide lassen sich wie der Smash-Angriff aufladen). In der Luft mit dem schwachen oder starken Angriff: ohne Richtung oder vorwärts = Tritt nach vorne, zurück = Drehtritt nach hinten, hoch = Uppercut, runter = Schlag nach unten (schleudert den Gegner in die Tiefe, steht er am Boden, prallt er ab).

**Kante:** Wer neben der Bühne herunterfällt, hält sich automatisch an der Kante fest und ist kurz unverwundbar (erst wieder, nachdem man gelandet ist). Nach 2,5 Sekunden lässt man los.

**Spezial aufladen:** Unter den Namen oben zeigt eine Leiste die Spezial-Energie. Sie füllt sich langsam mit der Zeit,
schneller durch eigene Treffer und etwas durch Treffer, die man einsteckt. Erst bei voller Leiste (sie blinkt, über der Figur
steht „Spezial bereit!“) geht die Spezialattacke, danach ist die Leiste wieder leer. In den Optionen lässt sich das ausschalten.

Spezialattacken sind ein Spektakel: großer Schriftzug, kurze Zeitlupe, Lichtblitz und Schockwelle. Trifft eine, friert das Bild kurz ein, die Kamera wackelt und es knallt. Solange die Leiste voll ist, steigen Funken um die Figur auf.

**Spezialattacken:**
- Feuerball (Magierin): fliegt geradeaus.
- Laserkanone (Kampfroboter): lädt kurz im Bauch auf, dann schießt ein Laserstrahl quer über die Arena.
- Sturmangriff (Schurke): schneller Stoß nach vorne.
- Wirbel (Barbar): trifft vorne und hinten.
- Himmelshieb (Held): springt hoch, schlägt nach oben und rettet dich zurück auf die Plattform.
- Lichtschild (Paladin): 1,6 Sekunden unverwundbar in einer Lichtkuppel, dann explodiert sie und schleudert alle in der Nähe weg.
- Erdbeben (Brummbart): kleiner Sprung, dann ein Stampfer, dessen Schockwelle weit über den Boden läuft.
- Schweinezauber (Hexe): grüne Zauberkugel. Wer getroffen wird, ist 3 Sekunden lang ein kleines rosa Schwein:
  kann nur laufen und springen, nicht angreifen oder blocken, und nimmt mehr Schaden.
- Pfeilregen (Jägerin): Ein leuchtender Kreis markiert die Stelle des Gegners, dann regnen Pfeile herab.

## Kämpfer und passive Fähigkeiten

Jeder Kämpfer hat zusätzlich eine passive Fähigkeit, die immer wirkt:

| Kämpfer | Spezial | Passiv |
|---|---|---|
| Barbar | Wirbel | Berserker: je mehr Schaden er hat, desto härter schlägt er (bis +40 %) |
| Magierin | Feuerball | Arkane Quelle: Spezial lädt 60 % schneller |
| Kampfroboter | Laserkanone | Overcharge: entlädt sich alle 7 Sekunden in einem Stromschlag, der Gegner in der Nähe trifft (kurz vorher knistert es blau) |
| Schurke | Sturmangriff | Kritisch: 25 % Chance auf doppelten Schaden |
| Held | Himmelshieb | Heldenmut: ab 80 % Schaden 30 % stärker |
| Paladin | Lichtschild | Heilung: heilt sich langsam, wenn er 3 Sekunden nicht getroffen wird |
| Brummbart | Erdbeben | Schwergewicht: wird 25 % weniger weit geschleudert, trotzt dem Wind, springt etwas niedriger |
| Hexe | Schweinezauber | Gleiten: Sprungtaste in der Luft halten, um langsam zu schweben |
| Jägerin | Pfeilregen | Flink: läuft schneller und springt dreimal |
| Piratin | Breitseite: eine kleine Kanone feuert eine Kugel im Bogen, die explodiert | Plündern: jeder Treffer stiehlt dem Gegner Spezial-Energie |
| Mönch | Hundert Fäuste: sechs blitzschnelle Schläge mit goldenen Faust-Abdrücken, der letzte schleudert weg | Innere Ruhe: wer still steht, meditiert und lädt das Spezial doppelt so schnell |

## Map-Effekte

Jede Map hat ihren eigenen Aufbau (z. B. Wehrturm in der Burg, Marktstand im Dorf, Gruft und Baum auf dem Friedhof,
Ausguck am Mast auf dem Piratenschiff, Spalte in der Eiswelt) und einen eigenen Effekt:


- **Burg**: Kanonenkugeln fliegen quer über die Arena, mal auf Bodenhöhe, mal auf Höhe der Plattformen.
  Ein blinkendes rotes Ausrufezeichen zeigt vorher, von welcher Seite.
- **Dorf**: Windböen schieben alle Kämpfer für ein paar Sekunden zur Seite, in der Luft stärker als am Boden.
  Pfeile kündigen die Richtung an.
- **Friedhof**: weniger Schwerkraft, man springt höher und fliegt weiter. Leuchtende lila Kreise am Boden zeigen,
  wo gleich ein Geist hochschießt und alle darüber nach oben schleudert.
- **Vulkan**: Lavafontänen schießen an glühenden orangen Kreisen aus dem Boden und schleudern alle darüber nach oben.
- **Piratenschiff**: Seegang. Das Schiff schaukelt, und Wellen schieben alle Kämpfer für ein paar Sekunden zur Seite.
- **Eiswelt**: spiegelglatter Boden, man rutscht beim Laufen und Bremsen. Eiszapfen fallen auf die blauen Kreise.
- **Wolkentempel**: Blitze schlagen an gelben Kreisen ein und schleudern alle in der Nähe weg.

## Sound

Jede Map und das Menü haben eigene Musik. Schläge, Treffer, Sprünge, Abwehr, Items und Map-Effekte haben Geräusche.
Ein Ansager zählt „Drei, zwei, eins, Kampf!“ herunter und verkündet den Sieger, die Kämpfer rufen beim Zuschlagen und
Getroffenwerden (der Barbar tiefer, die Hexe höher).

## Items

Wenn Items eingeschaltet sind, fallen sie im Kampf vom Himmel. Berühren reicht:

- **Heiltrank**: 30 % weniger Schaden
- **Goldschwert (Kraft)**: 10 Sekunden lang härter zuschlagen
- **Goldmünzen (Tempo)**: 10 Sekunden lang schneller laufen und höher springen
- **Bombe**: explodiert kurz nach der Berührung und schleudert alle in der Nähe weg

## Starten

1. Godot 4 herunterladen und öffnen.
2. Im Projektmanager auf **Importieren** klicken und `project.godot` wählen.
3. Mit **F5** starten.

## Aufbau

- `scenes/menu.tscn` / `scripts/menu.gd`: Hauptmenü und Optionen.
- `scenes/fight.tscn` / `scripts/fight.gd`: der Kampf mit Kämpferauswahl, Kamera, Anzeige und Items.
- `scenes/maps/`: die drei Maps. Du kannst sie in Godot öffnen und Deko verschieben. Die Kollision steckt in `Stage`, `LeftPlatform` und `RightPlatform`.
- `scenes/player.tscn` / `scripts/player.gd`: ein Kämpfer mit Bewegung, Angriffen, Abwehr und Animationen. Die Werte aller Angriffe stehen oben in `ATTACKS`.
- `scripts/roster.gd`: die Liste aller Kämpfer mit Modell, Waffen, Animationen und Spezialattacke.
- `scripts/item.gd`, `scripts/projectile.gd`: Items und Feuerbälle.
- `scripts/settings.gd`: gespeicherte Einstellungen.
- `assets/`: die 3D-Modelle (alle CC0, siehe `assets/CREDITS.md`).
