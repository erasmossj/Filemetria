extends Control

## Anel de tempo restante da lanterna do HUD. Uma volta inteira é o tempo total da fase,
## e o arco começa no topo e diminui no sentido horário.

@export var cor_trilho := Color(0.784, 0.125, 0.169, 0.18)
@export var cor_anel := Color("c8202b")
@export var espessura := 5.0
## Distância da borda do disco até o centro do traço.
@export var recuo := 7.0

## Fração do tempo que ainda resta, de 0 a 1.
var fracao := 1.0:
	set(valor):
		valor = clampf(valor, 0.0, 1.0)
		if is_equal_approx(valor, fracao):
			return
		fracao = valor
		queue_redraw()


func _draw() -> void:
	var centro := size / 2.0
	var raio := minf(size.x, size.y) / 2.0 - recuo
	draw_arc(centro, raio, 0.0, TAU, 96, cor_trilho, espessura, true)
	if fracao > 0.0:
		draw_arc(centro, raio, -PI / 2.0, -PI / 2.0 + TAU * fracao, 96, cor_anel, espessura, true)


func definir_cores(trilho: Color, anel: Color) -> void:
	cor_trilho = trilho
	cor_anel = anel
	queue_redraw()
