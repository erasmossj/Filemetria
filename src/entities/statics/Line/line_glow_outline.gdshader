shader_type spatial;

// Passe 2 do glow: casca da reta inflada em pixels de tela, desenhada sem teste
// de profundidade e só onde o stencil NÃO foi marcado pela máscara.
// Resultado: apenas o traçado ao redor da reta, visível através de paredes.
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix, shadows_disabled;
stencil_mode read, compare_not_equal, 1;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Espessura do traçado em pixels, constante a qualquer distância.
uniform float outline_width_px : hint_range(0.5, 10.0) = 2.0;

void vertex() {
	// Direção de expansão própria do cilindro (eixo Y local), igual para vértices
	// que ocupam a mesma posição: evita rachaduras entre a lateral e as tampas.
	vec2 radial = length(VERTEX.xz) > 1e-5 ? normalize(VERTEX.xz) : vec2(0.0);
	vec3 grow_dir = normalize(vec3(radial.x, sign(VERTEX.y), radial.y));

	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 dir_view = (MODELVIEW_MATRIX * vec4(grow_dir, 0.0)).xyz;
	vec2 dir_clip = (PROJECTION_MATRIX * vec4(dir_view, 0.0)).xy;

	if (length(dir_clip) > 1e-6) {
		// Converte pixels para NDC e multiplica por w para anular a divisão de perspectiva.
		clip.xy += normalize(dir_clip) * outline_width_px * 2.0 / VIEWPORT_SIZE * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = glow_color.rgb;
	ALPHA = glow_color.a;
}
