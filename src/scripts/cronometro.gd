extends Node

## Cronômetro da fase (CG-37). É autoload porque cada ato é uma cena própria e
## change_scene_to_file destruiria o tempo restante na troca de ato.
## Quem inicia, pausa e retoma é a fase (fase_farol.gd); o HUD lê o tempo e solicita o alerta urgente.

## Emitido uma vez quando a contagem chega a zero.
signal tempo_esgotado
## Emitido uma vez por tentativa quando o HUD entra na faixa urgente.
signal tempo_urgente

## Segundos que faltam. Zero antes da primeira chamada de iniciar().
var tempo_restante := 0.0
## Tempo da fase inteira, recebido em iniciar(). O HUD usa para a fração de tempo restante.
var tempo_total := 0.0

var _rodando := false
var _alerta_urgente_emitido := false


func _process(delta: float) -> void:
	if not _rodando:
		return
	tempo_restante = maxf(tempo_restante - delta, 0.0)
	if tempo_restante == 0.0:
		_rodando = false
		tempo_esgotado.emit()


## Zera a contagem para tempo_total segundos e começa a correr.
func iniciar(tempo_total: float) -> void:
	self.tempo_total = tempo_total
	tempo_restante = tempo_total
	_alerta_urgente_emitido = false
	_rodando = tempo_total > 0.0


## Volta a correr de onde parou, sem mexer no tempo restante.
func continuar() -> void:
	_rodando = tempo_restante > 0.0


func pausar() -> void:
	_rodando = false


## O HUD detecta a urgência; a trava fica aqui para sobreviver à troca de ato.
func alertar_tempo_urgente() -> void:
	if _alerta_urgente_emitido:
		return
	_alerta_urgente_emitido = true
	tempo_urgente.emit()
