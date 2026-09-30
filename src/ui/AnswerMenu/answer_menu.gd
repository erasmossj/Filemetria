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
## Erro relativo acima do qual o chute é um erro grosseiro (1.0 = 100%).
@export_range(0.0, 10.0, 0.05) var fail_margin := 1.0

@onready var ans = $"CanvasLayer/MenuHolder/AnswerTextEdit"
@onready var ans_btn : Button = $"CanvasLayer/MenuHolder/AnswerButton"

var _number_regex := RegEx.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Aceita "." ou "," como separador decimal. O sinal de menos é capturado
	# para que valores negativos sejam reconhecidos e bloqueados.
	_number_regex.compile("-?\\d+(?:[.,]\\d+)?")
	ans_btn.pressed.connect(_on_answer_button_pressed)


func _analyse_answer(usr_ans : float) -> AnswerResult:
	var rel_error := absf(usr_ans - correct_ans) / correct_ans
	
	if rel_error <= hit_margin:
		return AnswerResult.CORRECT
	if rel_error <= fail_margin:
		return AnswerResult.RETRY
	return AnswerResult.FAIL


func _on_answer_button_pressed() -> void:
	if ans.text.strip_edges().is_empty():
		return
	
	var resultado := _number_regex.search(ans.text)
	if resultado == null:
		return
	
	var usr_num := resultado.get_string().replace(",", ".").to_float()
	
	# Negativo ou zero é entrada inválida: não submete nem conta como erro
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
