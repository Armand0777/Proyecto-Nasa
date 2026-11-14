shader_type canvas_item;
// Casco visto desde adentro: borde oscuro con forma de visor y un tinte dorado en el vidrio.
// Se usa en el prólogo al ponerse el traje (el rectángulo baja desde arriba como un casco).

// Cuánto se nota el visor dorado (0 = vidrio transparente).
uniform float dorado : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec2 p = UV - 0.5;
	// Abertura del visor: un óvalo ancho, un poco más plano abajo.
	vec2 q = p / vec2(0.47, p.y > 0.0 ? 0.4 : 0.44);
	float d = length(q);
	float borde = smoothstep(0.9, 1.0, d);
	// Reflejo suave en la parte de arriba del vidrio.
	float reflejo = (1.0 - smoothstep(0.0, 0.35, length(p - vec2(-0.18, -0.28)))) * 0.12 * (1.0 - borde);
	vec3 vidrio = vec3(1.0, 0.78, 0.3);
	vec3 color = mix(vidrio + reflejo, vec3(0.04, 0.05, 0.09), borde);
	float alfa = mix(dorado * 0.45 + reflejo, 0.97, borde);
	COLOR = vec4(color, alfa);
}
