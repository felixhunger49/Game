shader_type spatial;
// Meer mit Wellen (Vertex-Bewegung), heller Gischt auf den Wellenkämmen und Glanz.

uniform vec3 deep_color : source_color = vec3(0.03, 0.22, 0.4);
uniform vec3 shallow_color : source_color = vec3(0.1, 0.55, 0.7);
uniform vec3 foam_color : source_color = vec3(0.95, 0.98, 1.0);
uniform float wave_height = 0.35;
uniform float wave_speed = 1.2;

varying float crest;

float waves(vec2 p, float t) {
	return sin(p.x * 0.35 + t) * 0.5 + sin(p.y * 0.5 + t * 1.3) * 0.3 + sin((p.x + p.y) * 0.9 + t * 1.7) * 0.2;
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = waves(w.xz, TIME * wave_speed);
	VERTEX.y += h * wave_height;
	crest = h;
	// Normale aus der Steigung der Wellen.
	float e = 0.5;
	float hx = waves(w.xz + vec2(e, 0.0), TIME * wave_speed) - h;
	float hz = waves(w.xz + vec2(0.0, e), TIME * wave_speed) - h;
	NORMAL = normalize(vec3(-hx * wave_height / e, 1.0, -hz * wave_height / e));
}

void fragment() {
	vec3 col = mix(deep_color, shallow_color, smoothstep(-0.6, 0.8, crest));
	col = mix(col, foam_color, smoothstep(0.75, 1.0, crest));
	ALBEDO = col;
	ROUGHNESS = 0.08;
	METALLIC = 0.1;
	SPECULAR = 0.8;
}
