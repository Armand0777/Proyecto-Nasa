shader_type canvas_item;
// Prólogo: lo que ve Comandante Junior al despertar del sueño criogénico.
// Párpados que se abren desde el centro, vista borrosa y doble, tinte frío y bordes oscuros.
// Va en una capa debajo del HUD, para que los subtítulos de A.R.T.I. se lean nítidos.

uniform sampler2D pantalla : hint_screen_texture, filter_linear;
// 0 = ojos cerrados; 1 = abiertos; más de 1 = sin ningún borde de párpado.
uniform float abierto : hint_range(0.0, 1.5) = 0.0;
// 0 = vista nítida; 1 = muy borrosa, doble y fría.
uniform float borroso : hint_range(0.0, 1.0) = 1.0;
uniform vec3 tinte : source_color = vec3(0.56, 0.89, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	// Desenfoque: promedio de 7 × 7 puntos, más separados cuanto más borroso.
	vec2 paso = SCREEN_PIXEL_SIZE * 4.0 * borroso;
	vec3 suma = vec3(0.0);
	float pesos = 0.0;
	for (int i = -3; i <= 3; i++) {
		for (int j = -3; j <= 3; j++) {
			float peso = 1.0 / (1.0 + float(i * i + j * j));
			suma += texture(pantalla, uv + vec2(float(i), float(j)) * paso).rgb * peso;
			pesos += peso;
		}
	}
	vec3 color = suma / pesos;
	// Vista doble: una copia corrida que se junta al despertar del todo.
	vec3 doble = texture(pantalla, uv + vec2(0.008, 0.003) * borroso).rgb;
	color = mix(color, doble, 0.18 * borroso);
	color = mix(color, color * tinte + vec3(0.04, 0.06, 0.09), 0.45 * borroso);

	// Párpados: una abertura con forma de ojo que crece desde el centro.
	vec2 p = SCREEN_UV - 0.5;
	float limite = abierto * 0.72 * sqrt(max(0.0, 1.0 - p.x * p.x * 2.2));
	float suave = 0.05 + 0.1 * borroso;
	float ojo = 1.0 - smoothstep(limite - suave, limite, abs(p.y));
	// Bordes oscuros mientras dura el mareo.
	float vineta = 1.0 - borroso * 0.55 * smoothstep(0.25, 0.75, length(p * vec2(1.3, 1.0)));
	COLOR = vec4(color * ojo * vineta, 1.0);
}
