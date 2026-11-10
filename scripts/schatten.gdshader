shader_type spatial;
// Schattenkrieger im Ansturm-Modus: der Körper wird fast schwarz, die Ränder glühen in der Farbe der Sorte.
render_mode unshaded, blend_mix, cull_back, depth_draw_never;

uniform vec4 glow : source_color = vec4(0.7, 0.3, 1.0, 1.0);
uniform float dark = 0.82;
uniform float power = 2.2;

void fragment() {
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), power);
	// Leichtes Flackern, das über den Körper nach oben läuft.
	float flicker = 0.85 + 0.15 * sin(TIME * 6.0 + VERTEX.y * 9.0);
	ALBEDO = mix(vec3(0.03, 0.02, 0.07), glow.rgb * 2.4 * flicker, rim);
	ALPHA = mix(dark, 1.0, rim);
}
