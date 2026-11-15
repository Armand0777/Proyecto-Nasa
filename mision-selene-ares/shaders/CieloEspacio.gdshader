shader_type sky;

#include "res://shaders/CieloComun.gdshaderinc"

// Cielo del espacio (desde la órbita de la Tierra hasta la Luna): negro, con muchas estrellas, la
// franja suave de la Vía Láctea y el Sol: un disco blanco muy brillante con su resplandor y rayos.
// Sin aire, el cielo es negro también de día. La Tierra y la Luna son esferas aparte (Cabina.gd).

uniform float densidad_estrellas : hint_range(0.95, 0.999) = 0.975;
uniform float tamano_sol = 0.022;

void sky() {
	vec3 dir = normalize(EYEDIR);
	vec3 sol = LIGHT0_ENABLED ? normalize(LIGHT0_DIRECTION) : normalize(vec3(0.4, 0.5, 0.75));
	float ang_sol = acos(clamp(dot(dir, sol), -1.0, 1.0));
	vec3 color = vec3(0.002, 0.003, 0.008);

	if (!AT_CUBEMAP_PASS) {
		// Vía Láctea: una franja inclinada con nubes de estrellas.
		vec3 eje = normalize(vec3(0.35, 0.8, -0.48));
		float franja = exp(-pow(dot(dir, eje) / 0.18, 2.0));
		float nubes = fbm2(vec2(atan(dir.z, dir.x) * 3.0, dir.y * 6.0) + 4.0);
		color += vec3(0.16, 0.15, 0.2) * franja * smoothstep(0.35, 0.8, nubes) * 0.6;
		// Estrellas (cerca del Sol se pierden en su brillo).
		float lejos_del_sol = smoothstep(0.15, 0.6, ang_sol);
		color += vec3(estrellas(dir, densidad_estrellas, TIME)) * lejos_del_sol;
		color += vec3(0.75, 0.82, 1.0) * estrellas(dir * 1.7, densidad_estrellas - 0.04, TIME * 0.7) * (0.25 + franja) * 0.45 * lejos_del_sol;
	}

	// El Sol: disco, corona y un resplandor amplio. Unos rayos finos en cruz, como en las fotos.
	float disco = 1.0 - smoothstep(tamano_sol * 0.85, tamano_sol, ang_sol);
	color += vec3(1.0, 0.98, 0.94) * disco * 6.0;
	color += vec3(1.0, 0.93, 0.8) * exp(-ang_sol / (tamano_sol * 1.6)) * 1.6;
	color += vec3(1.0, 0.85, 0.65) * exp(-ang_sol * 5.0) * 0.18;
	vec3 derecha = normalize(cross(sol, vec3(0.0, 1.0, 0.0)));
	vec3 arriba = cross(derecha, sol);
	vec2 plano = vec2(dot(dir, derecha), dot(dir, arriba));
	float rayos = exp(-abs(plano.x) * 260.0) + exp(-abs(plano.y) * 260.0);
	color += vec3(1.0, 0.95, 0.85) * rayos * exp(-ang_sol * 9.0) * step(0.0, dot(dir, sol)) * 0.8;
	COLOR = color;
}
