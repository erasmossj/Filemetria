extends Control

## Telas de resultado do chute e do tempo esgotado, opção C do Figma ("Faixa de tela
## inteira"): faixa larga no centro, renda de filé por cima e por baixo, cantos Lisbon
## nas pontas, título, subtítulo e chips com os detalhes.

const TITULO_ACERTO := "Correto!"
const SUBTITULO_ACERTO := "Você conseguiu recuperar a área com sucesso!"
const TITULO_ERRO := "Tente novamente!"
const SUBTITULO_ERRO := "Quase lá: confira as medidas e calcule de novo."
const TITULO_ERRO_GROSSEIRO := "Tente novamente..."
const SUBTITULO_ERRO_GROSSEIRO := "Dessa vez do começo... Ok?"
const TITULO_TEMPO_ESGOTADO := "Tempo esgotado!"

const CHIP_RESPOSTA := "SUA RESPOSTA"
const CHIP_A_SEGUIR := "A SEGUIR"
const CHIP_TEMPO := "TEMPO"
const CHIP_VOLTANDO := "VOLTANDO AO"
const TEXTO_PROXIMO_ATO := "ATO %d DE %d"
const TEXTO_FIM_DA_FASE := "FIM DA FASE"
const TEXTO_ATO_1 := "ATO 1"
const TEXTO_TEMPO_ZERADO := "00:00"

const VERDE := Color("2e9b57")
const VERMELHO := Color("c8202b")
## Vermelho mais escuro da resposta errada, para não se confundir com o erro grosseiro.
const VERMELHO_ESCURO := Color("9c1b24")
const ESCURO := Color("141a1f")
const FUNDO_CINZA := Color(0.447, 0.447, 0.447, 0.576)
const FUNDO_ESCURO := Color(ESCURO, 0.62)

const ICONE_ACERTO := preload("res://assets/sprites/circle_check.svg")
const ICONE_ERRO := preload("res://assets/sprites/rotate_ccw.svg")
const ICONE_RECOMECO := preload("res://assets/sprites/undo_2.svg")
const FONTE_ROTULO := preload("res://assets/fonts/bebas_neue/bebas_neue_regular.ttf")
const FONTE_VALOR := preload("res://assets/fonts/barlow/barlow_bold.ttf")

## A renda é desenhada a 60% do tamanho do SVG, como no painel de controles do HUD.
const ESCALA_RENDA := 0.6

## Tempo, em segundos, que a tela fica visível.
@export var duracao := 2.5

## Conta as exibições para que o timer de uma exibição antiga não esconda a atual.
var _exibicao := 0
## Cor dos rótulos dos chips na exibição atual.
var _destaque := VERDE
var _estilo_faixa: StyleBoxFlat
var _estilo_canto: StyleBoxFlat

@onready var _layer: CanvasLayer = $CanvasLayer
@onready var _fundo: ColorRect = $CanvasLayer/Fundo
@onready var _faixa: Panel = %Faixa
@onready var _renda_topo: TextureRect = %RendaTopo
@onready var _renda_base: TextureRect = %RendaBase
@onready var _cantos: Array[Panel] = [%CantoEsquerdo, %CantoDireito]
@onready var _icone: TextureRect = %Icone
@onready var _titulo: Label = %Titulo
@onready var _subtitulo: Label = %Subtitulo
@onready var _chips: HBoxContainer = %Chips


func _ready() -> void:
	_layer.visible = false

	# Cópias próprias: cada tela muda as cores sem mexer no recurso da cena.
	_estilo_faixa = _faixa.get_theme_stylebox("panel").duplicate()
	_faixa.add_theme_stylebox_override("panel", _estilo_faixa)
	_estilo_canto = _cantos[0].get_theme_stylebox("panel").duplicate()
	for canto in _cantos:
		canto.add_theme_stylebox_override("panel", _estilo_canto)

	_faixa.resized.connect(_posicionar_rendas)
	_posicionar_rendas()


## As funções mostrar_* esperam a tela sumir: use com await para agir depois dela.
func mostrar_acerto(resposta: float, proximo_ato: int, total_atos: int) -> void:
	var a_seguir := TEXTO_FIM_DA_FASE if proximo_ato > total_atos else TEXTO_PROXIMO_ATO % [proximo_ato, total_atos]
	_aplicar_cores(VERDE, VERDE, FUNDO_CINZA, ICONE_ACERTO)
	await _mostrar(TITULO_ACERTO, SUBTITULO_ACERTO, [
		[CHIP_RESPOSTA, _formatar_area(resposta)],
		[CHIP_A_SEGUIR, a_seguir],
	])


