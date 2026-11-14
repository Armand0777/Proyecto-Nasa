shader_type spatial;
// Paredes, pisos y techos de los interiores de la Tierra, para que ninguna superficie quede lisa:
// paneles con juntas y un tono apenas distinto cada uno, zócalo oscuro, una franja azul a media
// altura y sombra junto al piso (como la que se junta en las esquinas). Se dibuja en coordenadas del
// mundo, así que sirve para cualquier caja sin preparar nada. El color base es el de los vértices.
render_mode diffuse_burley, specular_disabled, cull_disabled;

uniform float piso = 0.6;                 // Altura del piso en el mundo (hangar y laboratorio).
uniform vec2 panel = vec2(1.6, 1.2);      // Ancho y alto de cada panel de pared.
uniform float baldosa = 1.0;              // Lado de cada baldosa del piso.
uniform vec3 color_zocalo : source_color = vec3(0.2, 0.22, 0.26);
uniform vec3 color_franja : source_color = vec3(0.043, 0.239, 0.569);  // Azul NASA.
uniform float alto_franja = 1.1;          // Centro de la franja sobre el piso; negativo = sin franja.

varying vec3 pos_mundo;
varying vec3 normal_mundo;

float azar(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// 1 sobre la junta entre paneles y 0 lejos de ella. «grosor» en metros.
float junta(vec2 p, vec2 celda, float grosor) {
	vec2 f = fract(p / celda) * celda;
	vec2 d = min(f, celda - f);
	return 1.0 - smoothstep(grosor * 0.5, grosor, min(d.x, d.y));
}

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 color = COLOR.rgb;  // Godot ya lo entrega en espacio lineal: convertirlo otra vez dejaba el piso negro.
	vec3 n = abs(normal_mundo);
	float alto = pos_mundo.y - piso;
	if (n.y > 0.7) {
		// Piso (baldosas) o techo (paneles grandes).
		float lado = normal_mundo.y > 0.0 ? baldosa : panel.x;
		vec2 p = pos_mundo.xz;
		color *= 0.93 + 0.1 * azar(floor(p / lado));
		color *= 1.0 - 0.25 * junta(p, vec2(lado), 0.02);
	} else {
		vec2 p = vec2(n.x > n.z ? pos_mundo.z : pos_mundo.x, alto);
		color *= 0.94 + 0.08 * azar(floor(p / panel));
		color *= 1.0 - 0.3 * junta(p, panel, 0.025);
		if (alto_franja > 0.0 && abs(alto - alto_franja) < 0.06) {
			color = color_franja;
		}
		if (alto < 0.15) {
			color = color_zocalo;
		}
		color *= mix(0.55, 1.0, smoothstep(0.0, 0.9, alto));  // Sombra junto al piso.
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
