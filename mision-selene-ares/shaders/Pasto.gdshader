shader_type spatial;
render_mode cull_disabled;
// Pasto y flores de la pradera: se mecen con el viento (más arriba, más se mueven).
// El color sale de los vértices (oscuro abajo, claro en la punta) por el color de cada mata.

uniform float fuerza = 0.09;

void vertex() {
	vec3 mundo = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float altura = VERTEX.y;
	VERTEX.x += sin(TIME * 1.7 + mundo.x * 0.35 + mundo.z * 0.2) * fuerza * altura;
	VERTEX.z += cos(TIME * 1.3 + mundo.x * 0.2 - mundo.z * 0.3) * fuerza * 0.6 * altura;
}

void fragment() {
	// Los colores de vértice vienen en sRGB: al cuadrado quedan casi en lineal.
	ALBEDO = COLOR.rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
}
