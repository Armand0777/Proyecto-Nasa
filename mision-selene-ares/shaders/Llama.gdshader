shader_type spatial;
// Llama de un motor (un cono que sale hacia abajo desde la tobera): casi blanca junto a la tobera,
// naranja hacia la punta y cada vez más transparente, con bordes suaves, parpadeo y, si se pide,
// «diamantes de choque»: las bandas brillantes que se ven en el escape de los cohetes reales cuando
// el gas sale más rápido que el sonido. Se mezcla (no solo suma luz) para que el naranja se vea
// fuerte también contra el cielo claro de día.
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform float largo = 10.0;  // Largo del cono, para saber qué tan lejos de la tobera está cada punto.
uniform vec4 color_cerca : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform vec4 color_lejos : source_color = vec4(1.0, 0.32, 0.05, 1.0);
uniform float intensidad = 1.0;  // Qué tan opaca es la capa.
uniform float diamantes = 0.0;

varying float t;  // 0 en la tobera, 1 en la punta.

void vertex() {
	t = clamp((largo * 0.5 - VERTEX.y) / largo, 0.0, 1.0);
}

void fragment() {
	float borde = pow(abs(dot(NORMAL, VIEW)), 0.7);
	float parpadeo = 0.85 + 0.15 * sin(TIME * 37.0 + t * 19.0) * sin(TIME * 23.0 + t * 7.0);
	float cola = 1.0 - smoothstep(0.35, 1.0, t);
	float banda = diamantes * smoothstep(0.55, 1.0, sin(t * 26.0 - TIME * 0.5)) * (1.0 - t);
	ALBEDO = mix(color_cerca.rgb, color_lejos.rgb, smoothstep(0.0, 0.75, t)) + vec3(banda * 0.6);
	ALPHA = clamp(cola * borde * parpadeo * intensidad + banda * 0.3, 0.0, 1.0);
}
