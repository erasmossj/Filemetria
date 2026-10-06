shader_type spatial;

// Passe 1 do glow: marca no stencil a silhueta do objeto, ignorando a profundidade.
// Não desenha cor. Serve para o contorno saber onde NÃO pintar,
// mesmo quando o objeto está escondido atrás/dentro de outro.
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, blend_mix, shadows_disabled;
stencil_mode write, compare_always, 1;

void fragment() {
	ALBEDO = vec3(0.0);
	ALPHA = 0.0;
}
