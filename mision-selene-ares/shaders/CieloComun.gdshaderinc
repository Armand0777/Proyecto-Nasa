// Funciones compartidas por los cielos de los fondos del menú (Marte, Tierra y Luna).

const vec3 COLOR_OCEANO = vec3(0.16, 0.42, 0.95);
const vec3 COLOR_CONTINENTES = vec3(0.33, 0.52, 0.27);
const vec3 COLOR_LUNA = vec3(0.64, 0.65, 0.68);
const vec3 COLOR_MARES_LUNA = vec3(0.42, 0.43, 0.46);

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float ruido2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash13(vec3(i, 1.0));
	float b = hash13(vec3(i + vec2(1.0, 0.0), 1.0));
	float c = hash13(vec3(i + vec2(0.0, 1.0), 1.0));
	float d = hash13(vec3(i + vec2(1.0, 1.0), 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Ruido con detalle (4 capas), de 0 a casi 1.
float fbm2(vec2 p) {
	float valor = 0.0;
	float peso = 0.5;
	for (int i = 0; i < 4; i++) {
		valor += peso * ruido2(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		peso *= 0.5;
	}
	return valor;
}

// Estrellas que titilan; una densidad cerca de 1 deja pocas estrellas.
float estrellas(vec3 dir, float densidad, float tiempo) {
	vec3 p = dir * 240.0;
	vec3 celda = floor(p);
	float h = hash13(celda);
	vec3 centro = celda + 0.5 + (vec3(hash13(celda + 1.7), hash13(celda + 4.3), hash13(celda + 8.1)) - 0.5) * 0.6;
	float estrella = step(densidad, h) * (1.0 - smoothstep(0.08, 0.32, length(p - centro)));
	return estrella * (0.65 + 0.35 * sin(tiempo * (1.0 + h * 3.0) + h * 50.0));
}

// Planeta o luna en el cielo: color en .rgb y cuánto tapa en .a.
// «manchas» pinta continentes (Tierra) o mares oscuros (Luna); «nubosidad» agrega nubes blancas.
vec4 planeta(vec3 dir, vec3 centro, float radio, vec3 sol, vec3 color_base, vec3 color_manchas,
		float manchas, float nubosidad, float tiempo) {
	if (dot(dir, centro) < cos(radio * 1.2)) {
		return vec4(0.0);
	}
	vec3 derecha = normalize(cross(centro, vec3(0.0, 1.0, 0.0)));
	vec3 arriba = cross(derecha, centro);
	vec2 uv = vec2(dot(dir, derecha), dot(dir, arriba)) / sin(radio);
	float r2 = dot(uv, uv);
	float cobertura = 1.0 - smoothstep(0.8, 1.0, r2);
	vec3 normal = derecha * uv.x + arriba * uv.y - centro * sqrt(max(1.0 - r2, 0.0));
	// Fase gibosa: la luz viene del lado del Sol y un poco desde nuestro lado,
	// así se ve casi toda la cara iluminada.
	vec3 hacia_sol = normalize(sol - centro * dot(sol, centro) + vec3(0.0, 0.0001, 0.0));
	vec3 luz_dir = normalize(hacia_sol - centro * 0.6);
	float luz = clamp(dot(normal, luz_dir) * 0.85 + 0.2, 0.12, 1.0);
	// La superficie gira despacio y las nubes un poco más rápido.
	float mancha = smoothstep(0.5, 0.58, fbm2(uv * 1.6 + vec2(tiempo * 0.01, 3.0))) * manchas;
	float nubes = smoothstep(0.6, 0.85, ruido2(uv * 3.0 + vec2(tiempo * 0.02, 0.0))) * nubosidad;
	vec3 color = mix(mix(color_base, color_manchas, mancha), vec3(1.0), nubes) * luz;
	return vec4(color, cobertura);
}
