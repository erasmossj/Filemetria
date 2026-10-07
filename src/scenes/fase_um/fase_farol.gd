extends Node3D

## Emitido ao acertar o último ato (quando não há próxima fase configurada).
signal fase_concluida

## Quantos atos a fase tem. O HUD mostra "Ato N de TOTAL_ATOS".
const TOTAL_ATOS := 3

## Ato que o Farol exibe. O Lodo de cada ato vem dentro do .glb e o Farol liga só o do ato ativo.
@export_range(1, 3) var ato := 1
## Área da casca de Lodo deste ato em m² (tabela de gabarito do CG-16).
@export var gabarito := 0.0
## Cena carregada ao acertar. Vazio no último ato: emite fase_concluida.
@export_file("*.tscn") var proxima_fase := ""
## Cena carregada no erro grosseiro: reiniciar a fase volta ao Ato 1 (CG-36).
@export_file("*.tscn") var primeiro_ato := "uid://c0o36thse02tt"  # ato_1_farol.tscn
## Tempo total da fase em segundos, somando os 3 atos (CG-37). Só é lido no Ato 1,
## que zera o cronômetro; os outros atos continuam a contagem de onde ela parou.
@export_range(1, 3600, 1, "suffix:s") var tempo_total := 600.0
## Objetivo do ato em uma frase, exibido no HUD (CG-38).
@export_multiline var objetivo := ""

## True quando o cronômetro não pode mais voltar a correr nesta cena: troca de cena
## já decidida ou último ato concluído. Sair da pausa do ESC não o retoma.
var _cronometro_encerrado := false

@onready var _farol = $Farol
@onready var _player = $Player
@onready var _answer_menu = $AnswerMenu
@onready var _result_screen = $ResultScreen
@onready var _hud = $Hud


func _ready() -> void:
	_farol.ato = ato
	_answer_menu.correct_ans = gabarito
	_answer_menu.answer_correct.connect(_on_answer_correct)
	_answer_menu.answer_retry.connect(_on_answer_retry)
	_answer_menu.answer_failed.connect(_on_answer_failed)

	_hud.configurar(ato, TOTAL_ATOS, objetivo)
	_hud.calcular_area_pressionado.connect(_on_hud_calcular_area_pressionado)
	_player.ps.lines_changed.connect(_hud.mostrar_retas)
	_player.ps.lines_changed.connect(_answer_menu.mostrar_retas)

	# Tempo zerado: a cena de um ato foi aberta direto pelo editor, sem passar pelo Ato 1.
	if ato == 1 or Cronometro.tempo_restante <= 0.0:
		Cronometro.iniciar(tempo_total)
	else:
		Cronometro.continuar()
	Cronometro.tempo_esgotado.connect(_on_tempo_esgotado)
	_player.pause_toggled.connect(_on_player_pause_toggled)


func _on_answer_correct() -> void:
	SFXManager.play(SFXManager.CORRECT)
	if proxima_fase.is_empty():
		_encerrar_cronometro()
		_result_screen.mostrar_acerto(_answer_menu.ultima_resposta, ato + 1, TOTAL_ATOS)
		fase_concluida.emit()
		return
	_travar_jogo()
	await _result_screen.mostrar_acerto(_answer_menu.ultima_resposta, ato + 1, TOTAL_ATOS)
	get_tree().change_scene_to_file(proxima_fase)


## O jogo continua: a tela só mostra o chute e o tempo que restava ao enviar.
func _on_answer_retry() -> void:
	SFXManager.play(SFXManager.WRONG)
	_result_screen.mostrar_erro(_answer_menu.ultima_resposta, Cronometro.tempo_restante)


func _on_answer_failed() -> void:
	SFXManager.play(SFXManager.WRONG)
	_travar_jogo()
	await _result_screen.mostrar_erro_grosseiro(_answer_menu.ultima_resposta)
	get_tree().change_scene_to_file(primeiro_ato)


## O botão do HUD faz o mesmo que o Tab. Depois que a fase trava o menu
## (_travar_jogo), o clique não o abre mais.
func _on_hud_calcular_area_pressionado() -> void:
	if _answer_menu.can_process():
		_answer_menu.toggle_menu()


func _on_player_pause_toggled(paused: bool) -> void:
	if paused:
		Cronometro.pausar()
	elif not _cronometro_encerrado:
		Cronometro.continuar()


func _on_tempo_esgotado() -> void:
	_travar_jogo()
	await _result_screen.mostrar_tempo_esgotado()
	get_tree().change_scene_to_file(primeiro_ato)


## Enquanto a tela de resultado antecede a troca de cena, o player fica parado
## e o menu de resposta não abre. Não mexe no mouse, que continua capturado.
## O cronômetro também para: o tempo da tela não conta, e ele não pode esgotar
## no meio de uma troca de cena já decidida.
func _travar_jogo() -> void:
	_encerrar_cronometro()
	get_tree().set_group("Player", "input_locked", true)
	_answer_menu.process_mode = Node.PROCESS_MODE_DISABLED


func _encerrar_cronometro() -> void:
	_cronometro_encerrado = true
	Cronometro.pausar()
