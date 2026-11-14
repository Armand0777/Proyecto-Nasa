shader_type sky;

#include "res://shaders/CieloComun.gdshaderinc"

// Cielo de la Luna en el Polo Sur.
// Datos reales: sin atmósfera el cielo es negro también de día, y desde el Polo Sur la Tierra
// se ve siempre cerca del horizonte. Desde la Luna la Tierra se ve unas 4 veces más grande que
// la Luna llena vista desde la Tierra; aquí se dibuja todavía más grande, para verla de cerca.

uniform vec3 color_suelo : source_color = vec3(0.22, 0.22, 0.24);
uniform vec3 direccion_tierra = vec3(0.631, 0.191, -0.752);
uniform float radio_tierra = 0.09;
uniform float densidad_estrellas : hint_range(0.95, 0.999) = 0.982;

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sol = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(-0.86, 0.12, -0.5));
	float altura = dir.y;
	vec3 color = vec3(0.004, 0.005, 0.01);

	// El Sol: disco blanco con un brillo pequeño (sin aire no hay cielo de colores alrededor).
	float ang_sol = acos(clamp(dot(dir, sol), -1.0, 1.0));
	color += vec3(1.0, 0.98, 0.94) * (1.0 - smoothstep(0.0085, 0.0105, ang_sol)) * 3.0;
	color += vec3(1.0, 0.95, 0.85) * exp(-ang_sol * 18.0) * 0.35;

	if (!AT_CUBEMAP_PASS) {
		float lejos_del_sol = 1.0 - exp(-ang_sol * 6.0);
		color += vec3(estrellas(dir, densidad_estrellas, TIME) * smoothstep(0.0, 0.12, altura) * lejos_del_sol);

		// La Tierra grande, con un borde azul de atmósfera.
		vec3 tierra = normalize(direccion_tierra);
		float ang_tierra = acos(clamp(dot(dir, tierra), -1.0, 1.0));
		color += vec3(0.3, 0.55, 1.0) * exp(-max(ang_tierra - radio_tierra, 0.0) / (radio_tierra * 0.25)) * 0.25;
		vec4 t = planeta(dir, tierra, radio_tierra, sol, COLOR_OCEANO, COLOR_CONTINENTES, 1.0, 1.0, TIME);
		color = mix(color, t.rgb, t.a);
	}

	if (altura < 0.0) {
		color = mix(color, color_suelo, smoothstep(0.0, 0.05, -altura));
	}
	COLOR = color;
}
