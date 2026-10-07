extends Control

## HUD da fase (CG-38), opção E do Figma ("Farol"): objetivo e ato no canto superior
## esquerdo, lanterna do cronômetro no topo, retas à direita, botão de chute embaixo e
## painel de controles enquanto F1 estiver pressionado.
## Quem alimenta é a fase (fase_farol.gd): configurar() e mostrar_retas(). O tempo vem
## direto do autoload Cronometro.

## Emitido no clique do botão "Calcular área". A fase abre o menu de chute (CG-20).
signal calcular_area_pressionado

const VERMELHO := Color("c8202b")
const VERMELHO_CLARO := Color("db3a44")
const ESCURO := Color("141a1f")
const CINZA := Color("6a7075")
const ROSA := Color("f3e2e3")
const BRANCO_CARTAO := Color(1, 1, 1, 0.96)
const LISTRA_FUTURA := Color("d7d7d7")
const FUNDO_TECLA := Color("f5f5f5")

const TEXTO_ATO := "ATO %d DE %d"
const TEXTO_TEMPO := "TEMPO"
const TEXTO_URGENTE := "CORRA!"
const TEXTO_SEM_RETAS := "nenhuma ainda"
const TEXTO_RETAS_OCULTAS := "+%d anteriores"
const TEXTO_TAB := "abre o menu de chute da área"
const TEXTO_SOLTE := "Solte"
const TEXTO_PARA_FECHAR := "para fechar"

## Linhas do painel de controles: teclas (ou "@ícone") e o que fazem.
const CONTROLES_ESQUERDA := [
	[["W", "A", "S", "D"], "andar"],
	[["@move"], "olhar (mouse)"],
	[["Espaço"], "subir"],
	[["Shift"], "descer"],
	[["Esc"], "pausar o tempo"],
]
const CONTROLES_DIREITA := [
	[["@clique"], "marcar ponto"],
	[["@mouse"], "botão dir.: apagar ponto"],
	[["Q"], "cancelar reta"],
	[["E"], "desfazer última reta"],
	[["R"], "limpar todas as retas"],
]
const ICONES := {
	"move": preload("res://assets/sprites/move.svg"),
	"clique": preload("res://assets/sprites/mouse_pointer_click.svg"),
	"mouse": preload("res://assets/sprites/mouse.svg"),
}

const FONTE_TITULO := preload("res://assets/fonts/bebas_neue/bebas_neue_regular.ttf")
const FONTE_TEXTO := preload("res://assets/fonts/barlow/barlow_medium.ttf")
const FONTE_TEXTO_FORTE := preload("res://assets/fonts/barlow/barlow_semibold.ttf")
const FONTE_TECLA := preload("res://assets/fonts/barlow/barlow_bold.ttf")

## Recuo lateral das rendas do painel de controles e quanto os cantos de filé passam da borda.
const RECUO_RENDA := 19.0
const ESCALA_RENDA := 0.6
const SALIENCIA_CANTO := 17.0

## Abaixo deste tempo restante a lanterna fica vermelha e o anel pisca.
@export_range(0, 120, 1, "suffix:s") var limite_urgente := 30.0
## Piscadas por segundo do anel no modo urgente.
@export_range(0.5, 6.0, 0.5) var piscadas_por_segundo := 2.0
## Quantas retas aparecem no cartão. As mais antigas viram "+N anteriores".
@export_range(1, 30) var max_retas_visiveis := 8

## Último segundo exibido, para só reescrever o texto quando ele muda.
var _segundos_exibidos := -1
var _urgente := false
var _estilo_lanterna: StyleBoxFlat
var _estilo_botao: StyleBoxFlat
var _estilo_botao_hover: StyleBoxFlat

@onready var _objetivo: Label = %ObjetivoTexto
@onready var _ato: Label = %AtoTexto
## Da listra de baixo (Ato 1) para a de cima, como as faixas do Farol.
@onready var _listras: Array[Panel] = [%Listra1, %Listra2, %Listra3]
@onready var _disco: Panel = %Disco
@onready var _anel: Control = %Anel
@onready var _tempo: Label = %Tempo
@onready var _legenda: Label = %Legenda
@onready var _lista_retas: VBoxContainer = %ListaRetas
@onready var _botao: PanelContainer = %BotaoCalcular
@onready var _botao_conteudo: HBoxContainer = %BotaoConteudo
@onready var _atalho_conteudo: HBoxContainer = %AtalhoConteudo
@onready var _escurecer: ColorRect = %Escurecer
@onready var _painel_controles: PanelContainer = %PainelControles
@onready var _coluna_esquerda: VBoxContainer = %ColunaEsquerda
@onready var _coluna_direita: VBoxContainer = %ColunaDireita
@onready var _rodape: HBoxContainer = %Rodape
@onready var _ornamentos: Control = %Ornamentos
@onready var _renda_topo: TextureRect = %RendaTopo
@onready var _renda_base: TextureRect = %RendaBase
@onready var _cantos: Array[Control] = [%CantoSE, %CantoSD, %CantoIE, %CantoID]


