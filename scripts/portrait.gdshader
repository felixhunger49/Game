shader_type canvas_item;
// Rundes Kopfbild mit farbigem Ring (Anzeige im Kampf).

uniform vec4 ring : source_color = vec4(1.0);
uniform vec4 back : source_color = vec4(0.08, 0.09, 0.16, 1.0);
uniform float grey = 0.0;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	vec4 tex = texture(TEXTURE, UV);
	// Hinter dem Kopf ein dunkler Kreis, unten etwas von der Spielerfarbe.
	vec3 bg = mix(back.rgb, ring.rgb * 0.55, smoothstep(0.2, 1.1, UV.y));
	vec3 col = mix(bg, tex.rgb, tex.a);
	col = mix(col, vec3(dot(col, vec3(0.3, 0.6, 0.1))) * 0.6, grey);
	float edge = fwidth(d) * 1.5;
	col = mix(col, ring.rgb, smoothstep(0.86 - edge, 0.86, d));
	col = mix(col, vec3(0.0), smoothstep(0.97 - edge, 0.97, d) * 0.85);
	COLOR = vec4(col, 1.0 - smoothstep(1.0 - edge, 1.0, d));
}
