shader_type sky;

#include "res://shaders/CieloComun.gdshaderinc"

// Cielo de Marte al atardecer.
// Datos reales: de día el cielo de Marte es color caramelo y al atardecer se ve azul cerca del Sol.
// Desde Marte, la Tierra y la Luna se ven como un lucero de la tarde; aquí se dibujan más grandes
// para que se reconozcan.

uniform vec3 color_horizonte : source_color = vec3(0.851, 0.627, 0.400);
uniform vec3 color_cenit : source_color = vec3(0.110, 0.094, 0.200);
uniform vec3 color_atardecer : source_color = vec3(0.435, 0.659, 0.863);
uniform vec3 color_suelo : source_color = vec3(0.431, 0.165, 0.102);
uniform vec3 direccion_tierra = vec3(0.25, 0.36, -1.0);
uniform float radio_tierra = 0.035;
uniform float densidad_estrellas : hint_range(0.95, 0.999) = 0.988;

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sol = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(0.68, 0.14, -0.72));
	float altura = dir.y;

	// Degradado del crepúsculo: caramelo en el horizonte y oscuro hacia arriba.
	vec3 color = mix(color_horizonte, color_cenit, pow(clamp(altura, 0.0, 1.0), 0.5));

	// Brillo azul alrededor del Sol y el disco del Sol.
	float cerca_sol = max(dot(dir, sol), 0.0);
	color = mix(color, color_atardecer, pow(cerca_sol, 8.0) * 0.9);
	float ang_sol = acos(clamp(dot(dir, sol), -1.0, 1.0));
	color += vec3(1.0, 0.96, 0.88) * (1.0 - smoothstep(0.010, 0.013, ang_sol)) * 2.0;

	if (!AT_CUBEMAP_PASS) {
		// Estrellas solo arriba y lejos del brillo del Sol.
		float oscuro = smoothstep(0.08, 0.45, altura) * (1.0 - pow(cerca_sol, 2.0));
		color += vec3(estrellas(dir, densidad_estrellas, TIME) * oscuro);

		// La Tierra (con su halo) y la Luna a su lado.
		vec3 tierra = normalize(direccion_tierra);
		vec3 der = normalize(cross(tierra, vec3(0.0, 1.0, 0.0)));
		vec3 arr = cross(der, tierra);
		vec3 luna = normalize(tierra + der * radio_tierra * 2.6 + arr * radio_tierra * 0.9);
		float ang_tierra = acos(clamp(dot(dir, tierra), -1.0, 1.0));
		color += vec3(0.35, 0.6, 1.0) * exp(-ang_tierra / (radio_tierra * 1.2)) * 0.35;
		vec4 t = planeta(dir, tierra, radio_tierra, sol, COLOR_OCEANO, COLOR_CONTINENTES, 1.0, 1.0, TIME);
		color = mix(color, t.rgb, t.a);
		vec4 l = planeta(dir, luna, radio_tierra * 0.3, sol, COLOR_LUNA, COLOR_MARES_LUNA, 1.0, 0.0, TIME);
		color = mix(color, l.rgb, l.a);
	}

	// Bruma de polvo en el horizonte y suelo a lo lejos.
	color = mix(color, color_horizonte, exp(-abs(altura) * 18.0) * 0.45);
	if (altura < 0.0) {
		color = mix(color, color_suelo, smoothstep(0.0, 0.2, -altura));
	}
	COLOR = color;
}
