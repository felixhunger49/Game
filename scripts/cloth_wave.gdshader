shader_type spatial;
render_mode cull_disabled;
// Wehender Stoff (Fahnen, Segel, Banner). Die Kante bei UV.x = 0 bleibt fest (am Mast/an der Stange),
// zur anderen Seite hin weht der Stoff immer stärker.

uniform sampler2D cloth_texture : source_color, hint_default_white;
uniform vec3 color : source_color = vec3(1.0);
uniform float strength = 0.25;
uniform float speed = 3.0;
uniform float ripples = 6.0;
// 0 = fest an der linken Kante (Fahne), 1 = fest an der oberen Kante (Segel, Banner).
uniform float pin_top = 0.0;

void vertex() {
	float along = mix(UV.x, UV.y, pin_top);
	float wave = sin(along * ripples - TIME * speed + UV.y * 2.0) * 0.6 + sin(along * ripples * 0.5 - TIME * speed * 0.7) * 0.4;
	VERTEX.z += wave * strength * along;
}

void fragment() {
	ALBEDO = texture(cloth_texture, UV).rgb * color;
	ROUGHNESS = 0.9;
}
