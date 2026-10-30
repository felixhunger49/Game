shader_type spatial;
// Feuerschein um den Phönix: nur am Rand sichtbar, addiert sich zum Bild, züngelt nach oben.
render_mode unshaded, blend_add, cull_front, depth_draw_never;

uniform vec4 farbe : source_color = vec4(1.0, 0.35, 0.05, 1.0);
uniform float staerke = 1.2;

void fragment() {
	float rand = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	vec3 welt = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float zunge = 0.6 + 0.4 * sin(welt.y * 9.0 - TIME * 16.0 + welt.x * 4.0);
	ALBEDO = farbe.rgb * staerke * (0.35 + rand) * zunge;
}
