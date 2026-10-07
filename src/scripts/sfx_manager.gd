extends Node

## Efeitos globais: os players sobrevivem à troca de ato e usam somente o bus SFX.
const INTERACTION: AudioStream = preload("res://assets/audio/sfx/interaction.mp3")
const CORRECT: AudioStream = preload("res://assets/audio/sfx/correct.mp3")
const WRONG: AudioStream = preload("res://assets/audio/sfx/wrong.mp3")
const TIME_WARNING: AudioStream = preload("res://assets/audio/sfx/time_warning.mp3")

var _players: Dictionary = {}


func _ready() -> void:
	# Um player por arquivo evita cortar o alerta ao tocar uma interação ou resposta.
	for stream in [INTERACTION, CORRECT, WRONG, TIME_WARNING]:
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = &"SFX"
		player.max_polyphony = 4
		add_child(player)
		_players[stream] = player
	Cronometro.tempo_urgente.connect(play.bind(TIME_WARNING))


func play(stream: AudioStream) -> void:
	var player: AudioStreamPlayer = _players[stream]
	player.play()
