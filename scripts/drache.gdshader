shader_type spatial;
// Chinesischer Drache: rote Rückenschuppen, goldener Bauch mit Querstreifen, leichter Eigenschein.
// UV.x läuft vom Kopf zum Schwanz, UV.y einmal um den Körper (0.5 = Bauch).
render_mode cull_disabled;

uniform vec4 ruecken : source_color = vec4(0.78, 0.07, 0.04, 1.0);
uniform vec4 kante : source_color = vec4(0.35, 0.02, 0.02, 1.0);
uniform vec4 bauch : source_color = vec4(1.0, 0.78, 0.25, 1.0);
uniform float laenge = 60.0;
uniform float leuchten = 0.35;
// Gemalte Flux-Texturen (wenn vorhanden): Schuppen für den Rücken, Platten für den Bauch, je mit Normal-Map.
uniform bool texturen = false;
uniform sampler2D schuppen_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D schuppen_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D bauch_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D bauch_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec2 kacheln = vec2(12.0, 4.0);

void fragment() {
	float um = UV.y;
	// Schuppen: versetzte Halbkreise.
	float reihe = floor(UV.x * laenge);
	vec2 zelle = vec2(fract(UV.x * laenge), fract(um * 12.0 + mod(reihe, 2.0) * 0.5));
	float schuppe = length(vec2(zelle.x, (zelle.y - 0.5) * 1.3));
	float rand_s = smoothstep(0.75, 1.0, schuppe);
	vec3 farbe = mix(ruecken.rgb, kante.rgb, rand_s);
	// Glanz oben auf jeder Schuppe.
	farbe += vec3(1.0, 0.55, 0.2) * (1.0 - smoothstep(0.0, 0.45, schuppe)) * 0.18;
	// Bauch: goldene Platten mit dunklen Fugen.
	float b = 1.0 - smoothstep(0.13, 0.19, abs(um - 0.5));
	float platte = smoothstep(0.0, 0.12, fract(UV.x * laenge * 0.5)) * 0.35 + 0.65;
	farbe = mix(farbe, bauch.rgb * platte, b);
	// Goldener Saum zwischen Rücken und Bauch.
	float saum = 1.0 - smoothstep(0.0, 0.025, abs(abs(um - 0.5) - 0.2));
	farbe = mix(farbe, vec3(1.0, 0.85, 0.35), saum);
	if (texturen) {
		vec2 uv = UV * kacheln;
		vec3 s_farbe = texture(schuppen_tex, uv).rgb;
		vec3 b_farbe = texture(bauch_tex, vec2(UV.x * kacheln.x * 2.0, (um - 0.5) * 3.0 + 0.5)).rgb;
		farbe = mix(s_farbe, b_farbe, b);
		farbe = mix(farbe, vec3(1.0, 0.85, 0.35), saum * 0.6);
		vec3 n1 = texture(schuppen_n, uv).rgb;
		vec3 n2 = texture(bauch_n, vec2(UV.x * kacheln.x * 2.0, (um - 0.5) * 3.0 + 0.5)).rgb;
		NORMAL_MAP = mix(n1, n2, b);
		NORMAL_MAP_DEPTH = 1.5;
	}
	ALBEDO = farbe;
	ROUGHNESS = mix(0.35, 0.5, b);
	METALLIC = mix(0.25, 0.6, b);
	EMISSION = farbe * leuchten;
}
