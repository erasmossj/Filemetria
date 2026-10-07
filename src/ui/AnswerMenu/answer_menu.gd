extends Control

## Emitido quando o erro relativo está dentro da margem de acerto (dispara CG-21 e avança o ato).
signal answer_correct
## Emitido quando o erro está entre as duas margens: o jogador pode tentar de novo.
signal answer_retry
## Emitido quando o erro passa da margem de erro grosseiro: falha, reinicia a fase (CG-37).
signal answer_failed
## Emitido quando o envio não é uma área válida: campo vazio, só com "," ou "." ou zero
## (0, 0,0, 0.000...). Nada é avaliado, o menu continua aberto e mostra o aviso (CG-47).
signal answer_invalid

enum AnswerResult { CORRECT, RETRY, FAIL }

const VERMELHO := Color("c8202b")
const ESCURO := Color("141a1f")
const CINZA := Color("6a7075")
const FUNDO_RETA := Color(VERMELHO, 0.08)

const TEXTO_SEM_RETAS := "nenhuma ainda"
const TEXTO_RETAS_OCULTAS := "+%d"

const AVISO_SEM_NUMERO := "Digite um número"
## As dicas não trazem número de exemplo: um valor qualquer poderia coincidir com um gabarito.
const AVISO_SEM_NUMERO_DICA := "Use só números, com vírgula ou ponto para os decimais."
const AVISO_ZERO := "A área precisa ser maior que 0"
const AVISO_ZERO_DICA := "Digite uma área válida, maior que zero."

const FONTE_TITULO := preload("res://assets/fonts/bebas_neue/bebas_neue_regular.ttf")
const FONTE_TEXTO := preload("res://assets/fonts/barlow/barlow_medium.ttf")
const FONTE_NUMERO := preload("res://assets/fonts/barlow/barlow_bold.ttf")

## Gabarito da área total em m² (tabela de CG-16).
@export var correct_ans := 0.0
## Erro relativo máximo para contar como acerto (0.10 = 10%).
@export_range(0.0, 1.0, 0.01) var hit_margin := 0.10
## Erro acima do qual o chute é um erro grosseiro, nos dois sentidos.
## 1.0 = 100%: grosseiro acima do dobro ou abaixo da metade do gabarito.
@export_range(0.0, 10.0, 0.05) var fail_margin := 1.0
## Tempo, em segundos, que o aviso de resposta inválida fica na tela.
@export_range(0.5, 10.0, 0.5, "suffix:s") var duracao_aviso := 2.0
## Quantas retas aparecem no cartão. As mais antigas viram um "+N".
@export_range(1, 30) var max_retas_visiveis := 6

## Último chute válido enviado, em m². A fase mostra o valor na tela de resultado.
var ultima_resposta := 0.0
## Conta as exibições do aviso para que o timer de uma exibição antiga não esconda a atual.
var _aviso_exibicao := 0

@onready var ans : TextEdit = %AnswerTextEdit
## O CanvasLayer não herda a visibilidade do Control pai, então é ele que precisa ser escondido.
@onready var layer : CanvasLayer = $"CanvasLayer"
## Fica sempre no layout, só transparente (modulate.a = 0), para o menu não pular quando ele aparece.
@onready var _aviso : Control = %Aviso
@onready var _aviso_titulo : Label = %AvisoTitulo
@onready var _aviso_dica : Label = %AvisoSubtitulo
@onready var _lista_retas : HFlowContainer = %ListaRetas

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layer.visible = false
	var sem_retas: Array[float] = []
	mostrar_retas(sem_retas)


func _analyse_answer(usr_ans : float) -> AnswerResult:
	var rel_error := absf(usr_ans - correct_ans) / correct_ans
	
	if rel_error <= hit_margin:
		return AnswerResult.CORRECT

	# O erro relativo comum nunca passa de 100% para chutes abaixo do gabarito,
	# então o erro grosseiro compara pela razão, que vale nos dois sentidos:
	# com fail_margin = 1.0, é grosseiro chutar mais que o dobro ou menos que a metade.
	var fator := maxf(usr_ans, correct_ans) / minf(usr_ans, correct_ans)
	if fator - 1.0 <= fail_margin:
		return AnswerResult.RETRY
	return AnswerResult.FAIL


func _on_answer_button_pressed() -> void:
	var usr_text : String = ans.text
	
	# Campo vazio ou só com o separador não é número: não submete nem conta como erro,
	# e o menu continua aberto com o foco no campo para o jogador digitar o chute.
	# O sinal de menos é descartado por _filter_number, então não existe chute negativo.
	if usr_text.replace(",", "").replace(".", "").is_empty():
		_rejeitar(AVISO_SEM_NUMERO, AVISO_SEM_NUMERO_DICA)
		return
	
	# O campo só contém dígitos e no máximo um separador (ver _filter_number),
	# então basta normalizar a vírgula. ",5" vira 0.5 e "5," vira 5.
	var usr_num : float = usr_text.replace(",", ".").to_float()
	
	# Zero, com qualquer quantidade de casas (0, 0,0, 0.0000...), não é uma área:
	# é tratado como resposta inválida, igual ao campo vazio.
	if usr_num <= 0.0:
		_rejeitar(AVISO_ZERO, AVISO_ZERO_DICA)
		return
	
	# Um chute válido sempre limpa o campo e fecha o menu, seja qual for o resultado.
	ultima_resposta = usr_num
	ans.clear()
	_set_menu_open(false)
	
	if correct_ans <= 0.0:
		push_error("AnswerMenu: correct_ans precisa ser maior que 0.")
		return
	
	match _analyse_answer(usr_num):
		AnswerResult.CORRECT:
			answer_correct.emit()
		AnswerResult.RETRY:
			answer_retry.emit()
		AnswerResult.FAIL:
			answer_failed.emit()


