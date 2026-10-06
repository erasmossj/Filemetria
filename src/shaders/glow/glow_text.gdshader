shader_type canvas_item;

// Glow para texto 2D, aplicado num CanvasGroup que contém o Label.
// O contorno de fonte do Godot é preenchido por dentro, então o Label é desenhado
// com o miolo vermelho puro (marcador) e o contorno branco. Aqui o verde
// separa os dois: branco tem G = 1 e o marcador tem G = 0. O miolo some e
// sobra só o traçado, com bordas suaves.
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
	// O CanvasGroup entrega a cor pré-multiplicada pelo alfa.
	float outline = c.a > 0.0001 ? c.g / c.a : 0.0;
	COLOR = vec4(glow_color.rgb, glow_color.a * c.a * outline);
}
