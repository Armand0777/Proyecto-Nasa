shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never;
// El halo azul de la atmósfera alrededor de la Tierra: una capa un poco más grande que el planeta.
// Brilla más justo sobre el borde del planeta (donde se mira a través de más aire) y se apaga hacia
// afuera; del lado de noche casi no se ve, y en el amanecer se pone anaranjado.

uniform vec3 direccion_sol = vec3(0.0, 0.5, 0.86);
uniform vec3 color_dia : source_color = vec3(0.35, 0.65, 1.0);
uniform vec3 color_amanecer : source_color = vec3(1.0, 0.5, 0.2);
// Radio de la Tierra dividido por el radio de esta capa.
uniform float proporcion = 0.988;
uniform float intensidad = 1.5;

void fragment() {
	// Dónde queda el borde del planeta visto a través de esta capa (no depende de la distancia).
	float limbo = 1.0 - sqrt(1.0 - proporcion * proporcion);
	float f = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float adentro = pow(clamp(f / limbo, 0.0, 1.0), 4.0);
	float afuera = exp(-max(f - limbo, 0.0) / (1.0 - limbo) * 5.0);
	float halo = adentro * afuera;
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float luz = dot(normal, normalize(direccion_sol));
	float dia = smoothstep(-0.3, 0.25, luz);
	vec3 color = mix(color_amanecer, color_dia, smoothstep(-0.05, 0.3, luz));
	ALBEDO = color * halo * dia * intensidad;
}