## Mantém no campo apenas dígitos e um único separador decimal ("," ou ".").
func _filter_number(text : String) -> String:
	var filtered := ""
	var has_separator := false
	for c in text:
		if c >= "0" and c <= "9":
			filtered += c
		elif (c == "," or c == ".") and not has_separator:
			filtered += c
			has_separator = true
	return filtered


func _on_answer_text_edit_text_changed() -> void:
	# Voltar a digitar tira o aviso de resposta inválida.
	_esconder_aviso()
	
	var filtered := _filter_number(ans.text)
	if filtered == ans.text:
		return
	
	# Posição absoluta do cursor no texto antigo, para reposicioná-lo depois
	# de descartar os caracteres inválidos.
	var caret_index : int = ans.get_caret_column()
	for i in ans.get_caret_line():
		caret_index += ans.get_line(i).length() + 1
	var new_caret := _filter_number(ans.text.substr(0, caret_index)).length()
	
	ans.text = filtered
	ans.set_caret_line(0)
	ans.set_caret_column(new_caret)

# Usa _input (e não _unhandled_input) porque o TextEdit consumiria o Tab antes
# de o evento chegar aqui.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("answer_menu"):
		toggle_menu()
		get_viewport().set_input_as_handled()


## Abre o menu fechado ou fecha o aberto. Usado pelo Tab e pelo botão do HUD.
func toggle_menu() -> void:
	_set_menu_open(!layer.visible)


func _set_menu_open(open: bool) -> void:
	var abrindo := open and not layer.visible
	layer.visible = open
	_esconder_aviso()
	if open:
		ans.grab_focus()
		if abrindo:
			SFXManager.play(SFXManager.INTERACTION)
	else:
		ans.release_focus()
	
	## Libera o mouse e trava o player enquanto o menu estiver aberto.
	get_tree().call_group("Player", "set_input_locked", open)


## Reescreve as retas do cartão com os comprimentos em metros, como no HUD (CG-19).
## A fase liga este método ao sinal lines_changed do PointSystem.
func mostrar_retas(comprimentos: Array[float]) -> void:
	for filho in _lista_retas.get_children():
		_lista_retas.remove_child(filho)
		filho.queue_free()

	if comprimentos.is_empty():
		_lista_retas.add_child(_criar_label(TEXTO_SEM_RETAS, FONTE_TEXTO, 12, CINZA))
		return

	var inicio := maxi(comprimentos.size() - max_retas_visiveis, 0)
	if inicio > 0:
		_lista_retas.add_child(_criar_label(TEXTO_RETAS_OCULTAS % inicio, FONTE_TEXTO, 12, CINZA))
	for i in range(inicio, comprimentos.size()):
		_lista_retas.add_child(_criar_reta(i + 1, comprimentos[i]))


## Resposta inválida: mantém o menu aberto com o foco no campo, mostra o aviso e emite answer_invalid.
func _rejeitar(aviso: String, dica: String) -> void:
	ans.grab_focus()
	_mostrar_aviso(aviso, dica)
	answer_invalid.emit()


## Mostra o aviso por duracao_aviso segundos. Um novo envio inválido reinicia
## a contagem em vez de empilhar avisos.
func _mostrar_aviso(aviso: String, dica: String) -> void:
	_aviso_exibicao += 1
	var exibicao := _aviso_exibicao
	_aviso_titulo.text = aviso.to_upper()
	_aviso_dica.text = dica
	_aviso.modulate.a = 1.0

	await get_tree().create_timer(duracao_aviso).timeout
	if exibicao == _aviso_exibicao:
		_esconder_aviso()


func _esconder_aviso() -> void:
	# Invalida o timer da exibição atual.
	_aviso_exibicao += 1
	_aviso.modulate.a = 0.0


func _criar_reta(numero: int, comprimento: float) -> PanelContainer:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = FUNDO_RETA
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 6
	estilo.content_margin_right = 7
	estilo.content_margin_top = 2
	estilo.content_margin_bottom = 2

	var fundo := PanelContainer.new()
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.add_theme_stylebox_override("panel", estilo)
	var linha := HBoxContainer.new()
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_theme_constant_override("separation", 5)
	linha.add_child(_criar_label(str(numero), FONTE_TITULO, 13, VERMELHO))
	linha.add_child(_criar_label(("%.2f m" % comprimento).replace(".", ","), FONTE_NUMERO, 12, ESCURO))
	fundo.add_child(linha)
	return fundo


func _criar_label(texto: String, fonte: Font, tamanho: int, cor: Color) -> Label:
	var label := Label.new()
	label.text = texto
	label.add_theme_font_override("font", fonte)
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label
