extends Control

## Emitido quando o erro relativo está dentro da margem de acerto (dispara CG-21 e avança o ato).
signal answer_correct
## Emitido quando o erro está entre as duas margens: o jogador pode tentar de novo.
signal answer_retry
## Emitido quando o erro passa da margem de erro grosseiro: falha, reinicia a fase (CG-37).
signal answer_failed

enum AnswerResult { CORRECT, RETRY, FAIL }

## Gabarito da área total em m² (tabela de CG-16).
@export var correct_ans := 0.0
## Erro relativo máximo para contar como acerto (0.10 = 10%).
@export_range(0.0, 1.0, 0.01) var hit_margin := 0.10
## Erro acima do qual o chute é um erro grosseiro, nos dois sentidos.
## 1.0 = 100%: grosseiro acima do dobro ou abaixo da metade do gabarito.
@export_range(0.0, 10.0, 0.05) var fail_margin := 1.0

@onready var ans = $"CanvasLayer/MenuHolder/AnswerTextEdit"
## O CanvasLayer não herda a visibilidade do Control pai, então é ele que precisa ser escondido.
@onready var layer : CanvasLayer = $"CanvasLayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layer.visible = false


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
	
	# Enviar sempre limpa o campo e fecha o menu, seja qual for a entrada ou o resultado.
	ans.clear()
	_set_menu_open(false)
	
	if usr_text.is_empty():
		return
	
	# O campo só contém dígitos e no máximo um separador (ver _filter_number),
	# então basta normalizar a vírgula. ",5" vira 0.5 e "5," vira 5.
	var usr_num : float = usr_text.replace(",", ".").to_float()
	
	# Zero (ou só o separador) é entrada inválida: não submete nem conta como erro
	if usr_num <= 0.0:
		return
	
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
		_set_menu_open(!layer.visible)
		get_viewport().set_input_as_handled()


func _set_menu_open(open: bool) -> void:
	layer.visible = open
	if open:
		ans.grab_focus()
	else:
		ans.release_focus()
	
	## Libera o mouse e trava o player enquanto o menu estiver aberto.
	get_tree().call_group("Player", "set_input_locked", open)
