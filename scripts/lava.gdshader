shader_type spatial;
// Fließende, pulsierende Lava. Mit Textur (optional), sonst nur aus Rauschen berechnet.

uniform sampler2D lava_texture : source_color, hint_default_white;
uniform bool use_texture = false;
uniform vec3 hot_color : source_color = vec3(1.0, 0.75, 0.15);
uniform vec3 cool_color : source_color = vec3(0.55, 0.08, 0.02);
uniform float glow = 3.0;
uniform float flow_speed = 0.06;
uniform float tiling = 0.15;
// true: Lava fließt nach oben (Fontänen), sonst seitlich über eine Fläche.
uniform bool vertical = false;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise(p); p *= 2.1; a *= 0.5; }
	return v;
}

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = vertical ? vec2(world_pos.x + world_pos.z, world_pos.y - TIME * flow_speed * 40.0) * tiling
		: world_pos.xz * tiling + vec2(TIME * flow_speed, TIME * flow_speed * 0.4);
	float n = fbm(p * 3.0 + fbm(p * 2.0 - TIME * 0.05));
	float pulse = 0.85 + 0.15 * sin(TIME * 1.7 + n * 6.0);
	vec3 col = mix(cool_color, hot_color, smoothstep(0.35, 0.75, n));
	if (use_texture) {
		col *= texture(lava_texture, p).rgb * 1.6;
	}
	ALBEDO = col * 0.4;
	EMISSION = col * glow * pulse;
	ROUGHNESS = 0.6;
}
