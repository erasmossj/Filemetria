extends Control

## Mostra o tempo restante do autoload Cronometro em mm:ss, no topo da tela.

## Último segundo exibido, para só reescrever o texto quando ele muda.
var _segundos_exibidos := -1

@onready var _tempo: Label = $CanvasLayer/Painel/Conteudo/Tempo


func _process(_delta: float) -> void:
	# Arredonda para cima: 05:00 no início e 00:00 só quando o tempo acaba.
	var segundos := ceili(Cronometro.tempo_restante)
	if segundos == _segundos_exibidos:
		return
	_segundos_exibidos = segundos
	@warning_ignore("integer_division")
	_tempo.text = "%02d:%02d" % [segundos / 60, segundos % 60]
