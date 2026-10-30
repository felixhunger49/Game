shader_type spatial;
// Geisterhaft leuchtend: innen fast durchsichtig, am Rand hell (wie ein Schimmer), leicht flackernd.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform vec4 farbe : source_color = vec4(0.15, 0.55, 1.0, 1.0);
uniform float staerke = 1.6;

void fragment() {
	float rand = 1.0 - abs(dot(NORMAL, VIEW));
	float flackern = 0.85 + 0.15 * sin(TIME * 9.0 + VERTEX.x * 3.0);
	float a = (0.3 + pow(rand, 1.5) * 1.0) * flackern;
	ALBEDO = farbe.rgb * staerke * a;
	ALPHA = clamp(a, 0.0, 1.0);
}
