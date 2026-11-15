shader_type canvas_item;
// Fondo del menú de pausa: el juego detrás, desenfocado y oscurecido hacia el azul noche.

uniform sampler2D pantalla : hint_screen_texture, filter_linear;
uniform float radio = 6.0;  // En píxeles de la pantalla.
uniform vec4 tinte : source_color = vec4(0.043, 0.063, 0.149, 0.62);

void fragment() {
	vec3 suma = vec3(0.0);
	// 3 anillos de 8 muestras más el centro: desenfoque parejo y barato.
	for (int anillo = 1; anillo <= 3; anillo++) {
		for (int i = 0; i < 8; i++) {
			float angulo = float(i) * 0.785398 + float(anillo) * 0.39;
			vec2 paso = vec2(cos(angulo), sin(angulo)) * radio * float(anillo) * SCREEN_PIXEL_SIZE;
			suma += texture(pantalla, SCREEN_UV + paso).rgb;
		}
	}
	suma += texture(pantalla, SCREEN_UV).rgb;
	COLOR = vec4(mix(suma / 25.0, tinte.rgb, tinte.a), 1.0);
}
