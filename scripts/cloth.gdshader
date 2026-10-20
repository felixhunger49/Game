shader_type spatial;
// Stoff, Hutspitzen und Haare, die im Fallwind flattern.
// Wie stark sich ein Punkt bewegt, steht im Rot-Kanal der Vertex-Farbe (in Blender eingebacken):
// 0 = fest (z. B. am Hals), 1 = flattert voll (z. B. der untere Rand des Umhangs).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform float roughness_value = 0.75;
// 0..1: wie schnell die Figur fällt (Wind von unten)
uniform float fall_wind = 0.0;
// 0..1: wie schnell die Figur läuft oder fliegt (Wind von vorne)
uniform float run_wind = 0.0;

void vertex() {
	float w = COLOR.r;
	float t = TIME;
	float wave = sin(t * 17.0 + VERTEX.y * 7.0 + VERTEX.x * 3.0);
	float wave2 = sin(t * 11.0 + VERTEX.x * 6.0 + VERTEX.z * 2.0);
	float wind = clamp(fall_wind + run_wind * 0.6, 0.0, 1.0);
	// Fallwind drückt den Stoff nach oben, Laufwind nach hinten (die Figuren schauen nach +Z).
	VERTEX.y += fall_wind * w * (0.32 + 0.07 * wave);
	VERTEX.z -= (fall_wind * 0.22 + run_wind * 0.3) * w;
	// Flattern
	VERTEX.x += wind * w * 0.07 * wave2;
	VERTEX.z += wind * w * 0.06 * wave;
	// Ein ganz leichtes Wehen auch im Stand
	VERTEX.x += w * 0.012 * sin(t * 2.3 + VERTEX.y * 3.0);
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = roughness_value;
}
