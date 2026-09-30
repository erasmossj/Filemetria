extends Node3D

## Medida exibida como Label 2D (CanvasLayer), projetada a partir da posição 3D do ponto.
## Fica sempre por cima da geometria próxima, mas some quando algo sólido
## (chão ou cascas do Farol) está entre a câmera e o ponto.

const LABEL_OFFSET := Vector3(0, 0.15, 0)
## Chão (camada 1) + cascas do Farol (camada 2)
const OCLUSAO_MASK := 0b11

@onready var label: Label = $HUD/PointLabel


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var alvo := global_position + LABEL_OFFSET

	if label.text.is_empty() or cam == null or cam.is_position_behind(alvo) or _oculto(cam, alvo):
		label.visible = false
		return

	label.visible = true
	## Centraliza o texto horizontalmente, logo acima do ponto.
	label.position = cam.unproject_position(alvo) - label.size * Vector2(0.5, 1.0)


## Raio da câmera até o label: se bater em algo sólido, o ponto está escondido.
func _oculto(cam: Camera3D, alvo: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, alvo, OCLUSAO_MASK)
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
