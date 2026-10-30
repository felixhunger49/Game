shader_type spatial;
// Brennender Vogel: Farbe läuft von Gelb (Körper) nach Rot (Ränder), flackert und leuchtet von selbst.
render_mode cull_disabled;

uniform vec4 innen : source_color = vec4(1.0, 0.85, 0.3, 1.0);
uniform vec4 aussen : source_color = vec4(1.0, 0.25, 0.05, 1.0);
uniform float leuchten = 2.2;

void fragment() {
	float rand = 1.0 - abs(dot(NORMAL, VIEW));
	float flamme = 0.5 + 0.5 * sin(TIME * 14.0 + VERTEX.x * 6.0 + VERTEX.y * 4.0);
	vec3 farbe = mix(innen.rgb, aussen.rgb, clamp(rand * 1.2 + flamme * 0.25, 0.0, 1.0));
	ALBEDO = farbe;
	EMISSION = farbe * leuchten * (0.75 + 0.25 * flamme);
	ROUGHNESS = 0.8;
}