func _ready() -> void:
	# Cópias próprias: o modo urgente e o hover mudam as cores sem mexer no recurso da cena.
	_estilo_lanterna = _disco.get_theme_stylebox("panel").duplicate()
	_disco.add_theme_stylebox_override("panel", _estilo_lanterna)
	_estilo_botao = _botao.get_theme_stylebox("panel").duplicate()
	_estilo_botao_hover = _estilo_botao.duplicate()
	_estilo_botao_hover.bg_color = VERMELHO_CLARO
	_botao.add_theme_stylebox_override("panel", _estilo_botao)

	_botao_conteudo.add_child(_criar_tecla("Tab", VERMELHO, Color.WHITE, false))
	_atalho_conteudo.add_child(_criar_tecla("F1", ESCURO, FUNDO_TECLA))
	_atalho_conteudo.move_child(_atalho_conteudo.get_child(-1), 0)
	_preencher_painel_controles()

	_botao.gui_input.connect(_on_botao_gui_input)
	_botao.mouse_entered.connect(_botao.add_theme_stylebox_override.bind("panel", _estilo_botao_hover))
	_botao.mouse_exited.connect(_botao.add_theme_stylebox_override.bind("panel", _estilo_botao))
	_painel_controles.resized.connect(_posicionar_ornamentos)

	var sem_retas: Array[float] = []
	mostrar_retas(sem_retas)
	_mostrar_controles(false)


func _process(_delta: float) -> void:
	var restante := Cronometro.tempo_restante
	var total := Cronometro.tempo_total
	_anel.fracao = restante / total if total > 0.0 else 0.0

	var urgente := total > 0.0 and restante <= limite_urgente
	if urgente != _urgente:
		_aplicar_urgencia(urgente)
	if _urgente:
		var fase := Time.get_ticks_msec() / 1000.0 * TAU * piscadas_por_segundo
		_anel.modulate.a = 0.6 + 0.4 * cos(fase)

	# Arredonda para cima: 10:00 no início e 00:00 só quando o tempo acaba.
	var segundos := ceili(restante)
	if segundos == _segundos_exibidos:
		return
	_segundos_exibidos = segundos
	@warning_ignore("integer_division")
	_tempo.text = "%02d:%02d" % [segundos / 60, segundos % 60]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("show_controls"):
		_mostrar_controles(true)
	elif event.is_action_released("show_controls"):
		_mostrar_controles(false)


## Textos e listras do ato. Chamado pela fase no _ready.
func configurar(ato: int, total_atos: int, objetivo: String) -> void:
	_ato.text = TEXTO_ATO % [ato, total_atos]
	_objetivo.text = objetivo
	for i in _listras.size():
		_listras[i].add_theme_stylebox_override("panel", _estilo_listra(i + 1, ato))


## Reescreve o cartão de retas com os comprimentos em metros (CG-19). O arredondamento
## para duas casas é só na exibição.
func mostrar_retas(comprimentos: Array[float]) -> void:
	for filho in _lista_retas.get_children():
		_lista_retas.remove_child(filho)
		filho.queue_free()

	if comprimentos.is_empty():
		_lista_retas.add_child(_criar_aviso_retas(TEXTO_SEM_RETAS))
		return

	var inicio := maxi(comprimentos.size() - max_retas_visiveis, 0)
	if inicio > 0:
		_lista_retas.add_child(_criar_aviso_retas(TEXTO_RETAS_OCULTAS % inicio))
	for i in range(inicio, comprimentos.size()):
		_lista_retas.add_child(_criar_linha_reta(i + 1, comprimentos[i]))


func _aplicar_urgencia(urgente: bool) -> void:
	_urgente = urgente
	_estilo_lanterna.bg_color = VERMELHO if urgente else BRANCO_CARTAO
	_estilo_lanterna.shadow_color = Color(1, 0.25, 0.2, 0.9) if urgente else Color(0, 0, 0, 0.4)
	_estilo_lanterna.shadow_size = 16 if urgente else 8
	_estilo_lanterna.shadow_offset = Vector2.ZERO if urgente else Vector2(0, 4)
	if urgente:
		Cronometro.alertar_tempo_urgente()
		_anel.definir_cores(Color(1, 1, 1, 0.25), Color.WHITE)
	else:
		_anel.definir_cores(Color(VERMELHO, 0.18), VERMELHO)
		_anel.modulate.a = 1.0
	_tempo.add_theme_color_override("font_color", Color.WHITE if urgente else ESCURO)
	_legenda.add_theme_color_override("font_color", Color.WHITE if urgente else VERMELHO)
	_legenda.text = TEXTO_URGENTE if urgente else TEXTO_TEMPO


func _mostrar_controles(visivel: bool) -> void:
	_escurecer.visible = visivel
	_painel_controles.visible = visivel
	_ornamentos.visible = visivel
	if visivel:
		_posicionar_ornamentos()


