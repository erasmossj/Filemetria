extends Node3D

const CAMADA_CASCAS := 2

@export_range(1, 3) var ato: int = 1:
	set(valor):
		ato = valor
		if is_node_ready():
			_aplicar_ato()

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


func _configurar_camada(no: Node) -> void:
	for filho in no.get_children():
		if filho is StaticBody3D:
			filho.collision_layer = 0
			filho.set_collision_layer_value(CAMADA_CASCAS, true)
			filho.collision_mask = 0
		_configurar_camada(filho)
