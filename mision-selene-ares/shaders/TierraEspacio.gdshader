shader_type spatial;
render_mode specular_disabled;
// La Tierra vista desde arriba en el despegue: océano, continentes verdes y de arena, nubes que se
// mueven y un borde azul brillante (la atmósfera vista de canto). Las texturas de ruido se crean
// por código (Cabina.gd).

uniform sampler2D continentes : filter_linear_mipmap, repeat_enable;
uniform sampler2D nubes : filter_linear_mipmap, repeat_enable;
uniform vec3 oceano : source_color = vec3(0.08, 0.33, 0.78);
uniform vec3 verde : source_color = vec3(0.3, 0.62, 0.26);
uniform vec3 arena : source_color = vec3(0.84, 0.74, 0.48);
uniform vec3 atmosfera : source_color = vec3(0.45, 0.75, 1.0);

void fragment() {
	float n = texture(continentes, UV * vec2(12.0, 6.0)).r;
	float tierra = smoothstep(0.52, 0.56, n);
	vec3 suelo = mix(verde, arena, smoothstep(0.62, 0.72, n));
	vec3 color = mix(oceano, suelo, tierra);
	float c = texture(nubes, UV * vec2(30.0, 15.0) + vec2(TIME * 0.0015, 0.0)).r;
	color = mix(color, vec3(1.0), smoothstep(0.55, 0.72, c) * 0.85);
	float borde = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = color;
	EMISSION = atmosfera * borde * 0.9;
	ROUGHNESS = 0.9;
}
