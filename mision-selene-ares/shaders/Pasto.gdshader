shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled, world_vertex_coords;
// Pasto y flores de la pradera.
// - Viento en olas: ráfagas que cruzan la pradera (se ven avanzar) y un temblor suave.
// - Se aparta al pasar el jugador o A.R.T.I. (sus posiciones las manda FondoTierra.actualizar_pasto).
// - El color sale de los vértices (oscuro abajo, claro en la punta) por el tono de cada mata;
//   la ráfaga aclara un poco las puntas, como cuando el viento da vuelta las hojas.

uniform vec3 jugador = vec3(0.0, -1000.0, 0.0);
uniform vec3 arti = vec3(0.0, -1000.0, 0.0);
uniform float fuerza = 0.12;
uniform vec2 direccion_viento = vec2(0.8, 0.6);

varying float brillo;

// Hacia dónde y cuánto se aparta una mata con raíz en «raiz» de alguien parado en «quien».
vec2 apartar(vec3 quien, vec3 raiz, float radio) {
	vec2 d = raiz.xz - quien.xz;
	float distancia = length(d);
	if (distancia > radio || abs(quien.y - raiz.y) > 2.5) {
		return vec2(0.0);
	}
	return normalize(d + vec2(0.0001)) * (1.0 - distancia / radio);
}

void vertex() {
	vec3 raiz = MODEL_MATRIX[3].xyz;
	float altura = max(VERTEX.y - raiz.y, 0.0);
	float ola = sin(dot(raiz.xz, direccion_viento) * 0.12 - TIME * 1.8) * 0.5 + 0.5;
	ola *= ola;
	float temblor = sin(TIME * 3.1 + raiz.x * 1.7 + raiz.z * 1.3) * 0.25;
	vec2 viento = direccion_viento * (0.3 + ola + temblor) * fuerza;
	vec2 empuje = apartar(jugador, raiz, 1.3) + apartar(arti, raiz, 1.0);
	VERTEX.xz += (viento + empuje * 0.35) * altura * 2.5;
	VERTEX.y -= length(empuje) * altura * 0.45;
	brillo = ola * 0.12;
}

void fragment() {
	// Los colores vienen en sRGB: al cuadrado quedan casi en lineal.
	ALBEDO = COLOR.rgb * COLOR.rgb * (1.0 + brillo);
	ROUGHNESS = 1.0;
}
