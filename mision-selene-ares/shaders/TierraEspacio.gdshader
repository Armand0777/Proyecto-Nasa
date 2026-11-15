shader_type spatial;
render_mode unshaded, cull_back;
// La Tierra vista desde el espacio (despegue, órbita y viaje a la Luna), con luz propia del Sol:
// - océanos azul profundo con el brillo del Sol reflejado (como en las fotos de la NASA);
// - continentes verdes, pardos y desiertos, y casquetes de hielo en los polos;
// - nubes blancas que se mueven despacio;
// - lado de noche oscuro con luces de ciudades, y el amanecer anaranjado en el borde día-noche;
// - el borde azul de la atmósfera (el halo de afuera lo dibuja AtmosferaTierra.gdshader).
// Las texturas de ruido se crean por código (Cabina.gd). Se leen con la dirección desde el centro
// (triplanar): así no hay costuras ni polos estirados.

uniform sampler2D continentes : filter_linear_mipmap, repeat_enable;
uniform sampler2D nubes : filter_linear_mipmap, repeat_enable;
uniform vec3 direccion_sol = vec3(0.0, 0.5, 0.86);  // Hacia el Sol, en el mundo.
uniform vec3 oceano_hondo : source_color = vec3(0.01, 0.045, 0.16);
uniform vec3 oceano_costa : source_color = vec3(0.03, 0.2, 0.36);
uniform vec3 verde : source_color = vec3(0.13, 0.27, 0.09);
uniform vec3 pardo : source_color = vec3(0.36, 0.31, 0.18);
uniform vec3 desierto : source_color = vec3(0.74, 0.6, 0.39);
uniform vec3 atmosfera : source_color = vec3(0.32, 0.6, 1.0);

varying vec3 dir_local;

void vertex() {
	dir_local = normalize(VERTEX);
}

float triplanar(sampler2D textura, vec3 p, vec3 pesos) {
	return texture(textura, p.yz).r * pesos.x + texture(textura, p.zx).r * pesos.y + texture(textura, p.xy).r * pesos.z;
}

void fragment() {
	vec3 d = normalize(dir_local);
	vec3 pesos = pow(abs(d), vec3(6.0));
	pesos /= (pesos.x + pesos.y + pesos.z);

	// Superficie: océano, costa, tierra firme y hielo.
	float n = triplanar(continentes, d * 0.8 + vec3(0.3, 0.1, 0.7), pesos);
	float detalle = triplanar(continentes, d * 3.1, pesos);
	n += (detalle - 0.5) * 0.18;
	float tierra = smoothstep(0.545, 0.565, n);
	float costa = smoothstep(0.47, 0.55, n);
	vec3 agua = mix(oceano_hondo, oceano_costa, costa * costa);
	float clima = triplanar(nubes, d * 0.7 + vec3(5.0, 2.0, 1.0), pesos);
	vec3 suelo = mix(verde, pardo, smoothstep(0.42, 0.62, clima + (detalle - 0.5) * 0.4));
	suelo = mix(suelo, desierto, smoothstep(0.6, 0.75, clima) * (1.0 - abs(d.y)));
	suelo *= 0.85 + 0.3 * detalle;
	float latitud = abs(d.y) + (detalle - 0.5) * 0.12;
	float hielo = smoothstep(0.8, 0.86, latitud);
	vec3 color = mix(agua, suelo, tierra);
	color = mix(color, vec3(0.92, 0.95, 1.0), hielo);

	// Nubes: giran un poco más rápido que la Tierra.
	float giro = TIME * 0.004;
	vec3 dn = vec3(d.x * cos(giro) - d.z * sin(giro), d.y, d.x * sin(giro) + d.z * cos(giro));
	vec3 pesos_n = pow(abs(dn), vec3(6.0));
	pesos_n /= (pesos_n.x + pesos_n.y + pesos_n.z);
	float c = triplanar(nubes, dn * 2.2, pesos_n);
	c += (triplanar(nubes, dn * 7.0, pesos_n) - 0.5) * 0.35;
	float nube = smoothstep(0.5, 0.7, c) * 0.92;

	// Luz del Sol (el lado de noche queda oscuro, con un borde suave).
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 vista = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 sol = normalize(direccion_sol);
	float luz = dot(normal, sol);
	float dia = smoothstep(-0.08, 0.3, luz);
	float difusa = clamp(luz, 0.0, 1.0) * 0.95 + 0.03;
	vec3 iluminado = mix(color, vec3(1.0), nube) * difusa;
	// Reflejo del Sol en el mar (solo donde no hay nubes ni tierra).
	float brillo = pow(max(dot(reflect(-sol, normal), vista), 0.0), 70.0);
	iluminado += vec3(1.0, 0.92, 0.75) * brillo * (1.0 - tierra) * (1.0 - nube) * 0.9 * dia;
	// Amanecer: una franja anaranjada en el borde entre el día y la noche.
	iluminado += vec3(1.0, 0.42, 0.12) * exp(-pow(luz / 0.07, 2.0)) * 0.12;
	// Luces de las ciudades en la noche.
	float ciudades = smoothstep(0.62, 0.8, triplanar(nubes, d * 9.0, pesos)) * tierra * (1.0 - hielo);
	iluminado += vec3(1.0, 0.72, 0.35) * ciudades * (1.0 - dia) * (1.0 - nube) * 0.55;
	// La atmósfera se nota más en los bordes (se mira a través de más aire).
	float borde = pow(1.0 - clamp(dot(normal, vista), 0.0, 1.0), 2.5);
	iluminado = mix(iluminado, atmosfera * (0.25 + 0.75 * dia), borde * 0.65 * smoothstep(-0.25, 0.2, luz));
	iluminado += atmosfera * 0.05 * dia;
	ALBEDO = iluminado;
}
