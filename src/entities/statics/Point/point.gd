extends Node3D

## Medida exibida como Label 2D (CanvasLayer), projetada a partir da posição 3D do ponto.
## Fica sempre por cima da geometria próxima. Quando algo sólido (chão ou cascas
## do Farol) está entre a câmera e o ponto, vira só um traçado (glow), igual à
## reta e à esfera do ponto vistas através de paredes.

const LABEL_OFFSET := Vector3(0, 0.15, 0)
## Chão (camada 1) + cascas do Farol (camada 2)
const OCLUSAO_MASK := 0b11
## Cores lidas pelo glow_text.gdshader: miolo marcador (apagado) e contorno (vira glow).
const GLOW_FILL_MARKER := Color(1, 0, 0, 1)
const GLOW_OUTLINE_MARKER := Color(1, 1, 1, 1)
const GLOW_TEXT_SHADER: Shader = preload("res://src/shaders/glow/glow_text.gdshader")

@onready var label_group: CanvasGroup = $HUD/LabelGroup
@onready var label: Label = $HUD/LabelGroup/PointLabel
@onready var _font_color: Color = label.get_theme_color("font_color")
@onready var _outline_color: Color = label.get_theme_color("font_outline_color")

var _glow_material := ShaderMaterial.new()
var _em_glow := false


func _ready() -> void:
	_glow_material.shader = GLOW_TEXT_SHADER


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var alvo := global_position + LABEL_OFFSET

	if label.text.is_empty() or cam == null or cam.is_position_behind(alvo):
		label.visible = false
		return

	_set_glow(_oculto(cam, alvo))
	label.visible = true
	## Centraliza o texto horizontalmente, logo acima do ponto.
	label.position = cam.unproject_position(alvo) - label.size * Vector2(0.5, 1.0)


## Raio da câmera até o label: se bater em algo sólido, o ponto está escondido.
func _oculto(cam: Camera3D, alvo: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, alvo, OCLUSAO_MASK)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


## Escondido: o shader do grupo apaga o miolo do texto e deixa só o contorno.
## Só troca quando o estado muda, para não redesenhar o label todo frame.
func _set_glow(ativo: bool) -> void:
	if ativo == _em_glow:
		return
	_em_glow = ativo
	label_group.material = _glow_material if ativo else null
	label.add_theme_color_override("font_color", GLOW_FILL_MARKER if ativo else _font_color)
	label.add_theme_color_override("font_outline_color", GLOW_OUTLINE_MARKER if ativo else _outline_color)
