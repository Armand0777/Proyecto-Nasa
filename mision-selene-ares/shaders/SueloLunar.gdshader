shader_type spatial;
render_mode diffuse_burley, specular_disabled;
// Suelo de la Luna (el terreno y la Luna redonda del alunizaje usan el mismo, así no se nota dónde
// termina uno y empieza la otra):
// - «mares» de basalto oscuro muy grandes y manchas medianas (texturas de ruido de FondoLuna.gd);
// - cráteres con relieve de verdad en tres tamaños (texturas/crateres_luna.res, que arma
//   herramientas/generar_crateres.gd): de cientos de metros, de decenas y de pocos metros. El
//   relieve inclina la luz, así con el Sol bajo del Polo Sur cada cráter tiene su lado en sombra;
//   los bordes son más claros (material nuevo, recién expulsado) y los fondos más oscuros;
// - granos finos de regolito (el polvo y las piedritas) que solo se ven de cerca.
// Cada tamaño va girado y con otra escala: así no se ve el dibujo repetido en cuadrícula.
// En las paredes empinadas se pinta desde el costado (no se estira la textura).

uniform sampler2D manchas : filter_linear_mipmap, repeat_enable;
uniform sampler2D grano : filter_linear_mipmap, repeat_enable;
uniform sampler2D crateres : filter_linear_mipmap, repeat_enable;
uniform vec3 claro : source_color = vec3(0.68, 0.68, 0.69);
uniform vec3 oscuro : source_color = vec3(0.3, 0.3, 0.32);
uniform float relieve = 0.55;

varying vec3 mundo;
varying vec3 normal_mundo;

vec2 girar(vec2 p, float angulo) {
	float c = cos(angulo);
	float s = sin(angulo);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Inclinación (en x, z del mundo) y altura de los cráteres de un tamaño; «lado» = metros por imagen.
vec3 crater(vec2 p, float lado, float angulo) {
	vec4 m = texture(crateres, girar(p, angulo) / lado);
	vec2 inclinacion = (m.rg * 2.0 - 1.0) / max(m.b, 0.2);
	return vec3(girar(inclinacion, -angulo), m.a);
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float distancia = length(mundo - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	vec2 p = mundo.xz;
	// En las paredes empinadas, la textura se lee desde el costado.
	float empinado = smoothstep(0.55, 0.25, abs(normal_mundo.y));
	vec2 lateral = abs(normal_mundo.x) > abs(normal_mundo.z) ? mundo.zy : mundo.xy;
	p = mix(p, lateral, empinado);

	float mar = texture(manchas, girar(p, 0.7) / 14000.0).r;
	float mancha = texture(manchas, girar(p, 2.1) / 900.0).r;
	vec3 color = mix(oscuro, claro, smoothstep(0.35, 0.62, mar) * 0.75 + 0.25);
	color *= 0.84 + 0.3 * mancha;

	vec3 grande = crater(p, 8000.0, 0.3);
	vec3 medio = crater(p, 610.0, 1.9);
	vec3 chico = crater(p, 47.0, 4.0);
	// Lo chico se apaga de lejos (si no, de lejos se ve como un patrón de puntos).
	float ver_medio = 1.0 - smoothstep(1500.0, 6000.0, distancia);
	float ver_chico = 1.0 - smoothstep(60.0, 260.0, distancia);
	vec2 inclinacion = grande.xy * 0.8 + medio.xy * 0.55 * ver_medio + chico.xy * 0.5 * ver_chico;
	float borde = (grande.z - 0.55) + (medio.z - 0.55) * ver_medio + (chico.z - 0.55) * 0.6 * ver_chico;
	color *= 1.0 + clamp(borde, -0.5, 0.6) * 0.3;

	float fino = texture(grano, p * 0.45).r;
	float mediano = texture(grano, girar(p, 1.2) * 0.07).r;
	color *= mix(1.0, 0.9 + 0.2 * fino, 1.0 - smoothstep(20.0, 90.0, distancia));
	color *= mix(1.0, 0.9 + 0.2 * mediano, 1.0 - smoothstep(150.0, 700.0, distancia));

	vec3 n = normalize(normal_mundo + vec3(inclinacion.x, 0.0, inclinacion.y) * relieve * (1.0 - empinado));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
