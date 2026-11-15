shader_type spatial;
render_mode diffuse_burley, specular_disabled;
// Suelo de la Luna con textura propia (las texturas de ruido se crean en FondoLuna.gd):
// - manchas grandes más oscuras, como los «mares» de basalto que se ven desde la Tierra;
// - variación mediana y granos finos de regolito (el polvo y las piedritas del suelo).
// La luz es suave (normales suavizadas en el terreno): no se ven facetas ni «píxeles».

uniform sampler2D manchas : filter_linear_mipmap, repeat_enable;
uniform sampler2D grano : filter_linear_mipmap, repeat_enable;
uniform vec3 claro : source_color = vec3(0.7, 0.71, 0.73);
uniform vec3 oscuro : source_color = vec3(0.38, 0.39, 0.41);

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float grande = texture(manchas, mundo.xz * 0.004).r;
	float mediano = texture(grano, mundo.xz * 0.05).r;
	float fino = texture(grano, mundo.xz * 0.45).r;
	vec3 color = mix(oscuro, claro, smoothstep(0.32, 0.68, grande));
	color *= 0.86 + 0.24 * mediano;
	color *= 0.93 + 0.14 * fino;
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
