shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;
// Árboles y arbustos de la pradera: la copa se mece con el viento (el tronco casi no se mueve).
// Cada árbol se mece un poco distinto según dónde está. Colores de vértice, sombreado tipo dibujo.

uniform float fuerza = 0.03;
// Desde qué altura (en metros del modelo) empieza a moverse.
uniform float desde_altura = 1.2;

void vertex() {
	vec3 raiz = MODEL_MATRIX[3].xyz;
	float h = max(VERTEX.y - desde_altura, 0.0);
	float t = TIME * 0.9 + raiz.x * 0.13 + raiz.z * 0.11;
	VERTEX.x += sin(t) * fuerza * h;
	VERTEX.z += cos(t * 0.8) * fuerza * 0.7 * h;
}

void fragment() {
	ALBEDO = COLOR.rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
}
