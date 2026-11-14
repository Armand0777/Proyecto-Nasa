shader_type sky;

#include "res://shaders/CieloComun.gdshaderinc"

// Cielo de la Tierra de día: azul, con nubes que avanzan con el viento y la Luna pálida
// (el primer destino de la misión).

uniform vec3 color_horizonte : source_color = vec3(0.78, 0.88, 0.97);
uniform vec3 color_cenit : source_color = vec3(0.24, 0.50, 0.86);
uniform vec3 color_suelo : source_color = vec3(0.36, 0.45, 0.33);
uniform vec3 direccion_luna = vec3(0.557, 0.5, -0.663);
uniform float radio_luna = 0.025;
uniform float cantidad_nubes : hint_range(0.0, 1.0) = 0.5;

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sol = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(-0.55, 0.53, 0.65));
	float altura = dir.y;
	vec3 color = mix(color_horizonte, color_cenit, pow(clamp(altura, 0.0, 1.0), 0.6));

	// Brillo y disco del Sol.
	float cerca_sol = max(dot(dir, sol), 0.0);
	color += vec3(1.0, 0.9, 0.7) * pow(cerca_sol, 12.0) * 0.4;
	float ang_sol = acos(clamp(dot(dir, sol), -1.0, 1.0));
	color += vec3(1.0, 0.97, 0.9) * (1.0 - smoothstep(0.012, 0.016, ang_sol)) * 3.0;

	if (!AT_CUBEMAP_PASS) {
		// La Luna de día, pálida.
		vec4 l = planeta(dir, normalize(direccion_luna), radio_luna, sol, COLOR_LUNA * 1.3, COLOR_MARES_LUNA * 1.3, 1.0, 0.0, 0.0);
		color = mix(color, l.rgb, l.a * 0.7);

		// Nubes: se dibujan sobre un techo plano y se mueven con el viento.
		if (altura > 0.01) {
			vec2 p = dir.xz / altura * 0.6 + vec2(TIME * 0.006, 0.0);
			float n = fbm2(p * 1.4);
			float nubes = smoothstep(1.0 - cantidad_nubes, 1.15 - cantidad_nubes * 0.8, n) * smoothstep(0.01, 0.15, altura);
			vec3 color_nube = mix(vec3(0.82, 0.86, 0.92), vec3(1.0), clamp(n * 1.2, 0.0, 1.0));
			color = mix(color, color_nube, nubes * 0.9);
		}
	}

	// Bruma en el horizonte y suelo a lo lejos.
	color = mix(color, color_horizonte, exp(-abs(altura) * 14.0) * 0.5);
	if (altura < 0.0) {
		color = mix(color, color_suelo, smoothstep(0.0, 0.15, -altura));
	}
	COLOR = color;
}
