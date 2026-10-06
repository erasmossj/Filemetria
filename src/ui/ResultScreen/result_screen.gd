extends Control

const TITULO_ACERTO := "Correto!"
const SUBTITULO_ACERTO := "Você conseguiu recuperar a área com sucesso!"
const TITULO_ERRO := "Tente novamente!"
const TITULO_ERRO_GROSSEIRO := "Tente novamente..."
const SUBTITULO_ERRO_GROSSEIRO := "Dessa vez do começo... Ok?"
const TITULO_TEMPO_ESGOTADO := "Tempo esgotado!"

@export var cor_acerto := Color(0.3, 0.9, 0.4)
@export var cor_erro := Color(0.95, 0.3, 0.3)
## Tempo, em segundos, que a tela fica visível.
@export var duracao := 2.5

## Conta as exibições para que o timer de uma exibição antiga não esconda a atual.
var _exibicao := 0

@onready var _layer: CanvasLayer = $CanvasLayer
@onready var _titulo: Label = $CanvasLayer/Textos/Titulo
@onready var _subtitulo: Label = $CanvasLayer/Textos/Subtitulo


func _ready() -> void:
	_layer.visible = false


## As funções mostrar_* esperam a tela sumir: use com await para agir depois dela.
func mostrar_acerto() -> void:
	await _mostrar(TITULO_ACERTO, SUBTITULO_ACERTO, cor_acerto)


func mostrar_erro() -> void:
	await _mostrar(TITULO_ERRO, "", cor_erro)


func mostrar_erro_grosseiro() -> void:
	await _mostrar(TITULO_ERRO_GROSSEIRO, SUBTITULO_ERRO_GROSSEIRO, cor_erro)


func mostrar_tempo_esgotado() -> void:
	await _mostrar(TITULO_TEMPO_ESGOTADO, SUBTITULO_ERRO_GROSSEIRO, cor_erro)


func _mostrar(titulo: String, subtitulo: String, cor: Color) -> void:
	_exibicao += 1
	var exibicao := _exibicao

	_titulo.text = titulo
	_subtitulo.text = subtitulo
	_subtitulo.visible = not subtitulo.is_empty()
	_titulo.add_theme_color_override("font_color", cor)
	_subtitulo.add_theme_color_override("font_color", cor)
	_layer.visible = true

	await get_tree().create_timer(duracao).timeout
	if exibicao == _exibicao:
		_layer.visible = false
