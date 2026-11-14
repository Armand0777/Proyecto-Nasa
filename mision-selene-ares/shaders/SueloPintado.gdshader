shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Suelo de la pradera "pintado a mano" (estilo Ghibli): manchas grandes de verdes claros y oscuros,
// zonas amarillentas al sol y pinceladas alargadas. Las texturas de ruido se crean por código
// (FondoTierra.gd). Donde el terreno tiene tierra (color del vértice), la tierra se sigue viendo.

uniform sampler2D manchas : filter_linear_mipmap, repeat_enable;
uniform sampler2D pinceladas : filter_linear_mipmap, repeat_enable;
uniform vec3 verde_claro : source_color = vec3(0.56, 0.8, 0.3);
uniform vec3 verde_oscuro : source_color = vec3(0.2, 0.5, 0.22);
uniform vec3 amarillo : source_color = vec3(0.86, 0.85, 0.4);

varying vec3 mundo;

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = COLOR.rgb * COLOR.rgb;  // Color del vértice (sRGB a casi lineal).
	float grande = texture(manchas, mundo.xz * 0.012).r;
	float trazo = texture(pinceladas, mundo.xz * vec2(0.08, 0.26)).r;
	vec3 color = mix(verde_oscuro, verde_claro, smoothstep(0.32, 0.68, grande));
	color = mix(color, amarillo, smoothstep(0.7, 0.86, grande) * 0.55);
	color *= 0.86 + 0.28 * trazo;
	// Donde el vértice es más café que verde (caminos de tierra), gana la tierra.
	float tierra = smoothstep(0.02, 0.1, base.r - base.g * 0.8);
	ALBEDO = mix(color, base * 1.2, tierra);
	ROUGHNESS = 1.0;
}
