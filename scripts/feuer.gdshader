shader_type spatial;
// Brennender Vogel: weißgelber Kern, nach außen Orange und tiefes Rot, Flammenbänder laufen über den Körper.
render_mode cull_disabled;

uniform vec4 innen : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 mitte : source_color = vec4(1.0, 0.5, 0.08, 1.0);
uniform vec4 aussen : source_color = vec4(0.75, 0.08, 0.02, 1.0);
uniform float leuchten = 2.2;

void fragment() {
	float rand = 1.0 - abs(dot(NORMAL, VIEW));
	vec3 welt = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float flamme = 0.5 + 0.5 * sin(TIME * 14.0 + welt.x * 5.0 + welt.y * 7.0);
	float f = clamp(rand * 1.1 + flamme * 0.45 - 0.15, 0.0, 1.0);
	vec3 farbe = f < 0.5 ? mix(innen.rgb, mitte.rgb, f * 2.0) : mix(mitte.rgb, aussen.rgb, (f - 0.5) * 2.0);
	ALBEDO = farbe;
	EMISSION = farbe * leuchten * (0.7 + 0.3 * flamme);
	ROUGHNESS = 0.8;
}
