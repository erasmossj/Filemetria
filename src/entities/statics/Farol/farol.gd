extends Node3D

const CAMADA_CASCAS := 2

@export_range(1, 3) var ato: int = 1:
	set(valor):
		ato = valor
		if is_node_ready():
			_aplicar_ato()

## A faixa vermelha da base fica por fora da casca de Lodo dos Atos 2 e 3 (o Lodo está
## a 4,5 mm do corpo nessa altura) e apareceria por cima dela. Onde o Lodo do ato cobre
## a faixa, ela é escondida: o Lodo é opaco, então o resultado visual é o mesmo.
@onready var _faixa_base: CSGCombiner3D = $FaixasVermelhas/FaixaBase
## No Ato 3, o Lodo cobre a base só na metade x > 0 do corpo.
@onready var _recorte_lodo_ato_3: CSGBox3D = $FaixasVermelhas/FaixaBase/RecorteLodoAto3

@onready var _atos: Array[Node3D] = [
	$farol_ponta_verde_oficial/ato_1,
	$farol_ponta_verde_oficial/ato_2,
	$farol_ponta_verde_oficial/ato_3,
]


func _ready() -> void:
	for no in _atos:
		_configurar_camada(no)
	_aplicar_ato()


func _aplicar_ato() -> void:
	for i in _atos.size():
		var ativo := i == ato - 1
		_atos[i].process_mode = Node.PROCESS_MODE_INHERIT if ativo else Node.PROCESS_MODE_DISABLED
		_atos[i].visible = ativo

	_faixa_base.visible = ato != 2
	_recorte_lodo_ato_3.visible = ato == 3


func _configurar_camada(no: Node) -> void:
	for filho in no.get_children():
		if filho is StaticBody3D:
			filho.collision_layer = 0
			filho.set_collision_layer_value(CAMADA_CASCAS, true)
			filho.collision_mask = 0
		_configurar_camada(filho)