func mostrar_erro(resposta: float, tempo_restante: float) -> void:
	_aplicar_cores(VERMELHO_ESCURO, VERMELHO_ESCURO, FUNDO_CINZA, ICONE_ERRO)
	await _mostrar(TITULO_ERRO, SUBTITULO_ERRO, [
		[CHIP_RESPOSTA, _formatar_area(resposta)],
		[CHIP_TEMPO, _formatar_tempo(tempo_restante)],
	])


func mostrar_erro_grosseiro(resposta: float) -> void:
	_aplicar_cores(ESCURO, VERMELHO, FUNDO_ESCURO, ICONE_RECOMECO)
	await _mostrar(TITULO_ERRO_GROSSEIRO, SUBTITULO_ERRO_GROSSEIRO, [
		[CHIP_RESPOSTA, _formatar_area(resposta)],
		[CHIP_VOLTANDO, TEXTO_ATO_1],
	])


## Mesmo visual do erro grosseiro: as duas telas voltam para o Ato 1.
func mostrar_tempo_esgotado() -> void:
	_aplicar_cores(ESCURO, VERMELHO, FUNDO_ESCURO, ICONE_RECOMECO)
	await _mostrar(TITULO_TEMPO_ESGOTADO, SUBTITULO_ERRO_GROSSEIRO, [
		[CHIP_TEMPO, TEXTO_TEMPO_ZERADO],
		[CHIP_VOLTANDO, TEXTO_ATO_1],
	])


## faixa: cor de fundo da faixa. destaque: renda, cantos e rótulos dos chips.
## Com a faixa da mesma cor do destaque, os cantos ficam brancos translúcidos;
## com a faixa escura, ficam na cor do destaque e o ícone também.
func _aplicar_cores(faixa: Color, destaque: Color, fundo: Color, icone: Texture2D) -> void:
	var faixa_colorida := faixa == destaque
	_destaque = destaque
	_fundo.color = fundo
	_estilo_faixa.bg_color = Color(faixa, 0.97)
	_estilo_canto.bg_color = Color(1, 1, 1, 0.14) if faixa_colorida else destaque
	for canto in _cantos:
		canto.get_child(0).modulate = Color(1, 1, 1, 0.9) if faixa_colorida else Color.WHITE
	_renda_topo.modulate = destaque
	_renda_base.modulate = destaque
	_icone.texture = icone
	_icone.modulate = Color.WHITE if faixa_colorida else destaque


func _mostrar(titulo: String, subtitulo: String, chips: Array) -> void:
	_exibicao += 1
	var exibicao := _exibicao

	_titulo.text = titulo
	_subtitulo.text = subtitulo
	for filho in _chips.get_children():
		_chips.remove_child(filho)
		filho.queue_free()
	for chip in chips:
		_chips.add_child(_criar_chip(chip[0], chip[1]))
	_layer.visible = true

	await get_tree().create_timer(duracao).timeout
	if exibicao == _exibicao:
		_layer.visible = false


## Rendas logo acima e logo abaixo da faixa, na largura dela. A de cima é espelhada (flip_v).
func _posicionar_rendas() -> void:
	var altura_textura := _renda_base.texture.get_height()
	for renda in [_renda_topo, _renda_base]:
		renda.scale = Vector2.ONE * ESCALA_RENDA
		renda.size = Vector2(_faixa.size.x / ESCALA_RENDA, altura_textura)
	_renda_topo.position = Vector2(0, -altura_textura * ESCALA_RENDA)
	_renda_base.position = Vector2(0, _faixa.size.y)


func _criar_chip(rotulo: String, valor: String) -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.96)
	estilo.set_corner_radius_all(5)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 10
	estilo.content_margin_top = 3
	estilo.content_margin_bottom = 4
	estilo.shadow_color = Color(0, 0, 0, 0.25)
	estilo.shadow_size = 5
	estilo.shadow_offset = Vector2(0, 2)

	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", estilo)
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", 6)
	linha.add_child(_criar_label(rotulo, FONTE_ROTULO, 13, _destaque))
	linha.add_child(_criar_label(valor, FONTE_VALOR, 16, ESCURO))
	chip.add_child(linha)
	return chip


func _criar_label(texto: String, fonte: Font, tamanho: int, cor: Color) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_override("font", fonte)
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _formatar_area(area: float) -> String:
	return ("%.2f m²" % area).replace(".", ",")


## Arredonda para cima, como a lanterna do HUD.
func _formatar_tempo(segundos: float) -> String:
	var inteiros := ceili(segundos)
	return "%02d:%02d" % [inteiros / 60, inteiros % 60]
