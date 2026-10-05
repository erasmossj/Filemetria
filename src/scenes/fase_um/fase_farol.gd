extends Node3D

## Emitido ao acertar o último ato (quando não há próxima fase configurada).
signal fase_concluida

## Ato que o Farol exibe. O Lodo de cada ato vem dentro do .glb e o Farol liga só o do ato ativo.
@export_range(1, 3) var ato := 1
## Área da casca de Lodo deste ato em m² (tabela de gabarito do CG-16).
@export var gabarito := 0.0
## Cena carregada ao acertar. Vazio no último ato: emite fase_concluida.
@export_file("*.tscn") var proxima_fase := ""
## Cena carregada no erro grosseiro: reiniciar a fase volta ao Ato 1 (CG-36).
@export_file("*.tscn") var primeiro_ato := "uid://c0o36thse02tt"  # ato_1_farol.tscn

@onready var _farol = $Farol
@onready var _answer_menu = $AnswerMenu
@onready var _result_screen = $ResultScreen


func _ready() -> void:
	_farol.ato = ato
	_answer_menu.correct_ans = gabarito
	_answer_menu.answer_correct.connect(_on_answer_correct)
	_answer_menu.answer_retry.connect(_result_screen.mostrar_erro)
	_answer_menu.answer_failed.connect(_on_answer_failed)


func _on_answer_correct() -> void:
	if proxima_fase.is_empty():
		_result_screen.mostrar_acerto()
		fase_concluida.emit()
		return
	_travar_jogo()
	await _result_screen.mostrar_acerto()
	get_tree().change_scene_to_file(proxima_fase)


func _on_answer_failed() -> void:
	_travar_jogo()
	await _result_screen.mostrar_erro_grosseiro()
	get_tree().change_scene_to_file(primeiro_ato)


## Enquanto a tela de resultado antecede a troca de cena, o player fica parado
## e o menu de resposta não abre. Não mexe no mouse, que continua capturado.
func _travar_jogo() -> void:
	get_tree().set_group("Player", "input_locked", true)
	_answer_menu.process_mode = Node.PROCESS_MODE_DISABLED