## Rendas acima e abaixo do painel e os quatro cantos de filé, que ficam fora do
## PanelContainer para poder passar da borda dele.
func _posicionar_ornamentos() -> void:
	var r := _painel_controles.get_rect()
	var altura_renda := _renda_base.texture.get_height() * ESCALA_RENDA
	for renda in [_renda_topo, _renda_base]:
		renda.scale = Vector2.ONE * ESCALA_RENDA
		renda.size = Vector2((r.size.x - 2.0 * RECUO_RENDA) / ESCALA_RENDA, renda.texture.get_height())
	_renda_topo.position = Vector2(r.position.x + RECUO_RENDA, r.position.y - altura_renda)
	_renda_base.position = Vector2(r.position.x + RECUO_RENDA, r.end.y)

	var lado := _cantos[0].size.x
	var esquerda := r.position.x - SALIENCIA_CANTO
	var direita := r.end.x + SALIENCIA_CANTO - lado
	var topo := r.position.y - SALIENCIA_CANTO
	var base := r.end.y + SALIENCIA_CANTO - lado
	_cantos[0].position = Vector2(esquerda, topo)
	_cantos[1].position = Vector2(direita, topo)
	_cantos[2].position = Vector2(esquerda, base)
	_cantos[3].position = Vector2(direita, base)


func _preencher_painel_controles() -> void:
	for linha in CONTROLES_ESQUERDA:
		_coluna_esquerda.add_child(_criar_linha_controle(linha[0], linha[1]))
	for linha in CONTROLES_DIREITA:
		_coluna_direita.add_child(_criar_linha_controle(linha[0], linha[1]))

	_rodape.add_child(_criar_tecla("Tab", Color.WHITE, VERMELHO, false))
	_rodape.add_child(_criar_label(TEXTO_TAB, FONTE_TEXTO_FORTE, 11, ESCURO))
	_rodape.add_child(_criar_espaco(14))
	_rodape.add_child(_criar_label(TEXTO_SOLTE, FONTE_TEXTO, 10, CINZA))
	_rodape.add_child(_criar_tecla("F1", ESCURO, FUNDO_TECLA))
	_rodape.add_child(_criar_label(TEXTO_PARA_FECHAR, FONTE_TEXTO, 10, CINZA))


func _criar_linha_controle(teclas: Array, descricao: String) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", 4)
	for tecla: String in teclas:
		if tecla.begins_with("@"):
			linha.add_child(_criar_icone(ICONES[tecla.substr(1)], 14, ESCURO))
		else:
			linha.add_child(_criar_tecla(tecla, ESCURO, FUNDO_TECLA))
	linha.add_child(_criar_espaco(4))
	linha.add_child(_criar_label(descricao, FONTE_TEXTO, 11, ESCURO))
	return linha


func _criar_linha_reta(numero: int, comprimento: float) -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = ROSA if numero % 2 == 1 else Color.WHITE
	estilo.set_corner_radius_all(2)
	estilo.content_margin_left = 6
	estilo.content_margin_right = 8
	estilo.content_margin_top = 2
	estilo.content_margin_bottom = 2

	var fundo := PanelContainer.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_theme_stylebox_override("panel", estilo)
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", 7)
	linha.add_child(_criar_label(str(numero), FONTE_TITULO, 14, VERMELHO))
	linha.add_child(_criar_label(("%.2f m" % comprimento).replace(".", ","), FONTE_TECLA, 16, ESCURO))
	fundo.add_child(linha)
	return fundo


func _criar_aviso_retas(texto: String) -> Label:
	var aviso := _criar_label(texto, FONTE_TEXTO, 11, CINZA)
	aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return aviso


func _criar_tecla(texto: String, cor_texto: Color, cor_fundo: Color, com_borda := true) -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor_fundo
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 6
	estilo.content_margin_right = 6
	estilo.content_margin_top = 1
	estilo.content_margin_bottom = 2
	if com_borda:
		estilo.set_border_width_all(1)
		estilo.border_color = Color(cor_texto, 0.5)

	var tecla := PanelContainer.new()
	tecla.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tecla.custom_minimum_size.x = 19
	tecla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tecla.add_theme_stylebox_override("panel", estilo)
	var label := _criar_label(texto, FONTE_TECLA, 10, cor_texto)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tecla.add_child(label)
	return tecla


func _criar_icone(textura: Texture2D, tamanho: float, cor: Color) -> TextureRect:
	var icone := TextureRect.new()
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icone.texture = textura
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.custom_minimum_size = Vector2(tamanho, tamanho)
	icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icone.modulate = cor
	return icone


func _criar_label(texto: String, fonte: Font, tamanho: int, cor: Color) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_override("font", fonte)
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _criar_espaco(largura: float) -> Control:
	var espaco := Control.new()
	espaco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	espaco.custom_minimum_size.x = largura
	return espaco


func _estilo_listra(numero: int, ato: int) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = VERMELHO if numero <= ato else LISTRA_FUTURA
	estilo.set_corner_radius_all(1)
	if numero == ato:
		estilo.set_border_width_all(1)
		estilo.border_color = ESCURO
	return estilo


func _on_botao_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		calcular_area_pressionado.emit()
		_botao.accept_event()
