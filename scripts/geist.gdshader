shader_type spatial;
// Geisterwolf: dunkelblauer, halb durchsichtiger Kern, heller Schimmer am Rand, Nebelstreifen ziehen nach hinten.
render_mode unshaded, blend_mix, cull_back, depth_draw_never;

uniform vec4 farbe : source_color = vec4(0.15, 0.55, 1.0, 1.0);
uniform float staerke = 1.6;

void fragment() {
	float rand = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	vec3 welt = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float nebel = 0.5 + 0.5 * sin(welt.x * 5.0 + welt.y * 3.0 + TIME * 8.0);
	float flackern = 0.9 + 0.1 * sin(TIME * 11.0 + welt.y * 4.0);
	vec3 kern = farbe.rgb * 0.55;
	vec3 schimmer = mix(farbe.rgb, vec3(0.85, 0.97, 1.0), 0.55) * staerke;
	ALBEDO = mix(kern, schimmer, clamp(rand + nebel * 0.2, 0.0, 1.0)) * flackern;
	ALPHA = clamp(0.4 + rand * 0.6 + nebel * 0.1, 0.0, 0.95);
}
