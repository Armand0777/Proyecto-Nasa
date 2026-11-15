shader_type spatial;
render_mode unshaded, cull_back;
// La Luna vista desde la nave (viaje y órbita lunar), con la luz del Sol: gris con los «mares» de
// basalto oscuro, cráteres claros salpicados y el lado de noche negro (por eso se ven sus fases).
// Las texturas de ruido se crean por código (Cabina.gd) y se leen sin costuras (triplanar).

uniform sampler2D mares : filter_linear_mipmap, repeat_enable;
uniform sampler2D crateres : filter_linear_mipmap, repeat_enable;
uniform vec3 direccion_sol = vec3(0.0, 0.5, 0.86);
uniform vec3 claro : source_color = vec3(0.72, 0.71, 0.69);
uniform vec3 oscuro : source_color = vec3(0.3, 0.3, 0.32);

varying vec3 dir_local;

void vertex() {
	dir_local = normalize(VERTEX);
}

float triplanar(sampler2D textura, vec3 p, vec3 pesos) {
	return texture(textura, p.yz).r * pesos.x + texture(textura, p.zx).r * pesos.y + texture(textura, p.xy).r * pesos.z;
}

void fragment() {
	vec3 d = normalize(dir_local);
	vec3 pesos = pow(abs(d), vec3(6.0));
	pesos /= (pesos.x + pesos.y + pesos.z);
	float m = triplanar(mares, d * 0.9 + vec3(0.2, 0.5, 0.1), pesos);
	vec3 color = mix(claro, oscuro, smoothstep(0.52, 0.62, m) * 0.85);
	float cr = triplanar(crateres, d * 2.5, pesos);
	float fino = triplanar(crateres, d * 9.0, pesos);
	color *= 0.82 + 0.3 * cr;
	color *= 0.9 + 0.18 * fino;
	color = mix(color, vec3(0.92), smoothstep(0.78, 0.86, fino) * 0.35);  // Cráteres jóvenes, claros.
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float luz = dot(normal, normalize(direccion_sol));
	// Sin aire, el borde entre el día y la noche es nítido; un poquito de luz de la Tierra en la noche.
	float difusa = smoothstep(-0.02, 0.06, luz) * (0.35 + 0.75 * clamp(luz, 0.0, 1.0));
	ALBEDO = color * (difusa + 0.025);
}
