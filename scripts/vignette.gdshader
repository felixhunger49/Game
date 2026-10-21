shader_type canvas_item;
// Dunkelt die Bildränder leicht ab (lenkt den Blick zur Mitte).

uniform float strength = 0.35;
uniform vec3 tint : source_color = vec3(0.0);

void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.35, 0.85, length(d * vec2(1.0, 1.25)));
	COLOR = vec4(tint, v * strength);
}
